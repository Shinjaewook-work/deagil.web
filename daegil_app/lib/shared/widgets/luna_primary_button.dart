import 'package:flutter/material.dart';

import '../../app/theme/luna_theme.dart';

class LunaPrimaryButton extends StatelessWidget {
  const LunaPrimaryButton({
    required this.label,
    required this.onPressed,
    this.icon = Icons.pets_rounded,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 20),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: LunaColors.gold,
        foregroundColor: LunaColors.ink,
      ),
    );
  }
}
