# 10 — Security Architecture

## Purpose
Define the complete security model for SecureChat — threat model, attack surfaces, defenses, key management, and compliance requirements.

---

## 1. Threat Model

### 1.1 Assets to Protect

| Asset | Sensitivity | Location |
|---|---|---|
| Message plaintext | Critical | Client device only (never server) |
| Private keys (Signal) | Critical | flutter_secure_storage (Keychain/Keystore) |
| JWT tokens | High | flutter_secure_storage |
| Media files (decrypted) | High | App-private directory (encrypted at rest) |
| User profile (name, avatar) | Medium | Supabase (partner-visible, not public) |
| FCM token | Medium | Supabase `user_devices` table |
| Metadata (timestamps, pair existence) | Low | Supabase |

### 1.2 Threat Actors

| Actor | Capability | Threat |
|---|---|---|
| Network attacker (MITM) | Can intercept traffic | Steal session tokens; inject messages |
| Supabase administrator | Full database access | Read encrypted blobs (cannot decrypt) |
| Malicious app on same device | Sandboxing bypass | Access shared storage |
| Physical device access | Device in attacker's hands | Unlock app; read data |
| Compromised partner device | Partner's device taken | Read all messages |
| Malicious invite code | Social engineering | Force join wrong pair |

### 1.3 Threat Mitigations

| Threat | Mitigation |
|---|---|
| MITM | TLS 1.3; certificate pinning in production |
| Server reads messages | E2E encryption; server only stores ciphertext |
| Token theft | Tokens in flutter_secure_storage; short-lived access tokens |
| Shared storage access | App-private directories only; SQLite encrypted |
| Physical device access | App lock (biometric/PIN); lock screen shows no content |
| Compromised partner | Signal Protocol: forward secrecy limits exposure |
| Social engineering pair | Invite code expiry; single use; confirmation screen |

---

## 2. Encryption Layers

### Layer 1: Transport Security (TLS 1.3)
All communication between app and Supabase is over HTTPS (TLS 1.3). Supabase enforces this. Certificate pinning adds defense against proxy interception.

### Layer 2: Application-Level E2E Encryption (Signal Protocol)
Messages are encrypted on the sender's device with the Signal Protocol (Double Ratchet + X3DH) before any network transmission. Supabase only ever receives ciphertext.

### Layer 3: Media File Encryption (AES-256-GCM)
Media files are encrypted per-file with a unique AES-256-GCM key before upload to Supabase Storage. The AES key is itself encrypted within the Signal Protocol message ciphertext.

### Layer 4: Local Storage Encryption
- SQLite: encrypted using SQLCipher (or per-record encryption via Drift custom column)
- Secure storage: OS-backed (Keychain on iOS, Keystore on Android)

---

## 3. Key Management

### 3.1 Signal Protocol Keys

```
Key Hierarchy:
  Identity Key Pair (permanent — device lifetime)
  └── Signed Prekey Pair (rotated every 30 days)
      └── One-Time Prekey Pairs (batch of 100, consumed one per X3DH)
          └── Session Keys (derived via X3DH; rotated by Double Ratchet)
              └── Message Keys (unique per message — NEVER reused)
```

**Generation:**
- All key pairs generated on-device using libsignal's Curve25519 implementation
- Never generated or stored on the server

**Storage:**
- Private keys: `flutter_secure_storage` with `accessibility: KeychainAccessibility.firstUnlock` on iOS, hardware-backed on Android
- Public keys: Supabase `user_identity_keys` and `user_prekey_bundles` tables
- Session state: `flutter_secure_storage` as serialized binary blob

**Rotation:**
- Identity key: Never rotated (rotation would break existing session)
- Signed prekey: Rotated every 30 days; previous retained for 7 days for in-transit messages
- One-time prekeys: Refilled when supply drops below 10; empty supply falls back to signed prekey

**Deletion:**
- All private keys deleted on logout
- All private keys deleted on account deletion
- Supabase public key records deleted on account deletion

### 3.2 JWT Tokens

```
Token Lifecycle:
  Auth success → access_token (1hr) + refresh_token (30d)
      │
      ├── access_token: used in Authorization header for all API calls
      │   └── Auto-refreshed by Supabase client before expiry
      │
      └── refresh_token: used to obtain new access_token
          └── Rotated on each use
```

**Storage:** Both tokens stored in `flutter_secure_storage`:
- Key: `supabase_session`
- Value: Serialized `Session` object (JSON)

**Deletion:** On logout, `supabase.auth.signOut()` called (revokes server-side), then local secure storage entry deleted.

### 3.3 Media Encryption Keys

Each media file has a unique AES-256-GCM key:
1. Generate random 256-bit key + 96-bit IV (using `dart:math` SecureRandom)
2. Encrypt file with key
3. Include key + IV in Signal Protocol message plaintext before encryption
4. Server receives: encrypted media blob + encrypted (key+IV inside ciphertext)

The media key never appears in plaintext on the server.

---

## 4. Authentication Security

### 4.1 OTP Security
- 6-digit numeric OTP
- 5-minute expiry (enforced server-side by Supabase)
- Maximum 3 attempts per OTP session (Supabase enforced)
- Maximum 3 OTP requests per hour per phone number (Supabase enforced)

### 4.2 Magic Link Security
- Single-use link
- 1-hour expiry
- PKCE flow (Supabase default) — prevents authorization code interception

### 4.3 Session Security
- Access token: 1 hour lifetime
- Refresh token: 30 days, rotates on use
- Session bound to device (not transferable)
- All sessions invalidated on server on logout

---

## 5. Data-at-Rest Security

### 5.1 Local SQLite
Message content stored in SQLite is decrypted plaintext (needed for search). Protection:
- iOS: App sandbox + Data Protection entitlement (`NSFileProtectionComplete`)
- Android: App-private directory + Android File-Based Encryption
- Additional option: SQLCipher for explicit database encryption (added if threat model requires)

### 5.2 Media Cache
- Stored in `getApplicationDocumentsDirectory()` (app-private)
- Never in external storage or Downloads folder
- Files prefixed with random UUID names (no inference from filename)

### 5.3 Secure Storage
- iOS: Keychain with `kSecAttrAccessibleWhenUnlockedThisDeviceOnly`
- Android: EncryptedSharedPreferences backed by Android Keystore
- Contents: Signal private keys, JWT tokens, PIN hash, pair ID

---

## 6. Network Security

### 6.1 TLS
- Minimum TLS 1.2, prefer TLS 1.3
- Supabase endpoints enforce TLS
- Android `network_security_config.xml`: `cleartextTrafficPermitted = false`
- iOS `NSAppTransportSecurity`: no exceptions

### 6.2 Certificate Pinning
For production builds, Supabase API domains are certificate-pinned using `http` package with a custom `SecurityContext` or using `dio` with an interceptor.

**Pinned domains:**
- `<project>.supabase.co`
- `<project>.supabase.in` (if applicable)

**Bypass:**
- Certificate pinning not enforced in debug builds (to allow Charles Proxy for development)
- Controlled by `const bool isProd = bool.fromEnvironment('dart.vm.product')`

### 6.3 API Request Security
- All requests include `Authorization: Bearer <access_token>`
- No sensitive data in URL query parameters
- Request body always JSON (never form-encoded for sensitive data)

---

## 7. Application Security

### 7.1 Screenshot Prevention
- Android: `FLAG_SECURE` set on the Activity window
- iOS: Screen recording detection (partially possible via `UIScreen.isCaptured`)

### 7.2 Root/Jailbreak Detection
- Optionally use `flutter_jailbreak_detection` package
- V1: Log and show warning; do not block (too many false positives)
- V2: Block app on confirmed root/jailbreak

### 7.3 App Reverse Engineering
- Release builds: code obfuscation enabled (`flutter build --obfuscate --split-debug-info`)
- No hardcoded secrets in source (environment variables only)
- ProGuard/R8 rules for Android release builds

### 7.4 Deep Link Security
- Magic link callback URI validated: only `securechat://auth/callback` accepted
- GoRouter ignores unknown deep links

---

## 8. Privacy Design

### 8.1 Metadata Minimization
The server knows:
- Two user IDs are in a pair (required for routing)
- Message timestamps (required for ordering)
- Message count (unavoidable)

The server does NOT know:
- Message content
- Media content
- What kind of message (text vs. image — all sent as `message_type` enum, but content encrypted)
- Typing events (presence channels not persisted)

### 8.2 Notification Privacy
- Push notification body: "Sent you a message" — never message content
- Notification not shown if device is locked (configurable per OS)

### 8.3 Data Retention
- Messages: retained until deleted by user or disappearing timer expires
- Media: retained until manually deleted or account deleted
- Logs: No server-side message logs; Supabase access logs retained per Supabase's policy
- Account deletion: all data purged within 24 hours

---

## 9. Security Review Checklist

Before each release:
- [ ] No plaintext messages in any network request (verified by proxy test)
- [ ] No sensitive data in crash reports or logs (verified by Crashlytics config)
- [ ] All Supabase RLS policies tested with explicit deny tests
- [ ] TLS pinning working in production build (verified via proxy rejection test)
- [ ] App lock correctly obscures content (screenshot test)
- [ ] Account deletion removes all server data (verified via Supabase dashboard)
- [ ] Logout clears all local secure storage (verified by reinstall test)
- [ ] Signal Protocol session established correctly after fresh install (verified by E2E test)
