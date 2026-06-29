import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

// ── Types ────────────────────────────────────────────────────────────────────

interface TriggerPayload {
  message_id: string;
  pair_id: string;
  sender_id: string;
  message_type: string;
}

// ── FCM helpers (HTTP v1 API) ────────────────────────────────────────────────

function pemToDer(pem: string): ArrayBuffer {
  const base64 = pem
    .replace(/-----BEGIN PRIVATE KEY-----/g, '')
    .replace(/-----END PRIVATE KEY-----/g, '')
    .replace(/\s/g, '');
  const binary = atob(base64);
  const bytes = new Uint8Array(binary.length);
  for (let i = 0; i < binary.length; i++) {
    bytes[i] = binary.charCodeAt(i);
  }
  return bytes.buffer;
}

function base64url(buffer: ArrayBuffer): string {
  const bytes = new Uint8Array(buffer);
  let str = '';
  for (const b of bytes) str += String.fromCharCode(b);
  return btoa(str).replace(/\+/g, '-').replace(/\//g, '_').replace(/=/g, '');
}

async function getAccessToken(serviceAccount: {
  client_email: string;
  private_key: string;
  project_id: string;
}): Promise<string> {
  const now = Math.floor(Date.now() / 1000);

  const header = { alg: 'RS256', typ: 'JWT' };
  const payload = {
    iss: serviceAccount.client_email,
    scope: 'https://www.googleapis.com/auth/firebase.messaging',
    aud: 'https://oauth2.googleapis.com/token',
    exp: now + 3600,
    iat: now,
  };

  const enc = new TextEncoder();
  const headerB64 = base64url(enc.encode(JSON.stringify(header)));
  const payloadB64 = base64url(enc.encode(JSON.stringify(payload)));
  const signingInput = `${headerB64}.${payloadB64}`;

  const privateKey = await crypto.subtle.importKey(
    'pkcs8',
    pemToDer(serviceAccount.private_key),
    { name: 'RSASSA-PKCS1-v1_5', hash: 'SHA-256' },
    false,
    ['sign'],
  );

  const signature = await crypto.subtle.sign(
    'RSASSA-PKCS1-v1_5',
    privateKey,
    enc.encode(signingInput),
  );

  const jwt = `${signingInput}.${base64url(signature)}`;

  const tokenRes = await fetch('https://oauth2.googleapis.com/token', {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body: new URLSearchParams({
      grant_type: 'urn:ietf:params:oauth:grant-type:jwt-bearer',
      assertion: jwt,
    }),
  });

  if (!tokenRes.ok) {
    throw new Error(`OAuth2 token exchange failed: ${await tokenRes.text()}`);
  }

  const { access_token } = await tokenRes.json();
  return access_token as string;
}

async function sendFcmNotification(
  projectId: string,
  accessToken: string,
  fcmToken: string,
  messageType: string,
): Promise<void> {
  const isMedia = messageType === 'image' || messageType === 'voice';
  const body = isMedia
    ? `Sent you a ${messageType} message`
    : 'You have a new encrypted message';

  const res = await fetch(
    `https://fcm.googleapis.com/v1/projects/${projectId}/messages:send`,
    {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${accessToken}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        message: {
          token: fcmToken,
          notification: { title: 'SecureChat', body },
          data: { type: 'new_message' },
          android: {
            priority: 'HIGH',
            notification: { channel_id: 'securechat_messages', sound: 'default' },
          },
          apns: {
            payload: { aps: { sound: 'default', badge: 1, 'content-available': 1 } },
          },
        },
      }),
    },
  );

  if (!res.ok) {
    throw new Error(`FCM send failed: ${await res.text()}`);
  }
}

// ── Handler ──────────────────────────────────────────────────────────────────

Deno.serve(async (req: Request) => {
  try {
    const payload = (await req.json()) as TriggerPayload;
    const { pair_id, sender_id, message_type } = payload;

    // ── Supabase admin client ────────────────────────────────────────────────

    const supabase = createClient(
      Deno.env.get('SUPABASE_URL')!,
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
    );

    // ── Resolve recipient ────────────────────────────────────────────────────

    const { data: pair, error: pairErr } = await supabase
      .from('pairs')
      .select('user_a_id, user_b_id')
      .eq('id', pair_id)
      .single();

    if (pairErr || !pair) {
      console.warn('Pair not found:', pair_id);
      return new Response('ok', { status: 200 });
    }

    const recipientId =
      pair.user_a_id === sender_id ? pair.user_b_id : pair.user_a_id;

    // ── Fetch FCM token ──────────────────────────────────────────────────────

    const { data: profile, error: profileErr } = await supabase
      .from('user_profiles')
      .select('fcm_token')
      .eq('user_id', recipientId)
      .single();

    if (profileErr || !profile?.fcm_token) {
      // Recipient has no token — notifications not enabled on their device.
      return new Response('ok', { status: 200 });
    }

    // ── Send via FCM v1 API ──────────────────────────────────────────────────

    const serviceAccountJson = Deno.env.get('FIREBASE_SERVICE_ACCOUNT');
    if (!serviceAccountJson) {
      console.warn('FIREBASE_SERVICE_ACCOUNT secret not set — skipping FCM');
      return new Response('ok', { status: 200 });
    }

    const serviceAccount = JSON.parse(serviceAccountJson) as {
      client_email: string;
      private_key: string;
      project_id: string;
    };

    const accessToken = await getAccessToken(serviceAccount);
    await sendFcmNotification(
      serviceAccount.project_id,
      accessToken,
      profile.fcm_token,
      message_type,
    );

    return new Response(JSON.stringify({ sent: true }), {
      status: 200,
      headers: { 'Content-Type': 'application/json' },
    });
  } catch (err) {
    console.error('send-push-notification error:', err);
    // Return 200 so the DB trigger does not retry forever.
    return new Response(JSON.stringify({ error: String(err) }), {
      status: 200,
      headers: { 'Content-Type': 'application/json' },
    });
  }
});
