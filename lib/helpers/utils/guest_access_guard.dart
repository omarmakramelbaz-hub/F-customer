import 'package:faskhaninja/helpers/theme/fasakhansta_brand.dart';
import 'package:flutter/material.dart';

import '../hive/hive_methods.dart';
import '../theme/app_colors.dart';

class GuestAccessGuard {
  const GuestAccessGuard._();

  static bool get isGuest => HiveMethods.getToken() == null;

  static bool blockIfGuest(BuildContext context) {
    if (!isGuest) return false;
    showLoginRequired(context);
    return true;
  }

  static void showLoginRequired(BuildContext context) {
    final messenger = ScaffoldMessenger.of(context);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          elevation: 0,
          backgroundColor: Colors.transparent,
          margin: const EdgeInsets.fromLTRB(14, 0, 14, 16),
          padding: EdgeInsets.zero,
          duration: const Duration(seconds: 3),
          content: Directionality(
            textDirection: TextDirection.rtl,
            child: Container(
              padding: const EdgeInsets.fromLTRB(12, 11, 12, 11),
              decoration: BoxDecoration(
                color: FasakhanstaBrand.surface,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: FasakhanstaBrand.border),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x24000000),
                    blurRadius: 20,
                    offset: Offset(0, 7),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: const BoxDecoration(
                      color: FasakhanstaBrand.surfaceRaised,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.lock_outline_rounded,
                      color: AppColors.mainAppColor,
                      size: 23,
                    ),
                  ),
                  const SizedBox(width: 11),
                  const Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'يرجى التسجيل أولاً',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: FasakhanstaBrand.text,
                            fontSize: 14.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        SizedBox(height: 3),
                        Text(
                          'يرجى تسجيل الدخول أو إنشاء حساب للقدرة على استخدام هذه الخدمة.',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: FasakhanstaBrand.muted,
                            fontSize: 11.5,
                            height: 1.3,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 7),
                  InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: messenger.hideCurrentSnackBar,
                    child: const Padding(
                      padding: EdgeInsets.all(5),
                      child: Icon(
                        Icons.close_rounded,
                        color: FasakhanstaBrand.muted,
                        size: 19,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
  }
}
