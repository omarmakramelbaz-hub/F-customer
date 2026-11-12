import '../../../../helpers/payment/payment_navigation_policy.dart';

class WalletCheckout {
  const WalletCheckout({required this.url, this.orderId});

  final String url;
  final int? orderId;

  factory WalletCheckout.fromResponse(
    dynamic response, {
    required PaymentNavigationPolicy policy,
  }) {
    final data = response is Map ? response['data'] : null;
    final link = data is Map ? data['link'] : null;
    final uri = link is String ? Uri.tryParse(link) : null;
    if (uri == null || !policy.isCheckoutUrl(uri)) {
      throw const FormatException('Missing or invalid wallet checkout');
    }
    final rawOrderId = data['order_id'];
    final orderId = rawOrderId is int
        ? rawOrderId
        : rawOrderId is String
        ? int.tryParse(rawOrderId)
        : null;
    if (rawOrderId != null && (orderId == null || orderId <= 0)) {
      throw const FormatException('Invalid wallet checkout order');
    }
    return WalletCheckout(url: uri.toString(), orderId: orderId);
  }
}

enum WalletCheckoutErrorType {
  offline,
  timedOut,
  unavailable,
  invalidResponse,
  rejected,
  signInRequired,
}

class WalletCheckoutError {
  const WalletCheckoutError({
    required this.type,
    this.message,
    this.outcomeUncertain = false,
  });

  final WalletCheckoutErrorType type;
  final String? message;
  final bool outcomeUncertain;

  /// Only short human-readable backend messages belong in the interface.
  /// Never expose raw payloads, gateway URLs or credential-like diagnostics.
  static String? safeMessage(dynamic response) {
    final value = response is Map ? response['message'] : null;
    if (value is! String) return null;
    final message = value.trim();
    if (message.isEmpty ||
        message.length > 240 ||
        RegExp(r'[\x00-\x1F<>]').hasMatch(message) ||
        RegExp(
          r'https?://|bearer\s|client[_-]?secret|api[_-]?key',
          caseSensitive: false,
        ).hasMatch(message)) {
      return null;
    }
    return message;
  }
}
