import 'dart:io';

import 'package:faskhaninja/helpers/hive/hive_methods.dart';
import 'package:faskhaninja/helpers/routes/app_routers_import.dart';
import 'package:faskhaninja/helpers/translation/all_translation.dart';
import 'package:faskhaninja/view/layout/orders/model/orders_model.dart';
import 'package:faskhaninja/view/layout/orders/screen/request_again_screen.dart';
import 'package:faskhaninja/view/layout/orders/screen/tracking_your_order_screen.dart';
import 'package:faskhaninja/view/layout/orders/widgets/in_preparation_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:intl/date_symbol_data_local.dart';

OrdersModel _order(String status, {int id = 501}) => OrdersModel(
      id: id,
      orderNo: 'TEST-$status',
      status: status,
      resturantName: 'فرع الاختبار',
      grandTotal: 80,
      createdAt: '2026-11-11T12:00:00Z',
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory hiveDirectory;

  setUpAll(() async {
    hiveDirectory = await Directory.systemTemp.createTemp('order-card-test-');
    Hive.init(hiveDirectory.path);
    await Hive.openBox<dynamic>('app');
    await HiveMethods.updateToken('synthetic-order-card-test-token');
    await initializeDateFormatting('en');
    await GlobalTranslations.setNewLanguage('ar', false);
  });

  tearDownAll(() async {
    await HiveMethods.deleteToken();
    await Hive.close();
    await hiveDirectory.delete(recursive: true);
  });

  testWidgets(
      'every valid order card opens its receipt while explicit reorder stays separate',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(480, 900));
    final card = ValueNotifier(_order('completed'));
    final destinations = <RouteSettings>[];
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox.shrink());
      card.dispose();
      await tester.binding.setSurfaceSize(null);
    });

    // NamedNavigatorImpl retains its first NavigatorState. Keep one real
    // Navigator for the whole navigation contract instead of replacing it.
    await tester.pumpWidget(MaterialApp(
      navigatorKey: NamedNavigatorImpl.navigatorState,
      theme: ThemeData(fontFamily: 'Tajawal'),
      onGenerateRoute: (settings) {
        destinations.add(settings);
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => const Scaffold(
            body: Center(child: Text('intercepted-order-destination')),
          ),
        );
      },
      home: Scaffold(
        body: SingleChildScrollView(
          child: ValueListenableBuilder<OrdersModel>(
            valueListenable: card,
            // The existing image placeholder is decorative to navigation.
            builder: (_, order, __) => TickerMode(
              enabled: false,
              child: InPreparationWidget(orders: order),
            ),
          ),
        ),
      ),
    ));
    await tester.pumpAndSettle();

    for (final status in [
      'completed',
      'pending',
      'accepted',
      'shipped',
      'cancelled',
      'declined',
    ]) {
      card.value = _order(status);
      await tester.pumpAndSettle();
      final destinationsBeforeTap = destinations.length;

      // Tap the card body, away from its independently actionable footer.
      await tester.tap(find.text('TEST-$status'));
      await tester.pumpAndSettle();

      expect(destinations.length, destinationsBeforeTap + 1, reason: status);
      expect(destinations.last.name, TrackingYourOrderScreen.routeName,
          reason: 'The $status card should inspect the original order');
      expect(destinations.last.arguments, isA<TrackingYourOrderArgs>());
      expect((destinations.last.arguments as TrackingYourOrderArgs).id, 501);
      expect(find.text('intercepted-order-destination'), findsOneWidget);
      NamedNavigatorImpl.navigatorState.currentState!.pop();
      await tester.pumpAndSettle();
    }

    card.value = _order('completed');
    await tester.pumpAndSettle();
    final destinationsBeforeReorder = destinations.length;
    await tester.tap(find.text('اطلب مجددًا'));
    await tester.pumpAndSettle();

    expect(destinations.length, destinationsBeforeReorder + 1);
    expect(destinations.last.name, RequestAgainScreen.routeName);
    expect(destinations.last.arguments, isA<RequestAgainArgs>());
    expect((destinations.last.arguments as RequestAgainArgs).id, 501);
    NamedNavigatorImpl.navigatorState.currentState!.pop();
    await tester.pumpAndSettle();

    card.value = _order('completed', id: 0);
    await tester.pumpAndSettle();
    final destinationsBeforeInvalidCard = destinations.length;
    await tester.tap(find.text('TEST-completed'));
    await tester.pumpAndSettle();
    expect(destinations.length, destinationsBeforeInvalidCard);
    expect(tester.takeException(), isNull);
  });
}
