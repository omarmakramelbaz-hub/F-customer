import 'package:faskhaninja/helpers/theme/fasakhansta_brand.dart';
import 'package:flutter/material.dart';

import '../../../../helpers/theme/app_colors.dart';
import '../../../../helpers/theme/app_text_style.dart';

class CartMinimumOrderWidget extends StatelessWidget {
  final double current;
  final double minimum;

  const CartMinimumOrderWidget({
    super.key,
    required this.current,
    required this.minimum,
  });

  @override
  Widget build(BuildContext context) {
    if (minimum <= 0) return const SizedBox.shrink();

    final progress = (current / minimum).clamp(0.0, 1.0);
    final remaining = (minimum - current).clamp(0.0, minimum);
    final reached = remaining <= 0;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 6),
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
      decoration: BoxDecoration(
        color: FasakhanstaBrand.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: FasakhanstaBrand.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F000000),
            blurRadius: 18,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        textDirection: TextDirection.rtl,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _buildStatusIcon(reached),
          const SizedBox(width: 18),
          Container(
            width: 1,
            height: 84,
            color: FasakhanstaBrand.surfaceRaised,
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'الحد الأدنى للطلب',
                  textAlign: TextAlign.right,
                  style: AppTextStyle.text16BS(),
                ),
                const SizedBox(height: 4),
                Text(
                  '${_formatAmount(minimum)} ج',
                  textAlign: TextAlign.right,
                  style: AppTextStyle.text22BS(color: AppColors.mainAppColor),
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 8,
                    backgroundColor: FasakhanstaBrand.surfaceRaised,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      reached
                          ? const Color(0xFF20B66A)
                          : AppColors.mainAppColor,
                    ),
                  ),
                ),
                const SizedBox(height: 9),
                Text.rich(
                  TextSpan(
                    children: reached
                        ? [
                            TextSpan(
                              text: 'تم الوصول للحد الأدنى للطلب',
                              style: AppTextStyle.text12BS(
                                color: FasakhanstaBrand.success,
                              ),
                            ),
                          ]
                        : [
                            TextSpan(
                              text: 'متبقي ',
                              style: AppTextStyle.text12RG(),
                            ),
                            TextSpan(
                              text: '${_formatAmount(remaining)} ج',
                              style: AppTextStyle.text13BS(
                                color: AppColors.mainAppColor,
                              ),
                            ),
                            TextSpan(
                              text: ' لإتمام الطلب',
                              style: AppTextStyle.text12RG(),
                            ),
                          ],
                  ),
                  textAlign: TextAlign.right,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusIcon(bool reached) {
    final accentColor = reached
        ? const Color(0xFF20B66A)
        : AppColors.mainAppColor;

    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        color: accentColor.withValues(alpha: .10),
        shape: BoxShape.circle,
      ),
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          Icon(
            reached ? Icons.check_rounded : Icons.shopping_cart_outlined,
            color: accentColor,
            size: 30,
          ),
          if (!reached)
            Positioned(
              right: 10,
              bottom: 9,
              child: Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: FasakhanstaBrand.surface,
                  shape: BoxShape.circle,
                  border: Border.all(color: FasakhanstaBrand.border, width: 2),
                ),
                child: Icon(Icons.star_rounded, color: accentColor, size: 16),
              ),
            ),
        ],
      ),
    );
  }

  String _formatAmount(double value) {
    final raw = value.round().toString();
    return raw.replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (match) => ',',
    );
  }
}
