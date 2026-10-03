import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../helpers/routes/app_routers_import.dart';
import '../../../../helpers/theme/app_colors.dart';
import '../../../../helpers/theme/app_text_style.dart';
import '../../../../helpers/utils/restaurant_hours.dart';
import '../../../custom_widgets/api_response_widget/api_response_widget.dart';
import '../../../custom_widgets/custom_image/custom_network_image.dart';
import '../../../custom_widgets/page_container/page_container.dart';
import '../../restaurants/screen/restaurant_details_screen.dart';
import '../../restaurants/screen/restaurants_screen.dart';
import '../controller/favorite_controller.dart';
import '../model/favorite_model.dart';

class FavoriteScreen extends StatelessWidget {
  static const String routeName = 'FavoriteScreen';
  const FavoriteScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => FavoriteController()
        ..initialFavorite()
        ..getFavorite(),
      child: Consumer<FavoriteController>(
        builder: (context, controller, _) {
          return Scaffold(
            backgroundColor: const Color(0xFFF8F9FB),
            body: SafeArea(
              child: PageContainer(
                child: Column(
                  children: [
                    _header(context),
                    Expanded(
                      child: ApiResponseWidget(
                        apiResponse: controller.favoriteResponse,
                        onReload: controller.getFavorite,
                        isEmpty: controller.favorite.isEmpty,
                        child: RefreshIndicator(
                          color: AppColors.mainAppColor,
                          onRefresh: controller.getFavorite,
                          child: ListView(
                            physics: const AlwaysScrollableScrollPhysics(
                              parent: BouncingScrollPhysics(),
                            ),
                            padding: const EdgeInsets.fromLTRB(16, 6, 16, 28),
                            children: [
                              _summaryCard(controller.favorite.length),
                              const SizedBox(height: 18),
                              _sectionHeader(controller.favorite.length),
                              const SizedBox(height: 10),
                              for (var index = 0;
                                  index < controller.favorite.length;
                                  index++) ...[
                                _FavoriteRestaurantCard(
                                  model: controller.favorite[index],
                                  onRemove: () {
                                    final restaurantId = _restaurantId(
                                      controller.favorite[index],
                                    );
                                    if (restaurantId == 0) return;
                                    controller.addOrRemoveToWishlist(
                                      id: restaurantId,
                                      onSuccess: () {},
                                    );
                                  },
                                ),
                                if (index != controller.favorite.length - 1)
                                  const SizedBox(height: 10),
                              ],
                              const SizedBox(height: 18),
                              _browseBanner(context),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  static Widget _header(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
      child: SizedBox(
        height: 54,
        child: Row(
          children: [
            _circleButton(
              icon: Icons.arrow_back_ios_new_rounded,
              onTap: () => Navigator.maybePop(context),
            ),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('المفضلة', style: AppTextStyle.text22MS()),
                  const SizedBox(height: 2),
                  Text(
                    'مطاعمك المفضلة في مكان واحد',
                    style: AppTextStyle.text11RG().copyWith(
                      color: const Color(0xFF989CA3),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFFFFF3EA),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Icon(
                Icons.favorite_rounded,
                color: AppColors.mainAppColor,
                size: 22,
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _circleButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(15),
      child: InkWell(
        borderRadius: BorderRadius.circular(15),
        onTap: onTap,
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: const Color(0xFFECEEF1)),
          ),
          child: Icon(icon, color: AppColors.mainAppColor, size: 20),
        ),
      ),
    );
  }

  static Widget _summaryCard(int count) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [Color(0xFFFFF5ED), Color(0xFFFFFBF8)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFFFE0C8)),
      ),
      child: Row(
        textDirection: TextDirection.rtl,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.mainAppColor,
              borderRadius: BorderRadius.circular(15),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x30FD7201),
                  blurRadius: 12,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(
              Icons.favorite_rounded,
              color: Colors.white,
              size: 25,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('اختياراتك المفضلة', style: AppTextStyle.text15BS()),
                const SizedBox(height: 3),
                Text(
                  count == 1
                      ? 'لديك مطعم واحد محفوظ للوصول إليه بسرعة'
                      : 'لديك $count مطاعم محفوظة للوصول إليها بسرعة',
                  style: AppTextStyle.text11RG().copyWith(
                    color: const Color(0xFF858A92),
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(11),
              border: Border.all(color: const Color(0xFFFFDFC5)),
            ),
            child: Text(
              '$count',
              style: AppTextStyle.text16BS().copyWith(
                color: AppColors.mainAppColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static Widget _sectionHeader(int count) {
    return Row(
      textDirection: TextDirection.rtl,
      children: [
        Text('مطاعمك', style: AppTextStyle.text17BS()),
        const SizedBox(width: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF1E6),
            borderRadius: BorderRadius.circular(9),
          ),
          child: Text(
            '$count',
            style: AppTextStyle.text11BS().copyWith(
              color: AppColors.mainAppColor,
            ),
          ),
        ),
        const Spacer(),
        Text(
          'اضغط على المطعم لفتحه',
          style: AppTextStyle.text10RG().copyWith(
            color: const Color(0xFF9A9EA5),
          ),
        ),
      ],
    );
  }

  static Widget _browseBanner(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => NamedNavigatorImpl.push(RestaurantsScreen.routeName),
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFECEEF1)),
          ),
          child: Row(
            textDirection: TextDirection.rtl,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF3EA),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(
                  Icons.storefront_rounded,
                  color: AppColors.mainAppColor,
                  size: 21,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('اكتشف مطاعم جديدة', style: AppTextStyle.text14BS()),
                    const SizedBox(height: 2),
                    Text(
                      'تصفح الفروع وأضف مطاعم أخرى إلى المفضلة',
                      style: AppTextStyle.text10RG().copyWith(
                        color: const Color(0xFF92969D),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 16,
                color: AppColors.mainAppColor,
              ),
            ],
          ),
        ),
      ),
    );
  }

  static int _restaurantId(FavoriteModel model) {
    return model.id ?? model.resturantId ?? model.vendorId ?? 0;
  }
}

class _FavoriteRestaurantCard extends StatelessWidget {
  final FavoriteModel model;
  final VoidCallback onRemove;

  const _FavoriteRestaurantCard({
    required this.model,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final restaurantId =
        model.id ?? model.resturantId ?? model.vendorId ?? 0;
    final statusInfo = _restaurantStatus(context, model.status, model.openAt);
    final title = (model.name ?? model.vendorName ?? model.resturantName ?? '').trim();
    final address = (model.address ?? '').trim();
    final image = model.bgImage?.isNotEmpty == true
        ? model.bgImage!
        : (model.logo ?? '');

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: restaurantId == 0
            ? null
            : () => NamedNavigatorImpl.push(
                  RestaurantDetailsScreen.routeName,
                  arguments: RestaurantDetailsArgs(id: restaurantId),
                ),
        child: Container(
          height: 116,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFEDEFF2)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x10000000),
                blurRadius: 14,
                offset: Offset(0, 5),
              ),
            ],
          ),
          child: Row(
            textDirection: TextDirection.rtl,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: SizedBox(
                  width: 102,
                  height: 100,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      CustomNetworkImage(
                        imageUrl: image,
                        height: 100,
                        width: 102,
                        radius: 0,
                        fit: BoxFit.cover,
                      ),
                      Positioned(
                        right: 6,
                        bottom: 6,
                        child: Container(
                          constraints: const BoxConstraints(maxWidth: 94),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: statusInfo.color,
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x22000000),
                                blurRadius: 5,
                              ),
                            ],
                          ),
                          child: Text(
                            statusInfo.label,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: AppTextStyle.text9BW(),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title.isEmpty ? 'مطعم' : title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.right,
                            style: AppTextStyle.text15BS(),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Material(
                          color: const Color(0xFFFFF2E9),
                          borderRadius: BorderRadius.circular(11),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(11),
                            onTap: onRemove,
                            child: SizedBox(
                              width: 34,
                              height: 34,
                              child: Icon(
                                Icons.favorite_rounded,
                                color: AppColors.mainAppColor,
                                size: 19,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on_outlined,
                          size: 14,
                          color: AppColors.mainAppColor,
                        ),
                        const SizedBox(width: 3),
                        Expanded(
                          child: Text(
                            address.isEmpty ? 'اضغط لعرض تفاصيل المطعم' : address,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.right,
                            style: AppTextStyle.text10RG().copyWith(
                              color: const Color(0xFF92969D),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Row(
                      textDirection: TextDirection.rtl,
                      children: [
                        _InfoChip(
                          icon: Icons.star_rounded,
                          iconColor: const Color(0xFFFFB000),
                          text: _formatRate(model.avgRate),
                        ),
                        const SizedBox(width: 6),
                        _InfoChip(
                          icon: Icons.schedule_rounded,
                          iconColor: AppColors.mainAppColor,
                          text: (model.deliveryTime ?? '').trim().isEmpty
                              ? '—'
                              : model.deliveryTime!.trim(),
                        ),
                        const Spacer(),
                        Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF7F8FA),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.arrow_back_ios_new_rounded,
                            size: 14,
                            color: Color(0xFF6E737B),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static _StatusInfo _restaurantStatus(
    BuildContext context,
    String? rawStatus,
    String? openAt,
  ) {
    final status = (rawStatus ?? '').toLowerCase().trim();
    if (status == 'closed') {
      return _StatusInfo(
        restaurantClosedLabel(context, openAt),
        const Color(0xFF777B82),
      );
    }
    if (status == 'busy') {
      return const _StatusInfo('مشغول', Color(0xFFD99100));
    }
    if (status == 'opened' || status == 'open') {
      return const _StatusInfo('مفتوح', Color(0xFF0A6F6A));
    }
    return const _StatusInfo('متاح', Color(0xFF0A6F6A));
  }

  static String _formatRate(num? value) {
    if (value == null) return '0.0';
    return value.toStringAsFixed(1);
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String text;

  const _InfoChip({
    required this.icon,
    required this.iconColor,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 92),
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FB),
        borderRadius: BorderRadius.circular(9),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: iconColor),
          const SizedBox(width: 3),
          Flexible(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyle.text9RG().copyWith(
                color: const Color(0xFF5F646C),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusInfo {
  final String label;
  final Color color;

  const _StatusInfo(this.label, this.color);
}
