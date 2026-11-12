import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../networking/api_helper.dart';
import '../networking/urls.dart';
import 'fasakhansta_update_dialog.dart';
import 'under_test_stub.dart' if (dart.library.io) 'under_test_io.dart';

/// The forced update set on the dashboard («تحديث التطبيق الإجباري»): GET /api/app-version gives, per platform, the
/// lowest version still allowed and the store link. An older app shows, on its home, a message it cannot close.
class ForcedUpdatePolicy {
  final String? minVersion;
  final String? storeUrl;
  final String message;

  const ForcedUpdatePolicy(
      {this.minVersion, this.storeUrl, required this.message});

  /// The policy for this platform from the API's `data`, or null when nothing is forced.
  static ForcedUpdatePolicy? fromJson(dynamic data, TargetPlatform platform) {
    if (data is! Map) return null;
    final key = platform == TargetPlatform.iOS ? 'ios' : 'android';
    final entry = data[key];
    if (entry is! Map) return null;
    final min = entry['min_version']?.toString().trim() ?? '';
    if (min.isEmpty) return null;
    final url = entry['store_url']?.toString().trim() ?? '';
    return ForcedUpdatePolicy(
      minVersion: min,
      storeUrl: url.isEmpty ? null : url,
      message: data['message']?.toString().trim().isNotEmpty == true
          ? data['message'].toString()
          : 'في نسخة جديدة من فسخانستا. حدّث التطبيق علشان تكمّل.',
    );
  }

  /// Whether [installed] is older than [minimum] (1.0.9 < 1.0.10; missing parts count as 0).
  static bool isOlder(String installed, String minimum) {
    List<int> parts(String value) => value
        .split('+')
        .first
        .split('.')
        .map((part) => int.tryParse(part.trim()) ?? 0)
        .toList();
    final a = parts(installed), b = parts(minimum);
    for (var i = 0; i < (a.length > b.length ? a.length : b.length); i++) {
      final x = i < a.length ? a[i] : 0, y = i < b.length ? b[i] : 0;
      if (x != y) {
        return x < y;
      }
    }
    return false;
  }
}

class ForcedUpdate {
  static bool _shown = false;

  /// Asks the server once per launch; shows the update message when this app is older than allowed.
  static Future<void> check(BuildContext context) async {
    if (kIsWeb || _shown || runningUnderFlutterTest) return;
    final platform = defaultTargetPlatform;
    if (platform != TargetPlatform.android && platform != TargetPlatform.iOS) {
      return;
    }
    try {
      final response = await ApiHelper.instance.get(Urls.appVersion);
      final body = response.data;
      if (body is! Map) return;
      final policy = ForcedUpdatePolicy.fromJson(body['data'], platform);
      if (policy == null) return;
      final installed = (await PackageInfo.fromPlatform()).version;
      if (!ForcedUpdatePolicy.isOlder(installed, policy.minVersion!)) return;
      if (!context.mounted || _shown) return;
      _shown = true;
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (_) => ForcedUpdateDialog(policy: policy),
      );
    } catch (_) {
      // No internet or an older server: the app keeps working; it asks again on the next launch.
    }
  }
}

/// The forced update in Fasakhansta's own update design; it cannot be closed (no back, no tap outside).
class ForcedUpdateDialog extends StatelessWidget {
  const ForcedUpdateDialog({super.key, required this.policy});
  final ForcedUpdatePolicy policy;

  Future<void> _openStore() async {
    final url = policy.storeUrl;
    if (url == null) return;
    await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: FasakhanstaUpdateDialog(
        body: policy.message,
        onUpdate: policy.storeUrl == null ? null : _openStore,
      ),
    );
  }
}
