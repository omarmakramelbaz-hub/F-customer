import 'package:faskhaninja/helpers/theme/fasakhansta_brand.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

import '../../../../helpers/extensions/extensions.dart';
import '../../../../helpers/hive/hive_methods.dart';
import '../../../../helpers/images/app_images.dart';
import '../../../../helpers/routes/app_routers_import.dart';
import '../../../../helpers/theme/app_colors.dart';
import '../../../../helpers/theme/app_text_style.dart';
import '../../../../helpers/translation/all_translation.dart';
import '../../../custom_widgets/api_response_widget/api_response_widget.dart';
import '../../../custom_widgets/bottom_sheet/bottom_sheet_helper.dart';
import '../../../custom_widgets/custom_image/custom_image.dart';
import '../../../custom_widgets/custom_loading/custom_shimmer.dart';
import '../../address/screen/add_address_screen.dart';
import '../../auth/controller/auth_controller.dart';
import '../../auth/model/profile_model.dart';

class CurrentCityWidget extends StatefulWidget {
  const CurrentCityWidget({super.key, required this.onCityChanged});
  final VoidCallback onCityChanged;

  @override
  State<CurrentCityWidget> createState() => _CurrentCityWidgetState();
}

class _CurrentCityWidgetState extends State<CurrentCityWidget> {
  @override
  void initState() {
    // Fetch profile data when the widget is first initialized.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AuthController>(context, listen: false).initialProfile();
      Provider.of<AuthController>(context, listen: false).getProfile();
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthController>(
      builder: (context, value2, child) {
        final value = context.read<AuthController>();
        final userAddresses =
            context.read<AuthController>().profile?.userAddresses ?? [];

        final String? selectedCity = HiveMethods.getSelectedCity()?.toString();

        // Only set `selectedAddressId` if `selectedCity` is valid and exists in `userAddresses`
        String? selectedAddressId;
        if (userAddresses.any(
          (address) => address.id.toString() == selectedCity,
        )) {
          selectedAddressId = selectedCity;
        }

        return ApiResponseWidget(
          unauthorizedWidget: const SizedBox.shrink(),
          offlineWidget: InkWell(
            onTap: () {
              _showCitySelectionSheet(
                context,
                userAddresses,
                selectedAddressId,
              );
            },
            child: Text(
              selectedAddressId != null
                  ? ' ${userAddresses.firstWhere((address) => address.id.toString() == selectedAddressId).cityName ?? ""} ${userAddresses.firstWhere((address) => address.id.toString() == selectedAddressId).streetName ?? ""}'
                  : 'chooseAnAddress'.tr,
              style: AppTextStyle.text16BW(),
            ),
          ),
          apiResponse: value.profileResponse,
          onReload: () => value.getProfile(),
          isEmpty: value.profile == null,
          loadingSize: 10,
          loadingWidget: CustomShimmer(
            height: 30,
            width: 100,
            fillColor: AppColors.greyColor.withValues(alpha: 0.05),
            shimmerColor: AppColors.mainAppColor.withValues(alpha: 0.05),
          ),
          child: GestureDetector(
            onTap: () {
              _showCitySelectionSheet(
                context,
                userAddresses,
                selectedAddressId,
              );
            },
            child: Container(
              width: context.width * 0.7,
              padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 5),
              child: Row(
                // mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    constraints: BoxConstraints(maxWidth: context.width * 0.6),
                    child: Text(
                      selectedAddressId != null
                          ? ' ${userAddresses.firstWhere((address) => address.id.toString() == selectedAddressId).cityName ?? ""} ${userAddresses.firstWhere((address) => address.id.toString() == selectedAddressId).streetName ?? ""}'
                              .trim()
                          : 'chooseAnAddress'.tr,
                      style: AppTextStyle.text16BW(),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 5),
                    child: SvgPicture.asset(
                      AppImages.droPIcon,
                      colorFilter: ColorFilter.mode(
                        AppColors.whiteColor,
                        BlendMode.srcIn,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<bool?> _showCitySelectionSheet(
    BuildContext context,
    List<UserAddresses> userAddresses,
    String? selectedAddressId,
  ) {
    return BottomSheetHelper.gShowModalBottomSheet(
      context: context,
      maxHeight: context.height * 0.8,
      barrierDismissible: false,
      content: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'deliveryAddresses'.tr,
              style: AppTextStyle.text16MS().copyWith(
                color: FasakhanstaBrand.text,
              ),
            ),
            SizedBox(
              height: context.height * 0.65,
              child: ListView.builder(
                itemCount: userAddresses.length,
                itemBuilder: (context, index) {
                  final address = userAddresses[index];
                  return ListTile(
                    trailing:
                        userAddresses[index].streetName == HiveMethods.getCity()
                            ? const CustomImage(
                                path: AppImages.rateIcon,
                                type: ImageType.svg,
                                height: 20,
                                width: 20,
                              )
                            : const SizedBox.shrink(),
                    leading: CustomImage(
                      path: AppImages.addressIcon,
                      type: ImageType.svg,
                      color: FasakhanstaBrand.text,
                    ),
                    contentPadding: EdgeInsets.zero,
                    horizontalTitleGap: 0,
                    title: Text(
                      "${address.countryName ?? ""} \t-\t ${address.cityName ?? ""} \t-\t ${address.streetName ?? ""}",
                      style: AppTextStyle.text16BS(),
                    ),
                    selected: address.id.toString() == selectedAddressId,
                    onTap: () {
                      Navigator.pop(context); // Close the bottom sheet.
                      setState(() {
                        selectedAddressId = address.id.toString();
                        HiveMethods.updateSelectedCity(address.id ?? 0);
                        HiveMethods.updateLat(
                          double.tryParse(address.lat.toString()) ?? 0,
                        );
                        HiveMethods.updateLan(
                          double.tryParse(address.lng.toString()) ?? 0,
                        );
                        HiveMethods.updateCity(address.streetName ?? '');
                        HiveMethods.updateSelectedCityAreaId(
                          address.cityId ?? 0,
                        );

                        Provider.of<AuthController>(
                          context,
                          listen: false,
                        ).setSelectedAddressId(address.id);
                        widget.onCityChanged.call();
                      });
                    },
                  );
                },
              ),
            ),
            ListTile(
              title: Text(
                'deliveryToAnotherAddress'.tr,
                style: AppTextStyle.text16BS(),
              ),
              trailing: Icon(
                Icons.arrow_forward_ios,
                color: FasakhanstaBrand.text,
              ),
              onTap: () {
                Navigator.pop(context);
                NamedNavigatorImpl.push(
                  AddAddressScreen.routeName,
                  arguments: AddAddressArgs(
                    onSuccess: () {
                      Provider.of<AuthController>(
                        context,
                        listen: false,
                      ).getProfile();

                      Navigator.pop(context);
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        _showCitySelectionSheet(
                          context,
                          userAddresses,
                          selectedAddressId,
                        );
                      });
                    },
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
