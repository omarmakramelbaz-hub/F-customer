import 'dart:convert';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pusher_channels_flutter/pusher_channels_flutter.dart';

import '../../../../helpers/extensions/extensions.dart';
import '../../../../helpers/hive/hive_methods.dart';
import '../../../../helpers/networking/api_helper.dart';
import '../../../../helpers/pusher_service/pusher_controller.dart';
import '../../../../helpers/routes/app_routers_import.dart';
import '../../../../helpers/theme/app_colors.dart';
import '../../../../helpers/theme/app_text_style.dart';
import '../../../../helpers/translation/all_translation.dart';
import '../../address/screen/add_address_screen.dart';
import '../../auth/controller/auth_controller.dart';
import '../../auth/model/profile_model.dart';
import '../../restaurants/screen/restaurant_details_screen.dart';
import '../../wallet/controller/wallet_controller.dart';
import '../controller/home_controller.dart';
import '../model/previous_order_home_model.dart';
import '../model/restaurants_near_you_home_model.dart';
import '../widgets/go_drive_card_widget.dart';
import '../widgets/home_feature_cards.dart';
import '../widgets/home_header.dart';
import '../widgets/home_fullscreen_content.dart';
import '../widgets/home_video_background.dart';
import '../widgets/restaurants_near_you_list_view_widget.dart';
import '../screen/draw_resturant_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final PusherController _pusherController;
  final _branchesKey = GlobalKey();

  bool get _hasDeliveryLocation {
    final lat = HiveMethods.getLat();
    final lng = HiveMethods.getLan();
    return lat != null &&
        lng != null &&
        lat.isFinite &&
        lng.isFinite &&
        lat.abs() <= 90 &&
        lng.abs() <= 180 &&
        (lat != 0 || lng != 0);
  }

  @override
  void initState() {
    super.initState();
    _pusherController = context.read<PusherController>();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _ensureProfileLoaded();
      if (!mounted) return;
      final homeController = context.read<HomeController>();
      // The shell also initializes home data. Reuse requests already in flight.
      await Future.wait([
        if (homeController.restaurantsNearYouApiResponse.state ==
            ResponseState.sleep)
          homeController.getRestaurantsNearYou(
            lat: HiveMethods.getLat(),
            lng: HiveMethods.getLan(),
          ),
        if (homeController.couponResponse.state == ResponseState.sleep)
          homeController.getCoupon(
            lat: HiveMethods.getLat(),
            lng: HiveMethods.getLan(),
          ),
        context.read<WalletController>().getWallet(),
      ]);
      if (!mounted) return;
      await _checkSelectedCity();
    });

    _registerPusherListeners();
  }

  void _registerPusherListeners() {
    _pusherController.addEventListener(
      'coupon.wheel.updated',
      _onCouponWheelUpdated,
    );
    _pusherController.addEventListener(
      'resturant.updated',
      _onResturantUpdated,
    );
  }

  void _unregisterPusherListeners() {
    _pusherController.removeEventListener(
      'resturant.updated',
      _onResturantUpdated,
    );
    _pusherController.removeEventListener(
      'coupon.wheel.updated',
      _onCouponWheelUpdated,
    );
  }

  Future<void> _ensureProfileLoaded() async {
    final auth = context.read<AuthController>();
    if (auth.profile == null) {
      await auth.getProfile();
    }
  }

  void _onCouponWheelUpdated(PusherEvent event) {
    log('Coupon Wheel Updated: ${event.data}');
    if (!mounted) return;
    final homeProvider = context.read<HomeController>();
    homeProvider.getCoupon(
      lat: HiveMethods.getLat(),
      lng: HiveMethods.getLan(),
    );
  }

  void _onResturantUpdated(PusherEvent event) {
    try {
      final decoded = json.decode(event.data) as Map<String, dynamic>;
      final resturantData = decoded['resturant'] as Map<String, dynamic>;
      if (!mounted) return;

      final resturantModel = RestaurantsNearYouHomeModel.fromJson(
        resturantData,
      );
      final previousModel = PreviousOrderHomeModel.fromJson(resturantData);

      final homeController = context.read<HomeController>();
      homeController.updateResturantNearestYou(resturantModel);
      homeController.updateSpacialResturant(resturantModel);
      homeController.updatePreviousResturant(previousModel);
    } catch (e, st) {
      log('Error handling Pusher event: $e');
      log('Stack trace: $st');
    }
  }

  @override
  void dispose() {
    _unregisterPusherListeners();
    super.dispose();
  }

  Future<void> _checkSelectedCity() async {
    final selectedCity = HiveMethods.getSelectedCity();
    if (selectedCity == null && mounted) {
      await context.read<AuthController>().getProfile();
      if (!mounted) return;
      _showCitySelectionSheet(delayed: true);
    }
  }

  String _addressPrimaryLine(UserAddresses address) {
    final street = (address.streetName ?? '').trim();
    final city = (address.cityName ?? '').trim();
    final country = (address.countryName ?? '').trim();

    if (street.isNotEmpty) return street;
    if (city.isNotEmpty) return city;
    if (country.isNotEmpty) return country;
    return 'deliveryAddresses'.tr;
  }

  String _addressSecondaryLine(UserAddresses address) {
    final primary = _addressPrimaryLine(address);
    final city = (address.cityName ?? '').trim();
    final country = (address.countryName ?? '').trim();
    final parts = <String>[];

    if (city.isNotEmpty && city != primary) parts.add(city);
    if (country.isNotEmpty && country != primary) parts.add(country);

    return parts.join(' • ');
  }

  void _showCitySelectionSheet({bool delayed = false}) {
    final authProvider = context.read<AuthController>();
    final userAddresses = authProvider.profile?.userAddresses ?? [];
    final previousIds = userAddresses
        .map((address) => address.id)
        .whereType<int>()
        .toSet();

    void openAddAddress() {
      if (!mounted) return;
      _openAddAddressScreen(previousIds);
    }

    if (userAddresses.isEmpty) {
      if (delayed) {
        Future.delayed(const Duration(milliseconds: 500), openAddAddress);
      } else {
        openAddAddress();
      }
      return;
    }

    final selectedAddressId =
        authProvider.selectedAddressId ?? HiveMethods.getSelectedCity();
    final orderedAddresses = List<UserAddresses>.from(userAddresses)
      ..sort((a, b) {
        final aSelected = a.id == selectedAddressId;
        final bSelected = b.id == selectedAddressId;
        if (aSelected == bSelected) return 0;
        return aSelected ? -1 : 1;
      });

    void showSheet() {
      if (!mounted) return;

      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        isDismissible: !delayed,
        enableDrag: !delayed,
        backgroundColor: Colors.transparent,
        barrierColor: Colors.black.withOpacity(0.42),
        builder: (sheetContext) {
          final screenHeight = MediaQuery.sizeOf(sheetContext).height;

          return Directionality(
            textDirection: TextDirection.rtl,
            child: SafeArea(
              top: false,
              child: Container(
                constraints: BoxConstraints(maxHeight: screenHeight * 0.84),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 10),
                    Container(
                      width: 42,
                      height: 4,
                      decoration: BoxDecoration(
                        color: const Color(0xFFD8D8D8),
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 14),
                      child: Row(
                        children: [
                          Container(
                            width: 46,
                            height: 46,
                            decoration: BoxDecoration(
                              color: AppColors.mainAppColor.withOpacity(0.10),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Icon(
                              Icons.location_on_rounded,
                              color: AppColors.mainAppColor,
                              size: 25,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'deliveryAddresses'.tr,
                              style: AppTextStyle.text16BS().copyWith(
                                color: AppColors.darkTextColor,
                                fontSize: 19,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.lightGreyColor,
                              borderRadius: BorderRadius.circular(99),
                            ),
                            child: Text(
                              '${orderedAddresses.length}',
                              style: AppTextStyle.text12BS().copyWith(
                                color: AppColors.darkGreyColor,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          if (!delayed) ...[
                            const SizedBox(width: 8),
                            InkWell(
                              onTap: () => Navigator.of(sheetContext).pop(),
                              borderRadius: BorderRadius.circular(99),
                              child: Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: AppColors.lightGreyColor,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.close_rounded,
                                  size: 20,
                                  color: AppColors.darkTextColor,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    Divider(
                      height: 1,
                      thickness: 1,
                      color: AppColors.borderColor.withOpacity(0.55),
                    ),
                    Flexible(
                      child: ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
                        physics: const BouncingScrollPhysics(),
                        itemCount: orderedAddresses.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final address = orderedAddresses[index];
                          final isSelected = address.id == selectedAddressId;
                          final secondary = _addressSecondaryLine(address);

                          return Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () => _onAddressSelected(address),
                              borderRadius: BorderRadius.circular(18),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 180),
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? AppColors.mainAppColor.withOpacity(0.07)
                                      : Colors.white,
                                  borderRadius: BorderRadius.circular(18),
                                  border: Border.all(
                                    color: isSelected
                                        ? AppColors.mainAppColor
                                        : AppColors.borderColor.withOpacity(
                                            0.8,
                                          ),
                                    width: isSelected ? 1.5 : 1,
                                  ),
                                  boxShadow: isSelected
                                      ? const []
                                      : const [
                                          BoxShadow(
                                            color: Color(0x0A000000),
                                            blurRadius: 12,
                                            offset: Offset(0, 4),
                                          ),
                                        ],
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Container(
                                      width: 44,
                                      height: 44,
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? AppColors.mainAppColor
                                            : AppColors.mainAppColor
                                                  .withOpacity(0.10),
                                        borderRadius: BorderRadius.circular(13),
                                      ),
                                      child: Icon(
                                        Icons.location_on_outlined,
                                        size: 23,
                                        color: isSelected
                                            ? Colors.white
                                            : AppColors.mainAppColor,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            _addressPrimaryLine(address),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: AppTextStyle.text16BS()
                                                .copyWith(
                                                  color:
                                                      AppColors.darkTextColor,
                                                  fontSize: 15,
                                                  height: 1.35,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                          ),
                                          if (secondary.isNotEmpty) ...[
                                            const SizedBox(height: 4),
                                            Text(
                                              secondary,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: AppTextStyle.text12BS()
                                                  .copyWith(
                                                    color: AppColors.greyColor,
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    AnimatedContainer(
                                      duration: const Duration(
                                        milliseconds: 180,
                                      ),
                                      width: 30,
                                      height: 30,
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? AppColors.mainAppColor
                                            : AppColors.lightGreyColor,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        isSelected
                                            ? Icons.check_rounded
                                            : Icons.chevron_left_rounded,
                                        color: isSelected
                                            ? Colors.white
                                            : AppColors.darkGreyColor,
                                        size: 19,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border(
                          top: BorderSide(
                            color: AppColors.borderColor.withOpacity(0.6),
                          ),
                        ),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x0D000000),
                            blurRadius: 18,
                            offset: Offset(0, -4),
                          ),
                        ],
                      ),
                      child: SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.of(sheetContext).pop();
                            _openAddAddressScreen(previousIds);
                          },
                          style: ElevatedButton.styleFrom(
                            elevation: 0,
                            backgroundColor: AppColors.mainAppColor,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          icon: const Icon(
                            Icons.add_location_alt_rounded,
                            size: 22,
                          ),
                          label: Text(
                            'deliveryToAnotherAddress'.tr,
                            style: AppTextStyle.text16BS().copyWith(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                            ),
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
      );
    }

    if (delayed) {
      Future.delayed(const Duration(milliseconds: 500), showSheet);
    } else {
      showSheet();
    }
  }

  void _openAddAddressScreen(Set<int> previousIds) {
    NamedNavigatorImpl.push(
      AddAddressScreen.routeName,
      arguments: AddAddressArgs(
        onSuccess: () {
          _handleAddressAdded(previousIds);
        },
      ),
    );
  }

  Future<void> _handleAddressAdded(Set<int> previousIds) async {
    final authProvider = context.read<AuthController>();
    await authProvider.getProfile();
    if (!mounted) return;

    final refreshedAddresses = authProvider.profile?.userAddresses ?? [];
    if (refreshedAddresses.isEmpty) return;

    final newAddress = refreshedAddresses.firstWhere(
      (address) => address.id != null && !previousIds.contains(address.id),
      orElse: () => refreshedAddresses.last,
    );

    _onAddressSelected(newAddress, closeSheet: false);
  }

  void _onAddressSelected(UserAddresses address, {bool closeSheet = true}) {
    if (closeSheet) {
      Navigator.pop(context);
    }

    final authProvider = context.read<AuthController>();
    final homeController = context.read<HomeController>();

    authProvider.setSelectedAddressId(address.id);

    homeController.initialCountCart();
    homeController.initialHeaderImage();
    homeController.initialSlider();
    homeController.initialDefaultSlider();
    homeController.initialPreviousOrder();
    homeController.initialRestaurantsNearYou();
    homeController.initialCoupon();
    homeController.initialSpacialRestaurants();

    if (address.id != null) {
      HiveMethods.updateSelectedCity(address.id!);
    }
    HiveMethods.updateLat(double.tryParse(address.lat.toString()) ?? 0);
    HiveMethods.updateLan(double.tryParse(address.lng.toString()) ?? 0);
    HiveMethods.updateCity(address.streetName ?? '');
    HiveMethods.updateSelectedCityAreaId(address.cityId ?? 0);

    Future.wait([
      homeController.getHeaderImage(),
      homeController.getRestaurantsNearYou(
        lat: double.tryParse(address.lat ?? '') ?? HiveMethods.getLat(),
        lng: double.tryParse(address.lng ?? '') ?? HiveMethods.getLan(),
      ),
      homeController.getCoupon(
        lat: HiveMethods.getLat(),
        lng: HiveMethods.getLan(),
      ),
      homeController.getPreviousOrder(),
      homeController.getSpacialRestaurants(
        lat: HiveMethods.getLat(),
        lng: HiveMethods.getLan(),
      ),
      homeController.getSlider(),
    ]);
  }

  Future<void> _refreshHome() async {
    await Future.wait([
      context.read<HomeController>().getRestaurantsNearYou(
        lat: HiveMethods.getLat(),
        lng: HiveMethods.getLan(),
      ),
      context.read<HomeController>().getCoupon(
        lat: HiveMethods.getLat(),
        lng: HiveMethods.getLan(),
      ),
      context.read<WalletController>().getWallet(),
    ]);
  }

  void _startOrder(HomeController controller) {
    if (!_hasDeliveryLocation) {
      _showCitySelectionSheet();
      return;
    }
    final available = controller.restaurantsNearYou
        .where(
          (branch) =>
              (branch.id ?? 0) > 0 &&
              branch.underContract != 'yes' &&
              branch.status != 'busy',
        )
        .toList();
    if (available.length == 1) {
      NamedNavigatorImpl.push(
        RestaurantDetailsScreen.routeName,
        arguments: RestaurantDetailsArgs(id: available.single.id!),
      );
      return;
    }
    // There is no hidden/current branch selection: the customer chooses a
    // nearby branch's logo card whenever more than one menu is available.
    final branchesContext = _branchesKey.currentContext;
    if (branchesContext != null) {
      Scrollable.ensureVisible(
        branchesContext,
        duration: MediaQuery.disableAnimationsOf(context)
            ? Duration.zero
            : const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Widget _buildNearbyBranches(HomeController controller) {
    if (!_hasDeliveryLocation) {
      return _homeMessage(
        'حدّد عنوان التوصيل لعرض الفروع القريبة منك',
        action: 'اختار العنوان',
        onTap: () => _showCitySelectionSheet(),
      );
    }
    final response = controller.restaurantsNearYouApiResponse;
    if (response.state == ResponseState.loading ||
        response.state == ResponseState.sleep) {
      return const SizedBox(
        height: 84,
        child: Center(
          child: CircularProgressIndicator(
            color: Color(0xFFFFA258),
            strokeWidth: 2,
          ),
        ),
      );
    }
    if (response.state != ResponseState.complete) {
      return _homeMessage(
        'تعذّر تحميل الفروع، حاول مرة تانية',
        action: 'إعادة المحاولة',
        onTap: () => controller.getRestaurantsNearYou(
          lat: HiveMethods.getLat(),
          lng: HiveMethods.getLan(),
        ),
      );
    }
    if (controller.restaurantsNearYou.isEmpty) {
      return _homeMessage(
        'لا توجد فروع متاحة لهذا العنوان حاليًا',
        action: 'تغيير العنوان',
        onTap: () => _showCitySelectionSheet(),
      );
    }
    return RestaurantsNearYouListViewWidget(
      restaurantsNearYou: controller.restaurantsNearYou,
      handleApiResponse: false,
      padding: EdgeInsets.zero,
    );
  }

  Widget _homeMessage(
    String message, {
    required String action,
    required VoidCallback onTap,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xC008282E),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: .16)),
      ),
      child: Column(
        children: [
          Text(
            message,
            textAlign: TextAlign.center,
            style: AppTextStyle.text12BS(color: Colors.white),
          ),
          TextButton(
            onPressed: onTap,
            child: Text(
              action,
              style: AppTextStyle.text12BS(color: const Color(0xFFFFBB83)),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<HomeController>(
      builder: (context, controller, _) {
        final hasSelectedLocation = _hasDeliveryLocation;
        return Scaffold(
          backgroundColor: const Color(0xFF092225),
          body: Stack(
            fit: StackFit.expand,
            children: [
              const HomeVideoBackground(),
              SafeArea(
                bottom: false,
                child: LayoutBuilder(
                  builder: (context, constraints) => RefreshIndicator(
                    color: const Color(0xFFFF8A35),
                    onRefresh: _refreshHome,
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(
                        parent: ClampingScrollPhysics(),
                      ),
                      child: HomeFullscreenContent(
                        minHeight: constraints.maxHeight,
                        bottomInset: MediaQuery.paddingOf(context).bottom,
                        hasLocation: hasSelectedLocation,
                        branchesKey: _branchesKey,
                        header: HomeHeader(
                          controller: controller,
                          onLocationTap: () => _showCitySelectionSheet(),
                        ),
                        competition: HomeFeatureCards(
                          controller: controller,
                          padding: EdgeInsets.zero,
                        ),
                        branches: _buildNearbyBranches(controller),
                        courier: GoDriveCardWidget(controller: controller),
                        onStartOrder: () => _startOrder(controller),
                        onCompetition: () => NamedNavigatorImpl.push(
                          DrawRestaurantScreen.routeName,
                        ),
                        onChangeAddress: () => _showCitySelectionSheet(),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
