# 31 — Project Checklist

## Purpose
Master checklist tracking the completion status of every feature, component, and quality gate. Updated as development progresses.

---

## Foundation (M0)

- [ ] `pubspec.yaml` — all packages added with caret constraints
- [ ] `analysis_options.yaml` — strict lint rules configured
- [ ] `lib/core/error/failures.dart` — Failure sealed class hierarchy
- [ ] `lib/core/error/exceptions.dart` — Internal exception types
- [ ] `lib/core/error/failure_message_mapper.dart` — Failure → user message
- [ ] `lib/core/logger/app_logger.dart` — Logging abstraction
- [ ] `lib/core/constants/app_strings.dart` — All UI strings
- [ ] `lib/core/constants/app_routes.dart` — Route constants
- [ ] `lib/core/constants/storage_keys.dart` — Secure storage keys
- [ ] `lib/core/constants/animation_constants.dart` — Duration + curves
- [ ] `lib/core/theme/app_theme.dart` — Light + dark ThemeData
- [ ] `lib/core/theme/app_colors.dart` — Brand color tokens
- [ ] `lib/core/network/supabase_client_provider.dart` — Supabase singleton
- [ ] `lib/core/network/connectivity_service.dart` — Network state
- [ ] `lib/core/storage/app_database.dart` — Drift DB
- [ ] `lib/core/storage/secure_storage_provider.dart`
- [ ] `lib/core/components/` — All shared widgets
- [ ] `lib/app/router.dart` — GoRouter configuration
- [ ] `lib/app/app.dart` — MaterialApp.router root
- [ ] `lib/main.dart` — App entry point wired
- [ ] Supabase project created
- [ ] Firebase project created
- [ ] All database migration files created

---

## Authentication (M1)

- [ ] `PhoneNumber` value object with tests
- [ ] `EmailAddress` value object with tests
- [ ] `OtpCode` value object with tests
- [ ] `AuthRepository` interface
- [ ] `AuthRepositoryImpl` with tests
- [ ] `AuthRemoteDataSource` (Supabase auth calls)
- [ ] `AuthSecureDataSource` (token storage)
- [ ] `RequestOtpUseCase` with tests
- [ ] `VerifyOtpUseCase` with tests
- [ ] `RequestMagicLinkUseCase` with tests
- [ ] `LogoutUseCase` with tests
- [ ] `authStateProvider` stream
- [ ] `LoginViewModel` with tests
- [ ] LoginScreen (phone + email tabs)
- [ ] OtpVerificationScreen
- [ ] MagicLinkSentScreen
- [ ] SetupProfileScreen
- [ ] GoRouter auth guard
- [ ] Magic link deep link handling (Android + iOS)
- [ ] Session persistence to flutter_secure_storage
- [ ] Age verification (18+) in profile setup
- [ ] `user_profiles` table + RLS policies
- [ ] `user_settings` table + RLS policies

---

## Encryption Core (M2)

- [ ] `EncryptionService` abstract interface
- [ ] `SignalEncryptionService` implementation
- [ ] `KeyStorageService` (private key CRUD)
- [ ] Identity key pair generation + storage
- [ ] Signed prekey generation + storage + publishing
- [ ] One-time prekey batch generation + publishing
- [ ] `user_identity_keys` table + RLS
- [ ] `user_prekey_bundles` table + RLS
- [ ] `claim-prekey` Edge Function
- [ ] X3DH initiation (User A sends first message)
- [ ] X3DH completion (User B receives first message)
- [ ] Double Ratchet session persistence
- [ ] Encryption unit tests (encrypt → decrypt roundtrip)
- [ ] Key deletion on logout
- [ ] Key deletion on account deletion

---

## Pairing (M3)

- [ ] `PairCode` value object with tests
- [ ] `Pair` entity
- [ ] `PairingRepository` interface
- [ ] `PairingRepositoryImpl` with tests
- [ ] `GenerateInviteCodeUseCase` with tests
- [ ] `AcceptInviteCodeUseCase` with tests
- [ ] `GetCurrentPairUseCase`
- [ ] `pairs` table + RLS
- [ ] `pair_invite_codes` table + RLS
- [ ] `accept-invite-code` Edge Function deployed
- [ ] PairScreen (choose: generate or enter)
- [ ] GenerateInviteScreen (show code + real-time wait)
- [ ] EnterInviteScreen (input + submit)
- [ ] GoRouter pair guard
- [ ] Signal session initiation after pairing

---

## Core Messaging (M4)

- [ ] `Message` entity (all variants)
- [ ] `MessageContent` sealed class
- [ ] `MessageStatus` enum
- [ ] `MessageText` value object with tests
- [ ] `MessageRepository` interface
- [ ] `MessageRepositoryImpl` with tests
- [ ] `MessageRemoteDataSource`
- [ ] `MessageLocalDataSource`
- [ ] `RealtimeDataSource`
- [ ] `messages` table + RLS
- [ ] `SendMessageUseCase` with tests
- [ ] `WatchMessagesUseCase`
- [ ] `MarkReadUseCase`
- [ ] `ChatViewModel` with tests
- [ ] ChatScreen
- [ ] MessageBubble (text variant)
- [ ] ChatInputBar
- [ ] MessageStatusIcon
- [ ] DateSeparator
- [ ] ScrollToBottomFab
- [ ] Pagination (load more on scroll-up)
- [ ] Supabase Realtime subscription for messages
- [ ] Local SQLite storage for decrypted messages
- [ ] Outbox queue for offline messages
- [ ] Optimistic UI (message appears immediately)

---

## Message Features (M5)

- [ ] `message_receipts` table + RLS
- [ ] `message_reactions` table + RLS
- [ ] Message status tracking (delivered, read)
- [ ] Typing indicator broadcast + reception
- [ ] TypingIndicator widget (animated dots)
- [ ] ReactionPicker widget
- [ ] MessageContextMenu (long press)
- [ ] `ReactToMessageUseCase` with tests
- [ ] `EditMessageUseCase` with tests
- [ ] `DeleteMessageUseCase` with tests
- [ ] Edit flow (within 15 min, re-encrypted)
- [ ] Delete flow (both sides, "[Message deleted]" placeholder)
- [ ] Disappearing messages setting UI
- [ ] `cleanup-expired-messages` Edge Function
- [ ] Message search (FTS5)
- [ ] SearchScreen

---

## Media (M6)

- [ ] `chat-media` Supabase Storage bucket + RLS
- [ ] `MediaRepository` interface
- [ ] `MediaRepositoryImpl` with tests
- [ ] `StorageDataSource` (Supabase Storage)
- [ ] `MediaCacheDataSource` (local file cache)
- [ ] `UploadImageUseCase` with tests
- [ ] `DownloadMediaUseCase` with tests
- [ ] Image compression
- [ ] AES-256-GCM media encryption/decryption
- [ ] Image picker (camera + gallery)
- [ ] ImageMessageBubble widget
- [ ] ImageViewerScreen (Hero animation, pinch-to-zoom)
- [ ] Voice recording (hold-to-record)
- [ ] VoiceMessageBubble widget (waveform + playback)
- [ ] VoiceRecorder widget

---

## Notifications (M7)

- [ ] Firebase project configured (Android + iOS)
- [ ] FCM token registration on login
- [ ] `user_devices` table + RLS
- [ ] `send-push-notification` Edge Function deployed
- [ ] Foreground notification (FlutterLocalNotifications)
- [ ] Background message handler
- [ ] Terminated state tap → navigate to chat
- [ ] Android notification channel created
- [ ] iOS APNs configured
- [ ] Notification permission request flow
- [ ] Notification mute setting respected by Edge Function
- [ ] Badge count management

---

## Profile & Presence (M8)

- [ ] `UserProfile` entity
- [ ] `ProfileRepository` interface
- [ ] `ProfileRepositoryImpl` with tests
- [ ] `ProfileRemoteDataSource`
- [ ] `CreateProfileUseCase` with tests
- [ ] `UpdateProfileUseCase` with tests
- [ ] `UploadAvatarUseCase` with tests
- [ ] `avatars` Supabase Storage bucket
- [ ] MyProfileScreen
- [ ] PartnerProfileScreen
- [ ] AppAvatar widget
- [ ] StatusBadge widget
- [ ] `user_presence` table + RLS
- [ ] Realtime presence subscription
- [ ] ChatAppBar showing partner status

---

## App Lock (M9)

- [ ] `AppLockRepository` interface
- [ ] `AppLockRepositoryImpl`
- [ ] `BiometricDataSource` (local_auth)
- [ ] `EnableBiometricLockUseCase`
- [ ] `EnablePinLockUseCase`
- [ ] `AuthenticateUseCase`
- [ ] PIN hashing (bcrypt or SHA-256 with salt)
- [ ] AppLockScreen
- [ ] AppLockService (inactivity timer)
- [ ] GoRouter lock screen integration
- [ ] FLAG_SECURE set (Android)
- [ ] Auto-lock on app background

---

## Settings (M10)

- [ ] `AppSettings` entity
- [ ] `SettingsRepository` interface
- [ ] `SettingsRepositoryImpl`
- [ ] `GetSettingsUseCase`
- [ ] `UpdateSettingsUseCase`
- [ ] SettingsScreen
- [ ] NotificationSettingsScreen
- [ ] PrivacySettingsScreen
- [ ] SecuritySettingsScreen
- [ ] ChatSettingsScreen
- [ ] AccountSettingsScreen
- [ ] Chat background themes
- [ ] Chat export (local PDF)
- [ ] `delete-account` Edge Function deployed
- [ ] DeleteAccountScreen

---

## Offline Support (M11)

- [ ] `ConnectivityService` with stream
- [ ] `OutboxQueue` Drift table
- [ ] `GapFillService`
- [ ] OutboxQueue flush on reconnect
- [ ] OfflineBanner widget
- [ ] Queued message status indicator
- [ ] Realtime reconnect + gap fill triggered

---

## Quality Gates

- [ ] `flutter analyze` — zero warnings
- [ ] All unit tests pass
- [ ] All widget tests pass
- [ ] Use case coverage: 100%
- [ ] Repository coverage: 90%
- [ ] Cold start: ≤ 2s (measured)
- [ ] Frame rate: ≥ 60fps (DevTools verified)
- [ ] No plaintext in network traffic (proxy test)
- [ ] No sensitive data in SharedPreferences (verified)
- [ ] RLS policies tested (explicit deny tests)
- [ ] Dark mode: all screens verified
- [ ] Accessibility: all interactive elements have semantic labels

---

## Release Gates

- [ ] Production Supabase project configured
- [ ] Firebase production project configured
- [ ] All migrations applied to production
- [ ] All Edge Functions deployed
- [ ] App signed (Android AAB, iOS IPA)
- [ ] Privacy policy published
- [ ] App Store listing prepared
- [ ] Play Store listing prepared
- [ ] TestFlight build active
- [ ] Play Internal Testing build active
