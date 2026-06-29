import 'package:flutter/material.dart';

import '../../../../core/constants/app_strings.dart';

class ChatInputBar extends StatefulWidget {
  const ChatInputBar({
    super.key,
    required this.onSend,
    this.isSending = false,
    this.onTypingChanged,
    this.onAttachImage,
    this.onVoiceRecordStart,
    this.onVoiceRecordEnd,
    this.onVoiceRecordCancel,
    this.isRecording = false,
    this.recordingDuration = Duration.zero,
  });

  final void Function(String text) onSend;
  final bool isSending;
  final void Function(bool isTyping)? onTypingChanged;
  final VoidCallback? onAttachImage;
  final VoidCallback? onVoiceRecordStart;
  final VoidCallback? onVoiceRecordEnd;
  final VoidCallback? onVoiceRecordCancel;
  final bool isRecording;
  final Duration recordingDuration;

  @override
  State<ChatInputBar> createState() => _ChatInputBarState();
}

class _ChatInputBarState extends State<ChatInputBar> {
  final _controller = TextEditingController();
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      final hasText = _controller.text.trim().isNotEmpty;
      if (hasText != _hasText) {
        setState(() => _hasText = hasText);
        widget.onTypingChanged?.call(hasText);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _send() {
    final text = _controller.text.trim();
    if (text.isEmpty || widget.isSending) return;
    _controller.clear();
    widget.onSend(text);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (widget.isRecording) {
      return _RecordingBar(
        duration: widget.recordingDuration,
        onCancel: widget.onVoiceRecordCancel,
        onSend: widget.onVoiceRecordEnd,
      );
    }

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // Attachment button
            _AttachButton(onTap: widget.onAttachImage),
            const SizedBox(width: 6),
            // Text field
            Expanded(
              child: Container(
                constraints: const BoxConstraints(maxHeight: 120),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: TextField(
                  controller: _controller,
                  maxLines: null,
                  textInputAction: TextInputAction.newline,
                  keyboardType: TextInputType.multiline,
                  decoration: InputDecoration(
                    hintText: AppStrings.chatInputHint,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    hintStyle: TextStyle(
                      color:
                          colorScheme.onSurface.withValues(alpha: 0.4),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 6),
            // Send or mic button
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              child: _hasText
                  ? _SendButton(
                      key: const ValueKey('send'),
                      onTap: _send,
                      isSending: widget.isSending,
                    )
                  : _MicButton(
                      key: const ValueKey('mic'),
                      onLongPressStart: (_) =>
                          widget.onVoiceRecordStart?.call(),
                      onLongPressEnd: (_) => widget.onVoiceRecordEnd?.call(),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Recording bar ─────────────────────────────────────────────────────────────

class _RecordingBar extends StatefulWidget {
  const _RecordingBar({
    required this.duration,
    required this.onCancel,
    required this.onSend,
  });

  final Duration duration;
  final VoidCallback? onCancel;
  final VoidCallback? onSend;

  @override
  State<_RecordingBar> createState() => _RecordingBarState();
}

class _RecordingBarState extends State<_RecordingBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final m = widget.duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = widget.duration.inSeconds.remainder(60).toString().padLeft(2, '0');

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            // Pulsing red dot
            FadeTransition(
              opacity: _pulse,
              child: Container(
                width: 10,
                height: 10,
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              AppStrings.chatVoiceRecording,
              style: TextStyle(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '$m:$s',
              style: TextStyle(color: colorScheme.primary),
            ),
            const Spacer(),
            // Cancel
            GestureDetector(
              onTap: widget.onCancel,
              child: Icon(
                Icons.delete_outline_rounded,
                color: colorScheme.error,
              ),
            ),
            const SizedBox(width: 12),
            // Send
            GestureDetector(
              onTap: widget.onSend,
              child: Icon(
                Icons.send_rounded,
                color: colorScheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Buttons ───────────────────────────────────────────────────────────────────

class _AttachButton extends StatelessWidget {
  const _AttachButton({required this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Material(
      color: colorScheme.surfaceContainerHighest,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Icon(
            Icons.attach_file_rounded,
            size: 20,
            color: colorScheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
      ),
    );
  }
}

class _MicButton extends StatelessWidget {
  const _MicButton({
    super.key,
    required this.onLongPressStart,
    required this.onLongPressEnd,
  });

  final GestureLongPressStartCallback onLongPressStart;
  final GestureLongPressEndCallback onLongPressEnd;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onLongPressStart: onLongPressStart,
      onLongPressEnd: onLongPressEnd,
      child: Material(
        color: colorScheme.surfaceContainerHighest,
        shape: const CircleBorder(),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Icon(
            Icons.mic_rounded,
            size: 20,
            color: colorScheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
      ),
    );
  }
}

class _SendButton extends StatelessWidget {
  const _SendButton({
    super.key,
    required this.onTap,
    required this.isSending,
  });

  final VoidCallback? onTap;
  final bool isSending;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final enabled = onTap != null && !isSending;

    return Material(
      color: enabled
          ? colorScheme.primary
          : colorScheme.surfaceContainerHighest,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: enabled ? onTap : null,
        customBorder: const CircleBorder(),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: isSending
              ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: colorScheme.primary,
                  ),
                )
              : Icon(
                  Icons.send_rounded,
                  size: 20,
                  color: enabled
                      ? colorScheme.onPrimary
                      : colorScheme.onSurface.withValues(alpha: 0.3),
                ),
        ),
      ),
    );
  }
}
