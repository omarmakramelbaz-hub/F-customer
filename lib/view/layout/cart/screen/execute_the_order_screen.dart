import 'dart:async';
import 'dart:convert';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:pusher_channels_flutter/pusher_channels_flutter.dart';
import 'package:skeletonizer/skeletonizer.dart';

import '../../../../helpers/extensions/extensions.dart';
import '../../../../helpers/images/app_images.dart';
import '../../../../helpers/pusher_service/pusher_controller.dart';
import '../../../../helpers/theme/app_colors.dart';
import '../../../../helpers/theme/app_text_style.dart';
import '../../../../helpers/translation/all_translation.dart';
import '../../../../helpers/utils/date_methods.dart';
import '../../../../helpers/utils/restaurant_hours.dart';
import '../../../custom_widgets/api_response_widget/api_response_widget.dart';
import '../../../custom_widgets/custom_app_bar/custom_app_bar.dart';
import '../../../custom_widgets/custom_form_field/custom_form_field.dart';
import '../../../custom_widgets/custom_loading/custom_shimmer.dart';
import '../../address/controller/address_controller.dart';
import '../../auth/controller/auth_controller.dart';
import '../../my_account/controller/my_account_controller.dart';
import '../../restaurants/model/details_restaurants_model.dart';
import '../controller/cart_controller.dart';
import '../widgets/choose_cash_or_visa_or_vcash_widget.dart';
import '../widgets/execute_order_button.dart';
import '../widgets/order_prices_widget.dart';

class ExecuteTheOrderArgs {
  final int? userAddressId;
  ExecuteTheOrderArgs({this.userAddressId});
}

class ExecuteTheOrderScreen extends StatefulWidget {
  final ExecuteTheOrderArgs args;
  static const String routeName = 'ExecuteTheOrderScreen';
  const ExecuteTheOrderScreen({super.key, required this.args});

  @override
  State<ExecuteTheOrderScreen> createState() => _ExecuteTheOrderScreenState();
}

class _ExecuteTheOrderScreenState extends State<ExecuteTheOrderScreen> {
  List<Placemark>? placemarks;
  double? currentLat;
  double? currentLng;
  GoogleMapController? gmc;
  Set<Marker> markers = {};
  Timer? _debounce;
  late PusherController _pusherController; // Saved reference
  String? resturantStatus;
  String? resturantOpenAt;
  int? resturantId;
  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  // Future<void> _determinePosition() async {
  //   try {
  //     Position position = await Geolocator.getCurrentPosition();
  //     _updateLocation(position.latitude, position.longitude);
  //   } catch (e) {
  //     log("Failed to get location: $e");
  //   }
  // }

  // void _updateLocation(double lat, double lng) async {
  //   setState(() {
  //     currentLat = lat;
  //     currentLng = lng;
  //     markers.clear();
  //     markers.add(Marker(
  //       markerId: const MarkerId("currentLocation"),
  //       position: LatLng(lat, lng),
  //     ));
  //   });

  //   if (gmc != null) {
  //     gmc!.animateCamera(CameraUpdate.newLatLng(LatLng(lat, lng)));
  //   }

  //   placemarks = await placemarkFromCoordinates(lat, lng);
  //   setState(() {});
  // }

  @override
  initState() {
    //_determinePosition();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      Provider.of<MyAccountController>(context, listen: false).initialSetting();
      Provider.of<MyAccountController>(context, listen: false).getSetting();

      Provider.of<CartController>(context, listen: false).initialCart();
      Provider.of<CartController>(context, listen: false).getCart().then((value) {
        resturantStatus = context.read<CartController>().cart?.resturant?.resturantStatus;
        resturantOpenAt = context.read<CartController>().cart?.resturant?.resturantOpenAt;
        resturantId = context.read<CartController>().cart?.resturant?.resturantId;
        setState(() {});
        // log("================>$resturantStatus");
        // log("================>$resturantId");
      });
      // Provider.of<AuthController>(context, listen: false).initialProfile();
      // Provider.of<AuthController>(context, listen: false).getProfile();
    });
    _pusherController = context.read<PusherController>();
    _pusherController.addEventListener('resturant.updated', _handleResturantUpdated);

    super.initState();
  }

  void _handleResturantUpdated(PusherEvent event) {
    try {
      final decodedData = json.decode(event.data) as Map<String, dynamic>;
      final resturantData = decodedData['resturant'];

      if (mounted) {
        final resturantModel = DetailsRestaurantModel.fromJson(resturantData as Map<String, dynamic>);
        resturantStatus = resturantModel.status;
        resturantOpenAt = resturantModel.openAt;
        resturantId = resturantModel.id;
        setState(() {});
        // context
        //     .read<RestaurantsController>()
        //     .updateResturantDetails(resturantModel);
        // context.read<HomeController>().updateSpacialResturant(resturantModel);
      }
    } catch (e, stackTrace) {
      log('Error handling Pusher event: $e');
      log('Stack trace: $stackTrace');
    }
  }

  DateTime? selectedDate;
  DateTime? selectedTime;
  DateTime? selectedDateZone;
  final noteEC = TextEditingController();
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => AddressController()
        ..initialAddressDetails()
        ..getAddressDetails(id: widget.args.userAddressId ?? 0),
      child: Scaffold(
        appBar: CustomAppBar(
          actions: const [],
          height: 90,
          radius: 60,
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios, color: AppColors.blackColor),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
          title: Text('executeTheOrder'.tr, style: AppTextStyle.text16MS()),
        ),
        body: Consumer2<CartController, AddressController>(
          builder: (BuildContext context, cartController, addressController, _) {
            // resturantStatus = cartController.cart?.resturant?.resturantStatus;
            // log("================>$resturantStatus");

            final bool hasExpiryDate;
            if ((cartController.cart?.resturant?.resturantAreas?.any(
                  (e) =>
                      e.areaId == addressController.addressDetails?.cityId &&
                      e.type == 'day' &&
                      e.expectedDelivery != '0',
                )) ??
                false) {
              hasExpiryDate = true;
            } else {
              hasExpiryDate = false;
            }

            final dist = Geolocator.distanceBetween(
                  double.parse(addressController.addressDetails?.lat.toString() ?? '0.0'),
                  double.parse(addressController.addressDetails?.lng.toString() ?? '0.0'),
                  double.parse(cartController.cart?.carts?[0].resturantLat.toString() ?? '0.0'),
                  double.parse(cartController.cart?.carts?[0].resturantLng.toString() ?? '0.0'),
                ) /
                1000;
            num kmPrice;
            kmPrice = switch (dist.toStringAsFixed(0)) {
              '0' => num.parse(cartController.cart?.resturant?.default_0_1.toString() ?? '0'),
              '1' => num.parse(cartController.cart?.resturant?.default_1_2.toString() ?? '0'),
              '2' => num.parse(cartController.cart?.resturant?.default_2_3.toString() ?? '0'),
              '3' => num.parse(context.watch<MyAccountController>().setting?.default23.toString() ?? '0'),
              _ => (cartController.cart?.resturant?.resturantKmPrice ?? 0) * dist,
            };

            final totalPrice = cartController.totalPrice;
            final num serviceFees = (((cartController.cart?.resturant?.serviceFees ?? 0) * (totalPrice)) / 100);
            final num addedPrice = (((cartController.cart?.resturant?.tax ?? 0) * (totalPrice)) / 100);
            num resturantMinOrderPrice = cartController.cart?.resturant?.resturantMinOrderPrice ?? 0;
            // final num grandTotal = (kmPrice + serviceFees + addedPrice + (totalPrice));
            // log('kmPrice====> $kmPrice');
            // log('dist====> $dist');
            // log('dist fixd ====> ${dist.toStringAsFixed(0)}');

            return ApiResponseWidget(
              apiResponse: cartController.cartResponse,
              onReload: () {
                cartController.getCart();
                addressController.getAddressDetails(id: widget.args.userAddressId ?? 0);
              },
              isEmpty: cartController.cart == null,
              emptyWidget: const SizedBox(),
              errorWidget: const SizedBox(),
              child: SingleChildScrollView(
                child: Skeletonizer(
                  enabled: cartController.cart == null,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      18.sbH,

                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            //=========================== address =============================
                            ApiResponseWidget(
                              apiResponse: addressController.addressDetailsResponse,
                              onReload: () => addressController.getAddressDetails(id: widget.args.userAddressId ?? 0),
                              isEmpty: addressController.addressDetails == null,
                              loadingWidget: CustomShimmer(
                                height: 70,
                                width: double.infinity,
                                fillColor: AppColors.greyColor.withValues(alpha: 0.08),
                                shimmerColor: AppColors.mainAppColor,
                              ),
                              child: Column(
                                children: [
                                  SizedBox(
                                    height: context.height * 0.2,
                                    child: addressController.addressDetails?.lat != null &&
                                            addressController.addressDetails?.lng != null
                                        ? GoogleMap(
                                            markers: {
                                              Marker(
                                                markerId: const MarkerId('currentLocation'),
                                                position: LatLng(
                                                  double.parse(
                                                    addressController.addressDetails?.lat.toString() ?? '0',
                                                  ),
                                                  double.parse(
                                                    addressController.addressDetails?.lng.toString() ?? '0',
                                                  ),
                                                ),
                                              ),
                                            },
                                            mapType: MapType.normal,
                                            onMapCreated: (GoogleMapController controller) {
                                              gmc = controller;
                                              if (addressController.addressDetails != null) {
                                                gmc!.animateCamera(
                                                  CameraUpdate.newLatLng(
                                                    LatLng(
                                                      double.parse(
                                                        addressController.addressDetails?.lat.toString() ?? '0',
                                                      ),
                                                      double.parse(
                                                        addressController.addressDetails?.lng.toString() ?? '0',
                                                      ),
                                                    ),
                                                  ),
                                                );
                                              }
                                            },
                                            initialCameraPosition: CameraPosition(
                                              target: LatLng(
                                                double.parse(
                                                  addressController.addressDetails?.lat.toString() ?? '0',
                                                ),
                                                double.parse(
                                                  addressController.addressDetails?.lng.toString() ?? '0',
                                                ),
                                              ),
                                              zoom: 12,
                                            ),
                                          )
                                        : const Center(child: CircularProgressIndicator()),
                                  ),
                                  14.sbH,
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(10),
                                      color: AppColors.whiteColor,
                                      boxShadow: [
                                        BoxShadow(
                                          color: AppColors.greyColor.withValues(alpha: 0.3),
                                          offset: const Offset(0, 0),
                                          blurRadius: 10,
                                        ),
                                      ],
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.start,
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  SvgPicture.asset(
                                                    AppImages.addressIcon,
                                                    colorFilter: ColorFilter.mode(
                                                      AppColors.secondAppColor,
                                                      BlendMode.srcIn,
                                                    ),
                                                    width: 16,
                                                  ),
                                                  const SizedBox(width: 10),
                                                  Text('area'.tr, style: AppTextStyle.text14MG()),
                                                ],
                                              ),
                                              5.sbH,
                                              Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  5.sbH,
                                                  Text(
                                                    '${addressController.addressDetails?.countryName}, ${addressController.addressDetails?.cityName},${addressController.addressDetails?.address} ',
                                                    style: AppTextStyle.text14RG(),
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                  if (addressController.addressDetails?.mobile != null) ...[
                                                    5.sbH,
                                                    Text(
                                                      '${'mobileNumber'.tr} : ${addressController.addressDetails?.mobile ?? ""}',
                                                      style: AppTextStyle.text14RG(),
                                                    ),
                                                  ],
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                        InkWell(
                                          onTap: () {
                                            Navigator.pop(context);
                                          },
                                          child: Text(
                                            'change'.tr,
                                            style: AppTextStyle.text14MM().copyWith(
                                              decoration: TextDecoration.underline,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            24.sbH,
                            if (cartController.cart?.carts?.isNotEmpty == true &&
                                cartController.cart?.carts?.first.resturantDeliveryTime != null)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(10),
                                  color: AppColors.whiteColor,
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.greyColor.withValues(alpha: 0.3),
                                      offset: const Offset(0, 0),
                                      blurRadius: 10,
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.start,
                                      children: [
                                        SvgPicture.asset(AppImages.reloadIcon, width: 18),
                                        const SizedBox(width: 10),
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text('delivery'.tr, style: AppTextStyle.text14MG()),
                                            5.sbH,
                                            if (hasExpiryDate) ...[
                                              Text(
                                                'deliveryAfterDays'.tr.replaceAll(
                                                      '{}',
                                                      "${(cartController.cart?.resturant?.resturantAreas?.firstWhere((e) => e.areaId == addressController.addressDetails?.cityId && e.type == "day" && e.expectedDelivery != "0"))?.expectedDelivery}",
                                                    ),
                                                style: AppTextStyle.text14RG(),
                                              ),
                                            ],
                                            !hasExpiryDate
                                                ? Text(
                                                    cartController.cart?.carts?.first.resturantDeliveryTime ?? '',
                                                    style: AppTextStyle.text14RG(),
                                                  )
                                                : const SizedBox(),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            32.sbH,
                            Text('paymentThrough'.tr, style: AppTextStyle.text16BS()),
                            14.sbH,
                            const ChooseCashOrVisaOrVCashWidget(),
                            32.sbH,
                            if (cartController.cart?.resturant?.resturantAreas?.any(
                                  (e) =>
                                      e.areaId == addressController.addressDetails?.cityId &&
                                      e.type == 'day' &&
                                      e.expectedDelivery != '0',
                                ) ==
                                true)
                              Row(
                                children: [
                                  Text('chooseReDeliveryOrder'.tr, style: AppTextStyle.text16BS()),
                                  const Spacer(),
                                  IconButton(
                                    onPressed: () {
                                      final selectedArea = cartController.cart?.resturant?.resturantAreas?.firstWhere(
                                        (e) =>
                                            e.areaId == addressController.addressDetails?.cityId &&
                                            e.type == 'day' &&
                                            e.expectedDelivery != '0',
                                      );
                                      if (selectedArea != null) {
                                        DateMethods.pickTime(
                                          context,
                                          initialDate: DateTime.now().add(
                                            Duration(
                                              days: int.tryParse(selectedArea.expectedDelivery.toString()) ?? 0,
                                            ),
                                          ),
                                          onSuccess: (date) {
                                            setState(() {
                                              selectedDate = date;
                                              log(selectedDate.toString());
                                            });
                                          },
                                        );

                                        DateMethods.pickDate(
                                          context,
                                          initialDate: DateTime.now().add(
                                            Duration(
                                              days: int.tryParse(selectedArea.expectedDelivery.toString()) ?? 0,
                                            ),
                                          ),
                                          firstDate: DateTime.now().add(
                                            Duration(
                                              days: int.tryParse(selectedArea.expectedDelivery.toString()) ?? 0,
                                            ),
                                          ),
                                          onSuccess: (dateZone) {
                                            setState(() {
                                              selectedDateZone = dateZone;
                                              selectedTime = dateZone;
                                              log(selectedDateZone.toString());
                                            });
                                          },
                                        );
                                      }
                                    },
                                    icon: Icon(Icons.date_range_outlined, color: AppColors.mainAppColor),
                                  ),
                                ],
                              )
                            else
                              Row(
                                children: [
                                  Text(
                                    'doYouWantToScheduleYourOrder'.tr,
                                    style: AppTextStyle.text16BS(),
                                  ),
                                  const Spacer(),
                                  Switch(
                                    value: cartController.isSwitchedscheduleDate,
                                    onChanged: (value) {
                                      cartController.setIsSwitchedscheduleDate(value);
                                      if (value == true) {
                                        DateMethods.pickTime(
                                          context,
                                          initialDate: DateTime.now(),
                                          onSuccess: (date) {
                                            setState(() {
                                              selectedDate = date;
                                              log(selectedDate.toString());
                                            });
                                          },
                                        );
                                        DateMethods.pickDate(
                                          context,
                                          initialDate: DateTime.now(),
                                          firstDate: DateTime.now(),
                                          onSuccess: (time) {
                                            setState(() {
                                              selectedTime = time;
                                              log(selectedTime.toString());
                                            });
                                          },
                                        );
                                      } else {
                                        setState(() {
                                          selectedDate = null;
                                          selectedTime = null;
                                        });
                                      }
                                    },
                                    activeTrackColor: AppColors.mainAppColor,
                                    activeColor: AppColors.mainAppColor,
                                  ),
                                ],
                              ),
                            10.sbH,
                          ],
                        ),
                      ),

                      if (selectedTime != null)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                          child: Row(
                            children: [
                              Text('orderReceiveDate'.tr),
                              const Spacer(),
                              Text(
                                '${DateMethods.formatToDate(selectedTime.toString())} ${DateMethods.formatToTime(selectedDate.toString())}',
                              ),
                            ],
                          ),
                        )
                      else
                        const SizedBox(),
                      Container(
                        height: 5,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: AppColors.greyColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      24.sbH,
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        child: CustomFormField(
                          controller: noteEC,
                          title: 'didYouHaveAnyNotes'.tr,
                          radius: 5,
                          hintText: 'writeNotes'.tr,
                          onChanged: (value) {
                            if (_debounce?.isActive ?? false) _debounce?.cancel();
                            _debounce = Timer(const Duration(milliseconds: 500), () {
                              cartController.setNotes(value);
                            });
                          },
                          prefixIcon: Icon(Icons.edit_square, color: AppColors.mainAppColor),
                        ),
                      ),
                      24.sbH,
                      ExecuteOrderPricesWidget(
                        resturantMinOrderPrice: resturantMinOrderPrice,
                        addedPrice: addedPrice,
                        totalPrice: totalPrice,
                        kmPrice: cartController.cart?.resturant?.resturantKmPrice != 0 ? kmPrice : 0,
                        serviceFees: serviceFees,
                        cartController: cartController,
                      ),
                      // cartController.cart?.resturant?.resturantAreas?.any((e) =>
                      //             e.areaId ==
                      //             addressController.addressDetails?.cityId) ==
                      //         true
                      //     ?
                      Column(
                        children: [
                          context.read<AuthController>().profile?.otpFirstOrder == 0
                              ? Container(
                                  padding: const EdgeInsets.all(10),
                                  margin: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(border: Border.all(color: AppColors.borderColor)),
                                  child: Center(
                                    child: Text(
                                      'vrCode'.tr,
                                      style: AppTextStyle.text16BS(),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                )
                              : const SizedBox(),
                          10.sbH,
                          ((resturantStatus != 'opened' &&
                                  (resturantId == cartController.cart?.resturant?.resturantId)))
                              ? Container(
                                  width: double.infinity,
                                  margin: const EdgeInsets.symmetric(horizontal: 16),
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFFF4EE),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: AppColors.mainAppColor.withValues(alpha: .22),
                                    ),
                                  ),
                                  child: Text(
                                    restaurantOrderingUnavailableLabel(
                                      context,
                                      status: resturantStatus,
                                      openAt: resturantOpenAt,
                                    ),
                                    style: AppTextStyle.text14BM(),
                                    textAlign: TextAlign.center,
                                  ),
                                )
                              : ExecuteOrderButton(
                                  deliveryPrice: cartController.cart?.resturant?.resturantKmPrice != 0 ? kmPrice : 0,
                                  cartController: cartController,
                                  addressController: addressController,
                                  userAddressId: widget.args.userAddressId ?? 0,
                                  selectedDate: selectedDate,
                                  selectedDateZone: selectedDateZone,
                                  selectedTime: selectedTime,
                                ),
                        ],
                      ),
                      // : Center(
                      //     child: Padding(
                      //       padding:
                      //           const EdgeInsets.symmetric(horizontal: 21.0),
                      //       child: Text(
                      //         'sorryCantExecuteYourOrder'.tr,
                      //         style: AppTextStyle.text16BM(),
                      //         textAlign: TextAlign.center,
                      //       ),
                      //     ),
                      //   ),
                      20.sbH,
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
