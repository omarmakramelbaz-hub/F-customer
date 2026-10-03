import 'dart:developer';

import 'package:flutter/material.dart';
// import 'package:pay/pay.dart';
import 'package:provider/provider.dart';

import '../../../../helpers/routes/app_routers_import.dart';
import '../../../../helpers/translation/all_translation.dart';
import '../../../../helpers/utils/common_methods.dart';
import '../../../../helpers/utils/date_methods.dart';
import '../../../../helpers/utils/restaurant_hours.dart';
import '../../../custom_widgets/buttons/custom_button.dart';
import '../../../custom_widgets/custom_payment_web_view/custom_payment_web_view.dart';
import '../../address/controller/address_controller.dart';
import '../controller/cart_controller.dart';
import '../screen/order_otp_screen.dart';
import '../screen/your_order_successfully_completed_screen.dart';

class ExecuteOrderButton extends StatelessWidget {
  const ExecuteOrderButton({
    super.key,
    required this.cartController,
    required this.selectedDate,
    required this.selectedTime,
    required this.selectedDateZone,
    required this.userAddressId,
    required this.addressController,
    required this.deliveryPrice,
  });
  final CartController cartController;
  final AddressController addressController;
  final DateTime? selectedDate;
  final DateTime? selectedTime;
  final DateTime? selectedDateZone;
  final int userAddressId;
  final dynamic deliveryPrice;

  @override
  Widget build(BuildContext context) {
    // if (cartController.selectedPayment == 'apple_pay') {
    //   final totalPrice = cartController.totalPrice;
    //   final num serviceFees = (((cartController.cart?.resturant?.serviceFees ?? 0) * (totalPrice)) / 100);
    //   final num addedPrice = (((cartController.cart?.resturant?.tax ?? 0) * (totalPrice)) / 100);
    //   final num kmPrice = cartController.cart?.resturant?.resturantKmPrice != 0
    //       ? (deliveryPrice is num ? deliveryPrice : double.tryParse(deliveryPrice.toString()) ?? 0)
    //       : 0;
    //   final num grandTotal = (serviceFees + addedPrice + totalPrice + kmPrice);

    //   return Padding(
    //     padding: const EdgeInsets.symmetric(horizontal: 20),
    //     child: ApplePayButton(
    //       paymentConfiguration: PaymentConfiguration.fromJsonString('''{
    //             "provider": "apple_pay",
    //             "data": {
    //               "merchantIdentifier": "merchant.com.faskhaninja.clients",
    //               "displayName": "Faskha Ninja",
    //               "merchantCapabilities": ["3DS", "debit", "credit"],
    //               "supportedNetworks": ["amex", "visa", "masterCard"],
    //               "countryCode": "EG",
    //               "currencyCode": "EGP",
    //               "requiredBillingContactFields": ["email", "name", "phoneNumber", "postalAddress"],
    //               "requiredShippingContactFields": []
    //             }
    //           }'''),
    //       paymentItems: [
    //         PaymentItem(
    //           label: 'Total',
    //           amount: grandTotal.toStringAsFixed(2),
    //           status: PaymentItemStatus.final_price,
    //         )
    //       ],
    //       style: ApplePayButtonStyle.black,
    //       width: double.infinity,
    //       height: 50,
    //       type: ApplePayButtonType.buy,
    //       onPaymentResult: (result) {
    //         PrintLog.i(result);

    //         // Extract user info for billing
    //         final authController = context.read<AuthController>();
    //         final profile = authController.profile;
    //         final nameParts = (profile?.name ?? '').split(' ');
    //         final firstName = nameParts.isNotEmpty ? nameParts.first : '';
    //         final lastName = nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '';

    //         cartController.processApplePayment(
    //           applePayResult: result,
    //           amount: grandTotal.toDouble(),
    //           firstName: firstName,
    //           lastName: lastName,
    //           email: profile?.email ?? '',
    //           phoneNumber: profile?.mobile ?? '',
    //           onSuccess: () {
    //             NamedNavigatorImpl.push(YourOrderSuccessfullyCompletedScreen.routeName);
    //             context.read<CartController>().getCart();
    //           },
    //           onError: (error) => CommonMethods.showError(message: error),
    //         );
    //       },
    //       loadingIndicator: const Center(child: CircularProgressIndicator()),
    //     ),
    //   );
    // }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: CustomButton(
        onPressed: () {
          final restaurantStatus =
              cartController.cart?.resturant?.resturantStatus;
          if (restaurantStatus != 'opened') {
            CommonMethods.showError(
              message: restaurantOrderingUnavailableLabel(
                context,
                status: restaurantStatus,
                openAt: cartController.cart?.resturant?.resturantOpenAt,
              ),
            );
            return;
          }

          log(selectedDateZone.toString());
          if (cartController.isSwitchedscheduleDate == true && selectedDate == null && selectedTime == null) {
            CommonMethods.showError(message: 'chooseReDeliveryOrder'.tr);
          } else if (cartController.isSwitchedscheduleDate == true && selectedDate != null && selectedTime == null) {
            CommonMethods.showError(message: 'chooseReDeliveryOrder'.tr);
          } else if (cartController.isSwitchedscheduleDate == true && selectedDate == null && selectedTime != null) {
            CommonMethods.showError(message: 'chooseReDeliveryOrder'.tr);
          } else if (cartController.cart?.resturant?.zoneType != null && selectedDateZone == null) {
            CommonMethods.showError(message: 'doYouWantToScheduleYourOrder'.tr);
          } else if (cartController.cart?.resturant?.resturantAreas?.any(
                (e) =>
                    e.areaId == addressController.addressDetails?.cityId &&
                    e.expectedDelivery != '0' &&
                    e.type == 'day' &&
                    selectedDateZone == null,
              ) ==
              true) {
            CommonMethods.showError(message: 'chooseDeliveryDate'.tr);
          } else {
            context.read<CartController>().orderPayment(
                  notes: cartController.notes,
                  userAddressId: userAddressId,
                  paymentType: cartController.selectedPayment,
                  deliveryPrice: deliveryPrice.toString(),
                  orderType: cartController.isSwitchedscheduleDate == true
                      ? 'schedule'
                      : selectedDateZone != null
                          ? 'another_zone'
                          : 'default',
                  scheduleDate: cartController.isSwitchedscheduleDate == true
                      ? '${DateMethods.formatToDate(selectedTime.toString())} ${DateMethods.formatToTime(selectedDate.toString())}'
                      : selectedDateZone != null
                          ? '${DateMethods.formatToDate(selectedDateZone.toString())} ${DateMethods.formatToTime(selectedDate.toString())}'
                          : '',
                  onSuccess: (orderId) {
                    cartController.setIsSwitchedscheduleDate(false);
                    if (cartController.selectedPayment == 'cash' || cartController.selectedPayment == 'wallet') {
                      NamedNavigatorImpl.push(
                        YourOrderSuccessfullyCompletedScreen.routeName,
                        arguments: YourOrderSuccessfullyCompletedArgs(id: orderId),
                      );

                      context.read<CartController>().getCart();
                    }
                  },
                  onHadeLink: (link, orderId) {
                    if (cartController.selectedPayment != 'cash') {
                      NamedNavigatorImpl.push(
                        CustomPaymentWebViewScreen.routeName,
                        arguments: PaymentArgs(
                          url: link,
                          onFailed: () {
                            CommonMethods.showError(message: 'paymentFailed'.tr);
                          },
                          onSuccess: () {
                            NamedNavigatorImpl.push(
                              YourOrderSuccessfullyCompletedScreen.routeName,
                              arguments: YourOrderSuccessfullyCompletedArgs(id: orderId),
                            );
                            context.read<CartController>().getCart();
                          },
                        ),
                      );

                      // UrlLauncherMethods.launchInBrowser(link);
                      // NavigatorMethods.pushNamed(context,
                      //     YourOrderSuccessfullyCompletedScreen.routeName,
                      //     arguments:
                      //         YourOrderSuccessfullyCompletedArgs(id: orderId));
                      // context.read<CartController>().getCart();
                    }
                  },
                  onHasOTP: () {
                    NamedNavigatorImpl.push(OrderOTPScreen.routeName);
                  },
                );
          }
        },
        text: 'executeTheOrder'.tr,
      ),
    );
  }
}
