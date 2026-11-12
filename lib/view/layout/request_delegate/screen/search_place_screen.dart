import 'package:faskhaninja/helpers/theme/fasakhansta_brand.dart';

import 'dart:async';
import 'dart:developer';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../../../../helpers/extensions/extensions.dart';
import '../../../../helpers/routes/app_routers_import.dart';
import '../../../../helpers/theme/app_colors.dart';
import '../../address/model/address_model.dart';
import '../../address/screen/address_screen.dart';
import '../../map/model/place_autocomplete_model/place_autocomplete_model.dart';
import '../../map/utils/map_services.dart';
import '../../map/utils/places_autocomplete_bridge.dart';
import '../controller/request_delegate_controller.dart';
import 'select_location_from_map_screen.dart';

class SearchPlaceScreen extends StatefulWidget {
  static const routeName = 'SearchPlaceScreen';

  const SearchPlaceScreen({super.key});

  @override
  State<SearchPlaceScreen> createState() => _SearchPlaceScreenState();
}

class _SearchPlaceScreenState extends State<SearchPlaceScreen> {
  final fromFocusNode = FocusNode();
  final toFocusNode = FocusNode();

  late final MapServices mapServices;
  late final Uuid uuid;
  late RequestDelegateController requestDelegateController;

  Timer? _fromDebounce;
  Timer? _toDebounce;
  String? _fromSessionToken;
  String? _toSessionToken;

  List<PlaceModel> fromPlaces = [];
  List<PlaceModel> toPlaces = [];
  bool isFromFieldFocused = false;
  bool isToFieldFocused = false;
  bool isFromPredictionsLoading = false;
  bool isToPredictionsLoading = false;

  GoogleMapController? _routeMapController;
  Set<Polyline> _routePolylines = {};
  String? _routeSignature;
  bool _routeLoading = false;

  static const _text = FasakhanstaBrand.text;
  static const _muted = FasakhanstaBrand.muted;
  static const _border = FasakhanstaBrand.border;
  static const _softOrange = FasakhanstaBrand.orangeTint;

  bool _isArabic(BuildContext context) => context.languageCode == 'ar';

  @override
  void initState() {
    super.initState();
    mapServices = MapServices();
    uuid = const Uuid();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    requestDelegateController = Provider.of<RequestDelegateController>(
      context,
      listen: false,
    );

    if (requestDelegateController.fromController.text.isEmpty &&
        requestDelegateController.fromAddress.isNotEmpty) {
      requestDelegateController.fromController.text =
          requestDelegateController.fromAddress;
    }

    if (requestDelegateController.toController.text.isEmpty &&
        requestDelegateController.toAddress.isNotEmpty) {
      requestDelegateController.toController.text =
          requestDelegateController.toAddress;
    }
  }

  @override
  void dispose() {
    _fromDebounce?.cancel();
    _toDebounce?.cancel();
    _routeMapController?.dispose();
    fromFocusNode.dispose();
    toFocusNode.dispose();
    super.dispose();
  }

  void _onSearchChanged(bool isFrom) {
    final timer = isFrom ? _fromDebounce : _toDebounce;
    timer?.cancel();

    final nextTimer = Timer(const Duration(milliseconds: 280), () {
      _fetchPredictions(isFrom);
    });

    if (isFrom) {
      _fromDebounce = nextTimer;
    } else {
      _toDebounce = nextTimer;
    }
  }

  Future<void> _fetchPredictions(bool isFrom) async {
    if (!mounted) return;

    final controller = isFrom
        ? requestDelegateController.fromController
        : requestDelegateController.toController;
    final input = controller.text.trim();

    if (input.length < 2) {
      if (mounted) {
        setState(() {
          if (isFrom) {
            fromPlaces = [];
            isFromPredictionsLoading = false;
          } else {
            toPlaces = [];
            isToPredictionsLoading = false;
          }
        });
      }
      return;
    }

    setState(() {
      if (isFrom) {
        isFromPredictionsLoading = true;
      } else {
        isToPredictionsLoading = true;
      }
    });

    try {
      if (kIsWeb) {
        final results = await getWebPlacePredictions(
          input: input,
          countryCode: 'eg',
        );
        final mapped = results
            .map(
              (item) => PlaceModel(
                description: item.description,
                placeId: item.placeId,
              ),
            )
            .toList();

        if (!mounted) return;
        setState(() {
          if (isFrom) {
            fromPlaces = mapped;
          } else {
            toPlaces = mapped;
          }
        });
      } else {
        final places = isFrom ? fromPlaces : toPlaces;
        final token = isFrom
            ? (_fromSessionToken ??= uuid.v4())
            : (_toSessionToken ??= uuid.v4());

        await mapServices.getPredictions(
          input: input,
          sesstionToken: token,
          places: places,
        );

        if (mounted) setState(() {});
      }
    } catch (e) {
      log('Places autocomplete failed: $e');
      if (!mounted) return;
      setState(() {
        if (isFrom) {
          fromPlaces = [];
        } else {
          toPlaces = [];
        }
      });
    } finally {
      if (!mounted) return;
      setState(() {
        if (isFrom) {
          isFromPredictionsLoading = false;
        } else {
          isToPredictionsLoading = false;
        }
      });
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
            resizeToAvoidBottomInset: true,
            body: SafeArea(
              child: Column(
                children: [
                  _header(context),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(16, 10, 16, 18),
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      child: Column(
                        children: [
                          _locationCard(
                            context: context,
                            controller: controller,
                            isFrom: true,
                          ),
                          if (isFromFieldFocused &&
                              (fromPlaces.isNotEmpty ||
                                  isFromPredictionsLoading))
                            _predictions(
                              context,
                              controller,
                              fromPlaces,
                              true,
                              isFromPredictionsLoading,
                            ),
                          const SizedBox(height: 12),
                          _locationCard(
                            context: context,
                            controller: controller,
                            isFrom: false,
                          ),
                          if (isToFieldFocused &&
                              (toPlaces.isNotEmpty || isToPredictionsLoading))
                            _predictions(
                              context,
                              controller,
                              toPlaces,
                              false,
                              isToPredictionsLoading,
                            ),
                          if (_hasCompleteRoute(controller)) ...[
                            const SizedBox(height: 12),
                            _routePreviewCard(context, controller),
                          ],
                          const SizedBox(height: 12),
                          _savedAddressesCard(context, controller),
                          const SizedBox(height: 12),
                          _privacyCard(context),
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
                  child: ElevatedButton(
                    onPressed: () => _confirm(controller),
                    style: ElevatedButton.styleFrom(
                      elevation: 0,
                      backgroundColor: AppColors.mainAppColor,
                      foregroundColor: FasakhanstaBrand.onOrange,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    child: Text(
                      _isArabic(context)
                          ? 'تأكيد العناوين'
                          : 'Confirm addresses',
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
    );
  }

  Widget _header(BuildContext context) {
    return Container(
      color: FasakhanstaBrand.surface,
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 10),
      child: Row(
        children: [
          _roundIcon(
            icon: Icons.arrow_back_rounded,
            onTap: () => Navigator.of(context).pop(),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isArabic(context) ? 'تحديد العناوين' : 'Set addresses',
                  style: const TextStyle(
                    color: _text,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  _isArabic(context)
                      ? 'حدد موقعك الحالي وعنوان التوصيل'
                      : 'Set your current and delivery locations',
                  style: const TextStyle(
                    color: _muted,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Image.asset(
            'assets/images/deliveryRiderV2.png',
            width: 64,
            height: 54,
            fit: BoxFit.contain,
          ),
        ],
      ),
    );
  }

  Widget _locationCard({
    required BuildContext context,
    required RequestDelegateController controller,
    required bool isFrom,
  }) {
    final textController =
        isFrom ? controller.fromController : controller.toController;
    final focusNode = isFrom ? fromFocusNode : toFocusNode;
    final lat = isFrom ? controller.fromLat : controller.toLat;
    final lng = isFrom ? controller.fromLan : controller.toLan;
    final title = isFrom
        ? (_isArabic(context) ? 'موقعي الحالي' : 'Current location')
        : (_isArabic(context) ? 'التوصيل إلى' : 'Deliver to');
    final hint = isFrom
        ? (_isArabic(context) ? 'اكتب موقع الاستلام' : 'Enter pickup location')
        : (_isArabic(context)
            ? 'اختر أو ابحث عن عنوان التوصيل'
            : 'Choose or search delivery address');

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _cardDecoration(),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: _softOrange,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  isFrom
                      ? Icons.my_location_rounded
                      : Icons.location_on_outlined,
                  color: AppColors.mainAppColor,
                  size: 21,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: _text,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              if (isFrom)
                Container(
                  width: 9,
                  height: 9,
                  decoration: const BoxDecoration(
                    color: FasakhanstaBrand.successTint,
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Focus(
            onFocusChange: (focused) {
              if (!mounted) return;
              setState(() {
                if (isFrom) {
                  isFromFieldFocused = focused;
                  if (focused) isToFieldFocused = false;
                } else {
                  isToFieldFocused = focused;
                  if (focused) isFromFieldFocused = false;
                }
              });
            },
            child: TextField(
              controller: textController,
              focusNode: focusNode,
              maxLines: 2,
              minLines: 1,
              onChanged: (_) => _onSearchChanged(isFrom),
              onTapOutside: (_) {},
              style: const TextStyle(
                color: _text,
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
              ),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: const TextStyle(
                  color: _muted,
                  fontWeight: FontWeight.w400,
                ),
                filled: true,
                fillColor: FasakhanstaBrand.field,
                suffixIcon: textController.text.isEmpty
                    ? null
                    : IconButton(
                        onPressed: () {
                          textController.clear();
                          _onSearchChanged(isFrom);
                          if (mounted) setState(() {});
                        },
                        icon: const Icon(
                          Icons.close_rounded,
                          color: FasakhanstaBrand.muted,
                          size: 18,
                        ),
                      ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 13,
                  vertical: 12,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: _border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(
                    color: AppColors.mainAppColor,
                    width: 1.3,
                  ),
                ),
              ),
            ),
          ),
          if (lat != null &&
              lng != null &&
              lat.isNotEmpty &&
              lng.isNotEmpty) ...[
            const SizedBox(height: 7),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: Text(
                '${_shortCoordinate(lat)}, ${_shortCoordinate(lng)}',
                style: const TextStyle(
                  color: _muted,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
          const SizedBox(height: 10),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () async {
                FocusManager.instance.primaryFocus?.unfocus();
                final result = await NamedNavigatorImpl.push(
                  SelectLocationFromMapScreen.routeName,
                  arguments: SelectLocationFromMapScreenArgs(
                    isFromAddress: isFrom,
                  ),
                );
                if (!mounted) return;

                final selectedPoint =
                    isFrom ? controller.fromLatLng : controller.toLatLng;
                if (selectedPoint == null) return;

                if (isFrom) {
                  controller.setFromLat(selectedPoint.latitude.toString());
                  controller.setFromLan(selectedPoint.longitude.toString());
                  controller.setFromLatLng(selectedPoint);
                } else {
                  controller.setToLat(selectedPoint.latitude.toString());
                  controller.setToLan(selectedPoint.longitude.toString());
                  controller.setToLatLng(selectedPoint);
                }

                _routeSignature = null;
                _routePolylines = {};
                _recalculateDelivery(controller);
                setState(() {});
                log('Map selection synced for route preview: $result');
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 9,
                ),
                decoration: BoxDecoration(
                  color: _softOrange,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.map_outlined,
                      color: AppColors.mainAppColor,
                      size: 19,
                    ),
                    const SizedBox(width: 7),
                    Text(
                      _isArabic(context)
                          ? 'اختر من الخريطة'
                          : 'Choose from map',
                      style: TextStyle(
                        color: AppColors.mainAppColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _predictions(
    BuildContext context,
    RequestDelegateController controller,
    List<PlaceModel> places,
    bool isFrom,
    bool loading,
  ) {
    return TextFieldTapRegion(
      child: Container(
        margin: const EdgeInsets.only(top: 6),
        constraints: const BoxConstraints(maxHeight: 230),
        decoration: _cardDecoration(),
        child: loading && places.isEmpty
            ? const SizedBox(
                height: 58,
                child: Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              )
            : ListView.separated(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                itemCount: places.length,
                separatorBuilder: (_, __) =>
                    const Divider(height: 1, color: _border),
                itemBuilder: (context, index) {
                  final place = places[index];
                  return ListTile(
                    dense: true,
                    leading: Icon(
                      Icons.location_on_outlined,
                      color: AppColors.mainAppColor,
                      size: 20,
                    ),
                    title: Text(
                      place.description ?? '',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _text,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    onTap: () => _selectPrediction(controller, place, isFrom),
                  );
                },
              ),
      ),
    );
  }

  Future<void> _selectPrediction(
    RequestDelegateController controller,
    PlaceModel place,
    bool isFrom,
  ) async {
    final placeId = place.placeId;
    if (placeId == null || placeId.isEmpty) return;

    String address = place.description ?? '';
    double? lat;
    double? lng;

    try {
      if (kIsWeb) {
        final details = await getWebPlaceDetails(placeId: placeId);
        if (details == null) return;
        address = details.formattedAddress.isNotEmpty
            ? details.formattedAddress
            : address;
        lat = details.latitude;
        lng = details.longitude;
      } else {
        final details = await mapServices.getPlaceDetails(placeId: placeId);
        final location = details.geometry?.location;
        if (location?.lat == null || location?.lng == null) return;
        address = (details.formattedAddress ?? '').trim().isNotEmpty
            ? details.formattedAddress!.trim()
            : address;
        lat = location!.lat!.toDouble();
        lng = location.lng!.toDouble();
      }
    } catch (e) {
      log('Place details failed: $e');
      return;
    }

    if (lat == null || lng == null) return;

    if (isFrom) {
      controller.setFromController(address);
      controller.setFromAddress(address);
      controller.setFromLat(lat.toString());
      controller.setFromLan(lng.toString());
      controller.setFromLatLng(LatLng(lat, lng));
      fromPlaces = [];
      isFromFieldFocused = false;
      _fromSessionToken = null;
    } else {
      controller.setToController(address);
      controller.setToAddress(address);
      controller.setToLat(lat.toString());
      controller.setToLan(lng.toString());
      controller.setToLatLng(LatLng(lat, lng));
      toPlaces = [];
      isToFieldFocused = false;
      _toSessionToken = null;
    }

    FocusManager.instance.primaryFocus?.unfocus();
    _recalculateDelivery(controller);
    if (mounted) setState(() {});
  }

  bool _hasCompleteRoute(RequestDelegateController controller) {
    return double.tryParse(controller.fromLat ?? '') != null &&
        double.tryParse(controller.fromLan ?? '') != null &&
        double.tryParse(controller.toLat ?? '') != null &&
        double.tryParse(controller.toLan ?? '') != null;
  }

  Widget _routePreviewCard(
    BuildContext context,
    RequestDelegateController controller,
  ) {
    final from = LatLng(
      double.parse(controller.fromLat!),
      double.parse(controller.fromLan!),
    );
    final to = LatLng(
      double.parse(controller.toLat!),
      double.parse(controller.toLan!),
    );

    _scheduleRoutePreview(from, to);

    return Container(
      height: 190,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: FasakhanstaBrand.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D000000),
            blurRadius: 14,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: IgnorePointer(
              child: GoogleMap(
                mapType: MapType.normal,
                zoomControlsEnabled: false,
                myLocationButtonEnabled: false,
                mapToolbarEnabled: false,
                compassEnabled: false,
                initialCameraPosition: CameraPosition(
                  target: LatLng(
                    (from.latitude + to.latitude) / 2,
                    (from.longitude + to.longitude) / 2,
                  ),
                  zoom: 12.5,
                ),
                markers: {
                  Marker(
                    markerId: const MarkerId('pickupPreview'),
                    position: from,
                    icon: BitmapDescriptor.defaultMarkerWithHue(
                      BitmapDescriptor.hueGreen,
                    ),
                  ),
                  Marker(
                    markerId: const MarkerId('deliveryPreview'),
                    position: to,
                    icon: BitmapDescriptor.defaultMarkerWithHue(
                      BitmapDescriptor.hueOrange,
                    ),
                  ),
                },
                polylines: _routePolylines,
                onMapCreated: (mapController) {
                  _routeMapController = mapController;
                  Future.delayed(const Duration(milliseconds: 220), () {
                    if (mounted) _fitRoutePreview();
                  });
                },
              ),
            ),
          ),
          PositionedDirectional(
            top: 10,
            start: 10,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
              decoration: BoxDecoration(
                color: FasakhanstaBrand.surface.withOpacity(.94),
                borderRadius: BorderRadius.circular(12),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x15000000),
                    blurRadius: 10,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.route_rounded,
                    color: AppColors.mainAppColor,
                    size: 18,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _isArabic(context)
                        ? 'معاينة مسار التوصيل'
                        : 'Delivery route preview',
                    style: const TextStyle(
                      color: _text,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_routeLoading)
            PositionedDirectional(
              top: 12,
              end: 12,
              child: Container(
                width: 28,
                height: 28,
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: FasakhanstaBrand.surface.withOpacity(.94),
                  shape: BoxShape.circle,
                ),
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.mainAppColor,
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _scheduleRoutePreview(LatLng from, LatLng to) {
    final signature =
        '${from.latitude},${from.longitude}|${to.latitude},${to.longitude}';
    if (_routeSignature == signature) return;
    _routeSignature = signature;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _loadRoutePreview(from, to, signature);
    });
  }

  Future<void> _loadRoutePreview(
    LatLng from,
    LatLng to,
    String signature,
  ) async {
    if (!mounted) return;
    setState(() => _routeLoading = true);

    List<LatLng> points = [];
    try {
      final route = await mapServices.getRouteData(
        originFrom: from,
        desintation: to,
      );
      if (route.length >= 2) {
        points = [from, ...route, to];
      }
    } catch (e) {
      log('Route preview unavailable: $e');
    }

    if (!mounted || _routeSignature != signature) return;

    setState(() {
      _routeLoading = false;
      _routePolylines = points.length >= 2
          ? {
              Polyline(
                polylineId: const PolylineId('deliveryRoutePreview'),
                points: points,
                color: AppColors.mainAppColor,
                width: 5,
                startCap: Cap.roundCap,
                endCap: Cap.roundCap,
              ),
            }
          : {};
    });

    Future.delayed(const Duration(milliseconds: 120), () {
      if (mounted) {
        _fitRoutePreview(points: points.length >= 2 ? points : [from, to]);
      }
    });
  }

  Future<void> _fitRoutePreview({List<LatLng>? points}) async {
    final mapController = _routeMapController;
    if (mapController == null) return;

    final routePoints = points ??
        _routePolylines
            .expand((polyline) => polyline.points)
            .toList(growable: false);
    if (routePoints.length < 2) return;

    try {
      final bounds = mapServices.getLatLngBounds(routePoints);
      await mapController.animateCamera(
        CameraUpdate.newLatLngBounds(bounds, 42),
      );
    } catch (e) {
      log('Failed to fit route preview: $e');
    }
  }

  Widget _savedAddressesCard(
    BuildContext context,
    RequestDelegateController controller,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => _chooseSavedAddress(context, controller),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: _cardDecoration(),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: _softOrange,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(
                  Icons.list_alt_rounded,
                  color: AppColors.mainAppColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _isArabic(context)
                          ? 'العناوين المحفوظة'
                          : 'Saved addresses',
                      style: const TextStyle(
                        color: _text,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      _isArabic(context)
                          ? 'اختر عنوانًا محفوظًا للتوصيل'
                          : 'Choose a saved delivery address',
                      style: const TextStyle(color: _muted, fontSize: 11),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_left_rounded,
                color: FasakhanstaBrand.muted,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _chooseSavedAddress(
    BuildContext context,
    RequestDelegateController controller,
  ) async {
    FocusManager.instance.primaryFocus?.unfocus();

    final selected = await Navigator.of(context).push<AddressModel>(
      MaterialPageRoute(
        builder: (_) => const AddressScreen(selectForDelivery: true),
      ),
    );

    if (!mounted || selected == null) return;

    final lat = double.tryParse((selected.lat ?? '').trim());
    final lng = double.tryParse((selected.lng ?? '').trim());

    if (lat == null || lng == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: FasakhanstaBrand.surfaceRaised,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          content: Text(
            _isArabic(context)
                ? 'هذا العنوان لا يحتوي على موقع محدد. عدّله وأضف الموقع أولًا.'
                : 'This saved address has no location. Edit it and add a map location first.',
            style: const TextStyle(color: _text, fontWeight: FontWeight.w700),
          ),
        ),
      );
      return;
    }

    final label = _savedAddressLabel(selected);
    controller.setToController(label);
    controller.setToAddress(label);
    controller.setToLat(lat.toString());
    controller.setToLan(lng.toString());
    controller.setToLatLng(LatLng(lat, lng));

    toPlaces = [];
    isToFieldFocused = false;
    _toSessionToken = null;

    _recalculateDelivery(controller);
    if (mounted) setState(() {});
  }

  String _savedAddressLabel(AddressModel address) {
    final directAddress = (address.address ?? '').trim();
    if (directAddress.isNotEmpty) return directAddress;

    final parts = <String>[
      if ((address.streetName ?? '').trim().isNotEmpty)
        address.streetName!.trim(),
      if ((address.areaName ?? '').trim().isNotEmpty) address.areaName!.trim(),
      if ((address.cityName ?? address.cityname ?? '').trim().isNotEmpty)
        (address.cityName ?? address.cityname)!.trim(),
      if ((address.countryName ?? '').trim().isNotEmpty)
        address.countryName!.trim(),
      if ((address.floorNo ?? '').trim().isNotEmpty)
        '${_isArabic(context) ? 'الدور' : 'Floor'} ${address.floorNo!.trim()}',
      if ((address.apartmentNo ?? '').trim().isNotEmpty)
        '${_isArabic(context) ? 'شقة' : 'Apt'} ${address.apartmentNo!.trim()}',
    ];

    return parts.toSet().join(' - ');
  }

  Widget _privacyCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _softOrange,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Icon(
            Icons.verified_user_outlined,
            color: AppColors.mainAppColor,
            size: 28,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isArabic(context) ? 'خصوصيتك تهمنا' : 'Your privacy matters',
                  style: const TextStyle(
                    color: _text,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  _isArabic(context)
                      ? 'نستخدم موقعك فقط لتحسين تجربة التوصيل ووصول طلبك بدقة.'
                      : 'Your location is used only to improve delivery accuracy.',
                  style: const TextStyle(
                    color: FasakhanstaBrand.muted,
                    fontSize: 11,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _roundIcon({required IconData icon, required VoidCallback onTap}) {
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

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: FasakhanstaBrand.surface,
      borderRadius: BorderRadius.circular(18),
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

  String _shortCoordinate(String value) {
    final number = double.tryParse(value);
    return number?.toStringAsFixed(5) ?? value;
  }

  void _recalculateDelivery(RequestDelegateController controller) {
    if (!_hasCompleteRoute(controller)) return;

    controller.calculateDistance(
      kmPrice: controller.delegatesOnMap?.shippingKmPrice ?? 0,
    );
    controller.calculateDeliveryPrice(
      kmPrice: controller.delegatesOnMap?.shippingKmPrice ?? 0,
    );
  }

  void _confirm(RequestDelegateController controller) {
    controller.setFromAddress(controller.fromController.text.trim());
    controller.setToAddress(controller.toController.text.trim());

    if (controller.fromLatLng != null) {
      controller.setFromLat(controller.fromLatLng!.latitude.toString());
      controller.setFromLan(controller.fromLatLng!.longitude.toString());
    }
    if (controller.toLatLng != null) {
      controller.setToLat(controller.toLatLng!.latitude.toString());
      controller.setToLan(controller.toLatLng!.longitude.toString());
    }

    _recalculateDelivery(controller);

    log('delivery distance ${controller.distance}');
    Navigator.of(context).pop(true);
  }
}
