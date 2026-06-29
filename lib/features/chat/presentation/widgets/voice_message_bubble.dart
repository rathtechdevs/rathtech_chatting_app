import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';

import '../../../../features/media/providers.dart';
import '../../domain/entities/message.dart';

class VoiceMessageBubble extends ConsumerStatefulWidget {
  const VoiceMessageBubble({
    super.key,
    required this.message,
    required this.isOwn,
    required this.bubbleColor,
    required this.textColor,
    required this.onLongPress,
  });

  final Message message;
  final bool isOwn;
  final Color bubbleColor;
  final Color textColor;
  final VoidCallback onLongPress;

  @override
  ConsumerState<VoiceMessageBubble> createState() =>
      _VoiceMessageBubbleState();
}

class _VoiceMessageBubbleState extends ConsumerState<VoiceMessageBubble> {
  bool _isLoading = false;

  // Deterministic waveform bars seeded by message ID so the same message
  // always looks the same across devices.
  late final List<double> _bars = _buildBars();

  List<double> _buildBars() {
    final rng = math.Random(widget.message.id.hashCode);
    return List.generate(30, (_) => 0.15 + rng.nextDouble() * 0.85);
  }

  @override
  Widget build(BuildContext context) {
    final currentId = ref.watch(currentlyPlayingMessageIdProvider);
    final isThisPlaying = currentId == widget.message.id;

    final totalMs = widget.message.mediaDurationMs ?? 0;
    final canPlay = widget.message.mediaLocalPath != null;

    return GestureDetector(
      onLongPress: widget.onLongPress,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: SizedBox(
          width: 220,
          child: Row(
            children: [
              // Play / pause / loading button
              GestureDetector(
                onTap: canPlay ? _togglePlayback : null,
                child: _isLoading
                    ? SizedBox(
                        width: 36,
                        height: 36,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: widget.textColor,
                        ),
                      )
                    : Icon(
                        isThisPlaying
                            ? Icons.pause_circle_filled_rounded
                            : Icons.play_circle_filled_rounded,
                        size: 36,
                        color: canPlay
                            ? widget.textColor
                            : widget.textColor.withValues(alpha: 0.4),
                      ),
              ),
              const SizedBox(width: 8),
              // Waveform + duration
              Expanded(
                child: StreamBuilder<Duration>(
                  stream: isThisPlaying
                      ? ref.read(audioPlayerProvider).positionStream
                      : null,
                  builder: (context, snapshot) {
                    final pos = snapshot.data ?? Duration.zero;
                    final progress = totalMs > 0
                        ? (pos.inMilliseconds / totalMs).clamp(0.0, 1.0)
                        : 0.0;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Waveform
                        SizedBox(
                          height: 32,
                          child: Row(
                            children: List.generate(_bars.length, (i) {
                              final played = i / _bars.length < progress;
                              return Expanded(
                                child: Padding(
                                  padding:
                                      const EdgeInsets.symmetric(horizontal: 1),
                                  child: FractionallySizedBox(
                                    heightFactor: _bars[i],
                                    child: DecoratedBox(
                                      decoration: BoxDecoration(
                                        color: played
                                            ? widget.textColor
                                            : widget.textColor
                                                .withValues(alpha: 0.35),
                                        borderRadius: BorderRadius.circular(2),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }),
                          ),
                        ),
                        const SizedBox(height: 2),
                        // Duration label
                        Text(
                          isThisPlaying
                              ? _formatDuration(pos)
                              : _formatDuration(Duration(milliseconds: totalMs)),
                          style: TextStyle(
                            fontSize: 10,
                            color: widget.textColor.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _togglePlayback() async {
    final localPath = widget.message.mediaLocalPath;
    if (localPath == null) return;

    final player = ref.read(audioPlayerProvider);
    final notifier = ref.read(currentlyPlayingMessageIdProvider.notifier);
    final isThisPlaying =
        ref.read(currentlyPlayingMessageIdProvider) == widget.message.id;

    if (isThisPlaying) {
      await player.pause();
      notifier.state = null;
      return;
    }

    if (mounted) setState(() => _isLoading = true);
    try {
      // Stop whatever is currently playing.
      if (ref.read(currentlyPlayingMessageIdProvider) != null) {
        await player.stop();
      }
      await player.setFilePath(localPath);
      await player.play();
      notifier.state = widget.message.id;

      // Auto-reset state when playback completes.
      player.playerStateStream
          .where((s) => s.processingState == ProcessingState.completed)
          .first
          .then((_) {
        if (mounted &&
            ref.read(currentlyPlayingMessageIdProvider) == widget.message.id) {
          ref.read(currentlyPlayingMessageIdProvider.notifier).state = null;
        }
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  static String _formatDuration(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }
}
