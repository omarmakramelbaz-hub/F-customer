import 'package:faskhaninja/view/layout/orders/model/orders_model.dart';
import 'package:faskhaninja/view/layout/orders/widgets/live_order_tracking_content.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _pumpContent(
  WidgetTester tester,
  LiveOrderTrackingContent content, {
  double width = 320,
  double textScale = 1.5,
}) async {
  await tester.binding.setSurfaceSize(Size(width, 740));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    MaterialApp(
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: TextScaler.linear(textScale),
          disableAnimations: true,
        ),
        child: child!,
      ),
      home: Scaffold(
        backgroundColor: const Color(0xFF092225),
        body: content,
      ),
    ),
  );
  await tester.pump();
}

Future<void> _tapKey(WidgetTester tester, String value) async {
  final finder = find.byKey(ValueKey(value));
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

OrdersModel _order() => OrdersModel(
      id: 710,
      orderNo: 'FS-710',
      resturantName: 'فرع المحلة الكبرى',
      status: 'shipped',
      totalItemPrice: 100,
      deliveryPrice: 50,
      serviceFees: 10,
      tax: 14,
      grandTotal: 199.99,
      paymentType: 'cash',
    );

void main() {
  testWidgets('expanded real order details fit 320 pixels at enlarged text', (
    tester,
  ) async {
    final order = _order()
      ..resturantName = 'فرع المحلة الكبرى لخدمة طلبات الأسماك المملحة والمدخنة'
      ..delegateName = 'محمد أحمد مندوب توصيل فرع المحلة الكبرى'
      ..delegateMobile = '01012345678'
      ..userAddress = UserAddress(
        address: 'شارع البحر، عمارة 15 بجوار مدخل السوق القديم',
        streetName: 'شارع البحر',
        floorNo: '3',
        apartmentNo: '7',
      )
      ..items = [
        Items(
          restaurantProduct: ResturantProduct(
            productName: 'رنجة مدخنة مخلي بعناية لتجهيز السفرة العائلية',
          ),
          qty: 12,
          productFeatureName: 'half',
          productClean: 'extra_clear',
          total: 121.75,
          updatedTotal: 100.25,
          reasonUpdateTotal: 'تعديل الوزن بعد التجهيز حسب الكمية الفعلية',
        ),
      ];
    await _pumpContent(
      tester,
      LiveOrderTrackingContent(
        order: order,
        onBack: () {},
        onRefresh: () {},
        showDelegate: true,
        showRestaurantDelegate: true,
        showSupport: true,
        onDelegateCall: () {},
        onDelegateChat: () {},
        onRestaurantCall: () {},
        onSupportCall: () {},
        onSupportChat: () {},
        onCancel: () {},
        onRate: () {},
        onTip: () {},
      ),
    );

    expect(tester.takeException(), isNull);
    await _tapKey(tester, 'tracking-items-toggle');
    expect(find.text('رنجة مدخنة مخلي بعناية لتجهيز السفرة العائلية'),
        findsOneWidget);
    expect(find.textContaining('نصف كيلو'), findsOneWidget);
    expect(find.textContaining('مخلي'), findsWidgets);
    expect(find.text('العدد: 12'), findsOneWidget);
    expect(find.textContaining('شارع البحر'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('financial summary preserves authoritative totals and payment', (
    tester,
  ) async {
    final order = _order()
      ..updatedTotalItemPrice = 80
      ..paymentType = 'v_cash';
    await _pumpContent(
      tester,
      LiveOrderTrackingContent(
        order: order,
        onBack: () {},
        onRefresh: () {},
      ),
    );

    expect(find.text('قيمة الأصناف'), findsOneWidget);
    expect(find.text('80.00 ج.م'), findsOneWidget);
    expect(find.text('50.00 ج.م'), findsOneWidget);
    expect(find.text('10.00 ج.م'), findsOneWidget);
    expect(find.text('14.00 ج.م'), findsOneWidget);
    // The server total deliberately differs from a locally computed sum.
    expect(find.text('199.99 ج.م'), findsOneWidget);
    expect(find.text('فودافون كاش'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('missing money stays unknown and explicit zero subtotal is kept',
      (
    tester,
  ) async {
    final order = OrdersModel(status: 'pending');
    await _pumpContent(
      tester,
      LiveOrderTrackingContent(
        order: order,
        onBack: () {},
        onRefresh: () {},
      ),
    );
    expect(find.text('—'), findsWidgets);
    expect(find.text('0.00 ج.م'), findsNothing);
    expect(find.textContaining('null'), findsNothing);

    order
      ..totalItemPrice = 72.25
      ..updatedTotalItemPrice = 0;
    await _pumpContent(
      tester,
      LiveOrderTrackingContent(
        order: order,
        onBack: () {},
        onRefresh: () {},
      ),
    );
    expect(find.text('0.00 ج.م'), findsOneWidget);
    expect(find.text('72.25 ج.م'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('only a real item price update shows old price and its reason', (
    tester,
  ) async {
    final order = _order()
      ..items = [
        Items(
          restaurantProduct: ResturantProduct(productName: 'فسيخ'),
          qty: 1,
          productFeatureName: 'kilo',
          productClean: 'extra_clean',
          total: 10,
          updatedTotal: null,
          reasonUpdateTotal: 'سبب غير صالح بدون تعديل',
        ),
        Items(
          restaurantProduct: ResturantProduct(productName: 'سردين'),
          qty: 2,
          productFeatureName: 'quarter',
          productClean: 'extra_combo',
          total: 20,
          updatedTotal: 0,
          reasonUpdateTotal: 'سبب غير صالح مع صفر',
        ),
        Items(
          restaurantProduct: ResturantProduct(productName: 'بطارخ'),
          qty: 1,
          total: 30,
          updatedTotal: 25,
          reasonUpdateTotal: 'تعديل الوزن الفعلي',
        ),
      ];
    await _pumpContent(
      tester,
      LiveOrderTrackingContent(
        order: order,
        onBack: () {},
        onRefresh: () {},
      ),
    );
    expect(find.text('بطارخ'), findsNothing);
    await _tapKey(tester, 'tracking-items-toggle');

    expect(find.text('25.00 ج.م'), findsOneWidget);
    expect(find.text('30.00 ج.م'), findsOneWidget);
    expect(find.textContaining('تعديل الوزن الفعلي'), findsOneWidget);
    expect(find.textContaining('سبب غير صالح'), findsNothing);
    expect(find.textContaining('ربع كيلو'), findsOneWidget);
    expect(find.textContaining('كومبو'), findsOneWidget);
    expect(find.textContaining('تنظيف'), findsOneWidget);
    expect(find.textContaining('تم تحويل'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('contact flags never expose unavailable actions', (tester) async {
    await _pumpContent(
      tester,
      LiveOrderTrackingContent(
        order: _order(),
        onBack: () {},
        onRefresh: () {},
        showDelegate: true,
        showRestaurantDelegate: true,
        showSupport: true,
      ),
    );
    for (final key in [
      'tracking-delegate-call',
      'tracking-delegate-chat',
      'tracking-restaurant-call',
      'tracking-support-call',
      'tracking-support-chat',
      'tracking-rate',
      'tracking-tip',
      'tracking-cancel',
    ]) {
      expect(find.byKey(ValueKey(key)), findsNothing);
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('available callbacks invoke only their requested actions', (
    tester,
  ) async {
    final called = <String, int>{};
    VoidCallback action(String name) =>
        () => called.update(name, (value) => value + 1, ifAbsent: () => 1);
    await _pumpContent(
      tester,
      LiveOrderTrackingContent(
        order: _order()
          ..delegateName = 'أحمد'
          ..delegateMobile = '01012345678',
        onBack: action('back'),
        onRefresh: action('refresh'),
        showDelegate: true,
        showRestaurantDelegate: true,
        showSupport: true,
        onDelegateCall: action('delegate-call'),
        onDelegateChat: action('delegate-chat'),
        onRestaurantCall: action('restaurant-call'),
        onSupportCall: action('support-call'),
        onSupportChat: action('support-chat'),
        onRate: action('rate'),
        onTip: action('tip'),
        onCancel: action('cancel'),
      ),
    );
    for (final action in [
      'back',
      'refresh',
      'delegate-call',
      'delegate-chat',
      'restaurant-call',
      'support-call',
      'support-chat',
      'rate',
      'tip',
      'cancel',
    ]) {
      await _tapKey(tester, 'tracking-$action');
      expect(called[action], 1);
    }
    expect(called.length, 10);
    expect(tester.takeException(), isNull);
  });

  testWidgets('refresh failure retains cached order and offers a working retry',
      (tester) async {
    var refreshes = 0;
    await _pumpContent(
      tester,
      LiveOrderTrackingContent(
        order: _order(),
        onBack: () {},
        onRefresh: () => refreshes++,
        refreshFailed: true,
      ),
    );

    expect(
      find.text('تعذّر تحديث الطلب. تفاصيل طلبك الأخيرة ما زالت ظاهرة.'),
      findsOneWidget,
    );
    expect(find.text('فرع المحلة الكبرى'), findsWidgets);
    expect(find.text('199.99 ج.م'), findsOneWidget);
    await _tapKey(tester, 'tracking-refresh-retry');
    expect(refreshes, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('refresh in progress prevents duplicate refresh requests', (
    tester,
  ) async {
    var refreshes = 0;
    await _pumpContent(
      tester,
      LiveOrderTrackingContent(
        order: _order(),
        onBack: () {},
        onRefresh: () => refreshes++,
        refreshing: true,
      ),
    );
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('tracking-refresh')));
    await tester.pump();
    expect(refreshes, 0);
    expect(find.text('199.99 ج.م'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
