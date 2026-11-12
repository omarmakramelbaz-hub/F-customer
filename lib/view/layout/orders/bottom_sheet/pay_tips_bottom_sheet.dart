import 'package:faskhaninja/helpers/theme/fasakhansta_brand.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

import '../../../../helpers/extensions/extensions.dart';
import '../../../../helpers/images/app_images.dart';
import '../../../../helpers/theme/app_colors.dart';
import '../../../../helpers/theme/app_text_style.dart';
import '../../../../helpers/translation/all_translation.dart';
import '../../../custom_widgets/buttons/custom_button.dart';
import '../../../custom_widgets/custom_form_field/custom_form_field.dart';
import '../../../custom_widgets/validation/validation_mixin.dart';
import '../controller/orders_controller.dart';

class PayTipsBottomSheet extends StatefulWidget {
  final int orderId;
  final VoidCallback onSuccess;
  const PayTipsBottomSheet({
    super.key,
    required this.orderId,
    required this.onSuccess,
  });

  @override
  State<PayTipsBottomSheet> createState() => _PayTipsBottomSheetState();
}

class _PayTipsBottomSheetState extends State<PayTipsBottomSheet>
    with ValidationMixin {
  final commissionEc = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final _focusNode = FocusNode();

  @override
  dispose() {
    _focusNode.dispose();
    commissionEc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: ChangeNotifierProvider(
        create: (BuildContext context) => OrdersController(),
        child: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Form(
            key: _formKey,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 10),
              // height: context.height * .4,
              decoration: BoxDecoration(
                color: FasakhanstaBrand.surface,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(36),
                  topRight: Radius.circular(36),
                ),
              ),
              child: Column(
                children: [
                  20.sbH,
                  Row(
                    children: [
                      Text(
                        'payATipsToTheRepresentative'.tr,
                        style: AppTextStyle.text16MS(),
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Card(
                          elevation: 10,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: CircleAvatar(
                            radius: 20,
                            backgroundColor: FasakhanstaBrand.surface,
                            child: SvgPicture.asset(AppImages.cancelIcon),
                          ),
                        ),
                      ),
                    ],
                  ),
                  10.sbH,
                  const Divider(thickness: 1),
                  20.sbH,
                  CustomFormField(
                    controller: commissionEc,
                    validator: validateEmptyField,
                    keyboardType: TextInputType.number,
                    hintText: 'enterAmount'.tr,
                    focusNode: _focusNode,
                    onFieldSubmitted: (p0) {
                      _focusNode.unfocus();
                    },
                  ),
                  20.sbH,
                  Builder(
                    builder: (context) {
                      return CustomButton(
                        onPressed: () {
                          if (_formKey.currentState!.validate()) {
                            context.read<OrdersController>().commissionOrder(
                                  orderId: widget.orderId,
                                  commission: int.parse(commissionEc.text),
                                  onSuccess: () {
                                    Navigator.pop(context);
                                    widget.onSuccess.call();
                                  },
                                );
                          }
                        },
                        radius: 23,
                        text: 'send'.tr,
                        style: AppTextStyle.text16BW(
                          color: FasakhanstaBrand.onOrange,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
