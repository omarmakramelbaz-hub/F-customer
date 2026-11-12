import 'dart:developer';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../../../../helpers/networking/api_helper.dart';
import '../../../../helpers/networking/urls.dart';
// import '../../../../helpers/payment/paymob_service.dart';
import '../../../../helpers/utils/common_methods.dart';
import '../../../../helpers/utils/utils.dart';
import '../model/cart_item_model.dart';
import '../model/user_cart_model.dart';

class CartController extends ChangeNotifier {
  void init() {
    initialCart();
    getCart();
  }

  double totalPrice = 0.0;
  void initialCart() {
    _cartResponse = ApiResponse(state: ResponseState.sleep, data: null);
    _cart = null;
    totalPrice = 0.0;
    _isSwitchedScheduleDate = false;
    notifyListeners();
  }

  ApiResponse _cartResponse = ApiResponse(state: ResponseState.sleep, data: null);
  ApiResponse get cartResponse => _cartResponse;
  UserCartModel? _cart;
  UserCartModel? get cart => _cart;

  Future<void> getCart() async {
    _cartResponse = ApiResponse(state: ResponseState.loading, data: null);
    _cart = null;
    notifyListeners();
    _cartResponse = await ApiHelper.instance.get(Urls.userCart);
    if (_cartResponse.state == ResponseState.complete) {
      if (_cartResponse.data['data'] != null) {
        _cart = UserCartModel.fromJson(_cartResponse.data['data']);
        totalPrice = calculateTotalPrice();
        notifyListeners();
      } else {
        _cart = null;
      }
    }
    calculateTotalPrice();
    notifyListeners();
  }

  // void initialSetting() {
  //   _settingResponse = ApiResponse(
  //     state: ResponseState.sleep,
  //     data: null,
  //   );
  //   _setting = null;
  //   notifyListeners();
  // }

  // ApiResponse _settingResponse = ApiResponse(
  //   state: ResponseState.sleep,
  //   data: null,
  // );
  // ApiResponse get settingResponse => _settingResponse;
  // SettingModel? _setting;
  // SettingModel? get setting => _setting;

  // Future<void> getSetting() async {
  //   _settingResponse = ApiResponse(
  //     state: ResponseState.loading,
  //     data: null,
  //   );
  //   _setting = null;
  //   notifyListeners();
  //   _settingResponse = await ApiHelper.instance.get(Urls.setting);
  //   notifyListeners();
  //   if (_settingResponse.state == ResponseState.complete) {
  //     _setting = SettingModel.fromJson(_settingResponse.data['data']);
  //     notifyListeners();
  //   }
  // }

  String? _totalCountAddTCart;
  set totalCountAddTCart(String? value) {
    _totalCountAddTCart = value;
    //notifyListeners();
  }

  String? get totalCountAddTCart => _totalCountAddTCart;

  Future<void> addToCart({
    required int restaurantProductId,
    int? productFeature,
    String? productClean,
    required int qty,
    required VoidCallback onSuccess,
    required VoidCallback anotherCart,
  }) async {
    Utils.loading();

    FormData body = FormData.fromMap({
      'resturant_product_id': restaurantProductId,
      if (productFeature != null) ...{'product_feature': productFeature},
      if (productClean != null) ...{'product_clean': productClean},
      'qty': qty,
    });

    final response = await ApiHelper.instance.post(Urls.addToCart, body: body);
    debugPrint("ADD_TO_CART => ${response.state}");
    debugPrint(response.data.toString());
    Utils.loadingOff();
    if (response.state == ResponseState.complete) {
      CommonMethods.showToast(message: response.data['message']);
      totalPrice = calculateTotalPrice();
      onSuccess.call();
      notifyListeners();
    } else if (response.state == ResponseState.error) {
      notifyListeners();
      anotherCart.call();
    } else {
      CommonMethods.showError(message: response.data['message'], apiResponse: response);
    }
  }

  Future<void> updateCart({required num qty, required int id, required VoidCallback onSuccess}) async {
    Utils.loading();

    FormData body = FormData.fromMap({'qty': qty});
    final response = await ApiHelper.instance.post('${Urls.updateUserCart}$id/update', body: body);
    Utils.loadingOff();
    if (response.state == ResponseState.complete) {
      CommonMethods.showToast(message: response.data['message']);
      onSuccess.call();
    } else {
      CommonMethods.showError(message: response.data['message'], apiResponse: response);
    }
  }

  //==========>payment <=================
  String? _notes;
  String? get notes => _notes;
  void setNotes(String? value) {
    _notes = value;
    notifyListeners();
  }

  Future<void> orderPayment({
    required int userAddressId,
    required String paymentType,
    required String deliveryPrice,
    String? scheduleDate,
    String? notes,
    required String orderType,
    required Function(int orderId) onSuccess,
    required Function(String url, int orderId) onHadeLink,
    VoidCallback? onHasOTP,
  }) async {
    Utils.loading();

    FormData body = FormData.fromMap({
      'user_address_id': userAddressId,
      'payment_type': paymentType,
      'delivery_price': deliveryPrice,
      if (scheduleDate != null && scheduleDate.isNotEmpty) ...{
        'schedule_date': scheduleDate.replaceAll(' AM', '').replaceAll(' PM', ''),
      },
      'order_type': orderType,
      if (notes != null) 'notes': notes,
    });

    final response = await ApiHelper.instance.post(Urls.orderPayment, body: body);
    Utils.loadingOff();
    if (response.state == ResponseState.complete) {
      setNotes(null);
      // CommonMethods.showToast(message: response.data['message']);

      if (response.data['data'] == 1) {
        onHasOTP?.call();
      } else {
        if (paymentType == 'cash') {
          onSuccess.call(response.data['data']['id']);
        } else if (paymentType == 'wallet') {
          onSuccess.call(response.data['data']['id']);
        } else if (paymentType == 'online') {
          onHadeLink.call(response.data['data']['link'], response.data['data']['order_id']);
        } else if (paymentType == 'v_cash') {
          onHadeLink.call(response.data['data']['link'], response.data['data']['order_id']);
        }
      }
    } else {
      CommonMethods.showError(message: response.data['message'], apiResponse: response);
    }
  }

  double calculateTotalPrice() {
    double total = 0.0;
    if (_cart != null) {
      _cart!.carts?.forEach((element) {
        try {
          total += double.parse(element.price.toString()) * element.qty!;
        } catch (e) {
          log('Error parsing price: ${element.price} - ${e.toString()}');
        }
      });
    }
    return total;
  }

  void incrementQty(Carts cart) {
    cart.qty = cart.qty! + 1;
    updateCart(
      qty: cart.qty!,
      id: cart.id!,
      onSuccess: () {
        totalPrice = calculateTotalPrice();
        log(totalPrice.toString());
        notifyListeners();
      },
    );
  }

  void decrementQty(Carts cart) {
    if (cart.qty! > 0 || cart.qty! == 0) {
      cart.qty = cart.qty! - 1;
      updateCart(
        qty: cart.qty!,
        id: cart.id!,
        onSuccess: () {
          totalPrice = calculateTotalPrice();
          log(totalPrice.toString());
          notifyListeners();
        },
      );
    }
    // if (cart.qty == 0) {
    //   _cart?.carts!.removeWhere(
    //     (element) => element.id == cart.id,
    //   );
    //   notifyListeners();
    // }
  }

  void removeFromCart(Carts cart) {
    if (_cart != null && _cart!.carts != null) {
      _cart!.carts!.removeWhere((item) => item.id == cart.id);
      totalPrice = calculateTotalPrice();
      notifyListeners();
    }
  }

  String _selectedPayment = 'cash';
  String get selectedPayment => _selectedPayment;
  void setSelectedPayment(String value) {
    _selectedPayment = value;
    notifyListeners();
  }

  bool _isSwitchedScheduleDate = false;
  bool get isSwitchedscheduleDate => _isSwitchedScheduleDate;
  void setIsSwitchedscheduleDate(bool value) {
    _isSwitchedScheduleDate = value;
    notifyListeners();
  }

  //================================== delete cart ===============================
  Future<void> emptyCart({required VoidCallback onSuccess}) async {
    Utils.loading();

    final response = await ApiHelper.instance.post(Urls.emptyCart);
    Utils.loadingOff();
    if (response.state == ResponseState.complete) {
      CommonMethods.showToast(message: response.data['message']);
      onSuccess.call();
    } else {
      CommonMethods.showError(message: response.data['message'], apiResponse: response);
    }
  }

  //============================== single cart item ==============================
  ApiResponse _cartItemDetailsApiResponse = ApiResponse(state: ResponseState.sleep, data: null);
  ApiResponse get cartItemDetailsApiResponse => _cartItemDetailsApiResponse;

  void initialCartItemDetails() {
    _cartItemDetailsApiResponse = ApiResponse(state: ResponseState.sleep, data: null);
    _cartItemDetails = null;
    notifyListeners();
  }

  CartItemModel? _cartItemDetails;
  CartItemModel? get cartItemDetails => _cartItemDetails;

  Future<void> getCartItemDetails({required int id}) async {
    _cartItemDetailsApiResponse = ApiResponse(state: ResponseState.loading, data: null);
    _cartItemDetails = null;
    notifyListeners();
    _cartItemDetailsApiResponse = await ApiHelper.instance.get(Urls.getCartItemDetails(id));
    notifyListeners();
    if (_cartItemDetailsApiResponse.state == ResponseState.complete) {
      _cartItemDetails = CartItemModel.fromJson(_cartItemDetailsApiResponse.data['data']);
      notifyListeners();
    }
  }
  //============================= update cart item =====================

  Future<void> updateItemInCart({
    required int restaurantProductId,
    required int cartId,
    int? productFeature,
    String? productClean,
    required int qty,
    required VoidCallback onSuccess,
    required VoidCallback anotherCart,
  }) async {
    Utils.loading();

    FormData body = FormData.fromMap({
      'resturant_product_id': restaurantProductId,
      if (productFeature != null) ...{'product_feature': productFeature},
      if (productClean != null) ...{'product_clean': productClean},
      'qty': qty,
    });

    final response = await ApiHelper.instance.post(Urls.updateCartItemDetails(cartId), body: body);
    Utils.loadingOff();
    if (response.state == ResponseState.complete) {
      CommonMethods.showToast(message: response.data['message']);
      totalPrice = calculateTotalPrice();
      onSuccess.call();
      notifyListeners();
    } else if (response.state == ResponseState.error) {
      notifyListeners();
      anotherCart.call();
    } else {
      CommonMethods.showError(message: response.data['message'], apiResponse: response);
    }
  }

  //========================= otp checker ===================

  Future<void> otpChecker({required String otp, required VoidCallback onSuccess}) async {
    Utils.loading();

    FormData body = FormData.fromMap({'otp_first_no': otp});
    final response = await ApiHelper.instance.post(Urls.otpChecker, body: body);
    Utils.loadingOff();
    if (response.state == ResponseState.complete) {
      CommonMethods.showToast(message: response.data['message']);
      onSuccess.call();
    } else {
      CommonMethods.showError(message: response.data['message'], apiResponse: response);
    }
  }

  // // ========================= Apple Pay =========================
  // Future<void> processApplePayment({
  //   required Map<String, dynamic> applePayResult,
  //   required double amount,
  //   required String firstName,
  //   required String lastName,
  //   required String email,
  //   required String phoneNumber,
  //   required VoidCallback onSuccess,
  //   required Function(String) onError,
  // }) async {
  //   Utils.loading();
  //   try {
  //     // Prepare mandatory billing data for Paymob
  //     // Using dummy values for address if not available as Apple Pay handles shipping usually,
  //     // but Paymob API requires these fields to be present.
  //     final billingData = {
  //       'first_name': firstName.isNotEmpty ? firstName : 'User',
  //       'last_name': lastName.isNotEmpty ? lastName : 'Customer',
  //       'email': email.isNotEmpty ? email : 'customer@faskhaninja.com',
  //       'phone_number': phoneNumber.isNotEmpty ? phoneNumber : '01000000000',
  //       'apartment': 'NA',
  //       'floor': 'NA',
  //       'street': 'NA',
  //       'building': 'NA',
  //       'shipping_method': 'PKG',
  //       'postal_code': 'NA',
  //       'city': 'Cairo',
  //       'country': 'EG',
  //       'state': 'NA'
  //     };

  //     final result = await PaymobService().processApplePay(
  //       amount: amount,
  //       applePayResult: applePayResult,
  //       billingData: billingData,
  //     );

  //     Utils.loadingOff();

  //     if (result['success'] == true || result['pending'] == true) {
  //       // Success or Pending
  //       onSuccess.call();
  //     } else {
  //       onError.call('Payment Failed: ${result['data.message'] ?? 'Unknown Error'}');
  //     }
  //   } catch (e) {
  //     Utils.loadingOff();
  //     onError.call(e.toString());
  //   }
  // }
}
