import 'package:faskhaninja/helpers/theme/fasakhansta_brand.dart';
import 'package:flutter/material.dart';

import '../../../../helpers/routes/app_routers_import.dart';
import '../../../../helpers/theme/app_colors.dart';
import '../../../../helpers/theme/app_text_style.dart';
import '../../../custom_widgets/custom_image/custom_image.dart';
import '../../restaurants/screen/restaurant_details_screen.dart';
import '../controller/home_controller.dart';
import '../model/coupon_model.dart';

class RestaurantsDrawWidget extends StatelessWidget {
  const RestaurantsDrawWidget({super.key, required this.homeController});

  final HomeController homeController;

  @override
  Widget build(BuildContext context) {
    final data = homeController.coupon?.data;
    final restaurants = data?.resturants ?? <Resturants>[];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _ParticipationStatsCard(
          ordersCount: data?.eligibleOrdersCount ?? 0,
          ordersTotal: data?.eligibleOrdersTotal ?? 0,
        ),
        const SizedBox(height: 16),
        if (restaurants.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
            decoration: BoxDecoration(
              color: FasakhanstaBrand.surface,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: FasakhanstaBrand.border),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x0D000000),
                  blurRadius: 16,
                  offset: Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    color: AppColors.mainAppColor.withValues(alpha: .10),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.storefront_rounded,
                    color: AppColors.mainAppColor,
                    size: 30,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'لا توجد مطاعم مشاركة حالياً',
                  style: AppTextStyle.text14BS(),
                ),
              ],
            ),
          )
        else
          ListView.separated(
            padding: EdgeInsets.zero,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: restaurants.length,
            separatorBuilder: (_, __) => const SizedBox(height: 14),
            itemBuilder: (context, index) {
              return RestaurantCard(restaurant: restaurants[index]);
            },
          ),
      ],
    );
  }
}

class _ParticipationStatsCard extends StatelessWidget {
  const _ParticipationStatsCard({
    required this.ordersCount,
    required this.ordersTotal,
  });

  final int ordersCount;
  final num ordersTotal;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: FasakhanstaBrand.surfaceRaised,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: FasakhanstaBrand.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 14,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: const BoxDecoration(
                  color: FasakhanstaBrand.surface,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.confirmation_number_rounded,
                  color: FasakhanstaBrand.success,
                  size: 23,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'مشاركاتك المؤهلة في السحب',
                      style: AppTextStyle.text15BS(),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'كل طلب مؤهل = فرصة مستقلة للفوز',
                      style: AppTextStyle.text11RG(
                        color: FasakhanstaBrand.muted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _UserStat(
                  label: 'عدد الطلبات المؤهلة',
                  value: ordersCount.toString(),
                  icon: Icons.receipt_long_rounded,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _UserStat(
                  label: 'إجمالي قيمة الطلبات',
                  value: _formatMoney(ordersTotal),
                  icon: Icons.payments_rounded,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _UserStat extends StatelessWidget {
  const _UserStat({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 82),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 11),
      decoration: BoxDecoration(
        color: FasakhanstaBrand.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: FasakhanstaBrand.border),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: AppColors.mainAppColor, size: 20),
          const SizedBox(height: 5),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyle.text16BS(color: FasakhanstaBrand.text),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyle.text10RG(color: FasakhanstaBrand.muted),
          ),
        ],
      ),
    );
  }
}

class RestaurantCard extends StatelessWidget {
  const RestaurantCard({super.key, required this.restaurant});

  final Resturants restaurant;

  @override
  Widget build(BuildContext context) {
    final logo = (restaurant.logo ?? '').trim();
    final fallbackImage = (restaurant.bgImage ?? '').trim();
    final image = logo.isNotEmpty ? logo : fallbackImage;
    final address = (restaurant.address ?? '').trim().isNotEmpty
        ? restaurant.address!.trim()
        : (restaurant.cityName ?? restaurant.cityname ?? '').trim();
    final restaurantId = restaurant.id ?? 0;

    return Material(
      color: FasakhanstaBrand.surface,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: restaurantId > 0
            ? () => NamedNavigatorImpl.push(
                  RestaurantDetailsScreen.routeName,
                  arguments: RestaurantDetailsArgs(id: restaurantId),
                )
            : null,
        child: Container(
          padding: const EdgeInsets.fromLTRB(13, 13, 13, 12),
          decoration: BoxDecoration(
            color: FasakhanstaBrand.surface,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: FasakhanstaBrand.border),
            boxShadow: const [
              BoxShadow(
                color: Color(0x12000000),
                blurRadius: 18,
                offset: Offset(0, 7),
              ),
            ],
          ),
          child: Directionality(
            textDirection: TextDirection.rtl,
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    _RestaurantImage(image: image),
                    const SizedBox(width: 13),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  restaurant.name ?? '',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTextStyle.text17BS(),
                                ),
                              ),
                              const SizedBox(width: 7),
                              const _ParticipatingBadge(),
                            ],
                          ),
                          const SizedBox(height: 6),
                          if (address.isNotEmpty)
                            Row(
                              children: [
                                const Icon(
                                  Icons.location_on_outlined,
                                  size: 15,
                                  color: FasakhanstaBrand.muted,
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    address,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTextStyle.text12RG(
                                      color: FasakhanstaBrand.muted,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 9,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: FasakhanstaBrand.surfaceRaised,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.star_rounded,
                                  size: 17,
                                  color: FasakhanstaBrand.orange,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  restaurant.avgRate?.toStringAsFixed(1) ??
                                      '0.0',
                                  style: AppTextStyle.text13BS(),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      Icons.arrow_back_ios_new_rounded,
                      size: 17,
                      color: AppColors.mainAppColor,
                    ),
                  ],
                ),
                const SizedBox(height: 13),
                const Divider(height: 1, color: FasakhanstaBrand.border),
                const SizedBox(height: 11),
                Row(
                  children: [
                    Expanded(
                      child: _MetricItem(
                        icon: Icons.schedule_rounded,
                        label: 'وقت التوصيل',
                        value: _formatDeliveryTime(restaurant.deliveryTime),
                      ),
                    ),
                    _metricDivider(),
                    Expanded(
                      child: _MetricItem(
                        icon: Icons.star_rounded,
                        label: 'التقييم',
                        value: restaurant.avgRate?.toStringAsFixed(1) ?? '0.0',
                      ),
                    ),
                    _metricDivider(),
                    Expanded(
                      child: _MetricItem(
                        icon: Icons.delivery_dining_rounded,
                        label: 'رسوم التوصيل',
                        value: _formatMoney(restaurant.serviceFees),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _metricDivider() =>
      Container(width: 1, height: 46, color: FasakhanstaBrand.surfaceRaised);
}

class _RestaurantImage extends StatelessWidget {
  const _RestaurantImage({required this.image});

  final String image;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: image.isEmpty
          ? Container(
              width: 94,
              height: 94,
              color: FasakhanstaBrand.surfaceRaised,
              alignment: Alignment.center,
              child: Icon(
                Icons.storefront_rounded,
                color: AppColors.mainAppColor,
                size: 36,
              ),
            )
          : CustomImage(
              path: image,
              type: ImageType.network,
              fit: BoxFit.cover,
              radius: 0,
              height: 94,
              width: 94,
            ),
    );
  }
}

class _ParticipatingBadge extends StatelessWidget {
  const _ParticipatingBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: FasakhanstaBrand.surfaceRaised,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.check_circle_rounded,
            size: 14,
            color: FasakhanstaBrand.success,
          ),
          SizedBox(width: 4),
          Text(
            'مشارك',
            style: TextStyle(
              color: FasakhanstaBrand.success,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricItem extends StatelessWidget {
  const _MetricItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 19, color: AppColors.mainAppColor),
        const SizedBox(height: 4),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyle.text10RG(color: FasakhanstaBrand.muted),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyle.text12BS(),
        ),
      ],
    );
  }
}

String _formatMoney(dynamic value) {
  if (value == null) return '-';
  final number = value is num ? value : num.tryParse(value.toString());
  if (number == null) return value.toString();
  if (number == 0) return '0 ج';
  return '${number.toStringAsFixed(number % 1 == 0 ? 0 : 2)} ج';
}

String _formatDeliveryTime(String? value) {
  final text = value?.trim() ?? '';
  return text.isEmpty ? '-' : text;
}
