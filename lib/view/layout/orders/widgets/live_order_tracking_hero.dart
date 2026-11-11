import 'dart:ui';

import 'package:flutter/material.dart';

import '../model/orders_model.dart';

/// Status-only presentation: the parent supplies confirmed server order data.
class LiveOrderTrackingHero extends StatefulWidget {
  const LiveOrderTrackingHero({
    super.key,
    required this.order,
    this.padding = EdgeInsets.zero,
  });

  final OrdersModel order;
  final EdgeInsetsGeometry padding;

  @override
  State<LiveOrderTrackingHero> createState() => _LiveOrderTrackingHeroState();
}

class _LiveOrderTrackingHeroState extends State<LiveOrderTrackingHero>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final AnimationController _motion;
  bool _foreground = true;
  bool _visible = true;
  bool _reduceMotion = false;

  _TrackingStatus get _status => _TrackingStatus.from(widget.order.status);

  @override
  void initState() {
    super.initState();
    _motion = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );
    final lifecycle = WidgetsBinding.instance.lifecycleState;
    _foreground = lifecycle == null || lifecycle == AppLifecycleState.resumed;
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduceMotion = MediaQuery.disableAnimationsOf(context);
    _visible =
        TickerMode.of(context) && (ModalRoute.of(context)?.isCurrent ?? true);
    _syncMotion();
  }

  @override
  void didUpdateWidget(covariant LiveOrderTrackingHero oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncMotion();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    _syncMotion();
  }

  void _syncMotion() {
    if (_status.active && _foreground && _visible && !_reduceMotion) {
      if (!_motion.isAnimating) _motion.repeat(reverse: true);
    } else {
      _motion.stop();
      _motion.value = 0;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _motion.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final status = _status;
    final number = (widget.order.orderNo ?? '').trim();
    final orderNumber =
        number.isNotEmpty ? number : (widget.order.id?.toString() ?? '—');
    return Padding(
      padding: widget.padding,
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                  colors: [Color(0xEC123B3E), Color(0xE509252A)],
                ),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: const Color(0x35FFFFFF)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 12,
                    runSpacing: 8,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          AnimatedBuilder(
                            animation: _motion,
                            builder: (context, child) => Transform.scale(
                              scale: 1 + _motion.value * .24,
                              child: child,
                            ),
                            child: Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: status.color,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Flexible(
                            child: Text(
                              'حالة الطلب',
                              style: TextStyle(
                                color: Color(0xFFD8E5E0),
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      Text(
                        'طلب رقم $orderNumber',
                        style: const TextStyle(
                          color: Color(0xFFFFD3AB),
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Semantics(
                    liveRegion: true,
                    container: true,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          status.title,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: status.failed ? status.color : Colors.white,
                            fontSize: 27,
                            fontWeight: FontWeight.w900,
                            height: 1.3,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          status.message,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Color(0xFFE0E9E4),
                            fontSize: 14,
                            height: 1.6,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  ExcludeSemantics(
                    child: Center(
                      child: SizedBox(
                        width: 164,
                        height: 126,
                        child: AnimatedBuilder(
                          animation: _motion,
                          child: status.active
                              ? Image.asset(
                                  'assets/images/home_courier.webp',
                                  width: 144,
                                  height: 116,
                                  fit: BoxFit.contain,
                                )
                              : Icon(
                                  status.failed
                                      ? Icons.cancel_outlined
                                      : status.step == 3
                                          ? Icons.verified_rounded
                                          : Icons.receipt_long_outlined,
                                  size: 82,
                                  color: status.color,
                                ),
                          builder: (context, child) => Stack(
                            alignment: Alignment.center,
                            children: [
                              Transform.scale(
                                scale: 1 + _motion.value * .07,
                                child: Container(
                                  width: 108,
                                  height: 108,
                                  decoration: BoxDecoration(
                                    color: status.color.withValues(alpha: .08),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color:
                                          status.color.withValues(alpha: .24),
                                    ),
                                  ),
                                ),
                              ),
                              Transform.translate(
                                offset: status.active && status.step == 2
                                    ? Offset(
                                        _motion.value * 6, -_motion.value * 3)
                                    : Offset.zero,
                                child: child,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  _TrackingTimeline(status: status),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TrackingTimeline extends StatelessWidget {
  const _TrackingTimeline({required this.status});

  final _TrackingStatus status;

  static const _labels = [
    'تم الاستلام',
    'قيد التجهيز',
    'في الطريق',
    'تم التسليم',
  ];
  static const _icons = [
    Icons.receipt_long_outlined,
    Icons.restaurant_rounded,
    Icons.delivery_dining_rounded,
    Icons.home_rounded,
  ];
  static const _descriptions = [
    'وصول الطلب إلى الفرع',
    'تجهيز أصناف الطلب وتسليمها للمندوب',
    'استلام المندوب للطلب وتوصيله إلى العنوان',
    'اكتمال تسليم الطلب',
  ];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          children: [
            Positioned(
              top: 18,
              right: constraints.maxWidth / 8,
              left: constraints.maxWidth / 8,
              child: Row(
                children: List.generate(
                  3,
                  (index) => Expanded(
                    child: Container(
                      height: 2,
                      color: status.step != null && index < status.step!
                          ? status.color
                          : const Color(0x26FFFFFF),
                    ),
                  ),
                ),
              ),
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: List.generate(4, (index) {
                final current = status.step == index;
                final done = status.step != null &&
                    (index < status.step! || (status.step == 3 && index == 3));
                final color =
                    current || done ? status.color : const Color(0xFF97B0AC);
                final description = current
                    ? '${_labels[index]}، المرحلة الحالية'
                    : done
                        ? '${_labels[index]}، مكتملة'
                        : '${_labels[index]}، لم تكتمل';
                return Expanded(
                  child: Semantics(
                    label: description,
                    selected: current,
                    child: ExcludeSemantics(
                      child: Tooltip(
                        message: _descriptions[index],
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 3),
                          child: Column(
                            children: [
                              Container(
                                width: 38,
                                height: 38,
                                decoration: BoxDecoration(
                                  color: current || done
                                      ? color
                                      : const Color(0xFF173D41),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: current || done
                                        ? color
                                        : const Color(0xFF54716F),
                                  ),
                                ),
                                child: Icon(
                                  done ? Icons.check_rounded : _icons[index],
                                  color: current || done
                                      ? const Color(0xFF123333)
                                      : color,
                                  size: 19,
                                ),
                              ),
                              const SizedBox(height: 9),
                              Text(
                                _labels[index],
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: color,
                                  fontSize: 11,
                                  height: 1.4,
                                  fontWeight: current
                                      ? FontWeight.w800
                                      : FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ],
        );
      },
    );
  }
}

class _TrackingStatus {
  const _TrackingStatus(
    this.title,
    this.message, {
    this.step,
    this.active = false,
    this.failed = false,
    this.color = const Color(0xFFFFA15C),
  });

  final String title;
  final String message;
  final int? step;
  final bool active;
  final bool failed;
  final Color color;

  factory _TrackingStatus.from(String? rawStatus) {
    final status = (rawStatus ?? '')
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[\s-]+'), '_');
    return switch (status) {
      'pending' || 'another_delegate' => const _TrackingStatus(
          'استلمنا طلبك',
          'طلبك وصل للفرع وبانتظار التأكيد.',
          step: 0,
          active: true,
        ),
      'accepted' || 'preparing' || 'in_preparation' => const _TrackingStatus(
          'طلبك بيتجهّز',
          'الفرع بيجهّز أصناف طلبك.',
          step: 1,
          active: true,
        ),
      'new_order' => const _TrackingStatus(
          'المندوب في طريقه للاستلام',
          'طلبك في مرحلة التجهيز والتسليم للمندوب.',
          step: 1,
          active: true,
        ),
      'shipped' ||
      'picked_up' ||
      'on_the_way' ||
      'out_for_delivery' =>
        const _TrackingStatus(
          'طلبك في الطريق',
          'المندوب استلم طلبك وفي طريقه إلى عنوان التوصيل.',
          step: 2,
          active: true,
        ),
      'completed' || 'delivered' => const _TrackingStatus(
          'طلبك وصل بالسلامة',
          'تم تسليم الطلب. بالهنا والشفا!',
          step: 3,
          color: Color(0xFFA6DFC0),
        ),
      'cancelled' || 'canceled' => const _TrackingStatus(
          'تم إلغاء الطلب',
          'الطلب ملغي. تقدر تراجع تفاصيله بالأسفل.',
          failed: true,
          color: Color(0xFFFFB1A2),
        ),
      'declined' || 'rejected' => const _TrackingStatus(
          'تعذّر قبول الطلب',
          'الفرع لم يقبل الطلب. راجع التفاصيل للتواصل والمتابعة.',
          failed: true,
          color: Color(0xFFFFB1A2),
        ),
      'failed' || 'payment_failed' => const _TrackingStatus(
          'تعذّر إكمال الطلب',
          'راجع تفاصيل الطلب لمعرفة الحالة.',
          failed: true,
          color: Color(0xFFFFB1A2),
        ),
      _ => const _TrackingStatus(
          'جارٍ تحديث حالة الطلب',
          'ستظهر هنا آخر حالة مؤكدة للطلب.',
          color: Color(0xFFD8E5E0),
        ),
    };
  }
}
