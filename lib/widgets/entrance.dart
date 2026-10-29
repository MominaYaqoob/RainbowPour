import 'package:flutter/material.dart';

import '../core/anim.dart';

/// Fades and lifts [child] in between [begin] and [end] (0..1) of [progress].
class Entrance extends StatelessWidget {
  const Entrance({
    super.key,
    required this.progress,
    required this.begin,
    required this.end,
    required this.child,
    this.rise = 22,
  });

  final Animation<double> progress;
  final double begin;
  final double end;
  final double rise;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: progress,
      child: child,
      builder: (context, child) {
        final p = seg(progress.value, begin, end, Curves.easeOutCubic);
        return Opacity(
          opacity: p,
          child: Transform.translate(
            offset: Offset(0, (1 - p) * rise),
            child: child,
          ),
        );
      },
    );
  }
}
