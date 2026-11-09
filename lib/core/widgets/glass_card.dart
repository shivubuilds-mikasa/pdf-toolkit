import 'dart:ui';

import 'package:flutter/material.dart';

/// A clear, softly blurred surface used throughout the app.
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
    final blur = ImageFilter.blur(sigmaX: 7, sigmaY: 7);
    final backdropGroup = BackdropGroup.of(context);
    final glassContent = DecoratedBox(
      decoration: BoxDecoration(
        color: base.withOpacity(isDark ? 0.10 : 0.07),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withOpacity(isDark ? 0.09 : 0.14),
            base.withOpacity(isDark ? 0.07 : 0.04),
          ],
        ),
        borderRadius: radius,
        border: Border.all(
          color: Colors.white.withOpacity(isDark ? 0.20 : 0.48),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: child,
      ),
    );

    return Padding(
      padding: margin ?? EdgeInsets.zero,
      child: ClipRRect(
        borderRadius: radius,
        clipBehavior: clipBehavior,
        child: backdropGroup == null
            ? BackdropFilter(filter: blur, child: glassContent)
            : BackdropFilter.grouped(filter: blur, child: glassContent),
      ),
    );
  }
}
