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
import '../../../../helpers/theme/app_colors.dart';
import '../../../../helpers/theme/app_text_style.dart';
import '../../../../helpers/translation/all_translation.dart';
import '../../../custom_widgets/api_response_widget/api_response_widget.dart';
import '../../../custom_widgets/page_container/page_container.dart';
import '../controller/notifications_controller.dart';
import '../model/notifications_model.dart';
import '../widget/notification_widget.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  late PusherController _pusherController;
  int _selectedCategory = 0;

  static const List<_NotificationCategory> _categories = [
    _NotificationCategory('الكل', Icons.grid_view_rounded),
    _NotificationCategory('الطلبات', Icons.shopping_bag_outlined),
    _NotificationCategory('العروض', Icons.local_offer_outlined),
    _NotificationCategory('المعاملات', Icons.account_balance_wallet_outlined),
    _NotificationCategory('النظام', Icons.settings_outlined),
  ];

  @override
  void initState() {
    super.initState();
    _pusherController = context.read<PusherController>();
    _pusherController.addEventListener(
      'notification.updated',
      _handleVendorNotificationUpdated,
    );
  }

  void _handleVendorNotificationUpdated(PusherEvent event) {
    try {
      final jsonData = jsonDecode(event.data) as Map<String, dynamic>;
      log('Notification updated: $jsonData');
      if (!mounted) return;
      final notification = NotificationsModel.fromJson(jsonData);
      context.read<NotificationsController>().addNotificationToTop(
        notification,
      );
    } catch (e, stackTrace) {
      log('Error handling Pusher event: $e');
      log('Stack trace: $stackTrace');
    }
  }

  @override
  void dispose() {
    _pusherController.removeEventListener(
      'notification.updated',
      _handleVendorNotificationUpdated,
    );
    super.dispose();
  }

  List<NotificationsModel> _filter(List<NotificationsModel> list) {
    if (_selectedCategory == 0) return list;

    return list.where((item) {
      final type = item.data?.data?.notificationType;
      switch (_selectedCategory) {
        case 1:
          return type == 1;
        case 2:
          return type == 2;
        case 3:
          return type == 3;
        case 4:
          return type == null || (type != 1 && type != 2 && type != 3);
        default:
          return true;
      }
    }).toList();
  }

  String _emptyMessage() {
    switch (_selectedCategory) {
      case 1:
        return 'تحديثات طلباتك وحالة التوصيل هتظهر هنا أول ما يكون فيه جديد.';
      case 2:
        return 'أول ما ينزل عرض جديد أو خصم مميز هتلاقيه هنا.';
      case 3:
        return 'إشعارات الدفع والمحفظة والمعاملات المالية هتظهر هنا.';
      case 4:
        return 'تنبيهات النظام وأي تحديثات مهمة للتطبيق هتظهر هنا.';
      default:
        return 'أول ما يكون فيه تحديث جديد هنظهره لك هنا فوراً.';
    }
  }

  Future<void> _showClearAllDialog(NotificationsController controller) async {
    if (controller.notifications.isEmpty) return;

    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 28),
          child: Container(
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 18),
            decoration: BoxDecoration(
              color: FasakhanstaBrand.surface,
              borderRadius: BorderRadius.circular(24),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x1A000000),
                  blurRadius: 28,
                  offset: Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    color: FasakhanstaBrand.surfaceRaised,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: const Icon(
                    Icons.delete_sweep_rounded,
                    size: 30,
                    color: FasakhanstaBrand.danger,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'حذف جميع الإشعارات؟',
                  textAlign: TextAlign.center,
                  style: AppTextStyle.text18BS().copyWith(
                    color: FasakhanstaBrand.text,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'سيتم حذف كل الإشعارات الظاهرة حالياً من قائمة الإشعارات. الإشعارات الجديدة ستظهر بشكل طبيعي.',
                  textAlign: TextAlign.center,
                  style: AppTextStyle.text13RM().copyWith(
                    color: FasakhanstaBrand.muted,
                    height: 1.55,
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(dialogContext, false),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: FasakhanstaBrand.muted,
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          side: const BorderSide(
                            color: FasakhanstaBrand.border,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text('إلغاء'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () => Navigator.pop(dialogContext, true),
                        style: FilledButton.styleFrom(
                          backgroundColor: FasakhanstaBrand.dangerTint,
                          foregroundColor: FasakhanstaBrand.onOrange,
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        icon: const Icon(
                          Icons.delete_outline_rounded,
                          size: 18,
                        ),
                        label: const Text('حذف الكل'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );

    if (confirmed != true || !mounted) return;

    await controller.clearAllNotifications();
    if (!mounted) return;

    setState(() => _selectedCategory = 0);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: const Text(
            'تم حذف جميع الإشعارات',
            textAlign: TextAlign.center,
          ),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.fromLTRB(18, 0, 18, 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          duration: const Duration(seconds: 2),
        ),
      );
  }

  Widget _notificationsList(
    List<NotificationsModel> notifications,
    NotificationsController controller,
  ) {
    if (notifications.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(18, 28, 18, 36),
        children: [
          SizedBox(height: context.height * .055),
          Container(
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
            decoration: BoxDecoration(
              color: FasakhanstaBrand.surface,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: FasakhanstaBrand.border),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x0D000000),
                  blurRadius: 22,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  width: 118,
                  height: 118,
                  padding: const EdgeInsets.all(25),
                  decoration: BoxDecoration(
                    color: FasakhanstaBrand.surfaceRaised,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.mainAppColor.withValues(alpha: .14),
                    ),
                  ),
                  child: SvgPicture.asset(
                    AppImages.noNotificationIcon,
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(height: 22),
                Text(
                  'مفيش إشعارات جديدة',
                  textAlign: TextAlign.center,
                  style: AppTextStyle.text16BM().copyWith(
                    color: FasakhanstaBrand.text,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _emptyMessage(),
                  textAlign: TextAlign.center,
                  style: AppTextStyle.text13RM().copyWith(
                    color: FasakhanstaBrand.muted,
                    height: 1.55,
                  ),
                ),
                const SizedBox(height: 22),
                SizedBox(
                  height: 46,
                  child: OutlinedButton.icon(
                    onPressed: controller.getNotifications,
                    icon: Icon(
                      Icons.refresh_rounded,
                      size: 19,
                      color: AppColors.mainAppColor,
                    ),
                    label: Text(
                      'تحديث الإشعارات',
                      style: AppTextStyle.text13MS().copyWith(
                        color: AppColors.mainAppColor,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.mainAppColor,
                      backgroundColor: FasakhanstaBrand.surfaceRaised,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      side: BorderSide(
                        color: AppColors.mainAppColor.withValues(alpha: .34),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    return RefreshIndicator(
      color: AppColors.mainAppColor,
      onRefresh: controller.getNotifications,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(18, 10, 18, 34),
        itemCount: notifications.length,
        itemBuilder: (context, index) {
          final item = notifications[index];
          return NotificationWidget(
            orderId: item.data?.data?.id ?? 0,
            notification: item,
          );
        },
        separatorBuilder: (_, __) => const SizedBox(height: 12),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<NotificationsController>(
      builder: (context, notificationsController, _) {
        final all = notificationsController.notifications;
        final visible = _filter(all);

        return Scaffold(
          backgroundColor: Colors.transparent,
          body: PageContainer(
            bottom: false,
            child: SafeArea(
              top: true,
              bottom: false,
              child: Directionality(
                textDirection: TextDirection.rtl,
                child: Column(
                  children: [
                    const SizedBox(height: 8),
                    _TopBar(
                      hasNotifications: all.isNotEmpty,
                      onBack: () => Navigator.of(context).maybePop(),
                      onClearAll: () =>
                          _showClearAllDialog(notificationsController),
                      onMarkAllRead: () {
                        // The current API/model does not expose persisted read state yet.
                      },
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 58,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 4,
                        ),
                        itemCount: _categories.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 9),
                        itemBuilder: (context, index) {
                          final category = _categories[index];
                          return _CategoryChip(
                            title: category.title,
                            icon: category.icon,
                            selected: index == _selectedCategory,
                            onTap: () =>
                                setState(() => _selectedCategory = index),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 4),
                    Expanded(
                      child: ApiResponseWidget(
                        apiResponse:
                            notificationsController.notificationsResponse,
                        onReload: notificationsController.getNotifications,
                        isEmpty: all.isEmpty,
                        emptyWidget: _notificationsList(
                          const [],
                          notificationsController,
                        ),
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 220),
                          child: KeyedSubtree(
                            key: ValueKey(_selectedCategory),
                            child: _notificationsList(
                              visible,
                              notificationsController,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.onBack,
    required this.onMarkAllRead,
    required this.onClearAll,
    required this.hasNotifications,
  });

  final VoidCallback onBack;
  final VoidCallback onMarkAllRead;
  final VoidCallback onClearAll;
  final bool hasNotifications;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 62,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 156),
            child: Text(
              'notifications'.tr,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: AppTextStyle.text22BS(),
            ),
          ),
          Positioned(
            left: 14,
            child: Material(
              color: FasakhanstaBrand.surface,
              shape: const CircleBorder(),
              elevation: 1.5,
              shadowColor: Colors.black12,
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: onBack,
                child: const SizedBox(
                  width: 44,
                  height: 44,
                  child: Icon(
                    Icons.arrow_back_ios_new_rounded,
                    size: 19,
                    color: FasakhanstaBrand.text,
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            right: 10,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              textDirection: TextDirection.rtl,
              children: [
                AnimatedOpacity(
                  duration: const Duration(milliseconds: 180),
                  opacity: hasNotifications ? 1 : .35,
                  child: Material(
                    color: FasakhanstaBrand.surfaceRaised,
                    borderRadius: BorderRadius.circular(13),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(13),
                      onTap: hasNotifications ? onClearAll : null,
                      child: const SizedBox(
                        width: 40,
                        height: 40,
                        child: Icon(
                          Icons.delete_sweep_rounded,
                          size: 21,
                          color: FasakhanstaBrand.danger,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                SizedBox(
                  width: 92,
                  child: TextButton(
                    onPressed: onMarkAllRead,
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 3,
                        vertical: 8,
                      ),
                      foregroundColor: AppColors.mainAppColor,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      'تحديد الكل كمقروء',
                      maxLines: 2,
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyle.text13MS().copyWith(
                        color: AppColors.mainAppColor,
                        fontWeight: FontWeight.w700,
                        fontSize: 10.5,
                        height: 1.15,
                      ),
                    ),
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

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.title,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected
          ? FasakhanstaBrand.surfaceRaised
          : FasakhanstaBrand.surface,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: selected
                  ? AppColors.mainAppColor
                  : FasakhanstaBrand.border,
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: AppColors.mainAppColor.withValues(alpha: .08),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 18,
                color: selected
                    ? AppColors.mainAppColor
                    : FasakhanstaBrand.muted,
              ),
              const SizedBox(width: 7),
              Text(
                title,
                style: AppTextStyle.text13MS().copyWith(
                  color: selected
                      ? AppColors.mainAppColor
                      : FasakhanstaBrand.muted,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NotificationCategory {
  const _NotificationCategory(this.title, this.icon);

  final String title;
  final IconData icon;
}
