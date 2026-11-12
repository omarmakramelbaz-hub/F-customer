import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../helpers/images/app_images.dart';
import '../../../helpers/theme/app_colors.dart';
import '../../../helpers/utils/utils.dart';
import '../../layout/auth/bottom_sheet/change_lang_bottom_sheet.dart';

class CustomAppBar extends PreferredSize {
  final double height;
  final double radius;
  final double elevation;
  final Widget? leading;
  final List<Widget>? actions;
  final Widget? title;
  final Color? appBarColor;
  final Color? shadowColor;
  final bool? centerTitle;
  final PreferredSizeWidget? bottom;
  final double? leadingWidth;
  final bool automaticallyImplyLeading;
  final BorderRadiusGeometry? borderRadius;
  final VoidCallback? onPop;
  final bool showLang;

  CustomAppBar({
    super.key,
    this.height = kToolbarHeight,
    this.radius = 0,
    this.elevation = 0,
    this.leading,
    this.actions,
    this.title,
    this.appBarColor,
    this.centerTitle,
    this.bottom,
    this.leadingWidth,
    this.shadowColor,
    this.automaticallyImplyLeading = true,
    this.borderRadius,
    this.onPop,
    this.showLang = false,
  }) : super(
         preferredSize: Size.fromHeight(height),
         child: AppBar(
           elevation: elevation,
           backgroundColor: appBarColor ?? Colors.transparent,
           toolbarHeight: height,
           automaticallyImplyLeading: automaticallyImplyLeading,
           shadowColor: shadowColor,
           centerTitle: centerTitle,
           title: title,
           leading: leading,
           actions:
               actions ??
               [
                 if (showLang == true)
                   Padding(
                     padding: const EdgeInsets.symmetric(
                       horizontal: 25,
                       vertical: 5,
                     ),
                     child: GestureDetector(
                       onTap: () => Utils.showAppBottomSheet(
                         const ChangeLangBottomSheet(),
                       ),
                       child: SvgPicture.asset(
                         AppImages.langIcon,
                         color: AppColors.mainAppColor,
                       ),
                     ),
                   ),
               ],
           leadingWidth: leadingWidth,
           bottom: bottom,
         ),
       );
}
