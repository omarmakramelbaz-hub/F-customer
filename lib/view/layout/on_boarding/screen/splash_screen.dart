import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';

import '../../../../helpers/hive/hive_methods.dart';
import '../../../../helpers/pusher_service/pusher_controller.dart';
import '../../../../helpers/routes/app_routers_import.dart';
import '../../auth/controller/auth_controller.dart';
import '../../auth/screen/login_screen.dart';
import '../../bottom_navigation/bottom_navigation_bar_screen.dart';
import '../../bottom_navigation/controller/advertising_controller.dart';
import 'on_boarding_screen.dart';
import 'opening_video_controller_stub.dart'
    if (dart.library.html) 'opening_video_controller_web.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  static const String routeName = 'SplashScreen';

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  static const List<String> _videoChunks = [
    'assets/splash_video/part_00.b64',
    'assets/splash_video/part_01.b64',
    'assets/splash_video/part_02.b64',
    'assets/splash_video/part_03.b64',
    'assets/splash_video/part_04.b64',
    'assets/splash_video/part_05.b64',
    'assets/splash_video/part_06.b64',
    'assets/splash_video/part_07.b64',
  ];

  // Match the very first frame of the opening video as closely as possible.
  static const Color _openingBackground = Colors.transparent;
  static const Duration _maxOpeningDuration = Duration(seconds: 5);

  final LocalAuthentication _localAuth = LocalAuthentication();
  VideoPlayerController? _videoController;
  String? _pendingRouteName;
  bool _videoReady = false;
  bool _videoFinished = false;
  bool _videoFailed = false;
  bool _isBiometricCheckComplete = false;
  bool _isNavigationPending = false;
  bool _isBiometricDialogOpen = false;
  bool _firstFrameReleased = false;

  @override
  void initState() {
    super.initState();

    // Keep the native launch surface visible while the MP4 texture is being
    // prepared. This prevents Flutter from briefly painting a plain color
    // screen between the OS launch screen and the actual opening video.
    if (!kIsWeb) {
      WidgetsBinding.instance.deferFirstFrame();
    }

    _prepareOpeningVideo();
    WidgetsBinding.instance.addPostFrameCallback((_) => _initial());
  }

  void _releaseFirstFrame() {
    if (kIsWeb || _firstFrameReleased) return;
    _firstFrameReleased = true;
    WidgetsBinding.instance.allowFirstFrame();
  }

  Future<void> _prepareOpeningVideo() async {
    try {
      final controller = await createOpeningVideoController(_videoChunks);
      _videoController = controller;

      // The HQ asset is several MB, so allow enough time on a cold web load.
      await controller.initialize().timeout(const Duration(seconds: 20));
      await controller.setLooping(false);
      await controller.seekTo(Duration.zero);

      // Web autoplay must stay muted. On Android/iOS we only set the player
      // volume and never change the device media/ringer settings, so the app
      // does not force audio outside the user's current device configuration.
      await controller.setVolume(kIsWeb ? 0.0 : 1.0);
      controller.addListener(_handleVideoProgress);

      if (!mounted) {
        controller.removeListener(_handleVideoProgress);
        await controller.dispose();
        _releaseFirstFrame();
        return;
      }

      setState(() => _videoReady = true);

      try {
        await controller.play();
      } catch (playError) {
        // Some browsers can still reject the first autoplay attempt. Retry once
        // explicitly muted before treating the splash as failed.
        if (!kIsWeb) rethrow;
        await controller.setVolume(0.0);
        await controller.play();
      }

      // Only now let Flutter replace the native launch surface. The first
      // Flutter frame already contains the initialized playing video.
      _releaseFirstFrame();

      // Never hold the user on the branding screen for more than five seconds.
      // If the source video ends sooner, the progress listener exits earlier.
      Future.delayed(_maxOpeningDuration, () {
        if (!mounted || _videoFinished) return;
        _finishOpeningVideo();
      });
    } catch (error, stackTrace) {
      debugPrint('Opening splash video error: $error');
      debugPrintStack(stackTrace: stackTrace);

      _releaseFirstFrame();
      if (!mounted) return;
      setState(() => _videoFailed = true);
      _finishOpeningVideo();
    }
  }

  void _handleVideoProgress() {
    final controller = _videoController;
    if (controller == null || _videoFinished) return;

    final value = controller.value;
    if (!value.isInitialized || value.duration == Duration.zero) return;

    final remaining = value.duration - value.position;
    if (remaining <= const Duration(milliseconds: 150)) {
      _finishOpeningVideo();
    }
  }

  void _finishOpeningVideo() {
    if (_videoFinished) return;
    _videoFinished = true;
    _tryNavigate();
  }

  @override
  void dispose() {
    _releaseFirstFrame();
    _videoController?.removeListener(_handleVideoProgress);
    _videoController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _videoController;

    return Scaffold(
      backgroundColor: _openingBackground,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const ColoredBox(color: _openingBackground),
          if (_videoReady && !_videoFailed && controller != null)
            _buildVideo(controller),
        ],
      ),
    );
  }

  Widget _buildVideo(VideoPlayerController controller) {
    final size = controller.value.size;
    return ClipRect(
      child: SizedBox.expand(
        child: FittedBox(
          fit: BoxFit.cover,
          alignment: Alignment.center,
          child: SizedBox(
            width: size.width,
            height: size.height,
            child: VideoPlayer(controller),
          ),
        ),
      ),
    );
  }

  void _initial() {
    if (kIsWeb) {
      _requestNavigation(BottomNavigationBarScreen.routeName);
      return;
    }

    if (HiveMethods.isFirstTime()) {
      _requestNavigation(OnBoardingScreen.routeName);
    } else if (HiveMethods.getToken() != null) {
      _getData();
    } else {
      _requestNavigation(LoginScreen.routeName);
    }
  }

  void _requestNavigation(String routeName) {
    if (!mounted || _isNavigationPending) return;
    _pendingRouteName = routeName;
    _tryNavigate();
  }

  void _tryNavigate() {
    if (!mounted || _isNavigationPending || !_videoFinished) return;

    final routeName = _pendingRouteName;
    if (routeName == null) return;

    _isNavigationPending = true;
    NamedNavigatorImpl.push(clean: true, routeName);
  }

  Future<bool> _checkBiometrics() async {
    if (kIsWeb || kDebugMode) return true;

    try {
      final canAuthenticate = await _localAuth.canCheckBiometrics;
      final isDeviceSupported = await _localAuth.isDeviceSupported();

      if (!canAuthenticate || !isDeviceSupported) return true;

      return await _localAuth.authenticate(
        localizedReason: 'Authenticate to access your account',
        biometricOnly: false,
        persistAcrossBackgrounding: true,
      );
    } catch (e) {
      debugPrint('Biometric error: $e');
      return false;
    }
  }

  void _getData() {
    context.read<AuthController>().initialProfile();
    context.read<AdvertisingController>()
      ..initialAdvertising()
      ..getAdvertising();

    context.read<AuthController>().getProfile(
      onHaveIdANDToken: (id, token) {
        context.read<PusherController>().initPusher(
          channelName: 'private-user.$id',
          userId: id,
          token: token,
        );
      },
      onSuccess: () async {
        if (!mounted || _isNavigationPending) return;

        final authController = context.read<AuthController>();
        if (authController.profile?.email == null) {
          _requestNavigation(LoginScreen.routeName);
          return;
        }

        final bioSuccess = await _checkBiometrics();
        _isBiometricCheckComplete = true;

        if (bioSuccess) {
          _requestNavigation(BottomNavigationBarScreen.routeName);
        } else {
          _handleBiometricFailure();
        }
      },
      onUnauthenticated: () {
        if (!mounted || _isNavigationPending || _isBiometricCheckComplete) {
          return;
        }
        _requestNavigation(LoginScreen.routeName);
      },
    );
  }

  void _handleBiometricFailure() {
    if (!mounted || _isNavigationPending || _isBiometricDialogOpen) return;
    _isBiometricDialogOpen = true;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Authentication Required'),
        content: const Text(
          'Biometric authentication failed. Please login again.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _isBiometricDialogOpen = false;
              _requestNavigation(LoginScreen.routeName);
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
