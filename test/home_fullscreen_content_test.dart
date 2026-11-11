import 'package:faskhaninja/view/layout/home/widgets/home_fullscreen_content.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _courierActionKey = ValueKey('test-courier-action');
const _courierCardKey = ValueKey('test-courier-card');

Future<void> _pumpHome(
  WidgetTester tester, {
  double textScale = 1,
  double bottomInset = 0,
  ScrollController? controller,
  VoidCallback? onStartOrder,
  VoidCallback? onCompetition,
  VoidCallback? onChangeAddress,
  VoidCallback? onCourier,
}) async {
  await tester.binding.setSurfaceSize(const Size(320, 568));
  addTearDown(() => tester.binding.setSurfaceSize(null));

  await tester.pumpWidget(
    MaterialApp(
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: TextScaler.linear(textScale)),
        child: child!,
      ),
      home: Scaffold(
        backgroundColor: const Color(0xFF08282E),
        body: LayoutBuilder(
          builder: (context, constraints) => Stack(
            children: [
              SingleChildScrollView(
                controller: controller,
                child: HomeFullscreenContent(
                  minHeight: constraints.maxHeight,
                  bottomInset: bottomInset,
                  onStartOrder: onStartOrder ?? () {},
                  onCompetition: onCompetition ?? () {},
                  onChangeAddress: onChangeAddress ?? () {},
                  header: const SizedBox(
                    height: 84,
                    child: Center(child: Text('التوصيل إلى المحلة الكبرى')),
                  ),
                  competition: const AspectRatio(
                    aspectRatio: 1320 / 502,
                    child: ColoredBox(color: Color(0xFF173D45)),
                  ),
                  branches: const SizedBox(
                    height: 84,
                    child: Center(child: Text('فرع المحلة الكبرى')),
                  ),
                  courier: SizedBox(
                    key: _courierCardKey,
                    height: 128,
                    child: Center(
                      child: ElevatedButton(
                        key: _courierActionKey,
                        onPressed: onCourier ?? () {},
                        child: const Text('اطلب مندوب'),
                      ),
                    ),
                  ),
                ),
              ),
              if (bottomInset > 0)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  height: bottomInset,
                  child: const ColoredBox(color: Color(0xFF041A1F)),
                ),
            ],
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  for (final textScale in [1.0, 1.5]) {
    testWidgets(
      'narrow home scrolls without overflow at text scale $textScale',
      (tester) async {
        await _pumpHome(tester, textScale: textScale);

        expect(tester.takeException(), isNull);
        expect(find.byType(TextField), findsNothing);
        expect(find.byType(TextFormField), findsNothing);
        expect(find.textContaining('الفرع الحالي'), findsNothing);
        expect(find.textContaining('ابحث'), findsNothing);

        await tester.scrollUntilVisible(
          find.byKey(_courierActionKey),
          180,
          scrollable: find.byType(Scrollable),
        );
        await tester.pumpAndSettle();

        expect(find.byKey(_courierActionKey).hitTestable(), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('order, competition and address actions remain independent', (
    tester,
  ) async {
    var orders = 0;
    var competitions = 0;
    var addressChanges = 0;
    await _pumpHome(
      tester,
      onStartOrder: () => orders++,
      onCompetition: () => competitions++,
      onChangeAddress: () => addressChanges++,
    );

    final order = find.widgetWithText(ElevatedButton, 'ابدأ طلبك');
    await tester.ensureVisible(order);
    await tester.tap(order);
    await tester.pump();
    expect([orders, competitions, addressChanges], [1, 0, 0]);

    final competition = find.widgetWithText(TextButton, 'شارك الآن');
    await tester.ensureVisible(competition);
    await tester.tap(competition);
    await tester.pump();
    expect([orders, competitions, addressChanges], [1, 1, 0]);

    final address = find.widgetWithText(TextButton, 'تغيير العنوان');
    await tester.ensureVisible(address);
    await tester.tap(address);
    await tester.pump();
    expect([orders, competitions, addressChanges], [1, 1, 1]);
    expect(tester.takeException(), isNull);
  });

  testWidgets('last service remains reachable above the bottom controls', (
    tester,
  ) async {
    const bottomInset = 96.0;
    final controller = ScrollController();
    addTearDown(controller.dispose);
    var courierRequests = 0;
    await _pumpHome(
      tester,
      textScale: 1.5,
      bottomInset: bottomInset,
      controller: controller,
      onCourier: () => courierRequests++,
    );

    expect(controller.position.maxScrollExtent, greaterThan(0));
    controller.jumpTo(controller.position.maxScrollExtent);
    await tester.pumpAndSettle();

    final contentRect = tester.getRect(find.byKey(_courierCardKey));
    final viewportRect = tester.getRect(find.byType(SingleChildScrollView));
    expect(
      contentRect.bottom,
      lessThanOrEqualTo(viewportRect.bottom - bottomInset),
    );
    expect(find.byKey(_courierActionKey).hitTestable(), findsOneWidget);
    await tester.tap(find.byKey(_courierActionKey));
    await tester.pump();
    expect(courierRequests, 1);
    expect(tester.takeException(), isNull);
  });
}
