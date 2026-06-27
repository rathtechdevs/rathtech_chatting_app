# 16 — Animation System

## Purpose
Define all animations in SecureChat — their purpose, implementation approach, duration, curves, and performance requirements.

---

## 1. Animation Philosophy

- All animations must serve a purpose (orientation, feedback, delight)
- Duration: short (150–300ms) for feedback; longer (400–600ms) for transitions
- Default to `Curves.easeInOut` unless a specific curve is specified
- All animations respect `MediaQuery.disableAnimations` — if true, skip to final state
- No animations that block user interaction
- GPU-composited animations only (opacity, transform) — avoid layout-triggering animations

---

## 2. Animation Catalog

### ANIM-001: Message Bubble Appear
**Trigger:** New message inserted into list  
**Description:** Bubble slides up from below with fade in  
**Duration:** 300ms  
**Curve:** `Curves.easeOutCubic`  
**Implementation:**
```dart
AnimatedList + SlideTransition(
  position: Tween(begin: Offset(0, 0.3), end: Offset.zero)
    .animate(CurvedAnimation(parent: controller, curve: Curves.easeOutCubic)),
  child: FadeTransition(opacity: controller, child: bubble),
)
```

### ANIM-002: Typing Indicator (Three Dots)
**Trigger:** Partner is typing  
**Description:** Three dots bounce sequentially in a wave pattern  
**Duration:** 600ms loop  
**Curve:** `Curves.easeInOut`  
**Implementation:** `AnimationController` with staggered `TweenSequence` per dot; translate Y by -4dp peak

### ANIM-003: Message Send Success
**Trigger:** Message status changes from "sending" to "sent"  
**Description:** Spinner fades out, checkmark icon scales in  
**Duration:** 200ms  
**Curve:** `Curves.easeOut`  
**Implementation:** `AnimatedSwitcher` between loading indicator and icon

### ANIM-004: Reaction Float
**Trigger:** Reaction added to a message  
**Description:** Selected emoji floats up from picker and lands on message bubble  
**Duration:** 400ms  
**Curve:** `Curves.easeOut` for translate; `Curves.elasticOut` for final scale bounce  
**Implementation:** `OverlayEntry` with animated position + scale transform

### ANIM-005: App Unlock Reveal
**Trigger:** Successful biometric/PIN unlock  
**Description:** Lock screen fades out, revealing chat content underneath  
**Duration:** 400ms  
**Curve:** `Curves.easeOut`  
**Implementation:** `FadeTransition` on AppLockOverlay

### ANIM-006: Image Viewer Open
**Trigger:** User taps an image in chat  
**Description:** Image expands from thumbnail position to full-screen (Hero animation)  
**Duration:** Flutter default Hero (300ms)  
**Implementation:**
```dart
// In chat bubble:
Hero(tag: 'image_${message.id}', child: thumbnail)

// In ImageViewerScreen:
Hero(tag: 'image_${message.id}', child: fullImage)
```

### ANIM-007: Image Viewer Close
**Trigger:** User swipes down on image viewer  
**Description:** Image follows finger, snaps back or dismisses with Hero  
**Implementation:** `DraggableScrollableSheet` or `GestureDetector` with custom dismiss threshold

### ANIM-008: Message Long Press Context Menu
**Trigger:** Long press on message bubble  
**Description:** Bottom sheet slides up from screen bottom  
**Duration:** 300ms (Material default)  
**Implementation:** `showModalBottomSheet` with `transitionAnimationController`

### ANIM-009: Offline Banner Enter/Exit
**Trigger:** Network connectivity changes  
**Description:** Yellow banner slides down from top (enter); slides up and fades (exit)  
**Duration:** 350ms  
**Curve:** `Curves.easeInOut`  
**Implementation:** `AnimatedContainer` or `SizeTransition`

### ANIM-010: New Message Notification Badge
**Trigger:** New message received while scrolled up  
**Description:** "New messages ↓" badge slides in at bottom, tapping scrolls to bottom  
**Duration:** 300ms  
**Curve:** `Curves.easeOut`  
**Implementation:** `AnimatedPositioned` or `SlideTransition`

### ANIM-011: Pair Success Confetti
**Trigger:** Partner accepts invite code — both users are now paired  
**Description:** Subtle confetti burst (3–5 particles) over success screen  
**Duration:** 1200ms  
**Library:** Custom painter or `confetti` package  
**Note:** One-time animation, not looped

### ANIM-012: Profile Avatar Upload Progress
**Trigger:** Avatar image is being uploaded  
**Description:** Circular progress overlay on avatar image  
**Duration:** Based on upload speed  
**Implementation:** `CircularProgressIndicator` layered over avatar

### ANIM-013: Message Deletion Fade
**Trigger:** Message deleted  
**Description:** Message bubble fades out and collapses in height  
**Duration:** 400ms  
**Curve:** `Curves.easeIn`  
**Implementation:** `AnimatedList.removeItem()` with `FadeTransition` + `SizeTransition`

### ANIM-014: Page Transitions
**Trigger:** Navigation between screens  
**Default:** Material slide transition (right-to-left push, left-to-right pop)  
**Overrides:**
- Auth → Chat: Fade transition (old auth stack replaced)
- Chat → Image Viewer: Hero transition
- Any → App Lock: No transition (instant overlay)

---

## 3. Animation Performance Rules

1. **GPU-composited only:** Use only `opacity` and `transform` (translate, scale, rotate). Never animate `width`, `height`, `padding`, or `color` directly.
2. **RepaintBoundary:** Wrap animated widgets in `RepaintBoundary` to isolate repainting.
3. **Avoid AnimatedContainer for colors:** Use `AnimatedOpacity` with color overlays instead.
4. **Disable in tests:** All animation controllers accept a `vsync` from `TestVSync` or use `WidgetTester.pump`.
5. **Profile regularly:** Run `flutter run --profile` and check DevTools Frame Timeline after each new animation.

---

## 4. Global Animation Toggle

```dart
// Check before applying any animation
extension AnimationCheck on BuildContext {
  bool get shouldAnimate => !MediaQuery.of(this).disableAnimations;
}

// In widget
child: shouldAnimate
    ? AnimatedWidget(...)
    : FinalStateWidget(...),
```

---

## 5. Animation Constants

```dart
// lib/core/constants/animation_constants.dart
abstract class AppAnimations {
  static const Duration short = Duration(milliseconds: 150);
  static const Duration medium = Duration(milliseconds: 300);
  static const Duration long = Duration(milliseconds: 500);
  static const Duration veryLong = Duration(milliseconds: 800);

  static const Curve defaultCurve = Curves.easeInOut;
  static const Curve entryCurve = Curves.easeOutCubic;
  static const Curve exitCurve = Curves.easeInCubic;
  static const Curve bounceCurve = Curves.elasticOut;
}
```
