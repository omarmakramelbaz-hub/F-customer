import 'package:faskhaninja/helpers/theme/fasakhansta_brand.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../helpers/extensions/extensions.dart';
import '../../../../helpers/hive/hive_methods.dart';
import '../../../../helpers/routes/app_routers_import.dart';
import '../../../../helpers/theme/app_colors.dart';
import '../../../../helpers/theme/app_text_style.dart';
import '../../../../helpers/translation/all_translation.dart';
import '../../../../helpers/utils/common_methods.dart';
import '../../../../helpers/utils/utils.dart';
import '../../../custom_widgets/custom_image/custom_network_image.dart';
import '../../address/screen/address_screen.dart';
import '../../auth/bottom_sheet/change_lang_bottom_sheet.dart';
import '../../auth/controller/auth_controller.dart';
import '../../auth/screen/login_screen.dart';
import '../../bottom_navigation/controller/bottom_navigation_controller.dart';
import '../../favorite/screen/favorite_screen.dart';
import '../../vendor_and_delivery_register/screen/register_as_delivery.dart';
import '../../vendor_and_delivery_register/screen/register_as_vendor.dart';
import '../../vendor_and_delivery_register/screen/widgets/delete_account_btn.dart';
import '../../wallet/screen/wallet_screen.dart';
import '../bottom_sheet/change_password_bottom_sheet.dart';
import '../widgets/change_phone_number_bottom_sheet.dart';
import 'contact_us_screen.dart';
import 'personal_information_screen.dart';
import 'privacy_policy_screen.dart';
import 'terms_and_conditions_screen.dart';

class MyAccountScreen extends StatelessWidget {
  const MyAccountScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    final profile = auth.profile;
    final loggedIn = HiveMethods.getToken() != null;
    final isArabic = context.languageCode == 'ar';

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _header(context),
              const SizedBox(height: 16),
              if (loggedIn) ...[
                _profileHero(context, profile),
                const SizedBox(height: 14),
                _quickActions(context, profile),
                const SizedBox(height: 22),
                _sectionTitle(
                  isArabic ? 'الحساب والأمان' : 'Account & security',
                  isArabic
                      ? 'إدارة بيانات حسابك وحمايته'
                      : 'Manage and protect your account',
                ),
                const SizedBox(height: 9),
                _menuCard(context, [
                  _MenuItem(
                    Icons.person_outline_rounded,
                    'personalInformation'.tr,
                    isArabic
                        ? 'الاسم والبريد والمنطقة'
                        : 'Name, email and area',
                    () => NamedNavigatorImpl.push(
                      PersonalInformationScreen.routeName,
                    ),
                  ),
                  _MenuItem(
                    Icons.phone_iphone_rounded,
                    'changePhoneNumber'.tr,
                    isArabic
                        ? 'تحديث رقم الهاتف المرتبط بالحساب'
                        : 'Update your account phone number',
                    () => Utils.showAppBottomSheet(
                      enableDrag: true,
                      isScrollControlled: true,
                      const ChangePhoneNumberBottomSheet(),
                    ),
                  ),
                  _MenuItem(
                    Icons.lock_outline_rounded,
                    'changePassword'.tr,
                    isArabic
                        ? 'تغيير كلمة المرور بأمان'
                        : 'Change your password securely',
                    () => Utils.showAppBottomSheet(
                      isScrollControlled: true,
                      const ChangePasswordBottomSheet(),
                    ),
                  ),
                ]),
                const SizedBox(height: 22),
                _sectionTitle(
                  isArabic ? 'الإعدادات والدعم' : 'Settings & support',
                  isArabic
                      ? 'كل ما تحتاجه لإدارة تجربتك'
                      : 'Everything you need to manage your experience',
                ),
                const SizedBox(height: 9),
                _menuCard(context, [
                  _MenuItem(
                    Icons.language_rounded,
                    'changeTheLanguage'.tr,
                    isArabic
                        ? 'تغيير لغة واجهة التطبيق'
                        : 'Change app language',
                    () =>
                        Utils.showAppBottomSheet(const ChangeLangBottomSheet()),
                  ),
                  _MenuItem(
                    Icons.headset_mic_outlined,
                    'contactUs'.tr,
                    isArabic
                        ? 'تواصل مع فريق الدعم'
                        : 'Contact our support team',
                    () => NamedNavigatorImpl.push(ContactUsScreen.routeName),
                  ),
                  _MenuItem(
                    Icons.verified_user_outlined,
                    'privacyPolicy'.tr,
                    isArabic
                        ? 'تعرف على كيفية حماية بياناتك'
                        : 'Learn how your data is protected',
                    () =>
                        NamedNavigatorImpl.push(PrivacyPolicyScreen.routeName),
                  ),
                  _MenuItem(
                    Icons.description_outlined,
                    'termsAndConditions'.tr,
                    isArabic
                        ? 'الشروط المنظمة لاستخدام الخدمة'
                        : 'Terms for using the service',
                    () => NamedNavigatorImpl.push(
                      TermsAndConditionsScreen.routeName,
                    ),
                  ),
                ]),
                const SizedBox(height: 18),
                _logoutButton(context),
                const SizedBox(height: 10),
                const DeleteAccountBtn(),
                const SizedBox(height: 22),
                _partnerCard(context),
              ] else ...[
                _guestLoginCard(context),
                const SizedBox(height: 18),
                _sectionTitle(
                  isArabic ? 'الإعدادات والدعم' : 'Settings & support',
                  isArabic
                      ? 'يمكنك الوصول إليها بدون تسجيل دخول'
                      : 'Available without signing in',
                ),
                const SizedBox(height: 9),
                _menuCard(context, [
                  _MenuItem(
                    Icons.language_rounded,
                    'changeTheLanguage'.tr,
                    isArabic
                        ? 'تغيير لغة واجهة التطبيق'
                        : 'Change app language',
                    () =>
                        Utils.showAppBottomSheet(const ChangeLangBottomSheet()),
                  ),
                  _MenuItem(
                    Icons.headset_mic_outlined,
                    'contactUs'.tr,
                    isArabic
                        ? 'تواصل مع فريق الدعم'
                        : 'Contact our support team',
                    () => NamedNavigatorImpl.push(ContactUsScreen.routeName),
                  ),
                  _MenuItem(
                    Icons.verified_user_outlined,
                    'privacyPolicy'.tr,
                    isArabic
                        ? 'تعرف على كيفية حماية بياناتك'
                        : 'Learn how your data is protected',
                    () =>
                        NamedNavigatorImpl.push(PrivacyPolicyScreen.routeName),
                  ),
                  _MenuItem(
                    Icons.description_outlined,
                    'termsAndConditions'.tr,
                    isArabic
                        ? 'الشروط المنظمة لاستخدام الخدمة'
                        : 'Terms for using the service',
                    () => NamedNavigatorImpl.push(
                      TermsAndConditionsScreen.routeName,
                    ),
                  ),
                ]),
                const SizedBox(height: 18),
                _guestPartnerCard(context),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _header(BuildContext context) {
    return SizedBox(
      height: 50,
      child: Row(
        children: [
          _roundIcon(
            Icons.settings_outlined,
            () => Utils.showAppBottomSheet(const ChangeLangBottomSheet()),
          ),
          const Spacer(),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('account'.tr, style: AppTextStyle.text22BS()),
              const SizedBox(height: 2),
              Container(
                width: 24,
                height: 3,
                decoration: BoxDecoration(
                  color: AppColors.mainAppColor,
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ],
          ),
          const Spacer(),
          _roundIcon(
            Icons.notifications_none_rounded,
            () => context.read<BottomNavigationController>().updateIndex(2),
            badge: context.read<AuthController>().profile?.notificaionsCount,
          ),
        ],
      ),
    );
  }

  Widget _roundIcon(IconData icon, VoidCallback onTap, {int? badge}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: FasakhanstaBrand.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: FasakhanstaBrand.border),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x08000000),
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Icon(icon, color: AppColors.mainAppColor, size: 23),
          ),
          if (badge != null && badge > 0)
            Positioned(
              right: -4,
              top: -4,
              child: Container(
                constraints: const BoxConstraints(minWidth: 19, minHeight: 19),
                padding: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  color: FasakhanstaBrand.orange,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: FasakhanstaBrand.border,
                    width: 1.5,
                  ),
                ),
                child: Center(
                  child: Text(
                    '$badge',
                    style: const TextStyle(
                      color: FasakhanstaBrand.onOrange,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _profileHero(BuildContext context, dynamic profile) {
    final isArabic = context.languageCode == 'ar';
    final name = (profile?.name ?? '').toString();
    final mobile = (profile?.mobile ?? '').toString();
    final photo = (profile?.photoProfile ?? '').toString();
    final area = (profile?.areaTitle ?? profile?.cityName ?? '').toString();

    return InkWell(
      onTap: () => NamedNavigatorImpl.push(PersonalInformationScreen.routeName),
      borderRadius: BorderRadius.circular(26),
      child: Container(
        height: 148,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(26),
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
              color: Color(0x1A000000),
              blurRadius: 22,
              offset: Offset(0, 9),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(26),
          child: Stack(
            children: [
              Positioned(
                right: -42,
                top: -50,
                child: Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    color: AppColors.mainAppColor.withValues(alpha: .16),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              Positioned(
                left: -34,
                bottom: -62,
                child: Container(
                  width: 130,
                  height: 130,
                  decoration: BoxDecoration(
                    color: FasakhanstaBrand.surface.withValues(alpha: .035),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          width: 82,
                          height: 82,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: FasakhanstaBrand.border,
                              width: 2.4,
                            ),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x33000000),
                                blurRadius: 12,
                                offset: Offset(0, 5),
                              ),
                            ],
                          ),
                          child: ClipOval(
                            child: photo.isNotEmpty
                                ? CustomNetworkImage(
                                    imageUrl: photo,
                                    width: 82,
                                    height: 82,
                                    fit: BoxFit.cover,
                                    radius: 41,
                                  )
                                : Container(
                                    color: FasakhanstaBrand.surfaceRaised,
                                    child: Icon(
                                      Icons.person_rounded,
                                      size: 48,
                                      color: AppColors.mainAppColor,
                                    ),
                                  ),
                          ),
                        ),
                        Positioned(
                          right: -2,
                          bottom: 1,
                          child: Container(
                            width: 27,
                            height: 27,
                            decoration: BoxDecoration(
                              color: AppColors.mainAppColor,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: FasakhanstaBrand.border,
                                width: 2,
                              ),
                            ),
                            child: const Icon(
                              Icons.edit_rounded,
                              size: 14,
                              color: FasakhanstaBrand.onOrange,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  name.isEmpty ? 'account'.tr : name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTextStyle.text20BS(
                                    color: FasakhanstaBrand.text,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 9,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.mainAppColor.withValues(
                                    alpha: .17,
                                  ),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: AppColors.mainAppColor.withValues(
                                      alpha: .45,
                                    ),
                                  ),
                                ),
                                child: Text(
                                  isArabic ? 'حسابك' : 'Your account',
                                  style: AppTextStyle.text10BW(
                                    color: FasakhanstaBrand.onOrange,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (mobile.isNotEmpty) ...[
                            const SizedBox(height: 7),
                            Row(
                              children: [
                                Icon(
                                  Icons.phone_iphone_rounded,
                                  size: 15,
                                  color: FasakhanstaBrand.text.withValues(
                                    alpha: .72,
                                  ),
                                ),
                                const SizedBox(width: 5),
                                Flexible(
                                  child: Text(
                                    mobile,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTextStyle.text12RG(
                                      color: FasakhanstaBrand.text.withValues(
                                        alpha: .78,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                          if (area.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Icon(
                                  Icons.location_on_outlined,
                                  size: 15,
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
                          ],
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Text(
                                isArabic
                                    ? 'تعديل الملف الشخصي'
                                    : 'Edit profile',
                                style: AppTextStyle.text11BM(),
                              ),
                              const SizedBox(width: 4),
                              Icon(
                                context.languageCode == 'en'
                                    ? Icons.arrow_forward_rounded
                                    : Icons.arrow_back_rounded,
                                size: 15,
                                color: AppColors.mainAppColor,
                              ),
                            ],
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
      ),
    );
  }

  Widget _quickActions(BuildContext context, dynamic profile) {
    final isArabic = context.languageCode == 'ar';
    final addressCount = profile?.userAddresses?.length ?? 0;
    final balance = profile?.balance ?? 0;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _quickTile(
                context,
                icon: Icons.shopping_bag_outlined,
                title: 'orders'.tr,
                subtitle: isArabic ? 'تابع طلباتك' : 'Track orders',
                onTap: () => _goToOrders(context),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _quickTile(
                context,
                icon: Icons.account_balance_wallet_outlined,
                title: 'theWallet'.tr,
                subtitle: '$balance ${isArabic ? 'ج' : 'EGP'}',
                onTap: () => NamedNavigatorImpl.push(WalletScreen.routeName),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _quickTile(
                context,
                icon: Icons.location_on_outlined,
                title: 'addresses'.tr,
                subtitle:
                    isArabic ? '$addressCount عنوان' : '$addressCount saved',
                onTap: () => NamedNavigatorImpl.push(AddressScreen.routeName),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _quickTile(
                context,
                icon: Icons.favorite_border_rounded,
                title: 'favorite'.tr,
                subtitle: isArabic ? 'اختياراتك المفضلة' : 'Your favorites',
                onTap: () => NamedNavigatorImpl.push(FavoriteScreen.routeName),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _quickTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(19),
      child: Container(
        height: 76,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: FasakhanstaBrand.surface,
          borderRadius: BorderRadius.circular(19),
          border: Border.all(color: FasakhanstaBrand.border),
          boxShadow: const [
            BoxShadow(
              color: Color(0x07000000),
              blurRadius: 12,
              offset: Offset(0, 5),
            ),
          ],
        ),
        child: Row(
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
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyle.text13BS(),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyle.text10RG(color: FasakhanstaBrand.muted),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String title, String subtitle) {
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

  Widget _menuCard(BuildContext context, List<_MenuItem> items) {
    return Container(
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
        children: List.generate(items.length, (index) {
          final item = items[index];
          return Column(
            children: [
              InkWell(
                onTap: item.onTap,
                borderRadius: BorderRadius.vertical(
                  top: index == 0 ? const Radius.circular(22) : Radius.zero,
                  bottom: index == items.length - 1
                      ? const Radius.circular(22)
                      : Radius.zero,
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 13,
                    vertical: 11,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: FasakhanstaBrand.surfaceRaised,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(
                          item.icon,
                          color: AppColors.mainAppColor,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 11),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(item.title, style: AppTextStyle.text14BS()),
                            const SizedBox(height: 2),
                            Text(
                              item.subtitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyle.text10RG(
                                color: FasakhanstaBrand.muted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          color: FasakhanstaBrand.surfaceRaised,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          context.languageCode == 'en'
                              ? Icons.chevron_right_rounded
                              : Icons.chevron_left_rounded,
                          size: 20,
                          color: FasakhanstaBrand.muted,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (index != items.length - 1)
                const Divider(
                  height: 1,
                  indent: 66,
                  endIndent: 14,
                  color: FasakhanstaBrand.border,
                ),
            ],
          );
        }),
      ),
    );
  }

  Widget _logoutButton(BuildContext context) {
    final isArabic = context.languageCode == 'ar';
    return InkWell(
      onTap: () => _logout(context),
      borderRadius: BorderRadius.circular(18),
      child: Container(
        height: 54,
        padding: const EdgeInsets.symmetric(horizontal: 15),
        decoration: BoxDecoration(
          color: FasakhanstaBrand.surfaceRaised,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: FasakhanstaBrand.border),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: FasakhanstaBrand.surfaceRaised,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.logout_rounded,
                color: FasakhanstaBrand.orange,
                size: 21,
              ),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Text(
                'logOut'.tr,
                style: AppTextStyle.text14BS(color: FasakhanstaBrand.orange),
              ),
            ),
            Text(
              isArabic ? 'إنهاء الجلسة' : 'End session',
              style: AppTextStyle.text10RG(color: FasakhanstaBrand.danger),
            ),
          ],
        ),
      ),
    );
  }

  Widget _partnerCard(BuildContext context) {
    final isArabic = context.languageCode == 'ar';
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 8),
      decoration: BoxDecoration(
        color: FasakhanstaBrand.surfaceRaised,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 39,
                height: 39,
                decoration: BoxDecoration(
                  color: AppColors.mainAppColor.withValues(alpha: .15),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(
                  Icons.handshake_outlined,
                  color: AppColors.mainAppColor,
                  size: 22,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isArabic
                          ? 'انضم إلى شبكة فسخانستا'
                          : 'Join the Faskhansta network',
                      style: AppTextStyle.text14BS(
                        color: FasakhanstaBrand.text,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isArabic
                          ? 'فرص للمندوبين والتجار'
                          : 'Opportunities for couriers and merchants',
                      style: AppTextStyle.text10RG(
                        color: FasakhanstaBrand.text.withValues(alpha: .6),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _partnerRow(
            context,
            Icons.delivery_dining_rounded,
            'registerAsADelegate'.tr,
            () => NamedNavigatorImpl.push(RegisterAsDeliveryScreen.routeName),
          ),
          Divider(
            height: 1,
            color: FasakhanstaBrand.border.withValues(alpha: .08),
          ),
          _partnerRow(
            context,
            Icons.storefront_outlined,
            'registerAsAMerchant'.tr,
            () => NamedNavigatorImpl.push(RegisterAsVendorScreen.routeName),
          ),
        ],
      ),
    );
  }

  Widget _partnerRow(
    BuildContext context,
    IconData icon,
    String title,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 2),
        child: Row(
          children: [
            Icon(icon, color: AppColors.mainAppColor, size: 22),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                style: AppTextStyle.text13BS(color: FasakhanstaBrand.text),
              ),
            ),
            Icon(
              context.languageCode == 'en'
                  ? Icons.chevron_right_rounded
                  : Icons.chevron_left_rounded,
              color: FasakhanstaBrand.text.withValues(alpha: .55),
              size: 22,
            ),
          ],
        ),
      ),
    );
  }

  Widget _guestLoginCard(BuildContext context) {
    final isArabic = context.languageCode == 'ar';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 21, 18, 18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            FasakhanstaBrand.surfaceRaised,
            FasakhanstaBrand.surfaceRaised,
          ],
        ),
        borderRadius: BorderRadius.circular(26),
        boxShadow: const [
          BoxShadow(
            color: Color(0x18000000),
            blurRadius: 22,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 62,
            height: 62,
            decoration: BoxDecoration(
              color: AppColors.mainAppColor.withValues(alpha: .16),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppColors.mainAppColor.withValues(alpha: .35),
              ),
            ),
            child: Icon(
              Icons.person_rounded,
              size: 34,
              color: AppColors.mainAppColor,
            ),
          ),
          const SizedBox(height: 13),
          Text(
            isArabic
                ? 'سجل دخولك لإدارة حسابك'
                : 'Sign in to manage your account',
            textAlign: TextAlign.center,
            style: AppTextStyle.text18BS(color: FasakhanstaBrand.text),
          ),
          const SizedBox(height: 6),
          Text(
            isArabic
                ? 'تابع طلباتك واحفظ عناوينك واستفد من كل المميزات بسهولة.'
                : 'Track orders, save addresses and enjoy all features easily.',
            textAlign: TextAlign.center,
            style: AppTextStyle.text12RG(
              color: FasakhanstaBrand.text.withValues(alpha: .65),
            ).copyWith(height: 1.45),
          ),
          const SizedBox(height: 17),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: () =>
                  NamedNavigatorImpl.push(clean: true, LoginScreen.routeName),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.mainAppColor,
                foregroundColor: FasakhanstaBrand.onOrange,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.login_rounded, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'signIn'.tr,
                    style: AppTextStyle.text15BS(
                      color: FasakhanstaBrand.onOrange,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _guestPartnerCard(BuildContext context) {
    final isArabic = context.languageCode == 'ar';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 15, 14, 8),
      decoration: BoxDecoration(
        color: FasakhanstaBrand.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: FasakhanstaBrand.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 39,
                height: 39,
                decoration: BoxDecoration(
                  color: FasakhanstaBrand.surfaceRaised,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(
                  Icons.handshake_outlined,
                  color: AppColors.mainAppColor,
                  size: 22,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isArabic ? 'انضم كشريك' : 'Join as a partner',
                      style: AppTextStyle.text15BS(),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isArabic
                          ? 'اختار الطريقة المناسبة ليك وابدأ معانا'
                          : 'Choose how you want to partner with us',
                      style: AppTextStyle.text10RG(
                        color: FasakhanstaBrand.muted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          _guestPartnerRow(
            context: context,
            icon: Icons.delivery_dining_rounded,
            title: 'registerAsADelegate'.tr,
            subtitle: isArabic
                ? 'وصّل الطلبات وحقق دخل إضافي'
                : 'Deliver orders and earn extra income',
            onTap: () =>
                NamedNavigatorImpl.push(RegisterAsDeliveryScreen.routeName),
          ),
          const Divider(height: 1, indent: 58, color: FasakhanstaBrand.border),
          _guestPartnerRow(
            context: context,
            icon: Icons.storefront_outlined,
            title: 'registerAsAMerchant'.tr,
            subtitle: isArabic
                ? 'اعرض منتجاتك وابدأ البيع'
                : 'Show your products and start selling',
            onTap: () =>
                NamedNavigatorImpl.push(RegisterAsVendorScreen.routeName),
          ),
        ],
      ),
    );
  }

  Widget _guestPartnerRow({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(15),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 10),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: FasakhanstaBrand.surfaceRaised,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: AppColors.mainAppColor, size: 23),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTextStyle.text13BS()),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyle.text10RG(color: FasakhanstaBrand.muted),
                  ),
                ],
              ),
            ),
            Icon(
              context.languageCode == 'en'
                  ? Icons.chevron_right_rounded
                  : Icons.chevron_left_rounded,
              size: 22,
              color: FasakhanstaBrand.muted,
            ),
          ],
        ),
      ),
    );
  }

  void _goToOrders(BuildContext context) {
    context.read<BottomNavigationController>().updateIndex(1);
  }

  void _logout(BuildContext context) {
    CommonMethods.showChooseDialog(
      context,
      title: 'doYouWantToLogout'.tr,
      message: '',
      onPressed: () => context.read<AuthController>().logout(),
    );
  }
}

class _MenuItem {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _MenuItem(this.icon, this.title, this.subtitle, this.onTap);
}
