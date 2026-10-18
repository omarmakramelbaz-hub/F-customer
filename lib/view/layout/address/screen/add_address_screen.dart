import 'dart:developer';

import 'package:country_picker/country_picker.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';

import '../../../../helpers/routes/app_routers_import.dart';
import '../../../../helpers/theme/app_colors.dart';
import '../../../../helpers/translation/all_translation.dart';
import '../../../../helpers/utils/address_lookup_service.dart';
import '../../../../helpers/utils/common_methods.dart';
import '../../../../helpers/utils/location_service.dart';
import '../../../custom_widgets/validation/validation_mixin.dart';
import '../../auth/controller/auth_controller.dart';
import '../controller/address_controller.dart';
import 'map_screen.dart';

class AddAddressArgs {
  final VoidCallback onSuccess;

  AddAddressArgs({required this.onSuccess});
}

class AddAddressScreen extends StatefulWidget {
  final AddAddressArgs args;
  static const String routeName = 'AddAddressScreen';

  const AddAddressScreen({super.key, required this.args});

  @override
  State<AddAddressScreen> createState() => _AddAddressScreenState();
}

class _AddAddressScreenState extends State<AddAddressScreen>
    with ValidationMixin {
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

  Country? _country;
  List<Placemark>? placemarks;
  double? currentLat;
  double? currentLng;
  GoogleMapController? gmc;

  final LocationService _locationService = LocationService();
  final AddressLookupService _addressLookupService = AddressLookupService();

  static const _text = Color(0xFF171A1F);
  static const _muted = Color(0xFF858B94);
  static const _border = Color(0xFFE7EAEE);
  static const _softOrange = Color(0xFFFFF3E7);

  bool _isArabic(BuildContext context) => context.languageCode == 'ar';

  @override
  void initState() {
    super.initState();
    _setupLocationListeners();
    _determinePosition();
  }

  void _setupLocationListeners() {
    _locationService.listenToLocation((locationData) {
      if (locationData.latitude != null && locationData.longitude != null) {
        _updateLocation(locationData.latitude!, locationData.longitude!);
      }
    });
  }

  Future<void> _determinePosition() async {
    try {
      final location = await _locationService.getCurrentLocation();
      if (location?.latitude != null && location?.longitude != null) {
        await _updateLocation(location!.latitude!, location.longitude!);
      }
    } catch (e) {
      log('Failed to get address location: $e');
    }
  }

  Future<void> _updateLocation(double lat, double lng) async {
    if (!mounted) return;

    setState(() {
      currentLat = lat;
      currentLng = lng;
    });

    if (gmc != null) {
      try {
        await gmc!.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(target: LatLng(lat, lng), zoom: 14.5),
          ),
        );
      } catch (e) {
        log('Failed to move add-address map: $e');
      }
    }

    if (!mounted) return;
    try {
      final result = await _addressLookupService.lookup(lat, lng);
      if (!mounted) return;
      setState(() => placemarks = result);
    } catch (e) {
      log('Address reverse geocoding failed: $e');
    }
  }

  void _openMapPicker() {
    FocusManager.instance.primaryFocus?.unfocus();
    NamedNavigatorImpl.push(
      MapScreen.routeName,
      arguments: MapScreenArgs(
        onBack: (lat, lng) {
          _locationService.pauseLocationStream();
          _updateLocation(lat, lng);
        },
      ),
    );
  }

  @override
  void dispose() {
    _locationService.dispose();
    gmc?.dispose();

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
    return ChangeNotifierProvider(
      create: (_) => AddressController(),
      child: Consumer<AddressController>(
        builder: (context, addressController, _) {
          final isArabic = _isArabic(context);

          return Directionality(
            textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
            child: Scaffold(
              resizeToAvoidBottomInset: true,
              backgroundColor: const Color(0xFFF7F8FA),
              appBar: _buildAppBar(context),
              body: SafeArea(
                top: false,
                child: Form(
                  key: _formKey,
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final keyboardOpen =
                          MediaQuery.of(context).viewInsets.bottom > 0;
                      final compact = constraints.maxHeight < 760;
                      final mapHeight = keyboardOpen
                          ? 0.0
                          : (constraints.maxHeight * 0.23)
                              .clamp(compact ? 120.0 : 150.0, 190.0)
                              .toDouble();

                      return Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 620),
                          child: Padding(
                            padding: EdgeInsets.fromLTRB(
                              12,
                              compact ? 7 : 10,
                              12,
                              compact ? 7 : 10,
                            ),
                            child: Column(
                              children: [
                                if (!keyboardOpen) ...[
                                  _intro(context, compact),
                                  SizedBox(height: compact ? 6 : 8),
                                  _mapCard(context, height: mapHeight),
                                  SizedBox(height: compact ? 6 : 8),
                                ] else ...[
                                  _compactLocationBar(context),
                                  const SizedBox(height: 5),
                                ],
                                _typeSelector(
                                  context,
                                  addressController,
                                  compact: compact || keyboardOpen,
                                ),
                                SizedBox(height: compact ? 5 : 7),
                                Expanded(
                                  child: _formGrid(
                                    context,
                                    compact: compact || keyboardOpen,
                                  ),
                                ),
                                SizedBox(height: compact ? 5 : 7),
                                _saveButton(
                                  context,
                                  addressController,
                                  compact: compact || keyboardOpen,
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    final isArabic = _isArabic(context);

    return AppBar(
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: Colors.white,
      automaticallyImplyLeading: false,
      toolbarHeight: 58,
      titleSpacing: 12,
      title: Row(
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => NamedNavigatorImpl.pop(),
              borderRadius: BorderRadius.circular(22),
              child: SizedBox(
                width: 42,
                height: 42,
                child: Icon(
                  isArabic
                      ? Icons.arrow_forward_rounded
                      : Icons.arrow_back_rounded,
                  color: AppColors.mainAppColor,
                  size: 25,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            isArabic ? 'إضافة عنوان' : 'Add address',
            style: const TextStyle(
              color: _text,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _intro(BuildContext context, bool compact) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: 11,
        vertical: compact ? 7 : 9,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
      ),
      child: Row(
        children: [
          Container(
            width: compact ? 36 : 40,
            height: compact ? 36 : 40,
            decoration: BoxDecoration(
              color: _softOrange,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.location_on_outlined,
              color: AppColors.mainAppColor,
              size: compact ? 20 : 22,
            ),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isArabic(context)
                      ? 'حدد موقع العنوان وأكمل البيانات'
                      : 'Set the location and complete the details',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: _text,
                    fontSize: compact ? 13.5 : 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _isArabic(context)
                      ? 'كل البيانات أمامك في شاشة واحدة'
                      : 'All details are available on one screen',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: _muted,
                    fontSize: compact ? 9.5 : 10.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _mapCard(BuildContext context, {required double height}) {
    return Container(
      height: height,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: currentLat == null || currentLng == null
          ? Center(
              child: CircularProgressIndicator(
                color: AppColors.mainAppColor,
                strokeWidth: 2.3,
              ),
            )
          : Stack(
              children: [
                Positioned.fill(
                  child: GoogleMap(
                    initialCameraPosition: CameraPosition(
                      target: LatLng(currentLat!, currentLng!),
                      zoom: 14.5,
                    ),
                    markers: {
                      Marker(
                        markerId: const MarkerId('addressLocation'),
                        position: LatLng(currentLat!, currentLng!),
                        icon: BitmapDescriptor.defaultMarkerWithHue(
                          BitmapDescriptor.hueOrange,
                        ),
                      ),
                    },
                    zoomControlsEnabled: false,
                    myLocationButtonEnabled: false,
                    compassEnabled: false,
                    mapToolbarEnabled: false,
                    onTap: (_) => _openMapPicker(),
                    onMapCreated: (controller) => gmc = controller,
                  ),
                ),
                PositionedDirectional(
                  top: 8,
                  start: 8,
                  child: _mapHint(context),
                ),
                PositionedDirectional(
                  start: 8,
                  end: 8,
                  bottom: 8,
                  child: _locationInfo(context),
                ),
              ],
            ),
    );
  }

  Widget _mapHint(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(.96),
        borderRadius: BorderRadius.circular(11),
        boxShadow: const [
          BoxShadow(
            color: Color(0x10000000),
            blurRadius: 7,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.touch_app_outlined,
            size: 15,
            color: AppColors.mainAppColor,
          ),
          const SizedBox(width: 5),
          Text(
            _isArabic(context) ? 'اضغط لتعديل الموقع' : 'Tap to adjust location',
            style: const TextStyle(
              color: _text,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _locationInfo(BuildContext context) {
    return Container(
      height: 38,
      padding: const EdgeInsets.symmetric(horizontal: 9),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(.97),
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Color(0x10000000),
            blurRadius: 7,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(
            Icons.location_on_rounded,
            color: AppColors.mainAppColor,
            size: 17,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              _resolvedAddress(context),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: _text,
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (currentLat != null && currentLng != null) ...[
            const SizedBox(width: 6),
            Text(
              '${currentLat!.toStringAsFixed(4)}, ${currentLng!.toStringAsFixed(4)}',
              style: const TextStyle(
                color: _muted,
                fontSize: 8.5,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _compactLocationBar(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(13),
      child: InkWell(
        onTap: _openMapPicker,
        borderRadius: BorderRadius.circular(13),
        child: Container(
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(13),
            border: Border.all(color: _border),
          ),
          child: Row(
            children: [
              Icon(
                Icons.location_on_outlined,
                color: AppColors.mainAppColor,
                size: 18,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  _resolvedAddress(context),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _text,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Icon(
                Icons.edit_location_alt_outlined,
                color: AppColors.mainAppColor,
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _typeSelector(
    BuildContext context,
    AddressController controller, {
    required bool compact,
  }) {
    return Row(
      children: [
        Expanded(
          child: _typeOption(
            context,
            controller,
            value: 'office',
            label: _isArabic(context) ? 'شقة' : 'Apartment',
            icon: Icons.apartment_rounded,
            compact: compact,
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: _typeOption(
            context,
            controller,
            value: 'home',
            label: _isArabic(context) ? 'منزل' : 'Home',
            icon: Icons.home_outlined,
            compact: compact,
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: _typeOption(
            context,
            controller,
            value: 'apartment',
            label: _isArabic(context) ? 'مكتب' : 'Office',
            icon: Icons.business_center_outlined,
            compact: compact,
          ),
        ),
      ],
    );
  }

  Widget _typeOption(
    BuildContext context,
    AddressController controller, {
    required String value,
    required String label,
    required IconData icon,
    required bool compact,
  }) {
    final selected =
        controller.indexSelectedOfficeOrHouseOrApartment == value;

    return Material(
      color: selected ? _softOrange : Colors.white,
      borderRadius: BorderRadius.circular(13),
      child: InkWell(
        onTap: () =>
            controller.setIndexSelectedOfficeOrHouseOrApartment(value),
        borderRadius: BorderRadius.circular(13),
        child: Container(
          height: compact ? 38 : 42,
          padding: const EdgeInsets.symmetric(horizontal: 7),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(13),
            border: Border.all(
              color: selected ? AppColors.mainAppColor : _border,
              width: selected ? 1.2 : 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: compact ? 16 : 18,
                color: selected ? AppColors.mainAppColor : _muted,
              ),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: selected ? AppColors.mainAppColor : _text,
                    fontSize: compact ? 10.5 : 11.5,
                    fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _formGrid(BuildContext context, {required bool compact}) {
    final gap = compact ? 5.0 : 7.0;

    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        _fieldRow(
          _field(
            controller: _areaNameEc,
            focusNode: _areaNameFocusNode,
            hint: 'buildingName'.tr,
            icon: Icons.domain_outlined,
            validator: validateEmptyField,
            compact: compact,
            onSubmitted: (_) =>
                FocusScope.of(context).requestFocus(_streetNameFocusNode),
          ),
          _field(
            controller: _streetNameEc,
            focusNode: _streetNameFocusNode,
            hint: 'street'.tr,
            icon: Icons.signpost_outlined,
            validator: validateEmptyField,
            compact: compact,
            onSubmitted: (_) =>
                FocusScope.of(context).requestFocus(_apartmentNoFocusNode),
          ),
          gap,
        ),
        _fieldRow(
          _field(
            controller: _apartmentNoEc,
            focusNode: _apartmentNoFocusNode,
            hint: 'apartmentNumber'.tr,
            icon: Icons.door_front_door_outlined,
            keyboardType: TextInputType.number,
            validator: validateEmptyField,
            compact: compact,
            onSubmitted: (_) =>
                FocusScope.of(context).requestFocus(_floorNoFocusNode),
          ),
          _field(
            controller: _floorNoEc,
            focusNode: _floorNoFocusNode,
            hint: 'theRoleIsOptional'.tr,
            icon: Icons.stairs_outlined,
            keyboardType: TextInputType.number,
            validator: validateEmptyField,
            compact: compact,
            onSubmitted: (_) =>
                FocusScope.of(context).requestFocus(_mobileFocusNode),
          ),
          gap,
        ),
        _fieldRow(
          _field(
            controller: _mobileEc,
            focusNode: _mobileFocusNode,
            hint: 'mobileNumber'.tr,
            icon: Icons.phone_outlined,
            keyboardType: TextInputType.phone,
            validator: (value) => validatePhone(value, country: _country),
            compact: compact,
            onSubmitted: (_) =>
                FocusScope.of(context).requestFocus(_addressNameFocusNode),
          ),
          _field(
            controller: _addressNameEc,
            focusNode: _addressNameFocusNode,
            hint: 'titleLabelIsOptional'.tr,
            icon: Icons.bookmark_border_rounded,
            compact: compact,
            onSubmitted: (_) =>
                FocusScope.of(context).requestFocus(_badgeFocusNode),
          ),
          gap,
        ),
        _field(
          controller: _badgeEc,
          focusNode: _badgeFocusNode,
          hint: 'optionalDistinctiveSign'.tr,
          icon: Icons.near_me_outlined,
          compact: compact,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => FocusManager.instance.primaryFocus?.unfocus(),
        ),
      ],
    );
  }

  Widget _fieldRow(Widget first, Widget second, double gap) {
    return Padding(
      padding: EdgeInsets.only(bottom: gap),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: first),
          SizedBox(width: gap),
          Expanded(child: second),
        ],
      ),
    );
  }

  Widget _field({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String hint,
    required IconData icon,
    required bool compact,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    TextInputAction? textInputAction,
    ValueChanged<String>? onSubmitted,
  }) {
    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      validator: validator,
      keyboardType: keyboardType,
      textInputAction: textInputAction ?? TextInputAction.next,
      onFieldSubmitted: onSubmitted,
      onTapOutside: (_) => FocusManager.instance.primaryFocus?.unfocus(),
      style: TextStyle(
        color: _text,
        fontSize: compact ? 11.5 : 12.5,
        fontWeight: FontWeight.w600,
      ),
      decoration: InputDecoration(
        isDense: true,
        hintText: hint,
        hintStyle: TextStyle(
          color: _muted,
          fontSize: compact ? 10.5 : 11.5,
          fontWeight: FontWeight.w400,
        ),
        prefixIcon: Icon(
          icon,
          size: compact ? 16 : 18,
          color: const Color(0xFF9AA0A8),
        ),
        prefixIconConstraints: BoxConstraints(
          minWidth: compact ? 34 : 38,
          minHeight: compact ? 38 : 42,
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: EdgeInsets.symmetric(
          horizontal: 9,
          vertical: compact ? 9 : 11,
        ),
        errorStyle: const TextStyle(fontSize: 8, height: .85),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
          borderSide: const BorderSide(color: _border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
          borderSide: BorderSide(color: AppColors.mainAppColor, width: 1.3),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
          borderSide: const BorderSide(color: Color(0xFFE35B5B)),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
          borderSide: const BorderSide(color: Color(0xFFE35B5B)),
        ),
      ),
    );
  }

  Widget _saveButton(
    BuildContext context,
    AddressController addressController, {
    required bool compact,
  }) {
    return SizedBox(
      width: double.infinity,
      height: compact ? 46 : 50,
      child: ElevatedButton(
        onPressed: () => _saveAddress(context, addressController),
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: AppColors.mainAppColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
        child: Text(
          _isArabic(context) ? 'حفظ العنوان' : 'Save address',
          style: TextStyle(
            fontSize: compact ? 14.5 : 15.5,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }

  void _saveAddress(
    BuildContext context,
    AddressController addressController,
  ) {
    FocusManager.instance.primaryFocus?.unfocus();
    if (!_formKey.currentState!.validate()) return;

    final fallback = addressController.addressDetails;
    final lat = currentLat ?? double.tryParse('${fallback?.lat ?? ''}');
    final lng = currentLng ?? double.tryParse('${fallback?.lng ?? ''}');

    if (lat == null || lng == null || lat == 0 || lng == 0) {
      CommonMethods.showError(
        message: _isArabic(context)
            ? 'من فضلك حدد موقع العنوان على الخريطة أولاً'
            : 'Please select the address location on the map first',
      );
      return;
    }

    final place = placemarks?.isNotEmpty == true ? placemarks!.first : null;
    final mapStreet = (place?.street ?? '').trim();

    context.read<AddressController>().storeAddress(
          areaName: _areaNameEc.text.trim(),
          apartmentNo: _apartmentNoEc.text.trim(),
          floorNo: _floorNoEc.text.trim(),
          streetName: _streetNameEc.text.trim(),
          mobile: _mobileEc.text.trim(),
          addressName: _addressNameEc.text.trim(),
          type: addressController.indexSelectedOfficeOrHouseOrApartment,
          lat: lat,
          lang: lng,
          countryName: place?.country ?? fallback?.countryName ?? '',
          cityName: place?.locality ?? fallback?.cityName ?? '',
          address: mapStreet.isNotEmpty
              ? mapStreet
              : (fallback?.address ?? _streetNameEc.text.trim()),
          badge: _badgeEc.text.trim(),
          onSuccess: ({int? userAddressId}) {
            NamedNavigatorImpl.pop();
            context.read<AuthController>().getProfile();
            widget.args.onSuccess.call();
          },
        );
  }

  String _resolvedAddress(BuildContext context) {
    final place = placemarks?.isNotEmpty == true ? placemarks!.first : null;
    final parts = <String>[];

    final street = (place?.street ?? '').trim();
    final subLocality = (place?.subLocality ?? '').trim();
    final locality = (place?.locality ?? '').trim();

    if (street.isNotEmpty) parts.add(street);
    if (subLocality.isNotEmpty && !parts.contains(subLocality)) {
      parts.add(subLocality);
    }
    if (locality.isNotEmpty && !parts.contains(locality)) {
      parts.add(locality);
    }

    if (parts.isNotEmpty) return parts.join('، ');

    if (currentLat != null && currentLng != null) {
      return '${currentLat!.toStringAsFixed(5)}, ${currentLng!.toStringAsFixed(5)}';
    }

    return _isArabic(context)
        ? 'جاري تحديد موقعك...'
        : 'Locating your address...';
  }
}
