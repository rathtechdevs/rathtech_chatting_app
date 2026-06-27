# 03 — Non-Functional Requirements

## Purpose
Define measurable system quality attributes — performance, security, reliability, scalability, and maintainability. These requirements are as binding as functional ones.

---

## 1. Performance Requirements

### NFR-PERF-001: UI Frame Rate
- **Requirement:** App SHALL maintain 60fps during all UI interactions
- **Critical paths:** Message list scroll, chat bubble animation, image open/close
- **Measurement:** Flutter DevTools frame timeline; < 2% jank frames
- **Enforcement:** Profile build tested on a mid-range Android device (2GB RAM, Snapdragon 665 equivalent)

### NFR-PERF-002: App Cold Start
- **Requirement:** Time from icon tap to interactive chat screen ≤ 2 seconds
- **Measurement:** Android systrace from process start to first frame; iOS Instruments
- **Breakdown target:**
  - Engine initialization: ≤ 200ms
  - Riverpod provider initialization: ≤ 300ms
  - Auth token validation: ≤ 500ms
  - Route resolution and first frame: ≤ 1000ms

### NFR-PERF-003: Message Send Latency
- **Requirement:** Time from tap "send" to message appearing with "Sent" status ≤ 500ms (P95 on 4G)
- **Includes:** Encryption + network round trip + server ACK
- **Offline:** Message appears with "Queued" status immediately (no latency)

### NFR-PERF-004: Message List Load
- **Requirement:** Initial message list renders in ≤ 300ms from navigation
- **Implementation:** SQLite query + Riverpod stream; lazy-loaded images

### NFR-PERF-005: Media Upload
- **Requirement:** Upload starts within 500ms of user confirmation
- **Progress:** Real-time progress bar shown
- **Compression:** Image compression completes within 2 seconds for a 12MP image

### NFR-PERF-006: Memory Usage
- **Requirement:** App idle memory ≤ 150MB
- **Requirement:** App during active chat ≤ 250MB
- **Measurement:** Android Memory Profiler; iOS Instruments allocations

### NFR-PERF-007: Battery Drain
- **Requirement:** Background battery drain ≤ 1% per hour (primarily from FCM)
- **Realtime connection:** Disconnected when app is backgrounded; restored on foreground

### NFR-PERF-008: SQLite Query Performance
- **Requirement:** All local database queries ≤ 50ms
- **Indexes:** All foreign keys and frequently queried columns indexed
- **Message load:** SELECT with LIMIT 50 + ORDER BY timestamp DESC ≤ 20ms

---

## 2. Security Requirements

### NFR-SEC-001: Encryption at Rest
- **Requirement:** All sensitive data stored locally SHALL be encrypted
- **Enforcement:**
  - Messages in SQLite: encrypted using SQLCipher or per-record AES encryption
  - Keys in secure storage: flutter_secure_storage (Keychain iOS / Keystore Android)
  - Media cache: stored in app-private directory, encrypted per-file

### NFR-SEC-002: Encryption in Transit
- **Requirement:** All network communication SHALL use TLS 1.3
- **Certificate pinning:** Implemented for Supabase API endpoints in production
- **Enforcement:** No cleartext traffic allowed (Android `cleartext_traffic_permitted: false`)

### NFR-SEC-003: Zero Server Knowledge
- **Requirement:** The Supabase server SHALL never have access to plaintext messages
- **Audit:** Verified by code review: no plaintext message in any API request/response body
- **Database:** messages.ciphertext column stores only binary encrypted blobs

### NFR-SEC-004: Key Management
- **Requirement:** Private keys SHALL never leave the device
- **Private keys stored:** flutter_secure_storage only
- **Public keys stored:** Supabase (acceptable — public by definition)
- **Key deletion:** All keys wiped on logout and account deletion

### NFR-SEC-005: Session Security
- **Requirement:** JWT tokens rotated per Supabase Auth rules (access: 1hr, refresh: 30d)
- **Token storage:** flutter_secure_storage only (never SharedPreferences, never logs)
- **Revocation:** Logout calls supabase.auth.signOut() which invalidates server-side

### NFR-SEC-006: SQL Injection Prevention
- **Requirement:** All database queries use parameterized statements
- **Enforcement:** Drift ORM (type-safe queries only); no raw string concatenation in SQL

### NFR-SEC-007: Input Validation
- **Requirement:** All user input validated at domain layer before processing
- **Enforced:** Value objects (Phone, Email, DisplayName) throw validation failure on invalid input

### NFR-SEC-008: No Debug Data in Production
- **Requirement:** Production builds contain no debug symbols, stack traces in UI, or verbose logs
- **Logging:** Logger writes to console in debug mode only; no-op in release

### NFR-SEC-009: App Lock
- **Requirement:** App enforces biometric/PIN lock after inactivity
- **Screen content:** Lock screen shows no message preview or sensitive content
- **Screenshot prevention:** FLAG_SECURE set on Android; iOS equivalent applied

### NFR-SEC-010: RLS Policy Coverage
- **Requirement:** Every Supabase table has Row Level Security enabled
- **Default deny:** No table allows anonymous access
- **Audit:** RLS policies reviewed and tested before every database migration

---

## 3. Reliability Requirements

### NFR-REL-001: Crash Rate
- **Requirement:** App crash rate ≤ 0.1% of sessions
- **Measurement:** Crashlytics or equivalent crash reporting

### NFR-REL-002: Message Delivery Guarantee
- **Requirement:** Messages SHALL be delivered at least once
- **Implementation:** Local queue with retry; Supabase Realtime ACK; server-side persistence
- **No message loss:** If network fails during send, message persists locally until delivered

### NFR-REL-003: Offline Resilience
- **Requirement:** App SHALL function for core read operations without network
- **Offline readable:** All previously received messages
- **Offline writable:** Message composition and queue

### NFR-REL-004: Realtime Reconnection
- **Requirement:** Supabase Realtime channel automatically reconnects after network interruption
- **Max reconnect time:** ≤ 5 seconds after connectivity restored
- **Missed messages:** Fetched from REST API on reconnect (gap fill)

### NFR-REL-005: Data Integrity
- **Requirement:** No message SHALL be displayed as delivered if not saved to local DB
- **Atomic writes:** Insert to local DB and update UI in same transaction

---

## 4. Scalability Requirements

### NFR-SCALE-001: Two-User Constraint
- **Requirement:** System architecture SHALL enforce the 2-user limit at every layer
  - Database: pair table with enforced uniqueness constraint
  - API: RLS policies rejecting third-party access
  - Application: no UI affordance for adding users

### NFR-SCALE-002: Message Volume
- **Requirement:** System SHALL handle up to 500,000 messages per pair without degradation
- **Pagination:** Messages never loaded in full; always paginated
- **Archiving:** Messages older than 1 year flagged for archiving (future feature)

### NFR-SCALE-003: Media Volume
- **Requirement:** System SHALL handle up to 10GB of media per pair
- **Storage:** Supabase Storage with per-pair bucket size policy

---

## 5. Maintainability Requirements

### NFR-MAINT-001: Code Modularity
- **Requirement:** Each feature SHALL be independently deployable and testable
- **Enforcement:** Feature folder isolation; no cross-feature direct imports

### NFR-MAINT-002: Test Coverage
- **Requirement:**
  - Use case tests: 100% of use cases tested
  - Repository tests: 100% of repositories tested with mock data sources
  - Widget tests: 80% of screens covered
  - Integration tests: Critical user flows (register, pair, send message) covered

### NFR-MAINT-003: Static Analysis
- **Requirement:** `flutter analyze` must produce zero errors and zero warnings on every commit
- **Linting:** analysis_options.yaml with strict rules enabled

### NFR-MAINT-004: Documentation Currency
- **Requirement:** Documentation updated within 24 hours of any architecture change
- **Enforcement:** PR checklist includes documentation update verification

---

## 6. Usability Requirements

### NFR-USE-001: Accessibility
- **Requirement:** App SHALL comply with WCAG 2.1 Level AA
- **Color contrast:** ≥ 4.5:1 for body text; ≥ 3:1 for large text
- **Touch targets:** Minimum 48x48dp
- **Screen reader:** All interactive elements have semantic labels

### NFR-USE-002: Localization-Ready
- **Requirement:** All strings stored in ARB files, not hardcoded
- **Default locale:** English (en)
- **Architecture:** flutter_localizations with AppLocalizations

### NFR-USE-003: Responsive Layout
- **Requirement:** UI adapts to phones from 320dp to 428dp screen width
- **Minimum supported:** 5" phone (360dp width)
- **No tablet breakpoints** required for V1

---

## 7. Compatibility Requirements

### NFR-COMPAT-001: Android
- **Minimum SDK:** Android 8.0 (API 26)
- **Target SDK:** Android 15 (API 35)
- **Architecture:** arm64-v8a (primary), x86_64 (emulator)

### NFR-COMPAT-002: iOS
- **Minimum version:** iOS 14.0
- **Target version:** iOS 18.x
- **Architecture:** arm64 (device), x86_64 (simulator)

### NFR-COMPAT-003: Flutter Version
- **Minimum Flutter:** 3.22.0 (stable channel)
- **Dart:** ^3.4.0

---

## 8. Compliance Requirements

### NFR-COMP-001: GDPR (EU)
- **Requirement:** App SHALL comply with GDPR for EU users
- **Right to erasure:** Account deletion removes all server-side personal data within 24 hours
- **Data minimization:** Only collect data necessary for app function
- **Privacy policy:** Displayed at registration

### NFR-COMP-002: App Store Policies
- **Apple App Store:** Comply with Section 5.1.1 (Data Collection and Storage)
- **Google Play:** Comply with Data Safety section requirements
- **18+ restriction:** Age gate at registration with DOB collection

### NFR-COMP-003: Export Controls
- **Encryption export:** Signal Protocol is open source; export control requirements noted
- **Jurisdiction:** App intended for use in India (primary market) with global availability
