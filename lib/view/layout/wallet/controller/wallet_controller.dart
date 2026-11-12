import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../../../../helpers/hive/hive_methods.dart';
import '../../../../helpers/networking/api_helper.dart';
import '../../../../helpers/networking/urls.dart';
import '../../../../helpers/payment/payment_navigation_policy.dart';
import '../../../../helpers/utils/common_methods.dart';
import '../model/wallet_checkout.dart';
import '../model/wallet_checkout_service.dart';
import '../model/wallet_model.dart';
import '../model/wallet_transfer.dart';
import '../../../../helpers/translation/all_translation.dart';

class WalletController extends ChangeNotifier {
  WalletController({
    WalletCheckoutService? checkoutService,
    String? Function()? readCheckoutSession,
    this.checkoutTimeout = const Duration(seconds: 35),
  })  : _checkoutService = checkoutService ?? const WalletCheckoutService(),
        _readCheckoutSession = readCheckoutSession ?? _defaultCheckoutSession;

  final WalletCheckoutService _checkoutService;
  final String? Function() _readCheckoutSession;
  final Duration checkoutTimeout;
  bool _disposed = false;
  bool _isCreatingCheckout = false;
  int _checkoutGeneration = 0;
  CancelToken? _checkoutCancellation;
  WalletCheckoutError? _checkoutError;

  bool get isCreatingCheckout => _isCreatingCheckout;
  WalletCheckoutError? get checkoutError => _checkoutError;

  static String? _defaultCheckoutSession() =>
      HiveMethods.isGuestMode() ? null : HiveMethods.getToken();

  final chargeWalletFormKey = GlobalKey<FormState>();
  final chargeAmountEc = TextEditingController();
  final chargeAmountFocusNode = FocusNode();

  bool get _isGuestSession =>
      HiveMethods.isVisitor() || HiveMethods.getToken() == null;

  void updateWallet({required WalletModel transaction}) {
    getWallet();
    notifyListeners();
  }

  void initialWallet() {
    cancelCheckoutCreation();
    _walletResponse = ApiResponse(state: ResponseState.sleep, data: null);
    _wallet = null;
    notifyListeners();
  }

  ApiResponse _walletResponse = ApiResponse(
    state: ResponseState.sleep,
    data: null,
  );
  ApiResponse get walletResponse => _walletResponse;
  WalletResponse? _wallet;

  // Never expose a previously loaded user's wallet during a guest session.
  // WalletController is provided globally, so its in-memory state can survive
  // navigation from an authenticated session to guest mode unless we guard it.
  WalletResponse? get wallet => _isGuestSession ? null : _wallet;

  Future<void> getWallet() async {
    if (_isGuestSession) {
      _walletResponse = ApiResponse(state: ResponseState.sleep, data: null);
      _wallet = null;
      notifyListeners();
      return;
    }

    _walletResponse = ApiResponse(state: ResponseState.loading, data: null);
    _wallet = null;
    notifyListeners();
    _walletResponse = await ApiHelper.instance.get(Urls.wallet);
    notifyListeners();
    if (_walletResponse.state == ResponseState.complete) {
      _wallet = WalletResponse.fromJson(_walletResponse.data['data']);
      notifyListeners();
    }
  }

  String? _selectedPayment;
  String? get selectedPayment => _selectedPayment;
  void setSelectedPayment(String value) {
    if (_isCreatingCheckout) return;
    _selectedPayment = value;
    _checkoutError = null;
    notifyListeners();
  }

  //=============>  charging wallet  <================
  Future<WalletCheckout?> chargingWallet({required dynamic amount}) async {
    if (_disposed || _isCreatingCheckout) return null;
    final session = _readCheckoutSession();
    if (session == null || session.isEmpty) {
      _checkoutError = const WalletCheckoutError(
        type: WalletCheckoutErrorType.signInRequired,
      );
      notifyListeners();
      return null;
    }
    final paymentMethod = _selectedPayment;
    if (paymentMethod == null ||
        (paymentMethod != 'online' && paymentMethod != 'v_cash')) {
      _checkoutError = const WalletCheckoutError(
        type: WalletCheckoutErrorType.rejected,
      );
      notifyListeners();
      return null;
    }

    final generation = ++_checkoutGeneration;
    final cancellation = CancelToken();
    _checkoutCancellation = cancellation;
    _isCreatingCheckout = true;
    _checkoutError = null;
    notifyListeners();
    bool isCurrent() =>
        !_disposed &&
        generation == _checkoutGeneration &&
        !cancellation.isCancelled &&
        _readCheckoutSession() == session;

    try {
      final response = await _checkoutService.create(
        amount: amount,
        paymentMethod: paymentMethod,
        cancelToken: cancellation,
        timeout: checkoutTimeout,
        sessionToken: session,
        canSendRequest: isCurrent,
      );
      // A timeout cancels the transport too, but remains a visible error for
      // this attempt. User cancellation increments the generation instead.
      if (_disposed ||
          generation != _checkoutGeneration ||
          _readCheckoutSession() != session) {
        return null;
      }
      if (response.failure == ApiFailureKind.cancelled) return null;
      if (response.state != ResponseState.complete) {
        _checkoutError = _errorForResponse(response);
        return null;
      }
      try {
        return WalletCheckout.fromResponse(
          response.data,
          policy: PaymentNavigationPolicy(Uri.parse(Urls.baseUrl)),
        );
      } on FormatException {
        _checkoutError = WalletCheckoutError(
          type: WalletCheckoutErrorType.invalidResponse,
          message: WalletCheckoutError.safeMessage(response.data),
          outcomeUncertain: true,
        );
        return null;
      }
    } catch (_) {
      if (isCurrent()) {
        _checkoutError = const WalletCheckoutError(
          type: WalletCheckoutErrorType.unavailable,
          outcomeUncertain: true,
        );
      }
      return null;
    } finally {
      if (!_disposed && generation == _checkoutGeneration) {
        _checkoutCancellation = null;
        _isCreatingCheckout = false;
        notifyListeners();
      }
    }
  }

  WalletCheckoutError _errorForResponse(ApiResponse response) {
    if (response.failure == ApiFailureKind.timeout) {
      return const WalletCheckoutError(
        type: WalletCheckoutErrorType.timedOut,
        outcomeUncertain: true,
      );
    }
    if (response.failure == ApiFailureKind.network) {
      return const WalletCheckoutError(
        type: WalletCheckoutErrorType.unavailable,
        outcomeUncertain: true,
      );
    }
    if (response.state == ResponseState.offline) {
      return const WalletCheckoutError(type: WalletCheckoutErrorType.offline);
    }
    if (response.state == ResponseState.unauthorized) {
      return const WalletCheckoutError(
        type: WalletCheckoutErrorType.signInRequired,
      );
    }
    if (const [400, 403, 422].contains(response.statusCode)) {
      return WalletCheckoutError(
        type: WalletCheckoutErrorType.rejected,
        message: WalletCheckoutError.safeMessage(response.data),
      );
    }
    return const WalletCheckoutError(
      type: WalletCheckoutErrorType.unavailable,
      outcomeUncertain: true,
    );
  }

  void cancelCheckoutCreation() {
    if (_disposed) return;
    final shouldNotify = _isCreatingCheckout || _checkoutError != null;
    ++_checkoutGeneration;
    _checkoutCancellation?.cancel('wallet sheet closed');
    _checkoutCancellation = null;
    _isCreatingCheckout = false;
    _checkoutError = null;
    if (shouldNotify) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    ++_checkoutGeneration;
    _checkoutCancellation?.cancel('wallet controller disposed');
    chargeAmountEc.dispose();
    chargeAmountFocusNode.dispose();
    super.dispose();
  }

  Future<WalletTransferPreview?> checkMonyTransfer({
    required String mobile,
    required num amount,
    required TransferWallet wallet,
  }) async {
    final response = await ApiHelper.instance.post(
      Urls.checkMonyTransfer,
      body: FormData.fromMap({
        'mobile': mobile,
        'amount': amount,
        'target_wallet': wallet.value,
      }),
    );
    if (response.state == ResponseState.complete) {
      try {
        return WalletTransferPreview.fromJson(
          Map<String, dynamic>.from(response.data['data']),
          wallet: wallet,
          mobile: mobile,
          amount: amount,
        );
      } catch (_) {
        CommonMethods.showError(message: 'walletTransferUnavailable'.tr);
        return null;
      }
    }
    CommonMethods.showError(
      message: response.data is Map && response.data['message'] is String
          ? response.data['message'] as String
          : 'walletTransferFailed'.tr,
      apiResponse: response,
    );
    return null;
  }

  // null means an uncertain network result: retain the confirmation for a safe retry.
  Future<bool?> chargingMonyTransfer(WalletTransferPreview preview) async {
    final response = await ApiHelper.instance.post(
      Urls.transferWallet,
      body: FormData.fromMap(preview.payload),
    );
    if (response.state == ResponseState.complete) {
      CommonMethods.showToast(message: response.data['message']);
      return true;
    }
    CommonMethods.showError(
      message: response.data is Map && response.data['message'] is String
          ? response.data['message'] as String
          : 'walletTransferFailed'.tr,
      apiResponse: response,
    );
    return response.data is Map && response.data['transfer_rejected'] == true
        ? false
        : null;
  }
}
