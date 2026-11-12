import 'package:faskhaninja/helpers/theme/fasakhansta_brand.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../helpers/extensions/extensions.dart';
import '../../../../helpers/images/app_images.dart';
import '../../../../helpers/theme/app_colors.dart';
import '../../../../helpers/theme/app_text_style.dart';
import '../../../../helpers/translation/all_translation.dart';

class TrackingYourOrderWidget extends StatelessWidget {
  final String status;
  final String? orderDate;

  const TrackingYourOrderWidget({
    super.key,
    required this.status,
    this.orderDate,
  });

  @override
  Widget build(BuildContext context) {
    if (orderDate == null || orderDate!.isEmpty) return const SizedBox.shrink();

    DateTime createdAtDateTime;
    try {
      createdAtDateTime = DateTime.parse(orderDate!).toLocal();
    } catch (_) {
      return const SizedBox.shrink();
    }

    final createdAtPlus6Hours = createdAtDateTime.add(const Duration(hours: 6));
    if (DateTime.now().isAfter(createdAtPlus6Hours) && status == 'completed') {
      return const SizedBox.shrink();
    }

    final isAccepted =
        status != 'pending' && status != 'declined' && status != 'cancelled';
    final isPreparing = isAccepted;
    final isShipped = status == 'shipped' || status == 'completed';
    final isDelivered = status == 'completed';

    final activeStage = isDelivered
        ? 3
        : isShipped
        ? 2
        : isPreparing
        ? 1
        : 0;

    final stages = <_StatusStage>[
      _StatusStage('accepted'.tr, AppImages.checkIcon, activeStage >= 0),
      _StatusStage(
        'prepareTheOrder'.tr,
        AppImages.prepareIcon,
        activeStage >= 1,
      ),
      _StatusStage('inTheWay'.tr, AppImages.inTheWayIconDone, activeStage >= 2),
      _StatusStage(
        'delivered'.tr,
        AppImages.deliveredIconDone,
        activeStage >= 3,
      ),
    ];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      decoration: BoxDecoration(
        color: FasakhanstaBrand.surface,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: AppColors.greyColor.withValues(alpha: .10)),
        boxShadow: [
          BoxShadow(
            color: AppColors.greyColor.withValues(alpha: .10),
            blurRadius: 16,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('orderStatus'.tr, style: AppTextStyle.text16BS()),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: AppColors.mainAppColor.withValues(alpha: .09),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  '${activeStage + 1}/4',
                  style: AppTextStyle.text11BM().copyWith(
                    color: AppColors.mainAppColor,
                  ),
                ),
              ),
            ],
          ),
          10.sbH,
          _StageRouteMap(stages: stages, activeStage: activeStage),
          12.sbH,
          Container(
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
              color: AppColors.mainAppColor.withValues(alpha: .06),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: FasakhanstaBrand.surface,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.mainAppColor.withValues(alpha: .18),
                    ),
                  ),
                  child: Icon(
                    isDelivered
                        ? Icons.check_circle_rounded
                        : Icons.delivery_dining_rounded,
                    color: AppColors.mainAppColor,
                  ),
                ),
                10.sbW,
                Expanded(child: _statusMessage()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusMessage() {
    final String message;
    if (status == 'shipped') {
      message =
          'theRepresentativeHasReceivedTheOrderAndIsNowHeadingToYourDestination'
              .tr;
    } else if (status == 'declined') {
      message = 'orderDeclinedFromRestaurant'.tr;
    } else if (status == 'cancelled') {
      message = 'orderCanceled'.tr;
    } else if (status == 'completed') {
      message = 'yourOrderHasBeenDelivered'.tr;
    } else {
      message =
          'yourOrderHasBeenReceivedAndIsBeingPreparedPleaseWaitALittle'.tr;
    }
    return Text(
      message,
      style: AppTextStyle.text13RG(),
      maxLines: 3,
      overflow: TextOverflow.ellipsis,
    );
  }
}

class _StatusStage {
  final String title;
  final String icon;
  final bool done;

  const _StatusStage(this.title, this.icon, this.done);
}

class _StageRouteMap extends StatelessWidget {
  final List<_StatusStage> stages;
  final int activeStage;

  const _StageRouteMap({required this.stages, required this.activeStage});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 172,
      width: double.infinity,
      decoration: BoxDecoration(
        color: FasakhanstaBrand.surfaceRaised,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.greyColor.withValues(alpha: .10)),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: _RoutePainter(
                activeStage: activeStage,
                activeColor: AppColors.mainAppColor,
                inactiveColor: AppColors.greyColor.withValues(alpha: .18),
              ),
            ),
          ),
          Positioned(
            top: 10,
            right: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: FasakhanstaBrand.surface,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text('تتبع المراحل', style: AppTextStyle.text11BM()),
            ),
          ),
          Positioned.fill(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(4, 36, 4, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(stages.length, (index) {
                  final stage = stages[index];
                  final current = index == activeStage;
                  return SizedBox(
                    width: 68,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 220),
                          width: current ? 54 : 46,
                          height: current ? 54 : 46,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: stage.done
                                ? AppColors.mainAppColor
                                : FasakhanstaBrand.surface,
                            border: Border.all(
                              color: stage.done
                                  ? AppColors.mainAppColor
                                  : AppColors.greyColor.withValues(alpha: .24),
                              width: current ? 3 : 1.5,
                            ),
                            boxShadow: current
                                ? [
                                    BoxShadow(
                                      color: AppColors.mainAppColor.withValues(
                                        alpha: .22,
                                      ),
                                      blurRadius: 14,
                                      spreadRadius: 1,
                                    ),
                                  ]
                                : null,
                          ),
                          padding: const EdgeInsets.all(10),
                          child: SvgPicture.asset(
                            stage.icon,
                            colorFilter: ColorFilter.mode(
                              stage.done
                                  ? AppColors.whiteColor
                                  : AppColors.greyColor,
                              BlendMode.srcIn,
                            ),
                          ),
                        ),
                        7.sbH,
                        Text(
                          stage.title,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: current
                              ? AppTextStyle.text11BS()
                              : AppTextStyle.text10RG(),
                        ),
                      ],
                    ),
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RoutePainter extends CustomPainter {
  final int activeStage;
  final Color activeColor;
  final Color inactiveColor;

  const _RoutePainter({
    required this.activeStage,
    required this.activeColor,
    required this.inactiveColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final points = <Offset>[
      Offset(size.width * .14, size.height * .58),
      Offset(size.width * .38, size.height * .40),
      Offset(size.width * .62, size.height * .62),
      Offset(size.width * .86, size.height * .44),
    ];

    final inactivePaint = Paint()
      ..color = inactiveColor
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final activePaint = Paint()
      ..color = activeColor
      ..strokeWidth = 5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    for (var i = 0; i < points.length - 1; i++) {
      canvas.drawLine(points[i], points[i + 1], inactivePaint);
      if (i < activeStage) {
        canvas.drawLine(points[i], points[i + 1], activePaint);
      }
    }

    final marker = points[activeStage.clamp(0, points.length - 1)];
    canvas.drawCircle(marker, 5, Paint()..color = activeColor);
  }

  @override
  bool shouldRepaint(covariant _RoutePainter oldDelegate) {
    return oldDelegate.activeStage != activeStage;
  }
}
