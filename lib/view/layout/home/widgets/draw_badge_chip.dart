import 'package:flutter/material.dart';

import '../../../../helpers/theme/app_colors.dart';
import '../model/draw_badge.dart';

/// «🎁 يؤهلك للدخول في السحب بقيمة 5,000 جنيه» on the card of an item chosen for a draw by products.
class DrawBadgeChip extends StatelessWidget {
  const DrawBadgeChip({super.key, required this.badge, this.compact = false});

  final DrawBadge badge;
  /// On a small card: one line, smaller text.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: compact ? 7 : 10, vertical: compact ? 4 : 6),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF1E6),
        borderRadius: BorderRadius.circular(compact ? 8 : 10),
        border: Border.all(color: AppColors.mainAppColor.withValues(alpha: .35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.card_giftcard_rounded, size: compact ? 13 : 16, color: AppColors.darkMainAppColor),
          SizedBox(width: compact ? 4 : 6),
          Flexible(
            child: Text(
              badge.label,
              maxLines: compact ? 1 : 2,
              overflow: TextOverflow.ellipsis,
              textDirection: TextDirection.rtl,
              style: TextStyle(
                fontSize: compact ? 10 : 12,
                height: 1.35,
                fontWeight: FontWeight.w800,
                color: const Color(0xFFB94F00),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
