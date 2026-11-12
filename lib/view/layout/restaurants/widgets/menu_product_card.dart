import 'package:flutter/material.dart';

import '../../../../helpers/theme/app_colors.dart';
import '../../../../helpers/theme/fasakhansta_brand.dart';
import '../../home/model/draw_badge.dart';
import '../../home/widgets/draw_badge_chip.dart';

/// Shared menu tile, with a full gold treatment for draw-eligible products.
class MenuProductCard extends StatelessWidget {
  const MenuProductCard({
    super.key,
    required this.name,
    required this.priceLabel,
    required this.image,
    required this.onTap,
    this.draw,
    this.available = true,
    this.highestRated = false,
    this.compact = false,
  });

  final String name;
  final String priceLabel;
  final Widget image;
  final VoidCallback onTap;
  final DrawBadge? draw;
  final bool available;
  final bool highestRated;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final eligible = draw != null;
    final radius = BorderRadius.circular(18);
    final textScale = MediaQuery.textScalerOf(context).scale(10) / 10;
    final badgeWidthFactor = (.5 + (textScale - 1) * .18)
        .clamp(.5, .85)
        .toDouble();

    return DecoratedBox(
      decoration: BoxDecoration(
        color: eligible ? const Color(0xFFFFFAEF) : FasakhanstaBrand.surface,
        borderRadius: radius,
        border: Border.all(
          color: eligible ? const Color(0xFFE8B84C) : FasakhanstaBrand.border,
          width: eligible ? 2 : 1,
        ),
        boxShadow: eligible
            ? const [
                BoxShadow(
                  color: Color(0x22DDA038),
                  blurRadius: 12,
                  offset: Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Padding(
        padding: EdgeInsets.all(eligible ? 2 : 1),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(eligible ? 16 : 17),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        image,
                        if (eligible)
                          Positioned(
                            top: 7,
                            left: 7,
                            right: 7,
                            child: FractionallySizedBox(
                              widthFactor: badgeWidthFactor,
                              alignment: Alignment.topLeft,
                              child: DrawBadgeChip(
                                badge: draw!,
                                compact: true,
                                corner: true,
                              ),
                            ),
                          )
                        else if (highestRated)
                          PositionedDirectional(
                            top: 8,
                            start: 8,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.mainAppColor,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                'الأكثر طلباً',
                                style: TextStyle(
                                  color: FasakhanstaBrand.onOrange,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(10, 8, 10, 4),
                    child: Text(
                      name,
                      maxLines: eligible ? 2 : 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: eligible
                            ? const Color(0xFF191C24)
                            : FasakhanstaBrand.text,
                        fontSize: 14,
                        height: 1.3,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            priceLabel,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: available
                                  ? (eligible
                                        ? const Color(0xFF9A4A0B)
                                        : FasakhanstaBrand.orange)
                                  : FasakhanstaBrand.muted,
                              fontSize: compact ? 14 : 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Container(
                          width: compact ? 30 : 34,
                          height: compact ? 30 : 34,
                          decoration: BoxDecoration(
                            color: available
                                ? AppColors.mainAppColor
                                : Colors.grey,
                            borderRadius: BorderRadius.circular(
                              compact ? 10 : 17,
                            ),
                          ),
                          child: const Icon(
                            Icons.add,
                            color: FasakhanstaBrand.onOrange,
                            size: 20,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
