import 'package:faskhaninja/helpers/theme/fasakhansta_brand.dart';
import 'package:flutter/material.dart';

import '../../../helpers/extensions/extensions.dart';
import '../../../helpers/theme/app_colors.dart';

class BottomSheetHelper {
  static Future<bool?> gShowModalBottomSheet({
    required BuildContext context,
    required Widget content,
    Color? backgroundColor,
    bool isPaddingAll = true,
    bool isHidden = false,
    double? maxHeight,
    double? maxWidth,
    bool barrierDismissible = true,
    Color? handleColor,
    bool disableMinimumHeight = false,
  }) async {
    return await showModalBottomSheet(
      isDismissible: barrierDismissible,
      isScrollControlled: true,
      context: context,
      backgroundColor: FasakhanstaBrand.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(20),
          topLeft: Radius.circular(20),
        ),
      ),
      builder: (BuildContext context) {
        if (!isHidden) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: Container(
              width: MediaQuery.of(context).size.width,
              padding: const EdgeInsets.only(top: 15.0),
              height: maxHeight ?? 370,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Container(
                    height: 5.0,
                    width: 50.0,
                    decoration: BoxDecoration(
                      color: FasakhanstaBrand.surface,
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  15.sbH,
                  Flexible(child: content),
                ],
              ),
            ),
          );
        } else {
          return Container(
            decoration: BoxDecoration(
              color: FasakhanstaBrand.surface,
              borderRadius: BorderRadius.circular(20),
            ),
            padding: const EdgeInsets.only(bottom: 24),
            child: content,
          );
        }
      },
    );
  }
}
