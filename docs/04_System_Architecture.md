# 04 — System Architecture

## Purpose
Define the complete system architecture — all components, their responsibilities, how they communicate, and the data flow across the system. This is the technical blueprint.

---

## 1. Architecture Style

SecureChat uses a **Layered Clean Architecture** on the client, with a **Backend-as-a-Service (BaaS)** model for the server side.

| Layer | Pattern | Responsibility |
|---|---|---|
| Client | Clean Architecture + MVVM | All business logic, UI, state |
| Backend | Supabase BaaS | Persistence, Auth, Realtime, Storage |
| Encryption | Signal Protocol (client-side only) | E2E encryption — never touches server |
| Push | Firebase Cloud Messaging | Delivery of push notification envelopes |

---

## 2. C4 Architecture Model

### Level 1: System Context

```
┌─────────────────────────────────────────────────────────────────────┐
│                         SecureChat System                            │
│                                                                      │
│   ┌──────────┐                              ┌──────────┐            │
│   │  User A  │◄────── E2E Encrypted ───────►│  User B  │            │
│   │ (Phone)  │        Messages               │ (Phone)  │            │
│   └────┬─────┘                              └─────┬────┘            │
│        │                                          │                  │
│        └─────────────┬───────────────────────────┘                  │
│                      │                                               │
│               ┌──────▼──────┐                                       │
│               │   Supabase  │                                       │
│               │   Backend   │                                       │
│               └──────┬──────┘                                       │
│                      │                                               │
│               ┌──────▼──────┐                                       │
│               │    FCM      │  (Push delivery only)                 │
│               └─────────────┘                                       │
└─────────────────────────────────────────────────────────────────────┘
```

### Level 2: Container Diagram

```
┌─────────────────────────────────────────────────────────────────────┐
│                         Flutter App (Container)                      │
│                                                                      │
│  ┌─────────────────────────────────────────────────────────────┐   │
│  │                    Presentation Layer                         │   │
│  │   Screens ◄──── ViewModels ◄──── Riverpod Providers         │   │
│  └────────────────────────┬────────────────────────────────────┘   │
│                           │                                          │
│  ┌─────────────────────────────────────────────────────────────┐   │
│  │                      Domain Layer                             │   │
│  │   Use Cases ◄──── Entities ◄──── Repository Interfaces       │   │
│  └────────────────────────┬────────────────────────────────────┘   │
│                           │                                          │
│  ┌─────────────────────────────────────────────────────────────┐   │
│  │                       Data Layer                              │   │
│  │   Repositories ◄── Remote DS ◄── Supabase Client             │   │
│  │                ◄── Local DS  ◄── Drift (SQLite)               │   │
│  │                ◄── Secure DS ◄── flutter_secure_storage       │   │
│  └─────────────────────────────────────────────────────────────┘   │
│                                                                      │
│  ┌─────────────────────────────────────────────────────────────┐   │
│  │                      Core / Shared                            │   │
│  │   Signal Protocol | Logger | Failure types | Constants        │   │
│  └─────────────────────────────────────────────────────────────┘   │
└───────────────────────────────┬─────────────────────────────────────┘
                                │ HTTPS + WebSocket (TLS 1.3)
┌───────────────────────────────▼─────────────────────────────────────┐
│                         Supabase (Backend)                           │
│                                                                      │
│  ┌──────────┐  ┌─────────┐  ┌──────────────┐  ┌─────────────────┐ │
│  │  Auth    │  │Postgres │  │   Realtime   │  │    Storage      │ │
│  │  (JWT)   │  │  (RLS)  │  │  (WebSocket) │  │  (S3-compat)    │ │
│  └──────────┘  └─────────┘  └──────────────┘  └─────────────────┘ │
│                                                                      │
│  ┌──────────────────────────────────────────┐                       │
│  │           Edge Functions (Deno)           │                       │
│  │  - Push notification triggers             │                       │
│  │  - Disappearing message cleanup           │                       │
│  │  - Prekey bundle validation               │                       │
│  └──────────────────────────────────────────┘                       │
└─────────────────────────────────────────────────────────────────────┘
                                │
┌───────────────────────────────▼─────────────────────────────────────┐
│                    Firebase Cloud Messaging                           │
│              (Push notification delivery only)                       │
└─────────────────────────────────────────────────────────────────────┘
```

### Level 3: Component Diagram (Flutter App)

```
lib/
├── core/
│   ├── error/          ← Failure hierarchy, Either aliases
│   ├── network/        ← Supabase client provider, connectivity
│   ├── storage/        ← Secure storage wrapper, drift DB
│   ├── logger/         ← App logger (debug only)
│   ├── encryption/     ← Signal Protocol wrapper
│   └── constants/      ← App strings, route names, asset paths
│
├── features/
│   ├── auth/           ← Registration, login, session
│   ├── pairing/        ← Invite code, pair establishment
│   ├── chat/           ← Message list, send, receive
│   ├── media/          ← Upload, download, encrypt media
│   ├── notification/   ← FCM, local notifications
│   ├── profile/        ← User profile management
│   ├── settings/       ← App settings
│   └── app_lock/       ← Biometric/PIN lock
│
└── app/
    ├── router.dart     ← GoRouter configuration
    ├── providers.dart  ← Root-level Riverpod providers
    └── app.dart        ← MaterialApp.router root widget
```

---

## 3. Data Flow Architecture

### 3.1 Message Send Flow

```
User taps Send
     │
     ▼
ChatViewModel.sendMessage(text)
     │
     ▼
SendMessageUseCase.execute(params)
     │
     ▼
EncryptionService.encrypt(plaintext, recipientPublicKey)
     │  Returns: ciphertext (Uint8List)
     ▼
MessageRepository.sendMessage(ciphertext, metadata)
     │
     ├──► RemoteDataSource.insertMessage(supabase)   → Supabase DB
     │         Server stores: ciphertext only
     │
     └──► LocalDataSource.insertMessage(drift)       → SQLite
               Local stores: plaintext (decrypted) for search
     │
     ▼
Either<Failure, Message> returned to ViewModel
     │
     ▼
Riverpod state updated → UI reflects "Sent" status
```

### 3.2 Message Receive Flow

```
Supabase Realtime WebSocket
     │ (new INSERT event on messages table for this pair)
     ▼
RealtimeDataSource.messageStream()
     │
     ▼
MessageRepository.watchMessages()
     │
     ▼
EncryptionService.decrypt(ciphertext, senderPublicKey)
     │  Returns: plaintext
     ▼
LocalDataSource.insertMessage(drift)   → SQLite (decrypted)
     │
     ▼
Riverpod StreamProvider emits new list
     │
     ▼
ChatScreen rebuilds with new message
     │
     ▼
ReadReceiptUseCase.markRead(messageId) → Supabase update
```

### 3.3 Authentication Flow

```
Registration Screen
     │ (phone/email entered)
     ▼
AuthViewModel → RegisterUseCase
     │
     ▼
AuthRepository → Supabase Auth
     │
     ├── OTP sent / magic link sent
     │
     ▼ (user verifies)
AuthRepository.verifyOtp() → Supabase Auth
     │ Returns: Session (JWT + refresh)
     ▼
SecureStorageDataSource.saveSession()   → flutter_secure_storage
     │
     ▼
SignalProtocolService.generateKeyBundle()
     │ Generates: identity key, signed prekey, one-time prekeys
     ▼
KeyRepository.publishPublicKeys()       → Supabase DB
KeyRepository.savePrivateKeys()         → flutter_secure_storage
     │
     ▼
GoRouter redirects to /pair screen
```

---

## 4. Supabase Integration Architecture

### 4.1 Client Configuration

```
SupabaseClient
├── auth              → AuthClient (JWT management)
├── from('table')     → PostgrestClient (CRUD + RLS)
├── channel('name')   → RealtimeChannel (WebSocket subscriptions)
└── storage           → StorageClient (file upload/download)
```

### 4.2 Connection Strategy

| State | Realtime | REST | Action |
|---|---|---|---|
| App foreground + WiFi | Connected | Available | Full real-time |
| App foreground + Cellular | Connected | Available | Full real-time |
| App background | Disconnected | Not called | FCM wakes on push |
| App terminated | None | None | FCM wakes on push |
| No network | Disconnected | Fails | Queue locally |

### 4.3 Row Level Security Philosophy

Every table enforces these rules:
- `SELECT`: Only if `auth.uid()` is a member of the pair owning this row
- `INSERT`: Only if `auth.uid()` is a member of the pair
- `UPDATE`: Only for the user's own rows (where applicable)
- `DELETE`: Only for the user's own rows
- No row is accessible by users not in the pair

---

## 5. Signal Protocol Integration Architecture

### 5.1 Key Types

| Key | Type | Stored | Purpose |
|---|---|---|---|
| Identity Key Pair | EC (Curve25519) | Private: secure storage; Public: Supabase | Long-term identity |
| Signed Prekey Pair | EC (Curve25519) | Private: secure storage; Public: Supabase | Medium-term |
| One-Time Prekey | EC (Curve25519) | Private: secure storage; Public: Supabase | Single use |
| Session State | Symmetric | Secure storage (serialized) | Active session |

### 5.2 Session Lifecycle

```
Pairing
  │
  ▼
X3DH Key Agreement
  │  User A fetches User B's prekey bundle (identity + signed prekey + one-time prekey)
  │  User A computes shared secret → Initial message keys
  │
  ▼
Double Ratchet begins
  │
  ├── Every sent message: ratchet advances (sending chain key)
  ├── Every received message: ratchet advances (receiving chain key)
  └── DH ratchet: new ephemeral key every message (forward secrecy)
  │
  ▼
Session persisted to secure storage after every ratchet step
```

---

## 6. FCM Integration Architecture

```
New message inserted in Supabase (by sender)
     │
     ▼
Supabase Edge Function triggered (database webhook)
     │
     ▼
Edge Function: looks up recipient's FCM token (stored in user_devices table)
     │
     ▼
Edge Function: sends FCM notification
  - title: sender's display name
  - body: "Sent you a message"
  - data: { type: "new_message", pairId: "..." }
  - NO message content in payload
     │
     ▼
FCM → GCM/APNs → Device OS → Flutter app

App states:
  Foreground  → FlutterLocalNotifications (in-app banner)
  Background  → System tray notification
  Terminated  → System tray notification, app opened on tap
```

---

## 7. Offline Architecture

```
User Action (offline)
     │
     ▼
Use Case validates action (domain layer)
     │
     ▼
Repository checks connectivity
  ├── Online → immediate send
  └── Offline → persist to OutboxQueue (local SQLite table)
                  │
                  ▼
              ConnectivityService.onConnected()
                  │
                  ▼
              OutboxQueue.flush() → send all queued items
                  │
                  ▼
              Update message status: queued → sent
```

---

## 8. Architecture Decision Records (ADR)

### ADR-001: Supabase over self-hosted backend
**Decision:** Use Supabase as BaaS instead of building a custom Node.js/Go API.  
**Reason:** Supabase provides PostgreSQL (powerful, familiar), Realtime (WebSocket built-in), Auth (JWT, OTP, magic link), and Storage (S3-compatible) out of the box. Building equivalent infrastructure would add 4–8 weeks of backend work with no product advantage.  
**Tradeoff:** Vendor dependency; mitigated by clean repository pattern (swap data source without touching domain).

### ADR-002: Signal Protocol over custom encryption
**Decision:** Use Signal Protocol (libsignal) instead of custom AES/RSA encryption.  
**Reason:** Signal Protocol provides forward secrecy, break-in recovery, and is battle-tested. Custom encryption is high-risk and error-prone.  
**Tradeoff:** Library complexity; mitigated by an EncryptionService abstraction layer.

### ADR-003: Riverpod over Bloc
**Decision:** Use Riverpod for state management instead of flutter_bloc.  
**Reason:** Riverpod providers are compile-safe, testable without context, and composable. No need for separate Event/State boilerplate for this app's complexity level.  
**Tradeoff:** Different mental model from Bloc; team must learn Riverpod patterns.

### ADR-004: Drift (SQLite) for local persistence
**Decision:** Use Drift instead of Hive or Isar.  
**Reason:** Drift provides type-safe SQL queries via code generation, reactive streams, and supports complex joins needed for message + reaction queries.  
**Tradeoff:** Code generation step required; setup overhead.

### ADR-005: GoRouter for navigation
**Decision:** Use GoRouter over Navigator 2.0 directly or auto_route.  
**Reason:** GoRouter is officially supported by Flutter team, declarative, supports deep links and auth redirects out of the box.  
**Tradeoff:** Slightly more verbose than auto_route for complex nested routes.
