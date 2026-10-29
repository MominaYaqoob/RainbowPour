import 'package:flutter/material.dart';

/// Maps [v] from the range [a]..[b] to 0..1 (clamped), through [curve].
double seg(double v, double a, double b, [Curve curve = Curves.linear]) =>
    curve.transform(((v - a) / (b - a)).clamp(0.0, 1.0));

/// Cross-fade route. With [zoom] the new page also scales in from 1.12.
Route<T> fadeRoute<T>(
  Widget page, {
  Duration duration = const Duration(milliseconds: 600),
  bool zoom = false,
}) {
  return PageRouteBuilder<T>(
    transitionDuration: duration,
    reverseTransitionDuration: duration,
    pageBuilder: (_, _, _) => page,
    transitionsBuilder: (_, animation, _, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
      );
      final faded = FadeTransition(opacity: curved, child: child);
      if (!zoom) return faded;
      return ScaleTransition(
        scale: Tween(begin: 1.12, end: 1.0).animate(curved),
        child: faded,
      );
    },
  );
}
