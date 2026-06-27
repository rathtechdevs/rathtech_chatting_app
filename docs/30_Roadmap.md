# 30 — Development Roadmap

## Purpose
Define milestones, deliverables, dependencies, and timelines for building SecureChat. This is the master development plan.

---

## 1. Milestone Overview

| Milestone | Name | Duration | Goal |
|---|---|---|---|
| M0 | Foundation | 3 days | Project setup, dependencies, architecture scaffold |
| M1 | Authentication | 3 days | Registration, login, session management |
| M2 | Encryption Core | 4 days | Signal Protocol integration |
| M3 | Pairing System | 2 days | Invite code flow |
| M4 | Core Messaging | 5 days | Send, receive, real-time text messages |
| M5 | Message Features | 4 days | Status, reactions, edit, delete, search |
| M6 | Media | 5 days | Images, voice messages |
| M7 | Notifications | 2 days | FCM push, local notifications |
| M8 | Profile & Presence | 2 days | User profile, partner online status |
| M9 | App Lock | 2 days | Biometric/PIN lock |
| M10 | Settings | 2 days | All settings screens |
| M11 | Offline Support | 2 days | Queue, gap fill, connectivity UI |
| M12 | Polish & Testing | 4 days | Bug fixes, performance, test coverage |
| M13 | Release Preparation | 2 days | Deployment, App Store submission |

**Total Estimated Duration: 42 days (approximately 8–9 weeks)**

---

## 2. Milestone Details

### M0: Foundation (3 days)

**Objectives:**
- Set up pubspec.yaml with all dependencies
- Create complete folder structure
- Configure analysis_options.yaml
- Wire main.dart with Riverpod + GoRouter
- Set up core layer (failures, logger, constants)
- Initialize Supabase + Firebase in app
- Set up Drift database with migrations

**Deliverables:**
- `pubspec.yaml` with all packages
- Complete `lib/` folder structure (empty files)
- `lib/main.dart` → Supabase init + Riverpod ProviderScope + GoRouter
- `lib/core/` fully implemented
- `lib/app/router.dart` scaffolded
- Drift database setup

**Dependencies:** None

**Definition of Done:**
- App compiles and runs to blank screen
- `flutter analyze` zero errors
- Folder structure matches `19_Folder_Structure.md` exactly

---

### M1: Authentication (3 days)

**Objectives:**
- Phone OTP registration and login
- Email magic link registration and login
- Session persistence in secure storage
- Auth-gated GoRouter redirects
- Profile setup screen

**Deliverables:**
- `features/auth/` complete (all 3 layers)
- LoginScreen, OtpVerificationScreen, SetupProfileScreen
- Auth state stream via Riverpod
- GoRouter auth redirect working
- Signal Protocol key generation on profile creation

**Dependencies:** M0

**Definition of Done:**
- User can register with phone OTP
- User can register with email magic link
- Session persists between app restarts
- Logged-out users redirected to login; logged-in users redirected to pair/chat
- `flutter test test/unit/features/auth/` all pass

---

### M2: Encryption Core (4 days)

**Objectives:**
- Signal Protocol key generation (identity, signed prekey, one-time prekeys)
- Publish public keys to Supabase
- Store private keys in flutter_secure_storage
- EncryptionService implementation
- X3DH key exchange (initiation + completion)

**Deliverables:**
- `lib/core/encryption/` complete
- `user_identity_keys` and `user_prekey_bundles` tables seeded after registration
- `EncryptionService` with `encrypt()` and `decrypt()`
- Signal Protocol session initialized on first message send

**Dependencies:** M1

**Definition of Done:**
- Keys generated, published, and stored correctly
- `encrypt(plaintext)` → decrypt(ciphertext)` → original plaintext (verified by test)
- Private keys verified to be in secure storage, not SQLite or SharedPreferences
- All encryption unit tests pass

---

### M3: Pairing System (2 days)

**Objectives:**
- Generate invite code (User A)
- Accept invite code (User B via Edge Function)
- Signal session established after pairing
- GoRouter pair-gated redirects

**Deliverables:**
- `features/pairing/` complete
- PairScreen, GenerateInviteScreen, EnterInviteScreen
- `accept-invite-code` Supabase Edge Function deployed
- Realtime subscription for pair acceptance notification (User A sees it live)

**Dependencies:** M1, M2

**Definition of Done:**
- User A generates code; User B enters it; both navigate to chat screen
- Signal Protocol X3DH completed automatically after pairing
- Unpaired users cannot access chat screen (router redirect enforced)

---

### M4: Core Messaging (5 days)

**Objectives:**
- Send encrypted text messages
- Receive and decrypt messages via Realtime
- Message list (paginated, scrollable)
- Optimistic UI
- Local SQLite storage

**Deliverables:**
- `features/chat/` — all 3 layers for text messaging
- ChatScreen with message list + input bar
- MessageBubble widget (text variant)
- Supabase Realtime subscription for new messages
- Drift local database for decrypted messages
- Pagination (scroll to top loads more)

**Dependencies:** M3

**Definition of Done:**
- User A sends message; User B receives it in < 500ms
- Messages decrypted and readable
- Server stores only ciphertext (verified manually in Supabase dashboard)
- Offline: message queued; online: sent
- All message unit tests pass

---

### M5: Message Features (4 days)

**Objectives:**
- Message status (sending/sent/delivered/read)
- Typing indicator
- Message reactions
- Edit message (within 15 min)
- Delete message (both sides)
- Disappearing messages

**Deliverables:**
- Message status icons in chat
- Typing indicator (animated dots)
- Reaction picker and badges
- Long-press context menu
- Edit and delete flows
- DisappearingMessage settings screen
- `cleanup-expired-messages` Edge Function

**Dependencies:** M4

**Definition of Done:**
- All message status transitions observable
- Typing indicator shows/hides correctly
- React, edit, delete all work on both devices in real-time
- Disappearing messages auto-delete via Edge Function

---

### M6: Media (5 days)

**Objectives:**
- Send images (camera + gallery)
- Image encryption before upload
- Image thumbnail in chat + full-screen viewer
- Voice message recording
- Voice message playback with waveform

**Deliverables:**
- `features/media/` complete
- Image picker integration
- AES-256-GCM media encryption
- Supabase Storage upload/download
- ImageViewerScreen (Hero animation)
- Voice recorder widget (hold to record)
- Voice message bubble with waveform

**Dependencies:** M4

**Definition of Done:**
- Images encrypted before upload (verified: raw Storage file is binary gibberish)
- Image received by partner and displayed correctly
- Voice messages recorded, encrypted, uploaded, received, and played back
- Media cached locally after first download

---

### M7: Notifications (2 days)

**Objectives:**
- FCM token registration on login
- `send-push-notification` Edge Function
- Handle notifications in all app states
- Notification privacy (no content in payload)
- Android notification channel

**Deliverables:**
- FCM integration (android + ios)
- `send-push-notification` Supabase Edge Function deployed
- Background message handler
- Tap notification → navigate to chat
- Notification permission request flow

**Dependencies:** M4

**Definition of Done:**
- Push notification received when app is terminated (tested on real device)
- Notification body never contains message content
- Tapping notification opens correct chat
- Mute settings respected by Edge Function

---

### M8: Profile & Presence (2 days)

**Objectives:**
- Edit own profile (name, avatar)
- View partner profile
- Partner online/offline status
- Last seen timestamp

**Deliverables:**
- MyProfileScreen, PartnerProfileScreen
- Avatar upload to Supabase Storage
- Supabase Realtime presence for online status
- Last seen update on app background/foreground

**Dependencies:** M1, M3

**Definition of Done:**
- Profile update reflected for partner in real-time
- Online status shows correctly
- Last seen timestamp updated when partner goes offline

---

### M9: App Lock (2 days)

**Objectives:**
- Biometric lock (fingerprint/Face ID)
- PIN lock (6-digit)
- Auto-lock on inactivity
- Lock screen shows no content

**Deliverables:**
- AppLockScreen
- local_auth integration
- AppLockService (inactivity timer)
- GoRouter integration (lock screen overlay)
- SetupPinScreen

**Dependencies:** M1

**Definition of Done:**
- Lock activates on app background or inactivity timer
- Biometric unlock works on supported devices
- PIN unlock works as fallback
- No message content visible behind lock screen

---

### M10: Settings (2 days)

**Objectives:**
- Notification settings (mute, sound)
- Privacy settings (last seen, read receipts, typing)
- Chat settings (background, disappearing timer)
- Security settings (app lock)
- Account settings (export chat, delete account)

**Deliverables:**
- All settings screens
- Settings synced to Supabase `user_settings`
- Chat export (PDF) — local only
- `delete-account` Edge Function

**Dependencies:** M1, M7, M9

**Definition of Done:**
- All settings persist between app restarts
- Privacy settings respected (read receipts sent only if enabled)
- Account deletion removes all server data (verified in Supabase dashboard)

---

### M11: Offline Support (2 days)

**Objectives:**
- Offline banner UI
- Outbox queue
- Gap fill on reconnect
- Realtime reconnection handling

**Deliverables:**
- ConnectivityService
- OutboxQueue SQLite table
- GapFillService
- OfflineBanner widget
- Queued message status indicator

**Dependencies:** M4

**Definition of Done:**
- Messages composed offline sent on reconnect (in order)
- Gap fill fetches missed messages after reconnect
- Offline banner appears/disappears smoothly

---

### M12: Polish & Testing (4 days)

**Objectives:**
- Full test suite for all layers
- Performance profiling
- UI polish (animations, edge cases)
- Accessibility audit
- Dark mode verification

**Deliverables:**
- Test coverage at or above targets
- Performance metrics within bounds
- All known bugs fixed
- Animation system complete
- Accessibility labels on all interactive elements

**Definition of Done:**
- `flutter test` passes 100%
- Cold start < 2s on mid-range Android
- `flutter analyze` zero warnings

---

### M13: Release Preparation (2 days)

**Objectives:**
- Production Supabase setup
- App signing for both platforms
- App Store / Play Store submission materials
- Privacy policy and terms of service

**Definition of Done:**
- App submitted to Google Play (internal test track)
- App submitted to App Store (TestFlight)
- All release checklist items verified

---

## 3. Dependency Graph

```
M0 (Foundation)
└── M1 (Auth)
    ├── M2 (Encryption)
    │   └── M3 (Pairing)
    │       └── M4 (Core Messaging)
    │           ├── M5 (Message Features)
    │           ├── M6 (Media)
    │           ├── M7 (Notifications)
    │           └── M11 (Offline Support)
    ├── M8 (Profile & Presence)
    ├── M9 (App Lock)
    └── M10 (Settings)
        └── M12 (Polish)
            └── M13 (Release)
```

**Parallelizable:** After M4 is complete, M5, M6, M7, M8, M9, M10, and M11 can be worked on in parallel (if multiple developers are available). For a solo developer, implement in the order listed.
