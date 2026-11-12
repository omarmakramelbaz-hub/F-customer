import 'package:faskhaninja/helpers/theme/fasakhansta_brand.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../helpers/theme/app_colors.dart';
import '../../../../helpers/theme/app_text_style.dart';
import '../../../custom_widgets/custom_image/custom_network_image.dart';
import '../controller/favorite_controller.dart';
import '../model/product_favorite_model.dart';

class ProductFavoriteWidget extends StatelessWidget {
  final ProductFavoriteModel product;

  const ProductFavoriteWidget({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: FasakhanstaBrand.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(18),
                ),
                child: CustomNetworkImage(
                  imageUrl: product.productImage ?? '',
                  height: 145,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: InkWell(
                  onTap: () => context
                      .read<FavoriteController>()
                      .addOrRemoveProductFavorite(id: product.id ?? 0),
                  child: const CircleAvatar(
                    radius: 18,
                    backgroundColor: FasakhanstaBrand.surface,
                    child: Icon(
                      Icons.favorite_rounded,
                      color: FasakhanstaBrand.danger,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 10, 10, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.productName ?? product.productTitle ?? '',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyle.text16MS(),
                ),
                const SizedBox(height: 4),
                Text(
                  product.resturantName ?? '',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyle.text14RS(),
                ),
                const SizedBox(height: 8),
                Text(
                  '${product.productPrice ?? 0} جنيه',
                  style: AppTextStyle.text16MS().copyWith(
                    color: AppColors.mainAppColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
