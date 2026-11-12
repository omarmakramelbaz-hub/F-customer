import 'dart:async';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

/// The website's six-second food film, bundled for reliable mobile/web playback.
/// The foreground owns safe areas; this layer deliberately reaches every edge.
class HomeVideoBackground extends StatefulWidget {
  const HomeVideoBackground({super.key, this.respectReducedMotion = false});

  final bool respectReducedMotion;

  static const videoAsset = 'assets/splash_video/home_hero.mp4';
  static const posterAsset = 'assets/images/home_hero_poster.jpg';

  @override
  State<HomeVideoBackground> createState() => _HomeVideoBackgroundState();
}

class _HomeVideoBackgroundState extends State<HomeVideoBackground>
    with WidgetsBindingObserver {
  VideoPlayerController? _controller;
  bool _ready = false;
  bool _foreground = true;
  bool _visible = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(_initialize());
  }

  Future<void> _initialize() async {
    final controller = VideoPlayerController.asset(
      HomeVideoBackground.videoAsset,
      videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
    );
    _controller = controller;
    try {
      await controller.initialize().timeout(const Duration(seconds: 15));
      if (!mounted || _controller != controller) return;
      await controller.setVolume(0);
      await controller.setLooping(true);
      if (!mounted || _controller != controller) return;
      setState(() => _ready = true);
      _syncPlayback();
    } catch (_) {
      // Autoplay/plugin/asset failures leave the real video poster in place.
      // No controls, retries or loading panels cover the ordering experience.
      if (_controller == controller) {
        _controller = null;
        unawaited(controller.dispose());
      }
      if (mounted) setState(() => _ready = false);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _visible = TickerMode.of(context) &&
        (ModalRoute.of(context)?.isCurrent ?? true) &&
        !(widget.respectReducedMotion &&
            MediaQuery.disableAnimationsOf(context));
    _syncPlayback();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    _syncPlayback();
  }

  void _syncPlayback() {
    final controller = _controller;
    if (!_ready || controller == null) return;
    final shouldPlay = _foreground && _visible;
    final action = shouldPlay ? controller.play() : controller.pause();
    unawaited(
      action.catchError((Object _) {
        if (shouldPlay && mounted && _controller == controller) {
          setState(() => _ready = false);
        }
      }),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    final controller = _controller;
    _controller = null;
    if (controller != null) unawaited(controller.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    return ExcludeSemantics(
      child: IgnorePointer(
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              HomeVideoBackground.posterAsset,
              fit: BoxFit.cover,
              gaplessPlayback: true,
            ),
            if (_ready && controller != null)
              ClipRect(
                child: FittedBox(
                  fit: BoxFit.cover,
                  child: SizedBox(
                    width: controller.value.size.width,
                    height: controller.value.size.height,
                    child: VideoPlayer(controller),
                  ),
                ),
              ),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xB8092225),
                    Color(0x38092225),
                    Color(0x26092225),
                    Color(0xB0092225),
                    Color(0xEF092225),
                  ],
                  stops: [0, .23, .37, .67, 1],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
