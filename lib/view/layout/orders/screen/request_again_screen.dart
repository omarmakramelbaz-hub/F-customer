import 'package:faskhaninja/helpers/theme/fasakhansta_brand.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

import '../../../../helpers/extensions/extensions.dart';
import '../../../../helpers/hive/hive_methods.dart';
import '../../../../helpers/images/app_images.dart';
import '../../../../helpers/routes/app_routers_import.dart';
import '../../../../helpers/theme/app_colors.dart';
import '../../../../helpers/theme/app_text_style.dart';
import '../../../../helpers/translation/all_translation.dart';
import '../../../../helpers/utils/common_methods.dart';
import '../../../custom_widgets/api_response_widget/api_response_widget.dart';
import '../../../custom_widgets/buttons/custom_button.dart';
import '../../../custom_widgets/custom_image/custom_network_image.dart';
import '../../../custom_widgets/page_container/page_container.dart';
import '../../cart/controller/cart_controller.dart';
import '../../cart/screen/cart_screen.dart';
import '../../my_account/account_app_bar/account_app_bar.dart';
import '../controller/orders_controller.dart';
import '../widgets/reorder_in_cart_widget.dart';

class RequestAgainArgs {
  final int id;
  RequestAgainArgs({required this.id});
}

class RequestAgainScreen extends StatelessWidget {
  final RequestAgainArgs args;
  static const routeName = 'RequestAgainScreen';

  const RequestAgainScreen({super.key, required this.args});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (BuildContext context) => OrdersController()
        ..initialDetailsOrders()
        ..getDetailsOrders(id: args.id),
      child: Consumer<OrdersController>(
        builder: (context, ordersController, _) {
          final visibleItems = ordersController.detailsOrders?.items
              ?.where((item) => item.restaurantProduct?.status != 'hide')
              .toList();
          final inVisibleItems = ordersController.detailsOrders?.items
              ?.where((item) => item.restaurantProduct?.status == 'hide')
              .toList();
          return Container(
            color: FasakhanstaBrand.surface,
            child: ApiResponseWidget(
              apiResponse: ordersController.detailsOrdersApiResponse,
              onReload: () => ordersController.getDetailsOrders(id: args.id),
              isEmpty: ordersController.detailsOrders == null,
              child: Scaffold(
                body: PageContainer(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 35),
                      CustomAccountAppBar(
                        title: 'requestAgain'.tr,
                        actions: HiveMethods.getToken() != null
                            ? Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                ),
                                child: CircleAvatar(
                                  radius: 20,
                                  backgroundColor: AppColors.mainAppColor,
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
                                            radius: 8,
                                            backgroundColor:
                                                AppColors.darkMainAppColor,
                                            child: Text(
                                              context
                                                      .watch<CartController>()
                                                      .cart
                                                      ?.carts
                                                      ?.length
                                                      .toString() ??
                                                  '0',
                                              style: AppTextStyle.text16BW()
                                                  .copyWith(
                                                    height: 1.4,
                                                    fontSize: 14,
                                                    color:
                                                        FasakhanstaBrand.text,
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
                      ),
                      const SizedBox(height: 35),
                      Expanded(
                        child: Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: FasakhanstaBrand.surface,
                            borderRadius: const BorderRadius.only(
                              topRight: Radius.circular(36),
                              topLeft: Radius.circular(36),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.greyColor.withValues(
                                  alpha: .2,
                                ),
                                blurRadius: 10,
                                offset: const Offset(0, -3),
                              ),
                            ],
                          ),
                          child: SingleChildScrollView(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 19),
                                Center(
                                  child: CircleAvatar(
                                    radius: 60,
                                    backgroundColor: FasakhanstaBrand.surface,
                                    child: CustomNetworkImage(
                                      imageUrl:
                                          ordersController
                                              .detailsOrders
                                              ?.resturantLogo ??
                                          '',
                                      radius: 60,
                                    ),
                                  ),
                                ),
                                15.sbH,
                                Center(
                                  child: Text(
                                    ordersController
                                            .detailsOrders
                                            ?.resturantName ??
                                        '',
                                    style: AppTextStyle.text18BS(),
                                  ),
                                ),
                                15.sbH,
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      'requestCode'.tr,
                                      style: AppTextStyle.text14RS(),
                                    ),
                                    const SizedBox(width: 5),
                                    Text(':', style: AppTextStyle.text18RS()),
                                    const SizedBox(width: 5),
                                    Text(
                                      ordersController.detailsOrders?.orderNo ??
                                          '',
                                      style: AppTextStyle.text14RS(),
                                    ),
                                  ],
                                ),
                                15.sbH,
                                ...List.generate(visibleItems?.length ?? 0, (
                                  index,
                                ) {
                                  return ReorderInCartWidget(
                                    item: visibleItems?[index],
                                    index: index,
                                  );
                                }),
                                ...List.generate(inVisibleItems?.length ?? 0, (
                                  index,
                                ) {
                                  return ReorderInCartWidget(
                                    item: inVisibleItems?[index],
                                    index: index,
                                  );
                                }),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                bottomNavigationBar: visibleItems?.isNotEmpty == true
                    ? Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 21,
                          vertical: 16,
                        ),
                        child: CustomButton(
                          onPressed: () {
                            if (ordersController
                                    .detailsOrders
                                    ?.resturantStatus !=
                                'opened') {
                              CommonMethods.showToast(
                                message: 'restaurantClosedOrBusy'.tr,
                              );
                            } else {
                              ordersController.addReorderToCart(
                                productId: ordersController.productId,
                                productFeatureId:
                                    ordersController.productFeatureId,
                                productClean: ordersController.productClean,
                                productQuantity:
                                    ordersController.productQuantity,
                              );
                            }
                          },
                          text: 'addToCart'.tr,
                        ),
                      )
                    : const SizedBox(),
              ),
            ),
          );
        },
      ),
    );
  }
}
