import 'dart:math' as math;

import 'package:flutter/material.dart';
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

/// Displays the nearby branches in the order supplied by the API.
class RestaurantsNearYouListViewWidget extends StatelessWidget {
  final List<RestaurantsNearYouHomeModel> restaurantsNearYou;
  final bool handleApiResponse;
  final EdgeInsetsGeometry padding;

  const RestaurantsNearYouListViewWidget({
    super.key,
    required this.restaurantsNearYou,
    this.handleApiResponse = true,
    this.padding = const EdgeInsets.symmetric(horizontal: 16),
  });

  @override
  Widget build(BuildContext context) {
    final cards = _NearbyBranchList(
      restaurants: restaurantsNearYou,
      padding: padding,
    );
    if (!handleApiResponse) return cards;

    return ApiResponseWidget(
      apiResponse: context.read<HomeController>().restaurantsNearYouApiResponse,
      onReload: () => context.read<HomeController>().getRestaurantsNearYou(
        lat: HiveMethods.getLat(),
        lng: HiveMethods.getLan(),
      ),
      isEmpty: restaurantsNearYou.isEmpty,
      emptyWidget: const SizedBox.shrink(),
      loadingWidget: Padding(
        padding: padding,
        child: CustomShimmer(
          height: 84,
          width: double.infinity,
          fillColor: Colors.white.withValues(alpha: .06),
          shimmerColor: AppColors.mainAppColor,
        ),
      ),
      child: cards,
    );
  }
}

class _NearbyBranchList extends StatelessWidget {
  final List<RestaurantsNearYouHomeModel> restaurants;
  final EdgeInsetsGeometry padding;

  const _NearbyBranchList({required this.restaurants, required this.padding});

  @override
  Widget build(BuildContext context) {
    if (restaurants.isEmpty) return const SizedBox.shrink();

    return Directionality(
      textDirection: TextDirection.rtl,
      child: SizedBox(
        height: 84,
        child: LayoutBuilder(
          builder: (context, constraints) {
            if (restaurants.length == 1) {
              return Padding(
                padding: padding,
                child: _NearbyBranchCard(model: restaurants.first),
              );
            }

            final insets = padding.resolve(TextDirection.rtl);
            final availableWidth = constraints.maxWidth.isFinite
                ? constraints.maxWidth
                : MediaQuery.sizeOf(context).width;
            final cardWidth = math.min(
              340.0,
              math.max(0.0, availableWidth - insets.horizontal - 20),
            );

            return ListView.separated(
              padding: padding,
              scrollDirection: Axis.horizontal,
              itemCount: restaurants.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (_, index) => SizedBox(
                width: cardWidth,
                child: _NearbyBranchCard(model: restaurants[index]),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _NearbyBranchCard extends StatelessWidget {
  final RestaurantsNearYouHomeModel model;

  const _NearbyBranchCard({required this.model});

  @override
  Widget build(BuildContext context) {
    const orange = Color(0xFFFF7A1A);
    final radius = BorderRadius.circular(20);
    final canOpen =
        (model.id ?? 0) > 0 &&
        model.underContract != 'yes' &&
        model.status != 'busy';
    final logo = (model.logo ?? '').trim();
    final address = (model.address ?? '').trim();
    final city = (model.cityName ?? model.cityname ?? '').trim();
    final subtitle = model.underContract == 'yes'
        ? 'underContract'.tr
        : model.status == 'busy'
        ? 'busy'.tr
        : model.status == 'closed'
        ? restaurantClosedLabel(context, model.openAt)
        : address.isNotEmpty
        ? address
        : city;

    return Semantics(
      button: true,
      enabled: canOpen,
      child: Material(
        color: const Color(0xD908282E),
        borderRadius: radius,
        child: InkWell(
          borderRadius: radius,
          onTap: canOpen
              ? () => NamedNavigatorImpl.push(
                  RestaurantDetailsScreen.routeName,
                  arguments: RestaurantDetailsArgs(id: model.id!),
                )
              : null,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: radius,
              border: Border.all(color: Colors.white.withValues(alpha: .16)),
            ),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  padding: const EdgeInsets.all(4),
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFFAF4),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: logo.isEmpty
                      ? const Icon(
                          Icons.storefront_outlined,
                          color: orange,
                          size: 28,
                        )
                      : CustomNetworkImage(
                          imageUrl: logo,
                          width: 44,
                          height: 44,
                          fit: BoxFit.contain,
                          radius: 8,
                        ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Flexible(
                        child: Text(
                          model.name ?? '',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyle.text14BS(color: Colors.white)
                              .copyWith(height: 1.2),
                        ),
                      ),
                      if (subtitle.isNotEmpty) ...[
                        const SizedBox(height: 5),
                        Flexible(
                          child: Text(
                            subtitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyle.text11RG(
                              color: Colors.white.withValues(alpha: .72),
                            ).copyWith(height: 1.2),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 64,
                  height: 36,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: canOpen
                        ? orange
                        : Colors.white.withValues(alpha: .08),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Text(
                    'المنيو',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyle.text11BS(
                      color: canOpen
                          ? const Color(0xFF09282D)
                          : Colors.white.withValues(alpha: .55),
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

/// Kept for callers that use the existing unavailable-state overlay.
class IsRestaurantBusyWidget extends StatelessWidget {
  const IsRestaurantBusyWidget({super.key, required this.model});

  final RestaurantsNearYouHomeModel model;

  @override
  Widget build(BuildContext context) {
    final unavailable =
        model.status == 'closed' ||
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
