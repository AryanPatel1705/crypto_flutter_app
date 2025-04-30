import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:crypto_flutter_app/screen/auth_page.dart';
import 'package:crypto_flutter_app/screen/landing_screen.dart';
import 'package:crypto_flutter_app/screen/profile_screen.dart';
import 'package:crypto_flutter_app/widgets/gardientnavbar.dart';
import 'package:shimmer/shimmer.dart'; // Add shimmer package import
import 'dart:math' as math;

class WatchlistScreen extends StatefulWidget {
  const WatchlistScreen({super.key});

  @override
  _WatchlistScreenState createState() => _WatchlistScreenState();
}

class _WatchlistScreenState extends State<WatchlistScreen> with TickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<Map<String, dynamic>> _watchlist = [];
  bool _isLoading = true;
  
  // Animation controllers
  late AnimationController _backgroundAnimController;
  late Animation<double> _backgroundAnim;
  
  late AnimationController _floatingElementsController;
  
  // TabController for navbar
  late TabController _tabController;
  
  @override
  bool get wantKeepAlive => true; // Keep the screen state when switching tabs
  
  @override
  void initState() {
    super.initState();
    _loadWatchlist();
    
    // Initialize animation controllers
    _backgroundAnimController = AnimationController(
      vsync: this,
      duration: Duration(seconds: 20),
    )..repeat(reverse: true);
    
    _backgroundAnim = CurvedAnimation(
      parent: _backgroundAnimController,
      curve: Curves.easeInOut,
    );
    
    _floatingElementsController = AnimationController(
      vsync: this,
      duration: Duration(seconds: 12),
    )..repeat();
    
    // Initialize tab controller with 3 tabs - Profile, Activity, Watchlist
    _tabController = TabController(length: 3, vsync: this, initialIndex: 2);
  }
  
  @override
  void dispose() {
    _backgroundAnimController.dispose();
    _floatingElementsController.dispose();
    _tabController.dispose();
    super.dispose();
  }
  
  // Load watchlist from Firestore
  Future<void> _loadWatchlist() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      if (_auth.currentUser != null) {
        // User is logged in, get their watchlist from Firestore
        final snapshot = await _firestore
            .collection('users')
            .doc(_auth.currentUser!.uid)
            .collection('watchlist')
            .get();

        final List<Map<String, dynamic>> watchlistData = snapshot.docs.map((doc) {
          return {
            'id': doc.id,
            'name': doc.data()['name'] ?? 'Unknown',
            'symbol': doc.data()['symbol'] ?? 'UNKNOWN',
            'price': doc.data()['price'] ?? 0.0,
            'change': doc.data()['change'] ?? 0.0,
            'image': doc.data()['image'],
          };
        }).toList();

        setState(() {
          _watchlist = watchlistData;
          _isLoading = false;
        });
      } else {
        // User is not logged in
        setState(() {
          _watchlist = [];
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading watchlist: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  // Remove crypto from watchlist
  Future<void> _removeFromWatchlist(Map<String, dynamic> crypto) async {
    try {
      if (_auth.currentUser != null) {
        await _firestore
            .collection('users')
            .doc(_auth.currentUser!.uid)
            .collection('watchlist')
            .doc(crypto['id'])
            .delete();
            
        setState(() {
          _watchlist.removeWhere((item) => item['id'] == crypto['id']);
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${crypto['name']} removed from watchlist'),
            backgroundColor: Colors.teal,
          ),
        );
      }
    } catch (e) {
      print('Error removing from watchlist: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error removing from watchlist'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  
  @override
  Widget build(BuildContext context) {
    super.build(context);
    
    return Scaffold(
      body: Stack(
        children: [
          // Animated Background
          AnimatedBuilder(
            animation: _backgroundAnim,
            builder: (context, child) {
              return Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color(0xFF0D1F32),
                      Color.lerp(Color(0xFF0D1F32), Color(0xFF03A1A1), _backgroundAnim.value)!,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              );
            },
          ),
          
          // Floating Elements
          AnimatedBuilder(
            animation: _floatingElementsController,
            builder: (context, child) {
              return Stack(
                children: List.generate(15, (index) {
                  final size = 10.0 + (index % 3) * 8.0;
                  final opacity = 0.05 + (index % 5) * 0.03;
                  final speed = 0.5 + (index % 4) * 0.2;
                  final angle = _floatingElementsController.value * 2 * math.pi * speed;
                  final radius = 100.0 + (index % 5) * 30.0;
                  
                  return Positioned(
                    left: MediaQuery.of(context).size.width / 2 + radius * math.cos(angle + index),
                    top: MediaQuery.of(context).size.height / 2 + radius * math.sin(angle + index * 2),
                    child: Transform.rotate(
                      angle: angle,
                      child: Container(
                        width: size,
                        height: size,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(opacity),
                          borderRadius: BorderRadius.circular(size/2),
                        ),
                      ),
                    ),
                  );
                }),
              );
            },
          ),
          
          // Main Content
          SafeArea(
            child: Column(
              children: [
                // App Bar
                _buildAppBar(),
                
                // Watchlist Content - wrapped in Expanded to take available space
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Watchlist header
                      Padding(
                        padding: EdgeInsets.all(16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.star_rounded,
                                  color: Colors.amber,
                                  size: 28,
                                ),
                                SizedBox(width: 12),
                                Text(
                                  'Your Watchlist',
                                  style: TextStyle(
                                    color: const Color.fromARGB(255, 157, 144, 144),
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            if (_auth.currentUser != null)
                              _buildRefreshButton(),
                          ],
                        ),
                      ),
                      
                      // Login prompt or empty state or watchlist
                      Expanded(
                        child: _isLoading 
                          ? _buildLoadingIndicator()
                          : _auth.currentUser == null
                            ? _buildLoginPrompt()
                            : _watchlist.isEmpty
                              ? _buildEmptyWatchlist()
                              : _buildWatchlistContent(),
                      ),
                    ],
                  ),
                ),
                
                // Gradient Navbar at bottom
                GradientNavbar(
                  tabController: _tabController,
                  onTabSelected: (index) {
                    if (index == 0) {
                      // Navigate to Profile
                      Navigator.pushReplacement(
                        context,
                        PageRouteBuilder(
                          pageBuilder: (_, __, ___) => ProfileScreen(),
                          transitionsBuilder: (context, animation, secondaryAnimation, child) {
                            return FadeTransition(opacity: animation, child: child);
                          },
                          transitionDuration: Duration(milliseconds: 300),
                        ),
                      );
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildAppBar() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.1),
        border: Border(
          bottom: BorderSide(
            color: Colors.white.withOpacity(0.1),
            width: 1,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // App logo or title
          Row(
            children: [
              Image.asset(
                'assets/images/logo.png',
                height: 32,
                width: 32,
                errorBuilder: (context, error, stackTrace) => 
                  Icon(Icons.currency_bitcoin, color: Colors.teal, size: 32),
              ),
              SizedBox(width: 8),
              Text(
                'CryptoTracker',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          
          // User avatar or login button
          _auth.currentUser != null
              ? GestureDetector(
                  onTap: () {
                    Navigator.pushReplacement(
                      context, 
                      MaterialPageRoute(builder: (_) => ProfileScreen()),
                    );
                  },
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [Colors.teal, Colors.cyan],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        _auth.currentUser!.email?.substring(0, 1).toUpperCase() ?? 'U',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ),
                  ),
                )
              : TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => AuthPage()),
                    ).then((_) => _loadWatchlist());
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.teal,
                  ),
                  child: Text(
                    'Sign In',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
        ],
      ),
    );
  }
  
  Widget _buildRefreshButton() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: IconButton(
        icon: Icon(Icons.refresh_rounded, color: Colors.white),
        onPressed: () {
          _loadWatchlist();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Updating watchlist...'),
              backgroundColor: Colors.teal,
              duration: Duration(seconds: 1),
            ),
          );
        },
        tooltip: 'Refresh watchlist',
        iconSize: 22,
      ),
    );
  }
  
  Widget _buildLoadingIndicator() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.teal),
          ),
          SizedBox(height: 16),
          Text(
            'Loading watchlist...',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildLoginPrompt() {
    return Center(
      child: Container(
        padding: EdgeInsets.all(24),
        margin: EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            colors: [
              Colors.blueGrey.shade900.withOpacity(0.7),
              Colors.blueGrey.shade800.withOpacity(0.5),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(
            color: Colors.white.withOpacity(0.1),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 15,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Star icon with shimmer effect
            ShimmerIcon(
              child: Icon(
                Icons.star,
                size: 80,
                color: Colors.amber,
              ),
            ),
            SizedBox(height: 24),
            Text(
              'Track Your Favorites',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 12),
            Text(
              'Sign in to create and manage your cryptocurrency watchlist',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white70,
                fontSize: 16,
                height: 1.5,
              ),
            ),
            SizedBox(height: 32),
            AnimatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => AuthPage()),
                ).then((_) => _loadWatchlist());
              },
              child: Text(
                'Sign In',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildEmptyWatchlist() {
    return Center(
      child: Container(
        padding: EdgeInsets.all(24),
        margin: EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            colors: [
              Colors.blueGrey.shade900.withOpacity(0.7),
              Colors.blueGrey.shade800.withOpacity(0.5),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(
            color: Colors.white.withOpacity(0.1),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 15,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.amber.withOpacity(0.1),
              ),
              child: Icon(
                Icons.star_border_rounded,
                size: 64,
                color: Colors.amber.withOpacity(0.8),
              ),
            ),
            SizedBox(height: 24),
            Text(
              'Your Watchlist is Empty',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 12),
            Text(
              'Add cryptocurrencies to your watchlist\nfrom the Home screen',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white70,
                fontSize: 16,
                height: 1.5,
              ),
            ),
            SizedBox(height: 32),
            AnimatedButton(
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => LandingScreen()),
                );
              },
              backgroundColor: Colors.amber,
              textColor: Colors.black87,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.add, size: 18),
                  SizedBox(width: 8),
                  Text(
                    'Add Cryptocurrencies',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildWatchlistContent() {
    return ListView.builder(
      padding: EdgeInsets.symmetric(horizontal: 16),
      itemCount: _watchlist.length,
      itemBuilder: (context, index) {
        final crypto = _watchlist[index];
        final isPositive = crypto['change'] >= 0;
        
        return AnimatedCryptoCard(
          crypto: crypto, 
          isPositive: isPositive,
          onTap: () {
            // Navigate to crypto detail page
          },
          onRemove: () => _removeFromWatchlist(crypto),
        );
      },
    );
  }
}

// Animated Crypto Card with entrance animation
class AnimatedCryptoCard extends StatefulWidget {
  final Map<String, dynamic> crypto;
  final bool isPositive;
  final VoidCallback onTap;
  final VoidCallback onRemove;
  
  const AnimatedCryptoCard({
    super.key,
    required this.crypto,
    required this.isPositive,
    required this.onTap,
    required this.onRemove,
  });
  
  @override
  _AnimatedCryptoCardState createState() => _AnimatedCryptoCardState();
}

class _AnimatedCryptoCardState extends State<AnimatedCryptoCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacity;
  late Animation<Offset> _slideIn;
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 600),
    );
    
    _opacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );
    
    _slideIn = Tween<Offset>(
      begin: Offset(0.0, 0.2),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );
    
    _controller.forward();
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: SlideTransition(
        position: _slideIn,
        child: Container(
          margin: EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              colors: [
                Colors.blueGrey.shade900.withOpacity(0.7),
                Color(0xFF142E46).withOpacity(0.7),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: Offset(0, 4),
              ),
            ],
            border: Border.all(
              color: Colors.white.withOpacity(0.1),
              width: 1,
            ),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: widget.onTap,
              splashColor: Colors.teal.withOpacity(0.1),
              highlightColor: Colors.teal.withOpacity(0.05),
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Row(
                  children: [
                    // Crypto image
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 5,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Center(
                        child: widget.crypto['image'] != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(25),
                              child: CachedNetworkImage(
                                imageUrl: widget.crypto['image'],
                                placeholder: (context, url) => CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white70),
                                ),
                                errorWidget: (context, url, error) => Text(
                                  widget.crypto['symbol'].substring(0, 1).toUpperCase(),
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                ),
                                height: 40,
                                width: 40,
                                fit: BoxFit.cover,
                              ),
                            )
                          : Text(
                              widget.crypto['symbol'].substring(0, 1).toUpperCase(),
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                      ),
                    ),
                    SizedBox(width: 16),
                    
                    // Crypto details
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.crypto['name'],
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            widget.crypto['symbol'].toUpperCase(),
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Price info
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '\$${widget.crypto['price'].toStringAsFixed(2)}',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        SizedBox(height: 4),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: widget.isPositive
                              ? Colors.green.withOpacity(0.3)
                              : Colors.red.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${widget.isPositive ? "+" : ""}${widget.crypto['change']}%',
                            style: TextStyle(
                              color: widget.isPositive ? Colors.green : Colors.red,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                    
                    // Remove button
                    IconButton(
                      icon: Icon(
                        Icons.star,
                        color: Colors.amber,
                      ),
                      onPressed: widget.onRemove,
                      tooltip: 'Remove from watchlist',
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Shimmer effect for icons
class ShimmerIcon extends StatelessWidget {
  final Widget child;
  
  const ShimmerIcon({super.key, required this.child});
  
  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.amber.shade300,
      highlightColor: Colors.amber.shade100,
      period: Duration(seconds: 2),
      child: child,
    );
  }
}

// Animated Button
class AnimatedButton extends StatefulWidget {
  final Widget child;
  final VoidCallback onPressed;
  final Color? backgroundColor;
  final Color? textColor;
  
  const AnimatedButton({
    super.key,
    required this.child,
    required this.onPressed,
    this.backgroundColor,
    this.textColor,
  });
  
  @override
  _AnimatedButtonState createState() => _AnimatedButtonState();
}

class _AnimatedButtonState extends State<AnimatedButton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 150),
    );
    
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    final Color bgColor = widget.backgroundColor ?? Colors.teal;
    final Color txtColor = widget.textColor ?? Colors.white;
    
    return GestureDetector(
      onTapDown: (_) {
        setState(() => _isPressed = true);
        _controller.forward();
      },
      onTapUp: (_) {
        setState(() => _isPressed = false);
        _controller.reverse();
        widget.onPressed();
      },
      onTapCancel: () {
        setState(() => _isPressed = false);
        _controller.reverse();
      },
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 30, vertical: 14),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    bgColor,
                    Color.lerp(bgColor, Colors.white, 0.2)!,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(30),
                boxShadow: _isPressed ? [] : [
                  BoxShadow(
                    color: bgColor.withOpacity(0.4),
                    blurRadius: 12,
                    offset: Offset(0, 6),
                  ),
                ],
              ),
              child: DefaultTextStyle(
                style: TextStyle(
                  color: txtColor,
                  fontSize: 16,
                ),
                child: widget.child,
              ),
            ),
          );
        },
      ),
    );
  }
}