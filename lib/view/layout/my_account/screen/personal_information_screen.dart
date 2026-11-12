import 'package:faskhaninja/helpers/theme/fasakhansta_brand.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

import '../../../../helpers/extensions/extensions.dart';
import '../../../../helpers/images/app_images.dart';
import '../../../../helpers/routes/app_routers_import.dart';
import '../../../../helpers/theme/app_colors.dart';
import '../../../../helpers/theme/app_text_style.dart';
import '../../../../helpers/translation/all_translation.dart';
import '../../../../helpers/utils/utils.dart';
import '../../../custom_widgets/api_response_widget/api_response_widget.dart';
import '../../../custom_widgets/custom_form_field/custom_form_field.dart';
import '../../../custom_widgets/custom_image/custom_network_image.dart';
import '../../../custom_widgets/custom_select/custom_select_item.dart';
import '../../../custom_widgets/custom_select/custom_single_select.dart';
import '../../../custom_widgets/validation/validation_mixin.dart';
import '../../auth/controller/auth_controller.dart';
import '../bottom_sheet/choose_avatar_bottom_sheet.dart';

class PersonalInformationScreen extends StatefulWidget {
  static const String routeName = 'PersonalInformationScreen';

  const PersonalInformationScreen({super.key});

  @override
  State<PersonalInformationScreen> createState() =>
      _PersonalInformationScreenState();
}

class _PersonalInformationScreenState extends State<PersonalInformationScreen>
    with ValidationMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameEc = TextEditingController();
  final _emailEc = TextEditingController();
  final _mobile = TextEditingController();

  int? _country;
  String? _gender;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  Future<void> _loadData() async {
    final auth = context.read<AuthController>();
    await auth.getProfile();
    await auth.getArea();

    if (!mounted) return;
    final profile = auth.profile;
    _nameEc.text = profile?.name ?? '';
    _emailEc.text = profile?.email ?? '';
    _mobile.text = profile?.mobile ?? '';
    setState(() {
      _country = profile?.areaId;
      _gender = profile?.gender;
      _initialized = true;
    });
  }

  @override
  void dispose() {
    _nameEc.dispose();
    _emailEc.dispose();
    _mobile.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthController>(
      builder: (context, authController, _) {
        final isArabic = context.languageCode == 'ar';

        return Scaffold(
          backgroundColor: Colors.transparent,
          body: SafeArea(
            child: Column(
              children: [
                _topBar(context, isArabic),
                Expanded(
                  child: ApiResponseWidget(
                    apiResponse: authController.profileResponse,
                    onReload: _loadData,
                    isEmpty: authController.profile == null && !_initialized,
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(16, 6, 16, 30),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _profileHeader(context, authController, isArabic),
                            const SizedBox(height: 16),
                            _infoNotice(isArabic),
                            const SizedBox(height: 18),
                            _sectionLabel(
                              isArabic
                                  ? 'البيانات الأساسية'
                                  : 'Basic information',
                              isArabic
                                  ? 'حدّث معلوماتك التي تظهر داخل حسابك'
                                  : 'Update the information shown in your account',
                            ),
                            const SizedBox(height: 9),
                            _formCard(context, authController, isArabic),
                            const SizedBox(height: 18),
                            _sectionLabel(
                              isArabic
                                  ? 'بيانات التواصل'
                                  : 'Contact information',
                              isArabic
                                  ? 'رقم الهاتف المرتبط بالحساب'
                                  : 'The phone number linked to your account',
                            ),
                            const SizedBox(height: 9),
                            _mobileCard(isArabic),
                            const SizedBox(height: 20),
                            _saveButton(context, authController, isArabic),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _topBar(BuildContext context, bool isArabic) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
      child: SizedBox(
        height: 48,
        child: Row(
          children: [
            InkWell(
              onTap: () => NamedNavigatorImpl.pop(),
              borderRadius: BorderRadius.circular(15),
              child: Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: FasakhanstaBrand.surface,
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: FasakhanstaBrand.border),
                ),
                child: Icon(
                  isArabic
                      ? Icons.arrow_forward_ios_rounded
                      : Icons.arrow_back_ios_new_rounded,
                  size: 18,
                  color: FasakhanstaBrand.text,
                ),
              ),
            ),
            const Spacer(),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('personalInformation'.tr, style: AppTextStyle.text19BS()),
                const SizedBox(height: 2),
                Container(
                  width: 26,
                  height: 3,
                  decoration: BoxDecoration(
                    color: AppColors.mainAppColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ],
            ),
            const Spacer(),
            const SizedBox(width: 42),
          ],
        ),
      ),
    );
  }

  Widget _profileHeader(
    BuildContext context,
    AuthController authController,
    bool isArabic,
  ) {
    final profile = authController.profile;
    final name = (profile?.name ?? '').toString();
    final area = (profile?.areaTitle ?? '').toString();
    final photo = (profile?.photoProfile ?? '').toString();

    return Container(
      height: 144,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(25),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            FasakhanstaBrand.surfaceRaised,
            FasakhanstaBrand.surfaceRaised,
          ],
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x16000000),
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(25),
        child: Stack(
          children: [
            Positioned(
              right: -35,
              top: -45,
              child: Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  color: AppColors.mainAppColor.withValues(alpha: .16),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(15),
              child: Row(
                children: [
                  InkWell(
                    onTap: () => Utils.showAppBottomSheet(
                      const ChooseAvatarBottomSheet(),
                    ),
                    borderRadius: BorderRadius.circular(45),
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          width: 84,
                          height: 84,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: FasakhanstaBrand.surfaceRaised,
                            border: Border.all(
                              color: FasakhanstaBrand.border,
                              width: 2.5,
                            ),
                          ),
                          child: ClipOval(
                            child: photo.isNotEmpty
                                ? CustomNetworkImage(
                                    imageUrl: photo,
                                    width: 84,
                                    height: 84,
                                    fit: BoxFit.cover,
                                    radius: 42,
                                  )
                                : _avatarFallback(authController),
                          ),
                        ),
                        Positioned(
                          right: -1,
                          bottom: 1,
                          child: Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: AppColors.mainAppColor,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: FasakhanstaBrand.border,
                                width: 2,
                              ),
                            ),
                            child: const Icon(
                              Icons.camera_alt_outlined,
                              size: 14,
                              color: FasakhanstaBrand.onOrange,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name.isEmpty ? 'account'.tr : name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyle.text20BS(
                            color: FasakhanstaBrand.text,
                          ),
                        ),
                        const SizedBox(height: 7),
                        if (area.isNotEmpty)
                          Row(
                            children: [
                              Icon(
                                Icons.location_on_outlined,
                                size: 16,
                                color: AppColors.mainAppColor,
                              ),
                              const SizedBox(width: 5),
                              Expanded(
                                child: Text(
                                  area,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTextStyle.text12RG(
                                    color: FasakhanstaBrand.text.withValues(
                                      alpha: .72,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: FasakhanstaBrand.surface.withValues(
                              alpha: .08,
                            ),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: FasakhanstaBrand.border.withValues(
                                alpha: .09,
                              ),
                            ),
                          ),
                          child: Text(
                            isArabic
                                ? 'اضغط على الصورة لتغييرها'
                                : 'Tap photo to change it',
                            style: AppTextStyle.text10RG(
                              color: FasakhanstaBrand.text.withValues(
                                alpha: .7,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _avatarFallback(AuthController authController) {
    final gender = _gender ?? authController.profile?.gender;
    if (gender == 'male') {
      return Padding(
        padding: const EdgeInsets.all(5),
        child: SvgPicture.asset(AppImages.avatarMale, fit: BoxFit.cover),
      );
    }
    if (gender == 'female') {
      return Padding(
        padding: const EdgeInsets.all(5),
        child: SvgPicture.asset(AppImages.avatarFemale, fit: BoxFit.cover),
      );
    }

    final name = (authController.profile?.name ?? '').toString().trim();
    final firstLetter = name.isEmpty ? '?' : name.substring(0, 1).toUpperCase();
    return Container(
      color: AppColors.mainAppColor,
      alignment: Alignment.center,
      child: Text(
        firstLetter,
        style: AppTextStyle.text24BS(color: FasakhanstaBrand.onOrange),
      ),
    );
  }

  Widget _infoNotice(bool isArabic) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
      decoration: BoxDecoration(
        color: FasakhanstaBrand.surfaceRaised,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: FasakhanstaBrand.border),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: FasakhanstaBrand.surfaceRaised,
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(
              Icons.verified_user_outlined,
              size: 19,
              color: AppColors.mainAppColor,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              isArabic
                  ? 'حافظ على بياناتك محدثة لضمان تجربة أفضل واستلام طلباتك بسهولة.'
                  : 'Keep your details up to date for a smoother account and delivery experience.',
              style: AppTextStyle.text11RG(color: FasakhanstaBrand.muted)
                  .copyWith(height: 1.35),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String title, String subtitle) {
    return Padding(
      padding: const EdgeInsetsDirectional.only(start: 3, end: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyle.text16BS()),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyle.text10RG(color: FasakhanstaBrand.muted),
                ),
              ],
            ),
          ),
          Container(
            width: 28,
            height: 3,
            decoration: BoxDecoration(
              color: AppColors.mainAppColor,
              borderRadius: BorderRadius.circular(20),
            ),
          ),
        ],
      ),
    );
  }

  Widget _formCard(
    BuildContext context,
    AuthController authController,
    bool isArabic,
  ) {
    return Container(
      padding: const EdgeInsets.fromLTRB(15, 16, 15, 15),
      decoration: BoxDecoration(
        color: FasakhanstaBrand.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: FasakhanstaBrand.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 14,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          _fieldHeader(Icons.person_outline_rounded, 'name'.tr),
          const SizedBox(height: 7),
          CustomFormField(controller: _nameEc, title: ''),
          const SizedBox(height: 15),
          const Divider(height: 1, color: FasakhanstaBrand.border),
          const SizedBox(height: 15),
          _fieldHeader(Icons.alternate_email_rounded, 'email'.tr),
          const SizedBox(height: 7),
          CustomFormField(controller: _emailEc, title: ''),
          const SizedBox(height: 15),
          const Divider(height: 1, color: FasakhanstaBrand.border),
          const SizedBox(height: 15),
          _fieldHeader(Icons.location_city_outlined, 'country'.tr),
          const SizedBox(height: 7),
          CustomSingleSelect(
            validator: validateEmptyDropDown,
            apiResponse: authController.areaResponse,
            onReload: authController.getArea,
            value: _country ??
                (authController.area.isNotEmpty
                    ? authController.area[0].id ?? 0
                    : 0),
            onChanged: (value) {
              setState(() => _country = value);
            },
            title: '',
            items: authController.area
                .map((e) => CustomSelectItem(value: e.id, name: e.title ?? ''))
                .toList(),
          ),
          const SizedBox(height: 3),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: Text(
              isArabic
                  ? 'اختر المنطقة الصحيحة لتحسين نتائج المطاعم والتوصيل.'
                  : 'Choose the correct area for better restaurant and delivery results.',
              style: AppTextStyle.text9RG(color: FasakhanstaBrand.muted),
            ),
          ),
        ],
      ),
    );
  }

  Widget _fieldHeader(IconData icon, String label) {
    return Row(
      children: [
        Container(
          width: 31,
          height: 31,
          decoration: BoxDecoration(
            color: FasakhanstaBrand.surfaceRaised,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 17, color: AppColors.mainAppColor),
        ),
        const SizedBox(width: 8),
        Text(label, style: AppTextStyle.text12BS()),
      ],
    );
  }

  Widget _mobileCard(bool isArabic) {
    return Container(
      height: 70,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: FasakhanstaBrand.surface,
        borderRadius: BorderRadius.circular(19),
        border: Border.all(color: FasakhanstaBrand.border),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: FasakhanstaBrand.surfaceRaised,
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(
              Icons.phone_iphone_rounded,
              color: AppColors.mainAppColor,
              size: 22,
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'mobile'.tr,
                  style: AppTextStyle.text10RG(color: FasakhanstaBrand.muted),
                ),
                const SizedBox(height: 3),
                Text(
                  _mobile.text,
                  textDirection: TextDirection.ltr,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyle.text14BS(),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
            decoration: BoxDecoration(
              color: FasakhanstaBrand.surfaceRaised,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              isArabic ? 'محمي' : 'Protected',
              style: AppTextStyle.text10RG(color: FasakhanstaBrand.muted),
            ),
          ),
        ],
      ),
    );
  }

  Widget _saveButton(
    BuildContext context,
    AuthController authController,
    bool isArabic,
  ) {
    return SizedBox(
      height: 54,
      child: ElevatedButton(
        onPressed: () {
          final valid = _formKey.currentState?.validate() ?? true;
          if (!valid) return;

          context.read<AuthController>().updateUserInfo(
                name: _nameEc.text.trim(),
                email: _emailEc.text.trim(),
                id: _country ?? 1,
                onSuccess: () {
                  authController.getProfile();
                  Navigator.pop(context);
                },
              );
        },
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: AppColors.mainAppColor,
          foregroundColor: FasakhanstaBrand.onOrange,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(17),
          ),
          shadowColor: Colors.transparent,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle_outline_rounded, size: 20),
            const SizedBox(width: 8),
            Text(
              'saveChanges'.tr,
              style: AppTextStyle.text15BS(color: FasakhanstaBrand.text),
            ),
            const SizedBox(width: 7),
            Text(
              isArabic ? 'بأمان' : 'securely',
              style: AppTextStyle.text10RG(
                color: FasakhanstaBrand.text.withValues(alpha: .8),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
