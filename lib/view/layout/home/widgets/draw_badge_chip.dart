import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart' show NumberFormat;

import '../model/draw_badge.dart';

/// A readable prize with a gentle pulse and sheen, without changing its value.
class DrawBadgeChip extends StatefulWidget {
  const DrawBadgeChip({
    super.key,
    required this.badge,
    this.compact = false,
    this.corner = false,
  });

  final DrawBadge badge;
  final bool compact;
  final bool corner;

  @override
  State<DrawBadgeChip> createState() => _DrawBadgeChipState();
}

class _DrawBadgeChipState extends State<DrawBadgeChip>
    with SingleTickerProviderStateMixin {
  late final AnimationController _motion = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 3200),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final animate =
        TickerMode.of(context) && !MediaQuery.disableAnimationsOf(context);
    if (animate) {
      if (!_motion.isAnimating) _motion.repeat();
    } else {
      _motion.stop();
      _motion.value = 0;
    }
  }

  @override
  void dispose() {
    _motion.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final amount = widget.badge.prizeAmount;
    final hasAmount = amount != null && amount.isFinite && amount > 0;
    final compact = widget.compact;
    final corner = widget.corner;
    const gold = Color(0xFFFFDB88);

    return Semantics(
      label: widget.badge.label,
      excludeSemantics: true,
      child: Tooltip(
        message: widget.badge.label,
        child: RepaintBoundary(
          child: ClipRRect(
            borderRadius:
                BorderRadius.circular(corner ? 8 : (compact ? 12 : 16)),
            child: AnimatedBuilder(
              animation: _motion,
              builder: (context, child) {
                final pulse = (1 - math.cos(_motion.value * math.pi * 2)) / 2;
                return CustomPaint(
                  foregroundPainter: _PrizeSheenPainter(_motion.value),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      border: corner
                          ? Border.all(color: const Color(0xFFE8B84C))
                          : null,
                      gradient: const LinearGradient(
                        begin: Alignment.topRight,
                        end: Alignment.bottomLeft,
                        colors: [Color(0xFF173E4A), Color(0xFF071F2C)],
                      ),
                    ),
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: corner ? 5 : (compact ? 8 : 16),
                        vertical: corner ? 5 : (compact ? 7 : 12),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            textDirection: TextDirection.rtl,
                            children: [
                              if (!corner) ...[
                                Icon(Icons.emoji_events_rounded,
                                    color: gold, size: compact ? 15 : 20),
                                const SizedBox(width: 5),
                              ],
                              Flexible(
                                child: Text(
                                  corner
                                      ? 'هذا المنتج يؤهلك للسحب'
                                      : 'قيمة السحب',
                                  textDirection: TextDirection.rtl,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: corner ? 10 : (compact ? 11 : 14),
                                    fontWeight: FontWeight.w700,
                                    height: 1.25,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 3),
                          if (hasAmount)
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 3),
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Transform.scale(
                                  scale: 1 + pulse * .035,
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    textDirection: TextDirection.ltr,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.baseline,
                                    textBaseline: TextBaseline.alphabetic,
                                    children: [
                                      Text(
                                        NumberFormat('#,##0.##', 'en')
                                            .format(amount),
                                        textDirection: TextDirection.ltr,
                                        style: TextStyle(
                                          color: gold,
                                          fontFamily: 'Roboto',
                                          fontSize:
                                              corner ? 19 : (compact ? 28 : 38),
                                          height: 1.1,
                                          fontWeight: FontWeight.w900,
                                          shadows: [
                                            Shadow(
                                              color: gold.withValues(
                                                  alpha: .15 + pulse * .25),
                                              blurRadius: 5 + pulse * 8,
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 5),
                                      Text(
                                        'جنيه',
                                        textDirection: TextDirection.rtl,
                                        style: TextStyle(
                                          color: gold,
                                          fontSize:
                                              corner ? 9 : (compact ? 12 : 16),
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          if (!compact || !hasAmount) ...[
                            const SizedBox(height: 4),
                            Text(
                              corner ? 'تفاصيل السحب' : widget.badge.label,
                              textAlign: TextAlign.center,
                              textDirection: TextDirection.rtl,
                              style: TextStyle(
                                color: const Color(0xFFE3EBED),
                                fontSize: compact ? 11 : 12,
                                height: 1.4,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _PrizeSheenPainter extends CustomPainter {
  const _PrizeSheenPainter(this.progress);

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    // A brief subtle pass followed by a pause; the number remains fully opaque.
    if (progress <= .08 || progress >= .48) return;
    final position = (progress - .08) / .4;
    final center = -size.width * .3 + position * size.width * 1.6;
    final rect = Rect.fromLTWH(
        center - size.width * .2, 0, size.width * .4, size.height);
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          colors: [Color(0x00FFDB88), Color(0x18FFDB88), Color(0x00FFDB88)],
        ).createShader(rect),
    );
  }

  @override
  bool shouldRepaint(_PrizeSheenPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
