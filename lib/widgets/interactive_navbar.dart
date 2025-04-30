import 'package:crypto_flutter_app/screen/landing_screen.dart';
import 'package:crypto_flutter_app/screen/profile_screen.dart';
import 'package:crypto_flutter_app/screen/watchlist_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../screen/settings_screen.dart';

class NavbarItems extends StatefulWidget {
  const NavbarItems({super.key});

  @override
  _NavbarItemsState createState() => _NavbarItemsState();
}

class _NavbarItemsState extends State<NavbarItems> with SingleTickerProviderStateMixin {
  int _selectedIndex = 0;
  late AnimationController _animationController;
  
  final List<IconData> _icons = [
    Icons.home_rounded,
    Icons.star_rounded,
    Icons.person_rounded,
    Icons.settings_rounded,
  ];
  
  final List<String> _labels = [
    'Home',
    'Watchlist',
    'Profile',
    'Settings',
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 300),
    );
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 75, // Fixed height that's enough but not too large
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        // Updated gradient to match GradientNavbar for visual consistency
        gradient: LinearGradient(
          colors: [
            Color(0xFF1A2980), // Deep blue - matching profile screen gradient
            Color(0xFF26D0CE), // Teal - matching profile screen gradient
          ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(_icons.length, (index) {
            return _buildNavItem(_icons[index], _labels[index], index);
          }),
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String text, int index) {
    bool isSelected = _selectedIndex == index;
    
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          splashColor: Colors.white.withOpacity(0.1),
          highlightColor: Colors.transparent,
          onTap: () {
            HapticFeedback.lightImpact(); // Add haptic feedback
            setState(() {
              _selectedIndex = index;
            });
            _navigateToScreen(index);
          },
          child: AnimatedContainer(
            duration: Duration(milliseconds: 300),
            padding: EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: isSelected ? Colors.white.withOpacity(0.15) : Colors.transparent,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Animated icon with scale effect
                TweenAnimationBuilder<double>(
                  tween: Tween<double>(
                    begin: 0.8,
                    end: isSelected ? 1.0 : 0.8,
                  ),
                  duration: Duration(milliseconds: 200),
                  builder: (context, value, child) {
                    return Transform.scale(
                      scale: value,
                      child: Icon(
                        icon,
                        color: isSelected ? Colors.white : Colors.white60,
                        size: 24,
                      ),
                    );
                  },
                ),
                
                // Spacer with dynamic height to prevent overflow
                SizedBox(height: 3),
                
                // Text label
                Text(
                  text,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.white60,
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _navigateToScreen(int index) async {
    // Navigation logic based on the selected index
    switch (index) {
      case 0: // Home
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (_, __, ___) => LandingScreen(username: ''),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(opacity: animation, child: child);
            },
            transitionDuration: Duration(milliseconds: 250),
          ),
        );
        break;
        
      case 1: // Watchlist
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (_, __, ___) => WatchlistScreen(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(opacity: animation, child: child);
            },
            transitionDuration: Duration(milliseconds: 250),
          ),
        );
        break;
        
      case 2: // Profile
        User? user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          try {
            DocumentSnapshot userDoc = await FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .get();
            
            Navigator.pushReplacement(
              context,
              PageRouteBuilder(
                pageBuilder: (_, __, ___) => ProfileScreen(),
                transitionsBuilder: (context, animation, secondaryAnimation, child) {
                  return FadeTransition(opacity: animation, child: child);
                },
                transitionDuration: Duration(milliseconds: 250),
              ),
            );
          } catch (e) {
            print('Error fetching user data: $e');
            // Navigate anyway even if fetching failsz
            Navigator.pushReplacement(
              context,
              PageRouteBuilder(
                pageBuilder: (_, __, ___) => ProfileScreen(),
                transitionsBuilder: (context, animation, secondaryAnimation, child) {
                  return FadeTransition(opacity: animation, child: child);
                },
                transitionDuration: Duration(milliseconds: 250),
              ),
            );
          }
        } else {
          // Not logged in, navigate to profile screen anyway (it will show login UI)
          Navigator.pushReplacement(
            context,
            PageRouteBuilder(
              pageBuilder: (_, __, ___) => ProfileScreen(),
              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                return FadeTransition(opacity: animation, child: child);
              },
              transitionDuration: Duration(milliseconds: 250),
            ),
          );
        }
        break;
        
      case 3: // Settings
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (_, __, ___) => SettingsScreen(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(opacity: animation, child: child);
            },
            transitionDuration: Duration(milliseconds: 250),
          ),
        );
        break;
    }
  }
}
