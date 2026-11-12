import 'package:faskhaninja/helpers/theme/fasakhansta_brand.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:provider/provider.dart';

import '../../../../helpers/hive/hive_methods.dart';
import '../../../../helpers/images/app_images.dart';
import '../../../../helpers/networking/api_helper.dart';
import '../../../../helpers/networking/urls.dart';
import '../../../../helpers/notification_helper/notification_helper.dart';
import '../../../../helpers/pusher_service/pusher_controller.dart';
import '../../../../helpers/routes/app_routers_import.dart';
import '../../../../helpers/theme/app_text_style.dart';
import '../../../../helpers/utils/common_methods.dart';
import '../../../../helpers/utils/utils.dart';
import '../../../custom_widgets/custom_toast/custom_toast.dart';
import '../../bottom_navigation/bottom_navigation_bar_screen.dart';
import '../controller/auth_controller.dart';
import 'create_new_account_screen.dart';
import 'social_auth_phone_screen.dart';

class SocialBtn extends StatelessWidget {
  final String image;
  final String label;
  final VoidCallback onTap;

  const SocialBtn({
    super.key,
    required this.image,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(15),
          child: Ink(
            height: 52,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: FasakhanstaBrand.surface,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: FasakhanstaBrand.border),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x0D000000),
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 30,
                  height: 30,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: FasakhanstaBrand.surfaceRaised,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Image.asset(
                    image,
                    width: 22,
                    height: 22,
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(width: 7),
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyle.text12BS().copyWith(
                      color: FasakhanstaBrand.text,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class SocialLoginRowWidget extends StatelessWidget {
  const SocialLoginRowWidget({super.key});

  // OAuth 2.0 Web client for the same Firebase/Google Cloud project used by
  // the Android app. Android uses it as serverClientId so Google returns an
  // ID token whose audience can be verified safely by the backend.
  static const String _googleWebClientId = String.fromEnvironment(
    'GOOGLE_WEB_CLIENT_ID',
    defaultValue:
        '224648167390-efdtr7rjcnept7eiml1d642sdn8n9ki7.apps.googleusercontent.com',
  );

  void _onAuthSuccess(
    BuildContext context,
    int register,
    String? mobileVerifiedAt,
  ) {
    HiveMethods.updateIsVisitor(false);
    if (register == 0 && mobileVerifiedAt != null) {
      NamedNavigatorImpl.push(
        BottomNavigationBarScreen.routeName,
        replace: true,
      );
    } else {
      NamedNavigatorImpl.push(BottomNavigationBarScreen.routeName, clean: true);
    }
  }

  void _initPusher(BuildContext context, int id, String token) {
    context.read<PusherController>().initPusher(
          channelName: 'private-user.$id',
          userId: id,
          token: token,
        );
  }

  String _responseMessage(dynamic data, {required String fallback}) {
    if (data is Map) {
      final message = data['message'];
      if (message != null && message.toString().trim().isNotEmpty) {
        return message.toString().trim();
      }

      final error = data['error'];
      if (error != null && error.toString().trim().isNotEmpty) {
        return error.toString().trim();
      }

      final errors = data['errors'];
      if (errors is Map) {
        for (final value in errors.values) {
          if (value is List && value.isNotEmpty) {
            final first = value.first.toString().trim();
            if (first.isNotEmpty) return first;
          }
          final text = value?.toString().trim() ?? '';
          if (text.isNotEmpty) return text;
        }
      }
    }

    final text = data?.toString().trim() ?? '';
    if (text.isNotEmpty && text != '{}' && text != 'null') {
      return text;
    }
    return fallback;
  }

  int? _toInt(dynamic value) {
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '');
  }

  Future<void> _submitProviderToken(
    BuildContext context, {
    required String provider,
    required String accessToken,
    String? idToken,
  }) async {
    Utils.loading();

    try {
      final requestData = <String, dynamic>{
        'provider': provider,
        'fcm_id': FirebaseNotifications.fcmToken ?? '',
      };

      if (accessToken.trim().isNotEmpty) {
        requestData['access_token'] = accessToken.trim();
      }
      if (idToken?.trim().isNotEmpty == true) {
        requestData['id_token'] = idToken!.trim();
      }

      final body = FormData.fromMap(requestData);

      final response = await ApiHelper.instance.post(
        provider == 'facebook' ? Urls.loginWithFacebook : Urls.loginWithGoogle,
        body: body,
      );
      Utils.loadingOff();

      if (response.state != ResponseState.complete) {
        CommonMethods.showError(
          message: _responseMessage(
            response.data,
            fallback: provider == 'facebook'
                ? 'تعذر إكمال تسجيل الدخول بحساب Facebook.'
                : 'تعذر إكمال تسجيل الدخول بحساب Google.',
          ),
          apiResponse: response,
        );
        return;
      }

      if (response.data is! Map || response.data['data'] is! Map) {
        CommonMethods.showError(
          message: 'استجابة تسجيل الدخول من السيرفر غير صالحة.',
          apiResponse: response,
        );
        return;
      }

      final data = response.data['data'] as Map;
      if (data['user_data'] is! Map) {
        CommonMethods.showError(
          message: _responseMessage(
            response.data,
            fallback: 'لم يتم استلام بيانات المستخدم من السيرفر.',
          ),
          apiResponse: response,
        );
        return;
      }

      final userData = data['user_data'] as Map;
      final token = userData['token']?.toString() ?? '';
      final id = _toInt(userData['id']);
      final register = _toInt(data['register']) ?? 1;
      final mobileVerifiedAt = userData['mobile_verified_at']?.toString();
      final mobile = userData['mobile']?.toString().trim() ?? '';

      if (token.isEmpty) {
        CommonMethods.showError(
          message: 'السيرفر لم يرجع رمز جلسة صالح.',
          apiResponse: response,
        );
        return;
      }

      HiveMethods.updateToken(token);
      HiveMethods.updateIsVisitor(false);

      if (register == 0 && mobileVerifiedAt != null && id != null) {
        HiveMethods.updateUserId(id);
      }
      if (id != null) {
        _initPusher(context, id, token);
      }

      await context.read<AuthController>().getProfile();

      CommonMethods.showToast(
        message: _responseMessage(
          response.data,
          fallback: 'تم تسجيل الدخول بنجاح.',
        ),
      );

      if (mobile.isEmpty) {
        final socialAuthData = <String, dynamic>{'provider': provider};
        if (accessToken.trim().isNotEmpty) {
          socialAuthData['access_token'] = accessToken.trim();
        }
        if (idToken?.trim().isNotEmpty == true) {
          socialAuthData['id_token'] = idToken!.trim();
        }

        NamedNavigatorImpl.push(
          SocialAuthPhoneScreen.routeName,
          arguments: socialAuthData,
        );
        return;
      }

      _onAuthSuccess(context, register, mobileVerifiedAt);
    } catch (error) {
      Utils.loadingOff();
      CommonMethods.showToast(
        message: provider == 'facebook'
            ? 'Facebook: ${error.toString()}'
            : 'Google: ${error.toString()}',
        type: ToastType.error,
      );
    }
  }

  Future<void> _signInWithFacebook(BuildContext context) async {
    try {
      if (kIsWeb && !FacebookAuth.i.isWebSdkInitialized) {
        CommonMethods.showToast(
          message: 'Facebook login is not configured on this build.',
          type: ToastType.error,
        );
        return;
      }

      final result = await FacebookAuth.instance.login(
        permissions: const ['email', 'public_profile'],
      );

      if (result.status == LoginStatus.cancelled) return;
      if (result.status != LoginStatus.success) {
        CommonMethods.showToast(
          message: (result.message?.trim().isNotEmpty ?? false)
              ? result.message!.trim()
              : 'تعذر تسجيل الدخول باستخدام Facebook.',
          type: ToastType.error,
        );
        return;
      }

      final accessToken = result.accessToken?.tokenString ?? '';
      if (accessToken.isEmpty) {
        CommonMethods.showToast(
          message: 'Facebook لم يرجع Access Token صالح.',
          type: ToastType.error,
        );
        return;
      }

      await _submitProviderToken(
        context,
        provider: 'facebook',
        accessToken: accessToken,
      );
    } catch (error) {
      Utils.loadingOff();
      CommonMethods.showToast(
        message: 'Facebook: ${error.toString()}',
        type: ToastType.error,
      );
    }
  }

  Future<void> _signInWithGoogle(BuildContext context) async {
    try {
      final googleSignIn = GoogleSignIn(
        clientId: kIsWeb ? _googleWebClientId : null,
        serverClientId: kIsWeb ? null : _googleWebClientId,
        scopes: const ['email', 'profile'],
      );

      if (!kIsWeb) {
        await googleSignIn.signOut();
      }

      final googleUser = await googleSignIn.signIn();
      if (googleUser == null) return;

      final authentication = await googleUser.authentication;
      final accessToken = authentication.accessToken ?? '';
      final idToken = authentication.idToken ?? '';

      if (idToken.isEmpty && accessToken.isEmpty) {
        CommonMethods.showToast(
          message: 'Google لم يرجع رمز تحقق صالح.',
          type: ToastType.error,
        );
        return;
      }

      await _submitProviderToken(
        context,
        provider: 'google',
        accessToken: accessToken,
        idToken: idToken,
      );
    } catch (error) {
      Utils.loadingOff();
      CommonMethods.showToast(
        message: 'Google: ${error.toString()}',
        type: ToastType.error,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final showAppleLogin =
        !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: FasakhanstaBrand.surfaceRaised,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: FasakhanstaBrand.border),
      ),
      child: Row(
        children: [
          if (showAppleLogin) ...[
            SocialBtn(
              image: AppImages.appleLoginIcon,
              label: 'Apple',
              onTap: () {
                context.read<AuthController>().signInWithApple(
                      onSuccess: (register, mobileVerifiedAt) =>
                          _onAuthSuccess(context, register, mobileVerifiedAt),
                      onFirstTime: () => NamedNavigatorImpl.push(
                          CreateNewAccountScreen.routeName),
                      onHaveIdANDToken: (id, token) =>
                          _initPusher(context, id, token),
                    );
              },
            ),
            const SizedBox(width: 8),
          ],
          SocialBtn(
            image: AppImages.googleIcon,
            label: 'Google',
            onTap: () => _signInWithGoogle(context),
          ),
          const SizedBox(width: 8),
          SocialBtn(
            image: AppImages.facebookIcon,
            label: 'Facebook',
            onTap: () => _signInWithFacebook(context),
          ),
        ],
      ),
    );
  }
}
