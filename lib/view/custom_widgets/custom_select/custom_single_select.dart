import 'package:faskhaninja/helpers/theme/fasakhansta_brand.dart';
import 'package:collection/collection.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../helpers/extensions/extensions.dart';
import '../../../helpers/networking/api_helper.dart';
import '../../../helpers/theme/app_colors.dart';
import '../../../helpers/theme/app_text_style.dart';
import '../../../helpers/translation/all_translation.dart';
import '../../../helpers/utils/common_methods.dart';
import '../../../helpers/utils/utils.dart';
import '../api_response_widget/api_response_widget.dart';
import '../buttons/custom_button.dart';
import '../custom_form_field/custom_form_field.dart';
import 'custom_select_item.dart';

class CustomSingleSelect extends StatefulWidget {
  final dynamic value;
  final List<CustomSelectItem>? items;
  final void Function(dynamic)? onChanged;
  final String? Function(dynamic)? validator;
  final String? hintText;
  final int? maxLines;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final double radius;
  final Color? fillColor;
  final Color? focusColor;
  final Color? unFocusColor;
  final String? title;
  final String? otherSideTitle;
  final ApiResponse? apiResponse;
  final void Function()? onReload;
  final void Function()? onReInitial;
  final Widget? icon;
  final TextStyle? hintStyle;
  final bool hasRemove;
  final FormFieldBorder formFieldBorder;
  const CustomSingleSelect({
    super.key,
    this.value,
    this.items,
    this.onChanged,
    this.validator,
    this.hintText,
    this.maxLines = 1,
    this.prefixIcon,
    this.suffixIcon,
    this.radius = 25,
    this.fillColor,
    this.focusColor,
    this.unFocusColor,
    this.title,
    this.otherSideTitle,
    this.apiResponse,
    this.onReload,
    this.icon,
    this.onReInitial,
    this.formFieldBorder = FormFieldBorder.outLine,
    this.hintStyle,
    this.hasRemove = true,
  });

  @override
  State<CustomSingleSelect> createState() => _CustomSingleSelectState();
}

class _CustomSingleSelectState extends State<CustomSingleSelect> {
  final _selectedEC = TextEditingController();

  void _showValue() {
    Future.delayed(Duration.zero, () {
      _selectedEC.text = widget.items
              ?.firstWhereOrNull((element) => element.value == widget.value)
              ?.name ??
          '';
    });
  }

  @override
  Widget build(BuildContext context) {
    _showValue();
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
                    style: AppTextStyle.formTitleStyle,
                  ),
                ),
              },
              if (widget.otherSideTitle != null) ...{
                Text(
                  widget.otherSideTitle!,
                  style: AppTextStyle.formTitleStyle,
                ),
              },
            ],
          ),
          if (widget.title != null || widget.otherSideTitle != null) ...{
            10.sbH,
          },
          TextFormField(
            controller: _selectedEC,
            validator: (v) => widget.validator?.call(widget.value),
            onTap: widget.apiResponse?.state == ResponseState.loading
                ? null
                : widget.items != null && widget.items?.isNotEmpty == true
                    ? () {
                        Utils.showAppBottomSheet(
                          CustomSingleSelectBottomSheet(
                            value: widget.value,
                            items: widget.items,
                            hasRemove: widget.hasRemove,
                            onChanged: (v) {
                              widget.onChanged?.call(v);
                            },
                          ),
                          isScrollControlled: true,
                        );
                      }
                    : () => CommonMethods.showAlertDialog(
                          message: 'There is no data'.tr,
                        ),
            readOnly: true,
            style: AppTextStyle.textFormStyle,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            maxLines: widget.maxLines,
            cursorColor: widget.focusColor,
            decoration: InputDecoration(
              hintMaxLines: 2,
              hintText: widget.hintText,
              hintStyle: widget.hintStyle ?? AppTextStyle.hintStyle,
              fillColor: widget.fillColor ??
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
                color: widget.unFocusColor ?? AppColors.mainAppColor,
              ),
              enabledBorder: _border(
                color: widget.unFocusColor ?? AppColors.textFormBorderColor,
              ),
              contentPadding: const EdgeInsets.symmetric(
                vertical: 10,
                horizontal: 10,
              ),
              suffixIconConstraints: BoxConstraints(
                maxWidth: widget.suffixIcon != null ? 110 : 40,
              ),
              prefixIcon: widget.prefixIcon,
              suffixIcon: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 35,
                    child: widget.apiResponse != null
                        ? ApiResponseWidget(
                            apiResponse: widget.apiResponse!,
                            onReload: widget.onReload,
                            isEmpty: false,
                            errorWidget: IconButton(
                              onPressed: widget.onReload,
                              icon: Icon(
                                Icons.wifi_protected_setup_rounded,
                                color: AppColors.hintColor,
                              ),
                            ),
                            offlineWidget: GestureDetector(
                              onTap: widget.onReload,
                              child: Icon(
                                Icons.wifi_protected_setup_rounded,
                                color: AppColors.hintColor,
                              ),
                            ),
                            loadingWidget: const CupertinoActivityIndicator(),
                            child: widget.icon ??
                                Icon(
                                  widget.items == null || widget.items!.isEmpty
                                      ? Icons.error_rounded
                                      : Icons.keyboard_arrow_down_rounded,
                                  color: AppColors.hintColor,
                                  size: 25,
                                ),
                          )
                        : widget.icon ??
                            Icon(
                              widget.items == null || widget.items!.isEmpty
                                  ? Icons.error_rounded
                                  : Icons.keyboard_arrow_down_rounded,
                              color: AppColors.hintColor,
                              size: 25,
                            ),
                  ),
                  if (widget.suffixIcon != null) ...{
                    widget.suffixIcon ?? const SizedBox(),
                    const SizedBox(width: 10),
                  },
                ],
              ),
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
}

class CustomSingleSelectBottomSheet extends StatefulWidget {
  final dynamic value;
  final List<CustomSelectItem>? items;
  final void Function(dynamic)? onChanged;
  final bool hasRemove;
  const CustomSingleSelectBottomSheet({
    super.key,
    this.value,
    this.items,
    this.onChanged,
    this.hasRemove = true,
  });

  @override
  State<CustomSingleSelectBottomSheet> createState() =>
      _CustomSingleSelectBottomSheetState();
}

class _CustomSingleSelectBottomSheetState
    extends State<CustomSingleSelectBottomSheet> {
  dynamic _initialValue;
  List<CustomSelectItem>? _items;
  @override
  void initState() {
    _initialValue = widget.value;
    _items = widget.items;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      // margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
      decoration: BoxDecoration(
        color: FasakhanstaBrand.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
      ),
      constraints: BoxConstraints(maxHeight: context.height * 0.75),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              children: [
                CustomButton(
                  text: 'Done'.tr,
                  height: 47,
                  width: 90,
                  onPressed: () {
                    widget.onChanged?.call(_initialValue);
                    Navigator.pop(context);
                  },
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: CustomFormField(
                    fillColor: AppColors.offWhiteColor,
                    unFocusColor: AppColors.offWhiteColor,
                    hintText: 'search'.tr,
                    onChanged: (v) {
                      _items = widget.items
                          ?.where(
                            (element) => element.name.toLowerCase().contains(v),
                          )
                          .toList();
                      setState(() {});
                    },
                  ),
                ),
              ],
            ),
          ),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
              child: Column(
                children: [
                  ...List.generate(
                    _items?.length ?? 0,
                    (index) => Column(
                      children: [
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () {
                              switch (widget.hasRemove) {
                                case true:
                                  if (_initialValue == _items?[index].value) {
                                    setState(() {
                                      _initialValue = null;
                                    });
                                  } else {
                                    setState(() {
                                      _initialValue = _items?[index].value;
                                    });
                                  }
                                  break;
                                case false:
                                  setState(() {
                                    _initialValue = _items?[index].value;
                                  });
                                  break;
                              }
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 5),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      _items?[index].name ?? '',
                                      style: TextStyle(
                                        color: AppColors.darkTextColor,
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  CircleAvatar(
                                    backgroundColor:
                                        _initialValue == _items?[index].value
                                            ? AppColors.mainAppColor
                                            : AppColors.greyColor,
                                    radius: 11,
                                    child: CircleAvatar(
                                      backgroundColor: FasakhanstaBrand.surface,
                                      radius: 9,
                                      child: CircleAvatar(
                                        backgroundColor: _initialValue ==
                                                _items?[index].value
                                            ? AppColors.mainAppColor
                                            : FasakhanstaBrand.surface,
                                        radius: 7,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        5.sbH,
                      ],
                    ),
                  ),
                  SizedBox(height: MediaQuery.viewInsetsOf(context).bottom),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
