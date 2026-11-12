import 'package:faskhaninja/helpers/theme/fasakhansta_brand.dart';
import 'package:flutter/material.dart';

import '../../../../helpers/routes/app_routers_import.dart';
import '../../../../helpers/theme/app_colors.dart';
import '../../../../helpers/theme/app_text_style.dart';
import '../../search/screen/search_screen.dart';

class HomeSearchBar extends StatelessWidget {
  const HomeSearchBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
      child: InkWell(
        onTap: () => NamedNavigatorImpl.push(SearchScreen.routeName),
        borderRadius: BorderRadius.circular(18),
        child: Container(
          height: 52,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: FasakhanstaBrand.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.borderColorContainer),
            boxShadow: [
              BoxShadow(
                color: AppColors.blackColor.withOpacity(.05),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(
                Icons.search_rounded,
                size: 28,
                color: FasakhanstaBrand.text,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'ابحث عن منتج أو فرع...',
                  textAlign: TextAlign.right,
                  style: AppTextStyle.text16RS(color: AppColors.hintColor),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
