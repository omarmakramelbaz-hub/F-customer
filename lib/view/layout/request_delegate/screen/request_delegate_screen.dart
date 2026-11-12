import 'package:faskhaninja/helpers/theme/fasakhansta_brand.dart';

import 'dart:async';
import 'dart:developer';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';

import '../../../../helpers/extensions/extensions.dart';
import '../../../../helpers/routes/app_routers_import.dart';
import '../../../../helpers/theme/app_colors.dart';
import '../../../../helpers/translation/all_translation.dart';
import '../../../../helpers/utils/common_methods.dart';
import '../../../../helpers/utils/utils.dart';
import '../../../custom_widgets/api_response_widget/api_response_widget.dart';
import '../../../custom_widgets/custom_loading/custom_loading.dart';
import '../../../custom_widgets/custom_loading/custom_shimmer.dart';
import '../../../custom_widgets/custom_payment_web_view/custom_payment_web_view.dart';
import '../../map/utils/map_services.dart';
import '../bottom_sheet/payment_rd_bottom_sheet.dart';
import '../bottom_sheet/rd_details_bottom_sheet.dart';
import '../controller/request_delegate_controller.dart';
import '../widget/custom_map_animated_container.dart';
import 'show_delegate_on_map_screen.dart';

class RequestDelegateScreen extends StatefulWidget {
  static const String routeName = 'RequestDelegateScreen';

  const RequestDelegateScreen({super.key});

  @override
  State<RequestDelegateScreen> createState() => _RequestDelegateScreenState();
}

class _RequestDelegateScreenState extends State<RequestDelegateScreen>
    with WidgetsBindingObserver {
  double? containerHeight;
  Timer? _debounce;
  List<Placemark>? placemarks;
  double? currentLat;
  double? currentLng;
  GoogleMapController? gmc;
  BitmapDescriptor? _orangePinIcon;
  BitmapDescriptor? _pickupRiderIcon;
  BitmapDescriptor? _pickupGoDriveIcon;
  late final MapServices _mapServices;
  Set<Polyline> _deliveryRoutePolylines = {};
  String? _routeRequestKey;
  String? _fareRouteKey;
  double? _cachedShippingKmPrice;
  double? _cachedDefault0To1;
  double? _cachedDefault1To2;
  double? _cachedDefault2To3;
  Set<Marker> markers = {};
  bool isLocationLoaded = false;
  bool isCheckingLocation = false;

  double get _panelHeight => context.height * 0.64;

  static const String _cleanLightMapStyle = '''
[
  {"elementType":"geometry","stylers":[{"color":"#f7f7f5"}]},
  {"elementType":"labels.icon","stylers":[{"visibility":"off"}]},
  {"elementType":"labels.text.fill","stylers":[{"color":"#6f747b"}]},
  {"elementType":"labels.text.stroke","stylers":[{"color":"#ffffff"}]},
  {"featureType":"administrative","elementType":"geometry.stroke","stylers":[{"color":"#e4e5e7"}]},
  {"featureType":"landscape","elementType":"geometry","stylers":[{"color":"#f8f8f6"}]},
  {"featureType":"poi","stylers":[{"visibility":"off"}]},
  {"featureType":"road","elementType":"geometry","stylers":[{"color":"#ffffff"}]},
  {"featureType":"road","elementType":"geometry.stroke","stylers":[{"color":"#e6e8ea"}]},
  {"featureType":"road.arterial","elementType":"geometry","stylers":[{"color":"#fbfbfb"}]},
  {"featureType":"road.highway","elementType":"geometry","stylers":[{"color":"#f1f2f3"}]},
  {"featureType":"road.local","elementType":"labels.text.fill","stylers":[{"color":"#9a9ea5"}]},
  {"featureType":"transit","stylers":[{"visibility":"off"}]},
  {"featureType":"water","elementType":"geometry","stylers":[{"color":"#cfefff"}]},
  {"featureType":"water","elementType":"labels.text.fill","stylers":[{"color":"#5d8da5"}]}
]
''';

  Future<void> _loadPickupMarkerIcons() async {
    try {
      _pickupRiderIcon = await BitmapDescriptor.asset(
        const ImageConfiguration(),
        'assets/images/deliveryRiderV2.png',
        height: 68,
      );
      if (mounted) setState(() {});
    } catch (e) {
      log('Failed to load pickup rider marker: $e');
    }

    try {
      final riderData = await rootBundle.load(
        'assets/images/deliveryRiderV2.png',
      );
      final codec = await ui.instantiateImageCodec(
        riderData.buffer.asUint8List(),
      );
      final frame = await codec.getNextFrame();
      final rider = frame.image;

      const canvasWidth = 184.0;
      const canvasHeight = 92.0;
      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);

      final src = ui.Rect.fromLTWH(
        0,
        0,
        rider.width.toDouble(),
        rider.height.toDouble(),
      );
      final riderAspect = rider.width / rider.height;
      const riderHeight = 67.0;
      final riderWidth = riderHeight * riderAspect;
      final riderRect = ui.Rect.fromLTWH(
        4,
        canvasHeight - riderHeight,
        riderWidth,
        riderHeight,
      );
      canvas.drawImageRect(rider, src, riderRect, ui.Paint());

      final poleX = riderRect.right - 7;
      final polePaint = ui.Paint()
        ..color = const Color(0xFF555A61)
        ..strokeWidth = 2.4
        ..strokeCap = ui.StrokeCap.round;
      canvas.drawLine(
        ui.Offset(poleX, 15),
        ui.Offset(poleX, canvasHeight - 6),
        polePaint,
      );

      final flagPath = ui.Path()
        ..moveTo(poleX, 14)
        ..lineTo(canvasWidth - 7, 14)
        ..lineTo(canvasWidth - 19, 29)
        ..lineTo(canvasWidth - 7, 44)
        ..lineTo(poleX, 44)
        ..close();
      canvas.drawPath(flagPath, ui.Paint()..color = AppColors.mainAppColor);

      final textPainter = TextPainter(
        text: const TextSpan(
          text: 'GO Drive',
          style: TextStyle(
            color: FasakhanstaBrand.text,
            fontSize: 13,
            fontWeight: FontWeight.w800,
          ),
        ),
        textDirection: TextDirection.ltr,
        maxLines: 1,
      )..layout(maxWidth: canvasWidth - poleX - 16);
      textPainter.paint(
        canvas,
        Offset(poleX + 10, 29 - (textPainter.height / 2)),
      );

      final picture = recorder.endRecording();
      final markerImage = await picture.toImage(
        canvasWidth.toInt(),
        canvasHeight.toInt(),
      );
      final markerBytes = await markerImage.toByteData(
        format: ui.ImageByteFormat.png,
      );
      if (markerBytes == null) return;

      final icon = BitmapDescriptor.fromBytes(markerBytes.buffer.asUint8List());
      if (!mounted) return;
      setState(() => _pickupGoDriveIcon = icon);
    } catch (e) {
      log('Failed to build GO Drive pickup marker: $e');
    }
  }

  Future<void> _determinePosition() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        await Geolocator.openLocationSettings();
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied ||
            permission == LocationPermission.deniedForever) {
          log('Location permissions are denied.');
          return;
        }
      }

      final position = await Geolocator.getCurrentPosition();
      await _updateLocation(position.latitude, position.longitude);
    } catch (e) {
      log('Failed to get location: $e');
    }
  }

  Future<void> _updateLocation(double lat, double lng) async {
    final controller = Provider.of<RequestDelegateController>(
      context,
      listen: false,
    );

    _orangePinIcon ??= await BitmapDescriptor.asset(
      const ImageConfiguration(),
      'assets/images/deliveryLocationPin.png',
      height: 42,
    );
    if (!mounted) return;
    setState(() {
      currentLat = lat;
      currentLng = lng;
      markers
        ..removeWhere((marker) => marker.markerId.value == 'currentLocation')
        ..add(
          Marker(
            markerId: const MarkerId('currentLocation'),
            position: LatLng(lat, lng),
            icon:
                _orangePinIcon ??
                BitmapDescriptor.defaultMarkerWithHue(
                  BitmapDescriptor.hueOrange,
                ),
          ),
        );
    });

    controller.setFromLat(lat.toString());
    controller.setFromLan(lng.toString());
    controller.setFromLatLng(LatLng(lat, lng));
    _recalculateFareForCurrentRoute(controller);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.initialDelegatesOnMap();
      controller
          .getDelegatesOnMap(
            lat: currentLat.toString(),
            lan: currentLng.toString(),
          )
          .then((_) async {
            final delegatesOnMap = controller.delegatesOnMap;

            if (delegatesOnMap?.shippingOrderId != null &&
                delegatesOnMap?.shippingOrderId != 0) {
              controller.setOrderId(delegatesOnMap?.shippingOrderId ?? 0);
              NamedNavigatorImpl.push(
                ShowDelegateOnMapScreen.routeName,
                arguments: ShowDelegateOnMapArgs(
                  orderId: delegatesOnMap?.shippingOrderId,
                  fee: int.parse(
                    delegatesOnMap?.orderData?.actualPrice.toString() ?? '0',
                  ),
                  kmPrice: (delegatesOnMap?.shippingKmPrice ?? 0).round(),
                  shippingPercentage:
                      (delegatesOnMap?.shippingMinPricePrecentage ?? 10)
                          .round(),
                  distance: num.parse('${controller.distance ?? 0}'),
                ),
              );
            } else {
              controller.setDistance(0.0);
            }

            _recalculateFareForCurrentRoute(controller);

            if (delegatesOnMap?.userData != null) {
              try {
                final customMarkerIcon = await BitmapDescriptor.asset(
                  const ImageConfiguration(),
                  'assets/images/motorcycleImage.png',
                  height: 50,
                );
                final delegateMarkers = delegatesOnMap!.userData!
                    .where((userModel) {
                      final lat = double.tryParse(userModel.lat ?? '');
                      final lng = double.tryParse(userModel.lng ?? '');
                      return lat != null &&
                          lng != null &&
                          _isEgyptPoint(LatLng(lat, lng));
                    })
                    .map(
                      (userModel) => Marker(
                        icon: customMarkerIcon,
                        markerId: MarkerId(userModel.id.toString()),
                        position: LatLng(
                          double.parse(userModel.lat!),
                          double.parse(userModel.lng!),
                        ),
                      ),
                    );
                markers.addAll(delegateMarkers);
                if (mounted) setState(() {});
              } catch (e) {
                log('Failed to load delegate marker image: $e');
              }
            }
          });
    });

    if (gmc != null) {
      await gmc!.animateCamera(CameraUpdate.newLatLng(LatLng(lat, lng)));
    }

    try {
      placemarks = await placemarkFromCoordinates(lat, lng);
      if (placemarks != null && placemarks!.isNotEmpty) {
        controller.setFromAddress(
          '${placemarks![0].locality}, ${placemarks![0].country} ${placemarks![0].street}',
        );
      } else {
        controller.setFromAddress(
          '${lat.toStringAsFixed(5)}, ${lng.toStringAsFixed(5)}',
        );
      }
    } catch (e) {
      log('Reverse geocoding failed: $e');
      controller.setFromAddress(
        '${lat.toStringAsFixed(5)}, ${lng.toStringAsFixed(5)}',
      );
    }

    if (!mounted) return;
    setState(() {
      isLocationLoaded = true;
    });
  }

  double? _resolveShippingKmPrice(RequestDelegateController controller) {
    final liveKmPrice = double.tryParse(
      '${controller.delegatesOnMap?.shippingKmPrice}',
    );
    if (liveKmPrice != null && liveKmPrice > 0) {
      _cachedShippingKmPrice = liveKmPrice;
      return liveKmPrice;
    }
    return _cachedShippingKmPrice;
  }

  double? _resolveDefault0To1(RequestDelegateController controller) {
    final value = double.tryParse('${controller.delegatesOnMap?.default0To1}');
    if (value != null && value > 0) {
      _cachedDefault0To1 = value;
      return value;
    }
    return _cachedDefault0To1;
  }

  double? _resolveDefault1To2(RequestDelegateController controller) {
    final value = double.tryParse('${controller.delegatesOnMap?.default1To2}');
    if (value != null && value > 0) {
      _cachedDefault1To2 = value;
      return value;
    }
    return _cachedDefault1To2;
  }

  double? _resolveDefault2To3(RequestDelegateController controller) {
    final value = double.tryParse('${controller.delegatesOnMap?.default2To3}');
    if (value != null && value > 0) {
      _cachedDefault2To3 = value;
      return value;
    }
    return _cachedDefault2To3;
  }

  double _calculateDashboardFare({
    required double distanceKm,
    required double kmPrice,
    required double default0To1,
    required double default1To2,
    required double default2To3,
  }) {
    if (default0To1 <= 0 || default1To2 <= 0 || default2To3 <= 0) {
      return distanceKm * kmPrice;
    }
    if (distanceKm <= 1) return default0To1;
    if (distanceKm <= 2) return default1To2;
    if (distanceKm <= 3) return default2To3;

    final extraKm = (distanceKm - 3).ceil();
    return default2To3 + (extraKm * kmPrice);
  }

  String _fareKey(
    LatLng pickup,
    LatLng delivery,
    double kmPrice,
    double default0To1,
    double default1To2,
    double default2To3,
  ) =>
      '${pickup.latitude},${pickup.longitude}|${delivery.latitude},${delivery.longitude}|$kmPrice|$default0To1|$default1To2|$default2To3';

  String? _calculateExpectedFareForCurrentRoute(
    RequestDelegateController controller,
  ) {
    final pickup = _pickupPoint(controller);
    final delivery = _deliveryPoint(controller);
    final kmPrice = _resolveShippingKmPrice(controller);
    final default0To1 = _resolveDefault0To1(controller);
    final default1To2 = _resolveDefault1To2(controller);
    final default2To3 = _resolveDefault2To3(controller);

    if (pickup == null ||
        delivery == null ||
        kmPrice == null ||
        kmPrice <= 0 ||
        default0To1 == null ||
        default1To2 == null ||
        default2To3 == null) {
      return null;
    }

    final distanceKm =
        Geolocator.distanceBetween(
          pickup.latitude,
          pickup.longitude,
          delivery.latitude,
          delivery.longitude,
        ) /
        1000;
    return _calculateDashboardFare(
      distanceKm: distanceKm,
      kmPrice: kmPrice,
      default0To1: default0To1,
      default1To2: default1To2,
      default2To3: default2To3,
    ).round().toString();
  }

  void _recalculateFareForCurrentRoute(RequestDelegateController controller) {
    final fromLat = double.tryParse(controller.fromLat ?? '');
    final fromLng = double.tryParse(controller.fromLan ?? '');
    final toLat = double.tryParse(controller.toLat ?? '');
    final toLng = double.tryParse(controller.toLan ?? '');
    final kmPrice = _resolveShippingKmPrice(controller);
    final default0To1 = _resolveDefault0To1(controller);
    final default1To2 = _resolveDefault1To2(controller);
    final default2To3 = _resolveDefault2To3(controller);

    if (fromLat == null ||
        fromLng == null ||
        toLat == null ||
        toLng == null ||
        kmPrice == null ||
        kmPrice <= 0 ||
        default0To1 == null ||
        default1To2 == null ||
        default2To3 == null) {
      return;
    }

    final pickup = LatLng(fromLat, fromLng);
    final delivery = LatLng(toLat, toLng);
    final distanceKm =
        Geolocator.distanceBetween(fromLat, fromLng, toLat, toLng) / 1000;
    final updatedFare = _calculateDashboardFare(
      distanceKm: distanceKm,
      kmPrice: kmPrice,
      default0To1: default0To1,
      default1To2: default1To2,
      default2To3: default2To3,
    ).round().toString();

    _fareRouteKey = _fareKey(
      pickup,
      delivery,
      kmPrice,
      default0To1,
      default1To2,
      default2To3,
    );
    controller.setDistance(distanceKm);
    controller.setPriceEC(updatedFare);
    controller.setActualPrice(updatedFare);
  }

  void _syncFareForSelectedRoute(RequestDelegateController controller) {
    final pickup = _pickupPoint(controller);
    final delivery = _deliveryPoint(controller);
    final kmPrice = _resolveShippingKmPrice(controller);
    final default0To1 = _resolveDefault0To1(controller);
    final default1To2 = _resolveDefault1To2(controller);
    final default2To3 = _resolveDefault2To3(controller);
    if (pickup == null ||
        delivery == null ||
        kmPrice == null ||
        kmPrice <= 0 ||
        default0To1 == null ||
        default1To2 == null ||
        default2To3 == null) {
      return;
    }

    final key = _fareKey(
      pickup,
      delivery,
      kmPrice,
      default0To1,
      default1To2,
      default2To3,
    );
    if (_fareRouteKey == key) return;

    final distanceKm =
        Geolocator.distanceBetween(
          pickup.latitude,
          pickup.longitude,
          delivery.latitude,
          delivery.longitude,
        ) /
        1000;
    final updatedFare = _calculateDashboardFare(
      distanceKm: distanceKm,
      kmPrice: kmPrice,
      default0To1: default0To1,
      default1To2: default1To2,
      default2To3: default2To3,
    ).round().toString();

    _fareRouteKey = key;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      final latestPickup = _pickupPoint(controller);
      final latestDelivery = _deliveryPoint(controller);
      final latestKmPrice = _resolveShippingKmPrice(controller);
      final latestDefault0To1 = _resolveDefault0To1(controller);
      final latestDefault1To2 = _resolveDefault1To2(controller);
      final latestDefault2To3 = _resolveDefault2To3(controller);
      if (latestPickup == null ||
          latestDelivery == null ||
          latestKmPrice == null ||
          latestKmPrice <= 0 ||
          latestDefault0To1 == null ||
          latestDefault1To2 == null ||
          latestDefault2To3 == null ||
          _fareKey(
                latestPickup,
                latestDelivery,
                latestKmPrice,
                latestDefault0To1,
                latestDefault1To2,
                latestDefault2To3,
              ) !=
              key) {
        return;
      }

      controller.setDistance(distanceKm);
      controller.setPriceEC(updatedFare);
      controller.setActualPrice(updatedFare);
    });
  }

  void _onMapTap(LatLng latLng) async {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      _updateLocation(latLng.latitude, latLng.longitude);
    });

    if (gmc != null) {
      gmc!.animateCamera(CameraUpdate.newLatLng(latLng));
    }
  }

  bool _isEgyptPoint(LatLng point) {
    return point.latitude >= 21.0 &&
        point.latitude <= 32.5 &&
        point.longitude >= 24.0 &&
        point.longitude <= 37.5;
  }

  LatLng? _pickupPoint(RequestDelegateController controller) {
    final lat = double.tryParse(controller.fromLat ?? '');
    final lng = double.tryParse(controller.fromLan ?? '');
    if (lat == null || lng == null) return null;
    final point = LatLng(lat, lng);
    return _isEgyptPoint(point) ? point : null;
  }

  LatLng? _deliveryPoint(RequestDelegateController controller) {
    final lat = double.tryParse(controller.toLat ?? '');
    final lng = double.tryParse(controller.toLan ?? '');
    if (lat == null || lng == null) return null;
    final point = LatLng(lat, lng);
    return _isEgyptPoint(point) ? point : null;
  }

  Set<Marker> _visibleMarkers(RequestDelegateController controller) {
    final result = markers
        .where((marker) => _isEgyptPoint(marker.position))
        .toSet();
    final pickup = _pickupPoint(controller);
    final delivery = _deliveryPoint(controller);

    if (pickup != null) {
      result.removeWhere(
        (marker) => marker.markerId.value == 'currentLocation',
      );
      result.add(
        Marker(
          markerId: const MarkerId('pickupLocation'),
          position: pickup,
          icon:
              _pickupGoDriveIcon ??
              _pickupRiderIcon ??
              BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
          anchor: const Offset(.31, 1),
          zIndex: 100,
          infoWindow: InfoWindow(
            title: 'GO Drive',
            snippet: context.languageCode == 'ar'
                ? 'نقطة الاستلام'
                : 'Pickup point',
          ),
        ),
      );
    }

    if (delivery != null) {
      result.add(
        Marker(
          markerId: const MarkerId('deliveryDestination'),
          position: delivery,
          icon:
              _orangePinIcon ??
              BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
          zIndex: 90,
          infoWindow: InfoWindow(
            title: context.languageCode == 'ar'
                ? 'نقطة التوصيل'
                : 'Delivery point',
          ),
        ),
      );
    }
    return result;
  }

  void _syncSelectedRoute(RequestDelegateController controller) {
    final pickup = _pickupPoint(controller);
    final delivery = _deliveryPoint(controller);

    if (pickup == null || delivery == null) {
      if (_routeRequestKey != null || _deliveryRoutePolylines.isNotEmpty) {
        _routeRequestKey = null;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted || _deliveryRoutePolylines.isEmpty) return;
          setState(() => _deliveryRoutePolylines = {});
        });
      }
      return;
    }

    final key =
        '${pickup.latitude},${pickup.longitude}|${delivery.latitude},${delivery.longitude}';
    if (_routeRequestKey == key) return;
    _routeRequestKey = key;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _loadSelectedRoute(pickup, delivery, key);
    });
  }

  Future<void> _loadSelectedRoute(
    LatLng pickup,
    LatLng delivery,
    String key,
  ) async {
    try {
      final points = await _mapServices.getRouteData(
        originFrom: pickup,
        desintation: delivery,
      );

      if (!mounted || _routeRequestKey != key) return;
      final validPoints = points.where(_isEgyptPoint).toList(growable: false);
      if (validPoints.length < 2) {
        throw StateError('Route has no valid points');
      }

      setState(() {
        _deliveryRoutePolylines = {
          Polyline(
            polylineId: const PolylineId('selectedDeliveryRoute'),
            points: validPoints,
            color: AppColors.mainAppColor,
            width: 5,
            startCap: Cap.roundCap,
            endCap: Cap.roundCap,
            jointType: JointType.round,
          ),
        };
      });

      await _fitRoutePoints(validPoints);
    } catch (e) {
      log('Failed to load selected delivery route: $e');
      if (!mounted || _routeRequestKey != key) return;
      if (_deliveryRoutePolylines.isNotEmpty) {
        setState(() => _deliveryRoutePolylines = {});
      }
      await _fitSafeEndpoints(pickup, delivery);
    }
  }

  Future<void> _fitRoutePoints(List<LatLng> points) async {
    if (gmc == null || points.length < 2) return;
    await _fitSafeEndpoints(points.first, points.last);
  }

  double _zoomForRouteDistance(double distanceKm) {
    if (distanceKm <= 0.8) return 15.8;
    if (distanceKm <= 2) return 14.8;
    if (distanceKm <= 5) return 13.8;
    if (distanceKm <= 10) return 12.8;
    if (distanceKm <= 20) return 11.8;
    if (distanceKm <= 40) return 10.8;
    if (distanceKm <= 80) return 9.8;
    if (distanceKm <= 150) return 8.8;
    if (distanceKm <= 300) return 7.8;
    return 7.0;
  }

  Future<void> _fitSafeEndpoints(LatLng pickup, LatLng delivery) async {
    if (gmc == null) return;

    final distanceKm =
        Geolocator.distanceBetween(
          pickup.latitude,
          pickup.longitude,
          delivery.latitude,
          delivery.longitude,
        ) /
        1000;

    final center = LatLng(
      (pickup.latitude + delivery.latitude) / 2,
      (pickup.longitude + delivery.longitude) / 2,
    );
    final zoom = _zoomForRouteDistance(distanceKm);

    try {
      await gmc!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: center, zoom: zoom),
        ),
      );
    } catch (e) {
      log('Failed to focus selected delivery area: $e');
    }
  }

  @override
  void initState() {
    super.initState();
    _mapServices = MapServices();
    WidgetsBinding.instance.addObserver(this);
    _loadPickupMarkerIcons();
    _determinePosition();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _debounce?.cancel();
    gmc?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _recheckLocationServices();
    }
  }

  Future<void> _recheckLocationServices() async {
    if (!mounted) return;
    setState(() => isCheckingLocation = true);

    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (serviceEnabled) {
      await _determinePosition();
    } else {
      log('Location services are still disabled.');
    }

    if (!mounted) return;
    setState(() => isCheckingLocation = false);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<RequestDelegateController>(
      builder: (context, controller, _) {
        if (!isLocationLoaded) {
          return const Scaffold(
            backgroundColor: Colors.transparent,
            body: Center(child: CustomLoading()),
          );
        }

        _syncFareForSelectedRoute(controller);
        _syncSelectedRoute(controller);

        return Scaffold(
          backgroundColor: Colors.transparent,
          body: Stack(
            children: [
              GoogleMap(
                mapType: MapType.normal,
                onTap: _onMapTap,
                markers: _visibleMarkers(controller),
                polylines: _deliveryRoutePolylines,
                style: _cleanLightMapStyle,
                padding: EdgeInsets.only(bottom: _panelHeight * .25),
                minMaxZoomPreference: const MinMaxZoomPreference(7.0, 19.0),
                onMapCreated: (mapController) {
                  gmc = mapController;
                  final pickup = _pickupPoint(controller);
                  final delivery = _deliveryPoint(controller);

                  if (pickup != null && delivery != null) {
                    _syncSelectedRoute(controller);
                    Future.delayed(const Duration(milliseconds: 160), () {
                      if (mounted) _fitSafeEndpoints(pickup, delivery);
                    });
                  } else if (currentLat != null && currentLng != null) {
                    gmc!.animateCamera(
                      CameraUpdate.newLatLng(LatLng(currentLat!, currentLng!)),
                    );
                  }
                },
                initialCameraPosition: CameraPosition(
                  target: LatLng(currentLat ?? 0, currentLng ?? 0),
                  zoom: 14.5,
                ),
                zoomControlsEnabled: false,
                myLocationButtonEnabled: false,
                mapToolbarEnabled: false,
                compassEnabled: false,
              ),
              Positioned(
                top: MediaQuery.of(context).padding.top + 10,
                right: context.languageCode == 'ar' ? 12 : null,
                left: context.languageCode == 'ar' ? null : 12,
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => NamedNavigatorImpl.pop(),
                    borderRadius: BorderRadius.circular(25),
                    child: Ink(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: FasakhanstaBrand.surface,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.mainAppColor.withOpacity(.28),
                        ),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x18000000),
                            blurRadius: 14,
                            offset: Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Icon(
                        context.languageCode == 'ar'
                            ? Icons.arrow_forward_rounded
                            : Icons.arrow_back_rounded,
                        color: AppColors.mainAppColor,
                        size: 25,
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: ApiResponseWidget(
                  loadingWidget: CustomShimmer(
                    height: _panelHeight,
                    width: double.infinity,
                    radius: 34,
                    fillColor: FasakhanstaBrand.field,
                    shimmerColor: const Color(0xFFF3F4F6),
                  ),
                  apiResponse: controller.delegateOnMapApiResponse,
                  onReload: () => controller.getDelegatesOnMap(
                    lat: currentLat.toString(),
                    lan: currentLng.toString(),
                  ),
                  isEmpty: controller.delegatesOnMap?.userData == null,
                  child: CustomMapAnimatedContainer(
                    containerHeight: containerHeight,
                  ),
                ),
              ),
            ],
          ),
          bottomNavigationBar: _buildBottomNavigationBar(controller),
        );
      },
    );
  }

  Widget _buildBottomNavigationBar(RequestDelegateController controller) {
    return Container(
      decoration: const BoxDecoration(
        color: FasakhanstaBrand.surface,
        boxShadow: [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 18,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 9, 14, 10),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _onConfirmOrder(controller),
              borderRadius: BorderRadius.circular(18),
              child: Ink(
                height: 56,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  gradient: const LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [FasakhanstaBrand.orange, FasakhanstaBrand.orange],
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x33FF7200),
                      blurRadius: 16,
                      offset: Offset(0, 7),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    'confirmOrder'.tr,
                    style: const TextStyle(
                      color: FasakhanstaBrand.onOrange,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _bottomActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          width: 62,
          height: 56,
          decoration: BoxDecoration(
            color: FasakhanstaBrand.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: FasakhanstaBrand.border),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0D000000),
                blurRadius: 11,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: FasakhanstaBrand.text, size: 22),
              const SizedBox(height: 2),
              Text(
                label,
                style: const TextStyle(
                  color: FasakhanstaBrand.muted,
                  fontSize: 9.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openPaymentSheet(RequestDelegateController controller) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ChangeNotifierProvider.value(
        value: controller,
        child: PaymentRDBottomSheet(requestDelegateController: controller),
      ),
    );
  }

  void _onConfirmOrder(RequestDelegateController controller) {
    final expectedPrice =
        _calculateExpectedFareForCurrentRoute(controller) ??
        controller.priceEC.text.trim();
    final serviceActivated = controller.delegatesOnMap?.goDriveBlock == 0;

    if (controller.isDataValid()) {
      if (!serviceActivated) {
        CommonMethods.showError(message: 'callAdminToActivateService'.tr);
      } else {
        controller.createNewShippingOrder(
          fromLat: controller.fromLat ?? '',
          fromLng: controller.fromLan ?? '',
          fromAddress: controller.fromAddress,
          toLat: controller.toLat ?? '',
          toLng: controller.toLan ?? '',
          toAddress: controller.toAddress,
          description: controller.descriptionEC.text,
          actualPrice: controller.actualPrice ?? expectedPrice,
          expectedPrice: expectedPrice,
          paymentType: controller.selectedPayment,
          onSuccess: () {
            if (controller.selectedPayment == 'cash' ||
                controller.selectedPayment == 'wallet') {
              NamedNavigatorImpl.push(
                ShowDelegateOnMapScreen.routeName,
                arguments: ShowDelegateOnMapArgs(
                  orderId: controller.orderId,
                  fee: int.parse(controller.actualPrice ?? '0'),
                  kmPrice: (controller.delegatesOnMap?.shippingKmPrice ?? 0)
                      .round(),
                  shippingPercentage:
                      (controller.delegatesOnMap?.shippingMinPricePrecentage ??
                              10)
                          .round(),
                  distance: num.parse('${controller.distance}'),
                ),
              );
              controller.reset();
            }
          },
          onHadeLink: (link) {
            if (controller.selectedPayment != 'cash') {
              NamedNavigatorImpl.push(
                CustomPaymentWebViewScreen.routeName,
                arguments: PaymentArgs(
                  url: link,
                  onFailed: () {
                    CommonMethods.showError(message: 'paymentFailed'.tr);
                  },
                  onSuccess: () {
                    NamedNavigatorImpl.push(
                      ShowDelegateOnMapScreen.routeName,
                      arguments: ShowDelegateOnMapArgs(
                        orderId: controller.orderId,
                        fee: int.parse(controller.actualPrice ?? '0'),
                        kmPrice:
                            (controller.delegatesOnMap?.shippingKmPrice ?? 0)
                                .round(),
                        shippingPercentage:
                            (controller
                                        .delegatesOnMap
                                        ?.shippingMinPricePrecentage ??
                                    10)
                                .round(),
                        distance: num.parse('${controller.distance}'),
                      ),
                    );
                    controller.reset();
                  },
                ),
              );
            }
          },
        );
      }
    } else if (controller.descriptionEC.text.isEmpty) {
      CommonMethods.showError(
        message: context.languageCode == 'ar'
            ? 'من فضلك اكتب الغرض المطلوب توصيله أولاً'
            : 'Please enter the item to be delivered first',
      );
    } else {
      CommonMethods.showToast(message: 'confirmDataNotEmpty'.tr);
    }
  }
}
