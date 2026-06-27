# 00 — Project Overview

## Purpose
This document is the authoritative entry point for the SecureChat project. It defines what the product is, why it exists, who it is for, and the foundational technical decisions that govern the entire system.

---

## 1. Product Summary

**Name:** SecureChat  
**Tagline:** Your private world. Encrypted by default.  
**Type:** Mobile-first private messaging application  
**Audience:** Two users only — designed for couples, close partners, or any two people who need a completely private, exclusive communication channel  
**Age Restriction:** 18+ only  
**Platform:** Android & iOS (Flutter cross-platform)  

---

## 2. Problem Statement

Mainstream messaging apps (WhatsApp, Telegram, iMessage) are designed for mass communication — group chats, broadcast lists, and thousands of contacts. They involve server-side message access, metadata collection, and third-party data sharing.

Couples and intimate partners deserve a communication channel that is:
- Exclusively theirs (no accidental sends, no group noise)
- End-to-end encrypted with no server-side message access
- Designed for emotional closeness, not productivity
- Free of surveillance capitalism

SecureChat solves this by being purpose-built for exactly two people.

---

## 3. Key Differentiators

| Feature | SecureChat | WhatsApp | Signal | Telegram |
|---|---|---|---|---|
| Max users | 2 (enforced) | Unlimited | Unlimited | Unlimited |
| E2E encryption | Signal Protocol | Signal Protocol | Signal Protocol | Optional |
| Server reads messages | Never | Never | Never | Yes (cloud) |
| Designed for couples | Yes | No | No | No |
| Custom intimacy features | Yes | No | No | No |
| Metadata collection | Minimal | Extensive | Minimal | Moderate |

---

## 4. Core Principles

1. **Privacy by Design** — Zero-knowledge architecture. The server stores only ciphertext. Keys never leave the device.
2. **Two Users Only** — The entire system is architected for exactly two participants. This is a constraint, not a limitation.
3. **Production Quality** — Every line of code is written to production standards. No prototypes, no shortcuts.
4. **Clean Architecture** — Business logic is completely decoupled from UI and infrastructure. Every layer has a single responsibility.
5. **Offline First** — Core functionality works without a network connection. Sync happens when connectivity is restored.
6. **Performance** — 60fps UI, sub-second message delivery on good connections, minimal battery drain.

---

## 5. Technology Stack

### Frontend
| Layer | Technology | Version | Reason |
|---|---|---|---|
| Framework | Flutter | ^3.x | Cross-platform, high performance, Material 3 |
| Language | Dart | ^3.x | Null-safe, strong typing |
| State Management | Riverpod | ^2.x | Compile-safe providers, testable, no context required |
| Navigation | GoRouter | ^14.x | Declarative, deep-link-ready, type-safe routes |
| UI Toolkit | Material 3 | Built-in | Modern, accessible, themeable |
| Local DB | SQLite via drift | ^2.x | Type-safe local queries, reactive streams |
| Secure Storage | flutter_secure_storage | ^9.x | Keychain/Keystore backed |
| Functional Types | fpdart | ^1.x | Either, Option, TaskEither |

### Backend
| Layer | Technology | Reason |
|---|---|---|
| BaaS | Supabase | Postgres + Realtime + Auth + Storage in one |
| Database | PostgreSQL 15 | ACID, RLS, powerful indexing |
| Realtime | Supabase Realtime | WebSocket-based live subscriptions |
| Auth | Supabase Auth | JWT, magic link, phone OTP |
| File Storage | Supabase Storage | S3-compatible, bucket-level policies |
| Edge Functions | Deno (Supabase Edge) | Server-side validation and push triggers |

### Security
| Layer | Technology | Reason |
|---|---|---|
| E2E Encryption | Signal Protocol (libsignal) | Industry-standard, forward secrecy |
| Key Storage | flutter_secure_storage | Hardware-backed key storage |
| Transport | TLS 1.3 | All API traffic |
| App Lock | local_auth | Biometric + PIN |

### Notifications
| Layer | Technology | Reason |
|---|---|---|
| Push | Firebase Cloud Messaging | Reliable, cross-platform push delivery |
| Local | flutter_local_notifications | In-app notifications, scheduled alerts |

---

## 6. High-Level Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                     Flutter App                              │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────────┐  │
│  │ Presentation │  │    Domain    │  │      Data        │  │
│  │   (MVVM)     │→ │  (Use Cases) │→ │  (Repositories)  │  │
│  │  Riverpod    │  │  Entities    │  │  Data Sources    │  │
│  └──────────────┘  └──────────────┘  └────────┬─────────┘  │
└────────────────────────────────────────────────┼────────────┘
                                                  │
          ┌───────────────────────────────────────┼──────────┐
          │                                       │          │
    ┌─────▼──────┐   ┌─────────────┐   ┌─────────▼──────┐   │
    │  Supabase  │   │    FCM      │   │  Signal Proto  │   │
    │  Backend   │   │   Cloud     │   │  (Local Keys)  │   │
    │  Postgres  │   │  Messaging  │   │                │   │
    │  Realtime  │   └─────────────┘   └────────────────┘   │
    │  Storage   │                                           │
    │  Auth      │                                           │
    └────────────┘                                           │
```

---

## 7. Two-User Constraint Architecture

The entire backend is designed around a concept of a **"pair"** — a registered bond between exactly two user accounts. Every data operation is scoped to a pair.

```
User A ──┐
          ├── Pair (pair_id) ──── All messages, media, keys
User B ──┘
```

- A user can only belong to one pair at a time
- A pair cannot have more than two members
- All Supabase RLS policies enforce pair membership
- No message is readable by anyone outside the pair — including server admins

---

## 8. Signal Protocol — Zero-Knowledge Guarantee

```
User A Device                    Server                    User B Device
─────────────                    ──────                    ─────────────
Generate key pair                                          Generate key pair
Publish public keys ────────────→ Store ciphertext ←──── Publish public keys
                                  (no plaintext ever)
Encrypt message ────────────────→ [BLOB] ───────────────→ Decrypt message
(with B's public key)                                     (with A's public key)
```

The server receives only:
- Encrypted blobs
- Public keys
- Metadata (timestamps, delivery status)

The server **never** receives:
- Plaintext messages
- Private keys
- Symmetric session keys

---

## 9. Document Map

| Doc | Title | Status |
|---|---|---|
| 01 | Product Requirements | Active |
| 02 | Functional Requirements | Active |
| 03 | Non-Functional Requirements | Active |
| 04 | System Architecture | Active |
| 05 | Clean Architecture | Active |
| 06 | Feature Breakdown | Active |
| 07 | User Flows | Active |
| 08 | Database Design | Active |
| 09 | API Architecture | Active |
| 10 | Security Architecture | Active |
| 11 | Encryption Architecture | Active |
| 12 | Authentication | Active |
| 13 | State Management | Active |
| 14 | Routing | Active |
| 15 | UI/UX Guidelines | Active |
| 16 | Animation System | Active |
| 17 | Theme System | Active |
| 18 | Component Library | Active |
| 19 | Folder Structure | Active |
| 20 | Data Models | Active |
| 21 | Repository Pattern | Active |
| 22 | Offline Strategy | Active |
| 23 | Realtime Architecture | Active |
| 24 | Notification System | Active |
| 25 | File Storage | Active |
| 26 | Error Handling | Active |
| 27 | Testing Strategy | Active |
| 28 | Performance Strategy | Active |
| 29 | Deployment | Active |
| 30 | Roadmap | Active |
| 31 | Project Checklist | Active |
| 32 | Risks and Assumptions | Active |
| 33 | Development Guidelines | Active |
| 34 | AI Development Rules | Active |

---

## 10. Definition of Done (Project Level)

The project is considered complete when:
- [ ] Two users can register, pair, and exchange encrypted messages
- [ ] Messages are end-to-end encrypted via Signal Protocol
- [ ] All messages are delivered in real-time via Supabase Realtime
- [ ] Push notifications work on both Android and iOS in foreground, background, and terminated states
- [ ] Media (images, audio) can be sent and received with E2E encryption
- [ ] App works offline and syncs when connectivity returns
- [ ] App lock via biometric/PIN is enforced
- [ ] All Riverpod providers are tested
- [ ] All use cases are unit tested
- [ ] All repositories are integration tested
- [ ] `flutter analyze` produces zero warnings
- [ ] Performance: 60fps on mid-range Android device
- [ ] Security audit: no plaintext data in local storage or network traffic
