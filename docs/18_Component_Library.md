# 18 — Component Library

## Purpose
Catalog every reusable widget in SecureChat — its purpose, props, behavior, and where it is used.

---

## 1. Component Categories

| Category | Description |
|---|---|
| Foundation | Base atoms: avatars, buttons, inputs, badges |
| Chat | Message-specific components |
| Layout | Structural widgets: app bars, sheets, banners |
| Feedback | Loading, error, empty state widgets |
| Media | Image, voice, video display widgets |

---

## 2. Foundation Components

### COMP-001: `AppAvatar`
**Location:** `lib/core/components/app_avatar.dart`  
**Purpose:** Circular user avatar with fallback initials

**Props:**
| Prop | Type | Required | Default |
|---|---|---|---|
| `imageUrl` | `String?` | No | null |
| `displayName` | `String` | Yes | — |
| `size` | `double` | No | 40 |
| `onTap` | `VoidCallback?` | No | null |

**Behavior:**
- Shows avatar image if `imageUrl` is not null and loads successfully
- Falls back to initials (first letter of `displayName`) on a colored background
- Background color derived from `displayName` hashCode → consistent color
- Circular shape always

### COMP-002: `PrimaryButton`
**Location:** `lib/core/components/primary_button.dart`  
**Purpose:** Full-width primary action button with loading state

**Props:**
| Prop | Type | Required | Default |
|---|---|---|---|
| `label` | `String` | Yes | — |
| `onPressed` | `VoidCallback?` | Yes | — |
| `isLoading` | `bool` | No | false |
| `icon` | `IconData?` | No | null |

**Behavior:**
- Disabled when `onPressed` is null or `isLoading` is true
- Shows `CircularProgressIndicator` in place of label when `isLoading`
- Full-width by default

### COMP-003: `AppTextField`
**Location:** `lib/core/components/app_text_field.dart`  
**Purpose:** Styled text input field with consistent appearance

**Props:**
| Prop | Type | Required | Default |
|---|---|---|---|
| `controller` | `TextEditingController` | Yes | — |
| `hint` | `String` | Yes | — |
| `keyboardType` | `TextInputType` | No | `text` |
| `onChanged` | `Function(String)?` | No | null |
| `validator` | `String? Function(String?)?` | No | null |
| `prefix` | `Widget?` | No | null |
| `suffix` | `Widget?` | No | null |
| `obscureText` | `bool` | No | false |
| `maxLines` | `int?` | No | 1 |

### COMP-004: `StatusBadge`
**Location:** `lib/core/components/status_badge.dart`  
**Purpose:** Online/offline indicator dot

**Props:**
| Prop | Type | Required |
|---|---|---|
| `isOnline` | `bool` | Yes |
| `size` | `double` | No |

**Behavior:** Green dot when online, gray when offline. Positioned as overlay on avatar.

### COMP-005: `LoadingOverlay`
**Location:** `lib/core/components/loading_overlay.dart`  
**Purpose:** Full-screen loading overlay for blocking operations (e.g., account deletion)

**Props:**
| Prop | Type | Required |
|---|---|---|
| `isLoading` | `bool` | Yes |
| `child` | `Widget` | Yes |
| `message` | `String?` | No |

---

## 3. Chat Components

### COMP-010: `MessageBubble`
**Location:** `lib/features/chat/presentation/widgets/message_bubble.dart`  
**Purpose:** Renders a single message — text, image, voice, or system message

**Props:**
| Prop | Type | Required |
|---|---|---|
| `message` | `Message` | Yes |
| `isOutgoing` | `bool` | Yes |
| `showAvatar` | `bool` | No |
| `onLongPress` | `VoidCallback` | Yes |
| `onReactionTap` | `Function(String)` | No |

**Variants:**
- `TextMessageBubble` — Plain text content
- `ImageMessageBubble` — Thumbnail + tap to view full
- `VoiceMessageBubble` — Waveform + play/pause + duration
- `SystemMessageBubble` — Centered gray text (e.g., "Pairing complete")
- `DeletedMessageBubble` — Italic "[Message deleted]"

### COMP-011: `MessageStatusIcon`
**Location:** `lib/features/chat/presentation/widgets/message_status_icon.dart`  
**Purpose:** Shows send/deliver/read status as icon

| Status | Icon | Color |
|---|---|---|
| pending | clock | gray |
| sending | loading spinner | gray |
| sent | single checkmark | gray |
| delivered | double checkmark | gray |
| read | double checkmark | blue |
| failed | exclamation circle | red |

### COMP-012: `TypingIndicator`
**Location:** `lib/features/chat/presentation/widgets/typing_indicator.dart`  
**Purpose:** Animated "..." dots shown when partner is typing

**Behavior:**
- Shows partner avatar on left
- Three animated dots with wave animation
- Auto-hides when `isTyping` becomes false

### COMP-013: `ChatInputBar`
**Location:** `lib/features/chat/presentation/widgets/chat_input_bar.dart`  
**Purpose:** Bottom message input: attachment button + text field + send/voice button

**Props:**
| Prop | Type | Required |
|---|---|---|
| `onSend` | `Function(String)` | Yes |
| `onAttachment` | `VoidCallback` | Yes |
| `onVoiceStart` | `VoidCallback` | Yes |
| `onTypingChanged` | `Function(bool)` | Yes |

**Behavior:**
- When text is empty: show attachment icon (left) + microphone icon (right)
- When text is non-empty: hide attachment, show send button (right)
- Multi-line expand up to 6 lines

### COMP-014: `ReactionPicker`
**Location:** `lib/features/chat/presentation/widgets/reaction_picker.dart`  
**Purpose:** Emoji picker overlay for reacting to messages

**Props:**
| Prop | Type | Required |
|---|---|---|
| `onReactionSelected` | `Function(String emoji)` | Yes |
| `currentReaction` | `String?` | No |

**Emojis shown:** ❤️ 😂 😮 😢 😡 👍 👎 🙏

### COMP-015: `MessageContextMenu`
**Location:** `lib/features/chat/presentation/widgets/message_context_menu.dart`  
**Purpose:** Bottom sheet with actions for a long-pressed message

**Actions (conditional):**
- React (always)
- Edit (own message, < 15 min old)
- Delete (own message, any time)
- Copy text (text messages only)
- [Cancel]

### COMP-016: `DateSeparator`
**Location:** `lib/features/chat/presentation/widgets/date_separator.dart`  
**Purpose:** Sticky date header between messages from different days

**Format:**
- Today → "Today"
- Yesterday → "Yesterday"
- This week → "Monday", "Tuesday", etc.
- Older → "June 24, 2026"

### COMP-017: `VoiceRecorder`
**Location:** `lib/features/chat/presentation/widgets/voice_recorder.dart`  
**Purpose:** Hold-to-record voice message UI

**Behavior:**
- Press and hold microphone button → recording starts
- Show recording duration, waveform visualization
- Swipe left to cancel
- Release to send

### COMP-018: `ScrollToBottomFab`
**Location:** `lib/features/chat/presentation/widgets/scroll_to_bottom_fab.dart`  
**Purpose:** Floating "↓ N new" button when scrolled up and new messages arrive

**Props:**
| Prop | Type | Required |
|---|---|---|
| `onTap` | `VoidCallback` | Yes |
| `newMessageCount` | `int` | Yes |

---

## 4. Layout Components

### COMP-020: `ChatAppBar`
**Location:** `lib/features/chat/presentation/widgets/chat_app_bar.dart`  
**Purpose:** Top bar of chat screen with partner info

**Shows:**
- Back button (iOS/Android native)
- Partner avatar (with online status dot)
- Partner name
- Sub-text: "Online" or "Last seen X"
- Action icons: video call (V2), info/profile

### COMP-021: `AppBottomSheet`
**Location:** `lib/core/components/app_bottom_sheet.dart`  
**Purpose:** Standardized modal bottom sheet with drag handle and rounded corners

**Usage:**
```dart
showModalBottomSheet(
  context: context,
  builder: (_) => AppBottomSheet(
    title: 'Options',
    children: [...],
  ),
);
```

### COMP-022: `OfflineBanner`
**Location:** `lib/core/components/offline_banner.dart`  
**Purpose:** Animated banner shown when network is unavailable

**Shows:** Amber background, wifi-off icon, "You're offline" text, queued message count

---

## 5. Feedback Components

### COMP-030: `LoadingShimmer`
**Location:** `lib/core/components/loading_shimmer.dart`  
**Purpose:** Skeleton placeholder for loading states

**Variants:**
- `LoadingShimmer.messageBubble()` — Shimmer bubble
- `LoadingShimmer.avatar()` — Circular shimmer
- `LoadingShimmer.listTile()` — List item shimmer

### COMP-031: `EmptyState`
**Location:** `lib/core/components/empty_state.dart`  
**Purpose:** Empty state illustration + message for empty lists

**Props:**
| Prop | Type | Required |
|---|---|---|
| `icon` | `IconData` | Yes |
| `title` | `String` | Yes |
| `subtitle` | `String?` | No |
| `action` | `Widget?` | No |

### COMP-032: `ErrorView`
**Location:** `lib/core/components/error_view.dart`  
**Purpose:** Inline error display with retry button

**Props:**
| Prop | Type | Required |
|---|---|---|
| `failure` | `Failure` | Yes |
| `onRetry` | `VoidCallback?` | No |

**Behavior:** Maps `Failure` type to user-friendly message (uses `FailureMessageMapper`)

---

## 6. Component Rules

1. **No business logic** — components receive data as props; they do not read providers directly (except ViewModel providers in Screen widgets)
2. **const constructors** — use `const` for all widgets that don't depend on runtime data
3. **Named parameters** — all props use named parameters
4. **Documentation** — one-line doc comment per component describing purpose
5. **Separate file** — one component per file; file name matches widget name in snake_case
6. **Avoid anonymous lambdas in build** — extract callbacks to named methods to avoid unnecessary rebuilds
