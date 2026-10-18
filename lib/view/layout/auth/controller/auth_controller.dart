import 'dart:developer';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../../../../helpers/hive/hive_methods.dart';
import '../../../../helpers/networking/api_helper.dart';
import '../../../../helpers/networking/urls.dart';
import '../../../../helpers/notification_helper/notification_helper.dart';
import '../../../../helpers/routes/app_routers_import.dart';
import '../../../../helpers/utils/common_methods.dart';
import '../../../../helpers/utils/utils.dart';
import '../../../custom_widgets/custom_toast/custom_toast.dart';
import '../model/area_model.dart';
import '../model/profile_model.dart';
import '../screen/login_screen.dart';
import '../screen/social_auth_phone_screen.dart';

class AuthController extends ChangeNotifier {
  static const String _googleWebClientId = String.fromEnvironment(
    'GOOGLE_WEB_CLIENT_ID',
    defaultValue: '224648167390-efdtr7rjcnept7eiml1d642sdn8n9ki7.apps.googleusercontent.com',
  );

  void initialProfile() {
    _profileResponse = ApiResponse(state: ResponseState.sleep, data: null);
    _profile = null;
  }

  final formKey = GlobalKey<FormState>();
  final codeEC = TextEditingController();

  ApiResponse _profileResponse = ApiResponse(state: ResponseState.sleep, data: null);
  ApiResponse get profileResponse => _profileResponse;
  ProfileModel? _profile;
  ProfileModel? get profile => _profile;

  int? _selectedAddressId;

  int? get selectedAddressId => _selectedAddressId;

  void setSelectedAddressId(int? addressId) {
    _selectedAddressId = addressId;
    notifyListeners();
  }

  Future<void> getProfile({
    VoidCallback? onSuccess,
    VoidCallback? onUnauthenticated,
    void Function(int id, String token)? onHaveIdANDToken,
  }) async {
    _profileResponse = ApiResponse(state: ResponseState.loading, data: null);
    notifyListeners();

    try {
      final response = await ApiHelper.instance.get(Urls.profile);
      _profileResponse = response;

      if (_profileResponse.state == ResponseState.complete) {
        _profile = ProfileModel.fromJson(_profileResponse.data['data']);

        if (_profile?.id != null && _profile?.token != null) {
          onHaveIdANDToken?.call(_profile!.id!, _profile!.token!);
        }

        onSuccess?.call();
      } else if (_profileResponse.state == ResponseState.unauthorized) {
        onUnauthenticated?.call();
      }
    } catch (e) {
      log(e.toString());
    } finally {
      notifyListeners();
    }
  }

  Future<void> login({
    required String mobile,
    required String password,
    required Function(int register, String? mobileVerifiedAt) onSuccess,
    required Function() onFirstTime,
    void Function(int id, String token)? onHaveIdANDToken,
  }) async {
    Utils.loading();

    FormData body =
        FormData.fromMap({'mobile': mobile, 'fcm_id': FirebaseNotifications.fcmToken ?? '', 'password': password});
    final response = await ApiHelper.instance.post(Urls.login, body: body);
    Utils.loadingOff();
    if (response.state == ResponseState.complete) {
      HiveMethods.updateToken(response.data['data']['user_data']['token']);
      _profile = ProfileModel.fromJson(response.data['data']['user_data']);
      if (_profile?.id != null && _profile?.token != null) {
        onHaveIdANDToken?.call(_profile!.id!, _profile!.token!);
        log('============================ pusher connected =======================');
      }

      if (response.data['data']['register'] == 0 && _profile?.mobileVerifiedAt != null) {
        HiveMethods.updateUserId(_profile?.id);
        getProfile();
      }
      CommonMethods.showToast(message: response.data['message']);
      if (response.data['data']['register'] == 0 && _profile?.email != null) {
        onSuccess.call(response.data['data']['register'], _profile?.mobileVerifiedAt);
      } else {
        onFirstTime.call();
      }

      notifyListeners();
    } else {
      CommonMethods.showError(message: response.data['message'], apiResponse: response);
    }
  }

  Future<void> signInWithGoogle({
    required Function(int register, String? mobileVerifiedAt) onSuccess,
    required Function() onFirstTime,
    void Function(int id, String token)? onHaveIdANDToken,
  }) async {
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn(
        clientId: kIsWeb ? _googleWebClientId : null,
        scopes: const ['email', 'profile'],
      );

      // On Web, open the Google popup immediately from the user's tap.
      // Awaiting signOut() first can lose browser user-activation and cause
      // the popup to be silently blocked.
      if (!kIsWeb) {
        await googleSignIn.signOut();
      }

      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

      if (googleUser != null) {
        Utils.loading();

        FormData body = FormData.fromMap({
          'name': googleUser.displayName,
          'email': googleUser.email,
          'google_uuid': googleUser.id,
          'provider': 'google',
          'fcm_id': FirebaseNotifications.fcmToken ?? '',
        });

        await _socialLoginRequest(
          url: Urls.loginWithGoogle,
          body: body,
          onSuccess: onSuccess,
          onFirstTime: onFirstTime,
          onHaveIdANDToken: onHaveIdANDToken,
        );
      }
    } catch (error) {
      Utils.loadingOff();
      log('Google Sign In Error: $error');
      CommonMethods.showToast(
        message: 'Google Sign In Failed: $error',
        type: ToastType.error,
      );
    }
  }

  Future<void> signInWithApple({
    required Function(int register, String? mobileVerifiedAt) onSuccess,
    required Function() onFirstTime,
    void Function(int id, String token)? onHaveIdANDToken,
  }) async {
    try {
      if (!await SignInWithApple.isAvailable()) {
        CommonMethods.showToast(message: 'Apple Sign In is not available on this device', type: ToastType.error);
        return;
      }

      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      Utils.loading();

      String? name;
      if (credential.givenName != null || credential.familyName != null) {
        name = '${credential.givenName ?? ''} ${credential.familyName ?? ''}'.trim();
      }

      FormData body = FormData.fromMap({
        'name': name ?? 'Apple User',
        'email': credential.email,
        'apple_uuid': credential.userIdentifier,
        'provider': 'apple',
        'fcm_id': FirebaseNotifications.fcmToken ?? '',
      });

      await _socialLoginRequest(
        url: Urls.loginWithApple,
        body: body,
        onSuccess: onSuccess,
        onFirstTime: onFirstTime,
        onHaveIdANDToken: onHaveIdANDToken,
      );
    } catch (error) {
      Utils.loadingOff();
      if (error is SignInWithAppleAuthorizationException) {
        if (error.code == AuthorizationErrorCode.canceled) {
          return;
        }
      }
      log('Apple Sign In Error: $error');
      CommonMethods.showToast(message: 'Apple Sign In Failed: $error', type: ToastType.error);
    }
  }

  Future<void> signInWithFacebook({
    required Function(int register, String? mobileVerifiedAt) onSuccess,
    required Function() onFirstTime,
    void Function(int id, String token)? onHaveIdANDToken,
  }) async {
    try {
      if (kIsWeb && !FacebookAuth.i.isWebSdkInitialized) {
        CommonMethods.showToast(
          message: 'Facebook login is not configured yet. Please add the Facebook App ID.',
          type: ToastType.error,
        );
        return;
      }

      final LoginResult result = await FacebookAuth.instance.login(
        permissions: const ['email', 'public_profile'],
      );

      if (result.status == LoginStatus.success) {
        final userData = await FacebookAuth.instance.getUserData(
          fields: 'id,name,email,picture.width(200)',
        );

        Utils.loading();

        FormData body = FormData.fromMap({
          'name': userData['name'],
          'email': userData['email'],
          'facebook_uuid': userData['id'],
          'image_path': userData['picture']?['data']?['url'],
          'provider': 'facebook',
          'fcm_id': FirebaseNotifications.fcmToken ?? '',
        });

        await _socialLoginRequest(
          url: Urls.loginWithFacebook,
          body: body,
          onSuccess: onSuccess,
          onFirstTime: onFirstTime,
          onHaveIdANDToken: onHaveIdANDToken,
        );
      } else if (result.status == LoginStatus.cancelled) {
        return;
      } else {
        CommonMethods.showToast(
          message: 'Facebook Sign In Failed: ${result.message}',
          type: ToastType.error,
        );
      }
    } catch (error) {
      Utils.loadingOff();
      log('Facebook Sign In Error: $error');
      CommonMethods.showToast(
        message: 'Facebook Sign In Failed: $error',
        type: ToastType.error,
      );
    }
  }

  Future<void> _socialLoginRequest({
    required String url,
    required FormData body,
    required Function(int register, String? mobileVerifiedAt) onSuccess,
    required Function() onFirstTime,
    void Function(int id, String token)? onHaveIdANDToken,
  }) async {
    final response = await ApiHelper.instance.post(url, body: body);
    Utils.loadingOff();

    if (response.state == ResponseState.complete) {
      if (response.data['data'] != null && response.data['data']['user_data'] != null) {
        HiveMethods.updateToken(response.data['data']['user_data']['token']);
        _profile = ProfileModel.fromJson(response.data['data']['user_data']);

        if (_profile?.id != null && _profile?.token != null) {
          onHaveIdANDToken?.call(_profile!.id!, _profile!.token!);
          log('============================ pusher connected =======================');
        }

        if (response.data['data']['register'] == 0 && _profile?.mobileVerifiedAt != null) {
          HiveMethods.updateUserId(_profile?.id);
          getProfile();
        }

        CommonMethods.showToast(message: response.data['message']);

        if (_profile?.mobile == null || _profile?.mobile?.isEmpty == true) {
          NamedNavigatorImpl.push(
            SocialAuthPhoneScreen.routeName,
            arguments: {
              'provider': body.fields.firstWhere((e) => e.key == 'provider').value,
              'provider_uuid': body.fields.firstWhere((e) => e.key.contains('uuid')).value,
              'name': body.fields.firstWhere((e) => e.key == 'name').value,
              'email': body.fields.firstWhere((e) => e.key == 'email', orElse: () => const MapEntry('email', '')).value,
            },
          );
        } else if (response.data['data']['register'] == 0 && _profile?.email != null) {
          onSuccess.call(response.data['data']['register'], _profile?.mobileVerifiedAt);
        } else {
          onFirstTime.call();
        }
        notifyListeners();
      } else {
        CommonMethods.showError(message: 'Invalid response from server', apiResponse: response);
      }
    } else {
      CommonMethods.showError(message: response.data['message'], apiResponse: response);
    }
  }

  Future<void> completeSocialAuth({
    required Map<String, dynamic> socialAuthData,
    required String mobile,
    required String countryCode,
    required Function(int register, String? mobileVerifiedAt) onSuccess,
    void Function(int id, String token)? onHaveIdANDToken,
  }) async {
    Utils.loading();

    FormData body = FormData.fromMap({
      ...socialAuthData,
      'mobile': mobile,
      'country_code': countryCode,
      'fcm_id': FirebaseNotifications.fcmToken ?? '',
    });

    final response = await ApiHelper.instance.post(
      socialAuthData['provider'] == 'google'
          ? Urls.loginWithGoogle
          : socialAuthData['provider'] == 'apple'
              ? Urls.loginWithApple
              : Urls.loginWithFacebook,
      body: body,
    );
    Utils.loadingOff();

    if (response.state == ResponseState.complete) {
      if (response.data['data'] != null && response.data['data']['user_data'] != null) {
        HiveMethods.updateToken(response.data['data']['user_data']['token']);
        _profile = ProfileModel.fromJson(response.data['data']['user_data']);

        if (_profile?.id != null && _profile?.token != null) {
          onHaveIdANDToken?.call(_profile!.id!, _profile!.token!);
          log('============================ pusher connected =======================');
        }

        if (response.data['data']['register'] == 0 && _profile?.mobileVerifiedAt != null) {
          HiveMethods.updateUserId(_profile?.id);
          getProfile();
        }

        CommonMethods.showToast(message: response.data['message']);
        onSuccess.call(response.data['data']['register'], _profile?.mobileVerifiedAt);
        notifyListeners();
      } else {
        CommonMethods.showError(message: 'Invalid response from server', apiResponse: response);
      }
    } else {
      CommonMethods.showError(message: response.data['message'], apiResponse: response);
    }
  }

  Future<void> codeActivate({required String mobileCode, required VoidCallback onSuccess}) async {
    Utils.loading();

    FormData body = FormData.fromMap({'mobile_code': mobileCode});
    final response = await ApiHelper.instance.post(Urls.codeActivate, body: body);
    Utils.loadingOff();
    if (response.state == ResponseState.complete) {
      CommonMethods.showToast(message: response.data['message']);

      onSuccess.call();
    } else {
      CommonMethods.showError(message: response.data['message'], apiResponse: response);
    }
  }

  Future<void> updateUserInfo({
    required String name,
    required String email,
    required int id,
    required VoidCallback onSuccess,
    void Function(int id, String token)? onHaveIdANDToken,
  }) async {
    Utils.loading();
    final response = await ApiHelper.instance.post(
      Urls.updateUserProfile,
      body: FormData.fromMap(
          {'name': name, 'email': email, 'area_id': id, 'fcm_id': FirebaseNotifications.fcmToken ?? ''}),
    );
    Utils.loadingOff();
    if (response.state == ResponseState.complete) {
      CommonMethods.showToast(message: response.data['message']);
      if (response.data['data']['id'] != null && response.data['data']['token'] != null) {
        onHaveIdANDToken?.call(response.data['data']['id'], response.data['data']['token']);
      }

      onSuccess.call();
    } else {
      CommonMethods.showError(message: response.data['message'], apiResponse: response);
    }
  }

  void initialArea() {
    _areaResponse = ApiResponse(state: ResponseState.sleep, data: null);
    _area = [];
    notifyListeners();
  }

  ApiResponse _areaResponse = ApiResponse(state: ResponseState.sleep, data: null);
  ApiResponse get areaResponse => _areaResponse;
  List<AreaModel> _area = [];
  List<AreaModel> get area => _area;

  Future<void> getArea() async {
    _areaResponse = ApiResponse(state: ResponseState.loading, data: null);
    _area = [];
    notifyListeners();
    _areaResponse = await ApiHelper.instance.get(Urls.area);
    notifyListeners();
    if (_areaResponse.state == ResponseState.complete) {
      Iterable iterable = _areaResponse.data['data'];
      _area = iterable.map((e) => AreaModel.fromJson(e)).toList();
      notifyListeners();
    }
  }

  Future<void> logout() async {
    Utils.loading();
    final response = await ApiHelper.instance.post(Urls.logOut);
    Utils.loadingOff();
    if (response.state == ResponseState.complete) {
      CommonMethods.showToast(message: response.data['message']);
      _profile = null;

      HiveMethods.deleteToken();

      HiveMethods.updateNotificationCount(null);
      notifyListeners();
      NamedNavigatorImpl.push(LoginScreen.routeName, clean: true);
      HiveMethods.deleteSelectedCity();
      HiveMethods.deleteCity();
      HiveMethods.deleteLat();
      HiveMethods.deleteLan();
    } else {
      NamedNavigatorImpl.push(LoginScreen.routeName, clean: true);
      HiveMethods.deleteSelectedCity();
      HiveMethods.deleteCity();
      HiveMethods.deleteLat();
      HiveMethods.deleteLan();

      CommonMethods.showError(message: response.data['message'], apiResponse: response);
    }
  }

  Future<void> chooseAvatar({required final String gender, required VoidCallback onSuccess}) async {
    Utils.loading();
    final response = await ApiHelper.instance.put(Urls.chooseAvatar, queryParameters: {'gender': gender});
    Utils.loadingOff();
    if (response.state == ResponseState.complete) {
      CommonMethods.showToast(message: response.data['message']);
      notifyListeners();
      onSuccess.call();
    } else {
      CommonMethods.showError(message: response.data['message'], apiResponse: response);
    }
  }

  void initialCity() {
    _cityResponse = ApiResponse(state: ResponseState.sleep, data: null);
    _city = [];
    notifyListeners();
  }

  ApiResponse _cityResponse = ApiResponse(state: ResponseState.sleep, data: null);
  ApiResponse get cityResponse => _cityResponse;
  List<AreaModel> _city = [];
  List<AreaModel> get city => _city;

  Future<void> getCity() async {
    _cityResponse = ApiResponse(state: ResponseState.loading, data: null);
    _city = [];
    notifyListeners();
    _cityResponse = await ApiHelper.instance.get(Urls.city);
    notifyListeners();
    Utils.loadingOff();
    if (_cityResponse.state == ResponseState.complete) {
      Iterable iterable = _cityResponse.data['data'];
      _city = iterable.map((e) => AreaModel.fromJson(e)).toList();
      notifyListeners();
    }
  }

  Future<void> deleteAccount() async {
    Utils.loading();
    FormData body = FormData.fromMap({'password': codeEC.text});
    final response = await ApiHelper.instance.post(Urls.deleteAccount, body: body);
    Utils.loadingOff();
    if (response.state == ResponseState.complete) {
      CommonMethods.showToast(message: response.data['message']);
      NamedNavigatorImpl.push(LoginScreen.routeName);
    } else {
      CommonMethods.showError(message: response.data['message'], apiResponse: response);
    }
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
    required VoidCallback onSuccess,
  }) async {
    Utils.loading();
    FormData body = FormData.fromMap({
      'current_password': currentPassword,
      'password': newPassword,
      'password_confirmation': confirmPassword,
    });
    final response = await ApiHelper.instance.post(Urls.changePassword, body: body);
    Utils.loadingOff();
    if (response.state == ResponseState.complete) {
      CommonMethods.showToast(message: response.data['message']);
      onSuccess.call();
    } else {
      CommonMethods.showError(message: response.data['message'], apiResponse: response);
    }
  }

  Future<void> checkMobileHasAccount({
    required String mobile,
    required String countryCode,
    required void Function(String email) onSuccess,
  }) async {
    Utils.loading();
    FormData body = FormData.fromMap({'mobile': mobile, 'country_code': countryCode});
    final response = await ApiHelper.instance.post(Urls.checkMobileHasAccount, body: body);
    Utils.loadingOff();
    if (response.state == ResponseState.complete) {
      CommonMethods.showToast(message: response.data['message']);
      onSuccess.call(response.data['data']);
    } else {
      CommonMethods.showError(message: response.data['message'], apiResponse: response);
    }
  }

  Future<void> forgetPassword({required String email, required String mobile, required VoidCallback onSuccess}) async {
    Utils.loading();
    FormData body = FormData.fromMap({'mobile': mobile, 'email': email});
    final response = await ApiHelper.instance.post(Urls.forgetPassword, body: body);
    Utils.loadingOff();
    if (response.state == ResponseState.complete) {
      CommonMethods.showToast(message: response.data['message']);
      onSuccess.call();
    } else {
      CommonMethods.showError(message: response.data['message'], apiResponse: response);
    }
  }

  Future<void> checkCode({required String email, required String code, required VoidCallback onSuccess}) async {
    Utils.loading();
    FormData body = FormData.fromMap({'code': code, 'email': email});
    final response = await ApiHelper.instance.post(Urls.checkCode, body: body);
    Utils.loadingOff();
    if (response.state == ResponseState.complete) {
      CommonMethods.showToast(message: response.data['message']);
      onSuccess.call();
    } else {
      CommonMethods.showError(message: response.data['message'], apiResponse: response);
    }
  }

  Future<void> resetPassword({
    required String email,
    required String mobile,
    required String newPassword,
    required String confirmNewPassword,
    required VoidCallback onSuccess,
  }) async {
    Utils.loading();
    FormData body = FormData.fromMap({
      'new_password': newPassword,
      'confirm_password': confirmNewPassword,
      'email': email,
      'mobile': mobile,
    });
    final response = await ApiHelper.instance.post(Urls.resetPassword, body: body);
    Utils.loadingOff();
    if (response.state == ResponseState.complete) {
      CommonMethods.showToast(message: response.data['message']);
      onSuccess.call();
    } else {
      CommonMethods.showError(message: response.data['message'], apiResponse: response);
    }
  }
}
