import 'package:faskhaninja/helpers/theme/fasakhansta_brand.dart';

import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

import '../../../../helpers/hive/hive_methods.dart';
import '../../../../helpers/images/app_images.dart';
import '../../../../helpers/routes/app_routers_import.dart';
import '../../../../helpers/theme/app_colors.dart';
import '../../../../helpers/theme/app_text_style.dart';
import '../../../../helpers/translation/all_translation.dart';
import '../../../custom_widgets/api_response_widget/api_response_widget.dart';
import '../../../custom_widgets/custom_image/custom_network_image.dart';
import '../controller/cart_controller.dart';
import '../widgets/custom_update_item_cart_button.dart';
import 'cart_screen.dart';

class ProductInCartDetailsDetailsArgs {
  final int id;
  final int cartItemId;
  final VoidCallback? onSuccessAddItem;
  const ProductInCartDetailsDetailsArgs({
    required this.id,
    required this.cartItemId,
    this.onSuccessAddItem,
  });
}

class ProductInCartDetailsScreen extends StatefulWidget {
  final ProductInCartDetailsDetailsArgs args;
  static const String routeName = 'ProductInCartDetailsScreen';
  const ProductInCartDetailsScreen({super.key, required this.args});

  @override
  State<ProductInCartDetailsScreen> createState() =>
      _ProductInCartDetailsScreenState();
}

class _ProductInCartDetailsScreenState
    extends State<ProductInCartDetailsScreen> {
  int? _selectedRadio;
  int? _chooseQuantity;
  String? productFeature;
  int? productFeatureId;
  int? quantity;
  int? productQuantity;

  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      context.read<CartController>().initialCartItemDetails();
      context
          .read<CartController>()
          .getCartItemDetails(id: widget.args.cartItemId)
          .then((v) {
        productQuantity =
            context.read<CartController>().cartItemDetails?.qty ?? 1;
        productFeatureId =
            context.read<CartController>().cartItemDetails?.productFeature;
        productFeature = context
                .read<CartController>()
                .cartItemDetails
                ?.productFeatureName ??
            '';
        _chooseQuantity = getProductFeatureNameValueIndex(
              (context
                  .read<CartController>()
                  .cartItemDetails
                  ?.productFeatureName),
            ) ??
            0;
        quantity = getProductQuantity(
              (context
                  .read<CartController>()
                  .cartItemDetails
                  ?.productFeatureName),
            ) ??
            1;

        _selectedRadio = selectedRadio(
              (context.read<CartController>().cartItemDetails?.productClean ??
                  ''),
            ) ??
            0;
      });
      setState(() {});
    });

    super.initState();
  }

  // final List<String> _options = [
  //   'full'.tr,
  //   'clean'.tr,
  //   'clear'.tr
  // ];
  @override
  Widget build(BuildContext context) {
    return Consumer<CartController>(
      builder: (BuildContext context, cartController, _) {
        final dynamic defaultFeature;
        if (cartController.cartItemDetails?.resturantProduct?.features?.any(
              (e) => e.name == 'kilo',
            ) ==
            true) {
          defaultFeature = cartController
              .cartItemDetails?.resturantProduct?.features
              ?.firstWhere((e) => e.name == 'kilo')
              .id;
        } else if (cartController.cartItemDetails?.resturantProduct?.features
                ?.any((e) => e.name == 'large') ==
            true) {
          defaultFeature = cartController
              .cartItemDetails?.resturantProduct?.features
              ?.firstWhere((e) => e.name == 'large')
              .id;
        } else {
          defaultFeature = null;
        }

        return Scaffold(
          body: ApiResponseWidget(
            apiResponse: cartController.cartItemDetailsApiResponse,
            onReload: () =>
                cartController.getCartItemDetails(id: widget.args.cartItemId),
            isEmpty: cartController.cartItemDetails == null,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Stack(
                    children: [
                      ClipRRect(
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(20),
                          bottomRight: Radius.circular(20),
                        ),
                        child: CustomNetworkImage(
                          imageUrl: cartController.cartItemDetails
                                  ?.resturantProduct?.productImage ??
                              '',
                          height: 200,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Positioned(
                        top: 45,
                        right: 20,
                        child: InkWell(
                          onTap: () {
                            Navigator.pop(context);
                          },
                          child: CircleAvatar(
                            radius: 20,
                            backgroundColor: FasakhanstaBrand.surface,
                            child: Center(
                              child: SvgPicture.asset(
                                AppImages.backIosIcon,
                                colorFilter: ColorFilter.mode(
                                  AppColors.yellowColor,
                                  BlendMode.srcIn,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      HiveMethods.getToken() != null
                          ? Positioned(
                              top: 45,
                              left: 20,
                              child: CircleAvatar(
                                radius: 20,
                                backgroundColor: FasakhanstaBrand.surface,
                                child: InkWell(
                                  onTap: () => NamedNavigatorImpl.push(
                                    CartScreen.routeName,
                                  ),
                                  child: Stack(
                                    clipBehavior: Clip.none,
                                    children: [
                                      SvgPicture.asset(AppImages.nCartIcon),
                                      Positioned(
                                        bottom: 0,
                                        right: -2,
                                        child: CircleAvatar(
                                          radius: 20,
                                          backgroundColor:
                                              AppColors.mainAppColor,
                                          child: InkWell(
                                            onTap: () =>
                                                NamedNavigatorImpl.push(
                                              CartScreen.routeName,
                                            ),
                                            child: Stack(
                                              clipBehavior: Clip.none,
                                              children: [
                                                SvgPicture.asset(
                                                  AppImages.nCartIcon,
                                                ),
                                                Positioned(
                                                  bottom: 0,
                                                  right: -2,
                                                  child: CircleAvatar(
                                                    radius: 8,
                                                    backgroundColor: AppColors
                                                        .darkMainAppColor,
                                                    child: Text(
                                                      context
                                                              .watch<
                                                                  CartController>()
                                                              .cart
                                                              ?.carts
                                                              ?.length
                                                              .toString() ??
                                                          '0',
                                                      style: AppTextStyle
                                                              .text16BW()
                                                          .copyWith(
                                                        height: 1.4,
                                                        fontSize: 14,
                                                        color: FasakhanstaBrand
                                                            .text,
                                                      ),
                                                    ),
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
                              ),
                            )
                          : const SizedBox(),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          cartController.cartItemDetails?.resturantProduct
                                  ?.productName ??
                              '',
                          style: AppTextStyle.text18BS(),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          cartController.cartItemDetails?.resturantProduct
                                  ?.productDescription ??
                              '',
                          textAlign: TextAlign.justify,
                          style: AppTextStyle.text14RS().copyWith(height: 1.5),
                        ),

                        //============================================ Quantity Column =================================
                        (cartController.cartItemDetails?.resturantProduct
                                            ?.features?.isEmpty !=
                                        true &&
                                    cartController.cartItemDetails
                                            ?.resturantProduct?.features
                                            ?.any((e) => e.name == 'kilo') ==
                                        true ||
                                cartController.cartItemDetails?.resturantProduct
                                        ?.features
                                        ?.any((e) => e.name == 'half') ==
                                    true ||
                                cartController.cartItemDetails?.resturantProduct
                                        ?.features
                                        ?.any((e) => e.name == 'quarter') ==
                                    true)
                            ? Column(
                                children: [
                                  const SizedBox(height: 40),
                                  Row(
                                    children: [
                                      Text(
                                        'chooseQuantity'.tr,
                                        style: AppTextStyle.text16BS(),
                                      ),
                                      const Spacer(),
                                      Text(
                                        '${'required'.tr}*',
                                        style: AppTextStyle.text14RS().copyWith(
                                          color: AppColors.yellowColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 24),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceEvenly,
                                    children: [
                                      ...List.generate(
                                        cartController
                                                .cartItemDetails
                                                ?.resturantProduct
                                                ?.features
                                                ?.length ??
                                            0,
                                        (index) => InkWell(
                                          onTap: () {
                                            setState(() {
                                              _chooseQuantity = index;
                                              productFeatureId = cartController
                                                      .cartItemDetails
                                                      ?.resturantProduct
                                                      ?.features?[index]
                                                      .id ??
                                                  0;

                                              productFeature = cartController
                                                      .cartItemDetails
                                                      ?.resturantProduct
                                                      ?.features?[index]
                                                      .name ??
                                                  '';
                                              if (productFeature == 'kilo') {
                                                quantity = 1;
                                              } else if (productFeature ==
                                                  'half') {
                                                quantity = 2;
                                              } else if (productFeature ==
                                                  'quarter') {
                                                quantity = 4;
                                              }
                                            });

                                            log(quantity.toString());
                                          },
                                          child: Row(
                                            children: [
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                  horizontal: 18,
                                                  vertical: 8,
                                                ),
                                                height: 37,
                                                decoration: BoxDecoration(
                                                  color: _chooseQuantity ==
                                                          index
                                                      ? AppColors.mainAppColor
                                                      : FasakhanstaBrand
                                                          .surface,
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                  border: Border.all(
                                                    color: AppColors
                                                        .borderColorContainer,
                                                  ),
                                                ),
                                                child: Center(
                                                  child: Text(
                                                    cartController
                                                                .cartItemDetails
                                                                ?.resturantProduct
                                                                ?.features?[
                                                                    index]
                                                                .name ==
                                                            'kilo'
                                                        ? 'kilo'.tr
                                                        : cartController
                                                                    .cartItemDetails
                                                                    ?.resturantProduct
                                                                    ?.features?[
                                                                        index]
                                                                    .name ==
                                                                'half'
                                                            ? 'half'.tr
                                                            : cartController
                                                                        .cartItemDetails
                                                                        ?.resturantProduct
                                                                        ?.features?[
                                                                            index]
                                                                        .name ==
                                                                    'quarter'
                                                                ? 'quarter'.tr
                                                                : '',
                                                    style:
                                                        _chooseQuantity == index
                                                            ? AppTextStyle
                                                                    .text18MW()
                                                                .copyWith(
                                                                fontSize: 16,
                                                              )
                                                            : AppTextStyle
                                                                .text16MS(),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              )
                            : const SizedBox(),
                        const SizedBox(height: 40),

                        //============================================ Category Column =================================
                        Row(
                          children: [
                            Text(
                              'selectTheCategory'.tr,
                              style: AppTextStyle.text16BS(),
                            ),
                            const Spacer(),
                            Text(
                              '${'required'.tr}*',
                              style: AppTextStyle.text14RS().copyWith(
                                color: AppColors.yellowColor,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 22),
                        cartController.cartItemDetails?.resturantProduct
                                    ?.productPrice !=
                                0
                            ? Row(
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  Radio(
                                    activeColor: AppColors.yellowColor,
                                    value: 0,
                                    groupValue: _selectedRadio,
                                    onChanged: (value) {
                                      setState(() {
                                        _selectedRadio = value!;
                                      });
                                      context
                                          .read<CartController>()
                                          .totalCountAddTCart = null;
                                    },
                                  ),
                                  Text(
                                    'full'.tr,
                                    style: _selectedRadio == 0
                                        ? AppTextStyle.text16MS().copyWith(
                                            color: AppColors.yellowColor,
                                          )
                                        : AppTextStyle.text16MG(),
                                  ),
                                  const Spacer(),
                                  cartController.cartItemDetails
                                              ?.resturantProduct ==
                                          null
                                      ? const SizedBox()
                                      : Text(
                                          "${(int.tryParse(cartController.cartItemDetails?.resturantProduct?.productPrice.toString() ?? "0") ?? 0)}",
                                          style: _selectedRadio == 0
                                              ? AppTextStyle.text16MS()
                                              : AppTextStyle.text16MG(),
                                        ),
                                ],
                              )
                            : const SizedBox(),
                        Column(
                          children: [
                            cartController.cartItemDetails?.resturantProduct
                                        ?.extraClean !=
                                    0
                                ? Row(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    children: [
                                      Radio(
                                        activeColor: AppColors.yellowColor,
                                        value: 1,
                                        groupValue: _selectedRadio,
                                        onChanged: (value) {
                                          setState(() {
                                            _selectedRadio = value!;
                                          });
                                          context
                                              .read<CartController>()
                                              .totalCountAddTCart = null;
                                        },
                                      ),
                                      Text(
                                        'clean'.tr,
                                        style: _selectedRadio == 1
                                            ? AppTextStyle.text16MS().copyWith(
                                                color: AppColors.yellowColor,
                                              )
                                            : AppTextStyle.text16MG(),
                                      ),
                                      const Spacer(),
                                      cartController.cartItemDetails
                                                  ?.resturantProduct ==
                                              null
                                          ? const SizedBox()
                                          : Text(
                                              "${(int.tryParse(cartController.cartItemDetails?.resturantProduct?.extraClean?.toString() ?? "0") ?? 0) + (int.tryParse(cartController.cartItemDetails?.resturantProduct?.productPrice.toString() ?? "0") ?? 0)}",
                                              style: _selectedRadio == 1
                                                  ? AppTextStyle.text16MS()
                                                  : AppTextStyle.text16MG(),
                                            ),
                                    ],
                                  )
                                : const SizedBox(),
                            cartController.cartItemDetails?.resturantProduct
                                        ?.extraClear !=
                                    0
                                ? Row(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    children: [
                                      Radio(
                                        activeColor: AppColors.yellowColor,
                                        value: 2,
                                        groupValue: _selectedRadio,
                                        onChanged: (value) {
                                          setState(() {
                                            _selectedRadio = value!;
                                          });
                                          context
                                              .read<CartController>()
                                              .totalCountAddTCart = null;
                                        },
                                      ),
                                      Text(
                                        'clear'.tr,
                                        style: _selectedRadio == 2
                                            ? AppTextStyle.text16MS().copyWith(
                                                color: AppColors.yellowColor,
                                              )
                                            : AppTextStyle.text16MG(),
                                      ),
                                      const Spacer(),
                                      cartController.cartItemDetails
                                                  ?.resturantProduct ==
                                              null
                                          ? const SizedBox()
                                          : Text(
                                              "${(int.tryParse(cartController.cartItemDetails?.resturantProduct?.extraClear?.toString() ?? "0") ?? 0) + (int.tryParse(cartController.cartItemDetails?.resturantProduct?.productPrice.toString() ?? "0") ?? 0)}",
                                              style: _selectedRadio == 2
                                                  ? AppTextStyle.text16MS()
                                                  : AppTextStyle.text16MG(),
                                            ),
                                    ],
                                  )
                                : const SizedBox(),
                            cartController.cartItemDetails?.resturantProduct
                                        ?.extraLarge !=
                                    0
                                ? Row(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    children: [
                                      Radio(
                                        activeColor: AppColors.yellowColor,
                                        value: 3,
                                        groupValue: _selectedRadio,
                                        onChanged: (value) {
                                          setState(() {
                                            _selectedRadio = value!;
                                          });
                                          context
                                              .read<CartController>()
                                              .totalCountAddTCart = null;
                                          if (cartController.cartItemDetails
                                                  ?.resturantProduct?.features
                                                  ?.any(
                                                (e) => e.name == 'large',
                                              ) ==
                                              true) {
                                            productFeatureId = cartController
                                                .cartItemDetails
                                                ?.resturantProduct
                                                ?.features
                                                ?.firstWhere(
                                                  (e) => e.name == 'large',
                                                )
                                                .id;
                                          }
                                        },
                                      ),
                                      Text(
                                        'large'.tr,
                                        style: _selectedRadio == 3
                                            ? AppTextStyle.text16MS().copyWith(
                                                color: AppColors.yellowColor,
                                              )
                                            : AppTextStyle.text16MG(),
                                      ),
                                      const Spacer(),
                                      cartController.cartItemDetails
                                                  ?.resturantProduct ==
                                              null
                                          ? const SizedBox()
                                          : Text(
                                              "${(int.tryParse(cartController.cartItemDetails?.resturantProduct?.extraLarge?.toString() ?? "0") ?? 0) + (int.tryParse(cartController.cartItemDetails?.resturantProduct?.productPrice.toString() ?? "0") ?? 0)}",
                                              style: _selectedRadio == 3
                                                  ? AppTextStyle.text16MS()
                                                  : AppTextStyle.text16MG(),
                                            ),
                                    ],
                                  )
                                : const SizedBox(),
                            cartController.cartItemDetails?.resturantProduct
                                        ?.extraMedium !=
                                    0
                                ? Row(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    children: [
                                      Radio(
                                        activeColor: AppColors.yellowColor,
                                        value: 4,
                                        groupValue: _selectedRadio,
                                        onChanged: (value) {
                                          setState(() {
                                            _selectedRadio = value!;
                                          });
                                          context
                                              .read<CartController>()
                                              .totalCountAddTCart = null;
                                          if (cartController.cartItemDetails
                                                  ?.resturantProduct?.features
                                                  ?.any(
                                                (e) => e.name == 'medium',
                                              ) ==
                                              true) {
                                            productFeatureId = cartController
                                                .cartItemDetails
                                                ?.resturantProduct
                                                ?.features
                                                ?.firstWhere(
                                                  (e) => e.name == 'medium',
                                                )
                                                .id;
                                          }
                                        },
                                      ),
                                      Text(
                                        'medium'.tr,
                                        style: _selectedRadio == 4
                                            ? AppTextStyle.text16MS().copyWith(
                                                color: AppColors.yellowColor,
                                              )
                                            : AppTextStyle.text16MG(),
                                      ),
                                      const Spacer(),
                                      cartController.cartItemDetails
                                                  ?.resturantProduct ==
                                              null
                                          ? const SizedBox()
                                          : Text(
                                              "${(int.tryParse(cartController.cartItemDetails?.resturantProduct?.extraMedium?.toString() ?? "0") ?? 0) + (int.tryParse(cartController.cartItemDetails?.resturantProduct?.productPrice.toString() ?? "0") ?? 0)}",
                                              style: _selectedRadio == 4
                                                  ? AppTextStyle.text16MS()
                                                  : AppTextStyle.text16MG(),
                                            ),
                                    ],
                                  )
                                : const SizedBox(),
                            cartController.cartItemDetails?.resturantProduct
                                        ?.extraVacuim !=
                                    0
                                ? Row(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    children: [
                                      Radio(
                                        activeColor: AppColors.yellowColor,
                                        value: 5,
                                        groupValue: _selectedRadio,
                                        onChanged: (value) {
                                          setState(() {
                                            _selectedRadio = value!;
                                          });
                                          context
                                              .read<CartController>()
                                              .totalCountAddTCart = null;
                                          if (cartController.cartItemDetails
                                                  ?.resturantProduct?.features
                                                  ?.any(
                                                (e) => e.name == 'vacuim',
                                              ) ==
                                              true) {
                                            productFeatureId = cartController
                                                .cartItemDetails
                                                ?.resturantProduct
                                                ?.features
                                                ?.firstWhere(
                                                  (e) => e.name == 'vacuim',
                                                )
                                                .id;
                                          }
                                        },
                                      ),
                                      Text(
                                        'vacuum'.tr,
                                        style: _selectedRadio == 5
                                            ? AppTextStyle.text16MS().copyWith(
                                                color: AppColors.yellowColor,
                                              )
                                            : AppTextStyle.text16MG(),
                                      ),
                                      const Spacer(),
                                      cartController.cartItemDetails
                                                  ?.resturantProduct ==
                                              null
                                          ? const SizedBox()
                                          : Text(
                                              "${(int.tryParse(cartController.cartItemDetails?.resturantProduct?.extraVacuim?.toString() ?? "0") ?? 0) + (int.tryParse(cartController.cartItemDetails?.resturantProduct?.productPrice.toString() ?? "0") ?? 0)}",
                                              style: _selectedRadio == 5
                                                  ? AppTextStyle.text16MS()
                                                  : AppTextStyle.text16MG(),
                                            ),
                                    ],
                                  )
                                : const SizedBox(),
                            cartController.cartItemDetails?.resturantProduct
                                        ?.extraCombo !=
                                    0
                                ? Row(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    children: [
                                      Radio(
                                        activeColor: AppColors.yellowColor,
                                        value: 6,
                                        groupValue: _selectedRadio,
                                        onChanged: (value) {
                                          setState(() {
                                            _selectedRadio = value!;
                                          });
                                          context
                                              .read<CartController>()
                                              .totalCountAddTCart = null;
                                          if (cartController.cartItemDetails
                                                  ?.resturantProduct?.features
                                                  ?.any(
                                                (e) => e.name == 'combo',
                                              ) ==
                                              true) {
                                            productFeatureId = cartController
                                                .cartItemDetails
                                                ?.resturantProduct
                                                ?.features
                                                ?.firstWhere(
                                                  (e) => e.name == 'combo',
                                                )
                                                .id;
                                          }
                                        },
                                      ),
                                      Text(
                                        'combo'.tr,
                                        style: _selectedRadio == 6
                                            ? AppTextStyle.text16MS().copyWith(
                                                color: AppColors.yellowColor,
                                              )
                                            : AppTextStyle.text16MG(),
                                      ),
                                      const Spacer(),
                                      cartController.cartItemDetails
                                                  ?.resturantProduct ==
                                              null
                                          ? const SizedBox()
                                          : Text(
                                              "${(int.tryParse(cartController.cartItemDetails?.resturantProduct?.extraCombo?.toString() ?? "0") ?? 0) + (int.tryParse(cartController.cartItemDetails?.resturantProduct?.productPrice.toString() ?? "0") ?? 0)}",
                                              style: _selectedRadio == 6
                                                  ? AppTextStyle.text16MS()
                                                  : AppTextStyle.text16MG(),
                                            ),
                                    ],
                                  )
                                : const SizedBox(),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          bottomNavigationBar: ApiResponseWidget(
            loadingWidget: const SizedBox(),
            apiResponse: cartController.cartItemDetailsApiResponse,
            onReload: () =>
                cartController.getCartItemDetails(id: widget.args.cartItemId),
            isEmpty: cartController.cartItemDetails == null,
            child: CustomCartItemButtonBottomNavigation(
              productPrice: cartController
                      .cartItemDetails?.resturantProduct?.productPrice ??
                  0,
              cartId: widget.args.cartItemId,
              featureId: productFeatureId ?? defaultFeature,
              qty: quantity ?? 1,
              quantity: productQuantity ?? 1,
              onSuccessAddItems: () {
                Navigator.pop(context);
                context.read<CartController>().getCart();
              },
              restaurantProductId:
                  cartController.cartItemDetails?.resturantProduct?.id ?? 0,
              productFeature: productFeature ?? '',
              productClean: _selectedRadio == 0
                  ? null
                  : getProductClean(_selectedRadio ?? 0),

              //  _selectedRadio == 1
              //     ? "extra_clean"
              //     : _selectedRadio == 2
              //         ? "extra_clear"
              //         : _selectedRadio==3?'extra_vacuim':null,
              total: _selectedRadio == 0
                  ? cartController
                          .cartItemDetails?.resturantProduct?.productPrice
                          .toString() ??
                      ''
                  : _selectedRadio == 1
                      ? '${(((cartController.cartItemDetails?.resturantProduct?.productPrice ?? 0) + (cartController.cartItemDetails?.resturantProduct?.extraClean ?? 0)))}'
                      : _selectedRadio == 2
                          ? '${(((cartController.cartItemDetails?.resturantProduct?.productPrice ?? 0) + (cartController.cartItemDetails?.resturantProduct?.extraClear ?? 0)))}'
                          : _selectedRadio == 3
                              ? '${(((cartController.cartItemDetails?.resturantProduct?.productPrice ?? 0) + (cartController.cartItemDetails?.resturantProduct?.extraLarge ?? 0)))}'
                              : _selectedRadio == 4
                                  ? '${(((cartController.cartItemDetails?.resturantProduct?.productPrice ?? 0) + (cartController.cartItemDetails?.resturantProduct?.extraMedium ?? 0)))}'
                                  : _selectedRadio == 5
                                      ? '${(((cartController.cartItemDetails?.resturantProduct?.productPrice ?? 0) + (cartController.cartItemDetails?.resturantProduct?.extraVacuim ?? 0)))}'
                                      : _selectedRadio == 6
                                          ? '${(((cartController.cartItemDetails?.resturantProduct?.productPrice ?? 0) + (cartController.cartItemDetails?.resturantProduct?.extraCombo ?? 0)))}'
                                          : cartController
                                                  .cartItemDetails
                                                  ?.resturantProduct
                                                  ?.productPrice
                                                  .toString() ??
                                              '',
            ),
          ),
        );
      },
    );
  }

  String? getProductClean(int selectRadio) {
    switch (selectRadio) {
      case 1:
        return 'extra_clean';
      case 2:
        return 'extra_clear';
      case 3:
        return 'extra_large';
      case 4:
        return 'extra_medium';
      case 5:
        return 'extra_vacuim';
      case 6:
        return 'extra_combo';
      default:
        return null;
    }
  }

  int? selectedRadio(String productClean) {
    switch (productClean) {
      case 'extra_clean':
        return 1;
      case 'extra_clear':
        return 2;
      case 'extra_large':
        return 3;
      case 'extra_medium':
        return 4;
      case 'extra_vacuim':
        return 5;
      case 'extra_combo':
        return 6;
      default:
        return 0;
    }
  }

  int? getProductFeatureNameValueIndex(String? productFeatureName) {
    switch (productFeatureName) {
      case 'kilo':
        return 0;
      case 'half':
        return 1;
      case 'quarter':
        return 2;
      default:
        return 0;
    }
  }

  int? getProductQuantity(String? productFeatureName) {
    switch (productFeatureName) {
      case 'kilo':
        return 1;
      case 'half':
        return 2;
      case 'quarter':
        return 4;
      default:
        return 1;
    }
  }
}
