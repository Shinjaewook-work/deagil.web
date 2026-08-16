import 'package:flutter/material.dart';

/// Keeps phone content inside a predictable readable column on narrow phones,
/// desktop previews, and web screenshots.
class LunaPageFrame extends StatelessWidget {
  const LunaPageFrame({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topLeft,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 390),
        child: SizedBox(width: double.infinity, child: child),
      ),
    );
  }
}
