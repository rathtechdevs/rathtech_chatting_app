# 15 — UI/UX Guidelines

## Purpose
Define the complete design language — design principles, Material 3 usage, layout rules, interaction patterns, accessibility, and platform conventions.

---

## 1. Design Principles

### 1.1 Intimacy
The app is designed for two people who care deeply about each other. The UI must feel warm, personal, and intimate — not clinical or productivity-oriented.

- Use soft, warm colors (not harsh blues/grays)
- Rounded corners everywhere
- Subtle animations that feel alive
- Message bubbles that feel like handwritten notes, not data rows

### 1.2 Privacy by Appearance
The UI should visually communicate that this is a private space:
- No ads, banners, or external content
- No visible account numbers or technical IDs
- Content-first layout — the messages are the hero

### 1.3 Calm
No aggressive notifications, no red badges, no FOMO mechanics. The app is a calm, focused space.

### 1.4 Delight
Small moments of delight:
- Message send animation (bubble appears with a subtle bounce)
- Reaction animations (emoji floats up)
- Typing indicator animation (three dots with wave effect)
- App unlock animation (content reveals smoothly)

---

## 2. Material 3 Usage

SecureChat uses **Material 3 (Material You)** throughout.

### 2.1 ColorScheme

Generated from a brand seed color using `ColorScheme.fromSeed()`.

**Brand Color:** `#7C5CBF` (warm purple — intimate, trustworthy, modern)

```dart
ColorScheme.fromSeed(
  seedColor: const Color(0xFF7C5CBF),
  brightness: Brightness.light, // or Brightness.dark
)
```

**Derived colors used:**
| Role | Usage |
|---|---|
| `primary` | Primary actions, FABs, active states |
| `onPrimary` | Text/icons on primary |
| `primaryContainer` | Outgoing message bubbles |
| `onPrimaryContainer` | Text on outgoing message bubbles |
| `secondaryContainer` | Incoming message bubbles |
| `onSecondaryContainer` | Text on incoming message bubbles |
| `surface` | Chat background (default) |
| `surfaceVariant` | Input field background |
| `error` | Error states |
| `outline` | Dividers, borders |

### 2.2 Typography

Uses Material 3 `TextTheme`. Key roles:

| TextStyle | Usage |
|---|---|
| `displaySmall` | Not used |
| `headlineMedium` | Screen titles |
| `headlineSmall` | Section headers |
| `titleLarge` | AppBar title, contact name |
| `titleMedium` | Chat list item name |
| `bodyLarge` | Message bubble content |
| `bodyMedium` | Metadata (timestamps, status) |
| `labelLarge` | Buttons |
| `labelSmall` | Status indicators |

**Font:** System default (follows device font)

---

## 3. Layout Rules

### 3.1 Spacing Scale

All spacing uses multiples of 4dp:

| Token | Value | Usage |
|---|---|---|
| `spacing2` | 2dp | Micro gaps (icon padding) |
| `spacing4` | 4dp | Tight padding |
| `spacing8` | 8dp | Element gap |
| `spacing12` | 12dp | Card internal padding |
| `spacing16` | 16dp | Standard padding |
| `spacing24` | 24dp | Section spacing |
| `spacing32` | 32dp | Large gaps |
| `spacing48` | 48dp | Screen edge padding |

### 3.2 Border Radius Scale

| Token | Value | Usage |
|---|---|---|
| `radiusSmall` | 4dp | Input fields, chips |
| `radiusMedium` | 12dp | Cards, bottom sheets |
| `radiusLarge` | 20dp | Message bubbles |
| `radiusFull` | 999dp | Circular elements, FABs |

### 3.3 Touch Targets

Minimum 48x48dp for all interactive elements. Tap area can extend beyond visual size using `GestureDetector` with padding.

---

## 4. Screen Designs

### 4.1 Login Screen
- Clean, single-purpose layout
- Logo + app name centered at top 1/3
- Tab bar: Phone | Email
- Single text input with large, readable text
- Primary CTA button at bottom
- No distracting graphics

### 4.2 Chat Screen (Main)
- Full-screen message list (no side padding wasted)
- AppBar: partner avatar (left), name + online status (center), icons (right)
- Sticky date separators (e.g., "Today", "Monday, June 24")
- Message input bar fixed at bottom: attachment icon + text field + send button
- Input lifts above keyboard (resizeToAvoidBottomInset)
- Typing indicator appears between last message and input bar
- Scroll-to-bottom FAB appears when not at bottom
- Offline banner at top (amber, non-intrusive)

### 4.3 Message Bubbles
- Outgoing: `primaryContainer` color, right-aligned, radius: (20, 20, 4, 20)
- Incoming: `secondaryContainer` color, left-aligned, radius: (20, 20, 20, 4)
- Partner avatar shown next to incoming messages (first in group)
- Timestamp shown as small text below bubble (right-aligned)
- Status icon (sent/delivered/read) next to outgoing timestamp
- Max width: 75% of screen width

### 4.4 Image Viewer Screen
- Full-screen black background
- Image fills screen (fit: contain)
- Pinch to zoom (InteractiveViewer)
- Single tap toggles AppBar and download button
- Swipe down to dismiss (hero animation from chat)

### 4.5 Settings Screen
- List-based layout using `ListTile`
- Grouped sections with `Divider` separators
- Section headers in `bodySmall` with `secondaryContainer` background

---

## 5. Message Bubble Layout

```
┌─────────────────────────────────┐
│  [Avatar]                       │  ← Incoming
│           ┌─────────────────┐   │
│           │ Message content │   │
│           │                 │   │
│           └─────────────────┘   │
│            12:34 ✓✓             │
│                  [❤️ 1]        │  ← Reaction badge
└─────────────────────────────────┘

                ┌─────────────────┐  ← Outgoing
                │ Message content │
                │                 │
                └─────────────────┘
                   12:34 ✓✓ [❤️ 1]
```

---

## 6. Interaction Patterns

### 6.1 Long Press Menu (Message)
Long-press a message bubble shows a `showModalBottomSheet` (not popup menu) with:
- React (emoji picker — 8 options)
- Reply (V2 feature placeholder)
- Edit (own messages only, within 15 min)
- Delete (own messages only)
- Copy text (text messages only)
- [Cancel]

### 6.2 Swipe Actions
- Swipe right on message: quote/reply (V2)
- Swipe left in chat: back to home (iOS natural behavior)

### 6.3 Pull to Refresh
Not used — real-time is the source of truth. Pagination triggers on scroll-to-top.

### 6.4 Text Input Behavior
- Auto-focus on ChatScreen entry
- Send button: shows when input is non-empty
- Attachment button: shows when input is empty
- Multi-line input: auto-expands up to 6 lines, then scrollable
- Return key: sends message (not newline) — Shift+Return = newline on iOS keyboard with external keyboard

---

## 7. Accessibility

### 7.1 Semantic Labels
All interactive elements have `Semantics` wrappers or `tooltip` strings:
- Send button: `Semantics(label: AppStrings.sendMessage)`
- Message bubble: `Semantics(label: '${sender}: $content, ${time}')`
- Status icon: `Semantics(label: 'Message ${status}')`

### 7.2 Color Contrast
- All text on `primaryContainer`: minimum 4.5:1 ratio
- All text on `secondaryContainer`: minimum 4.5:1 ratio
- Verified with `flutter_contrast_checker` during development

### 7.3 Text Scaling
- App supports Dynamic Type / system font size scaling
- No absolute font sizes — all from `TextTheme`
- Layout tested at 1.0x, 1.3x, and 2.0x text scale

### 7.4 Reduced Motion
- Respect `MediaQuery.disableAnimations`
- When true: skip animations, use instant transitions

---

## 8. Platform Conventions

### iOS-specific
- Use `CupertinoPageRoute` for routes that feel more native (optional)
- Swipe-back gesture preserved (GoRouter + Navigator 2.0 supports this)
- Status bar style: `SystemChrome.setSystemUIOverlayStyle()`

### Android-specific
- Handle back button via `PopScope` widget
- Respect Android 13+ predictive back gesture
- Edge-to-edge display: `SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge)`

---

## 9. Dark Mode

Full dark mode support using `ThemeMode.system`:

```dart
MaterialApp.router(
  theme: AppTheme.light,
  darkTheme: AppTheme.dark,
  themeMode: ThemeMode.system,  // Follows device setting
)
```

Both themes derived from same seed color, different brightness.

---

## 10. Error States

### Empty State (no messages)
- Centered illustration (simple, line-art style)
- Headline: "Start your conversation"
- Sub-label: "Send your first message"

### Loading State
- Shimmer placeholders for message bubbles
- Skeleton for partner avatar and name in AppBar

### Error State
- Inline error banner (not full-screen) with retry button
- For critical errors: `AlertDialog` with clear message and action

### Network Error
- Offline banner at top of chat: "You're offline. Messages will be sent when you reconnect."
