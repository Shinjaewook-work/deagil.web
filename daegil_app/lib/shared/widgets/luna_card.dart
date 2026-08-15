import 'package:flutter/material.dart';

import '../../app/theme/luna_theme.dart';

class LunaCard extends StatelessWidget {
  const LunaCard({required this.child, this.padding, super.key});

  final Widget child;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: padding ?? const EdgeInsets.all(LunaSpacing.lg),
        child: child,
      ),
    );
  }
}
