import 'package:faskhaninja/helpers/theme/fasakhansta_brand.dart';

import 'dart:convert';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pusher_channels_flutter/pusher_channels_flutter.dart';

import '../../../../helpers/pusher_service/pusher_controller.dart';
import '../../../../helpers/theme/app_colors.dart';
import '../../../../helpers/translation/all_translation.dart';
import '../../../../helpers/utils/common_methods.dart';
import '../../../custom_widgets/api_response_widget/api_response_widget.dart';
import '../../../custom_widgets/page_container/page_container.dart';
import '../../my_account/account_app_bar/account_app_bar.dart';
import '../controller/request_delegate_controller.dart';
import '../model/request_delegate_order_model.dart';
import '../widget/delegate_order_widget.dart';

class DelegateOrdersScreen extends StatefulWidget {
  static const routeName = 'DelegateOrdersScreen';
  const DelegateOrdersScreen({super.key});

  @override
  State<DelegateOrdersScreen> createState() => _DelegateOrdersScreenState();
}

class _DelegateOrdersScreenState extends State<DelegateOrdersScreen> {
  late PusherController _pusherController; // Saved reference
  @override
  initState() {
    super.initState();
    _pusherController = context.read<PusherController>();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<RequestDelegateController>(
        context,
        listen: false,
      ).initialDelegateOrders();
      Provider.of<RequestDelegateController>(
        context,
        listen: false,
      ).getDelegateOrders();
    });
    _pusherController.addEventListener(
      'shipping.updated',
      _handleShippingUpdated,
    );
  }

  void _handleShippingUpdated(PusherEvent event) {
    try {
      final decodedData = json.decode(event.data) as Map<String, dynamic>;
      final orderData = decodedData['order_id'];
      var jsonData = jsonDecode(event.data) as Map<String, dynamic>;
      if (mounted) {
        var status = jsonData['order_id']['status']?.toString();
        var orderNo = jsonData['order_id']['order_no']?.toString();
        log('*************************************************************');
        log(jsonData.toString());
        if (status != null && status != 'pending') {
          CommonMethods.showToast(
            message: '${'thereIsANewOrderWithStatus'.tr} $orderNo',
          );
        }
      }
      if (mounted) {
        final orderModel = RequestDelegateOrderModel.fromJson(
          orderData as Map<String, dynamic>,
        );
        context.read<RequestDelegateController>().updateShippingOrder(
              orderModel,
            );
      }
    } catch (e, stackTrace) {
      log('Error handling Pusher event: $e');
      log('Stack trace: $stackTrace');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<RequestDelegateController>(
      builder: (context, requestDelegateController, _) {
        return Scaffold(
          extendBody: true,
          body: PageContainer(
            bottom: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 24),
                CustomAccountAppBar(title: 'delegatesOrders'.tr),
                const SizedBox(height: 22),
                Expanded(
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: FasakhanstaBrand.surface,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(34),
                        topRight: Radius.circular(34),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.greyColor.withValues(alpha: 0.2),
                          offset: const Offset(0, -3),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: RefreshIndicator(
                      onRefresh: () async {
                        await requestDelegateController.getDelegateOrders();
                      },
                      child: Center(
                        child: SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          child: ApiResponseWidget(
                            apiResponse: requestDelegateController
                                .delegateOrdersApiResponse,
                            onReload: () =>
                                requestDelegateController.getDelegateOrders(),
                            isEmpty: requestDelegateController
                                .delegateOrders.isEmpty,
                            child: Column(
                              children: [
                                // const SizedBox(
                                //   height: 25,
                                // ),
                                ...List.generate(
                                  requestDelegateController
                                      .delegateOrders.length,
                                  (index) => DelegateOrderWidget(
                                    requestDelegateOrderModel:
                                        requestDelegateController
                                            .delegateOrders[index],
                                  ),
                                ),
                                const SizedBox(height: 50),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
