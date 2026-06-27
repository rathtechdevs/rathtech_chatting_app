# 07 — User Flows

## Purpose
Define every user journey through the app — from first launch to complex interactions. Each flow includes decision points, error paths, and success outcomes.

---

## 1. First Launch Flow

```
App Launch
    │
    ▼
SplashScreen (check auth + pair status)
    │
    ├── Has valid JWT + is paired?
    │       └── YES → Check app lock setting
    │               ├── Lock enabled → AppLockScreen
    │               └── Lock disabled → ChatScreen
    │
    ├── Has valid JWT + NOT paired?
    │       └── YES → PairingScreen (Generate/Enter invite code)
    │
    └── No valid JWT (or expired)
            └── LoginScreen
```

---

## 2. Registration Flow

```
LoginScreen
    │
    ├── Tab: Phone Number
    │       │
    │       ▼
    │   Enter Phone Number (E.164 format)
    │       │
    │       ▼
    │   [Request OTP]
    │       │
    │       ├── Success → OtpVerificationScreen
    │       │               │
    │       │               ├── Enter 6-digit OTP
    │       │               │       ├── Valid + new user → ProfileSetupScreen
    │       │               │       ├── Valid + existing user → [Resume login flow]
    │       │               │       └── Invalid → Show error, allow retry (max 3)
    │       │               │
    │       │               └── OTP expired → [Show resend button after 60s]
    │       │
    │       └── Error (carrier fail) → Show error + "Try email instead" option
    │
    └── Tab: Email Magic Link
            │
            ▼
        Enter Email Address
            │
            ▼
        [Send Magic Link]
            │
            └── "Check your email" screen
                    │
                    └── (User taps link in email)
                            │
                            ▼
                        Deep link opens app → Authenticated
                                │
                                ├── New user → ProfileSetupScreen
                                └── Existing user → [Resume login flow]
```

---

## 3. Profile Setup Flow

```
ProfileSetupScreen
    │
    ├── Enter Display Name (required)
    ├── Upload Avatar (optional)
    │       ├── Camera → capture → crop → preview → confirm
    │       └── Gallery → pick → crop → preview → confirm
    │
    └── [Save Profile]
            │
            ▼
        Signal Protocol key generation (background)
            │
            ▼
        Publish public keys to Supabase
            │
            ▼
        PairingScreen
```

---

## 4. Pairing Flow

### 4.1 Inviter Flow (User A)

```
PairingScreen
    │
    └── Tab: Invite Partner
            │
            ▼
        [Generate Invite Code]
            │
            ▼
        InviteCodeScreen
            ├── Display 8-char code (large, copyable)
            ├── [Share] → OS share sheet
            ├── Countdown timer (48h expiry shown)
            └── Realtime subscription watching for partner acceptance
                    │
                    └── Partner accepts → Both navigate to ChatScreen
```

### 4.2 Invitee Flow (User B)

```
PairingScreen
    │
    └── Tab: Enter Code
            │
            ▼
        Enter 8-char code
            │
            ▼
        [Connect]
            │
            ├── Code valid → X3DH key exchange initiation
            │               │
            │               ▼
            │           PairingSuccessScreen
            │               │
            │               └── [Start Chatting] → ChatScreen
            │
            ├── Code invalid → Error message, allow retry
            ├── Code expired → "Code expired, ask partner to generate a new one"
            └── Code is own code → "You cannot connect with yourself"
```

---

## 5. Main Chat Flow

### 5.1 Send Text Message

```
ChatScreen (message input focused)
    │
    ├── Type message
    │
    └── Tap Send button (or return key)
            │
            ▼
        Optimistic insert: message appears with "sending" spinner
            │
            ▼
        EncryptionService.encrypt(text) → ciphertext
            │
            ▼
        POST to Supabase messages table
            │
            ├── Success → message status → "sent" (checkmark)
            │           → partner receives via Realtime → "delivered" (double checkmark)
            │           → partner reads → "read" (blue double checkmark)
            │
            └── Failure → message status → "failed" with retry button
```

### 5.2 Receive Text Message

```
Supabase Realtime INSERT event received
    │
    ▼
MessageRepository.decrypt(ciphertext) → plaintext
    │
    ▼
Insert to local SQLite (decrypted)
    │
    ▼
Riverpod StreamProvider emits updated list
    │
    ▼
ChatScreen auto-scrolls to new message (if user is at bottom)
    │
    ▼
ReadReceiptUseCase sends "read" receipt
```

### 5.3 Send Image

```
ChatScreen — tap attachment button → ImagePickerBottomSheet
    │
    ├── Camera → take photo → preview
    └── Gallery → pick photo → preview
            │
            ▼
        [Confirm Send]
            │
            ▼
        Compress image (≤ 2MB)
            │
            ▼
        Generate per-file AES-256 key
            │
            ▼
        Encrypt image with AES key
            │
            ▼
        Upload encrypted blob to Supabase Storage
            │
            ▼
        Encrypt AES key + storage path with Signal Protocol
            │
            ▼
        POST ciphertext (containing key + path) to messages table
            │
            ▼
        ChatScreen shows image thumbnail
```

---

## 6. App Lock Flow

### 6.1 App Goes to Background

```
App enters background
    │
    ▼
AppLockService.startInactivityTimer()
    │
    └── Timer fires (based on user setting)
            │
            ▼
        AppLockOverlay displayed over all content
        (content not visible)
```

### 6.2 User Returns to App

```
App comes to foreground
    │
    ├── App lock is enabled?
    │       └── YES → Show AppLockScreen
    │               │
    │               ├── Biometric → local_auth.authenticate()
    │               │       ├── Success → Dismiss lock → Show last screen
    │               │       └── Failure → Show PIN fallback
    │               │
    │               └── PIN → Enter 6-digit PIN
    │                       ├── Correct → Dismiss lock
    │                       └── Wrong → Show attempt counter
    │                               └── 5 fails → 30s cooldown
    │
    └── App lock disabled → Resume directly
```

---

## 7. Disappearing Messages Flow

```
[User A changes timer in chat settings]
    │
    ▼
System message sent: "User A set messages to disappear after 24 hours"
    │
    ▼
User B sees system message + must confirm
    │
    ├── Confirm → Timer applied to future messages
    └── Decline → Timer stays as-is, User A notified
```

### Timer execution

```
Message received by User B
    │
    ▼
expires_at = now + timer_duration set in DB
    │
    ▼
[Supabase Edge Function runs every hour]
    │
    ▼
DELETE messages WHERE expires_at < NOW()
    │
    ▼
[Realtime subscription fires DELETE event]
    │
    ▼
Both devices remove message from local SQLite
```

---

## 8. Account Deletion Flow

```
Settings → Account → Delete Account
    │
    ▼
DeleteAccountScreen
    │
    ├── Show warning: "This action is permanent"
    ├── Show checklist of what will be deleted
    └── Type "DELETE MY ACCOUNT" to confirm
            │
            └── [Delete Account] button enabled
                    │
                    ▼
                Send delete request to Supabase Edge Function
                    │
                    ├── Delete all messages (via cascade)
                    ├── Delete media from Supabase Storage
                    ├── Delete Signal Protocol keys (server-side public keys)
                    ├── Delete pair record
                    ├── Delete user_profile record
                    ├── Call supabase.auth.admin.deleteUser()
                    └── Notify partner via FCM
                            │
                            ▼
                        Local: clear SQLite, secure storage, SharedPreferences
                            │
                            ▼
                        Navigate to LoginScreen
```

---

## 9. Settings Flows

### Notification Mute
```
Settings → Notifications → Mute Notifications
    → Choose duration: 1h | 8h | 24h | Forever
    → Mute applied (FCM notifications still delivered; app suppresses display)
```

### Last Seen Privacy
```
Settings → Privacy → Last Seen
    → Toggle: Show to partner | Hide
    → Change synced to Supabase user_settings
```

### Chat Background
```
ChatScreen → Settings icon → Chat Background
    → Grid of theme options (curated colors + patterns)
    → Custom: pick from gallery
    → Preview applied immediately
    → Saved to SharedPreferences
```

---

## 10. Offline State Flow

```
Network disconnects
    │
    ▼
ConnectivityService emits disconnected
    │
    ▼
OfflineBanner shown in ChatScreen
    │
    ▼
User types and taps send
    │
    ▼
Message encrypted → saved to OutboxQueue (SQLite)
    │
    ▼
Message shown with "queued" icon
    │
    ▼
[Network reconnects]
    │
    ▼
ConnectivityService emits connected
    │
    ▼
OfflineBanner dismissed
    │
    ▼
OutboxQueue flushed → messages sent in order
    │
    ▼
Statuses updated: queued → sent → delivered
```
