import 'package:faskhaninja/helpers/theme/fasakhansta_brand.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../helpers/theme/app_colors.dart';
import '../../../../helpers/theme/app_text_style.dart';
import '../../../../helpers/translation/all_translation.dart';
import '../../../custom_widgets/buttons/custom_button.dart';
import '../../../custom_widgets/custom_form_field/custom_form_field.dart';
import '../../../custom_widgets/validation/validation_mixin.dart';
import '../../auth/controller/auth_controller.dart';

class ChangePasswordBottomSheet extends StatefulWidget {
  const ChangePasswordBottomSheet({super.key});

  @override
  State<ChangePasswordBottomSheet> createState() =>
      _ChangePasswordBottomSheetState();
}

class _ChangePasswordBottomSheetState extends State<ChangePasswordBottomSheet>
    with ValidationMixin {
  final _formKey = GlobalKey<FormState>();

  final _currentPasswordEC = TextEditingController();
  final _newPasswordEC = TextEditingController();
  final _passwordConfirmationEC = TextEditingController();

  final _currentPasswordFocusNode = FocusNode();
  final _newPasswordFocusNode = FocusNode();
  final _passwordConfirmationFocusNode = FocusNode();

  @override
  void dispose() {
    _currentPasswordEC.dispose();
    _newPasswordEC.dispose();
    _passwordConfirmationEC.dispose();
    _currentPasswordFocusNode.dispose();
    _newPasswordFocusNode.dispose();
    _passwordConfirmationFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final keyboardInset = MediaQuery.of(context).viewInsets.bottom;

    return AnimatedPadding(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      padding: EdgeInsets.only(bottom: keyboardInset),
      child: SafeArea(
        top: false,
        child: Material(
          color: Colors.transparent,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(18, 8, 18, 16),
            decoration: const BoxDecoration(
              color: FasakhanstaBrand.surface,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(28),
                topRight: Radius.circular(28),
              ),
              boxShadow: [
                BoxShadow(
                  color: Color(0x2A000000),
                  blurRadius: 24,
                  offset: Offset(0, -7),
                ),
              ],
            ),
            child: SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        width: 42,
                        height: 4,
                        decoration: BoxDecoration(
                          color: FasakhanstaBrand.surfaceRaised,
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                    ),
                    const SizedBox(height: 9),
                    _Header(
                      icon: Icons.lock_reset_rounded,
                      title: 'changePassword'.tr,
                      subtitle: isArabic
                          ? 'أنشئ كلمة مرور قوية لحماية حسابك'
                          : 'Create a strong password to protect your account',
                    ),
                    const SizedBox(height: 12),
                    _SecurityHint(
                      text: isArabic
                          ? 'استخدم 6 أحرف أو أرقام على الأقل وتجنب كلمات المرور سهلة التخمين.'
                          : 'Use at least 6 characters or numbers and avoid easy-to-guess passwords.',
                    ),
                    const SizedBox(height: 16),
                    CustomFormField(
                      validator: validateEmptyField,
                      controller: _currentPasswordEC,
                      title: isArabic
                          ? 'كلمة المرور الحالية'
                          : 'Current password',
                      hintText: isArabic
                          ? 'أدخل كلمة المرور الحالية'
                          : 'Enter current password',
                      isPassword: true,
                      focusNode: _currentPasswordFocusNode,
                      radius: 16,
                      fillColor: FasakhanstaBrand.field,
                      titleStyle: AppTextStyle.text13BS(),
                      prefixIcon: Icon(
                        Icons.lock_outline_rounded,
                        size: 20,
                        color: AppColors.mainAppColor,
                      ),
                      onFieldSubmitted: (_) {
                        FocusScope.of(context)
                            .requestFocus(_newPasswordFocusNode);
                      },
                    ),
                    const SizedBox(height: 14),
                    CustomFormField(
                      validator: validatePassword,
                      controller: _newPasswordEC,
                      title: 'newPassword'.tr,
                      hintText: isArabic
                          ? 'أدخل كلمة المرور الجديدة'
                          : 'Enter new password',
                      isPassword: true,
                      focusNode: _newPasswordFocusNode,
                      radius: 16,
                      fillColor: FasakhanstaBrand.field,
                      titleStyle: AppTextStyle.text13BS(),
                      prefixIcon: Icon(
                        Icons.key_rounded,
                        size: 20,
                        color: AppColors.mainAppColor,
                      ),
                      onFieldSubmitted: (_) {
                        FocusScope.of(context)
                            .requestFocus(_passwordConfirmationFocusNode);
                      },
                    ),
                    const SizedBox(height: 14),
                    CustomFormField(
                      validator: (value) =>
                          validateConfirmPassword(value, _newPasswordEC.text),
                      controller: _passwordConfirmationEC,
                      title: 'confirmNewPassword'.tr,
                      hintText: isArabic
                          ? 'أعد كتابة كلمة المرور الجديدة'
                          : 'Re-enter new password',
                      isPassword: true,
                      focusNode: _passwordConfirmationFocusNode,
                      radius: 16,
                      fillColor: FasakhanstaBrand.field,
                      titleStyle: AppTextStyle.text13BS(),
                      prefixIcon: Icon(
                        Icons.verified_user_outlined,
                        size: 20,
                        color: AppColors.mainAppColor,
                      ),
                      onFieldSubmitted: (_) => FocusScope.of(context).unfocus(),
                    ),
                    const SizedBox(height: 18),
                    ChangeNotifierProvider(
                      create: (_) => AuthController(),
                      child: Consumer<AuthController>(
                        builder: (context, authController, _) {
                          return CustomButton(
                            gradient: LinearGradient(
                              colors: [
                                AppColors.gridOneButtonColor,
                                AppColors.gridTwoButtonColor,
                              ],
                            ),
                            text: isArabic
                                ? 'حفظ كلمة المرور'
                                : 'Save password',
                            onPressed: () {
                              FocusScope.of(context).unfocus();
                              if (_formKey.currentState!.validate()) {
                                authController.changePassword(
                                  currentPassword: _currentPasswordEC.text,
                                  newPassword: _newPasswordEC.text,
                                  confirmPassword: _passwordConfirmationEC.text,
                                  onSuccess: () => Navigator.pop(context),
                                );
                              }
                            },
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 4),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        InkWell(
          onTap: () => Navigator.pop(context),
          borderRadius: BorderRadius.circular(18),
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: FasakhanstaBrand.surfaceRaised,
              shape: BoxShape.circle,
              border: Border.all(color: FasakhanstaBrand.border),
            ),
            child: Icon(
              Icons.close_rounded,
              size: 21,
              color: AppColors.mainAppColor,
            ),
          ),
        ),
        const Spacer(),
        Expanded(
          flex: 5,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(title, style: AppTextStyle.text18BS()),
                  const SizedBox(width: 8),
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: FasakhanstaBrand.surfaceRaised,
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: Icon(icon, size: 20, color: AppColors.mainAppColor),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.end,
                style: AppTextStyle.text11RG().copyWith(
                  color: FasakhanstaBrand.muted,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SecurityHint extends StatelessWidget {
  const _SecurityHint({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: FasakhanstaBrand.surfaceRaised,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: FasakhanstaBrand.border),
      ),
      child: Row(
        children: [
          Icon(Icons.shield_outlined, size: 19, color: AppColors.mainAppColor),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              text,
              style: AppTextStyle.text11RG().copyWith(
                color: FasakhanstaBrand.muted,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
