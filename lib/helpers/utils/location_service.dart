import 'dart:async';
import 'dart:developer';

import 'package:location/location.dart';

class LocationService {
  LocationService({Location? location}) : _location = location ?? Location();

  final Location _location;
  StreamSubscription<LocationData>? _locationSubscription;
  bool _isListening = false;

  Future<LocationData?> getCurrentLocation() async {
    try {
      if (await checkAndRequestLocationService() &&
          await checkAndRequestLocationPermission()) {
        return await _location.getLocation();
      }
      return null;
    } catch (e) {
      log('Error getting location: $e');
      return null;
    }
  }

  Future<bool> checkAndRequestLocationService() async {
    bool serviceEnabled = await _location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await _location.requestService();
    }
    return serviceEnabled;
  }

  Future<bool> checkAndRequestLocationPermission() async {
    PermissionStatus permission = await _location.hasPermission();
    if (permission == PermissionStatus.deniedForever) return false;

    if (permission == PermissionStatus.denied) {
      permission = await _location.requestPermission();
    }

    return permission == PermissionStatus.granted;
  }

  void getLocationData(void Function(LocationData)? onData) {
    _locationSubscription?.cancel();
    _locationSubscription = _location.onLocationChanged.listen(onData);
    _isListening = true;
  }

  void pauseLocationStream() {
    if (_isListening) {
      _locationSubscription?.pause();
      _isListening = false;
    }
  }

  void resumeLocationStream() {
    if (_locationSubscription != null && !_isListening) {
      _locationSubscription?.resume();
      _isListening = true;
    }
  }

  void listenToLocation(void Function(LocationData) onData) {
    getLocationData(onData);
  }

  void dispose() {
    _locationSubscription?.cancel();
    _locationSubscription = null;
    _isListening = false;
  }
}
