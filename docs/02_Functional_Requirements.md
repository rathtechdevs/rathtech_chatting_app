# 02 — Functional Requirements

## Purpose
Define every system behavior in precise, testable terms. Each requirement has a unique ID, a description, acceptance criteria, and dependencies.

---

## 1. Requirement Categories

| Prefix | Category |
|---|---|
| FR-AUTH | Authentication & Authorization |
| FR-PAIR | Pairing System |
| FR-MSG | Messaging |
| FR-MED | Media |
| FR-NOTIF | Notifications |
| FR-CRYPT | Encryption |
| FR-PROF | Profile |
| FR-LOCK | App Lock |
| FR-SYNC | Synchronization |
| FR-SET | Settings |
| FR-DEL | Data Deletion |

---

## 2. Authentication Requirements

### FR-AUTH-001: Phone Number Registration
- **Description:** User can register using a phone number with OTP verification
- **Trigger:** User enters phone number on registration screen
- **Flow:** Enter phone → Request OTP → Receive SMS → Enter OTP → Validated → Account created
- **Acceptance Criteria:**
  - OTP is 6 digits
  - OTP expires after 5 minutes
  - Maximum 3 OTP requests per hour per phone number
  - Invalid OTP shows error without revealing attempt count until limit reached
  - Successful OTP creates Supabase auth session
- **Edge Cases:**
  - Phone number already registered → show "link existing account" flow
  - OTP expired → allow resend with countdown timer (60s minimum)
  - No SMS received → show "try email login" fallback
- **Dependencies:** Supabase Auth, phone OTP provider

### FR-AUTH-002: Email Magic Link Registration
- **Description:** User can register/login using email magic link
- **Trigger:** User enters email on registration screen and taps "Send Magic Link"
- **Flow:** Enter email → Send link → Open email → Tap link → Deep link opens app → Authenticated
- **Acceptance Criteria:**
  - Magic link expires after 1 hour
  - Link is single-use
  - App handles deep link from email client correctly
  - Session is persisted to secure storage after successful auth
- **Edge Cases:**
  - Link opens in browser instead of app → show instructions to copy and open in app
  - Link already used → show "link expired, request a new one"
  - Email not received → show retry option with 30-second cooldown

### FR-AUTH-003: Session Persistence
- **Description:** Authenticated session persists between app launches
- **Acceptance Criteria:**
  - JWT access token and refresh token stored in flutter_secure_storage
  - App auto-refreshes expired access token using refresh token
  - If refresh token is expired, user is navigated to login screen
  - Session data cleared on explicit logout

### FR-AUTH-004: Logout
- **Description:** User can log out, clearing all local sensitive data
- **Acceptance Criteria:**
  - Tapping logout calls Supabase signOut
  - Local database is wiped (messages, media references)
  - Signal Protocol keys are deleted from secure storage
  - JWT tokens deleted from secure storage
  - GoRouter navigates to login screen
  - Partner is not notified of logout

### FR-AUTH-005: Session Security
- **Description:** Session tokens are rotated and stored securely
- **Acceptance Criteria:**
  - Tokens stored only in flutter_secure_storage (backed by Keychain/Keystore)
  - Access token rotated every 1 hour by Supabase Auth
  - Session tied to device; cannot be transferred

---

## 3. Pairing Requirements

### FR-PAIR-001: Generate Invite Code
- **Description:** After registration, user generates a one-time invite code to share with their partner
- **Acceptance Criteria:**
  - Invite code is alphanumeric, 8 characters, case-insensitive
  - Code expires after 48 hours
  - Code is single-use (destroyed after partner connects)
  - Code is shareable via system share sheet (copy, SMS, etc.)
  - A user can only have one active invite code at a time
- **Edge Cases:**
  - Code expired → allow regeneration
  - Code already used → show "partner already connected" state

### FR-PAIR-002: Accept Invite Code
- **Description:** Partner enters invite code to establish a pair connection
- **Acceptance Criteria:**
  - Partner enters 8-character code
  - System validates code is valid, not expired, and belongs to a different user
  - On success: pair record is created in database
  - Signal Protocol key exchange is initiated automatically after pairing
  - Both users are navigated to the chat screen
- **Edge Cases:**
  - Invalid code → clear error message
  - Own code entered → "You cannot connect with yourself"
  - Code from already-paired user → appropriate error

### FR-PAIR-003: Pair Status
- **Description:** App always knows whether the user is paired or unpaired
- **Acceptance Criteria:**
  - Unpaired users see onboarding/pair screen, not chat
  - GoRouter redirect enforces this routing rule
  - Pair status is fetched on app start and cached
  - Real-time subscription detects if partner dissolves the pair

### FR-PAIR-004: Dissolve Pair
- **Description:** Either user can dissolve the pair, ending the relationship
- **Acceptance Criteria:**
  - Requires explicit confirmation (typed "DELETE" or similar)
  - Partner is notified via push notification
  - Both users' chat data is optionally deleted (user choice)
  - Signal Protocol session is destroyed on both devices
  - Both users return to unpaired state

---

## 4. Messaging Requirements

### FR-MSG-001: Send Text Message
- **Description:** User can type and send a text message
- **Acceptance Criteria:**
  - Message encrypted on device before sending
  - Optimistic UI: message appears immediately with "Sending" status
  - On server ACK: status updates to "Sent"
  - On partner device receipt: status updates to "Delivered"
  - On partner read: status updates to "Read"
  - Messages stored in local SQLite database
  - Message input clears after successful send
- **Edge Cases:**
  - Offline: message queued locally, sent when online
  - Server error: message stays in "Failed" state with retry option
  - Very long message (>4000 chars): split into multiple encrypted chunks

### FR-MSG-002: Receive Text Message
- **Description:** User receives and decrypts messages from partner
- **Acceptance Criteria:**
  - New message received via Supabase Realtime subscription
  - Message decrypted on device immediately
  - Message inserted into local database
  - UI updates reactively via Riverpod stream provider
  - Read receipt sent automatically when user views the message

### FR-MSG-003: Message Status Tracking
- **Description:** Sender sees delivery/read status per message
- **Accepted States:** pending → sending → sent → delivered → read | failed
- **Acceptance Criteria:**
  - Status shown as icon next to message timestamp
  - Status updates in real-time via Realtime subscription
  - Failed messages show retry button

### FR-MSG-004: Message Pagination
- **Description:** Chat loads messages in pages, not all at once
- **Acceptance Criteria:**
  - Initial load: last 50 messages
  - Scroll up triggers next page load (50 messages)
  - Loading indicator shown during page fetch
  - No duplicate messages on pagination
  - Smooth scroll position maintained after page load

### FR-MSG-005: Typing Indicator
- **Description:** User sees when partner is typing
- **Acceptance Criteria:**
  - Typing indicator sent via Supabase Realtime presence channel
  - Indicator shown as animated dots in chat header or above input
  - Typing event sent after 300ms of keystroke activity
  - Typing indicator cleared 3 seconds after last keystroke
  - No typing event sent when message field is empty

### FR-MSG-006: Message Reactions
- **Description:** User can react to any message with a single emoji
- **Acceptance Criteria:**
  - Long-press on message shows emoji picker (8 curated emojis)
  - Reaction stored and synced to partner in real-time
  - Only one reaction per user per message
  - Tap existing reaction to remove it
  - Reactions shown inline below the message bubble

### FR-MSG-007: Edit Message
- **Description:** Sender can edit a message within 15 minutes of sending
- **Acceptance Criteria:**
  - Edit option available only for own messages within 15-minute window
  - Edit opens message text in input field
  - On save: encrypted new content replaces old on server and locally
  - Message shows "edited" label with timestamp
  - Partner sees updated content in real-time

### FR-MSG-008: Delete Message
- **Description:** Sender can delete a message (removes from both devices)
- **Acceptance Criteria:**
  - Delete option available for own messages at any time
  - Requires confirmation tap
  - On delete: server record marked deleted, ciphertext cleared
  - Both devices show "[Message deleted]" placeholder in real-time
  - Reactions on deleted messages are also removed

### FR-MSG-009: Disappearing Messages
- **Description:** Messages auto-delete after a configurable time period
- **Durations:** Off | 1h | 24h | 7d | 30d
- **Acceptance Criteria:**
  - Timer starts from message delivery (not send time)
  - Auto-deletion runs via a background Supabase Edge Function
  - Local database also purges deleted messages
  - Setting change requires partner confirmation
  - Active timer shown as icon on message bubble

### FR-MSG-010: Message Search
- **Description:** User can search their message history
- **Acceptance Criteria:**
  - Search is performed locally (not on server — messages are encrypted there)
  - SQLite FTS5 (full-text search) over decrypted local message store
  - Results highlight matching terms
  - Tapping result scrolls to that message in chat
  - Search is debounced (300ms) to avoid excessive queries

---

## 5. Media Requirements

### FR-MED-001: Send Image
- **Description:** User can send an image from camera or gallery
- **Acceptance Criteria:**
  - Image compressed to ≤ 2MB before encryption
  - Image encrypted with AES-256 before upload
  - Upload shows progress indicator
  - Thumbnail shown in chat while full image loads
  - Tap thumbnail to view full image
- **Edge Cases:**
  - Upload fails: retry option shown
  - Image too large after compression: user notified

### FR-MED-002: Send Voice Message
- **Description:** User can record and send a voice message
- **Acceptance Criteria:**
  - Hold microphone button to record (max 5 minutes)
  - Waveform visualization shown during recording
  - Release to send, swipe up to cancel
  - Recording encrypted and uploaded
  - Playback with waveform scrubbing in chat

### FR-MED-003: Send Video
- **Description:** User can send a short video clip (max 50MB)
- **Acceptance Criteria:**
  - Video compressed before encryption
  - Thumbnail shown in chat
  - Tap to play inline or full screen
  - Upload progress shown

### FR-MED-004: Media Encryption
- **Description:** All media files are encrypted before leaving the device
- **Acceptance Criteria:**
  - AES-256-GCM used for media encryption
  - Media key is generated per-file and included in the message ciphertext
  - Server stores only ciphertext (Supabase Storage)
  - Media decrypted only on download, never stored as plaintext

### FR-MED-005: Media Auto-Download
- **Description:** Media auto-downloads based on connection type
- **Acceptance Criteria:**
  - Images: auto-download on WiFi and cellular (configurable)
  - Voice: auto-download on WiFi only by default
  - Video: manual download only by default
  - Downloaded media cached locally in app-private directory

---

## 6. Notification Requirements

### FR-NOTIF-001: New Message Push Notification
- **Description:** User receives push notification for new messages when app is not in foreground
- **Acceptance Criteria:**
  - Notification title: partner's display name
  - Notification body: "Sent you a message" (never the message content)
  - Tapping notification opens app to chat screen
  - Notification cleared when chat is opened
- **Privacy:**
  - Message content never in notification payload
  - If device is locked, notification shows minimal info

### FR-NOTIF-002: Notification Management
- **Description:** User can manage notification preferences
- **Acceptance Criteria:**
  - Mute all notifications: 1h, 8h, 24h, forever
  - Notification sound configurable
  - Vibration configurable
  - System notification permission handled gracefully

---

## 7. Encryption Requirements

### FR-CRYPT-001: Signal Protocol Session Establishment
- **Description:** Signal Protocol X3DH key exchange performed during pairing
- **See:** `11_Encryption_Architecture.md` for full details

### FR-CRYPT-002: Message Encryption
- **Description:** Every outgoing message is encrypted using the active Signal session
- **Acceptance Criteria:**
  - Signal Protocol Double Ratchet used for message encryption
  - Each message uses a unique message key
  - No message key is reused

### FR-CRYPT-003: Key Rotation
- **Description:** Encryption keys rotate automatically
- **Acceptance Criteria:**
  - Ratchet advances with every message (forward secrecy)
  - Prekey bundle refreshed when supply runs below 10 keys
  - Device restores session after reinstall via key backup

---

## 8. Profile Requirements

### FR-PROF-001: Set Profile
- **Description:** User sets their display name and optional avatar
- **Acceptance Criteria:**
  - Display name: 1–30 characters
  - Avatar: image from camera or gallery, cropped to circle
  - Avatar stored in Supabase Storage (not encrypted — it is shared with partner)
  - Profile visible to partner only (not publicly listed)

### FR-PROF-002: View Partner Profile
- **Description:** User can view partner's profile (name, avatar, bio, join date)

---

## 9. App Lock Requirements

### FR-LOCK-001: Enable App Lock
- **Description:** User enables biometric or PIN lock
- **Acceptance Criteria:**
  - Biometric: uses local_auth (fingerprint / Face ID)
  - PIN: 6-digit PIN stored as hashed value in secure storage
  - App lock screen shows no message content

### FR-LOCK-002: Auto-Lock
- **Description:** App locks after configurable inactivity period
- **Options:** Immediately | 1 min | 5 min | 15 min | Never
- **Acceptance Criteria:**
  - Timer resets on any user interaction
  - Lock applied when app goes to background regardless of timer

---

## 10. Settings Requirements

### FR-SET-001: Notification Settings
- Mute, sound, vibration, in-app notification banner

### FR-SET-002: Privacy Settings
- Last seen visibility: everyone (partner only, already enforced) | nobody
- Read receipts: on | off
- Typing indicator: on | off

### FR-SET-003: Chat Settings
- Chat background theme
- Font size
- Disappearing message default timer

### FR-SET-004: Security Settings
- App lock toggle and timer
- Active sessions list
- Change PIN

### FR-SET-005: Account Settings
- Change display name
- Change avatar
- Change notification sound
- Export chat (local PDF)
- Delete account

---

## 11. Data Deletion Requirements

### FR-DEL-001: Delete Account
- **Acceptance Criteria:**
  - User must type "DELETE MY ACCOUNT" to confirm
  - All server data for this user deleted (profile, messages, media, keys)
  - Partner notified via push notification
  - Pair dissolved
  - Local database wiped
  - App returns to registration screen

### FR-DEL-002: Clear Chat History
- **Acceptance Criteria:**
  - Deletes all local messages from SQLite
  - Optionally deletes server-side encrypted blobs
  - Partner's local history unaffected (partner owns their copy)
