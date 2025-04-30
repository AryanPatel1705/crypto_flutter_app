
// Create a new file for this widget: lib/widgets/futuristic_welcome_widget.dart
import 'package:flutter/material.dart';

class FuturisticWelcomeWidget extends StatelessWidget {
  final String username;
  final AnimationController slideController;
  final AnimationController glowController;

  const FuturisticWelcomeWidget({super.key, 
    required this.username,
    required this.slideController,
    required this.glowController,
  });

  @override
  Widget build(BuildContext context) {
    // Slide in animation
    final slideAnimation = Tween<Offset>(
      begin: Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: slideController,
      curve: Curves.easeOutExpo,
    ));

    // Glow effect animation
    final glowAnimation = Tween<double>(
      begin: 0.0,
      end: 10.0,
    ).animate(CurvedAnimation(
      parent: glowController,
      curve: Curves.easeInOut,
    ));

    // Typewriter effect animation
    final typewriterAnimation = Tween<double>(
      begin: 0,
      end: username.length.toDouble(),
    ).animate(CurvedAnimation(
      parent: slideController,
      curve: Interval(0.3, 0.7, curve: Curves.linear),
    ));

    return SlideTransition(
      position: slideAnimation,
      child: AnimatedBuilder(
        animation: glowAnimation,
        builder: (context, child) {
          return Container(
            margin: EdgeInsets.symmetric(horizontal: 20),
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15),
              color: Colors.black.withOpacity(0.4),
              boxShadow: [
                BoxShadow(
                  color: Colors.cyanAccent.withOpacity(0.2 + (glowAnimation.value / 30)),
                  blurRadius: 10 + glowAnimation.value,
                  spreadRadius: 2 + (glowAnimation.value / 5),
                ),
              ],
              border: Border.all(
                color: Colors.cyanAccent.withOpacity(0.3 + (glowAnimation.value / 20)),
                width: 1.5,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Welcome message
                Text(
                  'WELCOME BACK',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w300,
                    letterSpacing: 3,
                    shadows: [
                      Shadow(
                        blurRadius: 5 + glowAnimation.value / 2, 
                        color: Colors.cyanAccent.withOpacity(0.5),
                        offset: Offset(0, 0),
                      ),
                    ],
                  ),
                ),
                
                SizedBox(height: 10),
                
                // Animated username with typewriter effect
                AnimatedBuilder(
                  animation: typewriterAnimation,
                  builder: (context, child) {
                    final displayText = username.substring(
                      0, 
                      typewriterAnimation.value.toInt().clamp(0, username.length)
                    );
                    
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          displayText,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.5,
                            shadows: [
                              Shadow(
                                blurRadius: 8 + glowAnimation.value,
                                color: Colors.cyanAccent.withOpacity(0.7),
                                offset: Offset(0, 0),
                              ),
                            ],
                          ),
                        ),
                        
                        // Blinking cursor
                        if (typewriterAnimation.value < username.length)
                          AnimatedOpacity(
                            opacity: (DateTime.now().millisecondsSinceEpoch % 1000) > 500 ? 1.0 : 0.0, 
                            duration: Duration(milliseconds: 100),
                            child: Text(
                              '|',
                              style: TextStyle(
                                color: Colors.cyanAccent,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                ),
                
                SizedBox(height: 10),
                
                // Status line with loading dots
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Let`s make some money💸💸💸',
                      style: TextStyle(
                        color: Colors.greenAccent,
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    
                    // Loading dots animation
                    AnimatedBuilder(
                      animation: glowController,
                      builder: (context, child) {
                        final time = DateTime.now().millisecondsSinceEpoch;
                        return Row(
                          children: List.generate(3, (index) {
                            return Opacity(
                              opacity: (time % 1000) > (index * 333) ? 1.0 : 0.3,
                              child: Text(
                                '•',
                                style: TextStyle(
                                  color: Colors.greenAccent,
                                  fontSize: 14,
                                ),
                              ),
                            );
                          }),
                        );
                      },
                    ),
                  ],
                ),
                
                SizedBox(height: 15),
                
                // Futuristic line decoration
                Container(
                  height: 1,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.transparent,
                        Colors.cyanAccent.withOpacity(0.5 + (glowAnimation.value / 20)),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
                
                // Future-dated timestamp
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    'The future is now',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 10,
                      letterSpacing: 1,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}