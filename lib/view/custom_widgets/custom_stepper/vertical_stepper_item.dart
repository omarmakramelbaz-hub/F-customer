import 'package:faskhaninja/helpers/theme/fasakhansta_brand.dart';
import 'package:flutter/material.dart';

import 'dot_provider.dart';
import 'stepper_data.dart';

class VerticalStepperItem extends StatelessWidget {
  final Color dotColor;

  /// Stepper Item to show vertical stepper
  const VerticalStepperItem({
    super.key,
    required this.item,
    required this.index,
    required this.totalLength,
    required this.gap,
    required this.activeIndex,
    required this.isInverted,
    required this.activeBarColor,
    required this.inActiveBarColor,
    required this.barWidth,
    required this.iconHeight,
    required this.iconWidth,
    required this.dotColor,
  });

  /// Stepper item of type [StepperData] to inflate stepper with data
  final StepperData item;

  /// Index at which the item is present
  final int index;

  /// Total length of the list provided
  final int totalLength;

  /// Active index which needs to be highlighted and before that
  final int activeIndex;

  /// Gap between the items in the stepper
  final double gap;

  /// Inverts the stepper with text that is being used
  final bool isInverted;

  /// Bar color for active step
  final Color activeBarColor;

  /// Bar color for inactive step
  final Color inActiveBarColor;

  /// Bar width/thickness
  final double barWidth;

  /// Height of [StepperData.iconWidget]
  final double iconHeight;

  /// Width of [StepperData.iconWidget]
  final double iconWidth;

  @override
  Widget build(BuildContext context) {
    return Row(children: isInverted ? getInvertedChildren() : getChildren());
  }

  List<Widget> getChildren() {
    return [
      Column(
        children: [
          Container(
            color: FasakhanstaBrand.surfaceRaised,
            width: barWidth,
            height: gap,
          ),
          const SizedBox(height: 2),
          DotProvider(
            dotColor: dotColor,
            activeIndex: activeIndex,
            index: index,
            item: item,
            totalLength: totalLength,
            iconHeight: iconHeight,
            iconWidth: iconWidth,
          ),
          const SizedBox(height: 2),
          Container(
            color: FasakhanstaBrand.surfaceRaised,
            width: barWidth,
            height: gap,
          ),
        ],
      ),
      const SizedBox(width: 8),
      Expanded(
        child: Column(
          crossAxisAlignment:
              isInverted ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            if (item.title != null) ...[
              Text(
                item.title!.text,
                textAlign: TextAlign.start,
                style: item.title!.textStyle ??
                    TextStyle(
                      fontSize: 14,
                      color: dotColor,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
            if (item.subtitle != null) ...[
              const SizedBox(height: 8),
              Text(
                item.subtitle!.text,
                textAlign: TextAlign.start,
                style: item.subtitle!.textStyle ??
                    TextStyle(
                      fontSize: 12,
                      color: (index <= activeIndex)
                          ? FasakhanstaBrand.info
                          : FasakhanstaBrand.muted,
                      fontWeight: FontWeight.w500,
                    ),
              ),
            ],
          ],
        ),
      ),
    ];
  }

  List<Widget> getInvertedChildren() {
    return getChildren().reversed.toList();
  }
}
