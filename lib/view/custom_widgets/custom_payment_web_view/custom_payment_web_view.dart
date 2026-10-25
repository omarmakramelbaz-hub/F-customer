import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

import '../../../helpers/routes/app_routers_import.dart';
import '../../../helpers/translation/all_translation.dart';
import '../../../helpers/utils/common_methods.dart';
import '../custom_app_bar/custom_app_bar.dart';

class PaymentArgs {
  final String url;
  final VoidCallback onSuccess;
  final VoidCallback onFailed;
  PaymentArgs({required this.url, required this.onSuccess, required this.onFailed});
}

class CustomPaymentWebViewScreen extends StatefulWidget {
  const CustomPaymentWebViewScreen({super.key, required this.args});
  static const routeName = 'CustomPaymentWebViewScreen';
  final PaymentArgs args;

  @override
  State<CustomPaymentWebViewScreen> createState() => _CustomPaymentWebViewScreenState();
}

class _CustomPaymentWebViewScreenState extends State<CustomPaymentWebViewScreen> {
  final GlobalKey webViewKey = GlobalKey();
  late final InAppWebViewController _controller;

  double progress = 0;
  @override
  Widget build(BuildContext context) {
    final options = InAppWebViewGroupOptions(
      crossPlatform: InAppWebViewOptions(
        javaScriptEnabled: true,
        useShouldOverrideUrlLoading: true,
        mediaPlaybackRequiresUserGesture: false,
        clearCache: false,
      ),
      android: AndroidInAppWebViewOptions(useHybridComposition: true),
      ios: IOSInAppWebViewOptions(allowsInlineMediaPlayback: true),
    );

    return Scaffold(
      appBar: CustomAppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => NamedNavigatorImpl.pop(),
        ),
      ),
      body: SafeArea(
        child: Stack(
          children: [
            InAppWebView(
              key: webViewKey,
              initialUrlRequest: URLRequest(url: WebUri(widget.args.url)),
              initialOptions: options,
              onWebViewCreated: (controller) {
                _controller = controller;
                // JS message handler similar to JavaScriptChannel 'Toaster'
                try {
                  _controller.addJavaScriptHandler(
                    handlerName: 'Toaster',
                    callback: (args) {
                      final message = args.isNotEmpty ? args.first?.toString() ?? '' : '';
                      if (message.isNotEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
                      }
                      return null;
                    },
                  );
                } catch (_) {}
              },
              onProgressChanged: (controller, p) {
                setState(() => progress = p / 100);
              },
              onLoadStart: (controller, uri) => log('Page started loading: ${uri?.toString() ?? ''}'),
              onLoadStop: (controller, uri) => log('Page finished loading: ${uri?.toString() ?? ''}'),
              shouldOverrideUrlLoading: (controller, navigationAction) async {
                final uri = navigationAction.request.url;
                final url = uri?.toString() ?? '';
                try {
                  final policy = await _pageRedirect(context, url);
                  return policy == NavigationActionPolicy.CANCEL
                      ? NavigationActionPolicy.CANCEL
                      : NavigationActionPolicy.ALLOW;
                } catch (e) {
                  log('Navigation error: $e');
                  return NavigationActionPolicy.ALLOW;
                }
              },
              onLoadError: (controller, uri, code, message) {
                log('Error occurred on page: $code - $message');
              },
              onConsoleMessage: (controller, consoleMessage) {
                log('Console: ${consoleMessage.message}');
              },
            ),
            if (progress < 1.0)
              Positioned(top: 0, right: 0, left: 0, child: LinearProgressIndicator(value: progress))
            else
              Container(),
          ],
        ),
      ),
    );
  }

  // Future<NavigationDecision> _pageRedirect(
  //     BuildContext context, String url) async {
  //       log(url);
  //   //bool isSuccess = url.contains('pay-thanks');
  //   bool isSuccess = url.contains('success=true');
  //   bool isFailed=url.contains('success=flase');
  //  // bool isFailed = url.contains('cancelled-form');
  //   if ( isSuccess) {
  //     Navigator.pop(context, isSuccess);
  //     CommonMethods.showToast(message: 'paymentSuccessful'.tr,seconds: 5);
  //     widget.args.onSuccess.call();
  //     return NavigationDecision.prevent;
  //  }
  //    else if (isFailed) {
  //     Navigator.pop(context, isSuccess);
  //     CommonMethods.showError(message: 'Payment Failed');
  //     return NavigationDecision.prevent;
  //   }
  //   else {
  //      Navigator.pop(context, isSuccess);
  //     CommonMethods.showError(message: 'Payment Failed',seconds:5 );
  //     return NavigationDecision.navigate;
  //   }
  // }
  bool _resultHandled = false;

  Future<NavigationActionPolicy> _pageRedirect(BuildContext context, String url) async {
    bool isSuccess = url.contains('pay-thanks');
    bool isFailed = url.contains('pay-false');
    if (!isSuccess && !isFailed) return NavigationActionPolicy.ALLOW;
    if (_resultHandled) return NavigationActionPolicy.CANCEL;
    _resultHandled = true;

    // Close the payment page first. The callback then opens the next screen,
    // so that screen is not closed by this page's own pop.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) Navigator.pop(context);
      if (isSuccess) {
        CommonMethods.showToast(message: 'paymentSuccess'.tr);
        widget.args.onSuccess.call();
      } else {
        CommonMethods.showError(message: 'paymentFailed'.tr);
        widget.args.onFailed.call();
      }
    });
    return NavigationActionPolicy.CANCEL;
  }
}
