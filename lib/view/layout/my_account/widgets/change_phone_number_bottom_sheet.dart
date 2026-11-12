import 'package:faskhaninja/helpers/theme/fasakhansta_brand.dart';
import 'package:country_picker/country_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../../helpers/theme/app_colors.dart';
import '../../../../helpers/theme/app_text_style.dart';
import '../../../../helpers/translation/all_translation.dart';
import '../../../custom_widgets/buttons/custom_button.dart';
import '../../../custom_widgets/custom_form_field/custom_form_field.dart';
import '../../../custom_widgets/validation/validation_mixin.dart';
import '../../auth/controller/auth_controller.dart';
import '../controller/my_account_controller.dart';

class ChangePhoneNumberBottomSheet extends StatefulWidget {
  const ChangePhoneNumberBottomSheet({super.key});

  @override
  State<ChangePhoneNumberBottomSheet> createState() =>
      _ChangePhoneNumberBottomSheetState();
}

class _ChangePhoneNumberBottomSheetState
    extends State<ChangePhoneNumberBottomSheet>
    with ValidationMixin {
  final _formKey = GlobalKey<FormState>();
  final _phoneNumberEc = TextEditingController();
  final _passwordEC = TextEditingController();
  final _phoneFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();
  Country? _country;

  @override
  void initState() {
    super.initState();
    _country = CountryParser.parsePhoneCode('20');
    _phoneNumberEc.text = context.read<AuthController>().profile?.mobile ?? '';
  }

  @override
  void dispose() {
    _phoneNumberEc.dispose();
    _passwordEC.dispose();
    _phoneFocusNode.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final keyboardInset = MediaQuery.of(context).viewInsets.bottom;
    final currentPhone = context.read<AuthController>().profile?.mobile ?? '';

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
                    _PhoneHeader(
                      title: 'changePhoneNumber'.tr,
                      subtitle: isArabic
                          ? 'حدّث الرقم المرتبط بحسابك بسهولة وأمان'
                          : 'Update the phone number linked to your account securely',
                    ),
                    const SizedBox(height: 12),
                    if (currentPhone.isNotEmpty) ...[
                      _CurrentNumberCard(
                        phone: currentPhone,
                        isArabic: isArabic,
                      ),
                      const SizedBox(height: 14),
                    ],
                    CustomFormField(
                      validator: (value) =>
                          validatePhone(value, country: _country),
                      controller: _phoneNumberEc,
                      keyboardType: TextInputType.phone,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      country: _country,
                      title: isArabic
                          ? 'رقم الهاتف الجديد'
                          : 'New phone number',
                      hintText: isArabic
                          ? 'أدخل رقم الهاتف الجديد'
                          : 'Enter new phone number',
                      focusNode: _phoneFocusNode,
                      radius: 16,
                      fillColor: FasakhanstaBrand.field,
                      titleStyle: AppTextStyle.text13BS(),
                      prefixIcon: context.languageCode == 'en'
                          ? Icon(
                              Icons.phone_iphone_rounded,
                              size: 20,
                              color: AppColors.mainAppColor,
                            )
                          : null,
                      suffixIcon: context.languageCode == 'ar'
                          ? Icon(
                              Icons.phone_iphone_rounded,
                              size: 20,
                              color: AppColors.mainAppColor,
                            )
                          : null,
                      onFieldSubmitted: (_) {
                        FocusScope.of(context).requestFocus(_passwordFocusNode);
                      },
                    ),
                    const SizedBox(height: 14),
                    CustomFormField(
                      validator: validateEmptyField,
                      controller: _passwordEC,
                      title: isArabic
                          ? 'تأكيد كلمة المرور'
                          : 'Confirm password',
                      hintText: isArabic
                          ? 'أدخل كلمة المرور لتأكيد التغيير'
                          : 'Enter your password to confirm the change',
                      isPassword: true,
                      focusNode: _passwordFocusNode,
                      radius: 16,
                      fillColor: FasakhanstaBrand.field,
                      titleStyle: AppTextStyle.text13BS(),
                      prefixIcon: Icon(
                        Icons.lock_outline_rounded,
                        size: 20,
                        color: AppColors.mainAppColor,
                      ),
                      onFieldSubmitted: (_) => FocusScope.of(context).unfocus(),
                    ),
                    const SizedBox(height: 12),
                    _PrivacyNotice(
                      text: isArabic
                          ? 'نطلب كلمة المرور للتأكد من أن التغيير يتم بواسطة صاحب الحساب.'
                          : 'We ask for your password to verify that this change is made by the account owner.',
                    ),
                    const SizedBox(height: 18),
                    ChangeNotifierProvider(
                      create: (_) => MyAccountController(),
                      child: Consumer<MyAccountController>(
                        builder: (context, myAccountController, _) {
                          return CustomButton(
                            gradient: LinearGradient(
                              colors: [
                                AppColors.gridOneButtonColor,
                                AppColors.gridTwoButtonColor,
                              ],
                            ),
                            text: isArabic
                                ? 'تحديث رقم الهاتف'
                                : 'Update phone number',
                            onPressed: () {
                              FocusScope.of(context).unfocus();
                              if (_formKey.currentState!.validate()) {
                                myAccountController.changePhoneNumber(
                                  phoneNumber: _phoneNumberEc.text,
                                  password: _passwordEC.text,
                                  onSuccess: () {
                                    context.read<AuthController>().getProfile();
                                    Navigator.pop(context);
                                  },
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

class _PhoneHeader extends StatelessWidget {
  const _PhoneHeader({required this.title, required this.subtitle});

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
                    child: Icon(
                      Icons.phone_iphone_rounded,
                      size: 20,
                      color: AppColors.mainAppColor,
                    ),
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

class _CurrentNumberCard extends StatelessWidget {
  const _CurrentNumberCard({required this.phone, required this.isArabic});

  final String phone;
  final bool isArabic;

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
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: FasakhanstaBrand.surface,
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(
              Icons.phone_in_talk_outlined,
              size: 19,
              color: AppColors.mainAppColor,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isArabic ? 'الرقم الحالي' : 'Current number',
                  style: AppTextStyle.text10RG().copyWith(
                    color: FasakhanstaBrand.muted,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  phone,
                  textDirection: TextDirection.ltr,
                  style: AppTextStyle.text14BS(),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
            decoration: BoxDecoration(
              color: FasakhanstaBrand.surfaceRaised,
              borderRadius: BorderRadius.circular(9),
            ),
            child: Text(
              isArabic ? 'موثّق' : 'Verified',
              style: AppTextStyle.text10RG().copyWith(
                color: AppColors.mainAppColor,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PrivacyNotice extends StatelessWidget {
  const _PrivacyNotice({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: FasakhanstaBrand.surfaceRaised,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(Icons.shield_outlined, size: 18, color: AppColors.mainAppColor),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: AppTextStyle.text10RG().copyWith(
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
