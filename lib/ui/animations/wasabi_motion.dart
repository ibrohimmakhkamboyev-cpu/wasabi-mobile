import 'package:flutter/material.dart';

/// Shared motion primitives keep interactions quick and consistent across the app.
class WasabiMotion {
  const WasabiMotion._();

  static Duration duration(BuildContext context, Duration value) {
    return MediaQuery.maybeOf(context)?.disableAnimations == true
        ? Duration.zero
        : value;
  }
}

class WasabiFadeUp extends StatelessWidget {
  const WasabiFadeUp(
      {super.key, required this.child, this.delay = Duration.zero});

  final Widget child;
  final Duration delay;

  @override
  Widget build(BuildContext context) {
    final duration = WasabiMotion.duration(
      context,
      const Duration(milliseconds: 240),
    );
    final total = duration + delay;
    final start = total.inMicroseconds == 0
        ? 0.0
        : delay.inMicroseconds / total.inMicroseconds;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: total,
      curve: Interval(start.clamp(0.0, 1.0), 1, curve: Curves.easeOutCubic),
      builder: (context, value, child) => Opacity(
        opacity: value,
        child: Transform.translate(
          offset: Offset(0, 10 * (1 - value)),
          child: child,
        ),
      ),
      child: child,
    );
  }
}

class WasabiAnimatedNumber extends StatelessWidget {
  const WasabiAnimatedNumber({
    super.key,
    required this.value,
    this.style,
    this.textAlign,
  });

  final int value;
  final TextStyle? style;
  final TextAlign? textAlign;

  @override
  Widget build(BuildContext context) {
    final duration = WasabiMotion.duration(
      context,
      const Duration(milliseconds: 180),
    );
    return AnimatedSwitcher(
      duration: duration,
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, .35),
            end: Offset.zero,
          ).animate(animation),
          child: child,
        ),
      ),
      child: Text(
        '$value',
        key: ValueKey(value),
        textAlign: textAlign,
        style: style,
      ),
    );
  }
}
