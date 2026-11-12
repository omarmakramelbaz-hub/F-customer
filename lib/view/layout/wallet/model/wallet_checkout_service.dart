import 'package:dio/dio.dart';

import '../../../../helpers/networking/api_helper.dart';
import '../../../../helpers/networking/urls.dart';

class WalletCheckoutService {
  const WalletCheckoutService({ApiHelper? api}) : _api = api;

  final ApiHelper? _api;

  Future<ApiResponse> create({
    required dynamic amount,
    required String paymentMethod,
    required CancelToken cancelToken,
    required Duration timeout,
    required String sessionToken,
    required bool Function() canSendRequest,
  }) => (_api ?? ApiHelper.instance).post(
    Urls.chargingWallet,
    body: FormData.fromMap({'amount': amount, 'payment_method': paymentMethod}),
    requestTimeout: timeout,
    cancelToken: cancelToken,
    // Headers stay bound to the account that requested this checkout.
    headers: {'Authorization': 'Bearer $sessionToken'},
    canSendRequest: canSendRequest,
  );
}
