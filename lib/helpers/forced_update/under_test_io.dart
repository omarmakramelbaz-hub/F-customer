import 'dart:io';

/// `flutter test` sets FLUTTER_TEST: the screens under test never ask the real server.
bool get runningUnderFlutterTest =>
    Platform.environment['FLUTTER_TEST'] == 'true';
