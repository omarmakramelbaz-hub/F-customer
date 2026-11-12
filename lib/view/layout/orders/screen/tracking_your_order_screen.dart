import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:pusher_channels_flutter/pusher_channels_flutter.dart';

import '../../../../helpers/delivery_activity/delivery_provider.dart';
import '../../../../helpers/networking/api_helper.dart';
import '../../../../helpers/networking/urls.dart';
import '../../../../helpers/pusher_service/pusher_controller.dart';
import '../../../../helpers/routes/app_routers_import.dart';
import '../../../../helpers/utils/url_launcher_methods.dart';
import '../../../../helpers/utils/utils.dart';
import '../../auth/controller/auth_controller.dart';
import '../../chat/screen/admin_chat_screen.dart';
import '../../chat/screen/chat_screen.dart';
import '../../home/widgets/home_video_background.dart';
import '../../my_account/model/setting_model.dart';
import '../bottom_sheet/cancel_order_bottom_sheet.dart';
import '../bottom_sheet/pay_tips_bottom_sheet.dart';
import '../controller/orders_controller.dart';
import '../model/orders_model.dart';
import '../widgets/live_order_tracking_content.dart';
import 'service_rating_screen.dart';

class TrackingYourOrderArgs {
  final int id;
  TrackingYourOrderArgs({required this.id});
}

class TrackingYourOrderScreen extends StatefulWidget {
  const TrackingYourOrderScreen(
      {super.key, required this.args, this.settingsLoader});
  final TrackingYourOrderArgs args;
  final Future<ApiResponse> Function()? settingsLoader;
  static const routeName = 'TrackingYourOrderScreen';

  @override
  State<TrackingYourOrderScreen> createState() =>
      _TrackingYourOrderScreenState();
}

class _TrackingYourOrderScreenState extends State<TrackingYourOrderScreen>
    with WidgetsBindingObserver {
  late final OrdersController _orders;
  late final PusherController _pusher;
  Timer? _poll;
  Future<void>? _refreshFuture;
  Future<void>? _settingsFuture;
  SettingModel? _settings;
  bool _visible = false;
  bool _foreground = true;
  bool _requestFailed = false;

  String _status(OrdersModel? order) => (order?.status ?? '')
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r'[\s-]+'), '_');

  bool _isFinished(OrdersModel? order) => const {
        'completed',
        'delivered',
        'cancelled',
        'canceled',
        'declined',
        'rejected',
        'ended',
        'failed',
        'payment_failed',
      }.contains(_status(order));

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _orders = context.read<OrdersController>();
    _pusher = context.read<PusherController>();
    _pusher.addEventListener('user.updated', _onOrderUpdated);
    _poll = Timer.periodic(const Duration(seconds: 30), (_) {
      if (!_isFinished(_orders.detailsOrders)) unawaited(_refresh());
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _orders.initialDetailsOrders();
      unawaited(_refresh(force: true));
      unawaited(_loadSettings());
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final visible =
        TickerMode.of(context) && (ModalRoute.of(context)?.isCurrent ?? true);
    final returned = visible && !_visible;
    _visible = visible;
    if (returned) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) unawaited(_refresh());
      });
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    if (_foreground) unawaited(_refresh());
  }

  void _onOrderUpdated(PusherEvent event) {
    if (!mounted) return;
    try {
      final data = jsonDecode(event.data);
      final target = data is Map ? data['order_id'] : null;
      final id = target is Map ? target['id'] : target;
      final parsed = int.tryParse(id?.toString() ?? '');
      if (parsed != null && parsed != widget.args.id) return;
    } catch (_) {
      // Older events omit the ID; only this authenticated order is reloaded.
    }
    unawaited(_refresh());
  }

  Future<void> _refresh({bool force = false}) {
    if (!mounted || (!force && (!_visible || !_foreground))) {
      return Future<void>.value();
    }
    final pending = _refreshFuture;
    if (pending != null) return pending;
    final completion = Completer<void>();
    _refreshFuture = completion.future;
    unawaited(_runRefresh(completion));
    return completion.future;
  }

  Future<void> _runRefresh(Completer<void> completion) async {
    try {
      if (mounted && _requestFailed) setState(() => _requestFailed = false);
      await _orders.getDetailsOrders(id: widget.args.id);
      if (!mounted ||
          _orders.detailsOrdersApiResponse.state != ResponseState.complete)
        return;
      final order = _orders.detailsOrders;
      if (order?.id == widget.args.id && order?.status != null) {
        await context.read<DeliveryProvider?>()?.syncOrder(
              id: widget.args.id,
              status: order!.status!,
              restaurantName: order.resturantName,
              updatedAt: order.updatedAt,
            );
      }
    } catch (_) {
      if (mounted) setState(() => _requestFailed = true);
    } finally {
      _refreshFuture = null;
      completion.complete();
    }
  }

  Future<void> _loadSettings() {
    final pending = _settingsFuture;
    if (pending != null) return pending;
    final completion = Completer<void>();
    _settingsFuture = completion.future;
    unawaited(_runSettings(completion));
    return completion.future;
  }

  Future<void> _runSettings(Completer<void> completion) async {
    try {
      final response = await (widget.settingsLoader?.call() ??
          ApiHelper.instance.get(Urls.setting));
      if (!mounted || response.state != ResponseState.complete) return;
      final data = response.data is Map ? response.data['data'] : null;
      if (data is Map) {
        final setting = SettingModel.fromJson(Map<String, dynamic>.from(data));
        setState(() => _settings = setting);
      }
    } catch (_) {
      // Missing support settings never replace an otherwise valid order.
    } finally {
      _settingsFuture = null;
      completion.complete();
    }
  }

  Future<void> _manualRefresh() async {
    await Future.wait([_refresh(force: true), _loadSettings()]);
  }

  @override
  void dispose() {
    _poll?.cancel();
    _pusher.removeEventListener('user.updated', _onOrderUpdated);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _call(String phone) {
    unawaited(UrlLauncherMethods.makePhoneCall(phone).catchError((Object _) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تعذّر فتح الاتصال على هذا الجهاز')),
        );
      }
    }));
  }

  void _openDelegateChat(OrdersModel order) {
    NamedNavigatorImpl.push(ChatScreen.routeName,
        arguments: ChatScreenArgs(
          orderId: 'DC${order.id}',
          accountType: 'user',
          isVendor: false,
          receiverDeviceToken: order.delegateFcmId ?? '',
          receiverName: order.delegateName ?? '',
          senderDeviceToken: order.userFcmId ?? '',
          senderName: order.userName ?? '',
          vendorDeviceToken: order.resturantVendorDeviceToken ?? '',
        ));
  }

  void _openSupportChat(int userId) {
    final setting = _settings;
    if (setting == null || (setting.adminId ?? 0) <= 0) return;
    NamedNavigatorImpl.push(AdminChatScreen.routeName,
        arguments: AdminChatScreenArgs(
          senderId: '$userId',
          receiverId: '${setting.adminId}',
          adminId: setting.adminId!,
          adminDeviceToken: setting.adminDeviceToken ?? '',
        ));
  }

  void _cancel(OrdersModel order) {
    Utils.showAppBottomSheet(CancelOrderBottomSheet(
      orderId: order.id!,
      onPressed: () {
        NamedNavigatorImpl.pop();
        _orders.cancelOrder(
            orderId: order.id!,
            onSuccess: () {
              // Keep the receipt alive while cancellation refreshes its order list.
              if (mounted) unawaited(_refresh(force: true));
            });
      },
    ));
  }

  void _rate(OrdersModel order) {
    NamedNavigatorImpl.push(
      ServiceRatingScreen.routeName,
      arguments: ServiceRatingArgs(
          detailsOrder: order,
          onRatingChanged: () {
            if (mounted) unawaited(_refresh(force: true));
          }),
    );
  }

  void _tip(OrdersModel order) {
    Utils.showAppBottomSheet(
        PayTipsBottomSheet(
            orderId: order.id!,
            onSuccess: () {
              if (mounted) unawaited(_refresh(force: true));
            }),
        isScrollControlled: true);
  }

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<AuthController>().profile;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light
          .copyWith(statusBarColor: Colors.transparent),
      child: Scaffold(
        backgroundColor: const Color(0xFF092225),
        body: Stack(fit: StackFit.expand, children: [
          const HomeVideoBackground(respectReducedMotion: true),
          const ColoredBox(color: Color(0x78092225)),
          Consumer<OrdersController>(builder: (context, controller, _) {
            final candidate = controller.detailsOrders;
            final order = candidate?.id == widget.args.id ? candidate : null;
            final response = controller.detailsOrdersApiResponse;
            if (order == null) {
              return _TrackingPlaceholder(
                loading: !_requestFailed &&
                    (response.state == ResponseState.loading ||
                        response.state == ResponseState.sleep),
                onBack: NamedNavigatorImpl.pop,
                onRetry: () => unawaited(_manualRefresh()),
              );
            }
            final status = _status(order);
            final completed = const {'completed', 'delivered'}.contains(status);
            final cancelled = const {'cancelled', 'canceled'}.contains(status);
            final declined = const {'declined', 'rejected'}.contains(status);
            final updated = DateTime.tryParse(order.updatedAt ?? '');
            final withinWindow = updated != null &&
                DateTime.now().isBefore(updated.add(const Duration(hours: 6)));
            final contactWindow =
                updated == null ? !_isFinished(order) : withinWindow;
            final external = order.delegateFromOut == 'out_resturant';
            final hasDelegate = (order.delegateId ?? 0) > 0;
            final showDelegate = !cancelled &&
                !declined &&
                contactWindow &&
                external &&
                hasDelegate &&
                status != 'new_order';
            final showBranchDelegate = !cancelled &&
                !declined &&
                contactWindow &&
                ((external && hasDelegate && status == 'new_order') ||
                    (order.delegateFromOut == 'in_resturant' &&
                        (order.resturantId ?? 0) > 0));
            final support = !cancelled && (!completed || withinWindow);
            final balance = profile?.balance;
            final canTip = completed &&
                withinWindow &&
                external &&
                order.hasCommissionedBefore != 1 &&
                balance != null &&
                balance > 0;
            final delegatePhone = (order.delegateMobile ?? '').trim();
            final branchPhone = (order.resturantPhone ?? '').trim();
            final supportPhone = (_settings?.mobile ?? '').trim();
            return RefreshIndicator(
              color: const Color(0xFFFF8A35),
              backgroundColor: const Color(0xFF14373A),
              onRefresh: _manualRefresh,
              child: LiveOrderTrackingContent(
                order: order,
                onBack: NamedNavigatorImpl.pop,
                onRefresh: () => unawaited(_manualRefresh()),
                refreshing:
                    !_requestFailed && response.state == ResponseState.loading,
                refreshFailed: _requestFailed ||
                    const {
                      ResponseState.error,
                      ResponseState.offline,
                      ResponseState.unauthorized
                    }.contains(response.state),
                showDelegate: showDelegate,
                showRestaurantDelegate: showBranchDelegate,
                showSupport: support && _settings != null,
                onCancel: status == 'pending' ? () => _cancel(order) : null,
                onRate: completed && withinWindow && order.hasRatedBefore != 1
                    ? () => _rate(order)
                    : null,
                onTip: canTip ? () => _tip(order) : null,
                onDelegateCall: showDelegate && delegatePhone.isNotEmpty
                    ? () => _call(delegatePhone)
                    : null,
                onDelegateChat:
                    showDelegate ? () => _openDelegateChat(order) : null,
                onRestaurantCall:
                    branchPhone.isNotEmpty ? () => _call(branchPhone) : null,
                onSupportCall:
                    supportPhone.isNotEmpty ? () => _call(supportPhone) : null,
                onSupportChat:
                    (profile?.id ?? 0) > 0 && (_settings?.adminId ?? 0) > 0
                        ? () => _openSupportChat(profile!.id!)
                        : null,
              ),
            );
          }),
        ]),
      ),
    );
  }
}

class _TrackingPlaceholder extends StatelessWidget {
  const _TrackingPlaceholder(
      {required this.loading, required this.onBack, required this.onRetry});
  final bool loading;
  final VoidCallback onBack;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => SafeArea(
        child: Directionality(
            textDirection: TextDirection.rtl,
            child: Column(children: [
              Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: IconButton(
                    tooltip: 'رجوع',
                    onPressed: onBack,
                    icon: const Icon(Icons.arrow_forward_rounded,
                        color: Colors.white),
                  )),
              Expanded(
                  child: Center(
                      child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (loading)
                                const CircularProgressIndicator(
                                    color: Color(0xFFFFA258))
                              else
                                const Icon(Icons.wifi_off_rounded,
                                    color: Color(0xFFFFA258), size: 40),
                              const SizedBox(height: 16),
                              Text(
                                  loading
                                      ? 'بنحمّل تفاصيل طلبك'
                                      : 'تعذّر تحميل الطلب',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 19,
                                      fontWeight: FontWeight.w700)),
                              if (!loading)
                                Padding(
                                    padding: const EdgeInsets.only(top: 14),
                                    child: FilledButton(
                                      onPressed: onRetry,
                                      child: const Text('إعادة المحاولة'),
                                    )),
                            ],
                          )))),
            ])),
      );
}
