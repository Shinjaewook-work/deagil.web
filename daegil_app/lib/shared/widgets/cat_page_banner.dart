import 'package:flutter/material.dart';

import '../../app/theme/luna_theme.dart';
import 'paper_blend_image.dart';

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
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 18),
      decoration: BoxDecoration(
        color: LunaColors.imageCanvas,
        borderRadius: BorderRadius.circular(LunaRadii.card),
        border: Border.all(color: LunaColors.subtleBorder, width: 1.15),
      ),
      child: Column(
        children: [
          SizedBox(
            height: imageHeight,
            width: double.infinity,
            child: PaperBlendImage(assetName: assetName),
          ),
          const SizedBox(height: 6),
          Text(
            title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium,
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
