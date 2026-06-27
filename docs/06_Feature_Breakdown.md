# 06 — Feature Breakdown & Inventory

## Purpose
Complete feature inventory with priority, complexity, dependencies, database tables, API endpoints, storage needs, realtime needs, and estimated effort for every feature.

---

## Feature Inventory

### FEAT-001: Authentication

| Property | Value |
|---|---|
| **Priority** | P0 (Critical — nothing works without this) |
| **Description** | Phone OTP and email magic link registration and login; JWT session management |
| **Complexity** | Medium |
| **Estimated Dev Time** | 3 days |
| **Dependencies** | None (first feature) |
| **Related Screens** | SplashScreen, LoginScreen, OtpVerificationScreen, RegistrationCompleteScreen |
| **Database Tables** | `auth.users` (Supabase managed), `user_profiles`, `user_devices` |
| **API Endpoints** | `supabase.auth.signInWithOtp()`, `supabase.auth.verifyOtp()`, `supabase.auth.signInWithMagicLink()` |
| **Storage Requirements** | JWT tokens → flutter_secure_storage |
| **Realtime Requirements** | None |
| **Security Requirements** | Tokens in secure storage; OTP expiry enforced; session rotation |
| **Potential Risks** | OTP delivery failures (carrier issues); deep link handling on iOS |

**Acceptance Criteria:**
- User can register with phone number and verify OTP
- User can register with email and verify magic link
- Session persists between app launches
- Logout clears all local sensitive data

---

### FEAT-002: Signal Protocol Key Management

| Property | Value |
|---|---|
| **Priority** | P0 (Critical — required before pairing) |
| **Description** | Generate identity keys, signed prekeys, and one-time prekeys; publish to server; manage sessions |
| **Complexity** | High |
| **Estimated Dev Time** | 4 days |
| **Dependencies** | FEAT-001 (Auth) |
| **Related Screens** | No dedicated screen (background operation) |
| **Database Tables** | `user_prekey_bundles`, `user_identity_keys`, `signal_sessions` |
| **API Endpoints** | `user_prekey_bundles` INSERT/SELECT, `user_identity_keys` INSERT |
| **Storage Requirements** | Private keys → flutter_secure_storage; session state → flutter_secure_storage |
| **Realtime Requirements** | None |
| **Security Requirements** | Private keys never leave device; prekeys deleted after use |
| **Potential Risks** | libsignal Flutter bindings stability; session re-establishment after reinstall |

---

### FEAT-003: Pairing System

| Property | Value |
|---|---|
| **Priority** | P0 (Critical) |
| **Description** | Generate invite code; partner enters code; pair established; Signal session initiated |
| **Complexity** | Medium |
| **Estimated Dev Time** | 2 days |
| **Dependencies** | FEAT-001, FEAT-002 |
| **Related Screens** | GenerateInviteScreen, EnterInviteScreen, PairingSuccessScreen |
| **Database Tables** | `pairs`, `pair_invite_codes` |
| **API Endpoints** | `pair_invite_codes` INSERT/SELECT/DELETE, `pairs` INSERT |
| **Storage Requirements** | Pair ID → secure storage (frequently needed) |
| **Realtime Requirements** | Subscription on `pairs` table to detect partner's acceptance |
| **Security Requirements** | Invite code is single-use and time-limited; RLS enforces pair membership |
| **Potential Risks** | Race condition if both users generate codes simultaneously |

---

### FEAT-004: Chat — Send & Receive Text

| Property | Value |
|---|---|
| **Priority** | P0 (Core product) |
| **Description** | Compose and send encrypted text messages; receive and display decrypted messages in real-time |
| **Complexity** | High |
| **Estimated Dev Time** | 5 days |
| **Dependencies** | FEAT-001, FEAT-002, FEAT-003 |
| **Related Screens** | ChatScreen, MessageBubbleWidget, MessageInputWidget |
| **Database Tables** | `messages` (remote, encrypted), `local_messages` (SQLite, decrypted) |
| **API Endpoints** | `messages` INSERT/SELECT; Realtime subscription |
| **Storage Requirements** | SQLite via Drift for decrypted local messages |
| **Realtime Requirements** | Supabase Realtime subscription on `messages` filtered by pair_id |
| **Security Requirements** | Message encrypted before INSERT; decrypted only on receive; server sees only ciphertext |
| **Potential Risks** | Signal session desync between devices; message ordering with concurrent sends |

---

### FEAT-005: Message Status Tracking

| Property | Value |
|---|---|
| **Priority** | P0 |
| **Description** | Track message lifecycle: pending → sending → sent → delivered → read |
| **Complexity** | Medium |
| **Estimated Dev Time** | 2 days |
| **Dependencies** | FEAT-004 |
| **Related Screens** | ChatScreen (status icons on bubbles) |
| **Database Tables** | `messages.status` column, `message_receipts` |
| **API Endpoints** | `message_receipts` INSERT; `messages` UPDATE status; Realtime subscription |
| **Storage Requirements** | Status in local SQLite |
| **Realtime Requirements** | Realtime subscription on `message_receipts` for this pair |
| **Security Requirements** | Only pair members can update receipts |
| **Potential Risks** | Race conditions on status updates; read receipt privacy setting |

---

### FEAT-006: Typing Indicator

| Property | Value |
|---|---|
| **Priority** | P1 |
| **Description** | Show animated typing indicator when partner is composing a message |
| **Complexity** | Low |
| **Estimated Dev Time** | 1 day |
| **Dependencies** | FEAT-004, FEAT-003 (pair_id needed) |
| **Related Screens** | ChatScreen (indicator in header or above input) |
| **Database Tables** | None (presence only) |
| **API Endpoints** | Supabase Realtime Presence channel |
| **Storage Requirements** | None |
| **Realtime Requirements** | Presence channel per pair_id |
| **Security Requirements** | Presence events only visible to pair members (channel name includes pair_id) |
| **Potential Risks** | Stale typing state if app crashes during composition |

---

### FEAT-007: Message Reactions

| Property | Value |
|---|---|
| **Priority** | P1 |
| **Description** | Long-press a message to react with emoji; both users see reactions in real-time |
| **Complexity** | Low |
| **Estimated Dev Time** | 2 days |
| **Dependencies** | FEAT-004 |
| **Related Screens** | ChatScreen (reaction picker overlay, reaction badges on bubbles) |
| **Database Tables** | `message_reactions` |
| **API Endpoints** | `message_reactions` INSERT/DELETE; Realtime subscription |
| **Storage Requirements** | Reactions in local SQLite |
| **Realtime Requirements** | Realtime subscription on `message_reactions` for this pair |
| **Security Requirements** | Only pair members can react |
| **Potential Risks** | Reaction picker UX on small screens |

---

### FEAT-008: Edit & Delete Messages

| Property | Value |
|---|---|
| **Priority** | P1 |
| **Description** | Edit own message within 15 min; delete own message for both sides |
| **Complexity** | Medium |
| **Estimated Dev Time** | 2 days |
| **Dependencies** | FEAT-004 |
| **Related Screens** | ChatScreen (long-press context menu) |
| **Database Tables** | `messages` (UPDATE ciphertext, edited_at, deleted_at) |
| **API Endpoints** | `messages` UPDATE, DELETE; Realtime subscription |
| **Storage Requirements** | Local SQLite update |
| **Realtime Requirements** | Realtime subscription on UPDATE events on `messages` |
| **Security Requirements** | RLS: only sender can edit/delete their own message; new ciphertext encrypted |
| **Potential Risks** | Edit window enforcement (15 min) must be server-side, not just client-side |

---

### FEAT-009: Disappearing Messages

| Property | Value |
|---|---|
| **Priority** | P1 |
| **Description** | Auto-delete messages after configurable duration; both sides agree on timer |
| **Complexity** | Medium |
| **Estimated Dev Time** | 2 days |
| **Dependencies** | FEAT-004 |
| **Related Screens** | ChatScreen (timer icon on messages), DisappearingMessageSettingsScreen |
| **Database Tables** | `pairs.disappearing_message_duration`, `messages.expires_at` |
| **API Endpoints** | `pairs` UPDATE; Supabase Edge Function for cleanup |
| **Storage Requirements** | None (cleanup is server-side) |
| **Realtime Requirements** | `pairs` UPDATE subscription to detect timer change |
| **Security Requirements** | Timer enforced server-side; local DB also purges on expiry |
| **Potential Risks** | Clock skew between devices; cleanup job reliability |

---

### FEAT-010: Media — Images

| Property | Value |
|---|---|
| **Priority** | P1 |
| **Description** | Send and receive encrypted images from camera or gallery |
| **Complexity** | High |
| **Estimated Dev Time** | 3 days |
| **Dependencies** | FEAT-004 |
| **Related Screens** | ChatScreen (image bubbles), ImageViewerScreen |
| **Database Tables** | `messages` (ciphertext includes encrypted media key + storage path) |
| **Storage Requirements** | Supabase Storage (encrypted blob); local cache in app-private dir |
| **Realtime Requirements** | Via message delivery (same as text) |
| **Security Requirements** | AES-256-GCM per-file encryption; media key in message ciphertext |
| **Potential Risks** | Upload failures; large image handling; iOS/Android permission differences |

---

### FEAT-011: Media — Voice Messages

| Property | Value |
|---|---|
| **Priority** | P1 |
| **Description** | Record, send, and play back voice messages |
| **Complexity** | Medium |
| **Estimated Dev Time** | 3 days |
| **Dependencies** | FEAT-010 |
| **Related Screens** | ChatScreen (hold-to-record button, voice bubble with waveform) |
| **Storage Requirements** | Supabase Storage (encrypted); local cache |
| **Security Requirements** | Same as images |
| **Potential Risks** | Background recording permission; audio format compatibility |

---

### FEAT-012: Push Notifications

| Property | Value |
|---|---|
| **Priority** | P0 |
| **Description** | Receive FCM push notifications for new messages; handle all app states |
| **Complexity** | Medium |
| **Estimated Dev Time** | 2 days |
| **Dependencies** | FEAT-004, Supabase Edge Function |
| **Related Screens** | No new screen; navigation on tap |
| **Database Tables** | `user_devices` (FCM token per device) |
| **Storage Requirements** | FCM token in secure storage |
| **Realtime Requirements** | None (FCM is the realtime transport for background) |
| **Security Requirements** | Message content never in push payload; token rotated on refresh |
| **Potential Risks** | FCM token refresh handling; iOS push permission UX; Android 13+ notification permission |

---

### FEAT-013: User Profile

| Property | Value |
|---|---|
| **Priority** | P1 |
| **Description** | Set display name and avatar; view partner profile |
| **Complexity** | Low |
| **Estimated Dev Time** | 2 days |
| **Dependencies** | FEAT-001 |
| **Related Screens** | ProfileScreen, EditProfileScreen, PartnerProfileScreen |
| **Database Tables** | `user_profiles` |
| **Storage Requirements** | Avatar → Supabase Storage (not encrypted; shared with partner) |
| **Realtime Requirements** | Realtime subscription on `user_profiles` to detect partner name/avatar change |
| **Security Requirements** | RLS: only pair members can read each other's profile |
| **Potential Risks** | Image cropping UX |

---

### FEAT-014: Partner Presence

| Property | Value |
|---|---|
| **Priority** | P1 |
| **Description** | Show partner's online status and last seen |
| **Complexity** | Low |
| **Estimated Dev Time** | 1 day |
| **Dependencies** | FEAT-003 |
| **Related Screens** | ChatScreen header |
| **Database Tables** | `user_presence` (updated on app foreground/background events) |
| **Realtime Requirements** | Supabase Realtime presence or table subscription |
| **Security Requirements** | Visible only to pair member |
| **Potential Risks** | Battery drain from frequent presence updates |

---

### FEAT-015: App Lock

| Property | Value |
|---|---|
| **Priority** | P1 |
| **Description** | Biometric or PIN lock with auto-lock after inactivity |
| **Complexity** | Medium |
| **Estimated Dev Time** | 2 days |
| **Dependencies** | FEAT-001 |
| **Related Screens** | AppLockScreen, SetupPinScreen, BiometricSetupScreen |
| **Database Tables** | None |
| **Storage Requirements** | PIN hash → flutter_secure_storage; lock settings → flutter_secure_storage |
| **Realtime Requirements** | None |
| **Security Requirements** | PIN hashed with bcrypt; biometric uses OS APIs; no content visible on lock screen |
| **Potential Risks** | Biometric availability varies by device; PIN recovery scenario |

---

### FEAT-016: Settings

| Property | Value |
|---|---|
| **Priority** | P1 |
| **Description** | All user-configurable settings: notifications, privacy, security, account |
| **Complexity** | Low |
| **Estimated Dev Time** | 2 days |
| **Dependencies** | FEAT-001, FEAT-012, FEAT-015 |
| **Related Screens** | SettingsScreen (multiple sub-screens) |
| **Database Tables** | `user_settings` |
| **Storage Requirements** | Settings cached in SharedPreferences (non-sensitive) and Supabase |
| **Realtime Requirements** | None |
| **Security Requirements** | Sensitive settings (app lock) in secure storage |
| **Potential Risks** | Settings sync between devices (user has one phone — not an issue for V1) |

---

### FEAT-017: Offline Mode & Message Queue

| Property | Value |
|---|---|
| **Priority** | P1 |
| **Description** | Queue messages when offline; sync on reconnect; graceful offline UI |
| **Complexity** | Medium |
| **Estimated Dev Time** | 2 days |
| **Dependencies** | FEAT-004 |
| **Related Screens** | ChatScreen (offline banner, queued status indicator) |
| **Database Tables** | `outbox_queue` (local SQLite only) |
| **Storage Requirements** | Local SQLite |
| **Realtime Requirements** | ConnectivityService observes network state |
| **Security Requirements** | Queued messages already encrypted before storage |
| **Potential Risks** | Out-of-order message delivery; Signal ratchet state consistency |

---

### FEAT-018: Message Search

| Property | Value |
|---|---|
| **Priority** | P2 |
| **Description** | Full-text search over local decrypted message history |
| **Complexity** | Low |
| **Estimated Dev Time** | 1 day |
| **Dependencies** | FEAT-004 |
| **Related Screens** | SearchScreen, ChatScreen (jump to result) |
| **Database Tables** | SQLite FTS5 virtual table |
| **Storage Requirements** | Local SQLite only |
| **Realtime Requirements** | None |
| **Security Requirements** | Search entirely local; no query sent to server |
| **Potential Risks** | FTS5 index performance for large message histories |

---

### FEAT-019: Chat Export

| Property | Value |
|---|---|
| **Priority** | P2 |
| **Description** | Export decrypted chat history as PDF (local only, never uploaded) |
| **Complexity** | Low |
| **Estimated Dev Time** | 1 day |
| **Dependencies** | FEAT-004 |
| **Related Screens** | SettingsScreen (Export option) |
| **Storage Requirements** | Exported file in app documents directory; shared via OS share sheet |
| **Security Requirements** | File created locally only; user chooses where to save via share sheet |

---

### FEAT-020: Account Deletion

| Property | Value |
|---|---|
| **Priority** | P1 |
| **Description** | Delete account and all associated server data |
| **Complexity** | Medium |
| **Estimated Dev Time** | 1 day |
| **Dependencies** | All features |
| **Related Screens** | DeleteAccountScreen (confirmation flow) |
| **Database Tables** | All tables (CASCADE delete) |
| **Storage Requirements** | Local storage wiped |
| **Realtime Requirements** | Partner notified via push |
| **Security Requirements** | All keys and tokens deleted; data purged from server within 24h |
| **Potential Risks** | Cascading delete performance; FCM token revocation |

---

## Development Priority Summary

| Priority | Features |
|---|---|
| P0 (Must have — MVP) | Auth, Signal Protocol Keys, Pairing, Send/Receive Text, Message Status, Push Notifications |
| P1 (Should have — V1) | Typing, Reactions, Edit/Delete, Disappearing Messages, Media, Profile, Presence, App Lock, Settings, Offline Mode, Account Deletion |
| P2 (Nice to have — V1.1) | Message Search, Chat Export, Video Messages |
