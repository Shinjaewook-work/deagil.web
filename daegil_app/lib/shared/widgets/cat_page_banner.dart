import 'package:flutter/material.dart';

import '../../app/theme/luna_theme.dart';

class CatPageBanner extends StatelessWidget {
  const CatPageBanner({
    required this.assetName,
    required this.title,
    this.message,
    this.imageHeight = 132,
    super.key,
  });

  final String assetName;
  final String title;
  final String? message;
  final double imageHeight;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3DC),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: LunaColors.gold.withValues(alpha: 0.55)),
      ),
      child: Column(
        children: [
          SizedBox(
            height: imageHeight,
            width: double.infinity,
            child: Image.asset(assetName, fit: BoxFit.contain),
          ),
          Text(
            title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          if (message != null) ...[
            const SizedBox(height: 6),
            Text(
              message!,
              textAlign: TextAlign.center,
              softWrap: true,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ],
      ),
    );
  }
}
