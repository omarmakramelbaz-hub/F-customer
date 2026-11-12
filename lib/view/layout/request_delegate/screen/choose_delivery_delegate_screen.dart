import 'package:faskhaninja/helpers/theme/fasakhansta_brand.dart';

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../helpers/extensions/extensions.dart';
import '../../../../helpers/routes/app_routers_import.dart';
import '../../../../helpers/theme/app_colors.dart';
import '../../../../helpers/theme/app_text_style.dart';
import '../../../../helpers/translation/all_translation.dart';
import '../../../custom_widgets/buttons/custom_button.dart';
import '../../bottom_navigation/bottom_navigation_bar_screen.dart';
import '../controller/request_delegate_controller.dart';
import '../model/accepted_delegate_model.dart';
import '../widget/delegate_offer_widget.dart';

class ChooseDeliveryDelegateScreen extends StatefulWidget {
  static const routeName = 'ChooseDeliveryDelegateScreen';
  const ChooseDeliveryDelegateScreen({super.key});

  @override
  State<ChooseDeliveryDelegateScreen> createState() =>
      _ChooseDeliveryDelegateScreenState();
}

class _ChooseDeliveryDelegateScreenState
    extends State<ChooseDeliveryDelegateScreen> {
  late Timer _pollingTimer;
  late Timer _navigationTimer;
  List<Delegates>? acceptedDelegates;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final requestDelegateController = Provider.of<RequestDelegateController>(
        context,
        listen: false,
      );
      requestDelegateController.initialAcceptedDelegate();
      requestDelegateController.getAcceptedDelegate().then((value) {
        setState(() {
          acceptedDelegates =
              requestDelegateController.acceptedDelegate?.delegates ?? [];
        });
      });

      _startPolling(requestDelegateController);

      _navigationTimer = Timer(const Duration(minutes: 5), () {
        requestDelegateController.cancelOrder(
          orderId: requestDelegateController.orderId!,
          onSuccess: () {
            NamedNavigatorImpl.push(
              clean: true,
              BottomNavigationBarScreen.routeName,
            );
          },
        );
      });
    });
  }

  void _startPolling(RequestDelegateController controller) {
    _pollingTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      controller.getAcceptedDelegate().then((value) {
        final newDelegates = controller.acceptedDelegate?.delegates;
        if (newDelegates != null && newDelegates.isNotEmpty) {
          final newDelegateIds = newDelegates.map((e) => e.id).toSet();
          final existingDelegateIds =
              acceptedDelegates?.map((e) => e.id).toSet() ?? {};

          if (!newDelegateIds.containsAll(existingDelegateIds)) {
            setState(() {
              acceptedDelegates = newDelegates;
            });
          }
        }
      });
    });
  }

  @override
  void dispose() {
    _pollingTimer.cancel();
    _navigationTimer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      onPopInvoked: (didPop) {
        if (didPop) {
          _pollingTimer.cancel();
          _navigationTimer.cancel();
        }
      },
      child: Scaffold(
        backgroundColor: Colors.transparent,
        extendBody: true,
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Consumer<RequestDelegateController>(
              builder: (context, requestDelegateController, _) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(height: context.height * 0.15),
                    Center(
                      child: Text(
                        'finalProposalsFromDrivers'.tr,
                        style: AppTextStyle.text18BS().copyWith(
                          color: FasakhanstaBrand.text,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    20.sbH,
                    Column(
                      children: [
                        ...List.generate(
                          acceptedDelegates?.length ?? 0,
                          (index) => DelegateOfferWidget(
                            acceptedDelegateModel: acceptedDelegates?[index],
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ),
        ),
        bottomNavigationBar: Consumer<RequestDelegateController>(
          builder: (context, requestDelegateController, _) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: CustomButton(
                text: 'cancelOrder'.tr,
                onPressed: () {
                  requestDelegateController.cancelOrder(
                    orderId: requestDelegateController.orderId!,
                    onSuccess: () {
                      _pollingTimer.cancel();
                      _navigationTimer.cancel();
                      NamedNavigatorImpl.push(
                        clean: true,
                        BottomNavigationBarScreen.routeName,
                      );
                    },
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }
}
