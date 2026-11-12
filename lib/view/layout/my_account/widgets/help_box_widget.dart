import 'package:faskhaninja/helpers/theme/fasakhansta_brand.dart';
import 'package:flutter/material.dart';

import '../../../../helpers/extensions/extensions.dart';
import '../../../../helpers/theme/app_colors.dart';
import '../../../../helpers/theme/app_text_style.dart';

class HelpBoxWidget extends StatefulWidget {
  const HelpBoxWidget({
    super.key,
    required this.answer,
    required this.question,
  });
  final String answer;
  final String question;
  @override
  State<HelpBoxWidget> createState() => _HelpBoxWidgetState();
}

class _HelpBoxWidgetState extends State<HelpBoxWidget> {
  bool isExpanded = false;
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        setState(() {
          isExpanded = !isExpanded;
        });
      },
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: 20,
          vertical: isExpanded ? 14 : 0,
        ),
        margin: EdgeInsets.only(
          bottom: 12,
          top: isExpanded == true ? 24 : 12,
          right: 20,
          left: 20,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isExpanded ? AppColors.mainAppColor : Colors.transparent,
          ),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Text(widget.question, style: AppTextStyle.text18MS()),
                const Spacer(),
                Card(
                  color: isExpanded
                      ? FasakhanstaBrand.surface
                      : AppColors.greyColor.withValues(alpha: 0.5),
                  elevation: isExpanded ? 6 : 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Icon(
                    isExpanded ? Icons.remove : Icons.add,
                    color: isExpanded
                        ? AppColors.yellowColor
                        : FasakhanstaBrand.onOrange,
                    size: isExpanded ? 24 : 20,
                  ),
                ),
              ],
            ),
            10.sbH,
            if (isExpanded)
              Text(
                widget.answer,
                textAlign: TextAlign.justify,
                style: AppTextStyle.text14RS(),
              ),
          ],
        ),
      ),
    );
  }
}
