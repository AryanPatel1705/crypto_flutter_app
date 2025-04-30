// lib/widgets/animated_navbar_title.dart
import 'package:flutter/material.dart';
import 'package:animated_text_kit/animated_text_kit.dart';

class AnimatedNavbarTitle extends StatelessWidget {
  const AnimatedNavbarTitle({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: 20), // Add padding for visual appeal
      child: Center(
        child: SizedBox(
          width: 250.0,
          child: DefaultTextStyle(
            style: const TextStyle(
              fontSize: 24.0,
              fontWeight: FontWeight.bold,
              color: Color.fromARGB(255, 252, 252, 252), // Very dark gray for neon effect
              shadows: [
                Shadow(
                  blurRadius: 10.0,
                  color: Color(0xFF0A0A0A), // Same dark gray color for shadow
                  offset: Offset(0, 0),
                ),
                Shadow(
                  blurRadius: 20.0,
                  color: Color(0xFF0A0A0A), // Same dark gray color for shadow
                  offset: Offset(0, 0),
                ),
              ],
            ),
            child: AnimatedTextKit(
              animatedTexts: [
                RotateAnimatedText('Crypto Tracking💸', duration: Duration(milliseconds: 1500)),
                RotateAnimatedText('Future Finance💰', duration: Duration(milliseconds: 1500)),
                RotateAnimatedText('Digital Assets📈', duration: Duration(milliseconds: 1500)),
              ],
              isRepeatingAnimation: true,
              repeatForever: true,
              pause: const Duration(milliseconds: 1000),
            ),
          ),
        ),
      ),
    );
  }
}
