import 'package:flutter/material.dart';

class TrackingDelegateOrderWidget extends StatelessWidget {
  final String status;
  final String? orderDate;

  const TrackingDelegateOrderWidget({super.key, required this.status, this.orderDate});

  @override
  Widget build(BuildContext context) {
    final ar = Localizations.localeOf(context).languageCode == 'ar';
    final cancelled = status == 'cancelled';
    final completed = status == 'completed';
    final shipped = status == 'shipped' || completed;
    final accepted = const ['accepted', 'shipped', 'completed'].contains(status);
    final steps = <({String ar, String en, IconData icon, bool done})>[
      (ar: 'تم الاتفاق مع المندوب', en: 'Driver confirmed', icon: Icons.handshake_outlined, done: accepted),
      (ar: 'المندوب في الطريق إليك', en: 'Driver is on the way', icon: Icons.delivery_dining_rounded, done: accepted),
      (ar: 'تم استلام الطلب', en: 'Order picked up', icon: Icons.inventory_2_outlined, done: shipped),
      (ar: 'تم التوصيل', en: 'Delivered', icon: Icons.check_circle_outline_rounded, done: completed),
    ];
    if (cancelled) {
      return _stateCard(ar ? 'تم إلغاء الطلب' : 'Order cancelled', Icons.cancel_outlined, const Color(0xffB84436));
    }
    return Column(
      children: List.generate(steps.length, (i) {
        final s = steps[i];
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(children: [
              Container(width: 38, height: 38, decoration: BoxDecoration(shape: BoxShape.circle, color: s.done ? const Color(0xffFFF0E3) : const Color(0xffF0F1F3)), child: Icon(s.icon, size: 20, color: s.done ? const Color(0xffFD7201) : const Color(0xffA4A9B0))),
              if (i < steps.length - 1) Container(width: 2, height: 34, color: s.done ? const Color(0xffFD7201) : const Color(0xffE2E4E8)),
            ]),
            const SizedBox(width: 12),
            Expanded(child: Padding(padding: const EdgeInsets.only(top: 9), child: Text(ar ? s.ar : s.en, style: TextStyle(fontSize: 14, fontWeight: s.done ? FontWeight.w800 : FontWeight.w500, color: s.done ? const Color(0xff171A1F) : const Color(0xff8A9099))))),
          ],
        );
      }),
    );
  }

  Widget _stateCard(String text, IconData icon, Color color) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(color: color.withValues(alpha: .08), borderRadius: BorderRadius.circular(14)),
    child: Row(children: [Icon(icon, color: color), const SizedBox(width: 10), Expanded(child: Text(text, style: TextStyle(color: color, fontWeight: FontWeight.w800)))]),
  );
}
