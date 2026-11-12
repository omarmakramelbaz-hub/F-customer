import 'package:faskhaninja/helpers/theme/fasakhansta_brand.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../helpers/hive/hive_methods.dart';
import '../../../../helpers/routes/app_routers_import.dart';
import '../../../../helpers/theme/app_colors.dart';
import '../../../../helpers/theme/app_text_style.dart';
import '../../../../helpers/translation/all_translation.dart';
import '../../../custom_widgets/api_response_widget/api_response_widget.dart';
import '../../../custom_widgets/custom_image/custom_network_image.dart';
import '../../cart/controller/cart_controller.dart';
import '../../cart/screen/cart_screen.dart';
import '../controller/restaurants_controller.dart';
import '../widgets/custom_button_bottom_navigation.dart';
import '../../home/widgets/draw_badge_chip.dart';

class ProductDetailsDetailsArgs {
  final int id;
  final VoidCallback? onSuccessAddItem;

  const ProductDetailsDetailsArgs({required this.id, this.onSuccessAddItem});
}

class ProductDetailsScreen extends StatefulWidget {
  final ProductDetailsDetailsArgs args;
  static const String routeName = 'ProductDetailsScreen';

  const ProductDetailsScreen({super.key, required this.args});

  @override
  State<ProductDetailsScreen> createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends State<ProductDetailsScreen> {
  int _selectedRadio = 0;
  String productFeature = '';
  int? productFeatureId;
  int quantity = 1;

  @override
  void initState() {
    super.initState();
    context.read<CartController>().totalCountAddTCart = null;
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (BuildContext context) => RestaurantsController()
            ..initialProductsDetailsRestaurant()
            ..getProductsDetailsRestaurant(id: widget.args.id),
        ),
      ],
      child: Consumer<RestaurantsController>(
        builder: (BuildContext context, restaurantsController, _) {
          final defaultFeature = _defaultFeatureId(restaurantsController);

          return Scaffold(
            backgroundColor: Colors.transparent,
            body: ApiResponseWidget(
              apiResponse:
                  restaurantsController.productsDetailsRestaurantApiResponse,
              onReload: () => restaurantsController
                  .getProductsDetailsRestaurant(id: widget.args.id),
              isEmpty: restaurantsController.productsDetailsRestaurant == null,
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(bottom: 30),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHero(context, restaurantsController),
                    Transform.translate(
                      offset: const Offset(0, -22),
                      child: Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: _buildProductInfoCard(restaurantsController),
                          ),
                          const SizedBox(height: 18),
                          if (_quantityFeatures(restaurantsController)
                              .isNotEmpty)
                            _buildQuantitySection(
                              restaurantsController,
                              defaultFeature,
                            ),
                          _buildPreparationSection(restaurantsController),
                          _buildInfoNote(),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            bottomNavigationBar: ApiResponseWidget(
              loadingWidget: const SizedBox(),
              apiResponse:
                  restaurantsController.productsDetailsRestaurantApiResponse,
              onReload: () => restaurantsController
                  .getProductsDetailsRestaurant(id: widget.args.id),
              isEmpty: restaurantsController.productsDetailsRestaurant == null,
              child: CustomButtonBottomNavigation(
                featureId: productFeatureId ?? defaultFeature,
                qty: quantity,
                onSuccessAddItems: () {
                  widget.args.onSuccessAddItem?.call();
                  context.read<CartController>().getCart();
                },
                restaurantProductId:
                    restaurantsController.productsDetailsRestaurant?.id ?? 0,
                productFeature: productFeature,
                productClean: _selectedRadio == 0
                    ? null
                    : getProductClean(_selectedRadio),
                total: getTotalFromSelectedRadio(restaurantsController),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHero(BuildContext context, RestaurantsController controller) {
    final cartCount = context.watch<CartController>().cart?.carts?.length ?? 0;

    return Stack(
      children: [
        ClipRRect(
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(28),
            bottomRight: Radius.circular(28),
          ),
          child: CustomNetworkImage(
            imageUrl: controller.productsDetailsRestaurant?.productImage ?? '',
            height: 245,
            width: double.infinity,
            fit: BoxFit.cover,
          ),
        ),
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(28),
                bottomRight: Radius.circular(28),
              ),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  FasakhanstaBrand.surfaceRaised.withValues(alpha: .12),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
        Positioned(
          top: 44,
          right: 18,
          child: _roundActionButton(
            icon: Icons.arrow_forward_ios_rounded,
            onTap: () => Navigator.pop(context),
          ),
        ),
        if (HiveMethods.getToken() != null)
          Positioned(
            top: 44,
            left: 18,
            child: _roundActionButton(
              icon: Icons.shopping_bag_outlined,
              onTap: () => NamedNavigatorImpl.push(CartScreen.routeName),
              badge: cartCount,
            ),
          ),
        Positioned(
          left: 18,
          bottom: 38,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: FasakhanstaBrand.successTint,
              borderRadius: BorderRadius.circular(20),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x22000000),
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.check_circle_rounded,
                  size: 18,
                  color: FasakhanstaBrand.text,
                ),
                const SizedBox(width: 6),
                Text(
                  'متوفر',
                  style: AppTextStyle.text13BS(color: FasakhanstaBrand.text),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _roundActionButton({
    required IconData icon,
    required VoidCallback onTap,
    int? badge,
  }) {
    return Material(
      color: FasakhanstaBrand.surface,
      shape: const CircleBorder(),
      elevation: 3,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 46,
          height: 46,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Center(child: Icon(icon, size: 23, color: FasakhanstaBrand.text)),
              if (badge != null && badge > 0)
                Positioned(
                  right: -2,
                  bottom: -2,
                  child: Container(
                    constraints: const BoxConstraints(
                      minWidth: 18,
                      minHeight: 18,
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.mainAppColor,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: FasakhanstaBrand.border,
                        width: 1.5,
                      ),
                    ),
                    child: Text(
                      '$badge',
                      style: AppTextStyle.text10BW(
                        color: FasakhanstaBrand.onOrange,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProductInfoCard(RestaurantsController controller) {
    final product = controller.productsDetailsRestaurant;
    final selectedTotal = _toInt(getTotalFromSelectedRadio(controller));

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 22, 18, 18),
      decoration: BoxDecoration(
        color: FasakhanstaBrand.surface,
        borderRadius: BorderRadius.circular(26),
        boxShadow: const [
          BoxShadow(
            color: Color(0x16000000),
            blurRadius: 24,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(product?.productName ?? '', style: AppTextStyle.text20BS()),
          if (product?.draw != null) ...[
            const SizedBox(height: 8),
            DrawBadgeChip(badge: product!.draw!),
          ],
          if ((product?.productDescription ?? '')
              .toString()
              .trim()
              .isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              product?.productDescription ?? '',
              style: AppTextStyle.text14RG().copyWith(height: 1.55),
            ),
          ],
          const SizedBox(height: 18),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _infoTile(Icons.verified_rounded, 'الحالة', 'متوفر'),
              _infoTile(
                Icons.scale_outlined,
                'الكمية',
                _quantityFeatures(controller).isNotEmpty
                    ? 'حسب الاختيار'
                    : 'حسب المنتج',
              ),
              _infoTile(Icons.tune_rounded, 'التجهيز', 'حسب اختيارك'),
            ],
          ),
          const SizedBox(height: 18),
          const Divider(height: 1, color: FasakhanstaBrand.border),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$selectedTotal ج',
                style: AppTextStyle.text24BS(color: AppColors.mainAppColor),
              ),
              const Spacer(),
              Text('السعر الحالي', style: AppTextStyle.text12RG()),
            ],
          ),
        ],
      ),
    );
  }

  Widget _infoTile(IconData icon, String title, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: FasakhanstaBrand.surfaceRaised,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: FasakhanstaBrand.info),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppTextStyle.text10RG()),
              const SizedBox(height: 1),
              Text(value, style: AppTextStyle.text12BS()),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuantitySection(
    RestaurantsController controller,
    int? defaultFeature,
  ) {
    final features = _quantityFeatures(controller);

    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 0, 18, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('chooseQuantity'.tr),
          const SizedBox(height: 14),
          Row(
            children: [
              for (var i = 0; i < features.length; i++) ...[
                if (i > 0) const SizedBox(width: 10),
                Expanded(
                  child: _quantityButton(
                    feature: features[i],
                    selected: _isFeatureSelected(features[i], defaultFeature),
                    onTap: () => _selectQuantityFeature(features[i]),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _quantityButton({
    required dynamic feature,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        height: 50,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? AppColors.mainAppColor : FasakhanstaBrand.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? AppColors.mainAppColor : FasakhanstaBrand.border,
          ),
          boxShadow: selected
              ? const [
                  BoxShadow(
                    color: Color(0x1FFF6A00),
                    blurRadius: 12,
                    offset: Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Text(
          _featureLabel(feature.name?.toString() ?? ''),
          style: selected ? AppTextStyle.text16BW() : AppTextStyle.text15MS(),
        ),
      ),
    );
  }

  Widget _buildPreparationSection(RestaurantsController controller) {
    final options = _preparationOptions(controller);
    if (options.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 0, 18, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('selectTheCategory'.tr),
          const SizedBox(height: 12),
          ...options.map(
            (option) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _preparationCard(
                controller: controller,
                value: option.value,
                title: option.title,
                subtitle: option.subtitle,
                price: option.price,
                featureName: option.featureName,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Row(
      children: [
        Text(title, style: AppTextStyle.text18BS()),
        const Spacer(),
        Text(
          '${'required'.tr}*',
          style: AppTextStyle.text12RM(color: AppColors.mainAppColor),
        ),
      ],
    );
  }

  Widget _preparationCard({
    required RestaurantsController controller,
    required int value,
    required String title,
    required String subtitle,
    required int price,
    String? featureName,
  }) {
    final selected = _selectedRadio == value;

    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () => _selectPreparation(controller, value, featureName),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: selected
              ? FasakhanstaBrand.surfaceRaised
              : FasakhanstaBrand.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected ? AppColors.mainAppColor : FasakhanstaBrand.border,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Radio<int>(
              value: value,
              groupValue: _selectedRadio,
              activeColor: AppColors.mainAppColor,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              onChanged: (_) =>
                  _selectPreparation(controller, value, featureName),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTextStyle.text16BS()),
                  const SizedBox(height: 3),
                  Text(subtitle, style: AppTextStyle.text12RG()),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Text(
              '$price ج',
              style: AppTextStyle.text16BS(
                color:
                    selected ? AppColors.mainAppColor : FasakhanstaBrand.text,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoNote() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 0, 18, 4),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        decoration: BoxDecoration(
          color: FasakhanstaBrand.surfaceRaised,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: FasakhanstaBrand.border),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(
              Icons.info_outline_rounded,
              color: FasakhanstaBrand.info,
              size: 22,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('معلومة', style: AppTextStyle.text13BS()),
                  const SizedBox(height: 2),
                  Text(
                    'السعر النهائي يتغير حسب الكمية والتجهيز المختار.',
                    style: AppTextStyle.text12RG().copyWith(height: 1.4),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<dynamic> _allFeatures(RestaurantsController controller) {
    final features = controller.productsDetailsRestaurant?.features;
    if (features == null) return <dynamic>[];
    return List<dynamic>.from(features);
  }

  List<dynamic> _quantityFeatures(RestaurantsController controller) {
    return _allFeatures(controller)
        .where(
          (feature) => const {
            'kilo',
            'half',
            'quarter',
          }.contains(feature.name?.toString()),
        )
        .toList();
  }

  int? _defaultFeatureId(RestaurantsController controller) {
    final features = _allFeatures(controller);
    for (final preferred in const ['kilo', 'large']) {
      for (final feature in features) {
        if (feature.name?.toString() == preferred) {
          return int.tryParse('${feature.id}');
        }
      }
    }
    return null;
  }

  bool _isFeatureSelected(dynamic feature, int? defaultFeature) {
    final id = int.tryParse('${feature.id}');
    return productFeatureId != null
        ? productFeatureId == id
        : defaultFeature == id;
  }

  void _selectQuantityFeature(dynamic feature) {
    final name = feature.name?.toString() ?? '';
    setState(() {
      productFeatureId = int.tryParse('${feature.id}');
      productFeature = name;
      quantity = switch (name) {
        'kilo' => 1,
        'half' => 2,
        'quarter' => 4,
        _ => 1,
      };
    });
    context.read<CartController>().totalCountAddTCart = null;
  }

  String _featureLabel(String name) {
    return switch (name) {
      'kilo' => 'kilo'.tr,
      'half' => 'half'.tr,
      'quarter' => 'quarter'.tr,
      _ => name,
    };
  }

  void _selectPreparation(
    RestaurantsController controller,
    int value,
    String? featureName,
  ) {
    setState(() {
      _selectedRadio = value;
      if (featureName != null) {
        for (final feature in _allFeatures(controller)) {
          if (feature.name?.toString() == featureName) {
            productFeatureId = int.tryParse('${feature.id}');
            productFeature = featureName;
            break;
          }
        }
      }
    });
    context.read<CartController>().totalCountAddTCart = null;
  }

  List<_PreparationOption> _preparationOptions(
    RestaurantsController controller,
  ) {
    final data = controller.productsDetailsRestaurant;
    if (data == null) return const [];

    final base = _toInt(data.productPrice);
    final options = <_PreparationOption>[];

    if (base != 0) {
      options.add(
        _PreparationOption(
          value: 0,
          title: 'full'.tr,
          subtitle: 'السعر الأساسي للمنتج',
          price: base,
        ),
      );
    }

    void addExtra(
      int value,
      dynamic extra,
      String title,
      String subtitle,
      String featureName,
    ) {
      final extraValue = _toInt(extra);
      if (extraValue == 0) return;
      options.add(
        _PreparationOption(
          value: value,
          title: title,
          subtitle: subtitle,
          price: base + extraValue,
          featureName: featureName,
        ),
      );
    }

    addExtra(1, data.extraClean, 'clean'.tr, 'تنظيف وتجهيز المنتج', 'clean');
    addExtra(2, data.extraClear, 'clear'.tr, 'تجهيز إضافي للمنتج', 'clear');
    addExtra(3, data.extraLarge, 'large'.tr, 'اختيار الحجم الكبير', 'large');
    addExtra(
      4,
      data.extraMedium,
      'medium'.tr,
      'اختيار الحجم المتوسط',
      'medium',
    );
    addExtra(5, data.extraVacuim, 'vacuum'.tr, 'تغليف وتجهيز فاكيوم', 'vacuim');
    addExtra(6, data.extraCombo, 'combo'.tr, 'تجهيز كومبو', 'combo');

    return options;
  }

  int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is double) return value.round();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  String getTotalFromSelectedRadio(
    RestaurantsController restaurantsController,
  ) {
    final data = restaurantsController.productsDetailsRestaurant;
    if (data == null) return '0';

    final base = _toInt(data.productPrice);
    final total = switch (_selectedRadio) {
      0 => base,
      1 => base + _toInt(data.extraClean),
      2 => base + _toInt(data.extraClear),
      3 => base + _toInt(data.extraLarge),
      4 => base + _toInt(data.extraMedium),
      5 => base + _toInt(data.extraVacuim),
      6 => base + _toInt(data.extraCombo),
      _ => base,
    };

    return '$total';
  }

  String? getProductClean(int selectRadio) {
    return switch (selectRadio) {
      1 => 'extra_clean',
      2 => 'extra_clear',
      3 => 'extra_large',
      4 => 'extra_medium',
      5 => 'extra_vacuim',
      6 => 'extra_combo',
      _ => null,
    };
  }
}

class _PreparationOption {
  final int value;
  final String title;
  final String subtitle;
  final int price;
  final String? featureName;

  const _PreparationOption({
    required this.value,
    required this.title,
    required this.subtitle,
    required this.price,
    this.featureName,
  });
}
