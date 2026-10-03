import 'dart:convert';
import 'dart:developer';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pusher_channels_flutter/pusher_channels_flutter.dart';

import '../../../../helpers/hive/hive_methods.dart';
import '../../../../helpers/pusher_service/pusher_controller.dart';
import '../../../../helpers/routes/app_routers_import.dart';
import '../../../../helpers/theme/app_colors.dart';
import '../../../../helpers/theme/app_text_style.dart';
import '../../../../helpers/utils/restaurant_hours.dart';
import '../../../custom_widgets/custom_image/custom_network_image.dart';
import '../../address/screen/add_address_screen.dart';
import '../../auth/controller/auth_controller.dart';
import '../../auth/model/profile_model.dart';
import '../../home/controller/home_controller.dart';
import '../../home/model/previous_order_home_model.dart';
import '../../home/model/restaurants_near_you_home_model.dart';
import '../controller/restaurants_controller.dart';
import '../model/restaurants_model.dart';
import 'restaurant_details_screen.dart';

class RestaurantsScreen extends StatefulWidget {
  static const routeName = 'RestaurantsScreen';
  const RestaurantsScreen({super.key});

  @override
  State<RestaurantsScreen> createState() => _RestaurantsScreenState();
}

class _RestaurantsScreenState extends State<RestaurantsScreen> {
  late final PusherController _pusherController;
  final TextEditingController _searchController = TextEditingController();
  String _selectedFilter = 'الكل';

  static const _filters = <String>[
    'الكل',
    'الأقرب',
    'الأعلى تقييماً',
    'الأسرع توصيلاً',
  ];

  @override
  void initState() {
    super.initState();
    _pusherController = context.read<PusherController>();
    _pusherController.addEventListener('resturant.updated', _handleResturantUpdated);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final auth = context.read<AuthController>();
      if (HiveMethods.getToken() != null && auth.profile == null) {
        await auth.getProfile();
      }
      if (!mounted) return;
      await _loadRestaurants();
    });
  }

  Future<void> _loadRestaurants() async {
    final restaurants = context.read<RestaurantsController>();
    final home = context.read<HomeController>();

    restaurants.initialRestaurants();
    home.initialRestaurantsNearYou();

    await Future.wait([
      restaurants.getRestaurants(),
      home.getRestaurantsNearYou(
        lat: HiveMethods.getLat(),
        lng: HiveMethods.getLan(),
      ),
    ]);
  }

  void _handleResturantUpdated(PusherEvent event) {
    try {
      final decodedData = json.decode(event.data) as Map<String, dynamic>;
      final resturantData = decodedData['resturant'] as Map<String, dynamic>;
      if (!mounted) return;

      context.read<RestaurantsController>().updateResturant(
            RestaurantsModel.fromJson(resturantData),
          );
      context.read<RestaurantsController>().updatePreviousResturant(
            PreviousOrderHomeModel.fromJson(resturantData),
          );

      context.read<HomeController>().getRestaurantsNearYou(
            lat: HiveMethods.getLat(),
            lng: HiveMethods.getLan(),
          );
    } catch (e, stackTrace) {
      log('Error handling restaurant update: $e');
      log('Stack trace: $stackTrace');
    }
  }

  @override
  void dispose() {
    _pusherController.removeEventListener('resturant.updated', _handleResturantUpdated);
    _searchController.dispose();
    super.dispose();
  }

  UserAddresses? _selectedAddress(AuthController auth) {
    final addresses = auth.profile?.userAddresses ?? <UserAddresses>[];
    if (addresses.isEmpty) return null;

    final selectedId = auth.selectedAddressId ?? HiveMethods.getSelectedCity();
    final index = addresses.indexWhere((item) => item.id == selectedId);
    return addresses[index >= 0 ? index : 0];
  }

  String _addressLabel(UserAddresses? address) {
    final parts = <String?>[
      address?.streetName,
      address?.cityName,
    ].where((value) => value != null && value!.trim().isNotEmpty).cast<String>().toList();

    if (parts.isNotEmpty) return parts.join(' - ');
    final saved = HiveMethods.getCity()?.trim() ?? '';
    return saved.isEmpty ? 'حدد عنوان التوصيل لعرض المطاعم القريبة' : saved;
  }

  Future<void> _showAddressSelector() async {
    final auth = context.read<AuthController>();
    if (auth.profile == null && HiveMethods.getToken() != null) {
      await auth.getProfile();
    }
    if (!mounted) return;

    final addresses = auth.profile?.userAddresses ?? <UserAddresses>[];
    final previousIds = addresses.map((e) => e.id).whereType<int>().toSet();

    if (addresses.isEmpty) {
      _openAddAddress(previousIds);
      return;
    }

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: Container(
            constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * .72),
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 22),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 46,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFDADADA),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Text('اختر عنوان التوصيل', style: AppTextStyle.text18BS()),
                const SizedBox(height: 12),
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: addresses.length,
                    separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0xFFF0F0F0)),
                    itemBuilder: (context, index) {
                      final address = addresses[index];
                      final selected = address.id == (auth.selectedAddressId ?? HiveMethods.getSelectedCity());
                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                        leading: Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: AppColors.mainAppColor.withValues(alpha: .10),
                            borderRadius: BorderRadius.circular(13),
                          ),
                          child: Icon(Icons.location_on_rounded, color: AppColors.mainAppColor),
                        ),
                        title: Text(
                          [address.streetName, address.cityName]
                              .where((e) => e != null && e!.trim().isNotEmpty)
                              .join(' - '),
                          style: AppTextStyle.text14BS(),
                        ),
                        trailing: selected
                            ? const Icon(Icons.check_circle_rounded, color: Color(0xFF0A857A))
                            : const Icon(Icons.chevron_left_rounded),
                        onTap: () {
                          Navigator.pop(sheetContext);
                          _applyAddress(address);
                        },
                      );
                    },
                  ),
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pop(sheetContext);
                    _openAddAddress(previousIds);
                  },
                  icon: Icon(Icons.add_location_alt_outlined, color: AppColors.mainAppColor),
                  label: Text('إضافة عنوان جديد', style: AppTextStyle.text14BS(color: AppColors.mainAppColor)),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                    side: BorderSide(color: AppColors.mainAppColor.withValues(alpha: .35)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _openAddAddress(Set<int> previousIds) {
    NamedNavigatorImpl.push(
      AddAddressScreen.routeName,
      arguments: AddAddressArgs(
        onSuccess: () async {
          final auth = context.read<AuthController>();
          await auth.getProfile();
          if (!mounted) return;
          final addresses = auth.profile?.userAddresses ?? <UserAddresses>[];
          if (addresses.isEmpty) return;
          final added = addresses.firstWhere(
            (item) => item.id != null && !previousIds.contains(item.id),
            orElse: () => addresses.last,
          );
          _applyAddress(added);
        },
      ),
    );
  }

  void _applyAddress(UserAddresses address) {
    final auth = context.read<AuthController>();
    auth.setSelectedAddressId(address.id);

    if (address.id != null) HiveMethods.updateSelectedCity(address.id!);
    HiveMethods.updateLat(double.tryParse(address.lat.toString()) ?? 0);
    HiveMethods.updateLan(double.tryParse(address.lng.toString()) ?? 0);
    HiveMethods.updateCity(address.streetName ?? '');
    HiveMethods.updateSelectedCityAreaId(address.cityId ?? 0);

    context.read<HomeController>().getRestaurantsNearYou(
          lat: HiveMethods.getLat(),
          lng: HiveMethods.getLan(),
        );
    setState(() {});
  }

  List<RestaurantsModel> _visibleAllRestaurants(List<RestaurantsModel> source) {
    final search = _searchController.text.trim().toLowerCase();
    final result = source.where((restaurant) {
      if (search.isEmpty) return true;
      final haystack = [
        restaurant.name,
        restaurant.address,
        restaurant.cityName,
        restaurant.cityname,
      ].whereType<String>().join(' ').toLowerCase();
      return haystack.contains(search);
    }).toList();

    if (_selectedFilter == 'الأعلى تقييماً') {
      result.sort((a, b) => (b.avgRate ?? 0).compareTo(a.avgRate ?? 0));
    } else if (_selectedFilter == 'الأسرع توصيلاً') {
      result.sort((a, b) => _deliveryMinutes(a.deliveryTime).compareTo(_deliveryMinutes(b.deliveryTime)));
    } else if (_selectedFilter == 'الأقرب') {
      result.sort((a, b) {
        final aDistance = _distanceKm(a.lat, a.lng) ?? double.infinity;
        final bDistance = _distanceKm(b.lat, b.lng) ?? double.infinity;
        return aDistance.compareTo(bDistance);
      });
    }

    return result;
  }

  int _deliveryMinutes(String? value) {
    final text = value?.trim() ?? '';
    final match = RegExp(r'(\d+)').firstMatch(text);
    if (match == null) return 99999;
    final number = int.tryParse(match.group(1) ?? '') ?? 99999;
    return text.contains('ساعة') ? number * 60 : number;
  }

  double? _distanceKm(String? restaurantLat, String? restaurantLng) {
    final userLat = HiveMethods.getLat();
    final userLng = HiveMethods.getLan();
    final lat2 = double.tryParse(restaurantLat ?? '');
    final lng2 = double.tryParse(restaurantLng ?? '');
    if (userLat == null || userLng == null || lat2 == null || lng2 == null) return null;

    const earthRadius = 6371.0;
    final dLat = _toRadians(lat2 - userLat);
    final dLng = _toRadians(lng2 - userLng);
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRadians(userLat)) * math.cos(_toRadians(lat2)) * math.sin(dLng / 2) * math.sin(dLng / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadius * c;
  }

  double _toRadians(double degree) => degree * math.pi / 180;

  void _openRestaurant(int? id, String? status, String? underContract) {
    if (id == null || status == 'busy' || underContract == 'yes') return;
    NamedNavigatorImpl.push(
      RestaurantDetailsScreen.routeName,
      arguments: RestaurantDetailsArgs(id: id),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    final restaurantsController = context.watch<RestaurantsController>();
    final homeController = context.watch<HomeController>();
    final selectedAddress = _selectedAddress(auth);
    final allRestaurants = _visibleAllRestaurants(restaurantsController.restaurant);
    final nearbyRestaurants = homeController.restaurantsNearYou;
    final nearbyIds = nearbyRestaurants.map((e) => e.id).whereType<int>().toSet();

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: SafeArea(
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: Column(
            children: [
              _TopBar(onBack: () => Navigator.pop(context)),
              Expanded(
                child: RefreshIndicator(
                  color: AppColors.mainAppColor,
                  onRefresh: _loadRestaurants,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'اطلب من أقرب مطعم أو تصفح كل المطاعم',
                          textAlign: TextAlign.center,
                          style: AppTextStyle.text13RG(color: const Color(0xFF777777)),
                        ),
                        const SizedBox(height: 16),
                        _LocationCard(
                          address: _addressLabel(selectedAddress),
                          onChange: _showAddressSelector,
                        ),
                        const SizedBox(height: 22),
                        _SectionHeader(
                          icon: Icons.location_on_rounded,
                          title: 'مطاعم قريبة منك',
                          subtitle: 'مطاعم يمكنها توصيل الطلب إلى موقعك الحالي',
                          accent: const Color(0xFF0A857A),
                          count: nearbyRestaurants.length,
                        ),
                        const SizedBox(height: 12),
                        if (nearbyRestaurants.isEmpty)
                          _EmptySection(
                            icon: Icons.delivery_dining_rounded,
                            title: 'لا توجد مطاعم توصل إلى موقعك حالياً',
                            subtitle: 'جرّب تغيير عنوان التوصيل أو تصفح كل المطاعم بالأسفل',
                          )
                        else
                          SizedBox(
                            height: 252,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              padding: EdgeInsets.zero,
                              itemCount: nearbyRestaurants.length,
                              separatorBuilder: (_, __) => const SizedBox(width: 12),
                              itemBuilder: (context, index) {
                                final restaurant = nearbyRestaurants[index];
                                return _NearbyRestaurantCard(
                                  restaurant: restaurant,
                                  distance: _distanceKm(restaurant.lat, restaurant.lng),
                                  onTap: () => _openRestaurant(
                                    restaurant.id,
                                    restaurant.status,
                                    restaurant.underContract,
                                  ),
                                );
                              },
                            ),
                          ),
                        const SizedBox(height: 28),
                        _SectionHeader(
                          icon: Icons.storefront_rounded,
                          title: 'كل المطاعم',
                          subtitle: 'جميع المطاعم المتاحة في التطبيق',
                          accent: AppColors.mainAppColor,
                          count: restaurantsController.restaurant.length,
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _searchController,
                                onChanged: (_) => setState(() {}),
                                textInputAction: TextInputAction.search,
                                decoration: InputDecoration(
                                  hintText: 'ابحث عن مطعم',
                                  hintStyle: AppTextStyle.text13RG(color: const Color(0xFFAAAAAA)),
                                  prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF111111)),
                                  filled: true,
                                  fillColor: Colors.white,
                                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: const BorderSide(color: Color(0xFFE7E7E7)),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: BorderSide(color: AppColors.mainAppColor, width: 1.3),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            InkWell(
                              borderRadius: BorderRadius.circular(15),
                              onTap: _showFilterSheet,
                              child: Container(
                                height: 50,
                                padding: const EdgeInsets.symmetric(horizontal: 14),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(15),
                                  border: Border.all(color: const Color(0xFFE7E7E7)),
                                  boxShadow: const [
                                    BoxShadow(color: Color(0x0D000000), blurRadius: 8, offset: Offset(0, 3)),
                                  ],
                                ),
                                child: const Row(
                                  children: [
                                    Icon(Icons.tune_rounded, size: 19),
                                    SizedBox(width: 5),
                                    Text('فلتر', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: _filters.map((filter) {
                              final selected = _selectedFilter == filter;
                              return Padding(
                                padding: const EdgeInsets.only(left: 8),
                                child: ChoiceChip(
                                  label: Text(filter),
                                  selected: selected,
                                  onSelected: (_) => setState(() => _selectedFilter = filter),
                                  showCheckmark: false,
                                  side: BorderSide(
                                    color: selected ? AppColors.mainAppColor.withValues(alpha: .25) : const Color(0xFFE9E9E9),
                                  ),
                                  selectedColor: const Color(0xFFFFF0E4),
                                  backgroundColor: Colors.white,
                                  labelStyle: AppTextStyle.text12BS(
                                    color: selected ? AppColors.mainAppColor : const Color(0xFF6B6B6B),
                                  ),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                        const SizedBox(height: 14),
                        if (allRestaurants.isEmpty)
                          _EmptySection(
                            icon: Icons.store_mall_directory_outlined,
                            title: 'لا توجد مطاعم مطابقة',
                            subtitle: _searchController.text.trim().isEmpty
                                ? 'لا توجد مطاعم متاحة حالياً'
                                : 'غيّر كلمة البحث أو الفلتر المستخدم',
                          )
                        else
                          ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: allRestaurants.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 11),
                            itemBuilder: (context, index) {
                              final restaurant = allRestaurants[index];
                              return _AllRestaurantCard(
                                restaurant: restaurant,
                                distance: _distanceKm(restaurant.lat, restaurant.lng),
                                deliversHere: restaurant.id != null && nearbyIds.contains(restaurant.id),
                                onTap: () => _openRestaurant(
                                  restaurant.id,
                                  restaurant.status,
                                  restaurant.underContract,
                                ),
                              );
                            },
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
    );
  }

  void _showFilterSheet() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => Directionality(
        textDirection: TextDirection.rtl,
        child: Container(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 46,
                  height: 4,
                  decoration: BoxDecoration(color: const Color(0xFFDADADA), borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 18),
              Text('ترتيب المطاعم', style: AppTextStyle.text18BS()),
              const SizedBox(height: 10),
              ..._filters.map(
                (filter) => RadioListTile<String>(
                  value: filter,
                  groupValue: _selectedFilter,
                  activeColor: AppColors.mainAppColor,
                  title: Text(filter, style: AppTextStyle.text14BS()),
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() => _selectedFilter = value);
                    Navigator.pop(sheetContext);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.onBack});
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 58,
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: Row(
          children: [
            SizedBox(
              width: 52,
              child: IconButton(
                onPressed: onBack,
                icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 21),
              ),
            ),
            Expanded(
              child: Center(
                child: Text(
                  'مطاعم',
                  textDirection: TextDirection.rtl,
                  style: AppTextStyle.text20BS(),
                ),
              ),
            ),
            const SizedBox(width: 52),
          ],
        ),
      ),
    );
  }
}

class _LocationCard extends StatelessWidget {
  const _LocationCard({required this.address, required this.onChange});
  final String address;
  final VoidCallback onChange;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF9F4),
        borderRadius: BorderRadius.circular(19),
        border: Border.all(color: const Color(0xFFFFDFC3)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.mainAppColor,
              borderRadius: BorderRadius.circular(15),
            ),
            child: const Icon(Icons.location_on_rounded, color: Colors.white, size: 27),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('عنوان التوصيل الحالي', style: AppTextStyle.text12RG(color: const Color(0xFF777777))),
                const SizedBox(height: 4),
                Text(
                  address,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyle.text14BS(),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          OutlinedButton(
            onPressed: onChange,
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: AppColors.mainAppColor),
              foregroundColor: AppColors.mainAppColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
            child: const Text('تغيير العنوان', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.accent,
    required this.count,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color accent;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(color: accent.withValues(alpha: .10), shape: BoxShape.circle),
          child: Icon(icon, color: accent, size: 24),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppTextStyle.text20BS()),
              const SizedBox(height: 2),
              Text(subtitle, style: AppTextStyle.text12RG(color: const Color(0xFF808080))),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
          decoration: BoxDecoration(color: accent.withValues(alpha: .08), borderRadius: BorderRadius.circular(12)),
          child: Text('$count', style: AppTextStyle.text12BS(color: accent)),
        ),
      ],
    );
  }
}

class _NearbyRestaurantCard extends StatelessWidget {
  const _NearbyRestaurantCard({
    required this.restaurant,
    required this.distance,
    required this.onTap,
  });

  final RestaurantsNearYouHomeModel restaurant;
  final double? distance;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final width = math.min(MediaQuery.sizeOf(context).width * .72, 278.0);
    final image = (restaurant.bgImage ?? '').trim().isNotEmpty ? restaurant.bgImage! : (restaurant.logo ?? '');

    return SizedBox(
      width: width,
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFF0F0F0)),
              boxShadow: const [BoxShadow(color: Color(0x12000000), blurRadius: 14, offset: Offset(0, 5))],
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  height: 118,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      CustomNetworkImage(imageUrl: image, height: 118, width: width, radius: 0, fit: BoxFit.cover),
                      const DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Color(0x09000000), Color(0x33000000)],
                          ),
                        ),
                      ),
                      Positioned(
                        top: 9,
                        right: 9,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0A857A),
                            borderRadius: BorderRadius.circular(11),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.check_circle_rounded, color: Colors.white, size: 13),
                              SizedBox(width: 4),
                              Text('يوصل إليك', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700)),
                            ],
                          ),
                        ),
                      ),
                      if (restaurant.status == 'closed')
                        Positioned(
                          right: 9,
                          bottom: 9,
                          child: Container(
                            constraints: const BoxConstraints(maxWidth: 190),
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                            decoration: BoxDecoration(
                              color: const Color(0xCC4B4B4B),
                              borderRadius: BorderRadius.circular(11),
                            ),
                            child: Text(
                              restaurantClosedLabel(context, restaurant.openAt),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(11, 9, 11, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        restaurant.name ?? '',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyle.text16BS(),
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          const Icon(Icons.star_rounded, color: Color(0xFFFF7A00), size: 17),
                          const SizedBox(width: 3),
                          Text(_rate(restaurant.avgRate), style: AppTextStyle.text12BS()),
                        ],
                      ),
                      const SizedBox(height: 9),
                      const Divider(height: 1, color: Color(0xFFF0F0F0)),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(child: _MiniMetric(icon: Icons.location_on_outlined, value: _distance(distance), label: 'المسافة')),
                          Expanded(child: _MiniMetric(icon: Icons.delivery_dining_rounded, value: _money(restaurant.serviceFees), label: 'التوصيل')),
                          Expanded(child: _MiniMetric(icon: Icons.schedule_rounded, value: _delivery(restaurant.deliveryTime), label: 'الوقت')),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AllRestaurantCard extends StatelessWidget {
  const _AllRestaurantCard({
    required this.restaurant,
    required this.distance,
    required this.deliversHere,
    required this.onTap,
  });

  final RestaurantsModel restaurant;
  final double? distance;
  final bool deliversHere;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final image = (restaurant.logo ?? '').trim().isNotEmpty ? restaurant.logo! : (restaurant.bgImage ?? '');
    final address = (restaurant.address ?? '').trim().isNotEmpty
        ? restaurant.address!
        : (restaurant.cityName ?? restaurant.cityname ?? '');

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(19),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(19),
        child: Container(
          padding: const EdgeInsets.all(11),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(19),
            border: Border.all(color: const Color(0xFFF0F0F0)),
            boxShadow: const [BoxShadow(color: Color(0x0D000000), blurRadius: 12, offset: Offset(0, 4))],
          ),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(15),
                    child: CustomNetworkImage(imageUrl: image, height: 78, width: 84, radius: 0, fit: BoxFit.cover),
                  ),
                  const SizedBox(width: 11),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                restaurant.name ?? '',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTextStyle.text16BS(),
                              ),
                            ),
                            if (deliversHere)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE8F7F4),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Text('يوصل إليك', style: TextStyle(color: Color(0xFF0A857A), fontSize: 9, fontWeight: FontWeight.w700)),
                              ),
                          ],
                        ),
                        if (restaurant.status == 'closed') ...[
                          const SizedBox(height: 5),
                          Text(
                            restaurantClosedLabel(context, restaurant.openAt),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyle.text11BS(
                              color: const Color(0xFFB45120),
                            ),
                          ),
                        ],
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(Icons.location_on_outlined, size: 14, color: Color(0xFF8A8A8A)),
                            const SizedBox(width: 3),
                            Expanded(
                              child: Text(
                                address,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTextStyle.text11RG(color: const Color(0xFF7E7E7E)),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.star_rounded, size: 17, color: Color(0xFFFF7A00)),
                            const SizedBox(width: 3),
                            Text(_rate(restaurant.avgRate), style: AppTextStyle.text12BS()),
                            if (distance != null) ...[
                              const SizedBox(width: 12),
                              const Icon(Icons.near_me_outlined, size: 14, color: Color(0xFF0A857A)),
                              const SizedBox(width: 3),
                              Text(_distance(distance), style: AppTextStyle.text11BS(color: const Color(0xFF0A857A))),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 5),
                  Icon(Icons.chevron_left_rounded, color: AppColors.mainAppColor, size: 23),
                ],
              ),
              const SizedBox(height: 10),
              const Divider(height: 1, color: Color(0xFFF1F1F1)),
              const SizedBox(height: 9),
              Row(
                children: [
                  Expanded(child: _MiniMetric(icon: Icons.schedule_rounded, value: _delivery(restaurant.deliveryTime), label: 'وقت التوصيل')),
                  _verticalDivider(),
                  Expanded(child: _MiniMetric(icon: Icons.delivery_dining_rounded, value: _money(restaurant.serviceFees), label: 'رسوم التوصيل')),
                  _verticalDivider(),
                  Expanded(child: _MiniMetric(icon: Icons.shopping_bag_outlined, value: _money(restaurant.minOrderPrice), label: 'الحد الأدنى')),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _verticalDivider() => Container(width: 1, height: 37, color: const Color(0xFFEDEDED));
}

class _MiniMetric extends StatelessWidget {
  const _MiniMetric({required this.icon, required this.value, required this.label});
  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 18, color: const Color(0xFF0A857A)),
        const SizedBox(height: 3),
        Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTextStyle.text11BS()),
        const SizedBox(height: 1),
        Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTextStyle.text9RG(color: const Color(0xFF888888))),
      ],
    );
  }
}

class _EmptySection extends StatelessWidget {
  const _EmptySection({required this.icon, required this.title, required this.subtitle});
  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFF0F0F0)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 34, color: AppColors.mainAppColor),
          const SizedBox(height: 9),
          Text(title, textAlign: TextAlign.center, style: AppTextStyle.text14BS()),
          const SizedBox(height: 4),
          Text(subtitle, textAlign: TextAlign.center, style: AppTextStyle.text11RG(color: const Color(0xFF888888))),
        ],
      ),
    );
  }
}

String _rate(num? value) => (value ?? 0).toStringAsFixed(1);

String _money(dynamic value) {
  if (value == null) return '-';
  final number = value is num ? value : num.tryParse(value.toString());
  if (number == null) return value.toString();
  if (number == 0) return 'مجاني';
  return '${number.toStringAsFixed(number % 1 == 0 ? 0 : 1)} ج';
}

String _delivery(String? value) {
  final text = value?.trim() ?? '';
  return text.isEmpty ? '-' : text;
}

String _distance(double? value) {
  if (value == null) return '-';
  return '${value.toStringAsFixed(value < 10 ? 1 : 0)} كم';
}
