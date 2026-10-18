import 'dart:async';

import 'package:faskhaninja/helpers/utils/address_lookup_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geocoding/geocoding.dart';

void main() {
  test('eight simultaneous lookups use one geocoder call instead of eight',
      () async {
    const expected = [Placemark(name: 'Cairo')];
    final beforeGate = Completer<List<Placemark>>();
    var beforeCalls = 0;
    Future<List<Placemark>> directLookup() {
      beforeCalls++;
      return beforeGate.future;
    }

    final before = List.generate(8, (_) => directLookup());
    expect(beforeCalls, 8);
    beforeGate.complete(expected);
    expect(await Future.wait(before), everyElement(expected));

    final afterGate = Completer<List<Placemark>>();
    var afterCalls = 0;
    final service = AddressLookupService(geocode: (latitude, longitude) {
      afterCalls++;
      return afterGate.future;
    });
    final after = List.generate(8, (_) => service.lookup(30, 31));
    expect(afterCalls, 1);
    afterGate.complete(expected);
    expect(await Future.wait(after), everyElement(expected));
  });

  test('completed results are discarded and the next lookup stays fresh',
      () async {
    var calls = 0;
    final service = AddressLookupService(geocode: (latitude, longitude) async {
      calls++;
      return [Placemark(name: 'result-$calls')];
    });

    expect((await service.lookup(30, 31)).single.name, 'result-1');
    expect((await service.lookup(30, 31)).single.name, 'result-2');
    expect(calls, 2);
  });

  test('different coordinates run independently without rounding', () async {
    final firstGate = Completer<List<Placemark>>();
    final secondGate = Completer<List<Placemark>>();
    final calledWith = <(double, double)>[];
    final service = AddressLookupService(geocode: (latitude, longitude) {
      calledWith.add((latitude, longitude));
      return calledWith.length == 1 ? firstGate.future : secondGate.future;
    });

    final first = service.lookup(30, 31);
    final second = service.lookup(30.0000001, 31);
    expect(calledWith, [(30.0, 31.0), (30.0000001, 31.0)]);
    firstGate.complete(const [Placemark(name: 'first')]);
    secondGate.complete(const [Placemark(name: 'second')]);
    expect((await first).single.name, 'first');
    expect((await second).single.name, 'second');
  });

  test('a failed active request is shared and a retry starts a new lookup',
      () async {
    final gate = Completer<List<Placemark>>();
    var calls = 0;
    final service = AddressLookupService(geocode: (latitude, longitude) {
      calls++;
      return calls == 1
          ? gate.future
          : Future.value(const [Placemark(name: 'retry')]);
    });

    final first = expectLater(service.lookup(30, 31), throwsStateError);
    final second = expectLater(service.lookup(30, 31), throwsStateError);
    expect(calls, 1);
    gate.completeError(StateError('temporary geocoder failure'));
    await Future.wait([first, second]);

    expect((await service.lookup(30, 31)).single.name, 'retry');
    expect(calls, 2);
  });

  test('synchronous failures are discarded so future attempts can retry',
      () async {
    var calls = 0;
    final service = AddressLookupService(geocode: (latitude, longitude) {
      calls++;
      throw StateError('unavailable');
    });

    await expectLater(service.lookup(30, 31), throwsStateError);
    await expectLater(service.lookup(30, 31), throwsStateError);
    expect(calls, 2);
  });
}
