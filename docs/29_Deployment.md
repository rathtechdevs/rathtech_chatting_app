# 29 — Deployment

## Purpose
Define the complete deployment process — build configuration, environment management, signing, release channels, Supabase deployment, and CI/CD pipeline.

---

## 1. Environment Configuration

### 1.1 Flutter Environments

Three environments managed via `--dart-define`:

| Environment | Purpose | Supabase Instance |
|---|---|---|
| `development` | Local development | Supabase local / dev project |
| `staging` | Pre-release testing | Supabase staging project |
| `production` | Live app | Supabase production project |

### 1.2 Environment Variables

```dart
// lib/core/config/app_config.dart
abstract class AppConfig {
  static const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');
  static const environment = String.fromEnvironment(
    'APP_ENV',
    defaultValue: 'development',
  );

  static bool get isProduction => environment == 'production';
  static bool get isDevelopment => environment == 'development';
}
```

### 1.3 Launch Commands

```bash
# Development
flutter run \
  --dart-define=SUPABASE_URL=https://xxx.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=xxx \
  --dart-define=APP_ENV=development

# Production build
flutter build appbundle \
  --release \
  --dart-define=SUPABASE_URL=https://yyy.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=yyy \
  --dart-define=APP_ENV=production \
  --obfuscate \
  --split-debug-info=build/debug-info
```

**Security:** Never commit `.env` files or `--dart-define` values to git. Store in CI/CD secrets.

---

## 2. Android Deployment

### 2.1 Build Variants

| Variant | Build Command | Output |
|---|---|---|
| Debug | `flutter run` | APK (debug) |
| Release APK | `flutter build apk --release` | `build/app/outputs/apk/release/app-release.apk` |
| Release AAB | `flutter build appbundle --release` | `build/app/outputs/bundle/release/app-release.aab` |

### 2.2 Signing Configuration

`android/key.properties` (gitignored):
```properties
storePassword=<store_password>
keyPassword=<key_password>
keyAlias=securechat
storeFile=../securechat-key.jks
```

`android/app/build.gradle`:
```groovy
android {
    signingConfigs {
        release {
            keyAlias keystoreProperties['keyAlias']
            keyPassword keystoreProperties['keyPassword']
            storeFile file(keystoreProperties['storeFile'])
            storePassword keystoreProperties['storePassword']
        }
    }
    buildTypes {
        release {
            signingConfig signingConfigs.release
            minifyEnabled true
            shrinkResources true
        }
    }
}
```

### 2.3 ProGuard Rules

```
# android/app/proguard-rules.pro
# Keep Flutter
-keep class io.flutter.** { *; }
# Keep Supabase
-keep class io.supabase.** { *; }
# Keep Signal Protocol
-keep class org.signal.** { *; }
# Keep Firebase
-keep class com.google.firebase.** { *; }
```

### 2.4 Obfuscation

```bash
flutter build appbundle --release --obfuscate --split-debug-info=build/debug-info/android
```

Upload `build/debug-info/android/*.symbols` to Google Play Console for deobfuscated crash reports.

---

## 3. iOS Deployment

### 3.1 Build Commands

```bash
# Archive (for App Store)
flutter build ipa --release \
  --dart-define=SUPABASE_URL=... \
  --dart-define=SUPABASE_ANON_KEY=... \
  --export-options-plist=ios/ExportOptions.plist

# App Store upload
xcrun altool --upload-app \
  --file build/ios/ipa/*.ipa \
  --type ios \
  --apiKey <API_KEY> \
  --apiIssuer <ISSUER_ID>
```

### 3.2 Required Capabilities

In Xcode → Target → Signing & Capabilities:
- Push Notifications
- Background Modes: Remote notifications, Background fetch
- Keychain Sharing (for flutter_secure_storage)

### 3.3 App Store Privacy Nutrition Label

Data types collected:
- Contact Info: Phone number or email (for auth)
- Usage Data: App launches (analytics)
- Identifiers: Device token (for push)

Data NOT collected:
- Messages (never leave device as plaintext)
- Location
- Health data
- Photos / Media content

---

## 4. Supabase Deployment

### 4.1 Database Migrations

```bash
# Apply migrations to production
supabase db push --db-url "postgresql://..."

# Or via Supabase CLI with linked project
supabase link --project-ref <project-ref>
supabase db push
```

### 4.2 Edge Functions

```bash
# Deploy all functions
supabase functions deploy

# Deploy specific function
supabase functions deploy send-push-notification

# Set secrets
supabase secrets set FCM_SERVER_KEY=xxx
supabase secrets set SUPABASE_SERVICE_ROLE_KEY=xxx
```

### 4.3 Storage Buckets

Create via Supabase dashboard or migration:
```sql
-- In a migration file
INSERT INTO storage.buckets (id, name, public) VALUES ('avatars', 'avatars', true);
INSERT INTO storage.buckets (id, name, public) VALUES ('chat-media', 'chat-media', false);
```

### 4.4 Realtime Configuration

Enable Realtime on tables via Supabase dashboard:
- `messages` → Enable Realtime (INSERT, UPDATE, DELETE)
- `message_reactions` → Enable Realtime (INSERT, DELETE)
- `message_receipts` → Enable Realtime (INSERT)
- `pairs` → Enable Realtime (INSERT, UPDATE)
- `user_presence` → Enable Realtime (UPDATE)

---

## 5. Version Management

### 5.1 pubspec.yaml Versioning

```yaml
version: 1.0.0+1
#         ^   ^
#         |   Build number (incremented on every release)
#         Semantic version (Major.Minor.Patch)
```

### 5.2 Version Bump Script

```bash
# Bump build number before every release
flutter pub run build_runner build
# Then manually update pubspec.yaml version
```

### 5.3 Semantic Versioning

| Change | Version Bump |
|---|---|
| Bug fix | 1.0.x |
| New feature (backward-compatible) | 1.x.0 |
| Breaking change (rarely applicable for an app) | x.0.0 |

---

## 6. Release Checklist

Before every production release:

**Code Quality:**
- [ ] `flutter analyze` passes with zero warnings
- [ ] All tests pass (`flutter test`)
- [ ] No TODO comments in committed code
- [ ] Documentation updated for any new features

**Security:**
- [ ] No hardcoded secrets in code
- [ ] Obfuscation enabled in release build
- [ ] Certificate pinning configured
- [ ] All Supabase RLS policies tested

**Performance:**
- [ ] Cold start measured: ≤ 2s
- [ ] Frame rate tested: 60fps
- [ ] APK/IPA size reasonable (< 50MB)

**Features:**
- [ ] Happy path tested on Android
- [ ] Happy path tested on iOS
- [ ] Push notifications tested (foreground, background, terminated)
- [ ] Offline mode tested
- [ ] App lock tested

**Deployment:**
- [ ] Supabase migrations applied to production
- [ ] Edge functions deployed
- [ ] App signed with production key
- [ ] Version number bumped

---

## 7. Rollback Strategy

| Scenario | Rollback |
|---|---|
| Flutter app bug | Push hotfix release; expedited App Store review |
| Supabase migration issue | Reverse migration script prepared before every migration |
| Edge function bug | `supabase functions deploy` previous version from git |
| FCM configuration issue | Update FCM settings in Firebase Console |

---

## 8. Monitoring (Post-Deploy)

| Tool | Monitors |
|---|---|
| Firebase Crashlytics | App crashes |
| Supabase Dashboard | API errors, query performance, Storage usage |
| Firebase Console | FCM delivery success rates |
| (Future) Sentry | Error tracking with breadcrumbs |
