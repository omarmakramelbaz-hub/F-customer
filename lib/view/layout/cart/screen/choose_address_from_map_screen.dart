import 'package:faskhaninja/helpers/theme/fasakhansta_brand.dart';

import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../helpers/extensions/extensions.dart';
import '../../../../helpers/images/app_images.dart';
import '../../../../helpers/routes/app_routers_import.dart';
import '../../../../helpers/theme/app_colors.dart';
import '../../../../helpers/theme/app_text_style.dart';
import '../../../../helpers/translation/all_translation.dart';
import '../../../../helpers/utils/common_methods.dart';
import '../../../custom_widgets/api_response_widget/api_response_widget.dart';
import '../../../custom_widgets/buttons/custom_button.dart';
import '../../../custom_widgets/custom_image/custom_image.dart';
import '../../address/controller/address_controller.dart';
import '../../address/screen/update_address_screen.dart';
import '../../auth/controller/auth_controller.dart';
import '../widgets/no_delevery_location_widget.dart';
import 'execute_the_order_screen.dart';

class ChooseAddressFromMapScreenArgs {
  final List<int> areaId;
  final int resturantId;

  ChooseAddressFromMapScreenArgs({
    required this.areaId,
    required this.resturantId,
  });
}

class ChooseAddressFromMapScreen extends StatefulWidget {
  static const String routeName = 'ChooseAddressFromMap';
  final ChooseAddressFromMapScreenArgs args;

  const ChooseAddressFromMapScreen({super.key, required this.args});

  @override
  State<ChooseAddressFromMapScreen> createState() =>
      _ChooseAddressFromMapScreenState();
}

class _ChooseAddressFromMapScreenState
    extends State<ChooseAddressFromMapScreen> {
  int? selectedAddressId;
  String? selectedAddressLat;
  String? selectedAddressLang;
  int selectedAddressIndex = 0;

  @override
  Widget build(BuildContext context) {
    log(widget.args.areaId.toString());

    return ChangeNotifierProvider(
      create: (context) => AddressController()
        ..initialAddress()
        ..getAddress(areaId: widget.args.areaId),
      child: Consumer<AddressController>(
        builder: (context, addressController, _) {
          if (selectedAddressId == null &&
              addressController.address.isNotEmpty) {
            selectedAddressId = addressController.address[0].id;
            selectedAddressLat = addressController.address[0].lat;
            selectedAddressLang = addressController.address[0].lng;
            selectedAddressIndex = 0;
          }

          return Scaffold(
            backgroundColor: Colors.transparent,
            appBar: AppBar(
              elevation: 0,
              backgroundColor: Colors.transparent,
              foregroundColor: FasakhanstaBrand.text,
              centerTitle: true,
              title: Text(
                'deliveryLocations'.tr,
                style: AppTextStyle.text18BS().copyWith(
                  color: FasakhanstaBrand.text,
                ),
              ),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            body: ApiResponseWidget(
              apiResponse: addressController.addressResponse,
              onReload: () =>
                  addressController.getAddress(areaId: widget.args.areaId),
              isEmpty: addressController.address.isEmpty,
              emptyWidget: NoDeliveryLocationWidget(
                addressController: addressController,
              ),
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 110),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'deliveryLocations'.tr,
                      style: AppTextStyle.text18BS(),
                    ),
                    5.sbH,
                    Text('chooseAddress'.tr, style: AppTextStyle.text13RG()),
                    16.sbH,
                    ...List.generate(addressController.address.length, (index) {
                      final address = addressController.address[index];
                      final selected = selectedAddressIndex == index;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(18),
                          onTap: () {
                            setState(() {
                              selectedAddressIndex = index;
                              selectedAddressId = address.id;
                              selectedAddressLat = address.lat;
                              selectedAddressLang = address.lng;
                            });
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            padding: const EdgeInsets.all(15),
                            decoration: BoxDecoration(
                              color: FasakhanstaBrand.surface,
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: selected
                                    ? AppColors.mainAppColor
                                    : AppColors.greyColor.withValues(
                                        alpha: .12,
                                      ),
                                width: selected ? 1.6 : 1,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(
                                    alpha: selected ? .06 : .035,
                                  ),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 46,
                                  height: 46,
                                  decoration: BoxDecoration(
                                    color: selected
                                        ? AppColors.mainAppColor.withValues(
                                            alpha: .12,
                                          )
                                        : AppColors.greyColor.withValues(
                                            alpha: .08,
                                          ),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    address.type == 'home'
                                        ? Icons.home_rounded
                                        : Icons.location_on_rounded,
                                    color: selected
                                        ? AppColors.mainAppColor
                                        : AppColors.greyColor,
                                  ),
                                ),
                                12.sbW,
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              address.addressName?.isNotEmpty ==
                                                      true
                                                  ? address.addressName!
                                                  : 'area'.tr,
                                              style: AppTextStyle.text15BS(),
                                            ),
                                          ),
                                          if (selected)
                                            Icon(
                                              Icons.check_circle_rounded,
                                              color: AppColors.mainAppColor,
                                              size: 22,
                                            ),
                                        ],
                                      ),
                                      5.sbH,
                                      Text(
                                        "${address.countryName ?? ''} - ${address.cityName ?? ''} - ${address.streetName ?? ''}",
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: AppTextStyle.text13RS(),
                                      ),
                                    ],
                                  ),
                                ),
                                8.sbW,
                                InkWell(
                                  borderRadius: BorderRadius.circular(10),
                                  onTap: () {
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
                                        onSuccess: () =>
                                            addressController.getAddress(
                                          areaId: widget.args.areaId,
                                        ),
                                        userAddressId: context
                                                .read<AuthController>()
                                                .profile
                                                ?.id ??
                                            0,
                                      ),
                                    );
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.all(6),
                                    child: Icon(
                                      Icons.edit_outlined,
                                      color: AppColors.mainAppColor,
                                      size: 20,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                    if (addressController.address.isNotEmpty)
                      InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () {
                          NamedNavigatorImpl.push(
                            UpdateAddressScreen.routeName,
                            arguments: UpdateAddressScreenArgs(
                              id: 0,
                              areaName: '',
                              apartmentNo: '',
                              floorNo: '',
                              streetName: '',
                              mobile: '',
                              badge: '',
                              addressName: '',
                              type: 'home',
                              lat: '',
                              lng: '',
                              onSuccess: () => addressController.getAddress(
                                areaId: widget.args.areaId,
                              ),
                              userAddressId:
                                  context.read<AuthController>().profile?.id ??
                                      0,
                            ),
                          );
                        },
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            color: AppColors.mainAppColor.withValues(
                              alpha: .07,
                            ),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: AppColors.mainAppColor.withValues(
                                alpha: .25,
                              ),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.add_location_alt_outlined,
                                color: AppColors.mainAppColor,
                              ),
                              8.sbW,
                              Text(
                                'addAddress'.tr,
                                style: AppTextStyle.text14BS().copyWith(
                                  color: AppColors.mainAppColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            bottomNavigationBar: SafeArea(
              top: false,
              child: Container(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
                decoration: BoxDecoration(
                  color: FasakhanstaBrand.surface,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: .1),
                      blurRadius: 16,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                child: CustomButton(
                  onPressed: () {
                    if (selectedAddressId == null) {
                      CommonMethods.showError(message: 'mustChooseAccount'.tr);
                      return;
                    }
                    addressController.canDeliver(
                      restaurantId: widget.args.resturantId,
                      customerLat: selectedAddressLat!,
                      customerLng: selectedAddressLang!,
                      onSuccess: () {
                        NamedNavigatorImpl.push(
                          ExecuteTheOrderScreen.routeName,
                          arguments: ExecuteTheOrderArgs(
                            userAddressId: selectedAddressId,
                          ),
                        );
                      },
                    );
                  },
                  text: 'confirm'.tr,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
