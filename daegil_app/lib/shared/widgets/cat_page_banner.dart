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
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
      decoration: BoxDecoration(
        color: LunaColors.cream,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: LunaColors.subtleBorder),
        boxShadow: [
          BoxShadow(
            color: LunaColors.seal.withValues(alpha: 0.13),
            blurRadius: 18,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                height: imageHeight - 8,
                margin: const EdgeInsets.symmetric(horizontal: 18),
                decoration: BoxDecoration(
                  color: LunaColors.peachSoft.withValues(alpha: 0.55),
                  shape: BoxShape.circle,
                ),
              ),
              SizedBox(
                height: imageHeight,
                width: double.infinity,
                child: Image.asset(assetName, fit: BoxFit.contain),
              ),
              const Positioned(
                top: 2,
                right: 6,
                child: _PawBubble(color: LunaColors.butter, size: 34),
              ),
              const Positioned(
                bottom: 2,
                left: 4,
                child: _PawBubble(color: LunaColors.jadeSoft, size: 30),
              ),
            ],
          ),
          const SizedBox(height: 4),
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

class _PawBubble extends StatelessWidget {
  const _PawBubble({required this.color, required this.size});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      child: Icon(
        Icons.pets_rounded,
        size: size * 0.52,
        color: LunaColors.seal,
      ),
    );
  }
}
