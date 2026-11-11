import 'package:faskhaninja/view/layout/home/model/coupon_model.dart';
import 'package:faskhaninja/view/layout/home/model/draw_badge.dart';
import 'package:faskhaninja/view/layout/home/widgets/draw_badge_chip.dart';
import 'package:flutter/material.dart';
import 'package:faskhaninja/view/layout/restaurants/model/products_restaurant_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('an item chosen for a draw carries its badge; another item none', () {
    final chosen = ResturantItems.fromJson({
      'id': 10,
      'product_name': 'فسيخ كيلو',
      'draw': {'coupon_wheel_id': 1, 'label': 'يؤهلك للدخول في السحب بقيمة 5,000 جنيه', 'prize_amount': 5000.0, 'end_date': '2026-11-30'},
    });
    expect(chosen.draw?.label, 'يؤهلك للدخول في السحب بقيمة 5,000 جنيه');
    expect(chosen.draw?.couponWheelId, 1);
    expect(chosen.draw?.prizeAmount, 5000);
    expect(ResturantItems.fromJson({'id': 11, 'draw': null}).draw, isNull);
    expect(ResturantItems.fromJson({'id': 12}).draw, isNull, reason: 'Older servers send no draw');
  });

  test('the draw screen reads the draws by products, the customer codes and the winning codes', () {
    final coupon = CouponModel.fromJson({
      'flag': 'coupon',
      'data': {'id': 2, 'name': 'سحب الطلبات', 'price': '100.00', 'policy': 'order_total', 'my_codes': ['AAA111'], 'winner_code': null},
      'draws': [
        {'id': 2, 'name': 'سحب الطلبات', 'policy': 'order_total'},
        {
          'id': 1,
          'name': 'سحب الفسيخ',
          'policy': 'product',
          'badge_label': 'يؤهلك للدخول في السحب بقيمة 5,000 جنيه',
          'products': [{'id': 5, 'name': 'فسيخ'}, {'id': 6, 'name': 'رنجة'}],
          'my_codes': ['BBB222', 'CCC333'],
          'winner_code': 'CCC333',
        },
      ],
      'recent_winners': [{'id': 9, 'name': 'سحب أكتوبر', 'prize_amount': '1000.00', 'end_date': '2026-10-31', 'winner_code': 'ZZZ999'}],
    });
    expect(coupon.data?.isByProducts, isFalse);
    expect(coupon.data?.myCodes, ['AAA111']);
    expect(coupon.productDraws.map((d) => d.id), [1]);
    final draw = coupon.productDraws.single;
    expect(draw.products.map((p) => p.name), ['فسيخ', 'رنجة']);
    expect(draw.myCodes, ['BBB222', 'CCC333']);
    expect(draw.winnerCode, 'CCC333');
    expect(coupon.recentWinners.single.code, 'ZZZ999');
  });

  test('an older server answer still reads', () {
    final coupon = CouponModel.fromJson({'flag': 'coupon', 'data': {'id': 2, 'name': 'سحب', 'price': '100.00'}});
    expect(coupon.data?.policy, 'order_total');
    expect(coupon.draws, isEmpty);
    expect(coupon.recentWinners, isEmpty);
  });

  testWidgets('the badge fits the small item card on one line without overflowing', (tester) async {
    const badge = DrawBadge(label: 'يؤهلك للدخول في السحب بقيمة 100,000 جنيه');
    for (final width in [145.0, 165.0, 320.0]) {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: width,
              child: const Align(alignment: Alignment.centerRight, child: DrawBadgeChip(badge: badge, compact: true)),
            ),
          ),
        ),
      ));
      expect(tester.takeException(), isNull, reason: 'width $width');
      expect(find.textContaining('يؤهلك للدخول في السحب'), findsOneWidget);
    }
  });
}
