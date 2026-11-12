import 'package:faskhaninja/helpers/theme/fasakhansta_brand.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../helpers/extensions/extensions.dart';
import '../../../../helpers/routes/app_routers_import.dart';
import '../../../../helpers/theme/app_colors.dart';
import '../../../../helpers/utils/common_methods.dart';
import '../../auth/controller/auth_controller.dart';
import '../controller/address_controller.dart';
import '../model/address_model.dart';
import '../screen/update_address_screen.dart';

class AddressWidget extends StatelessWidget {
  final AddressModel address;
  final bool selectionMode;
  final VoidCallback? onSelect;

  const AddressWidget({
    super.key,
    required this.address,
    this.selectionMode = false,
    this.onSelect,
  });

  static const _text = FasakhanstaBrand.text;
  static const _muted = FasakhanstaBrand.muted;
  static const _border = FasakhanstaBrand.border;
  static const _softOrange = FasakhanstaBrand.orangeTint;
  static const _delete = Color(0xFFE53935);

  bool _isArabic(BuildContext context) => context.languageCode == 'ar';

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: selectionMode ? onSelect : null,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: FasakhanstaBrand.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selectionMode
                ? AppColors.mainAppColor.withValues(alpha: .24)
                : _border,
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0D000000),
              blurRadius: 14,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: _softOrange,
                          borderRadius: BorderRadius.circular(11),
                        ),
                        child: Icon(
                          _addressIcon,
                          color: AppColors.mainAppColor,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 9),
                      Expanded(
                        child: Text(
                          _title(context),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: AppColors.mainAppColor,
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _primaryAddress,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: _text,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      height: 1.35,
                    ),
                  ),
                  if (_secondaryAddress.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      _secondaryAddress,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _muted,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        height: 1.35,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 10),
            Container(width: 1, height: 74, color: _border),
            const SizedBox(width: 10),
            if (selectionMode)
              _actionButton(
                context: context,
                icon: Icons.check_circle_outline_rounded,
                label: _isArabic(context) ? 'اختيار' : 'Select',
                color: AppColors.mainAppColor,
                onTap: onSelect ?? () {},
              )
            else
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _actionButton(
                    context: context,
                    icon: Icons.edit_outlined,
                    label: _isArabic(context) ? 'تعديل' : 'Edit',
                    color: _text,
                    onTap: () => _edit(context),
                  ),
                  const SizedBox(width: 8),
                  Container(width: 1, height: 44, color: _border),
                  const SizedBox(width: 8),
                  _actionButton(
                    context: context,
                    icon: Icons.delete_outline_rounded,
                    label: _isArabic(context) ? 'حذف' : 'Delete',
                    color: _delete,
                    onTap: () => _deleteAddress(context),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _actionButton({
    required BuildContext context,
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 5),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 21),
            const SizedBox(height: 5),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _title(BuildContext context) {
    final candidates = [address.addressName, address.badge, address.type];
    for (final value in candidates) {
      if ((value ?? '').trim().isNotEmpty) return value!.trim();
    }
    return _isArabic(context) ? 'عنوان محفوظ' : 'Saved address';
  }

  IconData get _addressIcon {
    final value = '${address.addressName} ${address.badge} ${address.type}'
        .toLowerCase();
    if (value.contains('home') || value.contains('منزل')) {
      return Icons.home_outlined;
    }
    if (value.contains('work') || value.contains('عمل')) {
      return Icons.work_outline_rounded;
    }
    return Icons.location_on_outlined;
  }

  String get _primaryAddress {
    final parts = <String>[
      if ((address.streetName ?? '').trim().isNotEmpty)
        address.streetName!.trim(),
      if ((address.cityName ?? address.cityname ?? '').trim().isNotEmpty)
        (address.cityName ?? address.cityname)!.trim(),
      if ((address.countryName ?? '').trim().isNotEmpty)
        address.countryName!.trim(),
    ];

    if (parts.isNotEmpty) return parts.toSet().join(' - ');
    if ((address.address ?? '').trim().isNotEmpty) {
      return address.address!.trim();
    }
    if ((address.areaName ?? '').trim().isNotEmpty) {
      return address.areaName!.trim();
    }
    return '—';
  }

  String get _secondaryAddress {
    final parts = <String>[
      if ((address.areaName ?? '').trim().isNotEmpty) address.areaName!.trim(),
      if ((address.floorNo ?? '').trim().isNotEmpty)
        'Floor ${address.floorNo!.trim()}',
      if ((address.apartmentNo ?? '').trim().isNotEmpty)
        'Apt ${address.apartmentNo!.trim()}',
    ];
    return parts.toSet().join(' • ');
  }

  void _edit(BuildContext context) {
    NamedNavigatorImpl.push(
      UpdateAddressScreen.routeName,
      arguments: UpdateAddressScreenArgs(
        id: address.id ?? 0,
        areaName: address.areaName ?? '',
        apartmentNo: address.apartmentNo ?? '',
        floorNo: address.floorNo ?? '',
        streetName: address.streetName ?? '',
        mobile: address.mobile ?? '',
        badge: address.badge ?? '',
        addressName: address.addressName ?? '',
        type: address.type ?? '',
        lat: address.lat ?? '',
        lng: address.lng ?? '',
        onSuccess: () {
          Provider.of<AddressController>(context, listen: false).getAddress();
        },
        userAddressId: context.read<AuthController>().profile?.id ?? 0,
      ),
    );
  }

  void _deleteAddress(BuildContext context) {
    CommonMethods.showChooseDialog(
      context,
      message: _isArabic(context)
          ? 'هل تريد حذف هذا العنوان؟'
          : 'Do you want to delete this address?',
      onPressed: () {
        Navigator.pop(context);
        final id = address.id;
        if (id == null) return;
        Provider.of<AddressController>(context, listen: false).deleteAddress(
          id: id,
          onSuccess: () {
            context.read<AuthController>().getProfile();
            context.read<AddressController>().getAddress();
          },
        );
      },
    );
  }
}
