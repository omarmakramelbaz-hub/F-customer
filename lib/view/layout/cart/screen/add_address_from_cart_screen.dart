import 'package:faskhaninja/helpers/theme/fasakhansta_brand.dart';

import 'dart:async';
import 'dart:developer';

import 'package:country_picker/country_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';

import '../../../../helpers/extensions/extensions.dart';
import '../../../../helpers/images/app_images.dart';
import '../../../../helpers/routes/app_routers_import.dart';
import '../../../../helpers/theme/app_colors.dart';
import '../../../../helpers/theme/app_text_style.dart';
import '../../../../helpers/translation/all_translation.dart';
import '../../../custom_widgets/api_response_widget/api_response_widget.dart';
import '../../../custom_widgets/buttons/custom_button.dart';
import '../../../custom_widgets/custom_app_bar/custom_app_bar.dart';
import '../../../custom_widgets/custom_form_field/custom_form_field.dart';
import '../../../custom_widgets/custom_loading/custom_loading.dart';
import '../../../custom_widgets/validation/validation_mixin.dart';
import '../../address/controller/address_controller.dart';
import '../widgets/apartment_and_house_and_office_widget.dart';
import 'execute_the_order_screen.dart';

class AddAddressFromCartScreen extends StatefulWidget {
  static const String routeName = 'AddAddressFromCartScreen';
  const AddAddressFromCartScreen({super.key});

  @override
  State<AddAddressFromCartScreen> createState() =>
      _AddAddressFromCartScreenState();
}

class _AddAddressFromCartScreenState extends State<AddAddressFromCartScreen>
    with ValidationMixin {
  final _formKey = GlobalKey<FormState>();
  final _areaNameEc = TextEditingController();
  final _apartmentNoEc = TextEditingController();
  final _floorNoEc = TextEditingController();
  final _streetNameEc = TextEditingController();
  final _mobileEc = TextEditingController();
  final _badgeEc = TextEditingController();
  final _addressNameEc = TextEditingController();
  Country? _country;

  StreamSubscription<Position>? positionStream;
  List<Placemark>? placemarks;
  double? currentLat;
  double? currentLng;
  GoogleMapController? gmc;
  Set<Marker> markers = {};
  Timer? _debounce;

  Future<void> _determinePosition() async {
    try {
      // bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      // if (!serviceEnabled) {
      //   log("Location services are disabled.");
      //   return;
      // }

      // LocationPermission permission = await Geolocator.checkPermission();
      // if (permission == LocationPermission.denied) {
      //   permission = await Geolocator.requestPermission();
      //   if (permission == LocationPermission.denied) {
      //     log("Location permissions are denied");
      //     return;
      //   }
      // }

      // if (permission == LocationPermission.deniedForever) {
      //   log('Location permissions are permanently denied, we cannot request permissions.');
      //   return;
      // }

      Position position = await Geolocator.getCurrentPosition();
      _updateLocation(position.latitude, position.longitude);
    } catch (e) {
      log('Failed to get location: $e');
    }
  }

  void _updateLocation(double lat, double lng) async {
    setState(() {
      currentLat = lat;
      currentLng = lng;
      markers.clear();
      markers.add(
        Marker(
          markerId: const MarkerId('currentLocation'),
          position: LatLng(lat, lng),
        ),
      );
    });

    if (gmc != null) {
      gmc!.animateCamera(CameraUpdate.newLatLng(LatLng(lat, lng)));
    }

    placemarks = await placemarkFromCoordinates(lat, lng);
    setState(() {});
  }

  void _onMapTap(LatLng latLng) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      _updateLocation(latLng.latitude, latLng.longitude);
    });
  }

  @override
  void initState() {
    _determinePosition();
    _country = CountryParser.parsePhoneCode('20');
    super.initState();
  }

  @override
  dispose() {
    _areaNameEc.dispose();
    _apartmentNoEc.dispose();
    _floorNoEc.dispose();
    _streetNameEc.dispose();
    _mobileEc.dispose();
    _badgeEc.dispose();
    _addressNameEc.dispose();
    super.dispose();
  }

  int? selectedAddress;
  int? selectedAddressId;
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (BuildContext context) => AddressController()
        ..initialAddress()
        ..getAddress(),
      child: Scaffold(
        appBar: CustomAppBar(
          actions: const [],
          height: 90,
          radius: 60,
          title: Text('deliveryLocation'.tr),
        ),
        body: SingleChildScrollView(
          child: Consumer<AddressController>(
            builder: (context, addressController, _) => ApiResponseWidget(
              apiResponse: addressController.addressResponse,
              onReload: () => addressController.getAddress(),
              isEmpty: addressController.address.isEmpty,
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    18.sbH,
                    Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 15,
                            vertical: 10,
                          ),
                          child: Column(
                            // this column for add address
                            children: [
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(25),
                                  child: SizedBox(
                                    height: context.height * 0.5,
                                    child:
                                        currentLat != null && currentLng != null
                                        ? GoogleMap(
                                            onTap: _onMapTap,
                                            markers: {
                                              Marker(
                                                markerId: const MarkerId(
                                                  'currentLocation',
                                                ),
                                                position: LatLng(
                                                  currentLat ??
                                                      double.parse(
                                                        addressController
                                                                .addressDetails
                                                                ?.lat
                                                                .toString() ??
                                                            '0',
                                                      ),
                                                  currentLng ??
                                                      double.parse(
                                                        addressController
                                                                .addressDetails
                                                                ?.lng
                                                                .toString() ??
                                                            '0',
                                                      ),
                                                ),
                                              ),
                                            },
                                            mapType: MapType.normal,
                                            onMapCreated:
                                                (
                                                  GoogleMapController
                                                  controller,
                                                ) {
                                                  gmc = controller;
                                                  if (addressController
                                                          .addressDetails !=
                                                      null) {
                                                    gmc!.animateCamera(
                                                      CameraUpdate.newLatLng(
                                                        LatLng(
                                                          double.parse(
                                                            addressController
                                                                    .addressDetails
                                                                    ?.lat
                                                                    .toString() ??
                                                                '0',
                                                          ),
                                                          double.parse(
                                                            addressController
                                                                    .addressDetails
                                                                    ?.lng
                                                                    .toString() ??
                                                                '0',
                                                          ),
                                                        ),
                                                      ),
                                                    );
                                                  }
                                                },
                                            initialCameraPosition:
                                                CameraPosition(
                                                  target: LatLng(
                                                    double.parse(
                                                      addressController
                                                              .addressDetails
                                                              ?.lat
                                                              .toString() ??
                                                          '0',
                                                    ),
                                                    double.parse(
                                                      addressController
                                                              .addressDetails
                                                              ?.lng
                                                              .toString() ??
                                                          '0',
                                                    ),
                                                  ),
                                                  zoom: 12,
                                                ),
                                          )
                                        : const Center(child: CustomLoading()),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 14),
                              ...List.generate(addressController.address.length, (
                                index,
                              ) {
                                final address =
                                    addressController.address[index];
                                return InkWell(
                                  onTap: () {
                                    setState(() {
                                      selectedAddress = index;
                                      selectedAddressId =
                                          addressController.address[index].id;
                                      log(selectedAddressId.toString());
                                    });
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 20,
                                      vertical: 15,
                                    ),
                                    margin: const EdgeInsets.symmetric(
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(10),
                                      color: FasakhanstaBrand.surface,
                                      boxShadow: [
                                        BoxShadow(
                                          color: AppColors.greyColor.withValues(
                                            alpha: 0.3,
                                          ),
                                          offset: const Offset(0, 0),
                                          blurRadius: 10,
                                        ),
                                      ],
                                      border: Border.all(
                                        color: selectedAddress == index
                                            ? AppColors.mainAppColor
                                            : AppColors.borderColor,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.start,
                                              children: [
                                                SvgPicture.asset(
                                                  AppImages.addressIcon,
                                                  width: 16,
                                                ),
                                                const SizedBox(width: 10),
                                                Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      'area'.tr,
                                                      style:
                                                          AppTextStyle.text14MG(),
                                                    ),
                                                    5.sbH,
                                                    Text(
                                                      "${address.addressName ?? ''} ${address.areaName ?? ''} ${address.streetName ?? ''} ",
                                                      style:
                                                          AppTextStyle.text14RG(),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                        const Spacer(),
                                        Radio(
                                          fillColor: WidgetStateProperty.all(
                                            selectedAddress == index
                                                ? AppColors.mainAppColor
                                                : AppColors.borderColor,
                                          ),
                                          value: selectedAddress,
                                          groupValue: index,
                                          onChanged: (v) {
                                            v = selectedAddress;
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }),
                              const SizedBox(height: 24),
                              const ApartmentAndHouseAndOfficeWidget(),
                              const SizedBox(height: 16),
                              CustomFormField(
                                controller: _areaNameEc,
                                validator: validateEmptyField,
                                hintText: 'buildingName'.tr,
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Expanded(
                                    child: CustomFormField(
                                      controller: _apartmentNoEc,
                                      validator: validateEmptyField,
                                      keyboardType: TextInputType.number,
                                      hintText: 'apartmentNumber'.tr,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: CustomFormField(
                                      controller: _floorNoEc,
                                      validator: validateEmptyField,
                                      keyboardType: TextInputType.number,
                                      hintText: 'theRoleIsOptional'.tr,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              CustomFormField(
                                controller: _streetNameEc,
                                validator: validateEmptyField,
                                hintText: 'street'.tr,
                              ),
                              const SizedBox(height: 16),
                              CustomFormField(
                                controller: _badgeEc,
                                hintText: 'optionalDistinctiveSign'.tr,
                              ),
                              const SizedBox(height: 16),
                              CustomFormField(
                                validator: (v) =>
                                    validatePhone(v, country: _country),
                                controller: _mobileEc,
                                keyboardType: TextInputType.number,
                                country: _country,
                                hintText: 'mobileNumber'.tr,
                              ),
                              const SizedBox(height: 16),
                              CustomFormField(
                                controller: _addressNameEc,
                                hintText: 'titleLabelIsOptional'.tr,
                              ),
                              const SizedBox(height: 15),
                              CustomButton(
                                onPressed: () {
                                  if (selectedAddressId != null) {
                                    NamedNavigatorImpl.push(
                                      ExecuteTheOrderScreen.routeName,
                                      arguments: ExecuteTheOrderArgs(
                                        userAddressId: selectedAddressId,
                                      ),
                                    );
                                  }
                                  if (_formKey.currentState!.validate() &&
                                      selectedAddressId == null) {
                                    context.read<AddressController>().storeAddress(
                                      areaName: _areaNameEc.text,
                                      apartmentNo: _apartmentNoEc.text,
                                      floorNo: _floorNoEc.text,
                                      streetName: _streetNameEc.text,
                                      mobile: _mobileEc.text,
                                      addressName: _addressNameEc.text,
                                      type:
                                          addressController
                                                  .indexSelectedOfficeOrHouseOrApartment ==
                                              'office'
                                          ? 'office'
                                          : addressController
                                                    .indexSelectedOfficeOrHouseOrApartment ==
                                                'home'
                                          ? 'home'
                                          : 'apartment',
                                      lat:
                                          currentLat ??
                                          double.parse(
                                            addressController
                                                    .addressDetails
                                                    ?.lat
                                                    .toString() ??
                                                '0',
                                          ),
                                      lang:
                                          currentLng ??
                                          double.parse(
                                            addressController
                                                    .addressDetails
                                                    ?.lng
                                                    .toString() ??
                                                '0',
                                          ),
                                      countryName:
                                          placemarks![0].country ??
                                          addressController
                                              .addressDetails
                                              ?.countryName ??
                                          '',
                                      cityName:
                                          placemarks![0].locality ??
                                          addressController
                                              .addressDetails
                                              ?.cityName ??
                                          '',
                                      address:
                                          placemarks![0].street ??
                                          addressController
                                              .addressDetails
                                              ?.address ??
                                          '',
                                      badge: _badgeEc.text,
                                      onSuccess: ({int? userAddressId}) {
                                        NamedNavigatorImpl.push(
                                          ExecuteTheOrderScreen.routeName,
                                          arguments: ExecuteTheOrderArgs(
                                            userAddressId: userAddressId,
                                          ),
                                        );
                                      },
                                    );
                                  }
                                },
                                text: 'confirm'.tr,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
