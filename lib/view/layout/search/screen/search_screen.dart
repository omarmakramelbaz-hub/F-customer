import 'package:faskhaninja/helpers/theme/fasakhansta_brand.dart';

import 'dart:convert';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:pusher_channels_flutter/pusher_channels_flutter.dart';

import '../../../../helpers/extensions/extensions.dart';
import '../../../../helpers/images/app_images.dart';
import '../../../../helpers/pusher_service/pusher_controller.dart';
import '../../../../helpers/routes/app_routers_import.dart';
import '../../../../helpers/theme/app_colors.dart';
import '../../../../helpers/theme/app_text_style.dart';
import '../../../../helpers/translation/all_translation.dart';
import '../../../custom_widgets/api_response_widget/api_response_widget.dart';
import '../../../custom_widgets/custom_app_bar/custom_app_bar.dart';
import '../../../custom_widgets/custom_form_field/custom_form_field.dart';
import '../../../custom_widgets/page_container/page_container.dart';
import '../../restaurants/controller/restaurants_controller.dart';
import '../../restaurants/model/restaurants_model.dart';
import '../../restaurants/widgets/all_restaurants_widget.dart';
import '../../restaurants/widgets/filtration_list_view_widget.dart';
import '../controller/search_controller.dart';

class SearchScreen extends StatefulWidget {
  static const String routeName = 'SearchScreen';
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _searchEc = TextEditingController();
  bool isSelected = false;
  late FocusNode searchFocusNode;
  late PusherController _pusherController; // Saved reference

  @override
  void initState() {
    _pusherController = context.read<PusherController>();
    _pusherController.addEventListener(
      'resturant.updated',
      _handleResturantUpdated,
    );
    super.initState();
    searchFocusNode = FocusNode();

    searchFocusNode.requestFocus();
  }

  void _handleResturantUpdated(PusherEvent event) {
    try {
      final decodedData = json.decode(event.data) as Map<String, dynamic>;
      final resturantData = decodedData['resturant'];

      if (mounted) {
        final resturantModel = RestaurantsModel.fromJson(
          resturantData as Map<String, dynamic>,
        );

        context.read<RestaurantsController>().updateResturant(resturantModel);
      }
    } catch (e, stackTrace) {
      log('Error handling Pusher event: $e');
      log('Stack trace: $stackTrace');
    }
  }

  @override
  void dispose() {
    _searchEc.dispose();
    searchFocusNode.dispose();
    _pusherController.removeEventListener(
      'resturant.updated',
      _handleResturantUpdated,
    );
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    String? search;
    return Consumer2<SearchRestaurantController, RestaurantsController>(
      builder: (context, searchController, restaurantController, _) {
        return Scaffold(
          extendBody: true,
          resizeToAvoidBottomInset: false,
          appBar: CustomAppBar(
            height: 50,
            leading: IconButton(
              icon: Icon(Icons.arrow_back_ios, color: FasakhanstaBrand.text),
              onPressed: () => NamedNavigatorImpl.pop(),
            ),
            title: Text('restaurants'.tr, style: AppTextStyle.text16BS()),
          ),
          body: GestureDetector(
            onTap: () => FocusScope.of(context).unfocus(),
            child: PageContainer(
              bottom: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        //  Text(
                        //         'deliveryTo'.tr,
                        //         style: AppTextStyle.text14RG(),
                        //       ),
                        //       const SizedBox(
                        //         height: 3,
                        //       ),
                        //       Row(
                        //         children: [
                        //           Text(
                        //             "المختلط",
                        //             style: AppTextStyle.text16BS(),
                        //           ),
                        //           const SizedBox(
                        //             width: 10,
                        //           ),
                        //           SvgPicture.asset(AppImages.dropDownIcon),
                        //           const Spacer(),
                        //           InkWell(
                        //             onTap: ()=>NavigatorMethods.pushNamed(context, CartScreen.routeName),
                        //          child: SvgPicture.asset(AppImages.cartIcon)),
                        //         ],
                        //       ),
                        18.sbH,
                        Builder(
                          builder: (context) {
                            return CustomFormField(
                              focusNode: searchFocusNode,
                              onFieldSubmitted: (value) {
                                if (value.isNotEmpty) {
                                  restaurantController.getRestaurants(
                                    search: value,
                                  );
                                }
                                if (value.isEmpty) {
                                  restaurantController.getRestaurants();
                                }
                              },
                              controller: _searchEc,
                              prefixIcon: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 13,
                                  vertical: 13,
                                ),
                                child: SvgPicture.asset(AppImages.searchIcon),
                              ),
                              hintText: 'searchForWhatYouWant'.tr,
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  FiltrationListViewWidget(
                    onSuccess: () {
                      setState(() {
                        isSelected = true;
                      });
                    },
                  ),
                  isSelected == true
                      ? const SizedBox(height: 16)
                      : const SizedBox(),
                  isSelected == true || _searchEc.text.isNotEmpty
                      ? const Expanded(child: AllRestaurantsWidget())
                      : Column(
                          children: [
                            const SizedBox(height: 24),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 24,
                              ),
                              width: context.width,
                              decoration: BoxDecoration(
                                color: FasakhanstaBrand.surface,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.grey.withValues(alpha: 0.2),
                                    blurRadius: 10,
                                    offset: const Offset(0, 0),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'researchResults'.tr,
                                    style: AppTextStyle.text16BS(),
                                  ),
                                  const SizedBox(height: 12),
                                  ApiResponseWidget(
                                    apiResponse:
                                        searchController.lastSearchApiResponse,
                                    onReload: () =>
                                        searchController.getLastSearch(),
                                    isEmpty:
                                        searchController.lastSearch.isEmpty,
                                    emptyWidget: Center(
                                      child: Text('noSearchResults'.tr),
                                    ),
                                    child: Wrap(
                                      spacing: 10,
                                      runSpacing: 12,
                                      children: List.generate(
                                        searchController.lastSearch.length,
                                        (index) => Container(
                                          padding: const EdgeInsets.all(10),
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(
                                              18,
                                            ),
                                            border: Border.all(
                                              color: FasakhanstaBrand.border,
                                            ),
                                          ),
                                          child: InkWell(
                                            onTap: () {
                                              setState(() {
                                                _searchEc.text =
                                                    searchController
                                                        .lastSearch[index]
                                                        .search ??
                                                    '';
                                                search =
                                                    searchController
                                                        .lastSearch[index]
                                                        .search ??
                                                    '';
                                                log(search ?? '');
                                              });
                                              restaurantController
                                                  .getRestaurants(
                                                    search: search,
                                                  );
                                            },
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                SvgPicture.asset(
                                                  AppImages.reloadIcon,
                                                ),
                                                const SizedBox(width: 6),
                                                Text(
                                                  searchController
                                                          .lastSearch[index]
                                                          .search ??
                                                      '',
                                                  style:
                                                      AppTextStyle.text16MG(),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            15.sbH,
                            //           Container(
                            //   padding: const EdgeInsets.symmetric(horizontal: 20,vertical: 24),
                            //   width: context.width,
                            //   decoration: BoxDecoration(
                            //     color: AppColor.whiteColor,
                            //     boxShadow: [
                            //       BoxShadow(color: Colors.grey.withValues(alpha:0.2), blurRadius: 10, offset: const Offset(0, 0))
                            //     ]
                            //   ),
                            //   child: Column(
                            //     crossAxisAlignment: CrossAxisAlignment.start,
                            //     children: [
                            //       Text('featuredRestaurants'.tr,style: AppTextStyle.text16BS(),),
                            //       const SizedBox(height: 12,),
                            //        SizedBox(
                            //           height: 170,
                            //           child: ListView.builder(
                            // scrollDirection: Axis.horizontal,
                            // shrinkWrap: true,
                            // itemCount: 5,
                            // itemBuilder: (context, index) {
                            //   return  Row(
                            // children: [
                            //   Column(
                            //     children: [
                            //     const CustomNetworkImage(imageUrl: Urls.testNoonLogo, height: 108, width: 125, radius: 15, fit: BoxFit.cover,),
                            //      const SizedBox(height: 12,),
                            //      Text('الدمياطي',style: AppTextStyle.text16RS(),),
                            //        const SizedBox(height: 4,),
                            //      Row(
                            //       crossAxisAlignment: CrossAxisAlignment.start,
                            //       children: [
                            //         Padding(
                            //           padding: const EdgeInsets.only(top: 2),
                            //           child: SvgPicture.asset(AppImages.clockIcon),
                            //         ),
                            //         const SizedBox(width: 7,),
                            //         Text('30 د',style: AppTextStyle.text16RG().copyWith(fontWeight: FontWeight.w300),),
                            //       ],
                            //      )
                            //     ],
                            //   ),
                            //   const SizedBox(width: 10,),
                            // ],
                            //           );

                            // },
                            //           ),
                            //   )
                            //     ],
                            //   ),
                            //   ),
                          ],
                        ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
