import 'dart:ui';

import 'package:flutter/material.dart';

/// A translucent, softly blurred surface used throughout the app.
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? margin;
  final Color? color;
  final Clip clipBehavior;
  final ShapeBorder? shape;

  const GlassCard({
    super.key,
    required this.child,
    this.margin = const EdgeInsets.all(4),
    this.color,
    this.clipBehavior = Clip.antiAlias,
    this.shape,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final radius = shape is RoundedRectangleBorder
        ? (shape as RoundedRectangleBorder)
            .borderRadius
            .resolve(Directionality.of(context))
        : BorderRadius.circular(22);
    final base = color ?? theme.colorScheme.surface;

    return Padding(
      padding: margin ?? EdgeInsets.zero,
      child: ClipRRect(
        borderRadius: radius,
        clipBehavior: clipBehavior,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: base.withOpacity(isDark ? 0.38 : 0.58),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withOpacity(isDark ? 0.13 : 0.48),
                  base.withOpacity(isDark ? 0.22 : 0.30),
                ],
              ),
              borderRadius: radius,
              border: Border.all(
                color: Colors.white.withOpacity(isDark ? 0.22 : 0.72),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isDark ? 0.16 : 0.07),
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}
