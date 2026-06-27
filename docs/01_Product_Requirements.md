# 01 — Product Requirements Document (PRD)

## Purpose
Define what SecureChat must do from a product and business perspective. This is the "what and why" — not the "how". Every feature in this document traces to a user need.

---

## 1. Product Vision

SecureChat is the safest, most intimate digital communication space for two people. It is not a social network. It is not a productivity tool. It is a private sanctuary — a dedicated, encrypted channel between exactly two people who trust each other completely and want to communicate without surveillance.

---

## 2. Target Users

### Primary Persona — "The Couple"
- Age: 18–45
- Relationship: Romantic partners, long-distance couples
- Pain point: Existing apps feel generic; messages get mixed in with work chats and group threads; concerned about privacy
- Goal: A space that is only theirs — intimate, private, designed for emotional communication

### Secondary Persona — "The Close Friends"
- Age: 18–35
- Relationship: Best friends who want a private, exclusive channel
- Pain point: Main messaging apps feel monitored or data-harvested
- Goal: Total privacy for personal conversations

### Anti-Persona (out of scope)
- Groups of 3+ users (not supported by design)
- Business communication users
- Users expecting social media features (likes, public stories, etc.)

---

## 3. Core Product Requirements

### PR-001: Two-User Exclusivity
- The system SHALL support exactly two registered users per account pair
- A user SHALL NOT be able to add a third participant to any conversation
- The pairing mechanism SHALL require mutual consent from both users
- If a pair is dissolved, all data for both users SHALL be deleted or transferred per their consent

### PR-002: End-to-End Encryption
- All messages SHALL be encrypted on the sender's device before transmission
- The server SHALL never have access to message plaintext
- The encryption implementation SHALL use the Signal Protocol
- Key material SHALL be stored exclusively on user devices in hardware-backed secure storage
- Forward secrecy SHALL be maintained — compromise of current keys does not expose past messages

### PR-003: Authentication
- Users SHALL authenticate using phone number (OTP) OR email (magic link)
- Authentication tokens SHALL be stored in secure storage (not shared preferences)
- Sessions SHALL expire after 30 days of inactivity
- Users SHALL be able to manually log out, which clears all local keys and tokens

### PR-004: Real-Time Messaging
- Messages SHALL be delivered in real-time when both users are online
- Real-time delivery target: < 500ms on a 4G connection
- Message status SHALL be tracked: Sending → Sent → Delivered → Read
- Typing indicators SHALL be shown when the other user is composing

### PR-005: Offline Support
- Users SHALL be able to compose and queue messages while offline
- Queued messages SHALL be sent automatically when connectivity is restored
- Previously received messages SHALL be readable offline via local database
- The UI SHALL clearly indicate offline state and queued message count

### PR-006: Media Sharing
- Users SHALL be able to send images (JPEG, PNG, WEBP) up to 10MB
- Users SHALL be able to send voice messages (M4A, OGG) up to 5 minutes
- Users SHALL be able to send video clips up to 50MB
- All media SHALL be encrypted before upload and decrypted after download
- Media SHALL be automatically compressed before encryption to optimize storage

### PR-007: Push Notifications
- Users SHALL receive push notifications for new messages when the app is in background or terminated
- Notification content SHALL show "New message from [Partner Name]" — never the message content (privacy)
- Users SHALL be able to mute notifications with a configurable duration
- Notifications SHALL be cleared automatically when the user opens the relevant conversation

### PR-008: App Lock
- Users SHALL be able to lock the app with biometric (fingerprint/Face ID) or a PIN
- The app SHALL lock automatically after a configurable inactivity period (default: 1 minute)
- The lock screen SHALL not show any message preview or content
- Failed unlock attempts SHALL be limited to 5 before a cool-down period

### PR-009: Disappearing Messages
- Users SHALL be able to set messages to auto-delete after a configurable duration
- Durations: 1 hour, 24 hours, 7 days, 30 days, never
- Disappearing message settings SHALL apply to all future messages in the conversation
- Both users must agree on the disappearing message timer (change requires partner confirmation)

### PR-010: Message Reactions
- Users SHALL be able to react to any message with emoji reactions
- Both users SHALL see reactions in real-time
- A user can change or remove their own reaction

### PR-011: Message Editing and Deletion
- A sender SHALL be able to edit a sent message within 15 minutes of sending
- A sender SHALL be able to delete a sent message for both sides at any time
- Deleted messages SHALL show a placeholder: "[Message deleted]"
- Edited messages SHALL show an "edited" label with the edit timestamp

### PR-012: Partner Presence
- The app SHALL show whether the partner is currently online
- The app SHALL show the partner's last seen timestamp (configurable privacy)
- The app SHALL show a typing indicator in real-time

### PR-013: Profile and Customization
- Each user SHALL have a profile: display name, avatar, bio (optional)
- The chat background SHALL be customizable with curated themes or custom images
- The notification sound SHALL be customizable

### PR-014: Data Portability and Deletion
- Users SHALL be able to export their decrypted message history as a PDF or text file (local only, never uploaded)
- Users SHALL be able to delete their account and all associated server data
- After account deletion, partner SHALL be notified and their pair is dissolved

---

## 4. Out of Scope (V1)

The following features are explicitly NOT in scope for Version 1.0:

- Group chats (more than 2 users)
- Voice/video calls
- Web app interface
- Desktop application
- Sticker packs / GIF search (requires third-party APIs)
- Payment / subscription management in-app
- Message forwarding to other contacts
- Backup to cloud (iCloud, Google Drive) — intentionally excluded for security

---

## 5. Constraints

| Constraint | Detail |
|---|---|
| User limit | Hard limit of 2 users per pair, enforced at API and database level |
| Encryption | Signal Protocol only — no alternatives |
| Key storage | flutter_secure_storage only — no exceptions |
| Server knowledge | Server may never read message content |
| Age restriction | 18+ enforced via registration date-of-birth validation |
| App stores | Must comply with Apple App Store and Google Play Store policies |

---

## 6. Success Metrics

| Metric | Target |
|---|---|
| Message delivery latency | < 500ms (P95) |
| App crash rate | < 0.1% of sessions |
| Daily active usage | Both users open app ≥ 1x per day |
| User retention (30-day) | > 80% |
| Message send success rate | > 99.5% |
| Push notification delivery rate | > 95% |
| App launch time (cold start) | < 2 seconds |
| Encryption overhead | < 50ms per message |
