import 'package:faskhaninja/helpers/theme/fasakhansta_brand.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

import '../../../../helpers/extensions/extensions.dart';
import '../../../../helpers/images/app_images.dart';
import '../../../../helpers/routes/app_routers_import.dart';
import '../../../../helpers/theme/app_colors.dart';
import '../../../custom_widgets/api_response_widget/api_response_widget.dart';
import '../../auth/controller/auth_controller.dart';
import '../controller/address_controller.dart';
import '../widget/address_widget.dart';
import '../widget/circle_avatar_widget.dart';
import 'add_address_screen.dart';

class AddressScreen extends StatelessWidget {
  static const String routeName = 'AddressScreen';
  final bool selectForDelivery;

  const AddressScreen({super.key, this.selectForDelivery = false});

  static const _text = FasakhanstaBrand.text;
  static const _muted = FasakhanstaBrand.muted;
  static const _border = FasakhanstaBrand.border;
  static const _softOrange = FasakhanstaBrand.orangeTint;

  bool _isArabic(BuildContext context) => context.languageCode == 'ar';

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AddressController()
        ..initialAddress()
        ..getAddress(),
      child: Consumer<AddressController>(
        builder: (context, addressController, _) {
          final profile = context.watch<AuthController>().profile;

          return Directionality(
            textDirection:
                _isArabic(context) ? TextDirection.rtl : TextDirection.ltr,
            child: Scaffold(
              backgroundColor: Colors.transparent,
              body: SafeArea(
                child: Column(
                  children: [
                    _header(context, addressController),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(16, 10, 16, 22),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _profileCard(
                              context,
                              name: profile?.name ?? '',
                              area: profile?.areaTitle ?? '',
                              gender: profile?.gender,
                            ),
                            if (selectForDelivery) ...[
                              const SizedBox(height: 12),
                              _selectionHint(context),
                            ],
                            const SizedBox(height: 18),
                            _sectionTitle(context),
                            const SizedBox(height: 10),
                            ApiResponseWidget(
                              apiResponse: addressController.addressResponse,
                              onReload: addressController.getAddress,
                              isEmpty: addressController.address.isEmpty,
                              emptyWidget: _emptyState(context),
                              child: Column(
                                children: List.generate(
                                  addressController.address.length,
                                  (index) {
                                    final address =
                                        addressController.address[index];
                                    return Padding(
                                      padding: EdgeInsets.only(
                                        bottom: index ==
                                                addressController
                                                        .address.length -
                                                    1
                                            ? 0
                                            : 12,
                                      ),
                                      child: AddressWidget(
                                        address: address,
                                        selectionMode: selectForDelivery,
                                        onSelect: selectForDelivery
                                            ? () => Navigator.of(context)
                                                .pop(address)
                                            : null,
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              bottomNavigationBar: SafeArea(
                top: false,
                child: Container(
                  color: FasakhanstaBrand.surface,
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
                  child: SizedBox(
                    height: 56,
                    child: ElevatedButton.icon(
                      onPressed: () =>
                          _openAddAddress(context, addressController),
                      style: ElevatedButton.styleFrom(
                        elevation: 0,
                        backgroundColor: AppColors.mainAppColor,
                        foregroundColor: FasakhanstaBrand.onOrange,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                      icon: const Icon(Icons.add_circle_outline_rounded),
                      label: Text(
                        selectForDelivery
                            ? (_isArabic(context)
                                ? 'إضافة عنوان جديد'
                                : 'Add new address')
                            : (_isArabic(context)
                                ? 'إضافة عنوان'
                                : 'Add address'),
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _header(BuildContext context, AddressController controller) {
    return Container(
      color: FasakhanstaBrand.surface,
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 10),
      child: Row(
        children: [
          _roundButton(
            icon: Icons.arrow_back_rounded,
            onTap: () => Navigator.of(context).pop(),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              selectForDelivery
                  ? (_isArabic(context)
                      ? 'اختيار عنوان محفوظ'
                      : 'Choose saved address')
                  : (_isArabic(context) ? 'العناوين' : 'Addresses'),
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: _text,
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 12),
          _roundButton(
            icon: Icons.add_circle_outline_rounded,
            onTap: () => _openAddAddress(context, controller),
          ),
        ],
      ),
    );
  }

  Widget _profileCard(
    BuildContext context, {
    required String name,
    required String area,
    required String? gender,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _cardDecoration(radius: 20),
      child: Row(
        children: [
          CircleAvatarWidget(gender: gender, name: name),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _text,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    SizedBox(
                      width: 24,
                      height: 16,
                      child: SvgPicture.asset(
                        AppImages.egyptIcon,
                        fit: BoxFit.contain,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        area.isEmpty
                            ? (_isArabic(context) ? 'مصر' : 'Egypt')
                            : area,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: _muted,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Icon(
            Icons.chevron_left_rounded,
            color: FasakhanstaBrand.muted,
            size: 24,
          ),
        ],
      ),
    );
  }

  Widget _selectionHint(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: _softOrange,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.mainAppColor.withValues(alpha: .12),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: FasakhanstaBrand.surface,
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(
              Icons.touch_app_outlined,
              color: AppColors.mainAppColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _isArabic(context)
                  ? 'اضغط على العنوان الذي تريد التوصيل إليه'
                  : 'Tap the address you want to deliver to',
              style: const TextStyle(
                color: FasakhanstaBrand.onOrange,
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: _softOrange,
            borderRadius: BorderRadius.circular(11),
          ),
          child: Icon(
            Icons.location_on_outlined,
            color: AppColors.mainAppColor,
            size: 20,
          ),
        ),
        const SizedBox(width: 9),
        Text(
          selectForDelivery
              ? (_isArabic(context)
                  ? 'اختر عنوان التوصيل'
                  : 'Choose delivery address')
              : (_isArabic(context) ? 'عناويني المحفوظة' : 'Saved addresses'),
          style: const TextStyle(
            color: _text,
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }

  Widget _emptyState(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 42, horizontal: 20),
      decoration: _cardDecoration(radius: 20),
      child: Column(
        children: [
          SizedBox(
            width: 92,
            height: 92,
            child: SvgPicture.asset(AppImages.noAddressIcon),
          ),
          const SizedBox(height: 16),
          Text(
            _isArabic(context) ? 'لا توجد عناوين محفوظة' : 'No saved addresses',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: _text,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            _isArabic(context)
                ? 'أضف عنوانًا لتسهيل اختيار موقع التوصيل لاحقًا.'
                : 'Add an address to make delivery selection faster.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: _muted, fontSize: 11.5, height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _roundButton({required IconData icon, required VoidCallback onTap}) {
    return Material(
      color: FasakhanstaBrand.surface,
      shape: const CircleBorder(),
      elevation: 2,
      shadowColor: const Color(0x22000000),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 46,
          height: 46,
          child: Icon(icon, color: AppColors.mainAppColor, size: 23),
        ),
      ),
    );
  }

  BoxDecoration _cardDecoration({double radius = 18}) {
    return BoxDecoration(
      color: FasakhanstaBrand.surface,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: _border),
      boxShadow: const [
        BoxShadow(
          color: Color(0x0D000000),
          blurRadius: 14,
          offset: Offset(0, 4),
        ),
      ],
    );
  }

  void _openAddAddress(
    BuildContext context,
    AddressController addressController,
  ) {
    NamedNavigatorImpl.push(
      AddAddressScreen.routeName,
      arguments: AddAddressArgs(onSuccess: addressController.getAddress),
    );
  }
}
