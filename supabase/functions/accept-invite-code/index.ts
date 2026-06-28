import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';
import { corsHeaders } from '../_shared/cors.ts';

interface RequestBody {
  code: string;
}

interface ResponseBody {
  pair_id: string;
  partner_id: string;
}

Deno.serve(async (req: Request) => {
  // Handle CORS preflight
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  try {
    // Service-role client — bypasses RLS for the pairs INSERT.
    const supabaseAdmin = createClient(
      Deno.env.get('SUPABASE_URL')!,
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
    );

    // User-scoped client — identifies the caller.
    const authHeader = req.headers.get('Authorization');
    if (!authHeader) {
      return errorResponse('Missing Authorization header', 401);
    }
    const supabaseUser = createClient(
      Deno.env.get('SUPABASE_URL')!,
      Deno.env.get('SUPABASE_ANON_KEY')!,
      { global: { headers: { Authorization: authHeader } } },
    );

    const { data: { user }, error: userError } = await supabaseUser.auth.getUser();
    if (userError || !user) {
      return errorResponse('Unauthorized', 401);
    }
    const accepterId = user.id;

    const body = await req.json() as RequestBody;
    if (!body.code || body.code.length !== 8) {
      return errorResponse('Invalid code format', 400);
    }
    const code = body.code.toUpperCase();

    // Look up the invite code using admin to avoid RLS complications.
    const { data: inviteRow, error: lookupError } = await supabaseAdmin
      .from('pair_invite_codes')
      .select('id, creator_id, used, expires_at')
      .eq('code', code)
      .single();

    if (lookupError || !inviteRow) {
      return errorResponse('Invalid invite code', 404);
    }
    if (inviteRow.used) {
      return errorResponse('Invite code has already been used', 409);
    }
    if (new Date(inviteRow.expires_at) < new Date()) {
      return errorResponse('Invite code has expired', 410);
    }
    if (inviteRow.creator_id === accepterId) {
      return errorResponse('You cannot use your own invite code', 403);
    }
    const creatorId = inviteRow.creator_id as string;

    // Ensure neither user is already paired.
    const { count: existingPairCount } = await supabaseAdmin
      .from('pairs')
      .select('id', { count: 'exact', head: true })
      .or(`user_a_id.eq.${creatorId},user_b_id.eq.${creatorId},user_a_id.eq.${accepterId},user_b_id.eq.${accepterId}`);

    if ((existingPairCount ?? 0) > 0) {
      return errorResponse('One or both users are already paired', 409);
    }

    // Create the pair.
    const { data: pairRow, error: insertError } = await supabaseAdmin
      .from('pairs')
      .insert({ user_a_id: creatorId, user_b_id: accepterId })
      .select('id')
      .single();

    if (insertError || !pairRow) {
      console.error('pairs insert error', insertError);
      return errorResponse('Failed to create pair', 500);
    }

    // Mark the invite code as used.
    await supabaseAdmin
      .from('pair_invite_codes')
      .update({ used: true })
      .eq('id', inviteRow.id);

    const response: ResponseBody = {
      pair_id: pairRow.id as string,
      partner_id: creatorId,
    };
    return new Response(JSON.stringify(response), {
      status: 200,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  } catch (err) {
    console.error('accept-invite-code error', err);
    return errorResponse('Internal server error', 500);
  }
});

function errorResponse(message: string, status: number): Response {
  return new Response(JSON.stringify({ error: message }), {
    status,
    headers: { ...corsHeaders, 'Content-Type': 'application/json' },
  });
}
