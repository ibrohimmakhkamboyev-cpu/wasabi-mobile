import 'package:flutter/animation.dart';

class WasabiOpeningTimeline {
  const WasabiOpeningTimeline._();

  static const duration = Duration(milliseconds: 3200);

  static const drop = Interval(.056, .203, curve: Curves.easeInCubic);
  static const impact = Interval(.175, .297, curve: Curves.easeOutBack);
  static const ingredients = Interval(.225, .453, curve: Curves.easeOutCubic);
  static const orbit = Interval(.390, .594, curve: Curves.easeInOutCubic);
  static const brush = Interval(.516, .688, curve: Curves.easeInOutCubic);
  static const logo = Interval(.578, .766, curve: Curves.easeOutQuart);
  static const homeReveal = Interval(.844, .984, curve: Curves.easeInOutQuart);
  static const homeWidgets = Interval(.900, 1, curve: Curves.easeOutCubic);
}
