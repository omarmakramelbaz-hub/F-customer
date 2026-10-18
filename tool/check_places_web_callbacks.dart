// Standalone JavaScript smoke check for the Google Places callback bridge.
// ignore_for_file: avoid_web_libraries_in_flutter

import 'dart:js' as js;

import 'package:faskhaninja/view/layout/map/utils/places_autocomplete_bridge_web.dart';

Future<void> main() async {
  js.context.callMethod('eval', [
    r'''
globalThis.google = { maps: {
  places: { AutocompleteService: function() {
    this.getPlacePredictions = function(request, callback) {
      callback.call({ marker: 'ignored' }, [{ description: request.input, place_id: 'place-cairo' }], 'OK');
    };
  } },
  Geocoder: function() {
    this.geocode = function(request, callback) {
      callback.call({ marker: 'ignored' }, [{ formatted_address: 'Cairo address', geometry: { location: { lat: function() { return 30; }, lng: function() { return 31; } } } }], 'OK');
    };
  }
} };
''',
  ]);
  final predictions = await getWebPlacePredictions(input: 'Cairo');
  if (predictions.length != 1 ||
      predictions.single.description != 'Cairo' ||
      predictions.single.placeId != 'place-cairo') {
    throw StateError('Prediction callback arguments were not preserved');
  }
  final details = await getWebPlaceDetails(placeId: 'place-cairo');
  if (details == null ||
      details.formattedAddress != 'Cairo address' ||
      details.latitude != 30.0 ||
      details.longitude != 31.0) {
    throw StateError('Geocoder callback arguments were not preserved');
  }
}
