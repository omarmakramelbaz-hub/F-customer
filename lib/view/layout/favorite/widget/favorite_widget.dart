import 'package:faskhaninja/helpers/theme/fasakhansta_brand.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

import '../../../../helpers/extensions/extensions.dart';
import '../../../../helpers/images/app_images.dart';
import '../../../../helpers/theme/app_colors.dart';
import '../../../../helpers/theme/app_text_style.dart';
import '../../../custom_widgets/custom_image/custom_network_image.dart';
import '../controller/favorite_controller.dart';
import '../model/favorite_model.dart';

class FavoriteWidget extends StatelessWidget {
  final FavoriteModel? favoriteModel;
  const FavoriteWidget({super.key, required this.favoriteModel});

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: AppColors.borderColor),
              ),
              child: CustomNetworkImage(
                imageUrl: favoriteModel?.logo ?? '',
                height: 135,
                width: context.width * 0.4,
                radius: 20,
                fit: BoxFit.cover,
              ),
            ),
            10.sbH,
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 35),
              child: Text(
                favoriteModel?.name ?? '',
                style: AppTextStyle.text16RS(),
                maxLines: 1,
              ),
            ),
            const SizedBox(height: 3),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 5),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SvgPicture.asset(AppImages.timeIcon),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      favoriteModel?.deliveryTime ?? '',
                      style: AppTextStyle.text14RS(),
                    ),
                  ),
                  const SizedBox(width: 10),
                ],
              ),
            ),
          ],
        ),
        Positioned(
          top: 10,
          left: 20,
          child: InkWell(
            onTap: () {
              context.read<FavoriteController>().addOrRemoveToWishlist(
                    id: favoriteModel?.id ?? 0,
                    onSuccess: () {},
                  );
            },
            child: CircleAvatar(
              radius: 18,
              backgroundColor: FasakhanstaBrand.surface,
              child: Icon(
                Icons.favorite_rounded,
                color: AppColors.redColor,
                size: 20,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
