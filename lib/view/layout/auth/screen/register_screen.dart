import 'package:country_picker/country_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../helpers/extension/string_extension.dart';
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
import '../model/whatsapp_consent_selection.dart';
import 'create_new_account_screen.dart';
import 'login_screen.dart';
import 'social_login_row_widget.dart';
import 'whatsapp_consent_fields.dart';

class RegisterScreen extends StatefulWidget {
  static const routeName = 'RegisterScreen';

  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> with ValidationMixin {
  final _formKey = GlobalKey<FormState>();
  final _mobileEC = TextEditingController();
  final _passwordEC = TextEditingController();
  final _focusNode = FocusNode();
  WhatsAppConsentSelection _whatsAppConsent = const WhatsAppConsentSelection();

  Country? _country;

  static const _text = Color(0xFF171A1F);
  static const _muted = Color(0xFF858B94);
  static const _border = Color(0xFFE7EAEE);
  static const _softOrange = Color(0xFFFFF3E7);

  @override
  void initState() {
    _country = CountryParser.parsePhoneCode('20');
    super.initState();
  }

  @override
  void dispose() {
    _mobileEC.dispose();
    _passwordEC.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<String>(
      stream: mainAppBloc.langStream,
      builder: (context, _) {
        return Form(
          key: _formKey,
          child: Scaffold(
            backgroundColor: const Color(0xFFF7F8FA),
            appBar: CustomAppBar(
              showLang: true,
              centerTitle: false,
              height: 70,
              title: const CustomImage(
                path: AppImages.appLogo,
                type: ImageType.asset,
                height: 52,
                radius: 12,
              ),
              appBarColor: Colors.white,
            ),
            body: SafeArea(
              top: false,
              child: SingleChildScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.fromLTRB(16, 18, 16, 26),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 520),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _welcomeCard(context),
                        const SizedBox(height: 14),
                        _registerCard(context),
                        const SizedBox(height: 14),
                        _loginCard(context),
                        const SizedBox(height: 14),
                        _socialCard(context),
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

  Widget _welcomeCard(BuildContext context) {
    final isArabic = context.languageCode == 'ar';

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 17, 16, 17),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [Color(0xFFFFF8F1), Color(0xFFFFF0E1)],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFFFD9B8)),
      ),
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x12000000),
                  blurRadius: 14,
                  offset: Offset(0, 5),
                ),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Icon(
                  Icons.person_outline_rounded,
                  color: AppColors.mainAppColor,
                  size: 30,
                ),
                Positioned(
                  right: 8,
                  bottom: 8,
                  child: Container(
                    width: 19,
                    height: 19,
                    decoration: BoxDecoration(
                      color: AppColors.mainAppColor,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: const Icon(
                      Icons.add_rounded,
                      size: 13,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'createANewAccount'.tr,
                  style: AppTextStyle.text20BS().copyWith(
                    color: _text,
                    fontSize: 21,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  'heyYouPleaseEnterYourMobileNumberToCompleteTheAccountCreation'
                      .tr,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyle.text13RG().copyWith(
                    color: _muted,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.verified_user_outlined,
                      size: 15,
                      color: AppColors.mainAppColor,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      isArabic
                          ? 'بياناتك محفوظة وآمنة'
                          : 'Your information stays private and secure',
                      style: AppTextStyle.text10RG().copyWith(
                        color: const Color(0xFF7F6A57),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _registerCard(BuildContext context) {
    final isArabic = context.languageCode == 'ar';

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
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
                      isArabic ? 'بيانات الحساب' : 'Account details',
                      style: AppTextStyle.text16BS().copyWith(
                        color: _text,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isArabic
                          ? 'ابدأ برقم الموبايل وكلمة المرور'
                          : 'Start with your mobile number and password',
                      style: AppTextStyle.text10RG().copyWith(color: _muted),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          CustomFormField(
            validator: (v) => validatePhone(v, country: _country),
            controller: _mobileEC,
            keyboardType: TextInputType.phone,
            title: 'mobileNumber'.tr,
            country: _country,
          ),
          const SizedBox(height: 12),
          WhatsAppConsentFields(
            isArabic: isArabic,
            selection: _whatsAppConsent,
            onChanged: (value) => setState(() => _whatsAppConsent = value),
          ),
          const SizedBox(height: 14),
          CustomFormField(
            validator: validatePassword,
            controller: _passwordEC,
            title: 'password'.tr,
            isPassword: true,
            focusNode: _focusNode,
            onFieldSubmitted: (_) => _focusNode.unfocus(),
          ),
          const SizedBox(height: 18),
          _nextButton(context),
        ],
      ),
    );
  }

  Widget _nextButton(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _submit(context),
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          height: 54,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.mainAppColor,
                const Color(0xFFFF8B25),
              ],
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
                'next'.tr,
                style: AppTextStyle.text18BW().copyWith(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(width: 9),
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: .20),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.arrow_forward_rounded,
                  color: Colors.white,
                  size: 17,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _loginCard(BuildContext context) {
    final isArabic = context.languageCode == 'ar';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _border),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: _softOrange,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.login_rounded,
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
                  'doYouHaveAnAccount'.tr,
                  style: AppTextStyle.text13BS().copyWith(
                    color: _text,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  isArabic
                      ? 'ادخل لحسابك الحالي بدون إنشاء حساب جديد'
                      : 'Sign in to your existing account',
                  style: AppTextStyle.text10RG().copyWith(color: _muted),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          OutlinedButton(
            onPressed: () => NamedNavigatorImpl.push(LoginScreen.routeName),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.mainAppColor,
              side: BorderSide(
                color: AppColors.mainAppColor.withValues(alpha: .35),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(13),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            ),
            child: Text(
              'signIn'.tr,
              style: AppTextStyle.text12BS().copyWith(
                color: AppColors.mainAppColor,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _socialCard(BuildContext context) {
    final isArabic = context.languageCode == 'ar';

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _border),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Expanded(child: Divider(color: _border, height: 1)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Text(
                  isArabic ? 'أو التسجيل باستخدام' : 'Or continue with',
                  style: AppTextStyle.text11RG().copyWith(color: _muted),
                ),
              ),
              const Expanded(child: Divider(color: _border, height: 1)),
            ],
          ),
          const SizedBox(height: 12),
          const SocialLoginRowWidget(),
        ],
      ),
    );
  }

  void _submit(BuildContext context) {
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
          onFirstTime: () =>
              NamedNavigatorImpl.push(CreateNewAccountScreen.routeName),
          mobile: _mobileEC.text.removeZero(),
          password: _passwordEC.text,
          whatsAppConsent: _whatsAppConsent,
          onSuccess: (register, mobileVerifiedAt) {
            NamedNavigatorImpl.push(BottomNavigationBarScreen.routeName);
          },
        );
  }
}
