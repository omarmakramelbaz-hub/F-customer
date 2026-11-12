import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

typedef PaymentBrowserBuilder = Widget Function(
    BuildContext context, PaymentBrowserEvents events);

class PaymentBrowserEvents {
  const PaymentBrowserEvents({
    required this.url,
    required this.navigate,
    required this.progress,
    required this.error,
  });

  final Uri url;
  final Future<bool> Function(Uri uri, bool mainFrame) navigate;
  final ValueChanged<double> progress;
  final VoidCallback error;
}

/// 3DS/new-window requests stay in embedded views, preserving POSTs and cookies.
class EmbeddedPaymentBrowser extends StatefulWidget {
  const EmbeddedPaymentBrowser({super.key, required this.events});
  final PaymentBrowserEvents events;

  @override
  State<EmbeddedPaymentBrowser> createState() => _EmbeddedPaymentBrowserState();
}

class _EmbeddedPaymentBrowserState extends State<EmbeddedPaymentBrowser> {
  final _windows = <int>[];

  Widget _view(int? windowId) => InAppWebView(
        key: ValueKey(windowId ?? -1),
        windowId: windowId,
        initialUrlRequest: windowId == null
            ? URLRequest(url: WebUri.uri(widget.events.url))
            : null,
        initialSettings: InAppWebViewSettings(
          javaScriptEnabled: true,
          useShouldOverrideUrlLoading: true,
          supportMultipleWindows: true,
          javaScriptCanOpenWindowsAutomatically: true,
          useHybridComposition: true,
          thirdPartyCookiesEnabled: true,
          allowsInlineMediaPlayback: true,
          iframeAllow: 'payment *',
          iframeSandbox: {
            Sandbox.ALLOW_FORMS,
            Sandbox.ALLOW_SCRIPTS,
            Sandbox.ALLOW_SAME_ORIGIN,
            Sandbox.ALLOW_MODALS,
          },
        ),
        shouldOverrideUrlLoading: (_, action) async {
          final uri = action.request.url;
          if (uri == null) return NavigationActionPolicy.CANCEL;
          final allow =
              await widget.events.navigate(uri, action.isForMainFrame);
          return allow
              ? NavigationActionPolicy.ALLOW
              : NavigationActionPolicy.CANCEL;
        },
        onLoadStart: (_, uri) {
          if (uri != null) widget.events.navigate(uri, true);
        },
        onLoadStop: (_, uri) {
          if (uri != null) widget.events.navigate(uri, true);
          widget.events.progress(1);
        },
        onUpdateVisitedHistory: (_, uri, __) {
          if (uri != null) widget.events.navigate(uri, true);
        },
        onProgressChanged: (_, progress) =>
            widget.events.progress(progress / 100),
        onReceivedError: (_, request, __) {
          if (request.isForMainFrame != false) widget.events.error();
        },
        onReceivedHttpError: (_, request, response) {
          if (request.isForMainFrame != false &&
              (response.statusCode ?? 0) >= 400) {
            widget.events.error();
          }
        },
        onCreateWindow: (_, action) async {
          final uri = action.request.url;
          if (uri != null && !await widget.events.navigate(uri, true)) {
            return false;
          }
          if (!mounted || _windows.contains(action.windowId)) return false;
          setState(() => _windows.add(action.windowId));
          return true;
        },
        onCloseWindow: (_) {
          if (mounted && windowId != null) {
            setState(() => _windows.remove(windowId));
          }
        },
      );

  @override
  Widget build(BuildContext context) => Stack(
        fit: StackFit.expand,
        children: [_view(null), for (final id in _windows) _view(id)],
      );
}
