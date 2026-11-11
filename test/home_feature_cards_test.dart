import 'package:faskhaninja/helpers/networking/api_helper.dart';
import 'package:faskhaninja/view/layout/home/controller/home_controller.dart';
import 'package:faskhaninja/view/layout/home/model/coupon_model.dart';
import 'package:faskhaninja/view/layout/home/widgets/home_feature_cards.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _HomeControllerForCardTest extends HomeController {
  _HomeControllerForCardTest(this.responseState, this.dashboardImage);

  final ResponseState responseState;
  final String? dashboardImage;

  @override
  CouponModel? get coupon => dashboardImage == null
      ? null
      : CouponModel(flag: 'coupon', data: Data(image: dashboardImage));

  @override
  ApiResponse get couponResponse =>
      ApiResponse(state: responseState, data: null);
}

Future<void> _pumpCompetitionCard(
  WidgetTester tester, {
  required ResponseState responseState,
  double textScale = 1.5,
  String? dashboardImage,
}) async {
  await tester.binding.setSurfaceSize(const Size(320, 568));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  final controller = _HomeControllerForCardTest(responseState, dashboardImage);
  addTearDown(controller.dispose);

  await tester.pumpWidget(
    MaterialApp(
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: TextScaler.linear(textScale)),
        child: child!,
      ),
      home: Scaffold(
        backgroundColor: const Color(0xFF092225),
        body: Directionality(
          textDirection: TextDirection.rtl,
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: HomeFeatureCards(
                controller: controller,
                padding: EdgeInsets.zero,
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  for (final state in [ResponseState.complete, ResponseState.error]) {
    testWidgets(
      'competition without an image fits a narrow screen in $state state',
      (tester) async {
        await _pumpCompetitionCard(tester, responseState: state);

        expect(find.text('مسابقة فسخانستا'), findsOneWidget);
        expect(find.text('تفاصيل المسابقة وطريقة الاشتراك'), findsOneWidget);
        expect(find.text('شوف المسابقة'), findsOneWidget);
        expect(tester.takeException(), isNull);

        final normalHeight =
            tester.getSize(find.byType(HomeFeatureCards)).height;
        await _pumpCompetitionCard(tester, responseState: state, textScale: 2);

        expect(tester.takeException(), isNull);
        expect(
          tester.getSize(find.byType(HomeFeatureCards)).height,
          greaterThan(normalHeight),
        );
      },
    );
  }

  testWidgets('pending competition image shows loading instead of prize art', (
    tester,
  ) async {
    await _pumpCompetitionCard(tester, responseState: ResponseState.loading);

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('مسابقة فسخانستا'), findsNothing);
    expect(find.byIcon(Icons.emoji_events_outlined), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('failed dashboard image keeps competition readable at large text',
      (
    tester,
  ) async {
    await _pumpCompetitionCard(
      tester,
      responseState: ResponseState.complete,
      textScale: 2.5,
      dashboardImage: 'https://example.invalid/selected-contest.webp',
    );
    // Widget tests reject network requests with HTTP 400.
    await tester.pumpAndSettle();

    expect(find.text('شوف تفاصيل المسابقة'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
