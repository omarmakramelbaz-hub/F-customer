import 'package:faskhaninja/helpers/theme/fasakhansta_brand.dart';
import 'package:flutter/material.dart';

import '../../../../helpers/extensions/extensions.dart';
import '../../../../helpers/theme/app_colors.dart';
import '../../../../helpers/theme/app_text_style.dart';
import '../../../../helpers/translation/all_translation.dart';

class ChangeLangBottomSheet extends StatefulWidget {
  const ChangeLangBottomSheet({super.key});

  @override
  State<ChangeLangBottomSheet> createState() => _ChangeLangBottomSheetState();
}

class _ChangeLangBottomSheetState extends State<ChangeLangBottomSheet> {
  bool _isChangingLanguage = false;

  static const _text = FasakhanstaBrand.text;
  static const _muted = FasakhanstaBrand.muted;
  static const _border = FasakhanstaBrand.border;
  static const _surface = FasakhanstaBrand.surfaceRaised;

  @override
  Widget build(BuildContext context) {
    final isArabic = context.languageCode == 'ar';
    final isEnglish = context.languageCode == 'en';

    return SafeArea(
      top: false,
      child: Container(
        decoration: const BoxDecoration(
          color: FasakhanstaBrand.surface,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(30),
            topRight: Radius.circular(30),
          ),
          boxShadow: [
            BoxShadow(
              color: Color(0x1A000000),
              blurRadius: 30,
              offset: Offset(0, -8),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 10, 18, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: FasakhanstaBrand.surfaceRaised,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
              const SizedBox(height: 18),
              _buildHeader(context),
              const SizedBox(height: 20),
              _LanguageCard(
                code: 'AR',
                title: 'العربية',
                subtitle: 'Arabic',
                selected: isArabic,
                disabled: _isChangingLanguage,
                onTap: () => _selectLanguage('ar'),
              ),
              const SizedBox(height: 12),
              _LanguageCard(
                code: 'EN',
                title: 'English',
                subtitle: 'الإنجليزية',
                selected: isEnglish,
                disabled: _isChangingLanguage,
                onTap: () => _selectLanguage('en'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'changeLanguage'.tr,
                style: AppTextStyle.text20BS().copyWith(
                  color: _text,
                  fontWeight: FontWeight.w900,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                context.languageCode == 'ar'
                    ? 'اختر لغة عرض التطبيق'
                    : 'Choose your app language',
                style: AppTextStyle.text12RG().copyWith(
                  color: _muted,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 14),
        Material(
          color: _surface,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            onTap: _isChangingLanguage ? null : () => Navigator.pop(context),
            borderRadius: BorderRadius.circular(14),
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _border),
              ),
              child: Icon(Icons.close_rounded, color: _text, size: 22),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _selectLanguage(String language) async {
    if (_isChangingLanguage) return;

    if (context.languageCode == language) {
      Navigator.pop(context);
      return;
    }

    setState(() => _isChangingLanguage = true);
    await changeLanguage(language);

    if (!mounted) return;
    Navigator.pop(context);
  }
}

class _LanguageCard extends StatelessWidget {
  final String code;
  final String title;
  final String subtitle;
  final bool selected;
  final bool disabled;
  final VoidCallback onTap;

  const _LanguageCard({
    required this.code,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.disabled,
    required this.onTap,
  });

  static const _text = FasakhanstaBrand.text;
  static const _muted = FasakhanstaBrand.muted;
  static const _border = FasakhanstaBrand.border;

  @override
  Widget build(BuildContext context) {
    final accent = AppColors.mainAppColor;
    final radius = BorderRadius.circular(20);

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 180),
      opacity: disabled ? .65 : 1,
      child: Material(
        color: Colors.transparent,
        borderRadius: radius,
        child: InkWell(
          onTap: disabled ? null : onTap,
          borderRadius: radius,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOut,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            decoration: BoxDecoration(
              color: selected
                  ? accent.withValues(alpha: .065)
                  : FasakhanstaBrand.surface,
              borderRadius: radius,
              border: Border.all(
                color: selected ? accent.withValues(alpha: .55) : _border,
                width: selected ? 1.4 : 1,
              ),
              boxShadow: selected
                  ? [
                      BoxShadow(
                        color: accent.withValues(alpha: .10),
                        blurRadius: 18,
                        offset: const Offset(0, 6),
                      ),
                    ]
                  : const [
                      BoxShadow(
                        color: Color(0x07000000),
                        blurRadius: 12,
                        offset: Offset(0, 4),
                      ),
                    ],
            ),
            child: Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: selected
                        ? LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [accent, FasakhanstaBrand.orange],
                          )
                        : null,
                    color: selected ? null : FasakhanstaBrand.surfaceRaised,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    code,
                    style: AppTextStyle.text14BS().copyWith(
                      color: selected ? FasakhanstaBrand.text : _text,
                      fontWeight: FontWeight.w900,
                      letterSpacing: .4,
                    ),
                  ),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: AppTextStyle.text16BS().copyWith(
                          color: _text,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: AppTextStyle.text11RG().copyWith(color: _muted),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  width: 27,
                  height: 27,
                  decoration: BoxDecoration(
                    color: selected ? accent : Colors.transparent,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: selected ? accent : FasakhanstaBrand.border,
                      width: 1.4,
                    ),
                  ),
                  child: selected
                      ? const Icon(
                          Icons.check_rounded,
                          color: FasakhanstaBrand.text,
                          size: 17,
                        )
                      : null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
