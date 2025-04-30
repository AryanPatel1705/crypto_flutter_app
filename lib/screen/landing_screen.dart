// lib/screens/landing_screen.dart
import 'package:crypto_flutter_app/screen/auth_page.dart';
import 'package:crypto_flutter_app/widgets/cryptocurrencylist.dart';
import 'package:crypto_flutter_app/widgets/futuristic_welcome_widget.dart';
import 'package:crypto_flutter_app/widgets/gradient_background.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import '../widgets/animated_navbar_title.dart'; // Import animated title widget
import '../widgets/interactive_navbar.dart' as widgets; // Import navbar items widget 

class LandingScreen extends StatefulWidget {
  final String username;

  const LandingScreen({super.key, this.username = ''});

  @override
  _LandingScreenState createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen> with TickerProviderStateMixin {
  late AnimationController _backgroundAnimationController;
  late Animation<Color?> _colorAnimation;
  
  // Add new animation controllers for welcome animation
  late AnimationController _welcomeSlideController;
  late AnimationController _welcomeGlowController;
  
  // Track if user is logged in
  bool _isLoggedIn = false;
  String _displayName = '';
  
  // Add a map to store price subscriptions
  final Map<String, StreamSubscription<double>> _priceSubscriptions = {};
  
  // Add a variable to control welcome visibility
  bool _showWelcome = false;
  Timer? _welcomeTimer;
  
  // Key for shared preferences
  static const String _firstLoginKey = 'first_login_';

  @override
  void initState() {
    super.initState();
    
    // Initialize background animation controller
    _backgroundAnimationController = AnimationController(
      vsync: this,
      duration: Duration(seconds: 5),
    )..repeat(reverse: true);

    // Create color animation
    _colorAnimation = ColorTween(
      begin: Color.fromARGB(255, 252, 235, 3), // Neon green
      end: Color.fromARGB(255, 72, 0, 255), // Neon magenta
    ).animate(_backgroundAnimationController);
    
    // Initialize welcome animations
    _welcomeSlideController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 1200),
    );
    
    _welcomeGlowController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 2000),
    )..repeat(reverse: true);
    
    _initUser();
  }

  void _initUser() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      // Get shared preferences instance
      final prefs = await SharedPreferences.getInstance();
      // Create a unique key for this user
      final userFirstLoginKey = _firstLoginKey + user.uid;
      // Check if this is the first login (default to true if key doesn't exist)
      final isFirstLogin = prefs.getBool(userFirstLoginKey) ?? true;
      
      setState(() {
        _isLoggedIn = true;
        _displayName = user.displayName ?? user.email?.split('@')[0] ?? '';
        // Only show welcome if this is the first login
        _showWelcome = isFirstLogin;
      });
      
      if (isFirstLogin) {
        // Set the flag to false so it won't show on subsequent logins
        await prefs.setBool(userFirstLoginKey, false);
        
        // Start welcome animations
        _welcomeSlideController.forward();
        
        // Set timer to hide welcome after 5 seconds
        _welcomeTimer = Timer(Duration(seconds: 5), () {
          // Create a slide-out animation
          _welcomeSlideController.reverse().then((_) {
            if (mounted) {
              setState(() {
                _showWelcome = false;
              });
            }
          });
        });
      }
    }
  }

  @override
  void dispose() {
    // Cancel all price subscriptions
    for (var subscription in _priceSubscriptions.values) {
      subscription.cancel();
    }
    _welcomeTimer?.cancel(); // Cancel the timer
    _priceSubscriptions.clear();
    _backgroundAnimationController.dispose();
    _welcomeSlideController.dispose();
    _welcomeGlowController.dispose();
    super.dispose();
  }
   
  
 
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Using GradientBackground for unified look with profile screen
          GradientBackground(
            child: Column(
              children: [
                SizedBox(height: 80), // Provide space for the AnimatedNavbarTitle
                widgets.NavbarItems(), // Fixed navigation items row
                
                // Add the CryptoCurrencyList widget to the layout
                Expanded(
                  child: CryptoCurrencyList(), // Display the list of cryptocurrencies
                ),
              ],
            ),
          ),
          
          // AnimatedNavbarTitle positioned at the top
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: AnimatedNavbarTitle(),
          ),
          
          // Show login button only if not logged in
          if (!_isLoggedIn)
            Positioned(
              bottom: 20,
              left: 0,
              right: 0,
              child: Center(
                child: ElevatedButton(
                  onPressed: () {
                    // Use a reliable navigation approach
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (context) => AuthPage()),
                      );
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.purple.shade800,
                    padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    elevation: 5,
                    shadowColor: Colors.black.withOpacity(0.5),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.login, size: 20),
                      SizedBox(width: 10),
                      Text(
                        'Login',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ), // CryptoDetailScreen widget
          // Show welcome animation if logged in AND _showWelcome is true
          if (_isLoggedIn && _showWelcome)
            Positioned(
              top: 80, // Position below the navbar title
              left: 0,
              right: 0,
              child: FuturisticWelcomeWidget(
                username: _displayName,
                slideController: _welcomeSlideController,
                glowController: _welcomeGlowController,
              ),
            ),
        ],
      ),
    );
  }
}
