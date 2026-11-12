import 'package:faskhaninja/helpers/theme/fasakhansta_brand.dart';

import 'dart:convert';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
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
import '../../../../helpers/utils/utils.dart';
import '../../../custom_widgets/api_response_widget/api_response_widget.dart';
import '../../../custom_widgets/custom_image/custom_image.dart';
import '../../../custom_widgets/custom_image/custom_network_image.dart';
import '../../cart/controller/cart_controller.dart';
import '../../cart/screen/cart_screen.dart';
import '../../restaurants/controller/restaurants_controller.dart';
import '../../restaurants/model/details_restaurants_model.dart'
    as details_restaurant_model;
import '../../restaurants/model/highst_rated_model.dart';
import '../../restaurants/model/previous_order_model.dart';
import '../../restaurants/model/products_restaurant_model.dart';
import '../../restaurants/screen/product_details_screen.dart';
import '../../restaurants/widgets/another_home_hedar.dart';
import '../../restaurants/widgets/choices_according_to_your_taste_widget.dart';
import '../../restaurants/widgets/menu_bottom_sheet_widget.dart';
import '../../restaurants/widgets/previous_orders_list_view_widget.dart';

class AnotherHomeScreen extends StatefulWidget {
  static const String routeName = 'AnotherHomeScreen';
  const AnotherHomeScreen({super.key, required this.id});
  final int id;
  @override
  State<AnotherHomeScreen> createState() => _AnotherHomeScreenState();
}

class _AnotherHomeScreenState extends State<AnotherHomeScreen> {
  int currentIndex = 0;
  final ScrollController _verticalScrollController = ScrollController();
  final List<GlobalKey> _categoryKeys = [];
  late PusherController _pusherController; // Saved reference

  @override
  void initState() {
    _verticalScrollController.addListener(animateToTab);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<RestaurantsController>(
        context,
        listen: false,
      ).initialRestaurantsDetails();
      HiveMethods.getToken() != null
          ? Provider.of<RestaurantsController>(
              context,
              listen: false,
            ).initialPreviousOrder()
          : null;
      Provider.of<RestaurantsController>(
        context,
        listen: false,
      ).initialProductsRestaurant();
      Future.wait([
        Provider.of<RestaurantsController>(
          context,
          listen: false,
        ).getRestaurantsDetails(id: widget.id),
        Provider.of<RestaurantsController>(
          context,
          listen: false,
        ).getPreviousOrder(id: widget.id),
        Provider.of<RestaurantsController>(
          context,
          listen: false,
        ).getProductsRestaurant(id: widget.id),
      ]);
    });
    _pusherController = context.read<PusherController>();
    _pusherController.addEventListener(
      'product.updated',
      _handleProductUpdated,
    );
    _pusherController.addEventListener(
      'product.updated',
      _handlePreviousProductUpdated,
    );
    _pusherController.addEventListener(
      'product.updated',
      _handleHightsRatedUpdated,
    );
    _pusherController.addEventListener(
      'resturant.updated',
      _handleResturantUpdated,
    );
    super.initState();
  }

  void _handleProductUpdated(PusherEvent event) {
    try {
      final decodedData = json.decode(event.data) as Map<String, dynamic>;
      final resturantData = decodedData['product'];

      if (mounted) {
        final resturantModel = ResturantItems.fromJson(
          resturantData as Map<String, dynamic>,
        );
        context.read<RestaurantsController>().updateResturantProductOrder(
              resturantModel,
            );
        log('=================== update resturant product');
      }
    } catch (e, stackTrace) {
      log('Error handling Pusher event: $e');
      log('Stack trace: $stackTrace');
    }
  }

  void _handleHightsRatedUpdated(PusherEvent event) {
    try {
      final decodedData = json.decode(event.data) as Map<String, dynamic>;
      final resturantData = decodedData['product'];

      if (mounted) {
        final resturantModel = HighestRated.fromJson(
          resturantData as Map<String, dynamic>,
        );
        context
            .read<RestaurantsController>()
            .updateAccordingToYourTasteResturantProductOrder(resturantModel);
        log('=================== update resturant product');
      }
    } catch (e, stackTrace) {
      log('Error handling Pusher event: $e');
      log('Stack trace: $stackTrace');
    }
  }

  void _handlePreviousProductUpdated(PusherEvent event) {
    try {
      final decodedData = json.decode(event.data) as Map<String, dynamic>;
      final resturantData = decodedData['product'];

      if (mounted) {
        final resturantModel = PreviousOrderModel.fromJson(
          resturantData as Map<String, dynamic>,
        );
        context
            .read<RestaurantsController>()
            .updateResturantPreviousProductOrder(resturantModel);
        log('=================== update previous product');
      }
    } catch (e, stackTrace) {
      log('Error handling Pusher event: $e');
      log('Stack trace: $stackTrace');
    }
  }

  void _handleResturantUpdated(PusherEvent event) {
    try {
      final decodedData = json.decode(event.data) as Map<String, dynamic>;
      final resturantData = decodedData['resturant'];

      if (mounted) {
        final resturantModel =
            details_restaurant_model.DetailsRestaurantModel.fromJson(
          resturantData as Map<String, dynamic>,
        );
        context.read<RestaurantsController>().updateResturantDetails(
              resturantModel,
            );
        // context.read<HomeController>().updateSpacialResturant(resturantModel);
      }
    } catch (e, stackTrace) {
      log('Error handling Pusher event: $e');
      log('Stack trace: $stackTrace');
    }
  }

  @override
  void dispose() {
    _pusherController.removeEventListener(
      'product.updated',
      _handleResturantUpdated,
    );
    _verticalScrollController.dispose();
    super.dispose();
  }

  void _scrollToCategory(int index) {
    final keyContext = _categoryKeys[index].currentContext;
    if (keyContext != null) {
      Scrollable.ensureVisible(
        keyContext,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    }
  }

  void _scrollToTop() {
    _verticalScrollController.animateTo(
      0.0,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
  }

  void _onBottomSheetSuccess(int index) {
    setState(() {
      currentIndex = index;
    });
    if (index == -1) {
      _scrollToTop();
    } else {
      _scrollToCategory(index);
    }
  }

  void animateToTab() {
    if (_verticalScrollController.offset == 0) {
      setState(() {
        currentIndex = 0;
      });
    } else {
      for (var i = 0; i < _categoryKeys.length; i++) {
        final box =
            _categoryKeys[i].currentContext!.findRenderObject() as RenderBox;
        final position = box.localToGlobal(Offset.zero);

        if (_verticalScrollController.offset >= position.dy) {
          setState(() {
            currentIndex = i;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<RestaurantsController>(
      builder: (BuildContext context, restaurantsController, _) {
        _categoryKeys.clear();
        _categoryKeys.addAll(
          List.generate(
            restaurantsController.productsRestaurant.length,
            (index) => GlobalKey(),
          ),
        );

        final cartController = context.read<CartController>();
        return Container(
          color: FasakhanstaBrand.surface,
          child: ApiResponseWidget(
            apiResponse: restaurantsController.restaurantsDetailsApiResponse,
            onReload: () {
              restaurantsController.getRestaurantsDetails(id: widget.id);
              restaurantsController.getProductsRestaurant(id: widget.id);
              restaurantsController.getPreviousOrder(id: widget.id);
            },
            isEmpty: restaurantsController.detailsRestaurant == null,
            child: Scaffold(
              body: SafeArea(
                child: ListView(
                  physics: const ClampingScrollPhysics(),
                  children: [
                    AnotherHomeHeaderCoverAndImageRestaurantDetailsWidget(
                      detailsRestaurant:
                          restaurantsController.detailsRestaurant,
                    ),
                    16.sbH,
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: CustomImage(
                        path: AppImages.bannerAnotherHome,
                        type: ImageType.asset,
                      ),
                    ),
                    15.sbH,
                    _buildTabs(context, restaurantsController),
                    32.sbH,
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        restaurantsController.previousOrders.isNotEmpty
                            ? _buildPreviousOrders(
                                context,
                                restaurantsController,
                              )
                            : const SizedBox.shrink(),
                        restaurantsController.detailsRestaurant?.highestRated
                                    ?.isNotEmpty ==
                                true
                            ? _buildChoicesAccordingToYourTaste(
                                context,
                                restaurantsController,
                              )
                            : const SizedBox.shrink(),
                        ..._buildCategories(context, restaurantsController),
                      ],
                    ),
                  ],
                ),
              ),
              bottomNavigationBar: (cartController.cart == null ||
                      (cartController.cart?.carts?.isEmpty ?? false))
                  ? Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'minOrderPrice'.tr.replaceAll(
                                  '{}',
                                  restaurantsController
                                          .detailsRestaurant?.minOrderPrice
                                          .toString() ??
                                      '',
                                ),
                            style: AppTextStyle.text16BS(),
                          ),
                        ],
                      ),
                    )
                  : Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 10,
                        horizontal: 20,
                      ),
                      child: Row(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: AppColors.darkMainAppColor,
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 15,
                                vertical: 13,
                              ),
                              child: Text(
                                cartController.cart?.carts?.length.toString() ??
                                    '0',
                                style: AppTextStyle.text16BS(),
                              ),
                            ),
                          ),
                          10.sbW,
                          Expanded(
                            child: InkWell(
                              onTap: () =>
                                  NamedNavigatorImpl.push(CartScreen.routeName),
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  color: AppColors.darkMainAppColor,
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 15,
                                    vertical: 13,
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        'showCart'.tr,
                                        style: AppTextStyle.text16BW(),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                          10.sbW,
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: AppColors.darkMainAppColor,
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 15,
                                vertical: 13,
                              ),
                              child: Text(
                                'egyp'.tr.replaceAll(
                                      '{}',
                                      cartController.cart?.totalCart
                                              .toString() ??
                                          '0',
                                    ),
                                style: AppTextStyle.text16BS(),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTabs(
    BuildContext context,
    RestaurantsController restaurantsController,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        16.sbW,
        InkWell(
          onTap: () {
            Utils.showAppBottomSheet(
              MenuBottomSheetWidget(
                products: restaurantsController.productsRestaurant,
                previousOrders: restaurantsController.previousOrders,
                onSuccess: _onBottomSheetSuccess,
                initialIndex: currentIndex + 1,
              ),
              enableDrag: true,
              isScrollControlled: true,
            );
          },
          child: SvgPicture.asset(AppImages.menuIcon),
        ),
        8.sbW,
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                restaurantsController.previousOrders.isNotEmpty
                    ? _buildTabItem(context, 'previousOrders'.tr, -2)
                    : const SizedBox.shrink(),
                8.sbW,
                restaurantsController
                            .detailsRestaurant?.highestRated?.isNotEmpty ==
                        true
                    ? _buildTabItem(
                        context,
                        'choicesAccordingToYourTaste'.tr,
                        -1,
                      )
                    : const SizedBox.shrink(),
                ...List.generate(
                  restaurantsController.productsRestaurant.length,
                  (index) => Padding(
                    padding: const EdgeInsets.only(right: 16),
                    child: _buildTabItem(
                      context,
                      restaurantsController
                              .productsRestaurant[index].categoryName ??
                          '',
                      index,
                    ),
                  ),
                ),
                16.sbW,
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTabItem(BuildContext context, String title, int index) {
    return GestureDetector(
      onTap: () {
        setState(() {
          currentIndex = index;
        });
        if (index == -1) {
          _scrollToTop();
        } else {
          _scrollToCategory(index);
        }
      },
      child: Column(
        children: [
          Text(
            title,
            style: currentIndex == index
                ? AppTextStyle.text16BM()
                : AppTextStyle.text16MG(),
          ),
          5.sbH,
          Container(
            height: 5,
            width: 100,
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(7),
                topRight: Radius.circular(7),
              ),
              color: currentIndex == index
                  ? AppColors.mainAppColor
                  : Colors.transparent,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreviousOrders(
    BuildContext context,
    RestaurantsController restaurantsController,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text('previousOrders'.tr, style: AppTextStyle.text18BS()),
        ),
        10.sbH,
        if (restaurantsController.previousOrders.isNotEmpty)
          const PreviousOrdersListViewWidget()
        else
          Center(
            child: Text(
              'thereAreNoPreviousRequests'.tr,
              style: AppTextStyle.text16RS(),
            ),
          ),
        22.sbH,
      ],
    );
  }

  Widget _buildChoicesAccordingToYourTaste(
    BuildContext context,
    RestaurantsController restaurantsController,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            'choicesAccordingToYourTaste'.tr,
            style: AppTextStyle.text18BS(),
          ),
        ),
        if (restaurantsController.detailsRestaurant?.highestRated?.isNotEmpty ==
            true)
          const ChoicesAccordingToYourTasteWidget()
        else
          const SizedBox.shrink(),
        22.sbH,
      ],
    );
  }

  List<Widget> _buildCategories(
    BuildContext context,
    RestaurantsController restaurantsController,
  ) {
    return List.generate(
      restaurantsController.productsRestaurant.length,
      (index) => Padding(
        key: _categoryKeys[index],
        padding: const EdgeInsets.only(right: 20, left: 20, bottom: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              restaurantsController.productsRestaurant[index].categoryName ??
                  '',
              style: AppTextStyle.text18BS(),
            ),
            16.sbH,
            ...List.generate(
              restaurantsController
                      .productsRestaurant[index].resturantItems?.length ??
                  0,
              (indexRestaurantItems) => InkWell(
                onTap: () {
                  if (restaurantsController.detailsRestaurant?.status ==
                      'closed') {
                    CommonMethods.showError(
                      message: 'thisRestaurantIsClosed'.tr,
                    );
                  } else {
                    if (restaurantsController.productsRestaurant[index]
                            .resturantItems?[indexRestaurantItems].status ==
                        'show') {
                      NamedNavigatorImpl.push(
                        ProductDetailsScreen.routeName,
                        arguments: ProductDetailsDetailsArgs(
                          onSuccessAddItem: () {},
                          id: restaurantsController.productsRestaurant[index]
                                  .resturantItems?[indexRestaurantItems].id ??
                              0,
                        ),
                      );
                    } else {
                      CommonMethods.showError(
                        message: 'productNotAvailable'.tr,
                      );
                    }
                  }
                },
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 36),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              restaurantsController
                                      .productsRestaurant[index]
                                      .resturantItems?[indexRestaurantItems]
                                      .productName ??
                                  '',
                              style: AppTextStyle.text18RS(),
                            ),
                            8.sbH,
                            if (restaurantsController
                                    .productsRestaurant[index]
                                    .resturantItems?[indexRestaurantItems]
                                    .highestRated ==
                                'yes')
                              Container(
                                decoration: BoxDecoration(
                                  color: AppColors.mainAppColor.withValues(
                                    alpha: 0.2,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const CustomImage(
                                        path: AppImages.starIcon,
                                        type: ImageType.svg,
                                      ),
                                      5.sbW,
                                      Text(
                                        'highestRate'.tr,
                                        style: AppTextStyle.text16BS().copyWith(
                                          color: AppColors.darkMainAppColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                            else
                              const SizedBox.shrink(),
                            8.sbH,
                            if (restaurantsController
                                    .productsRestaurant[index]
                                    .resturantItems?[indexRestaurantItems]
                                    .status ==
                                'show')
                              Text(
                                'pound'.tr.replaceAll(
                                      '{}',
                                      restaurantsController
                                              .productsRestaurant[index]
                                              .resturantItems?[
                                                  indexRestaurantItems]
                                              .productPrice
                                              ?.toStringAsFixed(2)
                                              .toString() ??
                                          '',
                                    ),
                                style: AppTextStyle.text16RG(),
                              )
                            else
                              Text(
                                'notAvailable'.tr,
                                style: AppTextStyle.text16RG(),
                              ),
                          ],
                        ),
                      ),
                      20.sbW,
                      Container(
                        height: 106,
                        width: 121,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: AppColors.mainAppColor.withValues(alpha: 0.15),
                        ),
                        child: CustomNetworkImage(
                          imageUrl: restaurantsController
                                  .productsRestaurant[index]
                                  .resturantItems?[indexRestaurantItems]
                                  .productImage
                                  .toString() ??
                              '',
                          radius: 12,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
