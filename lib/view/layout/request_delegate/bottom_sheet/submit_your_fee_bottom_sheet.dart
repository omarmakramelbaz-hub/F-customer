import 'package:faskhaninja/helpers/theme/fasakhansta_brand.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../../helpers/extensions/extensions.dart';
import '../../../../helpers/routes/app_routers_import.dart';
import '../../../../helpers/theme/app_colors.dart';
import '../../../../helpers/translation/all_translation.dart';
import '../controller/request_delegate_controller.dart';
import '../widget/payment_methoud_widget.dart';

class SubmitYourFeeBottomSheet extends StatefulWidget {
  const SubmitYourFeeBottomSheet({
    super.key,
    required this.requestDelegateController,
    required this.kmPrice,
    required this.shippingPercentage,
    required this.distance,
  });

  final RequestDelegateController requestDelegateController;
  final num kmPrice;
  final num shippingPercentage;
  final num distance;

  @override
  State<SubmitYourFeeBottomSheet> createState() =>
      _SubmitYourFeeBottomSheetState();
}

class _SubmitYourFeeBottomSheetState extends State<SubmitYourFeeBottomSheet> {
  final TextEditingController _feeEC = TextEditingController();
  final FocusNode focusNode = FocusNode();
  final _formKey = GlobalKey<FormState>();

  late final double _referenceFare;
  late final double _minimumFare;
  late final double _maximumReductionPercentage;

  bool get _isArabic => context.languageCode == 'ar';

  @override
  void initState() {
    super.initState();

    _feeEC.text = widget.requestDelegateController.priceEC.text;

    final currentFare =
        double.tryParse(widget.requestDelegateController.priceEC.text.trim()) ??
        0;

    _referenceFare = currentFare > 0 ? currentFare : widget.distance.toDouble();
    final dashboardReduction =
        widget
            .requestDelegateController
            .delegatesOnMap
            ?.shippingMinPricePrecentage ??
        widget.shippingPercentage;
    _maximumReductionPercentage = dashboardReduction
        .toDouble()
        .clamp(0.0, 100.0)
        .toDouble();
    _minimumFare = (_referenceFare * (1 - (_maximumReductionPercentage / 100)))
        .ceilToDouble();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<RequestDelegateController>();
      }
    });
  }

  @override
  void dispose() {
    _feeEC.dispose();
    focusNode.dispose();
    super.dispose();
  }

  String? _validateFare(String? value) {
    final inputValue = double.tryParse((value ?? '').trim());

    if (inputValue == null) {
      return 'enterAmount'.tr;
    }

    if (_referenceFare > 0 && inputValue < _minimumFare) {
      return _isArabic
          ? 'أقل مبلغ مسموح هو ${_minimumFare.toStringAsFixed(0)} ج'
          : 'Minimum allowed fare is ${_minimumFare.toStringAsFixed(0)} EGP';
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    final viewInsets = MediaQuery.of(context).viewInsets;
    final reductionLabel = _maximumReductionPercentage.toStringAsFixed(
      _maximumReductionPercentage % 1 == 0 ? 0 : 1,
    );

    return Padding(
      padding: EdgeInsets.only(bottom: viewInsets.bottom),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * .86,
        ),
        decoration: const BoxDecoration(
          color: FasakhanstaBrand.surface,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(30),
            topRight: Radius.circular(30),
          ),
          boxShadow: [
            BoxShadow(
              color: Color(0x22000000),
              blurRadius: 24,
              offset: Offset(0, -7),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Directionality(
            textDirection: _isArabic ? TextDirection.rtl : TextDirection.ltr,
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(18, 10, 18, 18),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        width: 44,
                        height: 5,
                        decoration: BoxDecoration(
                          color: FasakhanstaBrand.surfaceRaised,
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _isArabic
                          ? 'عاوز تدفع كام؟'
                          : 'How much do you want to pay?',
                      style: const TextStyle(
                        color: FasakhanstaBrand.text,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      _isArabic
                          ? 'حدد المبلغ المناسب ليك، ويمكن تقليله بحد أقصى $reductionLabel%.'
                          : 'Choose your fare. You can reduce it by up to $reductionLabel%.',
                      style: const TextStyle(
                        color: FasakhanstaBrand.muted,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: FasakhanstaBrand.surfaceRaised,
                        borderRadius: BorderRadius.circular(17),
                        border: Border.all(
                          color: AppColors.mainAppColor.withOpacity(.20),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: FasakhanstaBrand.surface,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.payments_outlined,
                              color: AppColors.mainAppColor,
                              size: 23,
                            ),
                          ),
                          const SizedBox(width: 11),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _isArabic
                                      ? 'السعر المحدد'
                                      : 'Calculated fare',
                                  style: const TextStyle(
                                    color: FasakhanstaBrand.muted,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${_referenceFare.toStringAsFixed(0)} ${_isArabic ? 'ج' : 'EGP'}',
                                  style: const TextStyle(
                                    color: FasakhanstaBrand.text,
                                    fontSize: 19,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 7,
                            ),
                            decoration: BoxDecoration(
                              color: FasakhanstaBrand.surface,
                              borderRadius: BorderRadius.circular(11),
                            ),
                            child: Text(
                              _isArabic
                                  ? 'الحد الأدنى ${_minimumFare.toStringAsFixed(0)} ج'
                                  : 'Min ${_minimumFare.toStringAsFixed(0)} EGP',
                              style: TextStyle(
                                color: AppColors.mainAppColor,
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 13),
                    TextFormField(
                      controller: _feeEC,
                      focusNode: focusNode,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      validator: _validateFare,
                      textAlign: TextAlign.start,
                      style: const TextStyle(
                        color: FasakhanstaBrand.text,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                      decoration: InputDecoration(
                        labelText: _isArabic
                            ? 'المبلغ اللي هتدفعه'
                            : 'Your fare',
                        labelStyle: const TextStyle(
                          color: FasakhanstaBrand.muted,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                        suffixIcon: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          child: Center(
                            widthFactor: 1,
                            child: Text(
                              _isArabic ? 'جنيه مصري' : 'EGP',
                              style: const TextStyle(
                                color: FasakhanstaBrand.muted,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                        filled: true,
                        fillColor: FasakhanstaBrand.field,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 15,
                          vertical: 17,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                          borderSide: const BorderSide(
                            color: FasakhanstaBrand.border,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                          borderSide: BorderSide(
                            color: AppColors.mainAppColor,
                            width: 1.4,
                          ),
                        ),
                        errorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                          borderSide: const BorderSide(
                            color: FasakhanstaBrand.border,
                          ),
                        ),
                        focusedErrorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                          borderSide: const BorderSide(
                            color: FasakhanstaBrand.border,
                            width: 1.4,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      _isArabic ? 'طريقة الدفع' : 'Payment method',
                      style: const TextStyle(
                        color: FasakhanstaBrand.text,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const ChoosePaymentMethodWidget(),
                    const SizedBox(height: 18),
                    SizedBox(
                      height: 54,
                      child: ElevatedButton(
                        onPressed: () {
                          if (_formKey.currentState!.validate()) {
                            widget.requestDelegateController.setPriceEC(
                              _feeEC.text.trim(),
                            );
                            widget.requestDelegateController.setActualPrice(
                              _feeEC.text.trim(),
                            );
                            NamedNavigatorImpl.pop();
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.mainAppColor,
                          foregroundColor: FasakhanstaBrand.onOrange,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(17),
                          ),
                        ),
                        child: Text(
                          _isArabic ? 'تأكيد المبلغ' : 'Confirm fare',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
