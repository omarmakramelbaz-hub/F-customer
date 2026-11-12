import 'package:faskhaninja/helpers/theme/fasakhansta_brand.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../helpers/extensions/extensions.dart';
import '../../../../helpers/routes/app_routers_import.dart';
import '../../../../helpers/theme/app_colors.dart';
import '../../../../helpers/theme/app_text_style.dart';
import '../../../../helpers/translation/all_translation.dart';
import '../../../../helpers/utils/common_methods.dart';
import '../../../../helpers/utils/date_methods.dart';
import '../../../custom_widgets/custom_image/custom_network_image.dart';
import '../../../custom_widgets/state_conditional_builder.dart';
import '../controller/orders_controller.dart';
import '../model/orders_model.dart';
import '../screen/request_again_screen.dart';
import '../screen/tracking_your_order_screen.dart';

class InPreparationWidget extends StatelessWidget {
  final OrdersModel orders;
  const InPreparationWidget({super.key, required this.orders});

  @override
  Widget build(BuildContext context) {
    final status = orders.status;
    final color = _statusColor(status);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: FasakhanstaBrand.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.greyColor.withValues(alpha: .12)),
        boxShadow: [
          BoxShadow(
            color: AppColors.greyColor.withValues(alpha: .12),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: () => _openOrder(context),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Icon(
                          Icons.receipt_long_rounded,
                          size: 18,
                          color: AppColors.mainAppColor,
                        ),
                        7.sbW,
                        Text('requestCode'.tr, style: AppTextStyle.text13RG()),
                        5.sbW,
                        Flexible(
                          child: Text(
                            orders.orderNo ?? '',
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyle.text13BS(),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 11,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: .10),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      getStatusTitle(
                        status,
                        orders.scheduleDate,
                        orders.delegateFromOut,
                      ),
                      style: AppTextStyle.text12BS().copyWith(color: color),
                    ),
                  ),
                ],
              ),
              12.sbH,
              Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: CustomNetworkImage(
                      radius: 16,
                      imageUrl: orders.resturantLogo ?? '',
                      width: 78,
                      height: 78,
                      fit: BoxFit.cover,
                    ),
                  ),
                  12.sbW,
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          orders.resturantName ?? '',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyle.text16BS(),
                        ),
                        7.sbH,
                        Row(
                          children: [
                            Icon(
                              Icons.calendar_today_rounded,
                              size: 14,
                              color: AppColors.greyColor,
                            ),
                            5.sbW,
                            Flexible(
                              child: Text(
                                DateMethods.formatToDate(
                                  orders.scheduleDate ?? orders.createdAt ?? '',
                                ),
                                overflow: TextOverflow.ellipsis,
                                style: AppTextStyle.text12RG(),
                              ),
                            ),
                          ],
                        ),
                        7.sbH,
                        Text(
                          'pound'.tr.replaceAll(
                                '{}',
                                '${orders.grandTotal ?? 0}',
                              ),
                          style: AppTextStyle.text16BS().copyWith(
                            color: AppColors.mainAppColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_left_rounded,
                    color: AppColors.greyColor,
                    size: 24,
                  ),
                ],
              ),
              14.sbH,
              _Progress(status: status),
              13.sbH,
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _statusMessage(status),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyle.text12RG(),
                    ),
                  ),
                  _action(context),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _action(BuildContext context) {
    return MultiStateConditionalBuilder(
      conditions: [
        ConditionBuilder(
          when: orders.status == 'shipped',
          builder: (_) => _ActionButton(
            text: 'trackingYourOrder'.tr,
            icon: Icons.location_searching_rounded,
            onTap: () => _openTracking(context),
          ),
        ),
        ConditionBuilder(
          when: orders.status == 'completed',
          builder: (_) => _ActionButton(
            text: 'requestAgain'.tr,
            icon: Icons.replay_rounded,
            onTap: () => NamedNavigatorImpl.push(
              RequestAgainScreen.routeName,
              arguments: RequestAgainArgs(id: orders.id ?? 0),
            ),
          ),
        ),
        ConditionBuilder(
          when: orders.status == 'pending' ||
              (orders.status == 'another_delegate' &&
                  orders.paymentType == 'cash'),
          builder: (_) => _ActionButton(
            text: 'cancelOrder'.tr,
            icon: Icons.close_rounded,
            onTap: () => CommonMethods.showChooseDialog(
              context,
              message: 'didYouWantToCancelThisOrder'.tr,
              onPressed: () => context.read<OrdersController>().cancelOrder(
                    orderId: orders.id!,
                    onSuccess: () => NamedNavigatorImpl.pop(),
                  ),
            ),
          ),
        ),
      ],
      fallback: (_) => const SizedBox.shrink(),
    );
  }

  void _openOrder(BuildContext context) {
    if ((orders.id ?? 0) <= 0) return;
    _openTracking(context);
  }

  void _openTracking(BuildContext context) => NamedNavigatorImpl.push(
        TrackingYourOrderScreen.routeName,
        arguments: TrackingYourOrderArgs(id: orders.id ?? 0),
      );

  Color _statusColor(String? status) {
    if (status == 'completed') return Colors.green;
    if (status == 'cancelled' || status == 'declined') return Colors.red;
    return AppColors.mainAppColor;
  }

  String _statusMessage(String? status) {
    if (status == 'completed') return 'yourOrderHasBeenDelivered'.tr;
    if (status == 'shipped') {
      return 'theRepresentativeHasReceivedTheOrderAndIsNowHeadingToYourDestination'
          .tr;
    }
    if (status == 'cancelled') return 'orderCanceled'.tr;
    if (status == 'declined') return 'orderDeclinedFromRestaurant'.tr;
    return 'yourOrderHasBeenReceivedAndIsBeingPreparedPleaseWaitALittle'.tr;
  }

  String getStatusTitle(
    String? status,
    String? scheduleDate,
    String? delegateFromOut,
  ) {
    switch (status) {
      case 'completed':
        return 'delivered'.tr;
      case 'cancelled':
        return 'canceled'.tr;
      case 'declined':
        return 'rejectOrder'.tr;
      case 'pending':
      case 'another_delegate':
        return 'pending'.tr;
      case 'accepted':
        return 'inPreparation'.tr;
      case 'shipped':
      case 'new_order':
        return 'delegateInRoute'.tr;
      default:
        if (scheduleDate != null && status != 'completed') {
          return 'scheduledOrder'.tr;
        }
        if (delegateFromOut == 'in_resturant') return 'delivered'.tr;
        return '';
    }
  }
}

class _Progress extends StatelessWidget {
  final String? status;
  const _Progress({required this.status});

  @override
  Widget build(BuildContext context) {
    final step = switch (status) {
      'pending' => 0,
      'accepted' || 'new_order' => 1,
      'shipped' => 2,
      'completed' => 3,
      _ => 0,
    };
    final failed = status == 'cancelled' || status == 'declined';
    final labels = [
      'accepted'.tr,
      'prepareTheOrder'.tr,
      'inTheWay'.tr,
      'delivered'.tr,
    ];
    return Row(
      children: List.generate(7, (i) {
        if (i.isOdd) {
          return Expanded(
            child: Container(
              height: 3,
              color: (!failed && i ~/ 2 < step)
                  ? AppColors.mainAppColor
                  : AppColors.greyColor.withValues(alpha: .15),
            ),
          );
        }
        final n = i ~/ 2;
        final active = !failed && n <= step;
        return Column(
          children: [
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: active
                    ? AppColors.mainAppColor
                    : AppColors.greyColor.withValues(alpha: .10),
                shape: BoxShape.circle,
              ),
              child: active
                  ? const Icon(
                      Icons.check,
                      size: 14,
                      color: FasakhanstaBrand.onOrange,
                    )
                  : null,
            ),
            const SizedBox(height: 4),
            SizedBox(
              width: 48,
              child: Text(
                labels[n],
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: AppTextStyle.text9RG(),
              ),
            ),
          ],
        );
      }),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String text;
  final IconData icon;
  final VoidCallback onTap;
  const _ActionButton({
    required this.text,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.mainAppColor.withValues(alpha: .08),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 15, color: AppColors.mainAppColor),
              const SizedBox(width: 5),
              Text(
                text,
                style: AppTextStyle.text11BS().copyWith(
                  color: AppColors.mainAppColor,
                ),
              ),
            ],
          ),
        ),
      );
}
