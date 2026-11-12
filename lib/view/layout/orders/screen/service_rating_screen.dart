import 'package:faskhaninja/helpers/theme/fasakhansta_brand.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

import '../../../../helpers/extensions/extensions.dart';
import '../../../../helpers/images/app_images.dart';
import '../../../../helpers/theme/app_colors.dart';
import '../../../../helpers/theme/app_text_style.dart';
import '../../../../helpers/translation/all_translation.dart';
import '../../../../helpers/utils/common_methods.dart';
import '../../../custom_widgets/buttons/custom_button.dart';
import '../../../custom_widgets/custom_app_bar/custom_app_bar.dart';
import '../../../custom_widgets/custom_image/custom_network_image.dart';
import '../controller/orders_controller.dart';
import '../model/orders_model.dart';

class ServiceRatingArgs {
  final OrdersModel? detailsOrder;
  final VoidCallback onRatingChanged;

  ServiceRatingArgs({required this.onRatingChanged, this.detailsOrder});
}

class ServiceRatingScreen extends StatefulWidget {
  final ServiceRatingArgs args;
  static const routeName = 'ServiceRatingScreen';

  const ServiceRatingScreen({super.key, required this.args});

  @override
  State<ServiceRatingScreen> createState() => _ServiceRatingScreenState();
}

class _ServiceRatingScreenState extends State<ServiceRatingScreen> {
  int? _rating;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        height: 90,
        radius: 60,
        actions: const [],
        title: Text('trackingYourOrder'.tr),
      ),
      body: SingleChildScrollView(
        child: ChangeNotifierProvider(
          create: (context) => OrdersController(),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Column(
                children: [
                  const SizedBox(height: 100),
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: FasakhanstaBrand.surface,
                      borderRadius: const BorderRadius.only(
                        topRight: Radius.circular(36),
                        topLeft: Radius.circular(36),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.greyColor.withValues(alpha: .2),
                          blurRadius: 10,
                          offset: const Offset(0, -3),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        const SizedBox(height: 90),
                        Text(
                          widget.args.detailsOrder?.resturantName ?? '',
                          style: AppTextStyle.text18BS(),
                        ),
                        10.sbH,
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'requestCode'.tr,
                              style: AppTextStyle.text14RS(),
                            ),
                            const SizedBox(width: 5),
                            Text(':', style: AppTextStyle.text16RS()),
                            const SizedBox(width: 6),
                            Text(widget.args.detailsOrder?.orderNo ?? ''),
                          ],
                        ),
                        10.sbH,
                        Divider(
                          color: AppColors.greyColor.withValues(alpha: .1),
                          thickness: 5,
                        ),
                        15.sbH,
                        Text(
                          'evaluateYourApplication'.tr,
                          style: AppTextStyle.text18BS(),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 35),
                  ...List.generate(
                    3,
                    (index) => Column(
                      children: [
                        InkWell(
                          onTap: () {
                            setState(() {
                              _rating = index;
                            });
                          },
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 10,
                                ),
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 15,
                                ),
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: _rating == index
                                        ? AppColors.mainAppColor
                                        : AppColors.lightTextColor,
                                  ),
                                  color: FasakhanstaBrand.surface,
                                  borderRadius: const BorderRadius.all(
                                    Radius.circular(10),
                                  ),
                                ),
                                child: Center(
                                  child: Text(
                                    _getString(index),
                                    style: AppTextStyle.text16RS(),
                                  ),
                                ),
                              ),
                              if (_rating == index)
                                Positioned(
                                  top: -10,
                                  right: 20,
                                  child: Card(
                                    shape: const CircleBorder(),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 10,
                                        horizontal: 5,
                                      ),
                                      child: SvgPicture.asset(
                                        width: 15,
                                        AppImages.rateIcon,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 50),
                  Builder(
                    builder: (context) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: CustomButton(
                          onPressed: () {
                            _rating == null
                                ? CommonMethods.showError(
                                    message: 'evaluateYourApplication'.tr,
                                  )
                                : context.read<OrdersController>().reviewOrders(
                                    orderId: widget.args.detailsOrder?.id ?? 0,
                                    restaurantId:
                                        widget.args.detailsOrder?.resturantId ??
                                        0,
                                    rate: _rating == 0
                                        ? 5
                                        : _rating == 1
                                        ? 3
                                        : 1,
                                    onSuccess: () {
                                      Navigator.of(context).pop();
                                      widget.args.onRatingChanged.call();
                                    },
                                  );
                          },
                          text: 'submitYourRating'.tr,
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 50),
                ],
              ),
              Positioned(
                right: context.width * 0.3,
                left: context.width * 0.3,
                top: 14,
                child: Container(
                  width: context.width * 0.4,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(120),
                  ),
                  child: CustomNetworkImage(
                    radius: 120,
                    imageUrl:
                        widget.args.detailsOrder?.resturantLogo ??
                        ''
                            '',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getString(int index) {
    if (index == 0) {
      return 'myExperienceWasExcellentTheTasteWasGreatAndTheServiceWasExcellent'
          .tr;
    } else {
      if (index == 1) {
        return 'foodWasAcceptableButThereIsRoomForImprovement'.tr;
      } else {
        return 'unfortunatelyIDidNotLikeMyExperienceIAmCompletelyUnsatisfied'
            .tr;
      }
    }
  }
}
