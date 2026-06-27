# 09 — API Architecture

## Purpose
Define how the Flutter app communicates with Supabase — REST, Realtime, Storage, Auth, and Edge Functions. All API contracts, request/response shapes, error handling, and RLS enforcement.

---

## 1. Supabase Client Configuration

```
SupabaseClient initialized with:
  - url: SUPABASE_URL (from environment)
  - anonKey: SUPABASE_ANON_KEY (from environment)
  - authOptions: AuthClientOptions(
      autoRefreshToken: true,
      persistSession: false,    ← We handle persistence manually in SecureStorage
      detectSessionInUri: true,  ← For magic link deep links
    )
```

The Supabase client is provided as a singleton Riverpod provider:

```
final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});
```

---

## 2. Authentication API

### 2.1 Phone OTP

**Request:**
```
supabase.auth.signInWithOtp(phone: '+919876543210')
```

**Response (success):** `AuthResponse` with `session = null` (OTP sent)

**Verify OTP:**
```
supabase.auth.verifyOTP(
  phone: '+919876543210',
  token: '123456',
  type: OtpType.sms,
)
```

**Response (success):** `AuthResponse` with valid `Session`

**Error cases:**
| Error Code | Handling |
|---|---|
| `otp_expired` | Show "OTP expired, request a new one" |
| `invalid_otp` | Show "Invalid code, try again" |
| `otp_attempts_exceeded` | Show "Too many attempts, wait X minutes" |

### 2.2 Magic Link

**Request:**
```
supabase.auth.signInWithOtp(
  email: 'user@example.com',
  emailRedirectTo: 'securechat://auth/callback',
)
```

**Deep link handling:** GoRouter intercepts `securechat://auth/callback` and completes the session.

---

## 3. User Profile API

### 3.1 Create Profile

```
supabase.from('user_profiles').insert({
  'user_id': userId,
  'display_name': displayName,
  'date_of_birth': dob.toIso8601String(),
})
```

### 3.2 Get Own Profile

```
supabase.from('user_profiles')
  .select()
  .eq('user_id', auth.uid())
  .single()
```

### 3.3 Get Partner Profile

```
supabase.from('user_profiles')
  .select()
  .eq('user_id', partnerId)
  .single()
```

### 3.4 Update Profile

```
supabase.from('user_profiles')
  .update({'display_name': newName, 'updated_at': now})
  .eq('user_id', auth.uid())
```

---

## 4. Pairing API

### 4.1 Generate Invite Code

```
supabase.from('pair_invite_codes').insert({
  'code': generatedCode,   ← 8-char random alphanumeric, generated client-side
  'creator_id': auth.uid(),
  'expires_at': now + 48h,
})
```

### 4.2 Validate and Accept Invite Code

This is a Supabase Edge Function (not direct table access) to ensure atomicity:

**Edge Function:** `POST /functions/v1/accept-invite-code`

**Request body:**
```json
{
  "code": "ABC12345"
}
```

**Edge Function logic:**
1. Validate code exists, not used, not expired, not own code
2. Create `pairs` record atomically
3. Mark code as `used = true`
4. Return `pair_id`

**Response (success):**
```json
{
  "pair_id": "uuid",
  "partner_id": "uuid"
}
```

**Error responses:**
```json
{ "error": "CODE_INVALID" }
{ "error": "CODE_EXPIRED" }
{ "error": "CODE_SELF" }
{ "error": "ALREADY_PAIRED" }
```

---

## 5. Messaging API

### 5.1 Send Message

```
supabase.from('messages').insert({
  'pair_id': pairId,
  'sender_id': auth.uid(),
  'message_type': 'text',
  'ciphertext': ciphertextBytes,   ← Uint8List (binary)
  'sent_at': now,
})
.select()
.single()
```

**Returns:** The inserted message row (for obtaining the server-assigned `id`).

### 5.2 Fetch Messages (Paginated)

```
supabase.from('messages')
  .select('''
    *,
    message_reactions(id, user_id, emoji),
    message_receipts(user_id, read_at)
  ''')
  .eq('pair_id', pairId)
  .is_('deleted_at', null)
  .order('sent_at', ascending: false)
  .range(offset, offset + 49)
```

**Note:** Returns max 50 messages per page. `offset` increments by 50 per page.

### 5.3 Update Message (Edit)

```
supabase.from('messages')
  .update({
    'ciphertext': newCiphertext,
    'edited_at': now,
  })
  .eq('id', messageId)
  .eq('sender_id', auth.uid())   ← RLS also enforces, but explicit for clarity
```

### 5.4 Delete Message

```
supabase.from('messages')
  .update({
    'ciphertext': null,
    'status': 'deleted',
    'deleted_at': now,
  })
  .eq('id', messageId)
  .eq('sender_id', auth.uid())
```

### 5.5 Mark Message as Read

```
supabase.from('message_receipts').upsert({
  'message_id': messageId,
  'user_id': auth.uid(),
  'read_at': now,
})
```

---

## 6. Reactions API

### 6.1 Add Reaction

```
supabase.from('message_reactions').upsert({
  'message_id': messageId,
  'user_id': auth.uid(),
  'emoji': '❤️',
})
```

### 6.2 Remove Reaction

```
supabase.from('message_reactions')
  .delete()
  .eq('message_id', messageId)
  .eq('user_id', auth.uid())
```

---

## 7. Signal Protocol Keys API

### 7.1 Publish Identity Key

```
supabase.from('user_identity_keys').insert({
  'user_id': auth.uid(),
  'public_key': identityPublicKeyBytes,
  'registration_id': registrationId,
})
```

### 7.2 Publish Prekeys

```
supabase.from('user_prekey_bundles').insert([
  {
    'user_id': auth.uid(),
    'prekey_id': id,
    'public_key': publicKeyBytes,
    'is_one_time': true,
  },
  // ... batch of 100 prekeys
])
```

### 7.3 Fetch Partner Prekey Bundle

```
// Get signed prekey
supabase.from('user_prekey_bundles')
  .select()
  .eq('user_id', partnerId)
  .eq('is_one_time', false)
  .single()

// Get one-time prekey (and mark as used)
// Done via Edge Function for atomicity:
POST /functions/v1/claim-prekey
Body: { "partner_id": "uuid" }
Response: { prekey_id, public_key }
```

---

## 8. Realtime Subscriptions

### 8.1 New Messages

```dart
supabase.channel('messages:$pairId')
  .onPostgresChanges(
    event: PostgresChangeEvent.insert,
    schema: 'public',
    table: 'messages',
    filter: PostgresChangeFilter(
      type: FilterType.eq,
      column: 'pair_id',
      value: pairId,
    ),
    callback: (payload) => onNewMessage(payload),
  )
  .subscribe();
```

### 8.2 Message Status Updates

```dart
supabase.channel('receipts:$pairId')
  .onPostgresChanges(
    event: PostgresChangeEvent.insert,
    schema: 'public',
    table: 'message_receipts',
    callback: (payload) => onReceiptUpdate(payload),
  )
  .subscribe();
```

### 8.3 Typing Indicator (Presence)

```dart
final channel = supabase.channel('typing:$pairId');

// Send typing state
channel.sendBroadcastMessage(
  event: 'typing',
  payload: {'user_id': auth.uid(), 'is_typing': true},
);

// Receive typing state
channel.onBroadcast(
  event: 'typing',
  callback: (payload) => onTypingUpdate(payload),
).subscribe();
```

### 8.4 Partner Presence

```dart
supabase.channel('presence:$pairId')
  .onPresenceSync(callback: (payload) => onPresenceSync(payload))
  .onPresenceJoin(callback: (payload) => onPartnerOnline(payload))
  .onPresenceLeave(callback: (payload) => onPartnerOffline(payload))
  .subscribe();
```

### 8.5 Pair Status (for detecting partner acceptance)

```dart
supabase.channel('pair_status')
  .onPostgresChanges(
    event: PostgresChangeEvent.insert,
    schema: 'public',
    table: 'pairs',
    filter: PostgresChangeFilter(
      type: FilterType.eq,
      column: 'user_a_id',
      value: auth.uid(),
    ),
    callback: (payload) => onPairingComplete(payload),
  )
  .subscribe();
```

---

## 9. Edge Functions

### 9.1 `accept-invite-code`

**Trigger:** Client POST  
**Purpose:** Atomically validate invite code and create pair  
**Auth:** Requires Bearer JWT  

### 9.2 `claim-prekey`

**Trigger:** Client POST  
**Purpose:** Atomically fetch and mark-as-used one-time prekey  
**Auth:** Requires Bearer JWT  

### 9.3 `send-push-notification`

**Trigger:** Database webhook on `messages` INSERT  
**Purpose:** Send FCM push to recipient's device  
**Logic:**
1. Get `pair_id` from inserted message
2. Determine recipient (pair member who is not sender)
3. Fetch recipient's FCM token from `user_devices`
4. Check recipient's notification mute settings
5. Send FCM message via Google FCM API

### 9.4 `cleanup-expired-messages`

**Trigger:** Supabase cron (every hour)  
**Purpose:** Delete messages past their `expires_at`  
**Logic:**
```sql
DELETE FROM messages WHERE expires_at < NOW();
```

### 9.5 `delete-account`

**Trigger:** Client POST (authenticated)  
**Purpose:** Delete all user data atomically  
**Logic:**
1. Delete user_profiles, user_devices, user_settings, user_presence
2. Delete user_identity_keys, user_prekey_bundles
3. Delete pairs (CASCADE deletes messages, reactions, receipts)
4. Delete media from Supabase Storage bucket
5. Call `supabase.auth.admin.deleteUser(userId)`
6. Return success

---

## 10. Error Handling

### Supabase Error Mapping

| Supabase Error | Domain Failure |
|---|---|
| `PostgrestException` with status 401 | `AuthFailure.unauthorized()` |
| `PostgrestException` with status 403 | `AuthFailure.forbidden()` |
| `PostgrestException` with status 400 | `ServerFailure.badRequest(message)` |
| `PostgrestException` with status 5xx | `ServerFailure.server(message)` |
| `SocketException` | `ServerFailure.noConnection()` |
| `TimeoutException` | `ServerFailure.timeout()` |
| `AuthException` | `AuthFailure.fromCode(code)` |

All data sources wrap API calls in try-catch and return domain failures — no Supabase exceptions bubble to domain or presentation.

---

## 11. API Security Checklist

- [ ] All requests include `Authorization: Bearer <JWT>` header (Supabase client handles this)
- [ ] Every table has RLS enabled with default-deny
- [ ] Edge Functions validate JWT before processing
- [ ] No sensitive data in query parameters (use body/headers)
- [ ] Rate limiting on OTP requests (Supabase Auth built-in)
- [ ] Certificate pinning enabled in production builds
- [ ] No CORS vulnerabilities (Edge Functions configured correctly)
