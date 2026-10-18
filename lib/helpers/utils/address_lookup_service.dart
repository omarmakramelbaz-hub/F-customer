import 'dart:async';

import 'package:geocoding/geocoding.dart';

typedef PlacemarkLookup = Future<List<Placemark>> Function(
  double latitude,
  double longitude,
);

/// Shares only active lookups for identical coordinates. Completed results and
/// failures are discarded so subsequent requests always ask the geocoder again.
class AddressLookupService {
  AddressLookupService({PlacemarkLookup? geocode})
      : _geocode = geocode ?? placemarkFromCoordinates;

  final PlacemarkLookup _geocode;
  final _pending = <(double, double), Future<List<Placemark>>>{};

  Future<List<Placemark>> lookup(double latitude, double longitude) {
    final coordinates = (latitude, longitude);
    return _pending.putIfAbsent(coordinates, () {
      return Future<List<Placemark>>.sync(
        () => _geocode(latitude, longitude),
      ).whenComplete(() {
        _pending.remove(coordinates);
      });
    });
  }
}
