import 'package:flutter/material.dart';
import 'dart:math' as math;

class GradientBackground extends StatefulWidget {
  final Widget child;
  final bool showAnimatedElements;
  
  const GradientBackground({
    super.key,
    required this.child,
    this.showAnimatedElements = true,
  });

  @override
  _GradientBackgroundState createState() => _GradientBackgroundState();
}

class _GradientBackgroundState extends State<GradientBackground> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  // Define gradient colors for animation
  final List<List<Color>> _gradientSets = [
    [
      Color(0xFF1A2980),
      Color(0xFF26D0CE),
    ],
    [
      Color(0xFF4B0082), // Indigo
      Color(0xFF9370DB), // Medium Purple
    ],
    [
      Color(0xFF000428), // Deep Blue
      Color(0xFF004e92), // Royal Blue
    ],
    [
      Color(0xFF16222A), // Dark Slate
      Color(0xFF3A6073), // Steel Blue
    ],
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(seconds: 30), // Longer duration for smoother transitions
    )..repeat(reverse: false); // Don't reverse, complete 360° cycles
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        // Calculate the current gradient set based on animation value
        final currentIndex = (_controller.value * _gradientSets.length).floor();
        final nextIndex = (currentIndex + 1) % _gradientSets.length;
        final localProgress = (_controller.value * _gradientSets.length) % 1.0;
        
        // Interpolate between the current and next color sets
        final currentColors = _gradientSets[currentIndex];
        final nextColors = _gradientSets[nextIndex];
        
        final interpolatedColors = [
          Color.lerp(currentColors[0], nextColors[0], localProgress)!,
          Color.lerp(currentColors[1], nextColors[1], localProgress)!,
        ];
        
        return Stack(
          children: [
            // Base gradient with animated colors
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: interpolatedColors,
                ),
              ),
            ),
            
            // Dynamic rotating gradient overlay
            Opacity(
              opacity: 0.7,
              child: Container(
                decoration: BoxDecoration(
                  gradient: SweepGradient(
                    center: Alignment.center,
                    startAngle: 0,
                    endAngle: 2 * math.pi,
                    transform: GradientRotation(_controller.value * 2 * math.pi),
                    colors: [
                      Color.fromARGB(255, 248, 248, 248),
                      Color.fromARGB(255, 59, 225, 243),
                      Color.fromARGB(255, 49, 202, 236),
                      Color.fromARGB(255, 0, 255, 255),
                    ],
                  ),
                ),
              ),
            ),
            
            // Radial gradient for depth
            Opacity(
              opacity: 0.4,
              child: Container(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment(
                      math.cos(_controller.value * 2 * math.pi) * 0.5,
                      math.sin(_controller.value * 2 * math.pi) * 0.5,
                    ),
                    radius: 1.0,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.5),
                    ],
                    stops: [0.6, 1.0],
                  ),
                ),
              ),
            ),
            
            // Grid pattern using CustomPaint
            Opacity(
              opacity: 0.04 + (0.02 * math.sin(_controller.value * 2 * math.pi)), // Pulsating opacity
              child: CustomPaint(
                painter: GridPainter(),
                size: Size(MediaQuery.of(context).size.width, MediaQuery.of(context).size.height),
              ),
            ),
            
            if (widget.showAnimatedElements) ...[
              // Animated glowing circle 1
              Positioned(
                top: MediaQuery.of(context).size.height * 0.1,
                right: -MediaQuery.of(context).size.width * 0.15,
                child: _buildGlowingCircle(
                  color: interpolatedColors[0].withOpacity(0.2), // Use gradient color
                  size: MediaQuery.of(context).size.width * 0.4,
                  animation: _controller,
                ),
              ),
              
              // Animated glowing circle 2
              Positioned(
                bottom: -MediaQuery.of(context).size.height * 0.05,
                left: -MediaQuery.of(context).size.width * 0.1,
                child: _buildGlowingCircle(
                  color: interpolatedColors[1].withOpacity(0.15), // Use gradient color
                  size: MediaQuery.of(context).size.width * 0.4,
                  animation: _controller,
                  reverse: true,
                ),
              ),
              
              // Small floating particles with gradient colors
              ...List.generate(
                10,
                (index) => Positioned(
                  top: MediaQuery.of(context).size.height * (0.15 + (index * 0.08)),
                  left: MediaQuery.of(context).size.width * (0.1 + (index * 0.08 * math.sin(index))),
                  child: _buildParticle(
                    size: 4.0 + (index % 4) * 2,
                    // Alternate between gradient colors
                    color: index.isEven 
                        ? interpolatedColors[0]
                        : interpolatedColors[1],
                    animation: _controller,
                    offsetY: 15.0 + (index * 5),
                    delay: index / 10,
                  ),
                ),
              ),
            ],
            
            // Child content
            widget.child,
          ],
        );
      },
    );
  }
  
  Widget _buildGlowingCircle({
    required Color color,
    required double size,
    required Animation<double> animation,
    bool reverse = false,
  }) {
    final animValue = reverse ? 1 - animation.value : animation.value;
    final pulseSize = size * (0.9 + (animValue * 0.1));
    
    return Container(
      width: pulseSize,
      height: pulseSize,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color,
            blurRadius: size / 2,
            spreadRadius: size / 8,
          ),
        ],
      ),
    );
  }
  
  Widget _buildParticle({
    required double size,
    required Color color,
    required Animation<double> animation,
    required double offsetY,
    required double delay,
  }) {
    // Create a delayed animation value
    final delayedValue = (animation.value + delay) % 1.0;
    
    // Calculate vertical movement
    final verticalOffset = math.sin(delayedValue * 2 * math.pi) * offsetY;
    // Add slight horizontal movement too
    final horizontalOffset = math.cos(delayedValue * 2 * math.pi) * (offsetY / 3);
    
    return Transform.translate(
      offset: Offset(horizontalOffset, verticalOffset),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color.withOpacity(0.7),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: size,
              spreadRadius: size / 2,
            ),
          ],
        ),
      ),
    );
  }
}

// Custom painter for grid pattern
class GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.15)
      ..strokeWidth = 0.5
      ..style = PaintingStyle.stroke;

    // Draw horizontal lines
    final horizontalLineSpacing = 25.0; // Slightly larger spacing
    for (double y = 0; y < size.height; y += horizontalLineSpacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }

    // Draw vertical lines
    final verticalLineSpacing = 25.0;
    for (double x = 0; x < size.width; x += verticalLineSpacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    
    // Add some diagonal lines for more visual interest
    final diagonalSpacing = 100.0;
    final diagonalPaint = Paint()
      ..color = Colors.white.withOpacity(0.08)
      ..strokeWidth = 0.8
      ..style = PaintingStyle.stroke;
      
    for (double offset = 0; offset < size.width + size.height; offset += diagonalSpacing) {
      canvas.drawLine(
        Offset(math.min(offset, size.width), math.max(0, offset - size.width)),
        Offset(math.max(0, offset - size.height), math.min(offset, size.height)),
        diagonalPaint
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}