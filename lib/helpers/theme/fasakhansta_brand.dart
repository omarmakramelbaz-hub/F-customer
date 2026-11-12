import 'package:flutter/material.dart';

/// Shared identity from the approved immersive customer home. Keep foregrounds
/// and surfaces separate; pure white remains available for artwork.
abstract final class FasakhanstaBrand {
  static const background = Color(0xFF081F25);
  static const surface = Color(0xFF10313A);
  static const surfaceRaised = Color(0xFF173B43);
  static const field = Color(0xFF09252D);
  static const text = Color(0xFFFFF8EC);
  static const muted = Color(0xFFA8BDBA);
  static const border = Color(0xFF35545A);
  static const orange = Color(0xFFFF8A2B);
  static const orangeDeep = Color(0xFFFF7212);
  static const orangeTint = Color(0xFF29352F);
  static const orangeBorder = Color(0xFF725136);
  static const onOrange = Color(0xFF09222A);
  static const success = Color(0xFF69D5A9);
  static const successTint = Color(0xFF123C38);
  static const danger = Color(0xFFFF9691);
  static const dangerTint = Color(0xFF422F32);
  static const info = Color(0xFFA8C9EC);
  static const infoTint = Color(0xFF173744);
  static const radius = 18.0;

  static const buttonGradient = LinearGradient(
    begin: AlignmentDirectional.centerStart,
    end: AlignmentDirectional.centerEnd,
    colors: [orange, orangeDeep],
  );
}

/// A single static backdrop behind the navigator. Home and tracking keep their
/// own videos. This layer has no platform calls, input or semantic content.
class FasakhanstaAppBackground extends StatelessWidget {
  const FasakhanstaAppBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Positioned.fill(
          child: ExcludeSemantics(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: const BoxDecoration(
                  color: FasakhanstaBrand.background,
                  image: DecorationImage(
                    image: AssetImage('assets/images/home_hero_poster.jpg'),
                    fit: BoxFit.cover,
                    opacity: .11,
                  ),
                ),
                child: const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topRight,
                      end: Alignment.bottomLeft,
                      colors: [Color(0x08081F25), Color(0xDD081F25)],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        child,
      ],
    );
  }
}
