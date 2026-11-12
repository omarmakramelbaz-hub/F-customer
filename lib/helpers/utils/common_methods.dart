import 'package:faskhaninja/helpers/theme/fasakhansta_brand.dart';

import 'dart:async';

import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';

import '../../view/custom_widgets/custom_toast/custom_toast.dart';
import '../networking/api_helper.dart';
import '../routes/app_routers_import.dart';
import '../theme/app_colors.dart';
import '../translation/all_translation.dart';

class CommonMethods {
  static void showAlertDialog({String? title, required String message}) {
    showCupertinoDialog(
      context: NamedNavigatorImpl.navigatorState.currentContext!,
      builder: (context) => CupertinoAlertDialog(
        title: title != null
            ? Text(
                title,
                style: const TextStyle(
                  color: FasakhanstaBrand.text,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              )
            : null,
        content: Text(
          message,
          style: const TextStyle(
            color: FasakhanstaBrand.text,
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
        ),
        actions: [
          CupertinoDialogAction(
            child: Text(
              'ok'.tr,
              style: const TextStyle(
                color: FasakhanstaBrand.danger,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            onPressed: () => Navigator.of(context).pop(true),
          ),
        ],
      ),
    );
  }

  static void showChooseDialog(
    BuildContext context, {
    String? title,
    required String message,
    required VoidCallback onPressed,
  }) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: title != null
            ? Text(
                title,
                style: const TextStyle(
                  color: FasakhanstaBrand.text,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              )
            : null,
        content: Text(
          message,
          style: const TextStyle(
            color: FasakhanstaBrand.text,
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
        ),
        actions: [
          CupertinoDialogAction(
            child: Text(
              'no'.tr,
              style: TextStyle(
                color: AppColors.darkTextColor,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            onPressed: () => Navigator.of(context).pop(),
          ),
          CupertinoDialogAction(
            onPressed: onPressed,
            child: Text(
              'yes'.tr,
              style: TextStyle(
                color: AppColors.darkTextColor,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static void showToast({
    required String message,
    String? title,
    String? icon,
    ToastType type = ToastType.success,
    Color? backgroundColor,
    Color? textColor,
    int seconds = 3,
  }) {
    final normalizedMessage = message.trim().toLowerCase();
    final isArabic = _isArabic();
    final isSuccess = type == ToastType.success;

    final isLoginSuccess = isSuccess &&
        (message.contains('تسجيل الدخول') ||
            message.contains('تم الدخول') ||
            normalizedMessage.contains('logged in') ||
            normalizedMessage.contains('login success') ||
            normalizedMessage.contains('login successfully') ||
            normalizedMessage.contains('signed in'));

    final isLogoutSuccess = isSuccess &&
        (message.contains('تسجيل الخروج') ||
            normalizedMessage.contains('logged out') ||
            normalizedMessage.contains('logout success') ||
            normalizedMessage.contains('logout successfully') ||
            normalizedMessage.contains('signed out'));

    final isDeliveryCancellation = isSuccess &&
        (message.contains('تم الإلغاء') ||
            message.contains('تم الالغاء') ||
            message.contains('تم الغاء') ||
            (normalizedMessage.contains('cancel') &&
                (normalizedMessage.contains('order') ||
                    normalizedMessage.contains('success'))));

    final hasFareKeyword = message.contains('أجرة') ||
        message.contains('اجرة') ||
        message.contains('تسعير') ||
        message.contains('السعر') ||
        message.contains('سعر') ||
        normalizedMessage.contains('fare') ||
        normalizedMessage.contains('price');

    final hasFareUpdateKeyword = message.contains('تم') ||
        message.contains('تحديث') ||
        message.contains('تعديل') ||
        message.contains('رفع') ||
        message.contains('زيادة') ||
        message.contains('نجاح') ||
        normalizedMessage.contains('updated') ||
        normalizedMessage.contains('increased') ||
        normalizedMessage.contains('success');

    final isDeliveryFareUpdate =
        isSuccess && hasFareKeyword && hasFareUpdateKeyword;

    final isAddToCartSuccess = isSuccess &&
        ((message.contains('إضاف') && message.contains('السلة')) ||
            (normalizedMessage.contains('add') &&
                normalizedMessage.contains('cart')));

    if (isAddToCartSuccess) {
      showCartSuccess(message: message, seconds: seconds);
      return;
    }

    if (isLoginSuccess) {
      _showBrandedToast(
        type: ToastType.success,
        title: isArabic ? 'تم الدخول بنجاح' : 'Login successful',
        message: isArabic
            ? 'أهلاً بك، تم تسجيل دخولك إلى حسابك بنجاح'
            : 'Welcome back. You are signed in successfully.',
        seconds: seconds,
      );
      return;
    }

    if (isLogoutSuccess) {
      _showBrandedToast(
        type: ToastType.success,
        title: isArabic ? 'تم تسجيل الخروج' : 'Logged out',
        message: isArabic
            ? 'تم إنهاء الجلسة بأمان. ننتظرك في أي وقت.'
            : 'Your session ended safely. See you again soon.',
        seconds: seconds,
      );
      return;
    }

    if (isDeliveryCancellation) {
      _showBrandedToast(
        type: ToastType.warning,
        title: isArabic ? 'تم إلغاء طلب التوصيل' : 'Delivery request cancelled',
        message: isArabic
            ? 'تم إيقاف البحث عن مندوب ولن يتم تنفيذ الطلب.'
            : 'The courier search has stopped and the request will not be processed.',
        accentColor: const Color(0xFFD84A4A),
        seconds: seconds,
      );
      return;
    }

    if (isDeliveryFareUpdate) {
      _showBrandedToast(
        type: ToastType.success,
        title: isArabic ? 'تم تحديث أجرة التوصيل' : 'Delivery fare updated',
        message: isArabic
            ? 'تم تحديث الطلب وإرساله للمندوبين بالأجرة الجديدة.'
            : 'The request was updated and sent with the new delivery fare.',
        seconds: seconds,
      );
      return;
    }

    _showBrandedToast(
      type: type,
      title: title,
      message: message,
      icon: icon,
      accentColor: backgroundColor,
      textColor: textColor,
      seconds: seconds,
    );
  }

  static void showCartSuccess({required String message, int seconds = 3}) {
    final isArabic = _isArabic();

    _showBrandedToast(
      type: ToastType.success,
      title: isArabic ? 'تمت الإضافة إلى السلة' : 'Added to cart',
      message: message,
      seconds: seconds,
      actionLabel: isArabic ? 'عرض السلة' : 'View cart',
      actionIcon: Icons.shopping_cart_outlined,
      onAction: () => NamedNavigatorImpl.push('CartScreen'),
    );
  }

  static void showError({
    ApiResponse? apiResponse,
    required String message,
    String? title,
    String? icon,
    Color? backgroundColor,
    Color? textColor,
    int seconds = 3,
    VoidCallback? onTap,
  }) {
    final isArabic = _isArabic();

    if (message == 'chooseDeliveryLocationsFirst'.tr) {
      _showBrandedToast(
        type: ToastType.warning,
        title: isArabic ? 'حدد موقع التوصيل أولاً' : 'Choose delivery location',
        message: message,
        icon: icon,
        accentColor: backgroundColor,
        textColor: textColor,
        seconds: seconds,
        onTap: onTap,
      );
      return;
    }

    final isOffline = apiResponse?.state == ResponseState.offline;

    _showBrandedToast(
      type: isOffline ? ToastType.offline : ToastType.error,
      title: title ??
          (isOffline
              ? (isArabic
                  ? 'لا يوجد اتصال بالإنترنت'
                  : 'No internet connection')
              : (isArabic ? 'تعذر إتمام العملية' : 'Something went wrong')),
      message: message,
      icon: icon,
      accentColor: backgroundColor,
      textColor: textColor,
      seconds: seconds,
      onTap: onTap,
    );
  }

  static void _showBrandedToast({
    required ToastType type,
    required String message,
    String? title,
    String? icon,
    Color? accentColor,
    Color? textColor,
    int seconds = 3,
    VoidCallback? onTap,
    String? actionLabel,
    IconData? actionIcon,
    VoidCallback? onAction,
  }) {
    BotToast.showCustomText(
      duration: Duration(seconds: seconds),
      toastBuilder: (cancelFunc) => CustomToast(
        type: type,
        title: title,
        message: message,
        icon: icon,
        backgroundColor: accentColor,
        textColor: textColor,
        onClose: cancelFunc,
        onTap: onTap,
        actionLabel: actionLabel,
        actionIcon: actionIcon,
        onAction: onAction == null
            ? null
            : () {
                cancelFunc();
                onAction();
              },
      ),
    );
  }

  static bool _isArabic() {
    final context = NamedNavigatorImpl.navigatorState.currentContext;
    if (context == null) return true;
    return Localizations.localeOf(context).languageCode == 'ar';
  }

  static Future<bool> hasConnection() async {
    bool result = await InternetConnection().hasInternetAccess;

    if (!result) {
      final completer = Completer<bool>();
      final subscription = InternetConnection().onStatusChange.listen((status) {
        if (status == InternetStatus.connected) {
          completer.complete(true);
        }
      });

      Future.delayed(const Duration(seconds: 5), () {
        if (!completer.isCompleted) {
          completer.complete(false);
        }
        subscription.cancel();
      });

      result = await completer.future;
    }

    return result;
  }
}
