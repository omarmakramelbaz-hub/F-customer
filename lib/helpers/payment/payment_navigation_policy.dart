enum PaymentReturn { success, failure }

/// Gateway query flags are not receipts. Only the application's final return
/// pages, reached after backend gateway verification, signal a return.
class PaymentNavigationPolicy {
  const PaymentNavigationPolicy(this.apiOrigin);

  final Uri apiOrigin;

  bool isCheckoutUrl(Uri uri) =>
      uri.scheme == 'https' &&
      uri.userInfo.isEmpty &&
      uri.port == 443 &&
      (uri.host == 'paymob.com' || uri.host.endsWith('.paymob.com'));

  bool canNavigate(Uri uri) =>
      (uri.scheme == 'https' && uri.userInfo.isEmpty) ||
      uri.toString() == 'about:blank';

  PaymentReturn? result(Uri uri) {
    if (uri.scheme != 'https' ||
        uri.userInfo.isNotEmpty ||
        uri.host != apiOrigin.host ||
        uri.port != apiOrigin.port) {
      return null;
    }
    final path = uri.path.endsWith('/')
        ? uri.path.substring(0, uri.path.length - 1)
        : uri.path;
    return switch (path) {
      '/pay-thanks' => PaymentReturn.success,
      '/pay-false' => PaymentReturn.failure,
      _ => null,
    };
  }
}
