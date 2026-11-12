import 'dart:async';

import 'package:flutter/material.dart';

import '../../../helpers/networking/urls.dart';
import '../../../helpers/payment/order_payment_confirmation.dart';
import '../../../helpers/payment/payment_navigation_policy.dart';
import 'embedded_payment_browser.dart';

class PaymentArgs {
  final String url;
  final int? orderId;
  final VoidCallback onSuccess;
  final VoidCallback onFailed;

  PaymentArgs({
    required this.url,
    required this.onSuccess,
    required this.onFailed,
    this.orderId,
  });
}

class CustomPaymentWebViewScreen extends StatefulWidget {
  const CustomPaymentWebViewScreen({
    super.key,
    required this.args,
    this.browserBuilder,
    this.confirmationReader,
  });

  static const routeName = 'CustomPaymentWebViewScreen';
  final PaymentArgs args;
  final PaymentBrowserBuilder? browserBuilder;
  final PaymentConfirmationReader? confirmationReader;

  @override
  State<CustomPaymentWebViewScreen> createState() =>
      _CustomPaymentWebViewScreenState();
}

class _CustomPaymentWebViewScreenState extends State<CustomPaymentWebViewScreen>
    with WidgetsBindingObserver {
  late final PaymentNavigationPolicy _policy;
  Uri? _checkout;
  PaymentConfirmationMonitor? _monitor;
  double _progress = 0;
  bool _loadError = false;
  bool _awaitingConfirmation = false;
  bool _finished = false;
  bool _resumed = true;
  bool? _pendingCompletion;
  int _loadAttempt = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _policy = PaymentNavigationPolicy(Uri.parse(Urls.baseUrl));
    final uri = Uri.tryParse(widget.args.url);
    if (uri != null &&
        _policy.isCheckoutUrl(uri) &&
        (widget.args.orderId == null || widget.args.orderId! > 0)) {
      _checkout = uri;
      if (widget.args.orderId != null) {
        _monitor = PaymentConfirmationMonitor(
          orderId: widget.args.orderId!,
          read: widget.confirmationReader ?? OrderPaymentConfirmation().read,
        )..addListener(_confirmationChanged);
      }
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncMonitor();
    final pending = _pendingCompletion;
    if (pending != null && (ModalRoute.of(context)?.isCurrent ?? true)) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _finish(pending));
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _resumed = state == AppLifecycleState.resumed;
    _syncMonitor();
  }

  void _syncMonitor() {
    if (_resumed && !_finished && (ModalRoute.of(context)?.isCurrent ?? true)) {
      _monitor?.resume();
    } else {
      _monitor?.pause();
    }
  }

  void _confirmationChanged() {
    switch (_monitor?.result) {
      case PaymentConfirmation.confirmed:
        _finish(true);
      case PaymentConfirmation.failed:
        _finish(false);
      default:
        break;
    }
  }

  void _finish(bool success) {
    if (!mounted || _finished) return;
    if (!(ModalRoute.of(context)?.isCurrent ?? true)) {
      _pendingCompletion = success;
      return;
    }
    _finished = true;
    _pendingCompletion = null;
    _monitor?.pause();
    final callback = success ? widget.args.onSuccess : widget.args.onFailed;
    // Remove this route before the caller opens tracking or closes a wallet sheet.
    Navigator.of(context).pop(success);
    scheduleMicrotask(callback);
  }

  Future<bool> _navigate(Uri uri, bool mainFrame) async {
    if (!mounted || _finished) return false;
    if (!mainFrame) return _policy.canNavigate(uri);
    switch (_policy.result(uri)) {
      case PaymentReturn.success:
        if (_monitor == null) {
          _finish(true);
        } else {
          setState(() => _awaitingConfirmation = true);
          unawaited(_monitor!.checkNow());
        }
        return false;
      case PaymentReturn.failure:
        if (_monitor?.result == PaymentConfirmation.confirmed) {
          _finish(true);
        } else {
          _finish(false);
        }
        return false;
      case null:
        return _policy.canNavigate(uri);
    }
  }

  void _reload() {
    setState(() {
      _loadAttempt++;
      _progress = 0;
      _loadError = false;
    });
    unawaited(_monitor?.checkNow());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _monitor?.removeListener(_confirmationChanged);
    _monitor?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final checkout = _checkout;
    final events = checkout == null
        ? null
        : PaymentBrowserEvents(
            url: checkout,
            navigate: _navigate,
            progress: (value) {
              if (mounted && !_finished) {
                setState(() => _progress = value.clamp(0, 1));
              }
            },
            error: () {
              if (mounted && !_finished) setState(() => _loadError = true);
            },
          );
    return Scaffold(
      backgroundColor: const Color(0xFF092225),
      appBar: AppBar(
        backgroundColor: const Color(0xFF092225),
        foregroundColor: const Color(0xFFFFF4E2),
        surfaceTintColor: Colors.transparent,
        centerTitle: true,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/images/home_brand_logo.webp',
              width: 36,
              height: 36,
              excludeFromSemantics: true,
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                isArabic ? 'إتمام الدفع' : 'Complete payment',
                style: const TextStyle(
                  fontFamily: 'Tajawal',
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        leading: IconButton(
          key: const ValueKey('close-payment'),
          tooltip: isArabic ? 'إغلاق صفحة الدفع' : 'Close payment',
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        actions: const [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Icon(Icons.lock_outline, color: Color(0xFFFF8A35)),
          ),
        ],
      ),
      body: DecoratedBox(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/home_hero_poster.jpg'),
            fit: BoxFit.cover,
            opacity: .12,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              if (_progress < 1 && !_loadError && checkout != null)
                LinearProgressIndicator(
                  value: _progress == 0 ? null : _progress,
                  color: const Color(0xFFFF8A35),
                  backgroundColor: const Color(0xFF173B43),
                ),
              if (_awaitingConfirmation)
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    isArabic
                        ? 'جارٍ تأكيد الدفع...'
                        : 'Confirming your payment...',
                    style: const TextStyle(color: Color(0xFFFFF4E2)),
                  ),
                ),
              Expanded(
                child: events == null || _loadError
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.wifi_off_rounded,
                                size: 40,
                                color: Color(0xFFFF8A35),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                isArabic
                                    ? 'تعذّر تحميل صفحة الدفع'
                                    : 'Could not load the payment page',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Color(0xFFFFF4E2),
                                ),
                              ),
                              if (events != null) ...[
                                const SizedBox(height: 16),
                                FilledButton(
                                  key: const ValueKey('retry-payment'),
                                  onPressed: _reload,
                                  style: FilledButton.styleFrom(
                                    backgroundColor: const Color(0xFFFF8A35),
                                    foregroundColor: const Color(0xFF092225),
                                  ),
                                  child: Text(
                                    isArabic ? 'إعادة المحاولة' : 'Retry',
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      )
                    : Padding(
                        padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(18),
                          child: KeyedSubtree(
                            key: ValueKey(_loadAttempt),
                            child:
                                widget.browserBuilder?.call(context, events) ??
                                    EmbeddedPaymentBrowser(events: events),
                          ),
                        ),
                      ),
              ),
              if (widget.args.orderId != null)
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    isArabic
                        ? 'بعد تأكيد الدفع سيتم فتح تتبع طلبك تلقائيًا'
                        : 'Order tracking opens automatically after payment is confirmed',
                    textAlign: TextAlign.center,
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: const Color(0xFFFFF4E2)),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
