import 'dart:ui';

import 'package:flutter/material.dart';

import '../model/orders_model.dart';
import 'live_order_tracking_hero.dart';

/// Confirmed order data and actions supplied by the tracking screen.
class LiveOrderTrackingContent extends StatefulWidget {
  const LiveOrderTrackingContent({
    super.key,
    required this.order,
    required this.onBack,
    required this.onRefresh,
    this.refreshing = false,
    this.refreshFailed = false,
    this.onCancel,
    this.onRate,
    this.onTip,
    this.onDelegateCall,
    this.onDelegateChat,
    this.onRestaurantCall,
    this.onSupportCall,
    this.onSupportChat,
    this.showDelegate = false,
    this.showRestaurantDelegate = false,
    this.showSupport = false,
  });

  final OrdersModel order;
  final VoidCallback onBack;
  final VoidCallback onRefresh;
  final bool refreshing;
  final bool refreshFailed;
  final VoidCallback? onCancel;
  final VoidCallback? onRate;
  final VoidCallback? onTip;
  final VoidCallback? onDelegateCall;
  final VoidCallback? onDelegateChat;
  final VoidCallback? onRestaurantCall;
  final VoidCallback? onSupportCall;
  final VoidCallback? onSupportChat;
  final bool showDelegate;
  final bool showRestaurantDelegate;
  final bool showSupport;

  @override
  State<LiveOrderTrackingContent> createState() =>
      _LiveOrderTrackingContentState();
}

class _LiveOrderTrackingContentState extends State<LiveOrderTrackingContent> {
  bool _itemsExpanded = false;

  @override
  void didUpdateWidget(covariant LiveOrderTrackingContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.order.id != widget.order.id) _itemsExpanded = false;
  }

  @override
  Widget build(BuildContext context) {
    final order = widget.order;
    final address = _deliveryAddress(order);
    return Directionality(
      textDirection: TextDirection.rtl,
      child: SafeArea(
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: ClampingScrollPhysics(),
          ),
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: DefaultTextStyle(
                style: const TextStyle(
                  fontFamily: 'Tajawal',
                  color: Colors.white,
                  fontSize: 14,
                  height: 1.5,
                ),
                child: Column(
                  key: const ValueKey('tracking-content-column'),
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _topBar(),
                    const SizedBox(height: 18),
                    if (widget.refreshFailed) ...[
                      _refreshError(),
                      const SizedBox(height: 14),
                    ],
                    _GlassCard(
                      child: Row(
                        children: [
                          _TrackingAvatar(
                            url: order.resturantLogo,
                            icon: Icons.storefront_outlined,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('طلبك من', style: _text(color: _muted)),
                                Text(
                                  _value(order.resturantName) ?? 'الفرع',
                                  style:
                                      _text(size: 19, weight: FontWeight.w800),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    LiveOrderTrackingHero(order: order),
                    if (widget.showDelegate) ...[
                      const SizedBox(height: 16),
                      _contactCard(
                        title: 'مندوب التوصيل',
                        name: _value(order.delegateName),
                        photo: order.delegateLogo,
                        phone: _value(order.delegateMobile),
                        icon: Icons.delivery_dining_outlined,
                        actions: [
                          if (widget.onDelegateCall != null)
                            _TrackingAction(
                              key: const ValueKey('tracking-delegate-call'),
                              text: 'اتصال بالمندوب',
                              icon: Icons.call_outlined,
                              onPressed: widget.onDelegateCall!,
                            ),
                          if (widget.onDelegateChat != null)
                            _TrackingAction(
                              key: const ValueKey('tracking-delegate-chat'),
                              text: 'محادثة المندوب',
                              icon: Icons.chat_bubble_outline_rounded,
                              onPressed: widget.onDelegateChat!,
                            ),
                        ],
                      ),
                    ],
                    if (widget.showRestaurantDelegate) ...[
                      const SizedBox(height: 16),
                      _contactCard(
                        title: 'توصيل الفرع',
                        name: _value(order.resturantName),
                        photo: order.resturantLogo,
                        phone: _value(order.resturantPhone),
                        icon: Icons.storefront_outlined,
                        actions: [
                          if (widget.onRestaurantCall != null)
                            _TrackingAction(
                              key: const ValueKey('tracking-restaurant-call'),
                              text: 'اتصال بالفرع',
                              icon: Icons.call_outlined,
                              onPressed: widget.onRestaurantCall!,
                            ),
                        ],
                      ),
                    ],
                    if (widget.onRate != null || widget.onTip != null) ...[
                      const SizedBox(height: 16),
                      if (widget.onRate != null)
                        _TrackingAction(
                          key: const ValueKey('tracking-rate'),
                          text: 'قيّم تجربتك',
                          icon: Icons.star_outline_rounded,
                          primary: true,
                          onPressed: widget.onRate!,
                        ),
                      if (widget.onRate != null && widget.onTip != null)
                        const SizedBox(height: 10),
                      if (widget.onTip != null)
                        _TrackingAction(
                          key: const ValueKey('tracking-tip'),
                          text: 'إكرامية للمندوب',
                          icon: Icons.favorite_border_rounded,
                          onPressed: widget.onTip!,
                        ),
                    ],
                    const SizedBox(height: 16),
                    _itemDetails(),
                    const SizedBox(height: 16),
                    _totals(),
                    if (address.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      _GlassCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _sectionTitle(
                              'عنوان التوصيل',
                              Icons.location_on_outlined,
                            ),
                            const SizedBox(height: 10),
                            for (final line in address)
                              Text(line, style: _text(size: 15)),
                          ],
                        ),
                      ),
                    ],
                    if (widget.showSupport) ...[
                      const SizedBox(height: 16),
                      _GlassCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _sectionTitle('محتاج مساعدة؟', Icons.support_agent),
                            const SizedBox(height: 6),
                            Text(
                              'تواصل مع خدمة العملاء بخصوص طلبك.',
                              style: _text(color: _muted),
                            ),
                            if (widget.onSupportCall != null ||
                                widget.onSupportChat != null) ...[
                              const SizedBox(height: 14),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  if (widget.onSupportCall != null)
                                    _TrackingAction(
                                      key: const ValueKey(
                                        'tracking-support-call',
                                      ),
                                      text: 'اتصال بالدعم',
                                      icon: Icons.call_outlined,
                                      onPressed: widget.onSupportCall!,
                                    ),
                                  if (widget.onSupportChat != null)
                                    _TrackingAction(
                                      key: const ValueKey(
                                        'tracking-support-chat',
                                      ),
                                      text: 'محادثة الدعم',
                                      icon: Icons.chat_bubble_outline_rounded,
                                      onPressed: widget.onSupportChat!,
                                    ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                    if (widget.onCancel != null) ...[
                      const SizedBox(height: 16),
                      _TrackingAction(
                        key: const ValueKey('tracking-cancel'),
                        text: 'إلغاء الطلب',
                        icon: Icons.close_rounded,
                        danger: true,
                        onPressed: widget.onCancel!,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _topBar() => Row(
        children: [
          IconButton(
            key: const ValueKey('tracking-back'),
            tooltip: 'رجوع',
            onPressed: widget.onBack,
            color: Colors.white,
            icon: const Icon(Icons.arrow_back_rounded),
          ),
          Expanded(
            child: Text(
              'متابعة طلبك',
              textAlign: TextAlign.center,
              style: _text(size: 22, weight: FontWeight.w800),
            ),
          ),
          IconButton(
            key: const ValueKey('tracking-refresh'),
            tooltip: widget.refreshing ? 'جارٍ تحديث الطلب' : 'تحديث الطلب',
            onPressed: widget.refreshing ? null : widget.onRefresh,
            color: Colors.white,
            icon: widget.refreshing
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: _orange,
                      semanticsLabel: 'جارٍ تحديث الطلب',
                    ),
                  )
                : const Icon(Icons.refresh_rounded),
          ),
        ],
      );

  Widget _refreshError() => Semantics(
        liveRegion: true,
        child: _GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.info_outline_rounded, color: _orange),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'تعذّر تحديث الطلب. تفاصيل طلبك الأخيرة ما زالت ظاهرة.',
                      style: _text(size: 14),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              _TrackingAction(
                key: const ValueKey('tracking-refresh-retry'),
                text: 'إعادة المحاولة',
                icon: Icons.refresh_rounded,
                onPressed: widget.refreshing ? null : widget.onRefresh,
              ),
            ],
          ),
        ),
      );

  Widget _contactCard({
    required String title,
    required String? name,
    required String? photo,
    required String? phone,
    required IconData icon,
    required List<Widget> actions,
  }) =>
      _GlassCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                _TrackingAvatar(url: photo, icon: icon, fit: BoxFit.cover),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: _text(color: _orange)),
                      if (name != null)
                        Text(
                          name,
                          style: _text(size: 18, weight: FontWeight.w800),
                        ),
                      if (phone != null)
                        Directionality(
                          textDirection: TextDirection.ltr,
                          child: Text(phone, style: _text(color: _muted)),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            if (actions.isNotEmpty) ...[
              const SizedBox(height: 14),
              Wrap(spacing: 8, runSpacing: 8, children: actions),
            ],
          ],
        ),
      );

  Widget _itemDetails() {
    final items = widget.order.items ?? const <Items>[];
    return _GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextButton(
            key: const ValueKey('tracking-items-toggle'),
            onPressed: () => setState(() => _itemsExpanded = !_itemsExpanded),
            style: TextButton.styleFrom(
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 6),
              minimumSize: const Size(44, 44),
            ),
            child: Row(
              children: [
                const Icon(Icons.receipt_long_outlined, color: _orange),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'تفاصيل الأصناف',
                    style: _text(size: 17, weight: FontWeight.w700),
                  ),
                ),
                Text('${items.length}', style: _text(color: _muted)),
                const SizedBox(width: 8),
                Icon(
                  _itemsExpanded
                      ? Icons.expand_less_rounded
                      : Icons.expand_more_rounded,
                ),
              ],
            ),
          ),
          if (_itemsExpanded) ...[
            const SizedBox(height: 12),
            if (items.isEmpty)
              Text(
                'لا توجد أصناف معروضة لهذا الطلب.',
                style: _text(color: _muted),
              ),
            for (var index = 0; index < items.length; index++) ...[
              if (index != 0)
                const Divider(color: Color(0x25FFFFFF), height: 28),
              _item(items[index]),
            ],
          ],
        ],
      ),
    );
  }

  Widget _item(Items item) {
    final changed = item.updatedTotal != null &&
        item.updatedTotal != 0 &&
        item.updatedTotal!.isFinite;
    final feature = _portion(item.productFeatureName);
    final preparation = _preparation(item.productClean);
    final reason = _value(item.reasonUpdateTotal);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _value(item.restaurantProduct?.productName) ?? 'الصنف',
          style: _text(size: 16, weight: FontWeight.w700),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 12,
          runSpacing: 4,
          children: [
            Text('العدد: ${item.qty ?? '—'}', style: _text(color: _muted)),
            if (feature != null) Text(feature, style: _text(color: _muted)),
            if (preparation != null)
              Text(preparation, style: _text(color: _muted)),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 12,
          runSpacing: 4,
          children: [
            Text(
              _money(changed ? item.updatedTotal : item.total),
              style: _text(size: 16, color: _orange, weight: FontWeight.w700),
            ),
            if (changed && item.total != null && item.total!.isFinite)
              Text(
                _money(item.total),
                style: _text(color: _muted).copyWith(
                  decoration: TextDecoration.lineThrough,
                  decorationColor: _muted,
                ),
              ),
          ],
        ),
        if (changed && reason != null) ...[
          const SizedBox(height: 7),
          Text('سبب التعديل: $reason', style: _text(color: _muted)),
        ],
      ],
    );
  }

  Widget _totals() => _GlassCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _sectionTitle('ملخص الحساب', Icons.payments_outlined),
            const SizedBox(height: 18),
            _amountRow(
              'قيمة الأصناف',
              widget.order.updatedTotalItemPrice ?? widget.order.totalItemPrice,
            ),
            const SizedBox(height: 12),
            _amountRow('التوصيل', widget.order.deliveryPrice),
            const SizedBox(height: 12),
            _amountRow('رسوم الخدمة', widget.order.serviceFees),
            const SizedBox(height: 12),
            _amountRow('الضريبة', widget.order.tax),
            const Divider(color: Color(0x35FFFFFF), height: 30),
            _amountRow('الإجمالي', widget.order.grandTotal, emphasis: true),
            const SizedBox(height: 18),
            Wrap(
              spacing: 12,
              runSpacing: 4,
              alignment: WrapAlignment.spaceBetween,
              children: [
                Text('طريقة الدفع', style: _text(color: _muted)),
                Text(_payment(widget.order.paymentType), style: _text()),
              ],
            ),
          ],
        ),
      );
}

const _orange = Color(0xFFFF872D);
const _muted = Color(0xFFD0DFDA);

TextStyle _text({
  double size = 14,
  Color color = Colors.white,
  FontWeight weight = FontWeight.w500,
}) =>
    TextStyle(
      fontFamily: 'Tajawal',
      fontSize: size,
      height: 1.5,
      color: color,
      fontWeight: weight,
    );

Widget _sectionTitle(String title, IconData icon) => Row(
      children: [
        Icon(icon, color: _orange),
        const SizedBox(width: 10),
        Expanded(
          child: Text(title, style: _text(size: 17, weight: FontWeight.w700)),
        ),
      ],
    );

Widget _amountRow(String label, num? value, {bool emphasis = false}) => Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 3,
          child: Text(
            label,
            style: _text(
              size: emphasis ? 19 : 15,
              color: emphasis ? Colors.white : _muted,
              weight: emphasis ? FontWeight.w800 : FontWeight.w500,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Flexible(
          flex: 4,
          child: Text(
            _money(value),
            textAlign: TextAlign.end,
            style: _text(
              size: emphasis ? 21 : 15,
              color: emphasis ? _orange : Colors.white,
              weight: emphasis ? FontWeight.w900 : FontWeight.w600,
            ),
          ),
        ),
      ],
    );

String _money(num? value) =>
    value == null || !value.isFinite ? '—' : '${value.toStringAsFixed(2)} ج.م';

String? _value(String? value) {
  final result = value?.trim();
  return result == null || result.isEmpty ? null : result;
}

String? _portion(String? value) => switch (_value(value)) {
      'kilo' => 'كيلو',
      'half' => 'نصف كيلو',
      'quarter' => 'ربع كيلو',
      final other => other,
    };

String? _preparation(String? value) => switch (_value(value)) {
      'extra_clean' => 'تنظيف',
      'extra_clear' => 'مخلي',
      'extra_large' => 'كبير',
      'extra_medium' => 'متوسط',
      'extra_vacuim' => 'فاكيوم',
      'extra_combo' => 'كومبو',
      final other => other,
    };

String _payment(String? value) => switch (_value(value)) {
      'cash' => 'نقدًا',
      'online' => 'دفع إلكتروني',
      'v_cash' => 'فودافون كاش',
      'wallet' => 'المحفظة',
      _ => '—',
    };

List<String> _deliveryAddress(OrdersModel order) {
  final address = order.userAddress;
  final lines = <String?>[
    address?.addressName,
    address?.address,
    address?.streetName,
    address?.areaName,
    address?.cityName ?? address?.cityname,
    if (_value(address?.floorNo) != null) 'الدور ${address!.floorNo}',
    if (_value(address?.apartmentNo) != null) 'شقة ${address!.apartmentNo}',
    if (_value(address?.badge) != null) 'علامة مميزة: ${address!.badge}',
  ].map(_value).whereType<String>().toSet().toList();
  if (lines.isEmpty && _value(order.userLocation) != null) {
    lines.add(order.userLocation!.trim());
  }
  return lines;
}

class _GlassCard extends StatelessWidget {
  const _GlassCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xD609272B),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0x35FFFFFF)),
            ),
            child: child,
          ),
        ),
      );
}

class _TrackingAvatar extends StatelessWidget {
  const _TrackingAvatar({
    required this.url,
    required this.icon,
    this.fit = BoxFit.contain,
  });

  final String? url;
  final IconData icon;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    final fallback = Center(child: Icon(icon, size: 28, color: _orange));
    return Container(
      width: 52,
      height: 52,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0x18FFFFFF),
        borderRadius: BorderRadius.circular(16),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: _value(url) == null
            ? fallback
            : Image.network(
                url!.trim(),
                fit: fit,
                webHtmlElementStrategy: WebHtmlElementStrategy.prefer,
                errorBuilder: (context, error, stackTrace) => fallback,
              ),
      ),
    );
  }
}

class _TrackingAction extends StatelessWidget {
  const _TrackingAction({
    super.key,
    required this.text,
    required this.icon,
    required this.onPressed,
    this.primary = false,
    this.danger = false,
  });

  final String text;
  final IconData icon;
  final VoidCallback? onPressed;
  final bool primary;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final foreground = danger ? const Color(0xFFFFBDB1) : Colors.white;
    final style = OutlinedButton.styleFrom(
      foregroundColor: primary ? const Color(0xFF10282B) : foreground,
      backgroundColor: primary ? _orange : const Color(0x10000000),
      disabledForegroundColor: _muted,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      minimumSize: const Size(44, 48),
      side: BorderSide(
        color: primary
            ? _orange
            : danger
                ? const Color(0x70FFBDB1)
                : const Color(0x50FFFFFF),
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      textStyle: _text(size: 15, weight: FontWeight.w700),
    );
    return OutlinedButton.icon(
      onPressed: onPressed,
      style: style,
      icon: Icon(icon, size: 20),
      label: Text(text, textAlign: TextAlign.center),
    );
  }
}
