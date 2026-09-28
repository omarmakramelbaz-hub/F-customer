import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../../../../helpers/hive/hive_methods.dart';
import '../../../../helpers/networking/api_helper.dart';
import '../../../../helpers/networking/urls.dart';
import '../../../../helpers/utils/common_methods.dart';
import '../../../../helpers/utils/utils.dart';
import '../model/wallet_model.dart';
import '../model/wallet_transfer.dart';
import '../../../../helpers/translation/all_translation.dart';

class WalletController extends ChangeNotifier {
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
    _selectedPayment = value;
    notifyListeners();
  }

  //=============>  charging wallet  <================
  Future<void> chargingWallet({
    required dynamic amount,
    required Function(String link) onSuccess,
  }) async {
    Utils.loading();
    FormData body = FormData.fromMap({
      'amount': amount,
      'payment_method': _selectedPayment,
    });
    final response = await ApiHelper.instance.post(
      Urls.chargingWallet,
      body: body,
    );
    Utils.loadingOff();
    if (response.state == ResponseState.complete) {
      // CommonMethods.showToast(message: response.data['message']);
      onSuccess.call(response.data['data']['link']);
    } else {
      CommonMethods.showError(
        message: response.data['message'],
        apiResponse: response,
      );
    }
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
