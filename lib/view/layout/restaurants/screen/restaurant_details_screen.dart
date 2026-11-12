import 'dart:convert';
import 'dart:developer';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import 'package:pusher_channels_flutter/pusher_channels_flutter.dart';

import '../../../../helpers/extensions/extensions.dart';
import '../../../../helpers/hive/hive_methods.dart';
import '../../../../helpers/images/app_images.dart';
import '../../../../helpers/pusher_service/pusher_controller.dart';
import '../../../../helpers/routes/app_routers_import.dart';
import '../../../../helpers/theme/app_colors.dart';
import '../../../../helpers/theme/app_text_style.dart';
import '../../../../helpers/translation/all_translation.dart';
import '../../../../helpers/utils/common_methods.dart';
import '../../../custom_widgets/api_response_widget/api_response_widget.dart';
import '../../../custom_widgets/custom_image/custom_image.dart';
import '../../../custom_widgets/custom_image/custom_network_image.dart';
import '../../cart/controller/cart_controller.dart';
import '../../cart/screen/cart_screen.dart';
import '../controller/restaurants_controller.dart';
import '../model/details_restaurants_model.dart' as details_restaurant_model;
import '../model/highst_rated_model.dart';
import '../model/previous_order_model.dart';
import '../model/products_restaurant_model.dart';
import '../widgets/choices_according_to_your_taste_widget.dart';
import '../widgets/header_cover_and_image_restaurant_details_widget.dart';
import '../widgets/previous_orders_list_view_widget.dart';
import '../widgets/menu_product_card.dart';
import 'product_details_screen.dart';

class RestaurantDetailsArgs {
  final int id;
  final VoidCallback? onSuccessAddItem;

  const RestaurantDetailsArgs({required this.id, this.onSuccessAddItem});
}

class RestaurantDetailsScreen extends StatefulWidget {
  final RestaurantDetailsArgs args;
  static const String routeName = 'RestaurantDetailsScreen';

  const RestaurantDetailsScreen({super.key, required this.args});

  @override
  State<RestaurantDetailsScreen> createState() => _RestaurantDetailsScreenState();
}

class _RestaurantDetailsScreenState extends State<RestaurantDetailsScreen> {
  int currentIndex = 0;
  final ScrollController _verticalScrollController = ScrollController();
  final List<GlobalKey> _categoryKeys = [];
  late PusherController _pusherController;

  @override
  void initState() {
    super.initState();
    _verticalScrollController.addListener(animateToTab);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final controller = context.read<RestaurantsController>();
      controller.initialRestaurantsDetails();
      controller.initialPreviousOrder();
      controller.initialProductsRestaurant();
      Future.wait([
        controller.getRestaurantsDetails(id: widget.args.id),
        controller.getPreviousOrder(id: widget.args.id),
        controller.getProductsRestaurant(id: widget.args.id),
      ]);
    });

    _pusherController = context.read<PusherController>();
    _pusherController.addEventListener('product.updated', _handleProductUpdated);
    _pusherController.addEventListener('product.updated', _handlePreviousProductUpdated);
    _pusherController.addEventListener('product.updated', _handleHightsRatedUpdated);
    _pusherController.addEventListener('resturant.updated', _handleResturantUpdated);
  }

  void _handleProductUpdated(PusherEvent event) {
    try {
      final decodedData = json.decode(event.data) as Map<String, dynamic>;
      final productData = decodedData['product'];
      if (mounted) {
        final product = ResturantItems.fromJson(productData as Map<String, dynamic>);
        context.read<RestaurantsController>().updateResturantProductOrder(product);
      }
    } catch (e, stackTrace) {
      log('Error handling product.updated: $e');
      log('$stackTrace');
    }
  }

  void _handleHightsRatedUpdated(PusherEvent event) {
    try {
      final decodedData = json.decode(event.data) as Map<String, dynamic>;
      final productData = decodedData['product'];
      if (mounted) {
        final product = HighestRated.fromJson(productData as Map<String, dynamic>);
        context.read<RestaurantsController>().updateAccordingToYourTasteResturantProduct(product);
      }
    } catch (e, stackTrace) {
      log('Error handling highest rated update: $e');
      log('$stackTrace');
    }
  }

  void _handlePreviousProductUpdated(PusherEvent event) {
    try {
      final decodedData = json.decode(event.data) as Map<String, dynamic>;
      final productData = decodedData['product'];
      if (mounted) {
        final product = PreviousOrderModel.fromJson(productData as Map<String, dynamic>);
        context.read<RestaurantsController>().updateResturantPreviousProductOrder(product);
      }
    } catch (e, stackTrace) {
      log('Error handling previous product update: $e');
      log('$stackTrace');
    }
  }

  void _handleResturantUpdated(PusherEvent event) {
    try {
      final decodedData = json.decode(event.data) as Map<String, dynamic>;
      final restaurantData = decodedData['resturant'];
      if (mounted) {
        final restaurant = details_restaurant_model.DetailsRestaurantModel.fromJson(
          restaurantData as Map<String, dynamic>,
        );
        context.read<RestaurantsController>().updateResturantDetails(restaurant);
      }
    } catch (e, stackTrace) {
      log('Error handling resturant.updated: $e');
      log('$stackTrace');
    }
  }

  @override
  void dispose() {
    _pusherController.removeEventListener('product.updated', _handleProductUpdated);
    _pusherController.removeEventListener('product.updated', _handlePreviousProductUpdated);
    _pusherController.removeEventListener('product.updated', _handleHightsRatedUpdated);
    _pusherController.removeEventListener('resturant.updated', _handleResturantUpdated);
    _verticalScrollController.dispose();
    super.dispose();
  }

  void _scrollToCategory(int index) {
    if (index < 0 || index >= _categoryKeys.length) return;
    final keyContext = _categoryKeys[index].currentContext;
    if (keyContext != null) {
      Scrollable.ensureVisible(
        keyContext,
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeInOut,
        alignment: 0.08,
      );
    }
  }

  void _scrollToTop() {
    _verticalScrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeInOut,
    );
  }

  void animateToTab() {
    if (_categoryKeys.isEmpty || !mounted) return;
    if (_verticalScrollController.offset <= 10) {
      if (currentIndex != 0) setState(() => currentIndex = 0);
      return;
    }

    for (var i = 0; i < _categoryKeys.length; i++) {
      final context = _categoryKeys[i].currentContext;
      if (context == null) continue;
      final box = context.findRenderObject() as RenderBox?;
      if (box == null) continue;
      final position = box.localToGlobal(Offset.zero).dy;
      if (position < 190 && currentIndex != i) setState(() => currentIndex = i);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<RestaurantsController>(
      builder: (context, restaurantsController, _) {
        _categoryKeys
          ..clear()
          ..addAll(List.generate(
            restaurantsController.productsRestaurant.length,
            (_) => GlobalKey(),
          ));

        return Container(
          color: AppColors.whiteColor,
          child: ApiResponseWidget(
            apiResponse: restaurantsController.restaurantsDetailsApiResponse,
            onReload: () {
              restaurantsController.getRestaurantsDetails(id: widget.args.id);
              restaurantsController.getProductsRestaurant(id: widget.args.id);
              restaurantsController.getPreviousOrder(id: widget.args.id);
            },
            isEmpty: restaurantsController.detailsRestaurant == null,
            child: Scaffold(
              backgroundColor: const Color(0xFFFAFAFA),
              body: Column(
                children: [
                  HeaderCoverAndImageRestaurantDetailsWidget(
                    detailsRestaurant: restaurantsController.detailsRestaurant,
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      controller: _verticalScrollController,
                      padding: const EdgeInsets.only(bottom: 105),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildBranchStats(restaurantsController),
                          _buildSpecialOffer(),
                          _buildCategoryTabs(restaurantsController),
                          if (restaurantsController.previousOrders.isNotEmpty)
                            _buildPreviousOrders(restaurantsController),
                          _buildBestSellers(restaurantsController),
                          _buildOfferBanner(),
                          ..._buildCategories(restaurantsController),
                          if (restaurantsController.detailsRestaurant?.highestRated?.isNotEmpty == true)
                            _buildChoicesAccordingToYourTaste(restaurantsController),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              bottomNavigationBar: _buildCartBar(),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBranchStats(RestaurantsController controller) {
    final restaurant = controller.detailsRestaurant;
    final distanceKm = _calculateDistanceKm(restaurant);
    final deliveryFee = _calculateDeliveryFee(restaurant, distanceKm);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      child: Row(
        children: [
          Expanded(
            child: _statCard(
              Icons.delivery_dining,
              _formatDeliveryFee(deliveryFee),
              'رسوم التوصيل',
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _statCard(
              Icons.near_me_outlined,
              _formatDistance(distanceKm),
              'المسافة منك',
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _statCard(
              Icons.access_time_rounded,
              restaurant?.deliveryTime ?? '-',
              'وقت التوصيل',
            ),
          ),
        ],
      ),
    );
  }

  double? _calculateDistanceKm(
    details_restaurant_model.DetailsRestaurantModel? restaurant,
  ) {
    if (restaurant == null) return null;

    final userLat = HiveMethods.getLat();
    final userLng = HiveMethods.getLan();
    final restaurantLat = double.tryParse((restaurant.lat ?? '').trim());
    final restaurantLng = double.tryParse((restaurant.lng ?? '').trim());

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

  double? _calculateDeliveryFee(
    details_restaurant_model.DetailsRestaurantModel? restaurant,
    double? distanceKm,
  ) {
    if (restaurant == null ||
        distanceKm == null ||
        !distanceKm.isFinite ||
        distanceKm < 0) {
      return null;
    }

    num? configuredPrice;
    if (distanceKm <= 1) {
      configuredPrice = restaurant.default_0_1;
    } else if (distanceKm <= 2) {
      configuredPrice = restaurant.default_1_2;
    } else if (distanceKm <= 3) {
      configuredPrice = restaurant.default_2_3;
    } else {
      final perKmPrice = restaurant.kmPrice;
      return perKmPrice == null ? null : distanceKm * perKmPrice.toDouble();
    }

    if (configuredPrice != null) {
      return configuredPrice.toDouble();
    }

    final perKmPrice = restaurant.kmPrice;
    return perKmPrice == null ? null : distanceKm * perKmPrice.toDouble();
  }

  String _formatDeliveryFee(double? value) {
    if (value == null || !value.isFinite) return 'حسب المنطقة';
    return '${value.toStringAsFixed(0)} جنيه';
  }

  String _formatDistance(double? value) {
    if (value == null || !value.isFinite) return '-';
    if (value < 1) return '${(value * 1000).round()} م';
    if (value < 10) return '${value.toStringAsFixed(1)} كم';
    return '${value.round()} كم';
  }

  Widget _statCard(IconData icon, String value, String title) {
    return Container(
      height: 72,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: AppColors.whiteColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEDEDED)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: AppColors.mainAppColor, size: 20),
          const SizedBox(height: 3),
          Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTextStyle.text14BS()),
          Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTextStyle.text11RS()),
        ],
      ),
    );
  }

  Widget _buildSpecialOffer() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF4EC),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFFFE0CF)),
        ),
        child: Row(
          children: [
            Icon(Icons.card_giftcard_rounded, color: AppColors.mainAppColor, size: 28),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'عرض خاص  تابع العروض المتاحة داخل الفرع واستفد من أفضل الأسعار',
                textAlign: TextAlign.right,
                style: AppTextStyle.text13RS(),
              ),
            ),
            const SizedBox(width: 8),
            Text('التفاصيل', style: AppTextStyle.text12BS().copyWith(color: AppColors.mainAppColor)),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryTabs(RestaurantsController controller) {
    return SizedBox(
      height: 96,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        scrollDirection: Axis.horizontal,
        itemCount: controller.productsRestaurant.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final selected = currentIndex == index;
          return GestureDetector(
            onTap: () {
              setState(() => currentIndex = index);
              _scrollToCategory(index);
            },
            child: SizedBox(
              width: 72,
              child: Column(
                children: [
                  Container(
                    width: 58,
                    height: 58,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: selected ? AppColors.mainAppColor.withValues(alpha: .12) : AppColors.whiteColor,
                      border: Border.all(
                        color: selected ? AppColors.mainAppColor : const Color(0xFFE7E7E7),
                        width: selected ? 2 : 1,
                      ),
                    ),
                    child: Icon(_categoryIcon(index), color: AppColors.mainAppColor, size: 28),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    controller.productsRestaurant[index].categoryName ?? '',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: selected ? AppTextStyle.text12BS() : AppTextStyle.text12RS(),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  IconData _categoryIcon(int index) {
    const icons = [
      Icons.grid_view_rounded,
      Icons.set_meal_rounded,
      Icons.restaurant_rounded,
      Icons.rice_bowl_rounded,
      Icons.local_dining_rounded,
      Icons.fastfood_rounded,
    ];
    return icons[index % icons.length];
  }

  Widget _buildBestSellers(RestaurantsController controller) {
    final items = <ResturantItems>[];
    for (final category in controller.productsRestaurant) {
      for (final item in category.resturantItems ?? <ResturantItems>[]) {
        if (item.status == 'show') items.add(item);
        if (items.length == 4) break;
      }
      if (items.length == 4) break;
    }

    if (items.isEmpty) return const SizedBox();

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 2, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('الأكثر مبيعاً 🏆', style: AppTextStyle.text18BS()),
              Text('عرض الكل', style: AppTextStyle.text13BS().copyWith(color: AppColors.mainAppColor)),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: _productCardHeight(155),
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (context, index) => _productCard(items[index]),
            ),
          ),
        ],
      ),
    );
  }

  double _productCardHeight(double width) {
    final textScale = MediaQuery.textScalerOf(context).scale(14) / 14;
    return math.max(width / .70, 250 + math.max(0, textScale - 1) * 70);
  }

  Widget _productCard(ResturantItems item) {
    return SizedBox(
      width: 155,
      child: MenuProductCard(
        name: item.productName ?? '',
        priceLabel: '${item.productPrice?.toStringAsFixed(0) ?? '-'} ج',
        image: CustomNetworkImage(
          imageUrl: item.productImage ?? '',
          radius: 0,
          fit: BoxFit.cover,
        ),
        draw: item.draw,
        compact: true,
        onTap: () => _openProduct(item.id ?? 0),
      ),
    );
  }

  Widget _buildOfferBanner() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 18),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
        decoration: BoxDecoration(
          color: const Color(0xFF061827),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(color: AppColors.mainAppColor, borderRadius: BorderRadius.circular(15)),
              child: const Icon(Icons.local_fire_department_rounded, color: Colors.white, size: 30),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('🔥 عرض نار', style: AppTextStyle.text18BS().copyWith(color: AppColors.mainAppColor)),
                  const SizedBox(height: 3),
                  Text('اختيارات مميزة من منتجات فسخانستا', style: AppTextStyle.text12RS().copyWith(color: Colors.white)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildCategories(RestaurantsController controller) {
    return List.generate(controller.productsRestaurant.length, (index) {
      final category = controller.productsRestaurant[index];
      return Padding(
        key: _categoryKeys[index],
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(category.categoryName ?? '',
                    style: AppTextStyle.text18BS()),
                Text('عرض الكل',
                    style: AppTextStyle.text12BS()
                        .copyWith(color: AppColors.mainAppColor)),
              ],
            ),
            const SizedBox(height: 12),
            LayoutBuilder(
              builder: (context, constraints) {
                final cardWidth = (constraints.maxWidth - 10) / 2;
                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: category.resturantItems?.length ?? 0,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    mainAxisExtent: _productCardHeight(cardWidth),
                  ),
                  itemBuilder: (context, itemIndex) {
                    final item = category.resturantItems![itemIndex];
                    return _gridProductCard(item);
                  },
                );
              },
            ),
          ],
        ),
      );
    });
  }

  Widget _gridProductCard(ResturantItems item) {
    final available = item.status == 'show';
    return MenuProductCard(
      name: item.productName ?? '',
      priceLabel: available
          ? '${item.productPrice?.toStringAsFixed(0) ?? '-'} ج'
          : 'غير متاح',
      image: CustomNetworkImage(
        imageUrl: item.productImage ?? '',
        radius: 0,
        fit: BoxFit.cover,
      ),
      draw: item.draw,
      available: available,
      highestRated: item.highestRated == 'yes',
      onTap: () {
        if (!available) {
          CommonMethods.showError(message: 'productNotAvailable'.tr);
          return;
        }
        _openProduct(item.id ?? 0);
      },
    );
  }

  void _openProduct(int id) {
    if (id == 0) return;
    NamedNavigatorImpl.push(
      ProductDetailsScreen.routeName,
      arguments: ProductDetailsDetailsArgs(
        onSuccessAddItem: widget.args.onSuccessAddItem,
        id: id,
      ),
    );
  }

  Widget _buildPreviousOrders(RestaurantsController controller) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('المنتجات المطلوبة مسبقاً', style: AppTextStyle.text18BS()),
          const SizedBox(height: 10),
          const PreviousOrdersListViewWidget(),
        ],
      ),
    );
  }

  Widget _buildChoicesAccordingToYourTaste(RestaurantsController controller) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('choicesAccordingToYourTaste'.tr, style: AppTextStyle.text18BS()),
          const SizedBox(height: 8),
          const ChoicesAccordingToYourTasteWidget(),
        ],
      ),
    );
  }

  Widget _buildCartBar() {
    return Consumer<CartController>(
      builder: (context, cartController, _) {
        final cart = cartController.cart;
        final hasItems = cart?.carts?.isNotEmpty ?? false;
        if (!hasItems) return const SizedBox.shrink();

        return SafeArea(
          top: false,
          child: Container(
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            constraints: const BoxConstraints.tightFor(height: 64),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.whiteColor,
              borderRadius: BorderRadius.circular(18),
              boxShadow: const [BoxShadow(blurRadius: 18, color: Color(0x22000000), offset: Offset(0, 5))],
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(color: AppColors.mainAppColor.withValues(alpha: .12), borderRadius: BorderRadius.circular(14)),
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Center(child: Icon(Icons.shopping_cart_outlined, color: AppColors.mainAppColor, size: 27)),
                      Positioned(
                        top: -4,
                        right: -4,
                        child: Container(
                          padding: const EdgeInsets.all(5),
                          decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                          child: Text('${cart?.carts?.length ?? 0}', style: AppTextStyle.text9BW()),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('السلة', style: AppTextStyle.text13BS()),
                      Text('${cart?.totalCart?.toString() ?? 0} ج', style: AppTextStyle.text16BS().copyWith(color: AppColors.mainAppColor)),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: () => NamedNavigatorImpl.push(CartScreen.routeName),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.mainAppColor,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text('عرض السلة'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
