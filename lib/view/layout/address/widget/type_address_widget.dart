import 'package:faskhaninja/helpers/theme/fasakhansta_brand.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

import '../../../../helpers/extensions/extensions.dart';
import '../../../../helpers/images/app_images.dart';
import '../../../../helpers/theme/app_colors.dart';
import '../../../../helpers/theme/app_text_style.dart';
import '../../../../helpers/translation/all_translation.dart';
import '../controller/address_controller.dart';

class TypeAddressWidget extends StatefulWidget {
  final String? typeAddressFormUpdate;
  final String? onSelectedFromUpdate;
  const TypeAddressWidget({
    super.key,
    this.typeAddressFormUpdate,
    this.onSelectedFromUpdate,
  });

  @override
  State<TypeAddressWidget> createState() => _TypeAddressWidgetState();
}

class _TypeAddressWidgetState extends State<TypeAddressWidget> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.typeAddressFormUpdate != null) {
        Provider.of<AddressController>(
          context,
          listen: false,
        ).setIndexSelectedOfficeOrHouseOrApartment(
          widget.typeAddressFormUpdate!,
        );
      }
    });
  }

  Widget _buildAddressOption(
    BuildContext context,
    String icon,
    String label,
    String title,
  ) {
    final provider = Provider.of<AddressController>(context);

    final isSelected = provider.indexSelectedOfficeOrHouseOrApartment == title;
    final colorFilter = ColorFilter.mode(
      isSelected ? AppColors.whiteColor : AppColors.lightTextColor,
      BlendMode.srcIn,
    );

    return InkWell(
      onTap: () => provider.setIndexSelectedOfficeOrHouseOrApartment(title),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          color: isSelected ? AppColors.mainAppColor : FasakhanstaBrand.surface,
          border: isSelected
              ? null
              : Border.all(color: AppColors.borderColorContainer),
          gradient: isSelected
              ? LinearGradient(
                  colors: [
                    AppColors.gridOneButtonColor,
                    AppColors.gridTwoButtonColor,
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                )
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SvgPicture.asset(icon, colorFilter: colorFilter),
            const SizedBox(width: 8),
            Column(
              children: [
                5.sbH,
                Text(
                  label.tr,
                  style: isSelected
                      ? AppTextStyle.text14MW()
                      : AppTextStyle.text14RL(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildAddressOption(
          context,
          AppImages.apartmentIcon,
          'apartment',
          'office',
        ),
        _buildAddressOption(context, AppImages.houseIcon, 'house', 'home'),
        _buildAddressOption(
          context,
          AppImages.officeIcon,
          'office',
          'apartment',
        ),
      ],
    );
  }
}
