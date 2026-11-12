import 'dart:math' as math;

import 'package:faskhaninja/helpers/theme/app_colors.dart';
import 'package:faskhaninja/helpers/theme/fasakhansta_brand.dart';
import 'package:faskhaninja/helpers/theme/theme.dart';
import 'package:faskhaninja/helpers/translation/all_translation.dart';
import 'package:faskhaninja/view/custom_widgets/buttons/custom_button.dart';
import 'package:faskhaninja/view/custom_widgets/custom_form_field/custom_form_field.dart';
import 'package:faskhaninja/view/custom_widgets/page_container/page_container.dart';
import 'package:faskhaninja/view/layout/home/model/draw_badge.dart';
import 'package:faskhaninja/view/layout/restaurants/widgets/menu_product_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

double contrast(Color a, Color b) {
  final x = a.computeLuminance(), y = b.computeLuminance();
  return (math.max(x, y) + .05) / (math.min(x, y) + .05);
}

Future<void> mount(WidgetTester tester, Widget child) async {
  await tester.pumpWidget(
    Builder(
      builder: (context) {
        return MaterialApp(
          theme: theme(context),
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(disableAnimations: true),
            child: FasakhanstaAppBackground(child: child!),
          ),
          home: Directionality(textDirection: TextDirection.rtl, child: child),
        );
      },
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    GlobalTranslations.locale = const Locale('ar');
  });

  test('content, form and action text meet readable contrast', () {
    for (final surface in [
      FasakhanstaBrand.background,
      FasakhanstaBrand.surface,
      FasakhanstaBrand.surfaceRaised,
      FasakhanstaBrand.field,
    ]) {
      expect(
        contrast(FasakhanstaBrand.text, surface),
        greaterThanOrEqualTo(4.5),
      );
      expect(
        contrast(FasakhanstaBrand.muted, surface),
        greaterThanOrEqualTo(4.5),
      );
    }
    for (final accent in FasakhanstaBrand.buttonGradient.colors) {
      expect(
        contrast(FasakhanstaBrand.onOrange, accent),
        greaterThanOrEqualTo(4.5),
      );
    }
    // Pure white must stay white for artwork and externally hosted content.
    expect(AppColors.whiteColor, Colors.white);
  });

  testWidgets('shared background preserves input, validation and button taps', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(360, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final key = GlobalKey<FormState>();
    final input = TextEditingController();
    addTearDown(input.dispose);
    var accepted = 0;
    await mount(
      tester,
      Scaffold(
        body: MediaQuery(
          data: const MediaQueryData(
              size: Size(360, 800), textScaler: TextScaler.linear(1.6)),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: key,
              child: Column(
                children: [
                  CustomFormField(
                    controller: input,
                    title: 'الاسم',
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? 'مطلوب' : null,
                  ),
                  const SizedBox(height: 20),
                  CustomButton(
                    text: 'حفظ',
                    onPressed: () {
                      if (key.currentState!.validate()) accepted++;
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    expect(
      Theme.of(tester.element(find.byType(Scaffold))).brightness,
      Brightness.dark,
    );
    await tester.tap(find.text('حفظ'));
    await tester.pumpAndSettle();
    expect(find.text('مطلوب'), findsOneWidget);
    expect(accepted, 0);
    await tester.enterText(find.byType(TextFormField), 'عمر');
    await tester.tap(find.text('حفظ'));
    await tester.pumpAndSettle();
    expect(accepted, 1);
    expect(input.text, 'عمر');
    expect(find.text('مطلوب'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('secondary button keeps its explicit surface and callback', (
    tester,
  ) async {
    var taps = 0;
    await mount(
      tester,
      Scaffold(
        body: Center(
          child: CustomButton(
            text: 'رجوع',
            width: 180,
            color: FasakhanstaBrand.surfaceRaised,
            isMainColor: false,
            onPressed: () => taps++,
          ),
        ),
      ),
    );
    final container = tester.widget<Container>(
      find
          .descendant(
            of: find.byType(CustomButton),
            matching: find.byType(Container),
          )
          .first,
    );
    final decoration = container.decoration! as BoxDecoration;
    expect(decoration.gradient, isNull);
    expect(decoration.color, FasakhanstaBrand.surfaceRaised);
    final text = tester.widget<Text>(find.text('رجوع'));
    expect(
      contrast(text.style!.color!, decoration.color!),
      greaterThanOrEqualTo(4.5),
    );
    await tester.tap(find.text('رجوع'));
    expect(taps, 1);
  });

  testWidgets('safe-area pages use light system icons on the dark identity', (
    tester,
  ) async {
    await mount(
      tester,
      const Scaffold(body: PageContainer(child: Text('فسخانستا'))),
    );
    final region = tester.widget<AnnotatedRegion<SystemUiOverlayStyle>>(
      find.descendant(
        of: find.byType(PageContainer),
        matching: find.byType(AnnotatedRegion<SystemUiOverlayStyle>),
      ),
    );
    expect(region.value.statusBarIconBrightness, Brightness.light);
  });

  testWidgets(
    'regular cards use dark surfaces while eligible cards keep gold',
    (tester) async {
      for (final eligible in [false, true]) {
        await mount(
          tester,
          Scaffold(
            body: Center(
              child: SizedBox(
                width: 210,
                height: 300,
                child: MenuProductCard(
                  name: 'فسيخ فاخر',
                  priceLabel: '٣٦٠ ج',
                  image: const ColoredBox(color: Colors.transparent),
                  draw: eligible
                      ? const DrawBadge(label: 'معاينة', prizeAmount: 5000)
                      : null,
                  onTap: () {},
                ),
              ),
            ),
          ),
        );
        final surface = tester
            .widget<DecoratedBox>(
              find
                  .descendant(
                    of: find.byType(MenuProductCard),
                    matching: find.byType(DecoratedBox),
                  )
                  .first,
            )
            .decoration as BoxDecoration;
        final name = tester.widget<Text>(find.text('فسيخ فاخر'));
        expect(
          contrast(name.style!.color!, surface.color!),
          greaterThanOrEqualTo(4.5),
        );
        expect(
          surface.color,
          eligible ? const Color(0xFFFFFAEF) : FasakhanstaBrand.surface,
        );
        expect(
          find.text('هذا المنتج يؤهلك للسحب'),
          eligible ? findsOneWidget : findsNothing,
        );
        expect(tester.takeException(), isNull);
      }
    },
  );
}
