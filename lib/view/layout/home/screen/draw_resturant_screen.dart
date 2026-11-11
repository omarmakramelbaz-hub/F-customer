import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pusher_channels_flutter/pusher_channels_flutter.dart';

import '../../../../helpers/hive/hive_methods.dart';
import '../../../../helpers/pusher_service/pusher_controller.dart';
import '../../../../helpers/theme/app_colors.dart';
import '../../../../helpers/theme/app_text_style.dart';
import '../../../../helpers/translation/all_translation.dart';
import '../../../custom_widgets/api_response_widget/api_response_widget.dart';
import '../controller/home_controller.dart';
import '../model/coupon_model.dart';
import '../model/draw_badge.dart';
import '../widgets/draw_widget.dart';
import '../widgets/raffle_hero_art.dart';

class DrawRestaurantScreen extends StatefulWidget {
  static const String routeName = 'DrawRestaurantScreen';
  const DrawRestaurantScreen({super.key});

  @override
  State<DrawRestaurantScreen> createState() => _DrawRestaurantScreenState();
}

class _DrawRestaurantScreenState extends State<DrawRestaurantScreen> {
  late PusherController _pusherController;

  @override
  void initState() {
    _pusherController = context.read<PusherController>();
    _pusherController.addEventListener('coupon.wheel.updated', _couponWheelUpdated);
    Future.microtask(() {
      final controller = context.read<HomeController>();
      controller.initialCoupon();
      controller.getCoupon(lat: HiveMethods.getLat(), lng: HiveMethods.getLan());
    });
    super.initState();
  }

  void _couponWheelUpdated(PusherEvent event) {
    final homeProvider = context.read<HomeController>();
    if (!mounted) return;
    homeProvider.getCoupon(lat: HiveMethods.getLat(), lng: HiveMethods.getLan()).then((_) {
      if (mounted && homeProvider.coupon == null) Navigator.pop(context);
    });
  }

  @override
  void dispose() {
    _pusherController.removeEventListener('coupon.wheel.updated', _couponWheelUpdated);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<HomeController>(
      builder: (context, homeController, _) {
        final coupon = homeController.coupon;
        final data = coupon?.data;
        final restaurantsCount = data?.resturants?.length ?? 0;
        final byProducts = data?.isByProducts ?? false;
        // The other draws by products running now, each with its items and the customer's codes.
        final otherProductDraws = (coupon?.productDraws ?? const <Data>[]).where((d) => d.id != data?.id).toList();

        return Scaffold(
          backgroundColor: const Color(0xFFFBFBFB),
          body: SafeArea(
            child: Directionality(
              textDirection: TextDirection.rtl,
              child: Column(
                children: [
                  _TopBar(title: 'restaurantRaffle'.tr),
                  Expanded(
                    child: ApiResponseWidget(
                      apiResponse: homeController.couponResponse,
                      onReload: () => homeController.getCoupon(
                        lat: HiveMethods.getLat(),
                        lng: HiveMethods.getLan(),
                      ),
                      isEmpty: homeController.coupon == null,
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 30),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              byProducts ? 'اشتري الأصناف المختارة من أي فرع وادخل السحب!' : 'كل طلب مؤهل يأخذك لفرصة ربح رائعة!',
                              textAlign: TextAlign.right,
                              style: AppTextStyle.text13RG(color: const Color(0xFF777777)),
                            ),
                            const SizedBox(height: 14),
                            _RaffleHero(
                              title: data?.name ?? '',
                              drawAmount: data?.drawAmount,
                              price: data?.price ?? '',
                              endDate: data?.endDate,
                            ),
                            const SizedBox(height: 18),
                            if (data?.winnerCode != null) ...[
                              _WinnerCodeCard(code: data!.winnerCode!, mine: data.myCodes.contains(data.winnerCode)),
                              const SizedBox(height: 18),
                            ],
                            if (byProducts)
                              _ProductsDrawCard(draw: data!, showTitle: false)
                            else
                              _SubscriptionInfoCard(price: data?.price ?? ''),
                            if (!byProducts && (data?.myCodes.isNotEmpty ?? false)) ...[
                              const SizedBox(height: 18),
                              _MyCodesCard(codes: data!.myCodes),
                            ],
                            for (final draw in otherProductDraws) ...[
                              const SizedBox(height: 18),
                              _ProductsDrawCard(draw: draw, showTitle: true),
                            ],
                            if (coupon?.recentWinners.isNotEmpty ?? false) ...[
                              const SizedBox(height: 18),
                              _RecentWinnersCard(winners: coupon!.recentWinners),
                            ],
                            if (!byProducts) ...[
                              const SizedBox(height: 24),
                              _SectionHeader(count: restaurantsCount),
                              const SizedBox(height: 14),
                              RestaurantsDrawWidget(homeController: homeController),
                            ],
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
      },
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 7, 16, 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.right,
              style: AppTextStyle.text22BS(),
            ),
          ),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Icon(
              Icons.arrow_forward_ios_rounded,
              color: AppColors.mainAppColor,
              size: 23,
            ),
          ),
        ],
      ),
    );
  }
}

class _RaffleHero extends StatelessWidget {
  const _RaffleHero({
    required this.title,
    required this.drawAmount,
    required this.price,
    required this.endDate,
  });

  final String title;
  final String? drawAmount;
  final String price;
  final String? endDate;

  @override
  Widget build(BuildContext context) {
    final displayTitle = title.trim().isEmpty ? 'سحب على المطاعم' : title.trim();
    final prize = _displayPrize(drawAmount, displayTitle);

    return SizedBox(
      height: 360,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 300,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                color: const Color(0xFF073F46),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x2A052B35),
                    blurRadius: 24,
                    offset: Offset(0, 10),
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.memory(
                    raffleHeroArtBytes,
                    fit: BoxFit.cover,
                    alignment: Alignment.center,
                    gaplessPlayback: true,
                  ),
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.centerRight,
                        end: Alignment.centerLeft,
                        stops: [0.0, .48, 1.0],
                        colors: [
                          Color(0xE6073940),
                          Color(0xB8073940),
                          Color(0x18073940),
                        ],
                      ),
                    ),
                  ),
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Color(0x05000000), Color(0x61021D24)],
                      ),
                    ),
                  ),
                  Positioned(
                    top: -52,
                    left: -40,
                    child: Container(
                      width: 150,
                      height: 150,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.mainAppColor.withValues(alpha: .12),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 18,
                    bottom: 26,
                    child: Container(
                      width: 68,
                      height: 68,
                      decoration: BoxDecoration(
                        color: AppColors.mainAppColor.withValues(alpha: .94),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white.withValues(alpha: .28)),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x35000000),
                            blurRadius: 14,
                            offset: Offset(0, 6),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.card_giftcard_rounded, color: Colors.white, size: 36),
                    ),
                  ),
                  Positioned(
                    top: 18,
                    right: 18,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                      decoration: BoxDecoration(
                        color: AppColors.mainAppColor,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: const [
                          BoxShadow(color: Color(0x25000000), blurRadius: 8, offset: Offset(0, 3)),
                        ],
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.star_rounded, color: Colors.white, size: 15),
                          SizedBox(width: 5),
                          Text(
                            'المسابقة الحالية',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    top: 64,
                    right: 20,
                    left: 112,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          displayTitle,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyle.text22BS(color: Colors.white).copyWith(
                            height: 1.15,
                            fontSize: 27,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'كل طلب مؤهل يقربك من الفوز',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyle.text13RG(
                            color: Colors.white.withValues(alpha: .88),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    right: 18,
                    left: 98,
                    bottom: 24,
                    child: Row(
                      children: [
                        Expanded(
                          child: _GlassStat(
                            icon: Icons.emoji_events_rounded,
                            label: 'قيمة السحب',
                            value: prize,
                          ),
                        ),
                        const SizedBox(width: 9),
                        Expanded(
                          child: _GlassStat(
                            icon: Icons.shopping_bag_outlined,
                            label: 'الحد الأدنى للطلب',
                            value: _formatPrice(price),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            left: 24,
            right: 24,
            bottom: 0,
            child: _CountdownCard(endDate: endDate),
          ),
        ],
      ),
    );
  }
}

class _GlassStat extends StatelessWidget {
  const _GlassStat({required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 68,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xD9FFFFFF),
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: Colors.white.withValues(alpha: .48)),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: AppColors.mainAppColor.withValues(alpha: .12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppColors.mainAppColor, size: 19),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyle.text10RG(color: const Color(0xFF6E7475)),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyle.text14BS(color: const Color(0xFF132C31)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CountdownCard extends StatelessWidget {
  const _CountdownCard({required this.endDate});
  final String? endDate;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 82,
      padding: const EdgeInsets.symmetric(horizontal: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFF1F1F1)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1D000000),
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: const BoxDecoration(
              color: Color(0xFFEAF8F6),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.schedule_rounded, color: Color(0xFF0B7F77), size: 27),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('الوقت المتبقي للسحب', style: AppTextStyle.text13BS()),
                const SizedBox(height: 5),
                Text(
                  _remainingText(endDate),
                  style: AppTextStyle.text15BS(color: AppColors.mainAppColor),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SubscriptionInfoCard extends StatelessWidget {
  const _SubscriptionInfoCard({required this.price});
  final String price;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(15, 15, 15, 15),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF9F4),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFFFDFC5)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 49,
            height: 49,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFFFDFC5)),
            ),
            child: Icon(Icons.info_outline_rounded, color: AppColors.mainAppColor, size: 27),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: 'للاشتراك في المسابقة يرجى الطلب بمبلغ ',
                        style: AppTextStyle.text14BS(),
                      ),
                      TextSpan(
                        text: _formatPrice(price),
                        style: AppTextStyle.text15BS(color: AppColors.mainAppColor),
                      ),
                      TextSpan(text: ' أو أكثر', style: AppTextStyle.text14BS()),
                    ],
                  ),
                  textAlign: TextAlign.right,
                ),
                const SizedBox(height: 5),
                Text(
                  'كل طلب مؤهل يمنحك فرصة واحدة للدخول في السحب',
                  style: AppTextStyle.text11RG(color: const Color(0xFF7A7A7A)),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Container(
            width: 45,
            height: 45,
            decoration: BoxDecoration(
              color: AppColors.mainAppColor.withValues(alpha: .10),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(Icons.shopping_bag_outlined, color: AppColors.mainAppColor, size: 24),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.count});
  final int count;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 45,
          height: 45,
          decoration: BoxDecoration(
            color: AppColors.mainAppColor.withValues(alpha: .10),
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.groups_rounded, color: AppColors.mainAppColor, size: 24),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('المطاعم المشاركة في السحب', style: AppTextStyle.text19BS()),
              const SizedBox(height: 2),
              Text('$count مطعم مشارك', style: AppTextStyle.text12RG(color: const Color(0xFF858585))),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFFF0FAF9),
            borderRadius: BorderRadius.circular(13),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.chevron_right_rounded, size: 18, color: Color(0xFF0B7F77)),
              const SizedBox(width: 3),
              Text('عرض الكل', style: AppTextStyle.text12BS(color: const Color(0xFF0B7F77))),
            ],
          ),
        ),
      ],
    );
  }
}

String _formatPrice(String? value) {
  final text = value?.trim() ?? '';
  if (text.isEmpty) return '-';
  final number = num.tryParse(text.replaceAll(',', ''));
  if (number == null) return text;
  final formatted = number.toStringAsFixed(number % 1 == 0 ? 0 : 2);
  return '$formatted ج';
}

String _displayPrize(String? drawAmount, String title) {
  final raw = drawAmount?.trim() ?? '';
  if (raw.isNotEmpty) return _formatPrice(raw);

  final match = RegExp(r'([0-9٠-٩][0-9٠-٩,.]*)').firstMatch(title);
  if (match != null) return '${match.group(1)} ج';
  return title;
}

String _remainingText(String? value) {
  final raw = value?.trim() ?? '';
  if (raw.isEmpty) return '-';

  final parsed = DateTime.tryParse(raw) ?? DateTime.tryParse(raw.replaceFirst(' ', 'T'));
  if (parsed == null) return raw;

  final difference = parsed.difference(DateTime.now());
  if (difference.isNegative) return 'انتهى السحب';

  final days = difference.inDays;
  final hours = difference.inHours.remainder(24);
  final minutes = difference.inMinutes.remainder(60);

  if (days > 0) return '$days يوم  $hours ساعة  $minutes دقيقة';
  if (hours > 0) return '$hours ساعة  $minutes دقيقة';
  return '$minutes دقيقة';
}


/// A draw by chosen products: its items (bought from any branch, the ordinary way), the prize and the customer's codes.
class _ProductsDrawCard extends StatelessWidget {
  const _ProductsDrawCard({required this.draw, required this.showTitle});
  final Data draw;
  final bool showTitle;

  @override
  Widget build(BuildContext context) {
    final names = draw.products.map((p) => p.name).where((n) => n.trim().isNotEmpty).toList();
    return _DrawCard(
      icon: Icons.card_giftcard_rounded,
      children: [
        if (showTitle) ...[
          Text(draw.name ?? '', style: AppTextStyle.text15BS()),
          const SizedBox(height: 4),
        ],
        Text(
          draw.badgeLabel ?? 'يؤهلك للدخول في السحب',
          style: AppTextStyle.text14BS(color: AppColors.mainAppColor),
        ),
        const SizedBox(height: 6),
        Text(
          'اشتري أي صنف من الأصناف دي من أي فرع، وكل قطعة بتاخد بيها كود دخول بعد ما الأوردر يتسلّم.',
          style: AppTextStyle.text11RG(color: const Color(0xFF7A7A7A)),
        ),
        if (names.isNotEmpty) ...[
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: names.map((name) => DrawBadgeName(name: name)).toList(),
          ),
        ],
        if (draw.myCodes.isNotEmpty) ...[
          const SizedBox(height: 12),
          _CodesWrap(codes: draw.myCodes, winner: draw.winnerCode),
        ],
      ],
    );
  }
}

/// The customer's entry codes in the draw.
class _MyCodesCard extends StatelessWidget {
  const _MyCodesCard({required this.codes});
  final List<String> codes;

  @override
  Widget build(BuildContext context) {
    return _DrawCard(
      icon: Icons.confirmation_number_outlined,
      children: [_CodesWrap(codes: codes)],
    );
  }
}

class _CodesWrap extends StatelessWidget {
  const _CodesWrap({required this.codes, this.winner});
  final List<String> codes;
  final String? winner;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(codes.length == 1 ? 'كود الدخول بتاعك' : 'أكواد الدخول بتاعتك (${codes.length})', style: AppTextStyle.text13BS()),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: codes.map((code) {
            final won = code == winner;
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
              decoration: BoxDecoration(
                color: won ? const Color(0xFFE7F7EE) : Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: won ? const Color(0xFF1E9E5A) : const Color(0xFFE2E2E2)),
              ),
              child: Text(
                code,
                textDirection: TextDirection.ltr,
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 1.2,
                    color: won ? const Color(0xFF1E9E5A) : const Color(0xFF132C31)),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

/// The draw's winning code (green when it is one of the customer's).
class _WinnerCodeCard extends StatelessWidget {
  const _WinnerCodeCard({required this.code, required this.mine});
  final String code;
  final bool mine;

  @override
  Widget build(BuildContext context) {
    return _DrawCard(
      icon: Icons.emoji_events_rounded,
      highlight: true,
      children: [
        Text(mine ? 'مبروك! كودك هو الكود الفائز' : 'الكود الفائز', style: AppTextStyle.text14BS()),
        const SizedBox(height: 6),
        Text(code, textDirection: TextDirection.ltr,
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: 2, color: AppColors.mainAppColor)),
      ],
    );
  }
}

/// The draws ended lately and their winning codes.
class _RecentWinnersCard extends StatelessWidget {
  const _RecentWinnersCard({required this.winners});
  final List<DrawWinner> winners;

  @override
  Widget build(BuildContext context) {
    return _DrawCard(
      icon: Icons.emoji_events_outlined,
      children: [
        Text('الأكواد الفائزة', style: AppTextStyle.text14BS()),
        const SizedBox(height: 8),
        for (final winner in winners)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    winner.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyle.text12RG(color: const Color(0xFF555555)),
                  ),
                ),
                const SizedBox(width: 8),
                Text(winner.code, textDirection: TextDirection.ltr,
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, letterSpacing: 1.2, color: AppColors.mainAppColor)),
              ],
            ),
          ),
      ],
    );
  }
}

/// A chosen item's name on the draw screen.
class DrawBadgeName extends StatelessWidget {
  const DrawBadgeName({super.key, required this.name});
  final String name;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF1E6),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.mainAppColor.withValues(alpha: .30)),
      ),
      child: Text(name, style: AppTextStyle.text12BS(color: const Color(0xFFB94F00))),
    );
  }
}

class _DrawCard extends StatelessWidget {
  const _DrawCard({required this.icon, required this.children, this.highlight = false});
  final IconData icon;
  final List<Widget> children;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: highlight ? const Color(0xFFFFF9F4) : Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: highlight ? const Color(0xFFFFDFC5) : const Color(0xFFF1F1F1)),
        boxShadow: const [BoxShadow(color: Color(0x0A000000), blurRadius: 12, offset: Offset(0, 4))],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(color: AppColors.mainAppColor.withValues(alpha: .10), borderRadius: BorderRadius.circular(13)),
            child: Icon(icon, color: AppColors.mainAppColor, size: 23),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children)),
        ],
      ),
    );
  }
}
