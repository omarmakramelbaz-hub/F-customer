import 'package:country_picker/country_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../../helpers/theme/app_colors.dart';
import '../../../../helpers/translation/all_translation.dart';
import '../../../../helpers/utils/common_methods.dart';
import '../../../custom_widgets/buttons/custom_button.dart';
import '../../../custom_widgets/custom_form_field/custom_form_field.dart';
import '../../../custom_widgets/global_widgets/app_bottom_sheet.dart';
import '../../../custom_widgets/validation/validation_mixin.dart';
import '../../auth/controller/auth_controller.dart';
import '../controller/wallet_controller.dart';
import '../model/wallet_transfer.dart';

class MoneyTransferBottomSheet extends StatefulWidget {
  const MoneyTransferBottomSheet({super.key, required this.walletController});
  final WalletController walletController;

  @override
  State<MoneyTransferBottomSheet> createState() =>
      _MoneyTransferBottomSheetState();
}

class _MoneyTransferBottomSheetState extends State<MoneyTransferBottomSheet>
    with ValidationMixin {
  Country? _country;

  final chargeWalletFormKey = GlobalKey<FormState>();
  final chargeAmountEc = TextEditingController();
  final mobileEc = TextEditingController();
  final chargeAmountFocusNode = FocusNode();
  TransferWallet? _selectedWallet;
  WalletTransferPreview? _preview;
  bool _busy = false;

  @override
  void initState() {
    _country = CountryParser.parsePhoneCode('20');
    super.initState();
  }

  @override
  void dispose() {
    chargeAmountEc.dispose();
    mobileEc.dispose();
    chargeAmountFocusNode.dispose();
    super.dispose();
  }

  Future<void> _reviewTransfer() async {
    if (_busy || !chargeWalletFormKey.currentState!.validate()) return;
    setState(() => _busy = true);
    try {
      _preview ??= await widget.walletController.checkMonyTransfer(
        wallet: _selectedWallet!,
        mobile: mobileEc.text.trim(),
        amount: num.parse(chargeAmountEc.text),
      );
      if (!mounted || _preview == null) return;
      final preview = _preview!;
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text('reviewWalletTransfer'.tr),
          content: Text(
            [
              preview.wallet.labelKey.tr,
              '${'walletRecipientName'.tr}: ${preview.recipientName}',
              '${'mobileNumber'.tr}: ${preview.mobile}',
              '${'walletTransferAmount'.tr}: ${preview.amount} EGP',
            ].join('\n'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text('no'.tr),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: Text('transfer'.tr),
            ),
          ],
        ),
      );
      if (!mounted || confirmed != true) return;
      final result = await widget.walletController.chargingMonyTransfer(
        preview,
      );
      if (!mounted) return;
      if (result == true) {
        final auth = context.read<AuthController>();
        widget.walletController.getWallet();
        auth.getProfile();
        Navigator.pop(context);
      } else if (result == false) {
        _preview = null; // Explicit rejection: no money moved; request fresh confirmation.
      }
    } catch (_) {
      if (mounted) CommonMethods.showError(message: 'walletTransferFailed'.tr);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AbsorbPointer(
              absorbing: _busy,
              child: Form(
                key: chargeWalletFormKey,
                child: AppBottomSheet(
                  title: 'moneyTransfer'.tr,
                  children: [
                    const SizedBox(height: 21),
                    Text(
                      'recipientWallet'.tr,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    FormField<TransferWallet>(
                      validator: (_) => _selectedWallet == null
                          ? 'chooseRecipientWallet'.tr
                          : null,
                      builder: (field) => Column(
                        children: [
                          for (final wallet in TransferWallet.values)
                            RadioListTile<TransferWallet>(
                              contentPadding: EdgeInsets.zero,
                              title: Text(wallet.labelKey.tr),
                              value: wallet,
                              groupValue: _selectedWallet,
                              activeColor: AppColors.mainAppColor,
                              onChanged: (value) {
                                setState(() {
                                  _selectedWallet = value;
                                  _preview = null;
                                });
                                field.didChange(value);
                              },
                            ),
                          if (field.hasError)
                            Text(
                              field.errorText!,
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.error,
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    CustomFormField(
                      controller: mobileEc,
                      onChanged: (_) => _preview = null,
                      title: 'mobileNumber'.tr,
                      keyboardType: TextInputType.phone,
                      hintText: 'mobileNumber'.tr,
                      validator: (v) => validatePhone(v, country: _country),
                      country: _country,
                    ),
                    const SizedBox(height: 21),
                    CustomFormField(
                      title: 'amountToBeTransferred'.tr,
                      hintText: 'enterAmount'.tr,
                      controller: chargeAmountEc,
                      onChanged: (_) => _preview = null,
                      keyboardType: TextInputType.number,
                      focusNode: chargeAmountFocusNode,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      onFieldSubmitted: (p0) {
                        chargeAmountFocusNode.unfocus();
                      },
                      validator: (p0) {
                        if (p0 == null || p0.isEmpty) {
                          return 'enterAmount'.tr;
                        } else if ((num.tryParse(p0) ?? 0) < 1 ||
                            double.parse(p0) > 5000 ||
                            p0.startsWith('0')) {
                          return 'theMaximumTransferIs5000EGP'.tr;
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 21),
                    CustomButton(
                      text: 'reviewWalletTransfer'.tr,
                      isLoading: _busy,
                      onPressed: _busy ? null : _reviewTransfer,
                    ),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
