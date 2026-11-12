import 'package:faskhaninja/helpers/theme/fasakhansta_brand.dart';
import 'package:country_picker/country_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../helpers/extension/string_extension.dart';
import '../../../../helpers/extensions/extensions.dart';
import '../../../../helpers/hive/hive_methods.dart';
import '../../../../helpers/images/app_images.dart';
import '../../../../helpers/pusher_service/pusher_controller.dart';
import '../../../../helpers/routes/app_routers_import.dart';
import '../../../../helpers/theme/app_colors.dart';
import '../../../../helpers/theme/app_text_style.dart';
import '../../../../helpers/translation/all_translation.dart';
import '../../../../helpers/translation/main_app_bloc.dart';
import '../../../custom_widgets/custom_app_bar/custom_app_bar.dart';
import '../../../custom_widgets/custom_form_field/custom_form_field.dart';
import '../../../custom_widgets/custom_image/custom_image.dart';
import '../../../custom_widgets/validation/validation_mixin.dart';
import '../../bottom_navigation/bottom_navigation_bar_screen.dart';
import '../controller/auth_controller.dart';
import 'check_mobile_has_account.dart';
import 'create_new_account_screen.dart';
import 'register_screen.dart';
import 'social_login_row_widget.dart';

class LoginScreen extends StatefulWidget {
  static const routeName = 'LoginScreen';

  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with ValidationMixin {
  final _formKey = GlobalKey<FormState>();
  final _mobileEC = TextEditingController();
  final _passwordEC = TextEditingController();
  Country? _country;

  static const _text = FasakhanstaBrand.text;
  static const _muted = FasakhanstaBrand.muted;
  static const _border = FasakhanstaBrand.border;
  static const _softOrange = FasakhanstaBrand.orangeTint;

  @override
  void initState() {
    _country = CountryParser.parsePhoneCode('20');
    super.initState();
  }

  @override
  void dispose() {
    _mobileEC.dispose();
    _passwordEC.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<String>(
      stream: mainAppBloc.langStream,
      builder: (context, lang) {
        return Form(
          key: _formKey,
          child: Scaffold(
            backgroundColor: Colors.transparent,
            appBar: CustomAppBar(
              centerTitle: false,
              title: const CustomImage(
                path: AppImages.appLogo,
                type: ImageType.asset,
                height: 52,
                radius: 12,
              ),
              appBarColor: Colors.transparent,
              showLang: true,
            ),
            body: SafeArea(
              top: false,
              child: SingleChildScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 520),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _welcomeHeader(context),
                        const SizedBox(height: 14),
                        _loginCard(context),
                        const SizedBox(height: 14),
                        _guestCard(context),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _welcomeHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 15),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [
            FasakhanstaBrand.surfaceRaised,
            FasakhanstaBrand.surfaceRaised,
          ],
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: FasakhanstaBrand.border),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: FasakhanstaBrand.surface,
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x12000000),
                  blurRadius: 12,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Icon(
              Icons.lock_person_outlined,
              color: AppColors.mainAppColor,
              size: 27,
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'welcomeBackAgain'.tr,
                  style: AppTextStyle.text20BS().copyWith(
                    color: _text,
                    fontSize: 21,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'welcomeToYouPleaseEnterYourAccountDetails'.tr,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyle.text14RG().copyWith(
                    color: _muted,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _loginCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
      decoration: BoxDecoration(
        color: FasakhanstaBrand.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x10000000),
            blurRadius: 22,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'login'.tr,
            style: AppTextStyle.text18BS().copyWith(
              color: _text,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            context.languageCode == 'ar'
                ? 'استخدم رقم موبايلك وكلمة المرور للدخول إلى حسابك'
                : 'Use your mobile number and password to access your account',
            style: AppTextStyle.text12RG().copyWith(
              color: _muted,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 18),
          CustomFormField(
            validator: (v) => validatePhone(v, country: _country),
            controller: _mobileEC,
            keyboardType: TextInputType.phone,
            country: _country,
            title: 'mobileNumber'.tr,
          ),
          const SizedBox(height: 14),
          CustomFormField(
            validator: validatePassword,
            controller: _passwordEC,
            title: 'password'.tr,
            isPassword: true,
          ),
          const SizedBox(height: 4),
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: TextButton.icon(
              onPressed: () =>
                  NamedNavigatorImpl.push(CheckMobileHasAccount.routeName),
              icon: Icon(
                Icons.lock_reset_rounded,
                size: 17,
                color: AppColors.mainAppColor,
              ),
              label: Text(
                'didYouForgetPassword'.tr,
                style: AppTextStyle.text12BS().copyWith(
                  color: AppColors.mainAppColor,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          _primaryLoginButton(context),
          const SizedBox(height: 18),
          _socialDivider(context),
          const SizedBox(height: 12),
          const SocialLoginRowWidget(),
          const SizedBox(height: 12),
          _accountCreationCard(context),
        ],
      ),
    );
  }

  Widget _primaryLoginButton(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _submitLogin(context),
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          height: 54,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.mainAppColor, FasakhanstaBrand.orange],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AppColors.mainAppColor.withValues(alpha: .20),
                blurRadius: 16,
                offset: const Offset(0, 7),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'login'.tr,
                style: AppTextStyle.text18BW(color: FasakhanstaBrand.onOrange)
                    .copyWith(fontSize: 17, fontWeight: FontWeight.w800),
              ),
              const SizedBox(width: 9),
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: FasakhanstaBrand.surface.withValues(alpha: .20),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.arrow_forward_rounded,
                  color: FasakhanstaBrand.text,
                  size: 17,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _socialDivider(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: Divider(color: _border, height: 1)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.verified_user_outlined,
                size: 14,
                color: AppColors.mainAppColor,
              ),
              const SizedBox(width: 5),
              Text(
                context.languageCode == 'ar'
                    ? 'دخول سريع وآمن'
                    : 'Quick & secure sign in',
                style: AppTextStyle.text11RG().copyWith(
                  color: _muted,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        const Expanded(child: Divider(color: _border, height: 1)),
      ],
    );
  }

  Widget _accountCreationCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: FasakhanstaBrand.surfaceRaised,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(
          color: AppColors.mainAppColor.withValues(alpha: .16),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: FasakhanstaBrand.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: FasakhanstaBrand.border),
            ),
            child: Icon(
              Icons.person_add_alt_1_rounded,
              color: AppColors.mainAppColor,
              size: 21,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'youDontHaveAnAccount'.tr,
                  style: AppTextStyle.text12BS().copyWith(
                    color: _text,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  context.languageCode == 'ar'
                      ? 'أنشئ حسابك في خطوات بسيطة وابدأ الطلب فورًا'
                      : 'Create your account in a few simple steps',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyle.text10RG().copyWith(
                    color: _muted,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          OutlinedButton(
            onPressed: () => NamedNavigatorImpl.push(RegisterScreen.routeName),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.mainAppColor,
              backgroundColor: FasakhanstaBrand.surface,
              side: BorderSide(
                color: AppColors.mainAppColor.withValues(alpha: .35),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
            child: Text(
              'createAnAccount'.tr,
              style: AppTextStyle.text11BS().copyWith(
                color: AppColors.mainAppColor,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _guestCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: FasakhanstaBrand.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _border),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: _softOrange,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.visibility_outlined,
                  color: AppColors.mainAppColor,
                  size: 21,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'loginAsGuest'.tr,
                      style: AppTextStyle.text14BS().copyWith(
                        color: _text,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      context.languageCode == 'ar'
                          ? 'تصفح التطبيق أولاً ويمكنك تسجيل الدخول في أي وقت'
                          : 'Browse first and sign in whenever you are ready',
                      style: AppTextStyle.text10RG().copyWith(
                        color: _muted,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton(
                onPressed: () {
                  HiveMethods.deleteToken();
                  HiveMethods.updateIsVisitor(true);
                  NamedNavigatorImpl.push(
                    BottomNavigationBarScreen.routeName,
                    clean: true,
                  );
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.mainAppColor,
                  side: BorderSide(
                    color: AppColors.mainAppColor.withValues(alpha: .35),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(13),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                ),
                child: Icon(
                  Icons.arrow_forward_rounded,
                  size: 20,
                  color: AppColors.mainAppColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _submitLogin(BuildContext context) {
    FocusManager.instance.primaryFocus?.unfocus();
    if (!_formKey.currentState!.validate()) return;

    context.read<AuthController>().login(
      onHaveIdANDToken: (id, token) {
        context.read<PusherController>().initPusher(
          channelName: 'private-user.$id',
          userId: id,
          token: token,
        );
      },
      onFirstTime: () {
        NamedNavigatorImpl.push(CreateNewAccountScreen.routeName);
      },
      mobile: _mobileEC.text.removeZero(),
      password: _passwordEC.text,
      onSuccess: (register, mobileVerifiedAt) {
        HiveMethods.updateIsVisitor(false);
        if (register == 0 && mobileVerifiedAt != null) {
          NamedNavigatorImpl.push(
            BottomNavigationBarScreen.routeName,
            replace: true,
          );
        } else {
          NamedNavigatorImpl.push(
            BottomNavigationBarScreen.routeName,
            clean: true,
          );
        }
      },
    );
  }
}
