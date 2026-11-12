import 'package:faskhaninja/helpers/theme/fasakhansta_brand.dart';

import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:pinput/pinput.dart';

import '../../../helpers/theme/app_colors.dart';
import '../../../helpers/translation/all_translation.dart';

class CustomOtpField extends StatefulWidget {
  final int length;
  final TextEditingController? controller;
  final void Function(String)? onCompleted;
  const CustomOtpField({
    super.key,
    this.length = 4,
    this.controller,
    this.onCompleted,
  });

  @override
  State<CustomOtpField> createState() => _CustomOtpFieldState();
}

class _CustomOtpFieldState extends State<CustomOtpField> {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Directionality(
        textDirection: ui.TextDirection.ltr,
        child: Pinput(
          controller: widget.controller,
          defaultPinTheme: PinTheme(
            width: 50,
            height: 50,
            textStyle: TextStyle(
              fontSize: 20,
              color: FasakhanstaBrand.text,
              fontWeight: FontWeight.w600,
            ),
            decoration: BoxDecoration(
              color: AppColors.textFormFillColor,
              border: Border.all(color: AppColors.textFormBorderColor),
              borderRadius: BorderRadius.circular(25),
            ),
          ),
          focusedPinTheme: PinTheme(
            width: 50,
            height: 50,
            textStyle: TextStyle(
              fontSize: 20,
              color: AppColors.mainAppColor,
              fontWeight: FontWeight.w600,
            ),
            decoration: BoxDecoration(
              color: AppColors.textFormFillColor,
              border: Border.all(color: AppColors.textFormBorderColor),
              borderRadius: BorderRadius.circular(25),
            ),
          ),
          submittedPinTheme: PinTheme(
            width: 50,
            height: 50,
            textStyle: TextStyle(
              fontSize: 20,
              color: AppColors.mainAppColor,
              fontWeight: FontWeight.w600,
            ),
            decoration: BoxDecoration(
              color: AppColors.textFormFillColor,
              border: Border.all(color: AppColors.textFormBorderColor),
              borderRadius: BorderRadius.circular(25),
            ),
          ),
          errorPinTheme: PinTheme(
            width: 50,
            height: 50,
            textStyle: TextStyle(
              fontSize: 20,
              color: AppColors.mainAppColor,
              fontWeight: FontWeight.w600,
            ),
            decoration: BoxDecoration(
              color: AppColors.textFormFillColor,
              border: Border.all(color: FasakhanstaBrand.border),
              borderRadius: BorderRadius.circular(25),
            ),
          ),
          errorBuilder: (errorText, pin) {
            return Align(
              alignment: context.isRtl
                  ? AlignmentDirectional.centerEnd
                  : AlignmentDirectional.centerStart,
              child: Padding(
                padding: const EdgeInsets.all(5),
                child: Text(
                  errorText!,
                  style: TextStyle(
                    fontSize: 12,
                    color: FasakhanstaBrand.danger,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
            );
          },
          validator: (s) {
            return s!.trim().length == widget.length
                ? null
                : '${'The code consists of'.tr} ${widget.length} ${'digits'.tr}';
          },
          pinputAutovalidateMode: PinputAutovalidateMode.onSubmit,
          onTapOutside: (event) =>
              FocusManager.instance.primaryFocus?.unfocus(),
          onCompleted: widget.onCompleted,
        ),
      ),
    );
  }
}
