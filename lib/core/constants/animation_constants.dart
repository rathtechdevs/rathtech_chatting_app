import 'package:flutter/animation.dart';

abstract final class AnimationDurations {
  static const instant = Duration.zero;
  static const fast = Duration(milliseconds: 150);
  static const normal = Duration(milliseconds: 300);
  static const slow = Duration(milliseconds: 500);
  static const verySlow = Duration(milliseconds: 800);
  static const pageTransition = Duration(milliseconds: 350);
  static const messageBubble = Duration(milliseconds: 200);
  static const typingIndicator = Duration(milliseconds: 600);
}

abstract final class AnimationCurves {
  static const standard = Curves.easeInOut;
  static const decelerate = Curves.decelerate;
  static const accelerate = Curves.fastOutSlowIn;
  static const spring = Curves.elasticOut;
  static const overshoot = Curves.easeOutBack;
  static const emphasized = Curves.easeInOutCubicEmphasized;
}
