import 'package:faskhaninja/helpers/theme/fasakhansta_brand.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';

import '../../../../helpers/extensions/extensions.dart';
import '../../../../helpers/routes/app_routers_import.dart';
import '../../../../helpers/theme/app_colors.dart';
import '../../../../helpers/translation/all_translation.dart';
import '../../../../helpers/utils/common_methods.dart';
import '../../../../helpers/utils/utils.dart';
import '../bottom_sheet/payment_rd_bottom_sheet.dart';
import '../bottom_sheet/submit_your_fee_bottom_sheet.dart';
import '../controller/request_delegate_controller.dart';
import '../screen/search_place_screen.dart';

class CustomMapAnimatedContainer extends StatelessWidget {
  const CustomMapAnimatedContainer({super.key, required this.containerHeight});

  final double? containerHeight;

  static const _textColor = FasakhanstaBrand.text;
  static const _mutedColor = FasakhanstaBrand.muted;
  static const _borderColor = FasakhanstaBrand.border;
  static const _softOrange = FasakhanstaBrand.orangeTint;

  bool _isArabic(BuildContext context) => context.languageCode == 'ar';

  @override
  Widget build(BuildContext context) {
    return Consumer<RequestDelegateController>(
      builder: (context, controller, _) {
        final isHidden = containerHeight == 0;
        final compact = context.height < 820;
        final targetHeight = isHidden ? 0.0 : (compact ? 347.0 : 383.0);
        final gap = compact ? 5.0 : 6.0;
        final cardHeight = compact ? 49.0 : 53.0;
        final iconBox = compact ? 34.0 : 38.0;
        final headerHeight = compact ? 48.0 : 54.0;
        final summaryHeight = compact ? 54.0 : 58.0;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 260),
          height: targetHeight,
          clipBehavior: Clip.antiAlias,
          decoration: const BoxDecoration(
            color: FasakhanstaBrand.surface,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(32),
              topRight: Radius.circular(32),
            ),
            boxShadow: [
              BoxShadow(
                color: Color(0x1A000000),
                blurRadius: 24,
                offset: Offset(0, -7),
              ),
            ],
          ),
          child: isHidden
              ? const SizedBox.shrink()
              : Padding(
                  padding: EdgeInsets.fromLTRB(
                    14,
                    compact ? 7 : 8,
                    14,
                    compact ? 7 : 9,
                  ),
                  child: Directionality(
                    textDirection: _isArabic(context)
                        ? TextDirection.rtl
                        : TextDirection.ltr,
                    child: Column(
                      mainAxisSize: MainAxisSize.max,
                      children: [
                        _dragHandle(compact),
                        SizedBox(height: compact ? 6 : 7),
                        SizedBox(
                          height: headerHeight,
                          child: _header(context, compact),
                        ),
                        SizedBox(height: gap),
                        _addressesCard(
                          context,
                          controller,
                          cardHeight: cardHeight,
                          iconBox: iconBox,
                          compact: compact,
                        ),
                        SizedBox(height: gap),
                        _packageCard(
                          context,
                          controller,
                          cardHeight: cardHeight,
                          iconBox: iconBox,
                          compact: compact,
                        ),
                        SizedBox(height: gap),
                        _fareCard(
                          context,
                          controller,
                          cardHeight: cardHeight,
                          iconBox: iconBox,
                          compact: compact,
                        ),
                        SizedBox(height: gap),
                        _paymentCard(
                          context,
                          controller,
                          cardHeight: cardHeight,
                          iconBox: iconBox,
                          compact: compact,
                        ),
                        SizedBox(height: gap),
                        SizedBox(
                          height: summaryHeight,
                          child: _summaryCard(context, controller, compact),
                        ),
                      ],
                    ),
                  ),
                ),
        );
      },
    );
  }

  Widget _dragHandle(bool compact) {
    return Container(
      width: 44,
      height: compact ? 4 : 5,
      decoration: BoxDecoration(
        color: FasakhanstaBrand.surfaceRaised,
        borderRadius: BorderRadius.circular(20),
      ),
    );
  }

  Widget _header(BuildContext context, bool compact) {
    return Row(
      children: [
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _isArabic(context)
                    ? 'توصيل سريع وآمن'
                    : 'Fast & secure delivery',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: _textColor,
                  fontSize: compact ? 19 : 21,
                  fontWeight: FontWeight.w800,
                  height: 1.05,
                ),
              ),
              SizedBox(height: compact ? 2 : 4),
              Text(
                _isArabic(context)
                    ? 'حدد تفاصيل طلبك واختر ما يناسبك'
                    : 'Set your order details and choose what suits you',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: _mutedColor,
                  fontSize: compact ? 10.5 : 11.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: compact ? 72 : 80,
          height: compact ? 50 : 56,
          child: Image.asset(
            'assets/images/deliveryRiderV2.png',
            fit: BoxFit.contain,
            filterQuality: FilterQuality.high,
            gaplessPlayback: true,
            errorBuilder: (context, error, stackTrace) {
              debugPrint('Delivery rider asset error: $error');
              return const SizedBox.shrink();
            },
          ),
        ),
      ],
    );
  }

  Widget _addressesCard(
    BuildContext context,
    RequestDelegateController controller, {
    required double cardHeight,
    required double iconBox,
    required bool compact,
  }) {
    final hasPickup =
        controller.fromLat != null &&
        controller.fromLan != null &&
        controller.fromLat!.isNotEmpty &&
        controller.fromLan!.isNotEmpty;
    final hasDestination =
        controller.toLat != null &&
        controller.toLan != null &&
        controller.toLat!.isNotEmpty &&
        controller.toLan!.isNotEmpty;

    final subtitle = hasPickup && hasDestination
        ? (_isArabic(context)
              ? 'تم تحديد عنواني الاستلام والتوصيل'
              : 'Pickup and delivery addresses selected')
        : hasPickup
        ? (_isArabic(context)
              ? 'حدد عنوان التوصيل'
              : 'Choose the delivery address')
        : (_isArabic(context)
              ? 'حدد موقع الاستلام وعنوان التوصيل'
              : 'Set pickup and delivery addresses');

    return _actionCard(
      context: context,
      icon: Icons.my_location_rounded,
      title: _isArabic(context) ? 'تحديد العناوين' : 'Set addresses',
      subtitle: subtitle,
      highlight: hasPickup && hasDestination,
      trailing: Icon(
        Icons.chevron_left_rounded,
        color: FasakhanstaBrand.muted,
        size: compact ? 20 : 22,
      ),
      onTap: () => _openSearchPlace(controller),
      cardHeight: cardHeight,
      iconBox: iconBox,
      compact: compact,
    );
  }

  Widget _packageCard(
    BuildContext context,
    RequestDelegateController controller, {
    required double cardHeight,
    required double iconBox,
    required bool compact,
  }) {
    final value = controller.descriptionEC.text.trim();
    return _actionCard(
      context: context,
      icon: Icons.inventory_2_outlined,
      title: _isArabic(context)
          ? 'الغرض المطلوب توصيله'
          : 'Item to be delivered',
      subtitle: value.isNotEmpty
          ? value
          : (_isArabic(context)
                ? 'اضغط واكتب وصف الغرض'
                : 'Tap to describe the item'),
      highlight: value.isNotEmpty,
      trailing: Icon(
        Icons.edit_outlined,
        color: FasakhanstaBrand.muted,
        size: compact ? 18 : 20,
      ),
      onTap: () => _openPackageEditor(context, controller),
      cardHeight: cardHeight,
      iconBox: iconBox,
      compact: compact,
    );
  }

  Widget _fareCard(
    BuildContext context,
    RequestDelegateController controller, {
    required double cardHeight,
    required double iconBox,
    required bool compact,
  }) {
    final hasFare = controller.priceEC.text.trim().isNotEmpty;
    final fareValue = hasFare
        ? '${controller.priceEC.text.trim()} ${_isArabic(context) ? 'ج' : 'EGP'}'
        : (_isArabic(context)
              ? 'حدد الأجرة التي تريد دفعها'
              : 'Set the fare you want to pay');

    return _actionCard(
      context: context,
      icon: Icons.payments_outlined,
      title: _isArabic(context)
          ? 'عاوز تدفع كام'
          : 'How much do you want to pay?',
      subtitle: fareValue,
      highlight: hasFare,
      trailing: Icon(
        Icons.chevron_left_rounded,
        color: FasakhanstaBrand.muted,
        size: compact ? 20 : 22,
      ),
      onTap: () => _openFareSheet(context, controller),
      cardHeight: cardHeight,
      iconBox: iconBox,
      compact: compact,
    );
  }

  Widget _paymentCard(
    BuildContext context,
    RequestDelegateController controller, {
    required double cardHeight,
    required double iconBox,
    required bool compact,
  }) {
    final payment = switch (controller.selectedPayment) {
      'wallet' => _isArabic(context) ? 'المحفظة' : 'Wallet',
      'online' => _isArabic(context) ? 'بطاقة بنكية' : 'Bank card',
      'v_cash' =>
        _isArabic(context) ? 'محفظة إلكترونية / إنستا باي' : 'Digital wallet',
      'cash' => _isArabic(context) ? 'نقدًا' : 'Cash',
      _ => _isArabic(context) ? 'اختر طريقة الدفع' : 'Choose payment method',
    };

    return _actionCard(
      context: context,
      icon: Icons.account_balance_wallet_outlined,
      title: _isArabic(context) ? 'الدفع' : 'Payment',
      subtitle: payment,
      trailing: Icon(
        Icons.chevron_left_rounded,
        color: FasakhanstaBrand.muted,
        size: compact ? 20 : 22,
      ),
      onTap: () => _openPaymentSheet(context, controller),
      cardHeight: cardHeight,
      iconBox: iconBox,
      compact: compact,
    );
  }

  Widget _summaryCard(
    BuildContext context,
    RequestDelegateController controller,
    bool compact,
  ) {
    final fare = controller.priceEC.text.trim().isEmpty
        ? '—'
        : '${controller.priceEC.text.trim()} ${_isArabic(context) ? 'ج' : 'EGP'}';

    final fromLat = double.tryParse(controller.fromLat ?? '');
    final fromLng = double.tryParse(controller.fromLan ?? '');
    final toLat = double.tryParse(controller.toLat ?? '');
    final toLng = double.tryParse(controller.toLan ?? '');
    final hasDistance =
        fromLat != null && fromLng != null && toLat != null && toLng != null;
    final distanceKm = hasDistance
        ? Geolocator.distanceBetween(fromLat, fromLng, toLat, toLng) / 1000
        : 0.0;
    final distance = hasDistance
        ? '${distanceKm.toStringAsFixed(1)} ${_isArabic(context) ? 'كم' : 'km'}'
        : '—';
    final eta = hasDistance ? _deliveryEta(context, distanceKm) : '—';

    return Container(
      decoration: _cardDecoration(),
      padding: EdgeInsets.symmetric(vertical: compact ? 5 : 7),
      child: Row(
        children: [
          Expanded(
            child: _summaryItem(
              icon: Icons.route_outlined,
              label: _isArabic(context) ? 'المسافة' : 'Distance',
              value: distance,
              compact: compact,
            ),
          ),
          _divider(compact),
          Expanded(
            child: _summaryItem(
              icon: Icons.account_balance_wallet_outlined,
              label: _isArabic(context) ? 'الأجرة' : 'Fare',
              value: fare,
              compact: compact,
            ),
          ),
          _divider(compact),
          Expanded(
            child: _summaryItem(
              icon: Icons.schedule_rounded,
              label: _isArabic(context) ? 'وقت التوصيل' : 'ETA',
              value: eta,
              compact: compact,
            ),
          ),
        ],
      ),
    );
  }

  String _deliveryEta(BuildContext context, double distanceKm) {
    final isArabic = _isArabic(context);
    if (distanceKm <= 5) {
      return isArabic ? '30 - 45 د' : '30 - 45 min';
    }
    if (distanceKm <= 10) {
      return isArabic ? '60 - 90 د' : '60 - 90 min';
    }
    if (distanceKm <= 20) {
      return isArabic ? '90 - 150 د' : '90 - 150 min';
    }
    return isArabic ? 'خلال 6 ساعات' : 'Within 6 hrs';
  }

  Widget _summaryItem({
    required IconData icon,
    required String label,
    required String value,
    required bool compact,
  }) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: FasakhanstaBrand.muted, size: compact ? 17 : 19),
        const SizedBox(height: 2),
        Text(
          label,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: _textColor,
            fontSize: compact ? 9 : 9.5,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 1),
        Text(
          value,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: AppColors.mainAppColor,
            fontSize: compact ? 12.5 : 13.5,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }

  Widget _divider(bool compact) {
    return Container(
      width: 1,
      height: compact ? 37 : 41,
      color: FasakhanstaBrand.surfaceRaised,
    );
  }

  Widget _actionCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required Widget trailing,
    required VoidCallback onTap,
    required double cardHeight,
    required double iconBox,
    required bool compact,
    bool highlight = false,
  }) {
    return SizedBox(
      height: cardHeight,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(15),
          onTap: onTap,
          child: Ink(
            decoration: _cardDecoration(highlight: highlight),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: compact ? 10 : 12),
              child: Row(
                children: [
                  Container(
                    width: iconBox,
                    height: iconBox,
                    decoration: BoxDecoration(
                      color: _softOrange,
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: Icon(
                      icon,
                      color: AppColors.mainAppColor,
                      size: compact ? 19 : 21,
                    ),
                  ),
                  SizedBox(width: compact ? 9 : 10),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: _textColor,
                            fontSize: compact ? 12.3 : 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: highlight
                                ? AppColors.mainAppColor
                                : _mutedColor,
                            fontSize: compact ? 10 : 10.8,
                            fontWeight: highlight
                                ? FontWeight.w600
                                : FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  trailing,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  BoxDecoration _cardDecoration({bool highlight = false}) {
    return BoxDecoration(
      color: FasakhanstaBrand.surface,
      borderRadius: BorderRadius.circular(15),
      border: Border.all(
        color: highlight
            ? AppColors.mainAppColor.withOpacity(.72)
            : _borderColor,
        width: highlight ? 1.1 : 1,
      ),
      boxShadow: const [
        BoxShadow(
          color: Color(0x0A000000),
          blurRadius: 9,
          offset: Offset(0, 3),
        ),
      ],
    );
  }

  void _openSearchPlace(RequestDelegateController controller) {
    NamedNavigatorImpl.push(SearchPlaceScreen.routeName);
    if (controller.fromAddress.isNotEmpty) {
      controller.setFromController(controller.fromAddress);
    }
    if (controller.fromLat != null && controller.fromLat!.isNotEmpty) {
      controller.setFromLat(controller.fromLat!);
    }
    if (controller.fromLan != null && controller.fromLan!.isNotEmpty) {
      controller.setFromLan(controller.fromLan!);
    }
  }

  Future<void> _openPackageEditor(
    BuildContext context,
    RequestDelegateController controller,
  ) async {
    final textController = TextEditingController(
      text: controller.descriptionEC.text,
    );

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        final isAr = _isArabic(sheetContext);
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
          ),
          child: Container(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 22),
            decoration: const BoxDecoration(
              color: FasakhanstaBrand.surface,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(30),
                topRight: Radius.circular(30),
              ),
            ),
            child: SafeArea(
              top: false,
              child: Directionality(
                textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(child: _dragHandle(false)),
                    const SizedBox(height: 18),
                    Text(
                      isAr ? 'الغرض المطلوب توصيله' : 'Item to be delivered',
                      style: const TextStyle(
                        color: _textColor,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      isAr
                          ? 'اكتب وصفًا واضحًا للغرض أو أي تفاصيل مهمة'
                          : 'Add a clear description and important details',
                      style: const TextStyle(color: _mutedColor, fontSize: 12),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: textController,
                      autofocus: true,
                      minLines: 3,
                      maxLines: 5,
                      keyboardType: TextInputType.multiline,
                      textInputAction: TextInputAction.newline,
                      style: const TextStyle(color: _textColor, fontSize: 15),
                      decoration: InputDecoration(
                        hintText: isAr
                            ? 'مثال: كرتونة مستندات صغيرة'
                            : 'Example: small document box',
                        hintStyle: const TextStyle(
                          color: FasakhanstaBrand.muted,
                        ),
                        filled: true,
                        fillColor: FasakhanstaBrand.field,
                        contentPadding: const EdgeInsets.all(16),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(color: _borderColor),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(
                            color: AppColors.mainAppColor,
                            width: 1.4,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 52,
                      child: ElevatedButton(
                        onPressed: () {
                          controller.setDescriptionEC(
                            textController.text.trim(),
                          );
                          Navigator.pop(sheetContext);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.mainAppColor,
                          foregroundColor: FasakhanstaBrand.onOrange,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Text(
                          isAr ? 'حفظ التفاصيل' : 'Save details',
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
        );
      },
    );

    textController.dispose();
  }

  Future<void> _openPaymentSheet(
    BuildContext context,
    RequestDelegateController controller,
  ) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ChangeNotifierProvider.value(
        value: controller,
        child: PaymentRDBottomSheet(requestDelegateController: controller),
      ),
    );
  }

  void _openFareSheet(
    BuildContext context,
    RequestDelegateController controller,
  ) {
    if (controller.toLat != null &&
        controller.toLan != null &&
        controller.fromLat != null &&
        controller.fromLan != null) {
      Utils.showAppBottomSheet(
        ChangeNotifierProvider.value(
          value: controller,
          child: SubmitYourFeeBottomSheet(
            requestDelegateController: controller,
            kmPrice:
                int.tryParse('${controller.delegatesOnMap?.shippingKmPrice}') ??
                0,
            shippingPercentage: 10,
            distance: num.tryParse('${controller.distance}') ?? 0,
          ),
        ),
      );
    } else {
      CommonMethods.showError(message: 'chooseDeliveryLocationsFirst'.tr);
    }
  }
}
