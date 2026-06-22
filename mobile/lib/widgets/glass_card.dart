import 'package:flutter/material.dart';
import '../theme/aether_theme.dart';

class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;

  const GlassCard({super.key, required this.child, this.padding, this.margin});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: margin,
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AetherColors.glass,
        border: Border.all(color: AetherColors.glassBorder),
        borderRadius: BorderRadius.circular(16),
      ),
      child: child,
    );
  }
}
