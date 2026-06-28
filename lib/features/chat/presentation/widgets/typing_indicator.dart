import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

class TypingIndicator extends StatefulWidget {
  const TypingIndicator({super.key});

  @override
  State<TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<TypingIndicator>
    with TickerProviderStateMixin {
  static const _dotCount = 3;
  static const _dotSize = 8.0;
  static const _dotSpacing = 4.0;

  late final List<AnimationController> _controllers;
  late final List<Animation<double>> _animations;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(
      _dotCount,
      (i) => AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 600),
      ),
    );
    _animations = _controllers
        .map((c) => Tween<double>(begin: 0, end: -6).animate(
              CurvedAnimation(parent: c, curve: Curves.easeInOut),
            ))
        .toList();

    // Stagger dots by 150 ms each.
    for (var i = 0; i < _dotCount; i++) {
      Future.delayed(Duration(milliseconds: i * 150), () {
        if (mounted) _controllers[i].repeat(reverse: true);
      });
    }
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bubbleColor = isDark
        ? AppColors.receivedBubbleDark
        : AppColors.receivedBubbleLight;
    final dotColor = isDark
        ? AppColors.receivedBubbleTextDark.withValues(alpha: 0.6)
        : AppColors.receivedBubbleTextLight.withValues(alpha: 0.6);

    return Padding(
      padding: const EdgeInsets.only(left: 12, bottom: 4),
      child: Align(
        alignment: Alignment.centerLeft,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: bubbleColor,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(18),
              topRight: Radius.circular(18),
              bottomLeft: Radius.circular(4),
              bottomRight: Radius.circular(18),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(_dotCount, (i) {
                return Padding(
                  padding: EdgeInsets.only(
                    right: i < _dotCount - 1 ? _dotSpacing : 0,
                  ),
                  child: AnimatedBuilder(
                    animation: _animations[i],
                    builder: (context, child) => Transform.translate(
                      offset: Offset(0, _animations[i].value),
                      child: Container(
                        width: _dotSize,
                        height: _dotSize,
                        decoration: BoxDecoration(
                          color: dotColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}
