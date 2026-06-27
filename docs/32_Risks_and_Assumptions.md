# 32 — Risks and Assumptions

## Purpose
Identify all project risks, assumptions, and dependencies that could impact delivery.

---

## 1. Technical Risks

### RISK-001: Signal Protocol Dart Library Maturity
**Risk:** The available Dart Signal Protocol library (`signal_protocol_library` or libsignal bindings) may have incomplete API coverage, bugs, or poor documentation.  
**Probability:** Medium  
**Impact:** High (delays encryption milestone by 1–2 weeks)  
**Mitigation:**
- Prototype encryption core before building messaging
- Evaluate library early in M2; identify gaps
- Fallback: implement AES + manual ratchet (not Signal-compatible, but functional)
- Allocate buffer time in M2 estimate

### RISK-002: Supabase Realtime Message Ordering
**Risk:** Supabase Realtime may deliver events out of order under network stress.  
**Probability:** Low  
**Impact:** Medium (messages appear in wrong order)  
**Mitigation:**
- Always order messages by `sent_at` from local DB (not arrival order)
- Server `sent_at` is authoritative (set by `DEFAULT NOW()`, not client clock)
- Gap fill on reconnect catches missed events

### RISK-003: FCM Delivery Reliability
**Risk:** FCM notifications may not deliver on all Android OEMs (especially Chinese OEMs: Xiaomi, Vivo, Oppo) due to aggressive battery optimization.  
**Probability:** Medium  
**Impact:** Medium (partner doesn't receive notifications)  
**Mitigation:**
- Document battery optimization exemption instructions for affected OEMs
- Show prompt on first launch for affected OEMs
- In-app notification banner covers the foreground case regardless

### RISK-004: iOS Push in Terminated State
**Risk:** iOS APNs push delivery can be delayed or dropped under certain conditions.  
**Probability:** Low  
**Impact:** Medium  
**Mitigation:**
- App uses Realtime subscription when in foreground (FCM is backup, not primary)
- Test push delivery in all states on TestFlight before release

### RISK-005: SQLite Performance with Large Message History
**Risk:** SQLite FTS5 and indexed queries may degrade for pairs with 500,000+ messages.  
**Probability:** Low (takes months of heavy use)  
**Impact:** Low (pagination means typical queries are fast)  
**Mitigation:**
- FTS5 index maintained via triggers
- Pagination ensures max 50 rows per query
- Future: archive old messages

### RISK-006: App Store Rejection
**Risk:** Apple may reject the app for:
- E2E encryption export compliance (common; resolved by adding encryption declaration)
- 18+ content classification (requires correct age rating selection)
- Privacy nutrition label inaccuracies  
**Probability:** Medium (first submission)  
**Impact:** Medium (1–2 week delay)  
**Mitigation:**
- Add Encryption Use declaration in App Store Connect
- Select correct content rating (17+ mature)
- Prepare accurate Data Safety section

### RISK-007: Signal Protocol Session Desync
**Risk:** If one partner's app crashes during a ratchet step, their session state may diverge.  
**Probability:** Low  
**Impact:** High (messages become unreadable)  
**Mitigation:**
- Session state saved after every ratchet step (atomic write)
- Implement session reset flow (reinstall detection)
- Show "[Session error]" placeholder and trigger session re-establishment

### RISK-008: flutter_secure_storage Keychain Issues (iOS)
**Risk:** On iOS, Keychain items may be lost during app reinstall or OS upgrade, losing Signal Protocol private keys.  
**Probability:** Low (with correct Keychain accessibility settings)  
**Impact:** High (user loses all session keys)  
**Mitigation:**
- Use `kSecAttrAccessibleWhenUnlockedThisDeviceOnly` — does NOT migrate to new device, preventing key exposure
- Implement graceful reinstall detection: if keys absent but account exists → trigger session reset flow
- Document to users that reinstalling the app loses local message history

---

## 2. Product Risks

### RISK-009: Two-User Constraint Frustration
**Risk:** Users may want to add a third person (family member, friend) and feel constrained.  
**Probability:** Medium  
**Impact:** Low (by design — not a bug)  
**Mitigation:**
- Clear communication in App Store listing: "For two people only"
- Onboarding explains the exclusive nature as a feature, not a limitation

### RISK-010: Partner Loses Phone / Gets New Device
**Risk:** If partner gets a new phone, they lose their Signal Protocol session. Messages sent to old session are unreadable on new device.  
**Probability:** Medium  
**Impact:** Medium (old messages inaccessible; new messages work after session reset)  
**Mitigation:**
- Session reset flow (partner notified, new session initiated)
- Past messages remain in partner's old local DB but are inaccessible on new device (by design — forward secrecy)
- Document this behavior clearly

---

## 3. Assumptions

### ASSUM-001: Single Device Per User
- **Assumption:** Each user has exactly one primary device
- **Rationale:** Signal Protocol sessions are device-bound; multi-device requires significant additional complexity (sealed sender, device linking)
- **Impact if wrong:** Multi-device support requires Signal multi-device protocol (V2 consideration)

### ASSUM-002: Flutter Stable Channel is Sufficient
- **Assumption:** Flutter stable channel supports all required platform APIs (biometric, secure storage, FCM, deep links)
- **Risk:** Low — all listed packages are stable and tested on Flutter 3.22+

### ASSUM-003: Supabase Free/Pro Tier is Sufficient for Development
- **Assumption:** Supabase free tier (500MB DB, 1GB Storage, 50,000 MAU) is sufficient for development and early users
- **Risk:** Low — two-user app has minimal load

### ASSUM-004: libsignal Dart Bindings Cover Required APIs
- **Assumption:** The available Dart Signal Protocol library provides X3DH + Double Ratchet primitives
- **Risk:** Medium — if not, manual implementation or FFI to native libsignal required

### ASSUM-005: Firebase FCM is Available in Target Markets
- **Assumption:** Target users are in markets where Google services (Firebase) are available
- **Risk:** Low (India + global = FCM available); High if targeting China specifically

### ASSUM-006: Users Use Supabase-Supported Auth Methods
- **Assumption:** Users have access to a phone number (for OTP) or email (for magic link)
- **Risk:** Very low — universal coverage

---

## 4. Dependencies

| Dependency | Type | Risk Level | Fallback |
|---|---|---|---|
| Supabase | BaaS | Medium | Self-hosted Supabase (same API) |
| Firebase / FCM | Push notifications | Low | Amazon SNS or direct APNs |
| Signal Protocol Dart library | Encryption | High | Custom implementation |
| flutter_secure_storage | Key storage | Low | No fallback (required) |
| Riverpod | State management | Very low | No fallback planned |
| GoRouter | Navigation | Very low | No fallback planned |
| Drift (SQLite) | Local database | Low | Isar as alternative |
| flutter_local_notifications | In-app notifications | Low | Custom implementation |
| local_auth | Biometric | Low | PIN-only fallback |
