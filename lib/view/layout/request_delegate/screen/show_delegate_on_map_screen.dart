import 'dart:async';

import 'package:defer_pointer/defer_pointer.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';

import '../../../../helpers/extensions/extensions.dart';
import '../../../../helpers/routes/app_routers_import.dart';
import '../../../../helpers/theme/app_colors.dart';
import '../../../../helpers/translation/all_translation.dart';
import '../../../../helpers/utils/common_methods.dart';
import '../../../custom_widgets/validation/validation_mixin.dart';
import '../../bottom_navigation/bottom_navigation_bar_screen.dart';
import '../controller/request_delegate_controller.dart';
import '../model/accepted_delegate_model.dart';
import '../widget/custom_google_maps_widget.dart';
import '../widget/delegate_offer_widget.dart';

class ShowDelegateOnMapArgs {
  final num kmPrice;
  final num shippingPercentage;
  final num distance;
  final num fee;
  final int? orderId;

  ShowDelegateOnMapArgs({
    required this.kmPrice,
    required this.shippingPercentage,
    required this.distance,
    required this.fee,
    this.orderId,
  });
}

class ShowDelegateOnMapScreen extends StatefulWidget {
  static const String routeName = 'ShowDelegateOnMapScreen';

  const ShowDelegateOnMapScreen({super.key, required this.args});

  final ShowDelegateOnMapArgs args;

  @override
  State<ShowDelegateOnMapScreen> createState() =>
      _ShowDelegateOnMapScreenState();
}

class _ShowDelegateOnMapScreenState extends State<ShowDelegateOnMapScreen>
    with ValidationMixin {
  final TextEditingController _feeEC = TextEditingController();
  final FocusNode focusNode = FocusNode();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late RequestDelegateController requestDelegateController;
  Timer? _checkDelegateTimer;
  Timer? _fiveMinuteTimer;
  List<Delegates>? acceptedDelegates;

  @override
  void initState() {
    requestDelegateController = context.read<RequestDelegateController>();
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RequestDelegateController>().initialAcceptedDelegate();
      _fetchAcceptedDelegates();
      _feeEC.text = requestDelegateController.priceEC.text;
      _startCheckingAcceptedDelegate();
      _startFiveMinuteTimer();
    });
  }

  Future<void> _fetchAcceptedDelegates() async {
    try {
      await context
          .read<RequestDelegateController>()
          .getAcceptedDelegate(delegateOrderId: widget.args.orderId)
          .then((_) {
        if (mounted) {
          setState(() {
            acceptedDelegates =
                requestDelegateController.acceptedDelegate?.delegates ?? [];
          });
        }
        if (widget.args.orderId != null || widget.args.orderId != 0) {
          final order = requestDelegateController.acceptedDelegate!.order;
          requestDelegateController.setFromLat(
            order?.fromLat.toString() ?? '0.0',
          );
          requestDelegateController.setFromLan(
            order?.fromLng.toString() ?? '0.0',
          );
          requestDelegateController.setToLat(order?.toLat.toString() ?? '0.0');
          requestDelegateController.setToLan(order?.toLng.toString() ?? '0.0');
          _feeEC.text = requestDelegateController
              .acceptedDelegate!.order!.actualPrice
              .toString();
          requestDelegateController.calculateDeliveryPrice(
            kmPrice: widget.args.kmPrice,
          );
        }
      });
    } catch (e) {
      // Keep polling silently while delegates are being searched.
    }
  }

  void _startCheckingAcceptedDelegate() {
    _checkDelegateTimer =
        Timer.periodic(const Duration(seconds: 5), (timer) async {
      try {
        await _checkAcceptedDelegate();
        if (mounted) {
          setState(() {
            acceptedDelegates =
                requestDelegateController.acceptedDelegate?.delegates ?? [];
          });
        }
      } catch (e) {
        // Keep polling silently while delegates are being searched.
      }
    });
  }

  void _startFiveMinuteTimer() {
    _fiveMinuteTimer = Timer(const Duration(minutes: 5), () {
      CommonMethods.showError(message: 'noDelegateAvailable'.tr);
      _cancelTimersAndOrder();
      requestDelegateController.cancelOrder(
        orderId: widget.args.orderId!,
        onSuccess: () {
          requestDelegateController.setFee('0.0');
          NamedNavigatorImpl.push(
            clean: true,
            BottomNavigationBarScreen.routeName,
          );
        },
      );
    });
  }

  Future<void> _checkAcceptedDelegate() async {
    try {
      await requestDelegateController.getAcceptedDelegate(
        delegateOrderId: widget.args.orderId,
      );
      // Always mirror the server list. A driver's pre-selection decline only
      // removes that driver; the customer keeps searching for another one.
      // Do not turn an empty proposal list into an order cancellation.
      if (mounted) {
        setState(() {
          acceptedDelegates =
              requestDelegateController.acceptedDelegate?.delegates ?? [];
          final serverFare =
              requestDelegateController.acceptedDelegate?.order?.actualPrice;
          if (serverFare != null) {
            _feeEC.text = serverFare.toString();
          }
        });
      }
    } catch (e) {
      // Keep polling silently while delegates are being searched.
    }
  }

  void _resetFiveMinuteTimer() {
    _fiveMinuteTimer?.cancel();
    _fiveMinuteTimer = Timer(const Duration(minutes: 5), () {
      CommonMethods.showError(message: 'noDelegateAvailable'.tr);
      _cancelTimersAndOrder();
      requestDelegateController.cancelOrder(
        orderId: widget.args.orderId!,
        onSuccess: () {
          requestDelegateController.setFee('0.0');
          NamedNavigatorImpl.push(
            clean: true,
            BottomNavigationBarScreen.routeName,
          );
        },
      );
    });
  }

  void _resetCheckDelegateTimer() {
    _checkDelegateTimer?.cancel();
    _checkDelegateTimer =
        Timer.periodic(const Duration(seconds: 5), (timer) async {
      try {
        await _checkAcceptedDelegate();
        if (mounted) {
          setState(() {
            acceptedDelegates =
                requestDelegateController.acceptedDelegate?.delegates ?? [];
          });
        }
      } catch (e) {
        // Keep polling silently while delegates are being searched.
      }
    });
  }

  void _cancelTimersAndOrder() {
    _checkDelegateTimer?.cancel();
    _fiveMinuteTimer?.cancel();
    requestDelegateController.setFee('0.0');
  }

  int _minimumFare() {
    return int.tryParse(
          '${requestDelegateController.acceptedDelegate?.order?.actualPrice}',
        ) ??
        int.tryParse('${widget.args.fee}') ??
        0;
  }

  void _adjustFare(int delta) {
    final minimumFare = _minimumFare();
    final currentFare = int.tryParse(_feeEC.text) ?? minimumFare;
    final nextFare = currentFare + delta;
    if (nextFare < minimumFare) return;

    setState(() {
      _feeEC.text = nextFare.toString();
      _feeEC.selection = TextSelection.collapsed(offset: _feeEC.text.length);
    });
  }

  @override
  void dispose() {
    _checkDelegateTimer?.cancel();
    _fiveMinuteTimer?.cancel();
    _feeEC.dispose();
    focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = context.languageCode == 'ar';

    return PopScope(
      canPop: true,
      onPopInvoked: (didPop) {
        if (didPop) {
          _cancelTimersAndOrder();
          _checkDelegateTimer?.cancel();
          _fiveMinuteTimer?.cancel();
          requestDelegateController.setDistance(0.0);
          requestDelegateController.setFee('0.0');
        }
      },
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        body: Form(
          key: _formKey,
          child: DeferredPointerHandler(
            child: Stack(
              children: [
                if (!kIsWeb)
                  CustomGoogleMapsWidget(
                    showCircle: true,
                    addressLat: double.tryParse(
                          '${requestDelegateController.acceptedDelegate?.order?.fromLat}',
                        ) ??
                        double.tryParse('${requestDelegateController.fromLat}') ??
                        0.0,
                    addressLan: double.tryParse(
                          '${requestDelegateController.acceptedDelegate?.order?.fromLng}',
                        ) ??
                        double.tryParse('${requestDelegateController.fromLan}') ??
                        0.0,
                  )
                else
                  const Positioned.fill(
                    child: ColoredBox(color: Color(0xFFF3F4F6)),
                  ),
                Positioned.fill(
                  top: 20,
                  left: 0,
                  right: 0,
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        ...List.generate(
                          acceptedDelegates?.length ?? 0,
                          (index) => Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: DeferPointer(
                              child: DelegateOfferWidget(
                                onReject: () {
                                  setState(() {
                                    acceptedDelegates?.removeWhere(
                                      (i) => i.id == acceptedDelegates?[index].id,
                                    );
                                  });
                                },
                                order: requestDelegateController
                                    .acceptedDelegate?.order,
                                acceptedDelegateModel: acceptedDelegates?[index],
                                cancelReCall: _cancelTimersAndOrder,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  left: 0,
                  child: Directionality(
                    textDirection:
                        isArabic ? TextDirection.rtl : TextDirection.ltr,
                    child: Container(
                      width: double.infinity,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(28),
                          topRight: Radius.circular(28),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Color(0x24000000),
                            blurRadius: 24,
                            offset: Offset(0, -6),
                          ),
                        ],
                      ),
                      child: SafeArea(
                        top: false,
                        child: Padding(
                          padding: EdgeInsets.fromLTRB(
                            18,
                            10,
                            18,
                            14 + MediaQuery.of(context).viewInsets.bottom,
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 44,
                                height: 4,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFD7DADF),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                              ),
                              const SizedBox(height: 14),
                              Row(
                                children: [
                                  Container(
                                    width: 42,
                                    height: 42,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFFF3E8),
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.all(11),
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.6,
                                        color: AppColors.mainAppColor,
                                        backgroundColor:
                                            const Color(0xFFFFE1C7),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 11),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          isArabic
                                              ? 'جاري البحث عن مندوب'
                                              : 'Searching for a driver',
                                          style: const TextStyle(
                                            color: Color(0xFF171A1F),
                                            fontSize: 18,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                        const SizedBox(height: 3),
                                        Text(
                                          isArabic
                                              ? 'بنرسل طلبك لأقرب المندوبين المتاحين'
                                              : 'Sending your request to nearby available drivers',
                                          style: const TextStyle(
                                            color: Color(0xFF8A9099),
                                            fontSize: 11.5,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),
                              Container(
                                padding: const EdgeInsets.fromLTRB(
                                  12,
                                  10,
                                  12,
                                  10,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF9FAFB),
                                  borderRadius: BorderRadius.circular(18),
                                  border: Border.all(
                                    color: const Color(0xFFE8EBEF),
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    Text(
                                      isArabic
                                          ? 'الأجرة الحالية'
                                          : 'Current fare',
                                      style: const TextStyle(
                                        color: Color(0xFF777D86),
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        _FareStepButton(
                                          icon: Icons.remove_rounded,
                                          enabled: (int.tryParse(_feeEC.text) ??
                                                  _minimumFare()) >
                                              _minimumFare(),
                                          onTap: () => _adjustFare(-1),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: TextFormField(
                                            controller: _feeEC,
                                            focusNode: focusNode,
                                            textAlign: TextAlign.center,
                                            keyboardType: TextInputType.number,
                                            inputFormatters: [
                                              FilteringTextInputFormatter
                                                  .digitsOnly,
                                            ],
                                            validator: (v) =>
                                                validateFeeInShowDelegate(
                                              paymentType:
                                                  requestDelegateController
                                                      .acceptedDelegate
                                                      ?.order
                                                      ?.paymentType,
                                              actualPrice:
                                                  requestDelegateController
                                                          .acceptedDelegate
                                                          ?.order
                                                          ?.actualPrice ??
                                                      0,
                                              userBalance:
                                                  requestDelegateController
                                                          .acceptedDelegate
                                                          ?.order
                                                          ?.userBalance ??
                                                      0,
                                              value: _feeEC.text,
                                              distance:
                                                  requestDelegateController
                                                          .acceptedDelegate
                                                          ?.order
                                                          ?.expectedPrice ??
                                                      requestDelegateController
                                                          .distance ??
                                                      0,
                                              percentage:
                                                  widget.args.shippingPercentage,
                                              kmPrice: widget.args.kmPrice,
                                            ),
                                            style: TextStyle(
                                              color: AppColors.mainAppColor,
                                              fontSize: 23,
                                              fontWeight: FontWeight.w900,
                                            ),
                                            decoration: InputDecoration(
                                              suffixText: isArabic ? 'ج' : 'EGP',
                                              suffixStyle: TextStyle(
                                                color: AppColors.mainAppColor,
                                                fontSize: 13,
                                                fontWeight: FontWeight.w800,
                                              ),
                                              filled: true,
                                              fillColor: Colors.white,
                                              contentPadding:
                                                  const EdgeInsets.symmetric(
                                                horizontal: 12,
                                                vertical: 13,
                                              ),
                                              enabledBorder: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(14),
                                                borderSide: const BorderSide(
                                                  color: Color(0xFFE4E7EB),
                                                ),
                                              ),
                                              focusedBorder: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(14),
                                                borderSide: BorderSide(
                                                  color:
                                                      AppColors.mainAppColor,
                                                  width: 1.4,
                                                ),
                                              ),
                                              errorBorder: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(14),
                                                borderSide: const BorderSide(
                                                  color: Color(0xFFE34B4B),
                                                ),
                                              ),
                                              focusedErrorBorder:
                                                  OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(14),
                                                borderSide: const BorderSide(
                                                  color: Color(0xFFE34B4B),
                                                ),
                                              ),
                                            ),
                                            onChanged: (_) => setState(() {}),
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        _FareStepButton(
                                          icon: Icons.add_rounded,
                                          onTap: () => _adjustFare(1),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 9),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.bolt_rounded,
                                    size: 16,
                                    color: AppColors.mainAppColor,
                                  ),
                                  const SizedBox(width: 4),
                                  Flexible(
                                    child: Text(
                                      isArabic
                                          ? 'زيادة الأجرة قد تساعد على قبول الطلب أسرع'
                                          : 'A higher fare may help your request get accepted faster',
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        color: Color(0xFF777D86),
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 13),
                              Row(
                                children: [
                                  Expanded(
                                    flex: 2,
                                    child: SizedBox(
                                      height: 51,
                                      child: ElevatedButton(
                                        onPressed: () async {
                                          if (_formKey.currentState!.validate()) {
                                            await requestDelegateController
                                                .riseActualPrice(
                                              newPrice:
                                                  int.parse(_feeEC.text),
                                              onSuccess: () async {
                                                requestDelegateController
                                                    .setPriceEC(_feeEC.text);
                                                requestDelegateController
                                                    .setActualPrice(_feeEC.text);
                                                _resetFiveMinuteTimer();
                                                _resetCheckDelegateTimer();
                                                await _fetchAcceptedDelegates();
                                              },
                                            );
                                          }
                                        },
                                        style: ElevatedButton.styleFrom(
                                          elevation: 0,
                                          backgroundColor:
                                              AppColors.mainAppColor,
                                          foregroundColor: Colors.white,
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(16),
                                          ),
                                        ),
                                        child: Text(
                                          isArabic
                                              ? 'تحديث الأجرة'
                                              : 'Update fare',
                                          style: const TextStyle(
                                            fontSize: 15.5,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: SizedBox(
                                      height: 51,
                                      child: OutlinedButton(
                                        onPressed: () {
                                          _cancelTimersAndOrder();
                                          requestDelegateController.cancelOrder(
                                            orderId: widget.args.orderId!,
                                            onSuccess: () =>
                                                NamedNavigatorImpl.push(
                                              clean: true,
                                              BottomNavigationBarScreen
                                                  .routeName,
                                            ),
                                          );
                                        },
                                        style: OutlinedButton.styleFrom(
                                          backgroundColor: Colors.white,
                                          foregroundColor:
                                              const Color(0xFF626871),
                                          side: const BorderSide(
                                            color: Color(0xFFDDE1E6),
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(16),
                                          ),
                                        ),
                                        child: Text(
                                          isArabic
                                              ? 'إلغاء الطلب'
                                              : 'Cancel',
                                          maxLines: 1,
                                          style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
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
  }
}

class _FareStepButton extends StatelessWidget {
  const _FareStepButton({
    required this.icon,
    required this.onTap,
    this.enabled = true,
  });

  final IconData icon;
  final VoidCallback onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: enabled ? const Color(0xFFFFF0E2) : const Color(0xFFF0F1F3),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(14),
        child: SizedBox(
          width: 48,
          height: 48,
          child: Icon(
            icon,
            color: enabled
                ? AppColors.mainAppColor
                : const Color(0xFFB7BBC1),
            size: 24,
          ),
        ),
      ),
    );
  }
}
