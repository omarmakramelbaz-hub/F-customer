import 'package:faskhaninja/helpers/theme/fasakhansta_brand.dart';

import 'dart:io';

import 'package:country_picker/country_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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
import 'contract_vendor_screen.dart';

class RegisterAsVendorScreen extends StatefulWidget {
  static const String routeName = 'RegisterAsVendorScreen';

  const RegisterAsVendorScreen({super.key});

  @override
  State<RegisterAsVendorScreen> createState() => _RegisterAsVendorScreenState();
}

class _RegisterAsVendorScreenState extends State<RegisterAsVendorScreen>
    with ValidationMixin {
  final _formKey = GlobalKey<FormState>();

  final _merchantNameEc = TextEditingController();
  final _ownerNameEc = TextEditingController();
  final _branchesCountEc = TextEditingController();
  final _nationalIdEc = TextEditingController();
  final _taxIdEc = TextEditingController();
  final _commercialRegistrationEc = TextEditingController();
  final _phoneNumberOneEc = TextEditingController();
  final _phoneNumberTwoEc = TextEditingController();
  final _vodafoneCashNumber = TextEditingController();
  final _emailEc = TextEditingController();

  final _merchantNameFocus = FocusNode();
  final _ownerNameFocus = FocusNode();
  final _branchesCountFocus = FocusNode();
  final _nationalIdFocus = FocusNode();
  final _taxIdFocus = FocusNode();
  final _commercialRegistrationFocus = FocusNode();
  final _phoneNumberOneFocus = FocusNode();
  final _phoneNumberTwoFocus = FocusNode();
  final _vodafoneCashFocus = FocusNode();
  final _emailFocus = FocusNode();

  File? _idImage;
  File? _taxImage;
  File? _commercialRegistrationImage;
  Country? _country;

  @override
  void initState() {
    _country = CountryParser.parsePhoneCode('20');
    super.initState();
  }

  @override
  void dispose() {
    _merchantNameEc.dispose();
    _ownerNameEc.dispose();
    _branchesCountEc.dispose();
    _nationalIdEc.dispose();
    _taxIdEc.dispose();
    _commercialRegistrationEc.dispose();
    _phoneNumberOneEc.dispose();
    _phoneNumberTwoEc.dispose();
    _vodafoneCashNumber.dispose();
    _emailEc.dispose();

    _merchantNameFocus.dispose();
    _ownerNameFocus.dispose();
    _branchesCountFocus.dispose();
    _nationalIdFocus.dispose();
    _taxIdFocus.dispose();
    _commercialRegistrationFocus.dispose();
    _phoneNumberOneFocus.dispose();
    _phoneNumberTwoFocus.dispose();
    _vodafoneCashFocus.dispose();
    _emailFocus.dispose();
    super.dispose();
  }

  String _copy(BuildContext context, String ar, String en) {
    return context.languageCode == 'ar' ? ar : en;
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
            'startAsMerchant'.tr,
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
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 620),
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 34),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildIntroCard(context),
                    const SizedBox(height: 16),
                    _SectionCard(
                      icon: Icons.storefront_outlined,
                      title: _copy(
                        context,
                        'بيانات النشاط',
                        'Business details',
                      ),
                      subtitle: _copy(
                        context,
                        'اكتب بيانات النشاط والمالك كما هي في المستندات الرسمية',
                        'Enter the business and owner details exactly as shown in official documents.',
                      ),
                      child: Column(
                        children: [
                          CustomFormField(
                            controller: _merchantNameEc,
                            focusNode: _merchantNameFocus,
                            title: 'merchantName'.tr,
                            validator: validateName,
                            onFieldSubmitted: (_) {
                              FocusScope.of(context)
                                  .requestFocus(_ownerNameFocus);
                            },
                          ),
                          const SizedBox(height: 18),
                          CustomFormField(
                            controller: _ownerNameEc,
                            focusNode: _ownerNameFocus,
                            title: 'ownerName'.tr,
                            validator: validateName,
                            onFieldSubmitted: (_) {
                              FocusScope.of(context)
                                  .requestFocus(_branchesCountFocus);
                            },
                          ),
                          const SizedBox(height: 18),
                          CustomFormField(
                            controller: _branchesCountEc,
                            focusNode: _branchesCountFocus,
                            title: 'branchesCount'.tr,
                            validator: validateEmptyField,
                            keyboardType: TextInputType.number,
                            onFieldSubmitted: (_) {
                              FocusScope.of(context)
                                  .requestFocus(_nationalIdFocus);
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    _SectionCard(
                      icon: Icons.badge_outlined,
                      title: _copy(
                        context,
                        'المستندات الرسمية',
                        'Official documents',
                      ),
                      subtitle: _copy(
                        context,
                        'أدخل أرقام المستندات وارفع صور واضحة وكاملة للمراجعة',
                        'Enter document numbers and upload clear, complete images for review.',
                      ),
                      child: Column(
                        children: [
                          _InfoStrip(
                            text: _copy(
                              context,
                              'تأكد إن كل الأرقام والصور واضحة ومطابقة للمستندات الأصلية',
                              'Make sure all numbers and images are clear and match the original documents.',
                            ),
                          ),
                          const SizedBox(height: 18),
                          CustomFormField(
                            controller: _nationalIdEc,
                            focusNode: _nationalIdFocus,
                            title: 'nationalId'.tr,
                            validator: validateNationalId,
                            keyboardType: TextInputType.number,
                            onFieldSubmitted: (_) {
                              FocusScope.of(context).requestFocus(_taxIdFocus);
                            },
                          ),
                          const SizedBox(height: 18),
                          CustomFormField(
                            controller: _taxIdEc,
                            focusNode: _taxIdFocus,
                            title: 'taxNumber'.tr,
                            validator: validateEmptyField,
                            keyboardType: TextInputType.number,
                            onFieldSubmitted: (_) {
                              FocusScope.of(context)
                                  .requestFocus(_commercialRegistrationFocus);
                            },
                          ),
                          const SizedBox(height: 18),
                          CustomFormField(
                            controller: _commercialRegistrationEc,
                            focusNode: _commercialRegistrationFocus,
                            title: 'commercialRegistrationNumber'.tr,
                            validator: validateEmptyField,
                            keyboardType: TextInputType.number,
                            onFieldSubmitted: (_) {
                              FocusScope.of(context)
                                  .requestFocus(_phoneNumberOneFocus);
                            },
                          ),
                          const SizedBox(height: 22),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: _DocumentUpload(
                                  title: 'nationalIdImage'.tr,
                                  subtitle: _copy(
                                    context,
                                    'صورة واضحة للبطاقة',
                                    'Clear ID image',
                                  ),
                                  image: _idImage,
                                  onSuccess: (v) =>
                                      setState(() => _idImage = v),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _DocumentUpload(
                                  title: 'taxNumberImage'.tr,
                                  subtitle: _copy(
                                    context,
                                    'صورة البطاقة الضريبية',
                                    'Tax card image',
                                  ),
                                  image: _taxImage,
                                  onSuccess: (v) =>
                                      setState(() => _taxImage = v),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 22),
                          _DocumentUpload(
                            title: 'commercialRegistrationImage'.tr,
                            subtitle: _copy(
                              context,
                              'صورة واضحة للسجل التجاري',
                              'Clear commercial registration image',
                            ),
                            image: _commercialRegistrationImage,
                            onSuccess: (v) => setState(
                              () => _commercialRegistrationImage = v,
                            ),
                            maxWidth: 260,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    _SectionCard(
                      icon: Icons.phone_in_talk_outlined,
                      title: _copy(
                        context,
                        'بيانات التواصل والتحويل',
                        'Contact & payout details',
                      ),
                      subtitle: _copy(
                        context,
                        'هنستخدم البيانات دي للتواصل معاك وتحويل مستحقات النشاط',
                        'We will use these details to contact you and transfer business payouts.',
                      ),
                      child: Column(
                        children: [
                          CustomFormField(
                            validator: (v) =>
                                validatePhone(v, country: _country),
                            controller: _phoneNumberOneEc,
                            focusNode: _phoneNumberOneFocus,
                            title: 'firstPhoneNumber'.tr,
                            keyboardType: TextInputType.phone,
                            country: _country,
                            onFieldSubmitted: (_) {
                              FocusScope.of(context)
                                  .requestFocus(_phoneNumberTwoFocus);
                            },
                          ),
                          const SizedBox(height: 18),
                          CustomFormField(
                            controller: _phoneNumberTwoEc,
                            focusNode: _phoneNumberTwoFocus,
                            title:
                                '${'secondPhoneNumber'.tr} ${_copy(context, '(اختياري)', '(optional)')}',
                            keyboardType: TextInputType.phone,
                            country: _country,
                            onFieldSubmitted: (_) {
                              FocusScope.of(context)
                                  .requestFocus(_vodafoneCashFocus);
                            },
                          ),
                          const SizedBox(height: 18),
                          CustomFormField(
                            validator: (v) =>
                                validateVCash(v, country: _country),
                            controller: _vodafoneCashNumber,
                            focusNode: _vodafoneCashFocus,
                            title: 'vodafonCashNumber'.tr,
                            keyboardType: TextInputType.phone,
                            country: _country,
                            onFieldSubmitted: (_) {
                              FocusScope.of(context).requestFocus(_emailFocus);
                            },
                          ),
                          const SizedBox(height: 18),
                          CustomFormField(
                            validator: validateEmail,
                            controller: _emailEc,
                            focusNode: _emailFocus,
                            title: 'email'.tr,
                            keyboardType: TextInputType.emailAddress,
                            onFieldSubmitted: (_) {
                              FocusScope.of(context).unfocus();
                            },
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
                              _copy(
                                context,
                                'بياناتك ومستنداتك هتستخدم لمراجعة طلب الانضمام والتواصل معاك فقط.',
                                'Your details and documents will only be used to review your application and contact you.',
                              ),
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

                              if (_idImage == null ||
                                  _taxImage == null ||
                                  _commercialRegistrationImage == null) {
                                CommonMethods.showError(
                                  message: 'youMustAddAllImages'.tr,
                                );
                              }

                              if (_formKey.currentState!.validate() &&
                                  _idImage != null &&
                                  _taxImage != null &&
                                  _commercialRegistrationImage != null) {
                                NamedNavigatorImpl.push(
                                  ContractVendorScreen.routeName,
                                  arguments: ContractVendorArgs(
                                    vendorName: _merchantNameEc.text,
                                    vendorOwnerName: _ownerNameEc.text,
                                    vendorNational: _nationalIdEc.text,
                                    vendorCommercialRegistrationNo:
                                        _commercialRegistrationEc.text,
                                    vendorTaxNo: _taxIdEc.text,
                                    vendorMobile: _phoneNumberOneEc.text,
                                    vendorEmail: _emailEc.text,
                                    vendorVodafoneCash:
                                        _vodafoneCashNumber.text,
                                    onConfirm: () {
                                      providerContext
                                          .read<VendorAndDeliveryController>()
                                          .vendorRegister(
                                            fullName: _merchantNameEc.text,
                                            ownerName: _ownerNameEc.text,
                                            branchesNo: int.tryParse(
                                              _branchesCountEc.text,
                                            )!,
                                            nationalId: int.tryParse(
                                              _nationalIdEc.text,
                                            )!,
                                            commercialRegistrationNo:
                                                _commercialRegistrationEc.text,
                                            nationalIdImage: _idImage!,
                                            commercialRegistrationNoImage:
                                                _commercialRegistrationImage!,
                                            taxNo: _taxIdEc.text,
                                            taxNoImage: _taxImage!,
                                            estMobile: _phoneNumberOneEc.text,
                                            sndMobile: _phoneNumberTwoEc.text,
                                            vodafoneCashMobile:
                                                _vodafoneCashNumber.text,
                                            email: _emailEc.text,
                                            onSuccess: () {
                                              NamedNavigatorImpl.push(
                                                clean: true,
                                                BottomNavigationBarScreen
                                                    .routeName,
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
                    const SizedBox(height: 10),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIntroCard(BuildContext context) {
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
                      _copy(
                        context,
                        'ابدأ رحلتك معنا كتاجر',
                        'Start your journey as a merchant',
                      ),
                      style: AppTextStyle.text16BS().copyWith(
                        color: FasakhanstaBrand.text,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      _copy(
                        context,
                        'املأ بيانات النشاط وارفع المستندات، وبعدها راجع العقد وأرسل طلبك للمراجعة.',
                        'Complete your business details and documents, then review the contract and submit your application.',
                      ),
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
                _copy(context, 'الخطوة 1 من 2', 'Step 1 of 2'),
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

class _InfoStrip extends StatelessWidget {
  const _InfoStrip({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
      decoration: BoxDecoration(
        color: FasakhanstaBrand.surfaceRaised,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.mainAppColor.withValues(alpha: .13),
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
              text,
              style: AppTextStyle.text12RG().copyWith(
                color: FasakhanstaBrand.muted,
                height: 1.4,
              ),
            ),
          ),
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
    this.maxWidth,
  });

  final String title;
  final String subtitle;
  final File? image;
  final void Function(File) onSuccess;
  final double? maxWidth;

  @override
  Widget build(BuildContext context) {
    Widget content = Column(
      children: [
        Text(
          title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: AppTextStyle.text13MS().copyWith(
            color: FasakhanstaBrand.text,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          image == null
              ? subtitle
              : (context.languageCode == 'ar'
                  ? 'تم رفع الصورة'
                  : 'Image uploaded'),
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
          image == null
              ? (context.languageCode == 'ar' ? 'اضغط للرفع' : 'Tap to upload')
              : (context.languageCode == 'ar'
                  ? 'اضغط لتغيير الصورة'
                  : 'Tap to change image'),
          textAlign: TextAlign.center,
          style: AppTextStyle.text11RG().copyWith(
            color: AppColors.mainAppColor,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );

    if (maxWidth == null) return content;

    return Align(
      alignment: Alignment.center,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth!),
        child: content,
      ),
    );
  }
}
