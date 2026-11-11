import 'package:flutter/material.dart';

import '../../../../helpers/theme/app_text_style.dart';

/// Scrollable foreground, kept independent of providers for layout testing.
class HomeFullscreenContent extends StatelessWidget {
  const HomeFullscreenContent({
    super.key,
    required this.header,
    required this.competition,
    required this.branches,
    required this.courier,
    required this.onStartOrder,
    required this.onCompetition,
    required this.onChangeAddress,
    required this.minHeight,
    required this.bottomInset,
    this.branchesKey,
    this.hasLocation = true,
  });

  final Widget header;
  final Widget competition;
  final Widget branches;
  final Widget courier;
  final VoidCallback onStartOrder;
  final VoidCallback onCompetition;
  final VoidCallback onChangeAddress;
  final double minHeight;
  final double bottomInset;
  final Key? branchesKey;
  final bool hasLocation;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: minHeight),
        child: Padding(
          padding: EdgeInsets.fromLTRB(20, 12, 20, bottomInset + 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              header,
              SizedBox(height: (minHeight * .055).clamp(20.0, 54.0)),
              Text(
                'فسخانستا.. طعم له ناسه',
                style: AppTextStyle.text12BS(color: const Color(0xFFFFEDCA)),
              ),
              const SizedBox(height: 12),
              Text.rich(
                const TextSpan(
                  children: [
                    TextSpan(text: 'اللّمة الحلوة\nتبدأ '),
                    TextSpan(
                      text: 'من هنا',
                      style: TextStyle(color: Color(0xFFFFA258)),
                    ),
                  ],
                ),
                style: AppTextStyle.text20BS().copyWith(
                  color: Colors.white,
                  fontSize: 38,
                  fontWeight: FontWeight.w900,
                  height: 1.18,
                  shadows: const [
                    Shadow(color: Color(0x55001A1B), blurRadius: 16),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'فسيخ، رنجة، سردين وبطارخ',
                style: AppTextStyle.text13BS(color: const Color(0xFFFFF6E5)),
              ),
              const SizedBox(height: 19),
              ElevatedButton(
                key: const ValueKey('home-start-order'),
                onPressed: onStartOrder,
                style: ElevatedButton.styleFrom(
                  elevation: 0,
                  backgroundColor: const Color(0xFFFF8A35),
                  foregroundColor: const Color(0xFF132F2C),
                  minimumSize: const Size.fromHeight(50),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 13,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Flexible(
                      child: Text(
                        'ابدأ طلبك',
                        style: AppTextStyle.text16BS(
                          color: const Color(0xFF132F2C),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Icon(Icons.arrow_back_rounded, size: 21),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              _SectionTitle(
                title: 'المسابقة اليومية',
                action: 'شارك الآن',
                onTap: onCompetition,
              ),
              const SizedBox(height: 7),
              competition,
              const SizedBox(height: 16),
              _SectionTitle(
                key: branchesKey,
                title: 'فروعنا ومتاجرنا',
                action: 'تغيير العنوان',
                onTap: onChangeAddress,
              ),
              Text(
                hasLocation
                    ? 'القريبة من عنوانك'
                    : 'حدّد عنوانك لعرض الفروع القريبة',
                style: AppTextStyle.text11RG(color: const Color(0xFFDEDECB)),
              ),
              const SizedBox(height: 9),
              branches,
              const SizedBox(height: 14),
              courier,
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({
    super.key,
    required this.title,
    required this.action,
    required this.onTap,
  });

  final String title;
  final String action;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: AppTextStyle.text16BS(color: const Color(0xFFFFF4E2)),
          ),
        ),
        const SizedBox(width: 8),
        TextButton(
          onPressed: onTap,
          style: TextButton.styleFrom(
            foregroundColor: const Color(0xFFFFBC83),
            minimumSize: const Size(44, 44),
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 9),
          ),
          child: Text(
            action,
            style: AppTextStyle.text11BS(color: const Color(0xFFFFBC83)),
          ),
        ),
      ],
    );
  }
}
