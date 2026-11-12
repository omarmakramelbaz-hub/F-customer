import 'package:country_picker/country_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../helpers/extensions/extensions.dart';
import '../../../helpers/theme/app_colors.dart';
import '../../../helpers/theme/app_text_style.dart';
import '../../../helpers/translation/all_translation.dart';

enum FormFieldBorder { underLine, outLine, none }

class CustomFormField extends StatefulWidget {
  final TextEditingController? controller;
  final void Function(String)? onChanged;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final bool isPassword;
  final String? hintText;
  final int? maxLines;
  final int? minLines;
  final void Function()? onTap;
  final bool readOnly;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final double radius;
  final Color? fillColor;
  final Color? focusColor;
  final Color? unFocusColor;
  final Color? passwordColor;
  final String? title;
  final String? otherSideTitle;
  final TextDirection? textDirection;
  final Country? country;
  final List<TextInputFormatter>? inputFormatters;
  final void Function(Country)? onCountrySelect;
  final Function(String)? onFieldSubmitted;
  final FormFieldBorder formFieldBorder;
  final TextStyle? titleStyle;
  final TextStyle? textStyle;
  final TextStyle? hintStyle;
  final int? maxLength;
  final String? initialValue;
  final AutovalidateMode? autovalidateMode;
  final FocusNode? focusNode;

  const CustomFormField({
    super.key,
    this.controller,
    this.onChanged,
    this.validator,
    this.keyboardType,
    this.isPassword = false,
    this.hintText,
    this.maxLines = 1,
    this.minLines = 1,
    this.onTap,
    this.readOnly = false,
    this.prefixIcon,
    this.suffixIcon,
    this.radius = 14,
    this.fillColor,
    this.focusColor,
    this.unFocusColor,
    this.title,
    this.textDirection,
    this.otherSideTitle,
    this.country,
    this.passwordColor,
    this.formFieldBorder = FormFieldBorder.outLine,
    this.inputFormatters,
    this.onCountrySelect,
    this.onFieldSubmitted,
    this.titleStyle,
    this.textStyle,
    this.hintStyle,
    this.maxLength,
    this.autovalidateMode,
    this.initialValue,
    this.focusNode,
  });

  @override
  State<CustomFormField> createState() => _CustomFormFieldState();
}

class _CustomFormFieldState extends State<CustomFormField> {
  bool _obscureText = true;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: context.width,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (widget.title != null) ...{
                Expanded(
                  child: Text(
                    widget.title!,
                    style: widget.titleStyle ?? AppTextStyle.formTitleStyle,
                  ),
                ),
              },
              if (widget.otherSideTitle != null) ...{
                Text(
                  widget.otherSideTitle!,
                  style: widget.titleStyle ?? AppTextStyle.formTitleStyle,
                ),
              },
            ],
          ),
          if (widget.title != null || widget.otherSideTitle != null) ...{
            10.sbH,
          },
          Directionality(
            textDirection:
                widget.textDirection ??
                (context.isRtl ? TextDirection.rtl : TextDirection.ltr),
            child: TextFormField(
              onFieldSubmitted: widget.onFieldSubmitted,
              onTapOutside: (event) =>
                  FocusManager.instance.primaryFocus?.unfocus(),
              controller: widget.controller,
              onChanged: widget.onChanged,
              validator: widget.validator,
              onTap: widget.onTap,
              readOnly: widget.readOnly,
              keyboardType: widget.keyboardType,
              obscureText: widget.isPassword ? _obscureText : false,
              style: widget.textStyle ?? AppTextStyle.textFormStyle,
              autovalidateMode:
                  widget.autovalidateMode ?? AutovalidateMode.onUserInteraction,
              maxLines: widget.maxLines,
              minLines: widget.minLines,
              cursorColor: widget.focusColor ?? AppColors.mainAppColor,
              inputFormatters: widget.inputFormatters,
              maxLength: widget.maxLength,
              decoration: InputDecoration(
                hintMaxLines: 2,
                hintText: widget.hintText,
                hintStyle: widget.hintStyle ?? AppTextStyle.hintStyle,
                fillColor:
                    widget.fillColor ??
                    (widget.formFieldBorder == FormFieldBorder.underLine
                        ? Colors.transparent
                        : AppColors.textFormFillColor),
                filled: true,
                border: _border(
                  color: widget.unFocusColor ?? AppColors.textFormBorderColor,
                ),
                disabledBorder: _border(
                  color: widget.unFocusColor ?? AppColors.textFormBorderColor,
                ),
                focusedBorder: _border(
                  color: widget.focusColor ?? AppColors.mainAppColor,
                ),
                enabledBorder: _border(
                  color: widget.unFocusColor ?? AppColors.textFormBorderColor,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 10,
                  horizontal: 10,
                ),
                prefixIcon:
                    widget.country != null && context.languageCode == 'en'
                    ? Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          widget.prefixIcon ?? const SizedBox(),
                          TextButton(
                            onPressed: null,
                            // onPressed:
                            //     widget.onCountrySelect != null ? _select : null,
                            child: Text(
                              '${widget.country?.flagEmoji} +${widget.country?.phoneCode}',
                              style:
                                  widget.textStyle ??
                                  AppTextStyle.textFormStyle,
                              textDirection: TextDirection.ltr,
                            ),
                          ),
                        ],
                      )
                    : widget.prefixIcon,
                suffixIcon:
                    widget.country != null && context.languageCode == 'ar'
                    ? Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          TextButton(
                            onPressed: null,
                            // onPressed:
                            //     widget.onCountrySelect != null ? _select : null,
                            child: Text(
                              '${widget.country?.flagEmoji} +${widget.country?.phoneCode}',
                              style:
                                  widget.textStyle ??
                                  AppTextStyle.textFormStyle,
                              textDirection: TextDirection.ltr,
                            ),
                          ),
                          widget.suffixIcon ?? const SizedBox(),
                        ],
                      )
                    : widget.isPassword
                    ? InkWell(
                        onTap: () {
                          setState(() {
                            _obscureText = !_obscureText;
                          });
                        },
                        child: Icon(
                          _obscureText
                              ? Icons.visibility_off_rounded
                              : Icons.visibility_rounded,
                          size: 20,
                          color: widget.passwordColor ?? AppColors.hintColor,
                        ),
                      )
                    : widget.suffixIcon,
              ),
              initialValue: widget.initialValue,
              focusNode: widget.focusNode ?? FocusNode(),
            ),
          ),
        ],
      ),
    );
  }

  InputBorder _border({required Color color}) {
    switch (widget.formFieldBorder) {
      case FormFieldBorder.outLine:
        return OutlineInputBorder(
          borderRadius: BorderRadius.circular(widget.radius),
          borderSide: BorderSide(color: color),
        );
      case FormFieldBorder.underLine:
        return UnderlineInputBorder(
          borderRadius: BorderRadius.circular(0),
          borderSide: BorderSide(color: color),
        );
      case FormFieldBorder.none:
        return InputBorder.none;
    }
  }

  // void _select() {
  //   CountryCodeMethods.pickCountry(
  //     onSelect: (v) {
  //       widget.onCountrySelect?.call(v);
  //     },
  //     context: context,
  //   );
  // }
}
