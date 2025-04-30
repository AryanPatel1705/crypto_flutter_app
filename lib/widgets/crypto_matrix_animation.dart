import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cryptocoins_icons/cryptocoins_icons.dart';

class CryptoMatrixAnimation extends StatefulWidget {
  final Duration duration;

  const CryptoMatrixAnimation({
    super.key,
    this.duration = const Duration(seconds: 2),
  });

  @override
  State<CryptoMatrixAnimation> createState() => _CryptoMatrixAnimationState();
}

class _CryptoMatrixAnimationState extends State<CryptoMatrixAnimation> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final Random _random = Random();
  final List<FallingCryptoSymbol> _symbols = [];
  
  // List of common cryptocurrency icons from the CryptoCoinIcons package
  final List<IconData> _cryptoIcons = [
    CryptoCoinIcons.BTC,
    CryptoCoinIcons.ETH,
    CryptoCoinIcons.ADA,
    CryptoCoinIcons.LTC,  
    CryptoCoinIcons.BRK,
    CryptoCoinIcons.XRP,
    CryptoCoinIcons.DAO,
    CryptoCoinIcons.DOGE,
    CryptoCoinIcons.SIA,
    CryptoCoinIcons.AMP,
    CryptoCoinIcons.MINT,
    CryptoCoinIcons.LTC,
    CryptoCoinIcons.LBC,
    CryptoCoinIcons.AEON,
    CryptoCoinIcons.XEM,
    CryptoCoinIcons.ARCH,
  ];

  // Gradient colors for the background
  final List<Color> _gradientColors = [
    Color(0xFF000428),
    Color(0xFF004e92),
  ];

  Timer? _symbolGeneratorTimer;
  Timer? _completionTimer;

  @override
  void initState() {
    super.initState();
    
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: false);

    // Timer to add new symbols periodically
    _symbolGeneratorTimer = Timer.periodic(Duration(milliseconds: 150), (_) {
      if (mounted) {
        _addNewSymbol();
      }
    });
    
    // Timer to track when the animation should complete
    _completionTimer = Timer(widget.duration, () {
      // Animation will be stopped when the widget is disposed
    });
  }

  void _addNewSymbol() {
    if (_symbols.length < 100) { // Limit the number of symbols
      setState(() {
        _symbols.add(_createRandomSymbol());
      });
    }
  }

  FallingCryptoSymbol _createRandomSymbol() {
    final screenWidth = MediaQuery.of(context).size.width;
    final x = _random.nextDouble() * screenWidth;
    final speed = _random.nextDouble() * 3 + 1; // Random speed between 1 and 4
    final size = _random.nextDouble() * 15 + 10; // Random size between 10 and 25
    final iconIndex = _random.nextInt(_cryptoIcons.length);
    final opacity = _random.nextDouble() * 0.7 + 0.3; // Random opacity between 0.3 and 1.0
    final color = _getRandomColor();
    
    return FallingCryptoSymbol(
      x: x,
      y: -size,  // Start above the screen
      speed: speed,
      size: size,
      icon: _cryptoIcons[iconIndex],
      color: color.withOpacity(opacity),
    );
  }

  Color _getRandomColor() {
    // Generate colors that look good for a matrix effect
    // Primarily using greens and blues with occasional gold/yellow for bitcoin
    final colorChoice = _random.nextInt(10);
    if (colorChoice < 6) { // 60% chance of green shades
      return Color.fromARGB(
        255,
        _random.nextInt(30),
        150 + _random.nextInt(106), // 150-255
        _random.nextInt(100),
      );
    } else if (colorChoice < 9) { // 30% chance of blue shades
      return Color.fromARGB(
        255,
        _random.nextInt(30),
        _random.nextInt(100),
        150 + _random.nextInt(106), // 150-255
      );
    } else { // 10% chance of gold/yellow (for Bitcoin)
      return Color.fromARGB(
        255,
        200 + _random.nextInt(56), // 200-255
        170 + _random.nextInt(86), // 170-255
        _random.nextInt(30),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _symbolGeneratorTimer?.cancel();
    _completionTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        // Update the position of each symbol
        for (var symbol in _symbols) {
          symbol.y += symbol.speed;
        }
        
        // Remove symbols that have fallen off the screen
        _symbols.removeWhere((symbol) => symbol.y > screenHeight);
        
        return Stack(
          children: [
            // Gradient background
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: _gradientColors,
                ),
              ),
            ),
            
            // Overlay for matrix effect
            CustomPaint(
              painter: MatrixOverlayPainter(screenWidth, screenHeight),
              size: Size(screenWidth, screenHeight),
            ),
            
            // Falling crypto symbols
            ...List.generate(_symbols.length, (index) {
              final symbol = _symbols[index];
              return Positioned(
                left: symbol.x,
                top: symbol.y,
                child: Icon(
                  symbol.icon,
                  size: symbol.size,
                  color: symbol.color,
                ),
              );
            }),
            
            // App logo or branding in the center
            /*Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // App logo (assuming you have one in assets)
                  Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Image.asset(
                   //   'assets/images/logo.png',
                      width: 150,
                      height: 150,
                    ),
                  ),
                  
                  // Loading text with animation
                  AnimatedOpacity(
                    opacity: _controller.value,
                    duration: Duration(milliseconds: 500),
                    child: Text(
                      'Initializing',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),*/
          ],
        );
      },
    );
  }
}

// Class to represent a falling cryptocurrency symbol
class FallingCryptoSymbol {
  double x;
  double y;
  final double speed;
  final double size;
  final IconData icon;
  final Color color;
  
  FallingCryptoSymbol({
    required this.x,
    required this.y,
    required this.speed,
    required this.size,
    required this.icon,
    required this.color,
  });
}

// Custom painter for the matrix effect overlay
class MatrixOverlayPainter extends CustomPainter {
  final double width;
  final double height;
  
  MatrixOverlayPainter(this.width, this.height);
  
  @override
  void paint(Canvas canvas, Size size) {
    // Add a subtle grid pattern
    final paint = Paint()
      ..color = Colors.green.withOpacity(0.05)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.3;
    
    // Draw vertical lines
    for (double x = 0; x < width; x += 20) {
      canvas.drawLine(Offset(x, 0), Offset(x, height), paint);
    }
    
    // Draw horizontal lines
    for (double y = 0; y < height; y += 20) {
      canvas.drawLine(Offset(0, y), Offset(width, y), paint);
    }
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}