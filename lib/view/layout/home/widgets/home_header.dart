import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../helpers/hive/hive_methods.dart';
import '../../../../helpers/utils/guest_access_guard.dart';
import '../../auth/controller/auth_controller.dart';
import '../../bottom_navigation/controller/bottom_navigation_controller.dart';
import '../../wallet/controller/wallet_controller.dart';
import '../../wallet/screen/wallet_screen.dart';
import '../controller/home_controller.dart';

/// Transparent controls that sit directly above the home background video.
class HomeHeader extends StatelessWidget implements PreferredSizeWidget {
  final HomeController controller;
  final VoidCallback onLocationTap;
  final EdgeInsetsGeometry padding;

  const HomeHeader({
    super.key,
    required this.controller,
    required this.onLocationTap,
    this.padding = EdgeInsets.zero,
  });

  Future<void> _openWallet(BuildContext context) async {
    if (GuestAccessGuard.blockIfGuest(context)) return;
    final wallet = context.read<WalletController>();
    await Navigator.of(context).pushNamed(WalletScreen.routeName);
    if (context.mounted) await wallet.getWallet();
  }

  void _openNotifications(BuildContext context, AuthController auth) {
    if (GuestAccessGuard.blockIfGuest(context)) return;
    HiveMethods.updateNotificationCount(auth.profile?.notificaionsCount);
    context.read<BottomNavigationController>().updateIndex(2);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<AuthController, WalletController>(
      builder: (context, auth, wallet, _) {
        final isGuest = GuestAccessGuard.isGuest;
        final addresses = auth.profile?.userAddresses ?? [];
        final selectedAddressId =
            auth.selectedAddressId ?? HiveMethods.getSelectedCity();
        final selectedIndex = addresses.indexWhere(
          (item) => item.id == selectedAddressId,
        );
        final address = selectedIndex >= 0 ? addresses[selectedIndex] : null;
        final addressParts = [address?.streetName, address?.cityName]
            .whereType<String>()
            .map((part) => part.trim())
            .where((part) => part.isNotEmpty)
            .toSet();
        final savedLocation = (HiveMethods.getCity() ?? '').trim();
        final location = addressParts.isNotEmpty
            ? addressParts.join('، ')
            : (address?.address ?? savedLocation).trim();
        final balance = isGuest ? null : wallet.wallet?.balance;
        final balanceLabel = balance == null
            ? 'المحفظة'
            : '${balance.toStringAsFixed(2)} ج.م';
        final hasNewNotifications =
            !isGuest &&
            HiveMethods.getNotificationsCount() != null &&
            HiveMethods.getNotificationsCount() !=
                auth.profile?.notificaionsCount;

        return Padding(
          padding: padding,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                textDirection: TextDirection.ltr,
                children: [
                  _HeaderAction(
                    label: balance == null
                        ? 'المحفظة'
                        : 'المحفظة، رصيدك ${balance.toStringAsFixed(2)} جنيه',
                    onTap: () => _openWallet(context),
                    child: SizedBox(
                      width: 102,
                      height: 44,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 9),
                        child: Row(
                          textDirection: TextDirection.rtl,
                          children: [
                            const Icon(
                              Icons.account_balance_wallet_outlined,
                              color: Colors.white,
                              size: 20,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  balanceLabel,
                                  maxLines: 1,
                                  textDirection: TextDirection.rtl,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _HeaderAction(
                    label: 'الإشعارات',
                    onTap: () => _openNotifications(context, auth),
                    child: SizedBox(
                      width: 44,
                      height: 44,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          const Icon(
                            Icons.notifications_none_rounded,
                            color: Colors.white,
                            size: 23,
                          ),
                          if (hasNewNotifications)
                            const Positioned(
                              top: 9,
                              right: 11,
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  color: Color(0xFFFF8A36),
                                  shape: BoxShape.circle,
                                ),
                                child: SizedBox(width: 7, height: 7),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: SizedBox(
                      height: 66,
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerRight,
                          child: Semantics(
                            label: 'فسخانستا',
                            image: true,
                            child: ExcludeSemantics(
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                textDirection: TextDirection.rtl,
                                children: [
                                  Image.asset(
                                    'assets/images/home_brand_logo.webp',
                                    width: 44,
                                    height: 44,
                                    fit: BoxFit.contain,
                                  ),
                                  const SizedBox(width: 8),
                                  const Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        'فسخانستا',
                                        textDirection: TextDirection.rtl,
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 22,
                                          height: 1.2,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                      SizedBox(height: 3),
                                      Text(
                                        'FASAKHANSTA',
                                        textDirection: TextDirection.ltr,
                                        style: TextStyle(
                                          color: Color(0xFFE0E7E3),
                                          fontSize: 8,
                                          letterSpacing: 1.4,
                                          height: 1.2,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 9),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onLocationTap,
                  borderRadius: BorderRadius.circular(14),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 5),
                    child: Row(
                      textDirection: TextDirection.rtl,
                      children: [
                        const Icon(
                          Icons.location_on_outlined,
                          color: Color(0xFFFFA15F),
                          size: 25,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            textDirection: TextDirection.ltr,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              const Text(
                                'التوصيل إلى',
                                textDirection: TextDirection.rtl,
                                style: TextStyle(
                                  color: Color(0xFFD4DDDA),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                location.isEmpty
                                    ? 'حدّد عنوان التوصيل'
                                    : location,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                textDirection: TextDirection.rtl,
                                textAlign: TextAlign.right,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  height: 1.3,
                                  fontWeight: FontWeight.w700,
                                  shadows: [
                                    Shadow(
                                      color: Color(0x66000000),
                                      blurRadius: 8,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: Colors.white,
                          size: 22,
                        ),
                      ],
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

  @override
  Size get preferredSize => const Size.fromHeight(132);
}

class _HeaderAction extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final Widget child;

  const _HeaderAction({
    required this.label,
    required this.onTap,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: label,
      child: Semantics(
        button: true,
        label: label,
        child: Material(
          color: const Color(0x1AFFFFFF),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Color(0x30FFFFFF)),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(onTap: onTap, child: child),
        ),
      ),
    );
  }
}
