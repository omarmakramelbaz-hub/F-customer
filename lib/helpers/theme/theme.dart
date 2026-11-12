import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../translation/all_translation.dart';
import 'app_text_style.dart';
import 'fasakhansta_brand.dart';

ThemeData theme(BuildContext context) {
  final base = ThemeData(
    primaryColor: FasakhanstaBrand.orange,
    visualDensity: VisualDensity.adaptivePlatformDensity,
    useMaterial3: false,
    hintColor: FasakhanstaBrand.muted,
    brightness: Brightness.dark,
    canvasColor: FasakhanstaBrand.surface,
    cardColor: FasakhanstaBrand.surface,
    dividerColor: FasakhanstaBrand.border,
    disabledColor: FasakhanstaBrand.muted.withValues(alpha: .5),
    buttonTheme: const ButtonThemeData(
      buttonColor: FasakhanstaBrand.orange,
      alignedDropdown: true,
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: FasakhanstaBrand.surface,
      modalBackgroundColor: FasakhanstaBrand.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
    ),
    dialogTheme: const DialogThemeData(
      backgroundColor: FasakhanstaBrand.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(22)),
      ),
    ),
    colorScheme: const ColorScheme.dark(
      primary: FasakhanstaBrand.orange,
      onPrimary: FasakhanstaBrand.onOrange,
      secondary: FasakhanstaBrand.orange,
      onSecondary: FasakhanstaBrand.onOrange,
      surface: FasakhanstaBrand.surface,
      onSurface: FasakhanstaBrand.text,
      error: FasakhanstaBrand.danger,
      onError: FasakhanstaBrand.background,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: AppTextStyle.appBarStyle,
      foregroundColor: FasakhanstaBrand.text,
      systemOverlayStyle: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: FasakhanstaBrand.background,
      ),
    ),
    scaffoldBackgroundColor: Colors.transparent,
    fontFamily: context.languageCode == 'ar' ? 'Tajawal' : 'Roboto',
    iconTheme: const IconThemeData(color: FasakhanstaBrand.text),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: FasakhanstaBrand.field,
      hintStyle: const TextStyle(color: FasakhanstaBrand.muted),
      labelStyle: const TextStyle(color: FasakhanstaBrand.muted),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: FasakhanstaBrand.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: FasakhanstaBrand.orange),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: FasakhanstaBrand.orange,
        foregroundColor: FasakhanstaBrand.onOrange,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: FasakhanstaBrand.orange,
    ),
    textSelectionTheme: TextSelectionThemeData(
      cursorColor: FasakhanstaBrand.orange,
      selectionColor: FasakhanstaBrand.orange.withValues(alpha: .25),
      selectionHandleColor: FasakhanstaBrand.orange,
    ),
    platform: TargetPlatform.iOS,
  );
  return base.copyWith(
    textTheme: base.textTheme.apply(
      bodyColor: FasakhanstaBrand.text,
      displayColor: FasakhanstaBrand.text,
    ),
  );
}
