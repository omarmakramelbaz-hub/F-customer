import 'package:faskhaninja/helpers/theme/fasakhansta_brand.dart';

import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';

import '../../../../helpers/theme/app_colors.dart';
import '../../map/utils/map_services.dart';
import '../controller/request_delegate_controller.dart';

class CustomGoogleMapsWidget extends StatefulWidget {
  const CustomGoogleMapsWidget({
    super.key,
    required this.addressLat,
    required this.addressLan,
    this.showCircle,
    this.showRoute = false,
    this.deliveryLat,
    this.deliveryLan,
  });

  final double addressLat;
  final double addressLan;
  final bool? showCircle;
  final bool showRoute;
  final double? deliveryLat;
  final double? deliveryLan;

  @override
  State<CustomGoogleMapsWidget> createState() => _CustomGoogleMapsWidgetState();
}

class _CustomGoogleMapsWidgetState extends State<CustomGoogleMapsWidget> {
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

  final MapServices _mapServices = MapServices();

  GoogleMapController? googleMapController;
  Set<Marker> markers = {};
  Set<Circle> circles = {};
  Set<Polyline> polylines = {};

  BitmapDescriptor? _riderIcon;
  BitmapDescriptor? _pickupGoDriveIcon;
  BitmapDescriptor? _deliveryPinIcon;

  Timer? _searchAnimationTimer;
  double _searchAngle = 0;
  String? _routeKey;
  bool _delegateResponded = false;
  LatLng? _controllerDelivery;

  LatLng get _pickup => LatLng(widget.addressLat, widget.addressLan);

  LatLng? get _delivery {
    if (_controllerDelivery != null) return _controllerDelivery;
    final lat = widget.deliveryLat;
    final lng = widget.deliveryLan;
    if (lat == null || lng == null || lat == 0 || lng == 0) return null;
    return LatLng(lat, lng);
  }

  bool get _canShowRoute =>
      (_delegateResponded || widget.showRoute) && _delivery != null;

  @override
  void initState() {
    super.initState();
    _loadMarkerIcons().then((_) {
      if (mounted) _refreshMapState(moveCamera: false);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _refreshMapState(moveCamera: false);
    });
  }

  @override
  void didUpdateWidget(covariant CustomGoogleMapsWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.addressLat != widget.addressLat ||
        oldWidget.addressLan != widget.addressLan ||
        oldWidget.deliveryLat != widget.deliveryLat ||
        oldWidget.deliveryLan != widget.deliveryLan ||
        oldWidget.showRoute != widget.showRoute ||
        oldWidget.showCircle != widget.showCircle) {
      _routeKey = null;
      _refreshMapState(moveCamera: true);
    }
  }

  @override
  void dispose() {
    _searchAnimationTimer?.cancel();
    googleMapController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<RequestDelegateController>();
    _scheduleControllerSync(controller);

    return GoogleMap(
      circles: circles,
      polylines: polylines,
      zoomControlsEnabled: false,
      style: _cleanLightMapStyle,
      markers: markers,
      mapToolbarEnabled: false,
      compassEnabled: false,
      myLocationButtonEnabled: false,
      minMaxZoomPreference: const MinMaxZoomPreference(7.0, 19.0),
      onMapCreated: (controller) {
        googleMapController = controller;
        _refreshMapState(moveCamera: true);
      },
      initialCameraPosition: CameraPosition(target: _pickup, zoom: 14.5),
    );
  }

  void _scheduleControllerSync(RequestDelegateController controller) {
    final delegates = controller.acceptedDelegate?.delegates;
    final responded = delegates?.isNotEmpty == true;
    final order = controller.acceptedDelegate?.order;

    final toLat = double.tryParse('${order?.toLat ?? controller.toLat ?? ''}');
    final toLng = double.tryParse('${order?.toLng ?? controller.toLan ?? ''}');
    final nextDelivery =
        toLat != null && toLng != null && toLat != 0 && toLng != 0
            ? LatLng(toLat, toLng)
            : null;

    final deliveryChanged =
        (_controllerDelivery?.latitude != nextDelivery?.latitude) ||
            (_controllerDelivery?.longitude != nextDelivery?.longitude);

    if (_delegateResponded == responded && !deliveryChanged) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _delegateResponded = responded;
      _controllerDelivery = nextDelivery;
      _routeKey = null;
      _refreshMapState(moveCamera: true);
    });
  }

  Future<void> _loadMarkerIcons() async {
    try {
      _riderIcon = await BitmapDescriptor.asset(
        const ImageConfiguration(),
        'assets/images/deliveryRiderV2.png',
        height: 62,
      );
    } catch (_) {}

    try {
      _deliveryPinIcon = await BitmapDescriptor.asset(
        const ImageConfiguration(),
        'assets/images/deliveryLocationPin.png',
        height: 44,
      );
    } catch (_) {}

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
      if (markerBytes != null) {
        _pickupGoDriveIcon = BitmapDescriptor.fromBytes(
          markerBytes.buffer.asUint8List(),
        );
      }
    } catch (_) {}
  }

  void _refreshMapState({required bool moveCamera}) {
    if (!mounted) return;

    if (_canShowRoute) {
      _stopSearchingAnimation();
      _showRouteState(moveCamera: moveCamera);
    } else {
      _showSearchingState(moveCamera: moveCamera);
    }
  }

  void _showSearchingState({required bool moveCamera}) {
    polylines = {};
    _routeKey = null;

    circles = widget.showCircle == true
        ? {
            Circle(
              circleId: const CircleId('goDriveSearchRadius'),
              center: _pickup,
              radius: 1000,
              fillColor: AppColors.mainAppColor.withValues(alpha: .07),
              strokeColor: AppColors.mainAppColor.withValues(alpha: .42),
              strokeWidth: 2,
            ),
          }
        : {};

    _updateSearchingRider();
    _startSearchingAnimation();

    if (mounted) setState(() {});
    if (moveCamera) _focusSearchArea();
  }

  void _startSearchingAnimation() {
    if (_searchAnimationTimer?.isActive == true || _canShowRoute) return;

    _searchAnimationTimer = Timer.periodic(const Duration(milliseconds: 60), (
      _,
    ) {
      if (!mounted || _canShowRoute) return;
      _searchAngle += 0.045;
      if (_searchAngle >= math.pi * 2) {
        _searchAngle -= math.pi * 2;
      }
      _updateSearchingRider();
      if (mounted) setState(() {});
    });
  }

  void _stopSearchingAnimation() {
    _searchAnimationTimer?.cancel();
    _searchAnimationTimer = null;
  }

  void _updateSearchingRider() {
    final riderPosition = _pointOnSearchCircle(
      center: _pickup,
      radiusMeters: 760,
      angle: _searchAngle,
    );

    markers = {
      Marker(
        markerId: const MarkerId('searchingRider'),
        position: riderPosition,
        icon: _riderIcon ??
            BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
        anchor: const Offset(.5, .5),
        zIndex: 30,
      ),
    };
  }

  LatLng _pointOnSearchCircle({
    required LatLng center,
    required double radiusMeters,
    required double angle,
  }) {
    const metersPerDegree = 111320.0;
    final latRadians = center.latitude * math.pi / 180;
    final latOffset = (radiusMeters / metersPerDegree) * math.cos(angle);
    final cosLat = math.cos(latRadians).abs().clamp(.1, 1.0).toDouble();
    final lngOffset =
        (radiusMeters / (metersPerDegree * cosLat)) * math.sin(angle);

    return LatLng(center.latitude + latOffset, center.longitude + lngOffset);
  }

  Future<void> _showRouteState({required bool moveCamera}) async {
    final delivery = _delivery;
    if (delivery == null) return;

    circles = {};
    markers = {
      Marker(
        markerId: const MarkerId('goDrivePickup'),
        position: _pickup,
        icon: _pickupGoDriveIcon ??
            _riderIcon ??
            BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
        anchor: const Offset(.31, 1),
        zIndex: 100,
        infoWindow: const InfoWindow(
          title: 'GO Drive',
          snippet: 'نقطة الاستلام',
        ),
      ),
      Marker(
        markerId: const MarkerId('goDriveDelivery'),
        position: delivery,
        icon: _deliveryPinIcon ??
            BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        zIndex: 90,
        infoWindow: const InfoWindow(title: 'نقطة التوصيل'),
      ),
    };
    if (mounted) setState(() {});

    final key =
        '${_pickup.latitude},${_pickup.longitude}|${delivery.latitude},${delivery.longitude}';
    if (_routeKey != key) {
      _routeKey = key;
      await _loadRoute(_pickup, delivery, key);
    } else if (moveCamera) {
      await _fitEndpoints(_pickup, delivery);
    }
  }

  Future<void> _loadRoute(LatLng pickup, LatLng delivery, String key) async {
    try {
      final route = await _mapServices.getRouteData(
        originFrom: pickup,
        desintation: delivery,
      );
      if (!mounted || _routeKey != key) return;

      if (route.length >= 2) {
        final points = <LatLng>[pickup, ...route, delivery];
        setState(() {
          polylines = {
            Polyline(
              polylineId: const PolylineId('goDriveAcceptedRoute'),
              points: points,
              color: AppColors.mainAppColor,
              width: 5,
              startCap: Cap.roundCap,
              endCap: Cap.roundCap,
              jointType: JointType.round,
            ),
          };
        });
      } else {
        setState(() => polylines = {});
      }
    } catch (_) {
      if (mounted && _routeKey == key) {
        setState(() => polylines = {});
      }
    }

    await _fitEndpoints(pickup, delivery);
  }

  Future<void> _focusSearchArea() async {
    final controller = googleMapController;
    if (controller == null) return;

    try {
      await controller.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: _pickup, zoom: 14.1),
        ),
      );
    } catch (_) {}
  }

  Future<void> _fitEndpoints(LatLng pickup, LatLng delivery) async {
    final controller = googleMapController;
    if (controller == null) return;

    final south = math.min(pickup.latitude, delivery.latitude);
    final north = math.max(pickup.latitude, delivery.latitude);
    final west = math.min(pickup.longitude, delivery.longitude);
    final east = math.max(pickup.longitude, delivery.longitude);

    try {
      if ((north - south).abs() < .0002 && (east - west).abs() < .0002) {
        await controller.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(target: pickup, zoom: 16),
          ),
        );
        return;
      }

      await controller.animateCamera(
        CameraUpdate.newLatLngBounds(
          LatLngBounds(
            southwest: LatLng(south, west),
            northeast: LatLng(north, east),
          ),
          70,
        ),
      );
    } catch (_) {
      final center = LatLng(
        (pickup.latitude + delivery.latitude) / 2,
        (pickup.longitude + delivery.longitude) / 2,
      );
      await controller.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: center, zoom: 13),
        ),
      );
    }
  }
}
