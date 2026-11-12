import 'package:faskhaninja/helpers/theme/fasakhansta_brand.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../helpers/extensions/extensions.dart';
import '../../../../helpers/images/app_images.dart';
import '../../../../helpers/routes/app_routers_import.dart';
import '../../../../helpers/theme/app_colors.dart';
import '../../../../helpers/theme/app_text_style.dart';
import '../../../../helpers/translation/all_translation.dart';
import '../../../custom_widgets/buttons/custom_button.dart';
import '../../../custom_widgets/custom_app_bar/custom_app_bar.dart';
import '../../../custom_widgets/custom_form_field/custom_form_field.dart';
import '../../../custom_widgets/custom_image/custom_image.dart';
import '../../../custom_widgets/validation/validation_mixin.dart';
import '../controller/auth_controller.dart';
import 'login_screen.dart';

class ResetPasswordScreenArgs {
  final String mobile;
  final String email;

  ResetPasswordScreenArgs({required this.email, required this.mobile});
}

class ResetPasswordScreen extends StatefulWidget {
  static const routeName = 'ResetPasswordScreen';
  final ResetPasswordScreenArgs args;

  const ResetPasswordScreen({super.key, required this.args});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen>
    with ValidationMixin {
  final _formKey = GlobalKey<FormState>();
  final _passwordEC = TextEditingController();
  final _confirmPasswordEC = TextEditingController();

  static const _text = FasakhanstaBrand.text;
  static const _muted = FasakhanstaBrand.muted;
  static const _border = FasakhanstaBrand.border;

  @override
  void dispose() {
    _confirmPasswordEC.dispose();
    _passwordEC.dispose();
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
                    _buildPasswordCard(context),
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
            ),
            child: Icon(
              Icons.password_rounded,
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
                  'changePassword'.tr,
                  style: AppTextStyle.text20BS().copyWith(
                    color: _text,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  context.languageCode == 'ar'
                      ? 'اختار كلمة مرور جديدة وقوية لحماية حسابك.'
                      : 'Choose a new strong password to keep your account secure.',
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

  Widget _buildPasswordCard(BuildContext context) {
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
            context.languageCode == 'ar'
                ? 'كلمة المرور الجديدة'
                : 'New password',
            style: AppTextStyle.text16BS().copyWith(
              color: _text,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            context.languageCode == 'ar'
                ? 'اكتب كلمة المرور مرتين للتأكد من عدم وجود خطأ.'
                : 'Enter the password twice to make sure there are no typing mistakes.',
            style: AppTextStyle.text11RG().copyWith(color: _muted, height: 1.4),
          ),
          const SizedBox(height: 18),
          CustomFormField(
            validator: validatePassword,
            controller: _passwordEC,
            title: 'password'.tr,
            isPassword: true,
          ),
          const SizedBox(height: 14),
          CustomFormField(
            validator: (value) =>
                validateConfirmPassword(value, _passwordEC.text),
            controller: _confirmPasswordEC,
            title: 'confirmNewPassword'.tr,
            isPassword: true,
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
                  Icons.shield_outlined,
                  size: 19,
                  color: AppColors.mainAppColor,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    context.languageCode == 'ar'
                        ? 'استخدم كلمة مرور يصعب تخمينها ولا تشاركها مع أي شخص.'
                        : 'Use a password that is hard to guess and never share it with anyone.',
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
            text: 'changePassword'.tr,
          ),
        ],
      ),
    );
  }

  void _submit() {
    FocusManager.instance.primaryFocus?.unfocus();
    if (!_formKey.currentState!.validate()) return;

    context.read<AuthController>().resetPassword(
          mobile: widget.args.mobile,
          email: widget.args.email,
          newPassword: _passwordEC.text,
          confirmNewPassword: _confirmPasswordEC.text,
          onSuccess: () {
            NamedNavigatorImpl.push(LoginScreen.routeName, clean: true);
          },
        );
  }
}
