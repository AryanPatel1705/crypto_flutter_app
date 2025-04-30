import 'package:crypto_flutter_app/screen/landing_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class GradientNavbar extends StatefulWidget {
  final TabController tabController;
  final Function(int) onTabSelected;

  const GradientNavbar({
    super.key,
    required this.tabController,
    required this.onTabSelected,
  });

  @override
  State<GradientNavbar> createState() => _GradientNavbarState();
}

class _GradientNavbarState extends State<GradientNavbar> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  int _currentIndex = 0;
  final List<String> _tabNames = ["Portfolio", "Activity", "Watchlist","Home"];
  final List<IconData> _tabIcons = [
    Icons.account_balance_wallet_outlined,
    Icons.analytics_outlined,
    Icons.star_outline_rounded,
    Icons.home_rounded,
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 400),
    );
    
    // Sync with tabController
    _currentIndex = widget.tabController.index;
    widget.tabController.addListener(_handleTabChange);
  }
  
  void _handleTabChange() {
    if (widget.tabController.indexIsChanging || 
        widget.tabController.index != _currentIndex) {
      setState(() {
        _currentIndex = widget.tabController.index;
      });
    }
  }

  @override
  void dispose() {
    widget.tabController.removeListener(_handleTabChange);
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 68,
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        gradient: LinearGradient(
          colors: [
            Color(0xFF1A2980),
            Color(0xFF26D0CE),
          ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 15,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(
          _tabNames.length,
          (index) => _buildNavItem(index),
        ),
      ),
    );
  }
  
  Widget _buildNavItem(int index) {
    // Ensure tab index is always in sync with tabController for proper highlighting
    final bool isSelected = index < 3 ? widget.tabController.index == index : _currentIndex == index;
    
    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          
          // Update current index state
          setState(() {
            _currentIndex = index;
          });
          
          // Handle navigation based on tab index
          if (index == 3) { // Home tab
            // Navigate to home screen
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (context) => LandingScreen()),
              (route) => false, // Remove all previous routes
            );
          } else {
            // For other tabs, use the tab controller
            widget.tabController.animateTo(index);
            widget.onTabSelected(index); // Call the callback
          }
        },
        child: AnimatedContainer(
          duration: Duration(milliseconds: 300),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            color: isSelected ? Colors.white.withOpacity(0.2) : Colors.transparent,
          ),
          padding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          margin: EdgeInsets.all(6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                _tabIcons[index],
                color: isSelected ? Colors.white : Colors.white70,
                size: isSelected ? 24 : 20,
              ),
              if (isSelected) ...[
                SizedBox(width: 8),
                Flexible(
                  child: Text(
                    _tabNames[index],
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}