/// «مسابقة السحب» on a branch's item: the draw its purchase qualifies for (API: `draw` on every product), shown on the
/// item's card as «يؤهلك للدخول في السحب بقيمة … جنيه». Null when no draw by products runs for this item.
class DrawBadge {
  final int? couponWheelId;
  final String label;
  final num? prizeAmount;
  final String? endDate;

  const DrawBadge({this.couponWheelId, required this.label, this.prizeAmount, this.endDate});

  static DrawBadge? fromJson(dynamic json) {
    if (json is! Map) return null;
    final label = json['label']?.toString().trim() ?? '';
    if (label.isEmpty) return null;
    return DrawBadge(
      couponWheelId: int.tryParse(json['coupon_wheel_id']?.toString() ?? ''),
      label: label,
      prizeAmount: num.tryParse(json['prize_amount']?.toString() ?? ''),
      endDate: json['end_date']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'coupon_wheel_id': couponWheelId,
        'label': label,
        'prize_amount': prizeAmount,
        'end_date': endDate,
      };
}

/// A draw ended in the last 30 days and its winning code (API: `recent_winners`).
class DrawWinner {
  final int? id;
  final String name;
  final String? prizeAmount;
  final String? endDate;
  final String code;

  const DrawWinner({this.id, required this.name, this.prizeAmount, this.endDate, required this.code});

  static DrawWinner? fromJson(dynamic json) {
    if (json is! Map) return null;
    final code = json['winner_code']?.toString() ?? '';
    if (code.isEmpty) return null;
    return DrawWinner(
      id: int.tryParse(json['id']?.toString() ?? ''),
      name: json['name']?.toString() ?? '',
      prizeAmount: json['prize_amount']?.toString(),
      endDate: json['end_date']?.toString(),
      code: code,
    );
  }
}
