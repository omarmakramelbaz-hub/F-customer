import 'package:faskhaninja/helpers/theme/fasakhansta_brand.dart';
import 'package:flutter/material.dart';
import 'package:timeline_tile/timeline_tile.dart';

import '../../../../helpers/extensions/extensions.dart';
import '../../../../helpers/theme/app_colors.dart';

class MyTimeLineWidget extends StatelessWidget {
  final bool isFirst;
  final bool isLast;
  final Widget endChild;
  final bool isDone;
  final Widget icon;
  const MyTimeLineWidget({
    super.key,
    required this.isFirst,
    required this.isLast,
    required this.endChild,
    required this.isDone,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 80,
      child: TimelineTile(
        isFirst: isFirst,
        isLast: isLast,
        endChild: endChild,
        beforeLineStyle: LineStyle(
          color: AppColors.greyColor.withValues(alpha: .2),
        ),
        indicatorStyle: IndicatorStyle(
          width: context.width * 0.1,
          height: context.width * 0.3,
          indicator: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: FasakhanstaBrand.surface,
              boxShadow: [
                BoxShadow(
                  color: AppColors.greyColor,
                  blurRadius: 8,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: icon,
          ),
        ),
      ),
    );
  }
}
