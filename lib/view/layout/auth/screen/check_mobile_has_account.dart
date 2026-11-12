import 'package:faskhaninja/helpers/theme/fasakhansta_brand.dart';
import 'package:country_picker/country_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../helpers/extension/string_extension.dart';
import '../../../../helpers/extensions/extensions.dart';
import '../../../../helpers/images/app_images.dart';
import '../../../../helpers/routes/app_routers_import.dart';
import '../../../../helpers/theme/app_colors.dart';
import '../../../../helpers/theme/app_text_style.dart';
import '../../../../helpers/translation/all_translation.dart';
import '../../../../helpers/utils/common_methods.dart';
import '../../../custom_widgets/buttons/custom_button.dart';
import '../../../custom_widgets/custom_app_bar/custom_app_bar.dart';
import '../../../custom_widgets/custom_form_field/custom_form_field.dart';
import '../../../custom_widgets/custom_image/custom_image.dart';
import '../../../custom_widgets/validation/validation_mixin.dart';
import '../controller/auth_controller.dart';
import 'change_password_check_code.dart';

class CheckMobileHasAccount extends StatefulWidget {
  static const routeName = 'CheckMobileHasAccount';

  const CheckMobileHasAccount({super.key});

  @override
  State<CheckMobileHasAccount> createState() => _CheckMobileHasAccountState();
}

class _CheckMobileHasAccountState extends State<CheckMobileHasAccount>
    with ValidationMixin {
  final _formKey = GlobalKey<FormState>();
  final _mobileEC = TextEditingController();
  Country? _country;

  static const _text = FasakhanstaBrand.text;
  static const _muted = FasakhanstaBrand.muted;
  static const _border = FasakhanstaBrand.border;

  @override
  void initState() {
    _country = CountryParser.parsePhoneCode('20');
    super.initState();
  }

  @override
  void dispose() {
    _mobileEC.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: CustomAppBar(
          centerTitle: false,
          height: 70,
          title: const CustomImage(
            path: AppImages.appLogo,
            type: ImageType.asset,
            height: 52,
            radius: 12,
          ),
          appBarColor: Colors.transparent,
        ),
        body: SafeArea(
          top: false,
          child: SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 28),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildHeader(context),
                    const SizedBox(height: 14),
                    _buildFormCard(context),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(17),
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
              Icons.lock_reset_rounded,
              color: AppColors.mainAppColor,
              size: 28,
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'forgotPassword'.tr,
                  style: AppTextStyle.text20BS().copyWith(
                    color: _text,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  context.languageCode == 'ar'
                      ? 'اكتب رقم الموبايل المسجل على حسابك وسنساعدك في استعادة كلمة المرور.'
                      : 'Enter the mobile number linked to your account and we will help you reset your password.',
                  style: AppTextStyle.text12RG().copyWith(
                    color: _muted,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
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
            'mobileNumber'.tr,
            style: AppTextStyle.text16BS().copyWith(
              color: _text,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            context.languageCode == 'ar'
                ? 'هنراجع الرقم أولًا ثم نرسل كود الاستعادة على البريد المرتبط بالحساب.'
                : 'We will verify the number first, then send a recovery code to the email linked to your account.',
            style: AppTextStyle.text11RG().copyWith(color: _muted, height: 1.4),
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
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: FasakhanstaBrand.surfaceRaised,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _border),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.verified_user_outlined,
                  size: 19,
                  color: AppColors.mainAppColor,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    context.languageCode == 'ar'
                        ? 'لأمان حسابك، كود الاستعادة يتم إرساله فقط لبيانات الحساب المسجلة.'
                        : 'For your security, the recovery code is sent only to the contact details already registered on your account.',
                    style: AppTextStyle.text11RG().copyWith(
                      color: FasakhanstaBrand.muted,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          CustomButton(
            onPressed: _submit,
            radius: 18,
            text: 'send'.tr,
            style: AppTextStyle.text18BW(color: FasakhanstaBrand.onOrange),
          ),
        ],
      ),
    );
  }

  void _submit() {
    FocusManager.instance.primaryFocus?.unfocus();
    if (!_formKey.currentState!.validate()) return;

    final mobile = _mobileEC.text.removeZero();

    context.read<AuthController>().checkMobileHasAccount(
      mobile: mobile,
      countryCode: _country!.phoneCode,
      onSuccess: (email) {
        CommonMethods.showChooseDialog(
          context,
          message: 'weWillSendCodeToThisEmail'.translate(args: [email]),
          onPressed: () {
            context.read<AuthController>().forgetPassword(
              email: email,
              mobile: mobile,
              onSuccess: () {
                NamedNavigatorImpl.pop();
                NamedNavigatorImpl.push(
                  ChangePasswordCheckCodeScreen.routeName,
                  arguments: ChangePasswordCheckCodeArguments(
                    email: email,
                    mobile: mobile,
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}
