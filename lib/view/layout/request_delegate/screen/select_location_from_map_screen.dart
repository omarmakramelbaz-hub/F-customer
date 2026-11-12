import 'package:faskhaninja/helpers/theme/fasakhansta_brand.dart';

import 'dart:async';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';

import '../../../../helpers/extensions/extensions.dart';
import '../../../../helpers/theme/app_colors.dart';
import '../controller/request_delegate_controller.dart';

class SelectLocationFromMapScreenArgs {
  final bool isFromAddress;

  SelectLocationFromMapScreenArgs({required this.isFromAddress});
}

class SelectLocationFromMapScreen extends StatefulWidget {
  static const routeName = 'SelectLocationFromMapScreen';
  final SelectLocationFromMapScreenArgs? args;

  const SelectLocationFromMapScreen({super.key, this.args});

  @override
  State<SelectLocationFromMapScreen> createState() =>
      _SelectLocationFromMapScreenState();
}

class _SelectLocationFromMapScreenState
    extends State<SelectLocationFromMapScreen> with WidgetsBindingObserver {
  GoogleMapController? gmc;
  Timer? _debounce;
  List<Placemark>? placemarks;
  double? currentLat;
  double? currentLng;
  bool isCheckingLocation = false;
  bool isConfirmingLocation = false;

  static const _text = FasakhanstaBrand.text;
  static const _muted = FasakhanstaBrand.muted;
  static const _border = FasakhanstaBrand.border;
  static const _softOrange = FasakhanstaBrand.orangeTint;

  bool _isArabic(BuildContext context) => context.languageCode == 'ar';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialLocation();
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _loadInitialLocation() async {
    final controller = Provider.of<RequestDelegateController>(
      context,
      listen: false,
    );
    final isFrom = widget.args?.isFromAddress == true;

    if (isFrom) {
      // Pickup should always start from the user's real device location.
      // Keep the saved pickup only as a fallback if GPS is unavailable.
      await _determinePosition();
      if (currentLat != null && currentLng != null) return;

      final savedLat = double.tryParse(controller.fromLat ?? '');
      final savedLng = double.tryParse(controller.fromLan ?? '');
      if (savedLat != null && savedLng != null) {
        await _updateLocation(savedLat, savedLng, updateController: false);
      }
      return;
    }

    // When editing an already selected destination, keep that point.
    final savedToLat = double.tryParse(controller.toLat ?? '');
    final savedToLng = double.tryParse(controller.toLan ?? '');
    if (savedToLat != null && savedToLng != null) {
      await _updateLocation(savedToLat, savedToLng, updateController: false);
      return;
    }

    // A new destination map should open around the user's pickup/current
    // location so the customer starts from the right area automatically.
    final pickupLat = double.tryParse(controller.fromLat ?? '');
    final pickupLng = double.tryParse(controller.fromLan ?? '');
    if (pickupLat != null && pickupLng != null) {
      await _updateLocation(pickupLat, pickupLng, updateController: false);
      return;
    }

    await _determinePosition();
  }

  Future<void> _determinePosition() async {
    if (!mounted) return;
    setState(() => isCheckingLocation = true);

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        await Geolocator.openLocationSettings();
        serviceEnabled = await Geolocator.isLocationServiceEnabled();
        if (!serviceEnabled) return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.unableToDetermine) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        log('Location permission denied');
        return;
      }

      final position = await Geolocator.getCurrentPosition();
      await _updateLocation(
        position.latitude,
        position.longitude,
        updateController: false,
      );
    } catch (e) {
      log('Failed to get location: $e');
    } finally {
      if (mounted) setState(() => isCheckingLocation = false);
    }
  }

  Future<void> _updateLocation(
    double lat,
    double lng, {
    bool updateController = true,
  }) async {
    if (!mounted) return;

    setState(() {
      currentLat = lat;
      currentLng = lng;
    });

    if (updateController) {
      _applyCoordinatesToController(lat, lng);
    }

    if (gmc != null) {
      await gmc!.animateCamera(CameraUpdate.newLatLng(LatLng(lat, lng)));
    }

    try {
      final result = await placemarkFromCoordinates(lat, lng);
      if (!mounted) return;
      setState(() => placemarks = result);
    } catch (e) {
      log('Reverse geocoding failed: $e');
    }
  }

  void _applyCoordinatesToController(double lat, double lng) {
    final controller = Provider.of<RequestDelegateController>(
      context,
      listen: false,
    );
    final point = LatLng(lat, lng);

    if (widget.args?.isFromAddress == true) {
      controller.setFromLat(lat.toString());
      controller.setFromLan(lng.toString());
      controller.setFromLatLng(point);
    } else {
      controller.setToLat(lat.toString());
      controller.setToLan(lng.toString());
      controller.setToLatLng(point);
    }
  }

  void _onMapTap(LatLng point) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 180), () {
      _updateLocation(point.latitude, point.longitude, updateController: false);
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && currentLat == null) {
      _determinePosition();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<RequestDelegateController>(
      builder: (context, controller, _) {
        return Directionality(
          textDirection:
              _isArabic(context) ? TextDirection.rtl : TextDirection.ltr,
          child: Scaffold(
            backgroundColor: Colors.transparent,
            body: currentLat == null || currentLng == null
                ? _loadingState(context)
                : Stack(
                    children: [
                      Positioned.fill(
                        child: GoogleMap(
                          mapType: MapType.normal,
                          zoomControlsEnabled: false,
                          myLocationButtonEnabled: false,
                          compassEnabled: false,
                          mapToolbarEnabled: false,
                          onTap: _onMapTap,
                          markers: {
                            Marker(
                              markerId: const MarkerId('selectedLocation'),
                              position: LatLng(currentLat!, currentLng!),
                              icon: BitmapDescriptor.defaultMarkerWithHue(
                                BitmapDescriptor.hueOrange,
                              ),
                            ),
                          },
                          initialCameraPosition: CameraPosition(
                            target: LatLng(currentLat!, currentLng!),
                            zoom: 13.5,
                          ),
                          onMapCreated: (mapController) {
                            gmc = mapController;
                          },
                        ),
                      ),
                      Positioned(
                        top: MediaQuery.of(context).padding.top + 10,
                        left: 14,
                        child: _roundButton(
                          icon: Icons.arrow_back_rounded,
                          onTap: () => Navigator.of(context).pop(),
                        ),
                      ),
                      Positioned(
                        top: MediaQuery.of(context).padding.top + 10,
                        left: 76,
                        right: 76,
                        child: Container(
                          height: 48,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: FasakhanstaBrand.surface,
                            borderRadius: BorderRadius.circular(18),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x16000000),
                                blurRadius: 16,
                                offset: Offset(0, 5),
                              ),
                            ],
                          ),
                          child: Text(
                            _isArabic(context)
                                ? 'اختر موقعك على الخريطة'
                                : 'Choose location on map',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: _text,
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        right: 14,
                        bottom: 270,
                        child: Column(
                          children: [
                            _roundButton(
                              icon: Icons.my_location_rounded,
                              onTap: _determinePosition,
                            ),
                            const SizedBox(height: 10),
                            _zoomButtons(),
                          ],
                        ),
                      ),
                      Align(
                        alignment: Alignment.bottomCenter,
                        child: _detailsSheet(context, controller),
                      ),
                    ],
                  ),
          ),
        );
      },
    );
  }

  Widget _loadingState(BuildContext context) {
    return SafeArea(
      child: Stack(
        children: [
          Center(
            child: CircularProgressIndicator(
              color: AppColors.mainAppColor,
              strokeWidth: 2.6,
            ),
          ),
          Positioned(
            top: 10,
            left: 14,
            child: _roundButton(
              icon: Icons.arrow_back_rounded,
              onTap: () => Navigator.of(context).pop(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _detailsSheet(
    BuildContext context,
    RequestDelegateController controller,
  ) {
    final address = _formattedAddress();
    final coords = currentLat != null && currentLng != null
        ? '${currentLat!.toStringAsFixed(5)}, ${currentLng!.toStringAsFixed(5)}'
        : '';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 9, 16, 16),
      decoration: const BoxDecoration(
        color: FasakhanstaBrand.surface,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x1A000000),
            blurRadius: 24,
            offset: Offset(0, -6),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: FasakhanstaBrand.surfaceRaised,
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: _softOrange,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    Icons.location_on_outlined,
                    color: AppColors.mainAppColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _isArabic(context)
                            ? 'الموقع المحدد'
                            : 'Selected location',
                        style: const TextStyle(
                          color: _text,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        address,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: FasakhanstaBrand.muted,
                          fontSize: 12,
                          height: 1.4,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        coords,
                        style: const TextStyle(
                          color: _muted,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: FasakhanstaBrand.surfaceRaised,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _border),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.touch_app_outlined,
                    size: 19,
                    color: AppColors.mainAppColor,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _isArabic(context)
                          ? 'اضغط على الخريطة لتحديد المكان بدقة، أو استخدم زر موقعي الحالي.'
                          : 'Tap the map to fine-tune the location or use the current-location button.',
                      style: const TextStyle(
                        color: FasakhanstaBrand.muted,
                        fontSize: 11,
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: currentLat == null ||
                        currentLng == null ||
                        isConfirmingLocation
                    ? null
                    : () => _confirmLocation(controller),
                style: ElevatedButton.styleFrom(
                  elevation: 0,
                  backgroundColor: AppColors.mainAppColor,
                  foregroundColor: FasakhanstaBrand.onOrange,
                  disabledBackgroundColor: const Color(0xFFFFC896),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(17),
                  ),
                ),
                child: isConfirmingLocation
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        _isArabic(context)
                            ? 'استخدام هذا الموقع'
                            : 'Use this location',
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _roundButton({required IconData icon, required VoidCallback onTap}) {
    return Material(
      color: FasakhanstaBrand.surface,
      shape: const CircleBorder(),
      elevation: 3,
      shadowColor: const Color(0x26000000),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 48,
          height: 48,
          child: Icon(icon, color: AppColors.mainAppColor, size: 23),
        ),
      ),
    );
  }

  Widget _zoomButtons() {
    return Container(
      decoration: BoxDecoration(
        color: FasakhanstaBrand.surface,
        borderRadius: BorderRadius.circular(15),
        boxShadow: const [
          BoxShadow(
            color: Color(0x19000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () => gmc?.animateCamera(CameraUpdate.zoomIn()),
            child: const SizedBox(
              width: 48,
              height: 44,
              child: Icon(Icons.add_rounded, color: _text),
            ),
          ),
          const SizedBox(width: 30, child: Divider(height: 1, color: _border)),
          InkWell(
            onTap: () => gmc?.animateCamera(CameraUpdate.zoomOut()),
            child: const SizedBox(
              width: 48,
              height: 44,
              child: Icon(Icons.remove_rounded, color: _text),
            ),
          ),
        ],
      ),
    );
  }

  String _formattedAddress() {
    if (placemarks == null || placemarks!.isEmpty) {
      return _isArabic(context)
          ? 'جاري تحديد العنوان...'
          : 'Locating address...';
    }

    return _formatPlacemark(placemarks!.first);
  }

  String _formatPlacemark(Placemark place) {
    final parts = <String>[
      if ((place.street ?? '').trim().isNotEmpty) place.street!.trim(),
      if ((place.subLocality ?? '').trim().isNotEmpty)
        place.subLocality!.trim(),
      if ((place.locality ?? '').trim().isNotEmpty) place.locality!.trim(),
      if ((place.administrativeArea ?? '').trim().isNotEmpty)
        place.administrativeArea!.trim(),
    ];

    return parts.toSet().join('، ');
  }

  Future<void> _confirmLocation(RequestDelegateController controller) async {
    if (currentLat == null || currentLng == null || isConfirmingLocation)
      return;

    final lat = currentLat!;
    final lng = currentLng!;

    setState(() => isConfirmingLocation = true);

    _applyCoordinatesToController(lat, lng);

    String address = '${lat.toStringAsFixed(5)}, ${lng.toStringAsFixed(5)}';

    try {
      final result = await placemarkFromCoordinates(lat, lng);
      if (result.isNotEmpty) {
        placemarks = result;
        final resolvedAddress = _formatPlacemark(result.first).trim();
        if (resolvedAddress.isNotEmpty) {
          address = resolvedAddress;
        }
      }
    } catch (e) {
      log('Reverse geocoding on confirm failed: $e');
    }

    if (!mounted) return;

    if (widget.args?.isFromAddress == true) {
      controller.setFromAddress(address);
      controller.setFromController(address);
    } else {
      controller.setToAddress(address);
      controller.setToController(address);
    }

    setState(() => isConfirmingLocation = false);
    Navigator.of(context).pop(true);
  }
}
