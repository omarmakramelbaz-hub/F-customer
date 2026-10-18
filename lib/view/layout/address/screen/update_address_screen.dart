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
import '../../../../helpers/utils/address_lookup_service.dart';
import '../../../custom_widgets/api_response_widget/api_response_widget.dart';
import '../../../custom_widgets/buttons/custom_button.dart';
import '../../../custom_widgets/custom_form_field/custom_form_field.dart';
import '../../../custom_widgets/custom_loading/custom_loading.dart';
import '../../../custom_widgets/page_container/page_container.dart';
import '../../../custom_widgets/validation/validation_mixin.dart';
import '../../auth/controller/auth_controller.dart';
import '../controller/address_controller.dart';
import '../widget/change_adress_widget.dart';
import '../widget/type_address_widget.dart';
import 'map_screen.dart';

class UpdateAddressScreenArgs {
  final int id;
  final String areaName;
  final String apartmentNo;
  final String floorNo;
  final String streetName;
  final String mobile;
  final String badge;
  final String addressName;
  final String type;
  final String lat;
  final String lng;
  final VoidCallback? onSuccess;

  UpdateAddressScreenArgs({
    required this.id,
    required this.areaName,
    required this.apartmentNo,
    required this.floorNo,
    required this.streetName,
    required this.mobile,
    required this.badge,
    required this.addressName,
    required this.type,
    required this.lat,
    required this.lng,
    this.onSuccess,
    required int userAddressId,
  });
}

class UpdateAddressScreen extends StatefulWidget {
  final UpdateAddressScreenArgs args;

  static const String routeName = 'UpdateAddressScreen';
  const UpdateAddressScreen({super.key, required this.args});

  @override
  State<UpdateAddressScreen> createState() => _AddAddressScreenState();
}

class _AddAddressScreenState extends State<UpdateAddressScreen> with ValidationMixin {
  final AddressLookupService _addressLookupService = AddressLookupService();
  final _formKey = GlobalKey<FormState>();
  final _areaNameEc = TextEditingController();
  final _apartmentNoEc = TextEditingController();
  final _floorNoEc = TextEditingController();
  final _streetNameEc = TextEditingController();
  final _mobileEc = TextEditingController();
  final _badgeEc = TextEditingController();
  final _addressNameEc = TextEditingController();
  final _areaNameFocusNode = FocusNode();
  final _apartmentNoFocusNode = FocusNode();
  final _floorNoFocusNode = FocusNode();
  final _streetNameFocusNode = FocusNode();
  final _badgeFocusNode = FocusNode();
  final _mobileFocusNode = FocusNode();
  final _addressNameFocusNode = FocusNode();
  String? typeAddress;
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
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        log('Location services are disabled.');
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          log('Location permissions are denied');
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        log('Location permissions are permanently denied, we cannot request permissions.');
        return;
      }

      _updateLocation(double.parse(widget.args.lat), double.parse(widget.args.lng));
    } catch (e) {
      log('Failed to get location: $e');
    }
  }

  void _updateLocation(double lat, double lng) async {
    if (!mounted) return;
    setState(() {
      currentLat = lat;
      currentLng = lng;
      markers.clear();
      markers.add(Marker(markerId: const MarkerId('currentLocation'), position: LatLng(lat, lng)));
    });

    if (gmc != null) {
      gmc!.animateCamera(CameraUpdate.newLatLng(LatLng(lat, lng)));
    }

    placemarks = await _addressLookupService.lookup(lat, lng);
    if (!mounted) return;
    setState(() {});
  }

  // void _onMapTap(LatLng latLng) {
  //   if (_debounce?.isActive ?? false) _debounce!.cancel();
  //   _debounce = Timer(const Duration(milliseconds: 300), () {
  //     _updateLocation(latLng.latitude, latLng.longitude);
  //   });
  // }

  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AddressController>().initialAddressDetails();
      context.read<AddressController>().getAddressDetails(id: widget.args.id).then((value) {
        currentLat = double.parse(widget.args.lat);
        currentLng = double.parse(widget.args.lng);
      });
    });
    _determinePosition();
    _country = CountryParser.parsePhoneCode('20');
    _areaNameEc.text = widget.args.areaName;
    _apartmentNoEc.text = widget.args.apartmentNo;
    _floorNoEc.text = widget.args.floorNo;
    _streetNameEc.text = widget.args.streetName;
    _mobileEc.text = widget.args.mobile;
    _badgeEc.text = widget.args.badge;
    _addressNameEc.text = widget.args.addressName;
    typeAddress = widget.args.type;

    super.initState();
  }

  @override
  dispose() {
    positionStream?.cancel();
    _debounce?.cancel();
    _areaNameEc.dispose();
    _apartmentNoEc.dispose();
    _floorNoEc.dispose();
    _streetNameEc.dispose();
    _mobileEc.dispose();
    _badgeEc.dispose();
    _addressNameEc.dispose();

    _areaNameFocusNode.dispose();
    _apartmentNoFocusNode.dispose();
    _floorNoFocusNode.dispose();
    _streetNameFocusNode.dispose();
    _badgeFocusNode.dispose();
    _mobileFocusNode.dispose();
    _addressNameFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AddressController>(
      builder: (context, addressController, _) {
        return Scaffold(
          body: ApiResponseWidget(
            apiResponse: addressController.addressDetailsResponse,
            onReload: () => addressController.getAddressDetails(id: widget.args.id),
            isEmpty: addressController.addressDetails == null,
            child: PageContainer(
              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      30.sbH,
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: Row(
                          children: [
                            IconButton(
                              onPressed: () => Navigator.pop(context),
                              icon: SvgPicture.asset(AppImages.backIosIcon),
                            ),
                            Text('addresses'.tr, style: AppTextStyle.text18BS()),
                          ],
                        ),
                      ),
                      32.sbH,
                      Container(
                        decoration: BoxDecoration(
                          color: AppColors.whiteColor,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(34),
                            topRight: Radius.circular(34),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.greyColor.withValues(alpha: 0.2),
                              offset: const Offset(0, -3),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Provider.of<AuthController>(context).profile?.gender == 'male'
                                          ? SvgPicture.asset(AppImages.avatarMale)
                                          : Provider.of<AuthController>(context).profile?.gender == 'female'
                                              ? SvgPicture.asset(AppImages.avatarFemale)
                                              : Container(
                                                  height: 20,
                                                  width: 20,
                                                  decoration: BoxDecoration(
                                                    color: AppColors.mainAppColor,
                                                    shape: BoxShape.circle,
                                                  ),
                                                  child: Center(
                                                    child: Text(
                                                      Provider.of<AuthController>(context)
                                                              .profile
                                                              ?.name
                                                              ?.substring(0, 1) ??
                                                          '',
                                                      style: AppTextStyle.text18BW().copyWith(fontSize: 40),
                                                    ),
                                                  ),
                                                ),
                                      const SizedBox(width: 10),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            Provider.of<AuthController>(context).profile?.name ?? '',
                                            style: AppTextStyle.text18MS(),
                                          ),
                                          5.sbH,
                                          Row(
                                            children: [
                                              SvgPicture.asset(AppImages.egyptIcon),
                                              const SizedBox(width: 10),
                                              Text(
                                                Provider.of<AuthController>(context).profile?.areaTitle ?? '',
                                                style: AppTextStyle.text16RG(),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const Divider(),
                            // this column for add address
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                              child: Column(
                                // this column for add address
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 10),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(25),
                                      child: SizedBox(
                                        height: context.height * 0.5,
                                        child: currentLat != null && currentLng != null
                                            ? GoogleMap(
                                                onTap: (m) {
                                                  NamedNavigatorImpl.push(
                                                    MapScreen.routeName,
                                                    arguments: MapScreenArgs(
                                                      onBack: (lat, lng) {
                                                        _updateLocation(lat, lng);
                                                      },
                                                    ),
                                                  );
                                                },
                                                markers: markers,
                                                mapType: MapType.normal,
                                                onMapCreated: (GoogleMapController controller) {
                                                  gmc = controller;
                                                  if (addressController.addressDetails != null) {
                                                    gmc!.animateCamera(
                                                      CameraUpdate.newLatLng(LatLng(currentLat!, currentLng!)),
                                                    );
                                                  }
                                                },
                                                initialCameraPosition: CameraPosition(
                                                  target: LatLng(currentLat!, currentLng!),
                                                  zoom: 12,
                                                ),
                                              )
                                            : const Center(child: CustomLoading()),
                                      ),
                                    ),
                                  ),
                                  20.sbH,
                                  10.sbH,
                                  ApiResponseWidget(
                                    apiResponse: addressController.addressDetailsResponse,
                                    loadingSize: 20,
                                    onReload: () => addressController.getAddressDetails(id: widget.args.id),
                                    isEmpty: addressController.addressDetails == null,
                                    child: ChangeAddressWidget(
                                      addressController: addressController,
                                      placemarks: placemarks,
                                    ),
                                  ),
                                  15.sbH,
                                  TypeAddressWidget(typeAddressFormUpdate: typeAddress),
                                  16.sbH,
                                  CustomFormField(
                                    controller: _areaNameEc,
                                    validator: validateEmptyField,
                                    hintText: 'buildingName'.tr,
                                    focusNode: _areaNameFocusNode,
                                    onFieldSubmitted: (_) {
                                      FocusScope.of(context).requestFocus(_apartmentNoFocusNode);
                                    },
                                  ),
                                  16.sbH,
                                  Row(
                                    children: [
                                      Expanded(
                                        child: CustomFormField(
                                          controller: _apartmentNoEc,
                                          validator: validateEmptyField,
                                          keyboardType: TextInputType.number,
                                          hintText: 'apartmentNumber'.tr,
                                          focusNode: _apartmentNoFocusNode,
                                          onFieldSubmitted: (_) {
                                            FocusScope.of(context).requestFocus(_floorNoFocusNode);
                                          },
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: CustomFormField(
                                          controller: _floorNoEc,
                                          validator: validateEmptyField,
                                          keyboardType: TextInputType.number,
                                          hintText: 'theRoleIsOptional'.tr,
                                          focusNode: _floorNoFocusNode,
                                          onFieldSubmitted: (_) {
                                            FocusScope.of(context).requestFocus(_streetNameFocusNode);
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                  16.sbH,
                                  CustomFormField(
                                    controller: _streetNameEc,
                                    validator: validateEmptyField,
                                    hintText: 'street'.tr,
                                    focusNode: _streetNameFocusNode,
                                    onFieldSubmitted: (_) {
                                      FocusScope.of(context).requestFocus(_badgeFocusNode);
                                    },
                                  ),
                                  16.sbH,
                                  CustomFormField(
                                    controller: _badgeEc,
                                    hintText: 'optionalDistinctiveSign'.tr,
                                    focusNode: _badgeFocusNode,
                                    onFieldSubmitted: (_) {
                                      FocusScope.of(context).requestFocus(_mobileFocusNode);
                                    },
                                  ),
                                  16.sbH,
                                  CustomFormField(
                                    validator: (v) => validatePhone(v, country: _country),
                                    controller: _mobileEc,
                                    keyboardType: TextInputType.number,
                                    hintText: 'mobileNumber'.tr,
                                    country: _country,
                                    focusNode: _mobileFocusNode,
                                    onFieldSubmitted: (_) {
                                      FocusScope.of(context).requestFocus(_addressNameFocusNode);
                                    },
                                  ),
                                  16.sbH,
                                  CustomFormField(
                                    controller: _addressNameEc,
                                    hintText: 'titleLabelIsOptional'.tr,
                                    focusNode: _addressNameFocusNode,
                                  ),
                                  15.sbH,
                                  Builder(
                                    builder: (context) {
                                      return CustomButton(
                                        onPressed: () {
                                          log(widget.args.id.toString());
                                          log(_areaNameEc.text);
                                          log(_apartmentNoEc.text);
                                          log(_floorNoEc.text);
                                          log(_streetNameEc.text);
                                          log(_mobileEc.text);
                                          log(_addressNameEc.text);

                                          if (_formKey.currentState!.validate()) {
                                            context.read<AddressController>().updateAddress(
                                                  id: widget.args.id,
                                                  areaName: _areaNameEc.text,
                                                  apartmentNo: _apartmentNoEc.text,
                                                  floorNo: _floorNoEc.text,
                                                  streetName: _streetNameEc.text,
                                                  mobile: _mobileEc.text,
                                                  addressName: _addressNameEc.text,
                                                  type: addressController.indexSelectedOfficeOrHouseOrApartment ==
                                                          'office'
                                                      ? 'office'
                                                      : addressController.indexSelectedOfficeOrHouseOrApartment ==
                                                              'home'
                                                          ? 'home'
                                                          : 'apartment',
                                                  lat: currentLat ??
                                                      double.parse(
                                                          addressController.addressDetails?.lat.toString() ?? '0'),
                                                  lang: currentLng ??
                                                      double.parse(
                                                          addressController.addressDetails?.lng.toString() ?? '0'),
                                                  countryName: placemarks![0].country ??
                                                      addressController.addressDetails?.countryName ??
                                                      '',
                                                  cityName: placemarks![0].locality ??
                                                      addressController.addressDetails?.cityName ??
                                                      '',
                                                  address: placemarks![0].street ??
                                                      addressController.addressDetails?.address ??
                                                      '',
                                                  onSuccess: () {
                                                    widget.args.onSuccess!.call();
                                                    context.read<AuthController>().getProfile();
                                                    Navigator.pop(context);
                                                  },
                                                );
                                          }
                                        },
                                        text: 'saveChanges'.tr,
                                      );
                                    },
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
            ),
          ),
        );
      },
    );
  }
}
