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
import '../../../../helpers/translation/all_translation.dart';
import '../../../custom_widgets/buttons/custom_button.dart';
import '../../../custom_widgets/custom_form_field/custom_form_field.dart';
import '../../../custom_widgets/validation/validation_mixin.dart';
import '../../bottom_navigation/bottom_navigation_bar_screen.dart';
import '../controller/auth_controller.dart';

class SocialAuthPhoneScreen extends StatefulWidget {
  static const routeName = 'SocialAuthPhoneScreen';

  final Map<String, dynamic> socialAuthData;

  const SocialAuthPhoneScreen({super.key, required this.socialAuthData});

  @override
  State<SocialAuthPhoneScreen> createState() => _SocialAuthPhoneScreenState();
}

class _SocialAuthPhoneScreenState extends State<SocialAuthPhoneScreen>
    with ValidationMixin {
  final _formKey = GlobalKey<FormState>();
  final _mobileEC = TextEditingController();
  Country? _country;

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

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    context.read<AuthController>().completeSocialAuth(
      socialAuthData: widget.socialAuthData,
      mobile: _mobileEC.text.removeZero(),
      countryCode: _country?.phoneCode ?? '20',
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
      onHaveIdANDToken: (id, token) {
        context.read<PusherController>().initPusher(
          channelName: 'private-user.$id',
          userId: id,
          token: token,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isRtl = context.isRtl;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 28),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: Column(
                  children: [
                    SizedBox(
                      height: 58,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Positioned(
                            left: 0,
                            child: _RoundActionButton(
                              icon: isRtl
                                  ? Icons.arrow_forward_rounded
                                  : Icons.arrow_back_rounded,
                              onTap: () => Navigator.of(context).maybePop(),
                            ),
                          ),
                          Positioned(
                            right: 0,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.asset(
                                AppImages.appLogo,
                                width: 54,
                                height: 54,
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(17),
                      decoration: BoxDecoration(
                        color: FasakhanstaBrand.surfaceRaised,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: FasakhanstaBrand.border),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x0D000000),
                            blurRadius: 18,
                            offset: Offset(0, 7),
                          ),
                        ],
                      ),
                      child: Directionality(
                        textDirection: isRtl
                            ? TextDirection.rtl
                            : TextDirection.ltr,
                        child: Row(
                          children: [
                            Container(
                              width: 56,
                              height: 56,
                              decoration: BoxDecoration(
                                color: FasakhanstaBrand.surface,
                                borderRadius: BorderRadius.circular(17),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Color(0x0A000000),
                                    blurRadius: 10,
                                    offset: Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Icon(
                                Icons.person_add_alt_1_rounded,
                                color: AppColors.mainAppColor,
                                size: 28,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    isRtl ? 'خطوة أخيرة لإكمال حسابك' : 'One last step to complete your account',
                                    style: const TextStyle(
                                      color: FasakhanstaBrand.text,
                                      fontSize: 19,
                                      fontWeight: FontWeight.w800,
                                      height: 1.25,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    isRtl
                                        ? 'أضف رقم الجوال لنكمل إعداد حسابك ونحافظ على أمان بياناتك.'
                                        : 'Add your mobile number to finish setting up your account securely.',
                                    style: const TextStyle(
                                      color: FasakhanstaBrand.muted,
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w500,
                                      height: 1.45,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(17, 19, 17, 18),
                      decoration: BoxDecoration(
                        color: FasakhanstaBrand.surface,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: FasakhanstaBrand.border),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x0B000000),
                            blurRadius: 20,
                            offset: Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Directionality(
                            textDirection: isRtl
                                ? TextDirection.rtl
                                : TextDirection.ltr,
                            child: Row(
                              children: [
                                Container(
                                  width: 38,
                                  height: 38,
                                  decoration: BoxDecoration(
                                    color: FasakhanstaBrand.surfaceRaised,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    Icons.phone_iphone_rounded,
                                    color: AppColors.mainAppColor,
                                    size: 21,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'mobileNumber'.tr,
                                        style: const TextStyle(
                                          color: FasakhanstaBrand.text,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        isRtl
                                            ? 'اكتب رقمك الأساسي للتواصل وتأكيد الحساب'
                                            : 'Enter your main number for contact and account verification',
                                        style: const TextStyle(
                                          color: FasakhanstaBrand.muted,
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                          CustomFormField(
                            validator: (v) =>
                                validatePhone(v, country: _country),
                            controller: _mobileEC,
                            keyboardType: TextInputType.phone,
                            hintText: isRtl
                                ? 'مثال: 01012345678'
                                : 'Example: 01012345678',
                            country: _country,
                            radius: 17,
                            fillColor: FasakhanstaBrand.field,
                            unFocusColor: FasakhanstaBrand.border,
                            focusColor: AppColors.mainAppColor,
                            textDirection: TextDirection.ltr,
                            textStyle: const TextStyle(
                              color: FasakhanstaBrand.text,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                            hintStyle: const TextStyle(
                              color: FasakhanstaBrand.muted,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: FasakhanstaBrand.surfaceRaised,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: FasakhanstaBrand.border,
                              ),
                            ),
                            child: Directionality(
                              textDirection: isRtl
                                  ? TextDirection.rtl
                                  : TextDirection.ltr,
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.shield_outlined,
                                    color: FasakhanstaBrand.muted,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      isRtl
                                          ? 'رقمك يُستخدم لتأكيد الحساب والتواصل بخصوص الطلبات فقط.'
                                          : 'Your number is used only for account verification and order communication.',
                                      style: const TextStyle(
                                        color: FasakhanstaBrand.muted,
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w500,
                                        height: 1.4,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 22),
                          CustomButton(
                            onPressed: _submit,
                            height: 54,
                            radius: 18,
                            hasShadow: true,
                            text: 'continue'.tr,
                            style: const TextStyle(
                              color: FasakhanstaBrand.onOrange,
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                            suffixIcon: Container(
                              width: 30,
                              height: 30,
                              decoration: BoxDecoration(
                                color: FasakhanstaBrand.surface.withValues(
                                  alpha: 0.18,
                                ),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                isRtl
                                    ? Icons.arrow_back_rounded
                                    : Icons.arrow_forward_rounded,
                                color: FasakhanstaBrand.text,
                                size: 19,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
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

class _RoundActionButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _RoundActionButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: FasakhanstaBrand.surface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: FasakhanstaBrand.border),
          ),
          child: Icon(icon, color: AppColors.mainAppColor, size: 21),
        ),
      ),
    );
  }
}
