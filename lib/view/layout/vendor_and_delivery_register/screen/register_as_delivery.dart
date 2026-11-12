import 'package:faskhaninja/helpers/theme/fasakhansta_brand.dart';

import 'dart:io';

import 'package:country_picker/country_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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
import '../../../custom_widgets/global_widgets/custom_image_container.dart';
import '../../../custom_widgets/validation/validation_mixin.dart';
import '../../bottom_navigation/bottom_navigation_bar_screen.dart';
import '../controller/vendor_and_delivery_controller.dart';
import 'contract_delivery_screen.dart';

class RegisterAsDeliveryScreen extends StatefulWidget {
  static const String routeName = 'RegisterAsDeliveryScreen';

  const RegisterAsDeliveryScreen({super.key});

  @override
  State<RegisterAsDeliveryScreen> createState() =>
      _RegisterAsDeliveryScreenState();
}

class _RegisterAsDeliveryScreenState extends State<RegisterAsDeliveryScreen>
    with ValidationMixin {
  final _formKey = GlobalKey<FormState>();

  final _nameQuadrilateralEc = TextEditingController();
  final _nationalIdEc = TextEditingController();
  final _drivingLicenseNumberEc = TextEditingController();
  final _workAreaEc = TextEditingController();
  final _phoneNumberOneEc = TextEditingController();
  final _phoneNumberTwoEc = TextEditingController();
  final _vodafoneCashNumber = TextEditingController();
  final _emailEc = TextEditingController();

  File? _nationalIdImage;
  File? _drivingLicenseImage;
  Country? _country;

  final _nameQuadrilateralFocusNode = FocusNode();
  final _nationalIdFocusNode = FocusNode();
  final _drivingLicenseFocusNode = FocusNode();
  final _workAreaFocusNode = FocusNode();
  final _phoneNumberOneFocusNode = FocusNode();
  final _phoneNumberTwoFocusNode = FocusNode();
  final _vodafoneCashFocusNode = FocusNode();
  final _emailFocusNode = FocusNode();

  @override
  void initState() {
    _country = CountryParser.parsePhoneCode('20');
    super.initState();
  }

  @override
  void dispose() {
    _nameQuadrilateralEc.dispose();
    _nationalIdEc.dispose();
    _drivingLicenseNumberEc.dispose();
    _workAreaEc.dispose();
    _phoneNumberOneEc.dispose();
    _phoneNumberTwoEc.dispose();
    _vodafoneCashNumber.dispose();
    _emailEc.dispose();

    _nameQuadrilateralFocusNode.dispose();
    _nationalIdFocusNode.dispose();
    _drivingLicenseFocusNode.dispose();
    _workAreaFocusNode.dispose();
    _phoneNumberOneFocusNode.dispose();
    _phoneNumberTwoFocusNode.dispose();
    _vodafoneCashFocusNode.dispose();
    _emailFocusNode.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      onPopInvoked: (_) {},
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: CustomAppBar(
          height: 66,
          centerTitle: true,
          appBarColor: Colors.transparent,
          elevation: .5,
          shadowColor: Colors.black12,
          title: Text(
            'startAsDeliveryMan'.tr,
            style: AppTextStyle.text20BS().copyWith(
              color: FasakhanstaBrand.text,
              fontWeight: FontWeight.w800,
            ),
          ),
          leading: Padding(
            padding: const EdgeInsets.all(9),
            child: Material(
              color: FasakhanstaBrand.surfaceRaised,
              borderRadius: BorderRadius.circular(15),
              child: InkWell(
                borderRadius: BorderRadius.circular(15),
                onTap: () => Navigator.pop(context),
                child: Icon(
                  context.languageCode == 'en'
                      ? Icons.arrow_back_ios_new_rounded
                      : Icons.arrow_forward_ios_rounded,
                  size: 19,
                  color: FasakhanstaBrand.text,
                ),
              ),
            ),
          ),
        ),
        body: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 34),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildIntroCard(),
                const SizedBox(height: 16),
                _SectionCard(
                  icon: Icons.person_outline_rounded,
                  title: 'البيانات الشخصية',
                  subtitle: 'اكتب بياناتك كما هي مسجلة في مستنداتك الرسمية',
                  child: Column(
                    children: [
                      CustomFormField(
                        controller: _nameQuadrilateralEc,
                        title: 'nameQuadrilateral'.tr,
                        validator: validateNameFourthly,
                        focusNode: _nameQuadrilateralFocusNode,
                        onFieldSubmitted: (_) {
                          FocusScope.of(context)
                              .requestFocus(_nationalIdFocusNode);
                        },
                      ),
                      const SizedBox(height: 18),
                      CustomFormField(
                        controller: _nationalIdEc,
                        title: 'nationalId'.tr,
                        validator: validateNationalId,
                        keyboardType: TextInputType.number,
                        focusNode: _nationalIdFocusNode,
                        onFieldSubmitted: (_) {
                          FocusScope.of(context)
                              .requestFocus(_drivingLicenseFocusNode);
                        },
                      ),
                      const SizedBox(height: 18),
                      CustomFormField(
                        controller: _drivingLicenseNumberEc,
                        title: 'drivingLicenseNumber'.tr,
                        validator: validateEmptyField,
                        keyboardType: TextInputType.number,
                        focusNode: _drivingLicenseFocusNode,
                        onFieldSubmitted: (_) {
                          FocusScope.of(context)
                              .requestFocus(_workAreaFocusNode);
                        },
                      ),
                      const SizedBox(height: 18),
                      CustomFormField(
                        controller: _workAreaEc,
                        title: 'workArea'.tr,
                        validator: validateEmptyField,
                        focusNode: _workAreaFocusNode,
                        onFieldSubmitted: (_) {
                          FocusScope.of(context)
                              .requestFocus(_phoneNumberOneFocusNode);
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _SectionCard(
                  icon: Icons.badge_outlined,
                  title: 'المستندات المطلوبة',
                  subtitle: 'ارفع صور واضحة وكاملة حتى نقدر نراجع طلبك بسرعة',
                  child: Column(
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 13,
                          vertical: 11,
                        ),
                        decoration: BoxDecoration(
                          color: FasakhanstaBrand.surfaceRaised,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: AppColors.mainAppColor.withValues(
                              alpha: .13,
                            ),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.info_outline_rounded,
                              size: 19,
                              color: AppColors.mainAppColor,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'تأكد إن البيانات والصور واضحة قبل المتابعة',
                                style: AppTextStyle.text12RG().copyWith(
                                  color: FasakhanstaBrand.muted,
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: _DocumentUpload(
                              title: 'nationalIdImage'.tr,
                              subtitle: 'صورة واضحة للبطاقة',
                              image: _nationalIdImage,
                              onSuccess: (v) =>
                                  setState(() => _nationalIdImage = v),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _DocumentUpload(
                              title: 'drivingLicense'.tr,
                              subtitle: 'صورة واضحة للرخصة',
                              image: _drivingLicenseImage,
                              onSuccess: (v) =>
                                  setState(() => _drivingLicenseImage = v),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _SectionCard(
                  icon: Icons.phone_in_talk_outlined,
                  title: 'بيانات التواصل والتحويل',
                  subtitle: 'هنستخدم البيانات دي للتواصل معاك وتحويل مستحقاتك',
                  child: Column(
                    children: [
                      CustomFormField(
                        validator: (v) => validatePhone(v, country: _country),
                        controller: _phoneNumberOneEc,
                        title: 'firstPhoneNumber'.tr,
                        keyboardType: TextInputType.phone,
                        country: _country,
                        focusNode: _phoneNumberOneFocusNode,
                        onFieldSubmitted: (_) {
                          FocusScope.of(context)
                              .requestFocus(_phoneNumberTwoFocusNode);
                        },
                      ),
                      const SizedBox(height: 18),
                      CustomFormField(
                        controller: _phoneNumberTwoEc,
                        title: '${'secondPhoneNumber'.tr} (اختياري)',
                        keyboardType: TextInputType.phone,
                        country: _country,
                        focusNode: _phoneNumberTwoFocusNode,
                        onFieldSubmitted: (_) {
                          FocusScope.of(context)
                              .requestFocus(_vodafoneCashFocusNode);
                        },
                      ),
                      const SizedBox(height: 18),
                      CustomFormField(
                        validator: (v) => validateVCash(v, country: _country),
                        controller: _vodafoneCashNumber,
                        title: 'vodafonCashNumber'.tr,
                        keyboardType: TextInputType.phone,
                        country: _country,
                        focusNode: _vodafoneCashFocusNode,
                        onFieldSubmitted: (_) {
                          FocusScope.of(context).requestFocus(_emailFocusNode);
                        },
                      ),
                      const SizedBox(height: 18),
                      CustomFormField(
                        validator: validateEmptyField,
                        controller: _emailEc,
                        title: 'email'.tr,
                        keyboardType: TextInputType.emailAddress,
                        focusNode: _emailFocusNode,
                        onFieldSubmitted: (_) {},
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: FasakhanstaBrand.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: FasakhanstaBrand.border),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.verified_user_outlined,
                        size: 20,
                        color: AppColors.mainAppColor,
                      ),
                      const SizedBox(width: 9),
                      Expanded(
                        child: Text(
                          'بياناتك هتستخدم لمراجعة طلب الانضمام والتواصل معاك فقط.',
                          style: AppTextStyle.text12RG().copyWith(
                            color: FasakhanstaBrand.muted,
                            height: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                ChangeNotifierProvider(
                  create: (_) => VendorAndDeliveryController(),
                  child: Builder(
                    builder: (providerContext) {
                      return CustomButton(
                        text: 'next'.tr,
                        onPressed: () {
                          FocusScope.of(context).unfocus();

                          if (_nationalIdImage == null ||
                              _drivingLicenseImage == null) {
                            CommonMethods.showError(
                              message: 'youMustAddAllImages'.tr,
                            );
                          }

                          if (_formKey.currentState!.validate() &&
                              _nationalIdImage != null &&
                              _drivingLicenseImage != null) {
                            NamedNavigatorImpl.push(
                              ContractDeliveryScreen.routeName,
                              arguments: ContractDeliveryArgs(
                                name: _nameQuadrilateralEc.text,
                                nationalId: _nationalIdEc.text,
                                drivingLicenseNo: _drivingLicenseNumberEc.text,
                                email: _emailEc.text,
                                mobile: _phoneNumberOneEc.text,
                                vodafoneCash: _vodafoneCashNumber.text,
                                onConfirm: () {
                                  providerContext
                                      .read<VendorAndDeliveryController>()
                                      .deliveryRegister(
                                        fullName: _nameQuadrilateralEc.text,
                                        drivingLicenseImage:
                                            _drivingLicenseImage!,
                                        nationalId: int.tryParse(
                                          _nationalIdEc.text,
                                        )!,
                                        drivingLicenseNo:
                                            _drivingLicenseNumberEc.text,
                                        nationalIdImage: _nationalIdImage!,
                                        workArea: _workAreaEc.text,
                                        estMobile: _phoneNumberOneEc.text,
                                        sndMobile: _phoneNumberTwoEc.text,
                                        vodafoneCashMobile:
                                            _vodafoneCashNumber.text,
                                        email: _emailEc.text,
                                        onSuccess: () {
                                          NamedNavigatorImpl.push(
                                            clean: true,
                                            BottomNavigationBarScreen.routeName,
                                          );
                                        },
                                      );
                                },
                              ),
                            );
                          }
                        },
                      );
                    },
                  ),
                ),
                10.sbH,
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIntroCard() {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [
            FasakhanstaBrand.surfaceRaised,
            FasakhanstaBrand.surfaceRaised,
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppColors.mainAppColor.withValues(alpha: .12),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 64,
                height: 64,
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: FasakhanstaBrand.surface,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x0F000000),
                      blurRadius: 16,
                      offset: Offset(0, 6),
                    ),
                  ],
                ),
                child: const CustomImage(
                  path: AppImages.appLogo,
                  type: ImageType.asset,
                  radius: 14,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ابدأ رحلتك معنا كمندوب توصيل',
                      style: AppTextStyle.text16BS().copyWith(
                        color: FasakhanstaBrand.text,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'املأ البيانات التالية، وبعدها راجع العقد وأرسل طلبك للمراجعة.',
                      style: AppTextStyle.text12RG().copyWith(
                        color: FasakhanstaBrand.muted,
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Text(
                'الخطوة 1 من 2',
                style: AppTextStyle.text12RG().copyWith(
                  color: AppColors.mainAppColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: LinearProgressIndicator(
                    value: .5,
                    minHeight: 7,
                    backgroundColor: FasakhanstaBrand.surface,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      AppColors.mainAppColor,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: FasakhanstaBrand.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: FasakhanstaBrand.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 18,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: FasakhanstaBrand.surfaceRaised,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, size: 22, color: AppColors.mainAppColor),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTextStyle.text16BS().copyWith(
                        color: FasakhanstaBrand.text,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: AppTextStyle.text12RG().copyWith(
                        color: FasakhanstaBrand.muted,
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }
}

class _DocumentUpload extends StatelessWidget {
  const _DocumentUpload({
    required this.title,
    required this.subtitle,
    required this.image,
    required this.onSuccess,
  });

  final String title;
  final String subtitle;
  final File? image;
  final void Function(File) onSuccess;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: AppTextStyle.text13MS().copyWith(
            color: FasakhanstaBrand.text,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          image == null ? subtitle : 'تم رفع الصورة',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: AppTextStyle.text11RG().copyWith(
            color: image == null
                ? FasakhanstaBrand.muted
                : FasakhanstaBrand.success,
            fontWeight: image == null ? FontWeight.w400 : FontWeight.w700,
          ),
        ),
        const SizedBox(height: 10),
        Stack(
          clipBehavior: Clip.none,
          children: [
            FittedBox(
              fit: BoxFit.scaleDown,
              child: CustomImageContainer(image: image, onSuccess: onSuccess),
            ),
            if (image != null)
              Positioned(
                top: 7,
                right: 7,
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: const BoxDecoration(
                    color: FasakhanstaBrand.successTint,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    color: FasakhanstaBrand.text,
                    size: 18,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 5),
        Text(
          image == null ? 'اضغط للرفع' : 'اضغط لتغيير الصورة',
          textAlign: TextAlign.center,
          style: AppTextStyle.text11RG().copyWith(
            color: AppColors.mainAppColor,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
