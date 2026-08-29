import 'package:flutter/material.dart';

/// Softens only the outer paper pixels of the supplied mascot artwork so its
/// warm painted background merges into the app's matching paper canvas.
class PaperBlendImage extends StatelessWidget {
  const PaperBlendImage({
    required this.assetName,
    this.fit = BoxFit.contain,
    super.key,
  });

  final String assetName;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: AspectRatio(
        aspectRatio: 1,
        child: ShaderMask(
          blendMode: BlendMode.dstIn,
          shaderCallback: (bounds) => const LinearGradient(
            colors: <Color>[
              Colors.transparent,
              Colors.white,
              Colors.white,
              Colors.transparent,
            ],
            stops: <double>[0, 0.14, 0.86, 1],
          ).createShader(bounds),
          child: ShaderMask(
            blendMode: BlendMode.dstIn,
            shaderCallback: (bounds) => const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: <Color>[
                Colors.transparent,
                Colors.white,
                Colors.white,
                Colors.transparent,
              ],
              stops: <double>[0, 0.14, 0.86, 1],
            ).createShader(bounds),
            child: Image.asset(assetName, fit: fit),
          ),
        ),
      ),
    );
  }
}
