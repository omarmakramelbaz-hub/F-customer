import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../../helpers/utils/guest_access_guard.dart';
import '../../request_delegate/screen/request_delegate_screen.dart';
import '../controller/home_controller.dart';

class GoDriveCardWidget extends StatelessWidget {
  final HomeController controller;
  final EdgeInsetsGeometry padding;

  const GoDriveCardWidget({
    super.key,
    required this.controller,
    this.padding = EdgeInsets.zero,
  });

  void _openRequestDelegate(BuildContext context) {
    if (GuestAccessGuard.blockIfGuest(context)) return;
    Navigator.of(context).pushNamed(RequestDelegateScreen.routeName);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Semantics(
        button: true,
        label: 'Go Drive، مندوب المشتريات، اطلب مندوب',
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Material(
              color: Colors.transparent,
              child: Ink(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topRight,
                    end: Alignment.bottomLeft,
                    colors: [Color(0x26FFFFFF), Color(0x0FFFFFFF)],
                  ),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: const Color(0x38FFFFFF)),
                ),
                child: InkWell(
                  onTap: () => _openRequestDelegate(context),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: 96),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(10, 10, 16, 10),
                      child: Row(
                        textDirection: TextDirection.rtl,
                        children: [
                          const Expanded(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              textDirection: TextDirection.ltr,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  'Go Drive',
                                  textDirection: TextDirection.ltr,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 17,
                                    height: 1.15,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                SizedBox(height: 3),
                                Text(
                                  'مندوب المشتريات',
                                  textDirection: TextDirection.rtl,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: Color(0xFFE1E8E4),
                                    fontSize: 13,
                                    height: 1.3,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                SizedBox(height: 7),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  textDirection: TextDirection.rtl,
                                  children: [
                                    Text(
                                      'اطلب مندوب',
                                      textDirection: TextDirection.rtl,
                                      style: TextStyle(
                                        color: Color(0xFFFFAE70),
                                        fontSize: 12,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    SizedBox(width: 5),
                                    Icon(
                                      Icons.arrow_back_rounded,
                                      color: Color(0xFFFFAE70),
                                      size: 15,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Image.asset(
                            'assets/images/home_courier.webp',
                            width: 86,
                            height: 76,
                            fit: BoxFit.contain,
                            excludeFromSemantics: true,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
