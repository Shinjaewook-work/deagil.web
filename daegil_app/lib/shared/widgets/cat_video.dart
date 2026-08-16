import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class CatVideo extends StatefulWidget {
  const CatVideo({super.key});

  @override
  State<CatVideo> createState() => _CatVideoState();
}

class _CatVideoState extends State<CatVideo> with WidgetsBindingObserver {
  VideoPlayerController? _controller;
  Future<void>? _initialization;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _controller = VideoPlayerController.asset('assets/videos/fortune_cat.mp4');
    _initialization = _initialize();
  }

  Future<void> _initialize() async {
    try {
      await _controller!.initialize();
      await _controller!.setLooping(true);
      await _controller!.setVolume(0);
      if (!mounted) return;
      if (MediaQuery.disableAnimationsOf(context)) return;
      await _controller!.play();
      setState(() {});
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;
    if (state == AppLifecycleState.resumed &&
        !MediaQuery.disableAnimationsOf(context)) {
      controller.play();
    } else if (state == AppLifecycleState.paused) {
      controller.pause();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_failed) return const _CatFallback();
    return FutureBuilder<void>(
      future: _initialization,
      builder: (context, snapshot) {
        final controller = _controller;
        if (snapshot.connectionState == ConnectionState.done &&
            controller != null &&
            controller.value.isInitialized &&
            !MediaQuery.disableAnimationsOf(context)) {
          return ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width: controller.value.size.width,
                height: controller.value.size.height,
                child: VideoPlayer(controller),
              ),
            ),
          );
        }
        return const _CatFallback();
      },
    );
  }
}

class _CatFallback extends StatelessWidget {
  const _CatFallback();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: 190,
            child: Image.asset(
              'assets/images/daegil_cat_stretch.png',
              fit: BoxFit.contain,
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              '고양이가 오늘의 운세를 잡아올 준비를 하고 있다냥.',
              textAlign: TextAlign.center,
              softWrap: true,
            ),
          ),
        ],
      ),
    );
  }
}
