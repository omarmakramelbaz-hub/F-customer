import 'dart:async';

import 'package:faskhaninja/helpers/utils/location_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:location/location.dart';

class _FakeLocation extends Fake implements Location {
  _FakeLocation(this.changes);

  final Stream<LocationData> changes;

  @override
  Stream<LocationData> get onLocationChanged => changes;
}

void main() {
  late StreamController<LocationData> changes;
  late LocationService service;
  late LocationData location;

  setUp(() {
    changes = StreamController<LocationData>.broadcast(sync: true);
    service = LocationService(location: _FakeLocation(changes.stream));
    location = LocationData.fromMap({'latitude': 30.0, 'longitude': 31.0});
  });

  tearDown(() async {
    service.dispose();
    await changes.close();
  });

  test('disposing stops callbacks registered through getLocationData', () {
    final received = <LocationData>[];
    service.getLocationData(received.add);
    changes.add(location);
    service.dispose();
    changes.add(location);

    expect(received, [location]);
    expect(changes.hasListener, isFalse);
  });

  test('replacing a location listener cancels the previous listener', () {
    final previous = <LocationData>[];
    final current = <LocationData>[];
    service.getLocationData(previous.add);
    service.listenToLocation(current.add);
    changes.add(location);

    expect(previous, isEmpty);
    expect(current, [location]);
  });

  test(
    'repeated pause needs only one resume to deliver pending updates',
    () async {
      final received = <LocationData>[];
      service.getLocationData(received.add);
      service.pauseLocationStream();
      service.pauseLocationStream();
      changes.add(location);
      expect(received, isEmpty);

      service.resumeLocationStream();
      await Future<void>.delayed(Duration.zero);

      expect(received, [location]);
    },
  );
}
