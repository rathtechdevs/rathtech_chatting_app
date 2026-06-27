# 19 — Folder Structure

## Purpose
Define the complete, authoritative folder and file structure for the SecureChat Flutter project. Every file and directory is listed with its purpose.

---

## 1. Root Structure

```
rathtech_chatting_app/
├── lib/
│   ├── main.dart
│   ├── app/
│   ├── core/
│   └── features/
├── test/
│   ├── unit/
│   ├── widget/
│   └── integration/
├── supabase/
│   ├── migrations/
│   └── functions/
├── assets/
│   ├── images/
│   └── icons/
├── docs/                    ← This documentation
├── android/
├── ios/
├── pubspec.yaml
└── analysis_options.yaml
```

---

## 2. `lib/` Structure

```
lib/
├── main.dart                               ← App entry point
│
├── app/
│   ├── app.dart                            ← MaterialApp.router root
│   ├── router.dart                         ← GoRouter configuration
│   └── providers.dart                      ← Root-level Riverpod overrides
│
├── core/
│   ├── constants/
│   │   ├── app_strings.dart                ← All UI strings
│   │   ├── app_routes.dart                 ← Route path constants
│   │   ├── app_assets.dart                 ← Asset path constants
│   │   ├── animation_constants.dart        ← Duration & curve constants
│   │   └── storage_keys.dart               ← flutter_secure_storage keys
│   │
│   ├── theme/
│   │   ├── app_theme.dart                  ← ThemeData definitions
│   │   ├── app_colors.dart                 ← Brand color tokens
│   │   └── app_text_styles.dart            ← Named TextStyle extensions
│   │
│   ├── error/
│   │   ├── failures.dart                   ← Failure sealed class hierarchy
│   │   ├── exceptions.dart                 ← Internal exception types
│   │   └── failure_message_mapper.dart     ← Failure → user message
│   │
│   ├── network/
│   │   ├── supabase_client_provider.dart   ← Supabase singleton provider
│   │   └── connectivity_service.dart       ← Network state stream
│   │
│   ├── storage/
│   │   ├── app_database.dart               ← Drift DB class
│   │   ├── app_database.g.dart             ← Generated
│   │   ├── secure_storage_provider.dart    ← flutter_secure_storage provider
│   │   └── shared_prefs_provider.dart      ← SharedPreferences provider
│   │
│   ├── encryption/
│   │   ├── encryption_service.dart         ← Abstract interface
│   │   ├── signal_encryption_service.dart  ← Signal Protocol implementation
│   │   ├── key_storage_service.dart        ← Key CRUD on secure storage
│   │   └── models/
│   │       ├── key_bundle.dart             ← PreKeyBundle model
│   │       └── encrypted_payload.dart      ← Ciphertext wrapper
│   │
│   ├── logger/
│   │   └── app_logger.dart                 ← Logging abstraction
│   │
│   ├── extensions/
│   │   ├── datetime_extensions.dart        ← Formatting helpers
│   │   ├── string_extensions.dart
│   │   └── context_extensions.dart         ← Theme/animation helpers
│   │
│   ├── components/                         ← Shared UI components
│   │   ├── app_avatar.dart
│   │   ├── primary_button.dart
│   │   ├── app_text_field.dart
│   │   ├── status_badge.dart
│   │   ├── loading_overlay.dart
│   │   ├── loading_shimmer.dart
│   │   ├── empty_state.dart
│   │   ├── error_view.dart
│   │   ├── offline_banner.dart
│   │   ├── app_bottom_sheet.dart
│   │   └── confirmation_dialog.dart
│   │
│   └── use_case/
│       └── use_case.dart                   ← Base UseCase abstract class
│
└── features/
    ├── auth/                               ← Authentication feature
    │   ├── domain/
    │   │   ├── entities/
    │   │   │   └── auth_session.dart
    │   │   ├── repositories/
    │   │   │   └── auth_repository.dart
    │   │   ├── use_cases/
    │   │   │   ├── request_otp_use_case.dart
    │   │   │   ├── verify_otp_use_case.dart
    │   │   │   ├── request_magic_link_use_case.dart
    │   │   │   ├── get_stored_session_use_case.dart
    │   │   │   └── logout_use_case.dart
    │   │   ├── value_objects/
    │   │   │   ├── phone_number.dart
    │   │   │   ├── email_address.dart
    │   │   │   └── otp_code.dart
    │   │   └── failures/
    │   │       └── auth_failures.dart
    │   │
    │   ├── data/
    │   │   ├── repositories/
    │   │   │   └── auth_repository_impl.dart
    │   │   ├── data_sources/
    │   │   │   ├── remote/
    │   │   │   │   └── auth_remote_data_source.dart
    │   │   │   └── secure/
    │   │   │       └── auth_secure_data_source.dart
    │   │   └── dtos/
    │   │       └── session_dto.dart
    │   │
    │   ├── presentation/
    │   │   ├── screens/
    │   │   │   ├── login_screen.dart
    │   │   │   ├── otp_verification_screen.dart
    │   │   │   ├── magic_link_sent_screen.dart
    │   │   │   └── setup_profile_screen.dart
    │   │   ├── viewmodels/
    │   │   │   ├── login_view_model.dart
    │   │   │   ├── login_state.dart
    │   │   │   ├── otp_view_model.dart
    │   │   │   └── otp_state.dart
    │   │   └── widgets/
    │   │       ├── phone_input_tab.dart
    │   │       └── email_input_tab.dart
    │   │
    │   └── providers.dart
    │
    ├── pairing/                            ← Pairing feature
    │   ├── domain/
    │   │   ├── entities/
    │   │   │   └── pair.dart
    │   │   ├── repositories/
    │   │   │   └── pairing_repository.dart
    │   │   ├── use_cases/
    │   │   │   ├── generate_invite_code_use_case.dart
    │   │   │   ├── accept_invite_code_use_case.dart
    │   │   │   ├── get_current_pair_use_case.dart
    │   │   │   └── dissolve_pair_use_case.dart
    │   │   └── value_objects/
    │   │       └── pair_code.dart
    │   │
    │   ├── data/
    │   │   ├── repositories/
    │   │   │   └── pairing_repository_impl.dart
    │   │   └── data_sources/
    │   │       └── remote/
    │   │           └── pairing_remote_data_source.dart
    │   │
    │   ├── presentation/
    │   │   ├── screens/
    │   │   │   ├── pair_screen.dart
    │   │   │   ├── generate_invite_screen.dart
    │   │   │   └── enter_invite_screen.dart
    │   │   └── viewmodels/
    │   │       ├── pairing_view_model.dart
    │   │       └── pairing_state.dart
    │   │
    │   └── providers.dart
    │
    ├── chat/                               ← Core chat feature
    │   ├── domain/
    │   │   ├── entities/
    │   │   │   ├── message.dart
    │   │   │   ├── message_reaction.dart
    │   │   │   ├── message_receipt.dart
    │   │   │   └── message_status.dart
    │   │   ├── repositories/
    │   │   │   ├── message_repository.dart
    │   │   │   └── typing_repository.dart
    │   │   ├── use_cases/
    │   │   │   ├── send_message_use_case.dart
    │   │   │   ├── edit_message_use_case.dart
    │   │   │   ├── delete_message_use_case.dart
    │   │   │   ├── mark_read_use_case.dart
    │   │   │   ├── watch_messages_use_case.dart
    │   │   │   ├── send_typing_indicator_use_case.dart
    │   │   │   ├── react_to_message_use_case.dart
    │   │   │   └── load_more_messages_use_case.dart
    │   │   └── value_objects/
    │   │       └── message_text.dart
    │   │
    │   ├── data/
    │   │   ├── repositories/
    │   │   │   ├── message_repository_impl.dart
    │   │   │   └── typing_repository_impl.dart
    │   │   ├── data_sources/
    │   │   │   ├── remote/
    │   │   │   │   ├── message_remote_data_source.dart
    │   │   │   │   └── realtime_data_source.dart
    │   │   │   └── local/
    │   │   │       └── message_local_data_source.dart
    │   │   ├── dtos/
    │   │   │   └── message_dto.dart
    │   │   └── mappers/
    │   │       └── message_mapper.dart
    │   │
    │   ├── presentation/
    │   │   ├── screens/
    │   │   │   └── chat_screen.dart
    │   │   ├── viewmodels/
    │   │   │   ├── chat_view_model.dart
    │   │   │   └── chat_state.dart
    │   │   └── widgets/
    │   │       ├── message_bubble.dart
    │   │       ├── text_message_bubble.dart
    │   │       ├── image_message_bubble.dart
    │   │       ├── voice_message_bubble.dart
    │   │       ├── system_message_bubble.dart
    │   │       ├── message_status_icon.dart
    │   │       ├── typing_indicator.dart
    │   │       ├── chat_input_bar.dart
    │   │       ├── reaction_picker.dart
    │   │       ├── message_context_menu.dart
    │   │       ├── date_separator.dart
    │   │       ├── voice_recorder.dart
    │   │       ├── scroll_to_bottom_fab.dart
    │   │       └── chat_app_bar.dart
    │   │
    │   └── providers.dart
    │
    ├── media/                              ← Media upload/download feature
    │   ├── domain/
    │   │   ├── entities/
    │   │   │   └── media_message.dart
    │   │   ├── repositories/
    │   │   │   └── media_repository.dart
    │   │   └── use_cases/
    │   │       ├── upload_image_use_case.dart
    │   │       ├── upload_voice_use_case.dart
    │   │       ├── download_media_use_case.dart
    │   │       └── encrypt_media_use_case.dart
    │   │
    │   ├── data/
    │   │   ├── repositories/
    │   │   │   └── media_repository_impl.dart
    │   │   └── data_sources/
    │   │       ├── remote/
    │   │       │   └── storage_data_source.dart
    │   │       └── local/
    │   │           └── media_cache_data_source.dart
    │   │
    │   ├── presentation/
    │   │   ├── screens/
    │   │   │   ├── image_viewer_screen.dart
    │   │   │   └── voice_player_screen.dart
    │   │   └── viewmodels/
    │   │       ├── media_upload_view_model.dart
    │   │       └── media_upload_state.dart
    │   │
    │   └── providers.dart
    │
    ├── notification/                       ← FCM + local notifications
    │   ├── domain/
    │   │   ├── repositories/
    │   │   │   └── notification_repository.dart
    │   │   └── use_cases/
    │   │       ├── register_fcm_token_use_case.dart
    │   │       └── handle_push_notification_use_case.dart
    │   │
    │   ├── data/
    │   │   ├── repositories/
    │   │   │   └── notification_repository_impl.dart
    │   │   └── data_sources/
    │   │       └── fcm_data_source.dart
    │   │
    │   └── providers.dart
    │
    ├── profile/                            ← User profile feature
    │   ├── domain/
    │   │   ├── entities/
    │   │   │   └── user_profile.dart
    │   │   ├── repositories/
    │   │   │   └── profile_repository.dart
    │   │   └── use_cases/
    │   │       ├── create_profile_use_case.dart
    │   │       ├── update_profile_use_case.dart
    │   │       ├── get_partner_profile_use_case.dart
    │   │       └── upload_avatar_use_case.dart
    │   │
    │   ├── data/
    │   │   ├── repositories/
    │   │   │   └── profile_repository_impl.dart
    │   │   └── data_sources/
    │   │       └── remote/
    │   │           └── profile_remote_data_source.dart
    │   │
    │   ├── presentation/
    │   │   ├── screens/
    │   │   │   ├── my_profile_screen.dart
    │   │   │   └── partner_profile_screen.dart
    │   │   └── viewmodels/
    │   │       ├── profile_view_model.dart
    │   │       └── profile_state.dart
    │   │
    │   └── providers.dart
    │
    ├── settings/                           ← App settings feature
    │   ├── domain/
    │   │   ├── entities/
    │   │   │   └── app_settings.dart
    │   │   ├── repositories/
    │   │   │   └── settings_repository.dart
    │   │   └── use_cases/
    │   │       ├── get_settings_use_case.dart
    │   │       └── update_settings_use_case.dart
    │   │
    │   ├── data/
    │   │   ├── repositories/
    │   │   │   └── settings_repository_impl.dart
    │   │   └── data_sources/
    │   │       └── settings_data_source.dart
    │   │
    │   ├── presentation/
    │   │   ├── screens/
    │   │   │   ├── settings_screen.dart
    │   │   │   ├── notification_settings_screen.dart
    │   │   │   ├── privacy_settings_screen.dart
    │   │   │   ├── security_settings_screen.dart
    │   │   │   ├── chat_settings_screen.dart
    │   │   │   └── account_settings_screen.dart
    │   │   └── viewmodels/
    │   │       ├── settings_view_model.dart
    │   │       └── settings_state.dart
    │   │
    │   └── providers.dart
    │
    └── app_lock/                           ← App lock feature
        ├── domain/
        │   ├── repositories/
        │   │   └── app_lock_repository.dart
        │   └── use_cases/
        │       ├── enable_biometric_lock_use_case.dart
        │       ├── enable_pin_lock_use_case.dart
        │       ├── authenticate_use_case.dart
        │       └── disable_lock_use_case.dart
        │
        ├── data/
        │   ├── repositories/
        │   │   └── app_lock_repository_impl.dart
        │   └── data_sources/
        │       └── biometric_data_source.dart
        │
        ├── presentation/
        │   ├── screens/
        │   │   └── app_lock_screen.dart
        │   └── viewmodels/
        │       ├── app_lock_view_model.dart
        │       └── app_lock_state.dart
        │
        └── providers.dart
```

---

## 3. `test/` Structure

```
test/
├── unit/
│   ├── core/
│   │   └── encryption/
│   │       └── signal_encryption_service_test.dart
│   └── features/
│       ├── auth/
│       │   ├── domain/
│       │   │   ├── use_cases/
│       │   │   │   └── verify_otp_use_case_test.dart
│       │   │   └── value_objects/
│       │   │       └── phone_number_test.dart
│       │   └── data/
│       │       └── repositories/
│       │           └── auth_repository_impl_test.dart
│       └── chat/
│           └── domain/
│               └── use_cases/
│                   └── send_message_use_case_test.dart
│
├── widget/
│   └── features/
│       ├── auth/
│       │   └── screens/
│       │       └── login_screen_test.dart
│       └── chat/
│           └── widgets/
│               └── message_bubble_test.dart
│
└── integration/
    ├── auth_flow_test.dart
    ├── pairing_flow_test.dart
    └── send_message_flow_test.dart
```

---

## 4. `supabase/` Structure

```
supabase/
├── migrations/
│   ├── 20240101000001_create_user_profiles.sql
│   ├── 20240101000002_create_user_devices.sql
│   ├── 20240101000003_create_pairs.sql
│   ├── 20240101000004_create_messages.sql
│   └── ...
└── functions/
    ├── accept-invite-code/
    │   └── index.ts
    ├── claim-prekey/
    │   └── index.ts
    ├── send-push-notification/
    │   └── index.ts
    ├── cleanup-expired-messages/
    │   └── index.ts
    └── delete-account/
        └── index.ts
```

---

## 5. Naming Rules

| Item | Convention | Example |
|---|---|---|
| Files | `snake_case.dart` | `chat_view_model.dart` |
| Directories | `snake_case` | `data_sources/` |
| Classes | `PascalCase` | `ChatViewModel` |
| Methods | `camelCase` | `sendMessage()` |
| Variables | `camelCase` | `currentPairId` |
| Constants | `camelCase` (in abstract class) | `AppStrings.sendMessage` |
| Providers | `camelCase` + `Provider` suffix | `chatViewModelProvider` |
| Enums | `PascalCase` | `MessageStatus` |
| Enum values | `camelCase` | `MessageStatus.delivered` |
| Test files | `<subject>_test.dart` | `login_screen_test.dart` |
