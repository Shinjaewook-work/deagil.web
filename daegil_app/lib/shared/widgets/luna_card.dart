import 'package:flutter/material.dart';

import '../../app/theme/luna_theme.dart';

class LunaCard extends StatelessWidget {
  const LunaCard({
    required this.child,
    this.padding,
    this.color,
    this.margin,
    super.key,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final Color? color;
  final EdgeInsetsGeometry? margin;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: color,
      margin: margin,
      child: Padding(
        padding: padding ?? const EdgeInsets.all(LunaSpacing.lg),
        child: child,
      ),
    );
  }
}
