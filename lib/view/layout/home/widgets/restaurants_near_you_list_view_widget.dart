import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';

import '../../../../helpers/hive/hive_methods.dart';
import '../../../../helpers/routes/app_routers_import.dart';
import '../../../../helpers/theme/app_colors.dart';
import '../../../../helpers/theme/app_text_style.dart';
import '../../../../helpers/translation/all_translation.dart';
import '../../../../helpers/utils/restaurant_hours.dart';
import '../../../custom_widgets/api_response_widget/api_response_widget.dart';
import '../../../custom_widgets/custom_image/custom_network_image.dart';
import '../../../custom_widgets/custom_loading/custom_shimmer.dart';
import '../../restaurants/screen/restaurant_details_screen.dart';
import '../controller/home_controller.dart';
import '../model/restaurants_near_you_home_model.dart';

class RestaurantsNearYouListViewWidget extends StatelessWidget {
  final List<RestaurantsNearYouHomeModel> restaurantsNearYou;

  const RestaurantsNearYouListViewWidget({super.key, required this.restaurantsNearYou});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final cardWidth = ((screenWidth - 38) / 2).clamp(164.0, 184.0);
    const cardHeight = 188.0;

    return ApiResponseWidget(
      apiResponse: context.read<HomeController>().restaurantsNearYouApiResponse,
      onReload: () => context.read<HomeController>().getRestaurantsNearYou(
            lat: HiveMethods.getLat(),
            lng: HiveMethods.getLan(),
          ),
      isEmpty: restaurantsNearYou.isEmpty,
      loadingWidget: CustomShimmer(
        height: cardHeight,
        width: double.infinity,
        fillColor: AppColors.greyColor.withValues(alpha: .05),
        shimmerColor: AppColors.mainAppColor,
      ),
      child: SizedBox(
        height: cardHeight,
        child: ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          scrollDirection: Axis.horizontal,
          itemCount: restaurantsNearYou.length,
          separatorBuilder: (_, __) => const SizedBox(width: 10),
          itemBuilder: (context, index) {
            final model = restaurantsNearYou[index];
            final canOpen = model.underContract != 'yes' &&
                model.status != 'busy';

            return _NearbyRestaurantCard(
              model: model,
              width: cardWidth,
              canOpen: canOpen,
            );
          },
        ),
      ),
    );
  }
}

class _NearbyRestaurantCard extends StatelessWidget {
  final RestaurantsNearYouHomeModel model;
  final double width;
  final bool canOpen;

  const _NearbyRestaurantCard({
    required this.model,
    required this.width,
    required this.canOpen,
  });

  @override
  Widget build(BuildContext context) {
    const orange = Color(0xFFFF6B00);
    const teal = Color(0xFF0A6F6A);
    final radius = BorderRadius.circular(18);
    final subtitle = (model.address ?? '').trim().isNotEmpty
        ? model.address!.trim()
        : (model.cityName ?? model.cityname ?? '').trim();
    final actualDistanceKm = _calculateDistanceKm(model);
    final deliveryFee = _calculateDeliveryFee(model, actualDistanceKm);
    final deliveryTime = (model.deliveryTime ?? '').trim().isEmpty
        ? '-'
        : model.deliveryTime!.trim();

    return SizedBox(
      width: width,
      height: 188,
      child: Material(
        color: AppColors.whiteColor,
        borderRadius: radius,
        child: InkWell(
          borderRadius: radius,
          onTap: canOpen
              ? () => NamedNavigatorImpl.push(
                    RestaurantDetailsScreen.routeName,
                    arguments: RestaurantDetailsArgs(id: model.id ?? 0),
                  )
              : null,
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.whiteColor,
              borderRadius: radius,
              border: Border.all(color: const Color(0xFFF0F0F0)),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x14000000),
                  blurRadius: 16,
                  offset: Offset(0, 6),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  height: 88,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      CustomNetworkImage(
                        imageUrl: model.bgImage ?? model.logo ?? '',
                        height: 88,
                        width: width,
                        radius: 0,
                        fit: BoxFit.cover,
                      ),
                      const DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Color(0x12000000), Color(0x4D000000)],
                          ),
                        ),
                      ),
                      Positioned(
                        top: 8,
                        left: 8,
                        child: _DeliveryBadge(text: model.deliveryTime ?? 'سريع'),
                      ),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: .94),
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x18000000),
                                blurRadius: 5,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.location_on_rounded,
                            color: orange,
                            size: 18,
                          ),
                        ),
                      ),
                      Positioned(
                        right: 9,
                        bottom: 7,
                        child: _AvailabilityPill(model: model),
                      ),
                      IsRestaurantBusyWidget(model: model),
                    ],
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(9, 8, 9, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          textDirection: TextDirection.rtl,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Container(
                              width: 27,
                              height: 27,
                              decoration: BoxDecoration(
                                color: orange.withValues(alpha: .09),
                                borderRadius: BorderRadius.circular(9),
                              ),
                              child: const Icon(
                                Icons.storefront_rounded,
                                size: 16,
                                color: orange,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                model.name ?? '',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.right,
                                style: AppTextStyle.text13BS(),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          subtitle.isEmpty
                              ? 'مأكولات بحرية طازجة بأعلى جودة'
                              : subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.right,
                          style: AppTextStyle.text10RG(
                            color: AppColors.lightTextColor,
                          ),
                        ),
                        const SizedBox(height: 7),
                        Container(height: 1, color: const Color(0xFFF1F1F1)),
                        const Spacer(),
                        Row(
                          textDirection: TextDirection.rtl,
                          children: [
                            Expanded(
                              child: _MetricTile(
                                icon: Icons.schedule_rounded,
                                iconColor: orange,
                                label: 'وقت التوصيل',
                                value: deliveryTime,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: _MetricTile(
                                icon: Icons.location_on_outlined,
                                iconColor: orange,
                                label: 'المسافة',
                                value: _formatKm(actualDistanceKm),
                              ),
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: _MetricTile(
                                icon: Icons.delivery_dining_rounded,
                                iconColor: teal,
                                label: 'التوصيل',
                                value: _formatMoney(deliveryFee),
                              ),
                            ),
                          ],
                        ),
                      ],
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

class _MetricTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;

  const _MetricTile({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 42,
      padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8F2),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 12, color: iconColor),
              const SizedBox(width: 2),
              Flexible(
                child: Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyle.text10BW(color: AppColors.blackColor),
                ),
              ),
            ],
          ),
          const SizedBox(height: 1),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyle.text9RG(color: AppColors.greyColor),
          ),
        ],
      ),
    );
  }
}

class _DeliveryBadge extends StatelessWidget {
  final String text;

  const _DeliveryBadge({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .96),
        borderRadius: BorderRadius.circular(10),
        boxShadow: const [
          BoxShadow(
            color: Color(0x18000000),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.schedule_rounded,
            size: 12,
            color: Color(0xFFFF6B00),
          ),
          const SizedBox(width: 3),
          Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyle.text10BW(color: AppColors.blackColor),
          ),
        ],
      ),
    );
  }
}

class _AvailabilityPill extends StatelessWidget {
  final RestaurantsNearYouHomeModel model;

  const _AvailabilityPill({required this.model});

  @override
  Widget build(BuildContext context) {
    final isOpen = model.status == 'opened' && model.underContract != 'yes';
    final label = model.underContract == 'yes'
        ? 'underContract'.tr
        : model.status == 'busy'
            ? 'busy'.tr
            : model.status == 'closed'
                ? restaurantClosedLabel(context, model.openAt)
                : 'مفتوح';

    return Container(
      constraints: const BoxConstraints(maxWidth: 145),
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        color: isOpen ? const Color(0xFF0A6F6A) : const Color(0xFF6D6D6D),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        textAlign: TextAlign.center,
        style: AppTextStyle.text9BW(),
      ),
    );
  }
}

String _formatMoney(dynamic value) {
  if (value == null) return 'حسب المنطقة';
  if (value is num) return '${value.toStringAsFixed(0)}ج';
  final parsed = num.tryParse(value.toString());
  return parsed == null ? 'حسب المنطقة' : '${parsed.toStringAsFixed(0)}ج';
}

double? _calculateDeliveryFee(
  RestaurantsNearYouHomeModel model,
  double? distanceKm,
) {
  if (distanceKm == null || !distanceKm.isFinite || distanceKm < 0) {
    return null;
  }

  num? configuredPrice;
  if (distanceKm <= 1) {
    configuredPrice = model.default_0_1;
  } else if (distanceKm <= 2) {
    configuredPrice = model.default_1_2;
  } else if (distanceKm <= 3) {
    configuredPrice = model.default_2_3;
  } else {
    final perKmPrice = model.kmPrice;
    return perKmPrice == null ? null : distanceKm * perKmPrice.toDouble();
  }

  if (configuredPrice != null) {
    return configuredPrice.toDouble();
  }

  final perKmPrice = model.kmPrice;
  return perKmPrice == null ? null : distanceKm * perKmPrice.toDouble();
}

double? _calculateDistanceKm(RestaurantsNearYouHomeModel model) {
  final userLat = HiveMethods.getLat();
  final userLng = HiveMethods.getLan();
  final restaurantLat = double.tryParse((model.lat ?? '').trim());
  final restaurantLng = double.tryParse((model.lng ?? '').trim());

  if (userLat == null ||
      userLng == null ||
      restaurantLat == null ||
      restaurantLng == null) {
    return null;
  }

  if (userLat.abs() > 90 ||
      restaurantLat.abs() > 90 ||
      userLng.abs() > 180 ||
      restaurantLng.abs() > 180) {
    return null;
  }

  final distanceMeters = Geolocator.distanceBetween(
    userLat,
    userLng,
    restaurantLat,
    restaurantLng,
  );

  return distanceMeters / 1000;
}

String _formatKm(double? value) {
  if (value == null || !value.isFinite) return '-';
  if (value < 1) return '${(value * 1000).round()} م';
  if (value < 10) return '${value.toStringAsFixed(1)} كم';
  return '${value.round()} كم';
}

class IsRestaurantBusyWidget extends StatelessWidget {
  const IsRestaurantBusyWidget({super.key, required this.model});

  final RestaurantsNearYouHomeModel model;

  @override
  Widget build(BuildContext context) {
    final unavailable = model.status == 'closed' ||
        model.underContract == 'yes' ||
        model.status == 'busy';
    if (!unavailable) return const SizedBox.shrink();

    return Positioned.fill(
      child: Container(
        color: AppColors.blackColor.withValues(alpha: .48),
        alignment: Alignment.center,
        child: Text(
          model.underContract == 'yes'
              ? 'underContract'.tr
              : model.status == 'closed'
                  ? restaurantClosedLabel(context, model.openAt)
                  : 'busy'.tr,
          style: AppTextStyle.text14MW(),
        ),
      ),
    );
  }
}
