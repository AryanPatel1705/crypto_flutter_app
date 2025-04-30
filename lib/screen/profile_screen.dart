import 'dart:math';
import 'dart:async';
import 'package:crypto_flutter_app/models/crypto_model.dart';
import 'package:crypto_flutter_app/services/crypto_service.dart'; // Import the CryptoService

import 'package:crypto_flutter_app/screen/auth_page.dart';
import 'package:crypto_flutter_app/screen/watchlist_screen.dart';
import 'package:crypto_flutter_app/widgets/gardientnavbar.dart';
import 'package:crypto_flutter_app/widgets/gradient_background.dart';
import 'package:crypto_flutter_app/widgets/portfolio_timeline_graph.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Add this import
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:crypto_flutter_app/services/coin_gecko_service.dart';

class ProfileScreen extends StatefulWidget {
  // Remove the username parameter since we'll fetch it from Firebase
  const ProfileScreen({super.key});

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with TickerProviderStateMixin {
  // State variables
  late TabController _tabController;
  final List<Color> gradientColors = [
    const Color(0xff23b6e6),
    const Color(0xff02d39a),
  ];
  
  // Firebase related
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final CryptoService _cryptoService = CryptoService();
  
  // User data
  User? _user;
  String _displayName = '';
  bool _isLoading = true;
  
  // Portfolio data
  List<Map<String, dynamic>> portfolioData = [];
  bool _portfolioDataFetched = false;
  
  // Crypto data  
  List<Map<String, dynamic>> _trendingCryptos = [];
  bool _isLoadingTrending = true;
  List<CryptoModel> _cryptos = [];
  List<Map<String, dynamic>> cryptocurrencies = [];
  
  // Timers & animations
  Timer? _priceUpdateTimer;
  late AnimationController _animationController;

  @override
  Widget build(BuildContext context) {
    if (!mounted) return const SizedBox.shrink();
    
    double totalPortfolioValue = portfolioData.fold<double>(
      0, (double sum, Map<String, dynamic> item) => sum + ((item['amount'] as num).toDouble() * (item['value'] as num).toDouble()));

    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      body: GradientBackground(
        child: SafeArea(
          child: Column(
            children: [
              _buildAppBar(),
              
              // Tab Bar with custom styling
              Container(
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: Colors.white.withOpacity(0.2), width: 1),
                  ),
                ),
              ),
              
              // Content area (scrollable)
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    // Portfolio tab with its own scrolling
                    SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildProfileHeader(totalPortfolioValue),
                          _buildPortfolioContent(),
                        ],
                      ),
                    ),
                    
                    // Activity tab with cryptocurrencies
                    SingleChildScrollView(
                      child: Column(
                        children: [
                          _buildProfileHeader(totalPortfolioValue),
                          _buildActivityTab(),
                        ],
                      ),
                    ),
                    
                    // Watchlist tab
                    WatchlistScreen(),
                  ],
                ),
              ),
              
              // Add the gradient navbar at the bottom
              GradientNavbar(
                tabController: _tabController,
                onTabSelected: (index) {
                  print("selected tab: $index");
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Future<void> fetchCryptocurrencies() async {
    try {
      CoinGeckoService service = CoinGeckoService();
      List<Map<String, dynamic>> coins = await service.getAllCoins();
      if (mounted) { // Check if the widget is still mounted
        setState(() {
          cryptocurrencies = coins;
        });
      }
    } catch (e) {
      print('Error fetching cryptocurrencies: $e');
    }
  }

  @override
  void initState() {
    super.initState();
    // Change the length to match the number of tabs (3)
    _tabController = TabController(length: 3, vsync: this);
    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();
    
    // Get current user data
    _loadUserData();
    
    // Load cryptocurrencies and trending data without awaiting
    _loadCryptos(); // Don't use await here
    _loadTrendingCryptos();
    
    // Set up timer for regular price updates (every 30 seconds)
    _priceUpdateTimer = Timer.periodic(Duration(seconds: 30), (timer) {
      if (mounted) {
        _updatePortfolioPrices();
      }
    });
  }

  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
    });
    
    _user = _auth.currentUser;
    
    if (_user != null) {
      // User is logged in
      setState(() {
        _displayName = _user!.displayName ?? 
                      (_user!.email != null ? _user!.email!.split('@')[0] : 'User');
        _isLoading = false;
      });
      
      // Only fetch portfolio data if user is logged in
      await _loadUserPortfolio();
    } else {
      // User is not logged in
      setState(() {
        _displayName = 'Guest';
        _isLoading = false;
        // Keep portfolio empty when not logged in
        portfolioData = [];
      });
    }
  }

  Future<void> _loadCryptos() async { // New method to load cryptocurrencies
    setState(() {
      _isLoadingTrending = true; // Use this variable to manage loading state
    });
    
    try {
      List<CryptoModel> cryptos = await _cryptoService.fetchCryptos(); // Fetch cryptocurrencies from CoinGecko

      // Process the fetched cryptocurrencies as needed
      // For example, you can store them in a state variable
      setState(() {
        _cryptos = cryptos; // Store the fetched cryptocurrencies
      });
    } catch (e) {
      print('Error loading cryptocurrencies: $e');
    } finally {
      setState(() {
        _isLoadingTrending = false; // Update loading state
      });
    }
  }

  // Existing method to load trending cryptos
  Future<void> _loadTrendingCryptos() async {
    setState(() {
      _isLoadingTrending = true;
    });
    
    try {
      // This would come from your crypto service in a real app
      // For now using sample data
      await Future.delayed(Duration(seconds: 1)); // Simulate API delay
      
      _trendingCryptos = [
        {'name': 'Solana', 'symbol': 'SOL', 'price': 122.45, 'change': 12.5, 'isWatched': false},
        {'name': 'Polkadot', 'symbol': 'DOT', 'price': 6.78, 'change': 3.2, 'isWatched': false},
        {'name': 'Chainlink', 'symbol': 'LINK', 'price': 14.32, 'change': 5.7, 'isWatched': false},
        {'name': 'Avalanche', 'symbol': 'AVAX', 'price': 34.21, 'change': -2.3, 'isWatched': false},
        {'name': 'Polygon', 'symbol': 'MATIC', 'price': 0.89, 'change': 7.4, 'isWatched': false},
        {'name': 'Uniswap', 'symbol': 'UNI', 'price': 5.67, 'change': -1.8, 'isWatched': false},
      ];
      
      // If user is logged in, check which cryptos they're watching
      if (_user != null) {
        DocumentSnapshot userDoc = await _firestore
            .collection('users')
            .doc(_user!.uid)
            .get();
        
        if (userDoc.exists) {
          Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
          if (userData.containsKey('watchlist')) {
            List<String> watchlist = List<String>.from(userData['watchlist']);
            
            // Update isWatched status for each crypto
            for (var i = 0; i < _trendingCryptos.length; i++) {
              _trendingCryptos[i]['isWatched'] = 
                  watchlist.contains(_trendingCryptos[i]['symbol']);
            }
          }
        }
      }
    } catch (e) {
      print('Error loading trending cryptos: $e');
    } finally {
      setState(() {
        _isLoadingTrending = false;
      });
    }
  }

  Future<void> _toggleWatchCrypto(Map<String, dynamic> crypto) async {
    if (_user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please sign in to watch cryptocurrencies')),
      );
      return;
    }
    
    try {
      // Reference to user's document
      DocumentReference userRef = _firestore.collection('users').doc(_user!.uid);
      
      // Get current user document
      DocumentSnapshot userDoc = await userRef.get();
      List<String> watchlist = [];
      
      if (userDoc.exists) {
        Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
        if (userData.containsKey('watchlist')) {
          watchlist = List<String>.from(userData['watchlist']);
        }
      }
      
      // Toggle the watched status
      String symbol = crypto['symbol'];
      if (watchlist.contains(symbol)) {
        watchlist.remove(symbol);
      } else {
        watchlist.add(symbol);
      }
      
      // Update Firestore
      await userRef.set({
        'watchlist': watchlist,
      }, SetOptions(merge: true));
      
      // Update local state
      setState(() {
        int index = _trendingCryptos.indexWhere((c) => c['symbol'] == symbol);
        if (index >= 0) {
          _trendingCryptos[index]['isWatched'] = !_trendingCryptos[index]['isWatched'];
        }
      });
      
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(watchlist.contains(symbol)
              ? '${crypto['name']} added to your watchlist'
              : '${crypto['name']} removed from your watchlist'),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating watchlist: $e')),
      );
    }
  }

  Future<void> _addToPortfolio(Map<String, dynamic> crypto) async {
    if (_user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please sign in to manage your portfolio')),
      );
      return;
    }
    
    // Show dialog to enter amount
    TextEditingController amountController = TextEditingController();
    double? enteredAmount;
    
    try {
      enteredAmount = await showDialog<double>(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: Colors.blueGrey.shade800,
          title: Text(
            'Add ${crypto['name']} to Portfolio',
            style: TextStyle(color: Colors.white),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Current Price: \$${crypto['price']}',
                style: TextStyle(color: Colors.white70),
              ),
              SizedBox(height: 16),
              TextField(
                controller: amountController,
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                style: TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Amount',
                  labelStyle: TextStyle(color: Colors.white70),
                  border: OutlineInputBorder(),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white30),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel', style: TextStyle(color: Colors.white70)),
            ),
            ElevatedButton(
              onPressed: () {
                if (amountController.text.isEmpty) return;
                try {
                  double amount = double.parse(amountController.text);
                  if (amount <= 0) throw Exception("Amount must be positive");
                  Navigator.pop(context, amount);
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Please enter a valid positive number')),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
              ),
              child: Text('Add', style: TextStyle(color: Colors.black)),
            ),
          ],
        ),
      );
      
      if (enteredAmount == null) return;
      
      // Use a stateful loading indicator that doesn't block the UI thread
      bool isProcessing = true;
      
      // Show a non-blocking loading indicator
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    strokeWidth: 2,
                  ),
                ),
                SizedBox(width: 12),
                Text('Processing transaction...'),
              ],
            ),
            duration: Duration(seconds: 30), // Long duration, will dismiss manually
          ),
        );
      }
      
      // Use compute or isolate for heavy computation if needed
      // Perform the Firestore operation
      try {
        await _firestore
            .collection('users')
            .doc(_user!.uid)
            .collection('portfolio')
            .add({
              'name': crypto['name'],
              'symbol': crypto['symbol'],
              'amount': enteredAmount,
              'currentPrice': crypto['price'],
              'purchasePrice': crypto['price'],
              'addedAt': DateTime.now(),
              'lastUpdated': DateTime.now(),
              'purchaseHistory': [
                {
                  'amount': enteredAmount,
                  'price': crypto['price'],
                  'date': DateTime.now(),
                }
              ],
            });
        
        // Clear any showing snackbars
        if (mounted) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          
          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${crypto['name']} added to your portfolio'),
              backgroundColor: Colors.green,
            ),
          );
        }
        
        // Refresh portfolio data asynchronously
        if (mounted) {
          _loadUserPortfolio();
        }
      } catch (e) {
        if (mounted) {
          // Clear any showing snackbars
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error adding to portfolio: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
          print('Error adding to portfolio: $e');
        }
      }
    } catch (e) {
      // Handle any dialog errors
      print('Error with dialog: $e');
    }
  }

  Future<void> _loadUserPortfolio() async {
    if (_user == null) return;
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Fetch portfolio data from Firestore
      final portfolioSnapshot = await _firestore
          .collection('users')
          .doc(_user!.uid)
          .collection('portfolio')
          .get();
      
      if (portfolioSnapshot.docs.isNotEmpty) {
        // Convert Firebase data to app-friendly format
        List<Map<String, dynamic>> fetchedPortfolio = [];
        double totalPortfolioValue = 0;
        
        for (var doc in portfolioSnapshot.docs) {
          final item = doc.data();
          double currentPrice = (item['currentPrice'] as num?)?.toDouble() ?? 0.0;
          double purchasePrice = (item['purchasePrice'] as num?)?.toDouble() ?? currentPrice;
          double amount = (item['amount'] as num).toDouble();
          double targetAllocation = (item['targetAllocation'] as num?)?.toDouble() ?? 0.0;
          
          // Calculate performance metrics
          double changePercentage = purchasePrice > 0 
              ? ((currentPrice - purchasePrice) / purchasePrice) * 100 
              : 0.0;
          
          // Total value of this holding
          double totalValue = amount * currentPrice;
          totalPortfolioValue += totalValue;
          
          // Calculate current allocation
          double currentAllocation = totalPortfolioValue > 0 
              ? (totalValue / totalPortfolioValue) * 100 
              : 0.0;
              
          // Get historical performance data
          Map historicalPerformance = 
              (item['historicalPerformance'] as Map<String, dynamic>?) ?? <String, dynamic>{};
              
          // Get transaction history
          List<dynamic> transactions = item['transactions'] ?? [];
          
          fetchedPortfolio.add({
            'id': doc.id,
            'name': item['name'] ?? 'Unknown',
            'symbol': item['symbol'] ?? '???',
            'amount': amount,
            'value': currentPrice,
            'change': double.parse(changePercentage.toStringAsFixed(2)),
            'totalValue': totalValue,
            'purchasePrice': purchasePrice,
            'targetAllocation': targetAllocation,
            'currentAllocation': currentAllocation,
            'historicalPerformance': historicalPerformance,
            'transactions': transactions,
          'lastUpdated': item['lastUpdated'] != null
              ? (item['lastUpdated'] is Timestamp
                  ? (item['lastUpdated'] as Timestamp).toDate()
                  : item['lastUpdated'])
              : DateTime.now(),
        });
      }
      
      // Calculate allocation percentages
      for (var item in fetchedPortfolio) {
        item['currentAllocation'] = ((item['totalValue'] as double) / totalPortfolioValue) * 100;
        item['image'] = item['image'] as String? ?? ''; // Add image URL if available
        // Remove inconsistent assignment of lastUpdated here
      }
        
        // Sort by value (highest first)
        fetchedPortfolio.sort((a, b) => 
          (b['totalValue'] as double).compareTo(a['totalValue'] as double));
        
        setState(() {
          portfolioData = fetchedPortfolio;
          _portfolioDataFetched = true;
          _isLoading = false;
        });
      } else {
        // No portfolio data found
        setState(() {
          portfolioData = [];
          _portfolioDataFetched = true;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading portfolio data: $e');
      setState(() {
        _isLoading = false;
        _portfolioDataFetched = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading portfolio data'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  void dispose() {
    _priceUpdateTimer?.cancel();
    _tabController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _updatePortfolioPrices() async {
    if (_user == null || portfolioData.isEmpty) return;
    
    try {
      // In a real app, this would fetch current prices from your API
      // For now, we'll simulate this with a slight price change
      
      // Call your crypto price service to get current prices
      // CoinGeckoService cryptoService = CoinGeckoService();
      // final symbols = portfolioData.map((coin) => coin['symbol']).toList();
      // final prices = await cryptoService.getPricesBySymbols(symbols);
      
      // For demonstration, simulate price updates
      Random random = Random();
      Map<String, double> prices = {};
      
      for (var coin in portfolioData) {
        String symbol = coin['symbol'];
        double currentPrice = coin['value'];
        // Fetch current prices from CoinGecko service
        double change = (random.nextDouble() * 6 - 3) / 100; // Define change variable
        prices[symbol] = currentPrice * (1 + change);
      }
      
      // Update the UI with new prices
      setState(() {
        for (var i = 0; i < portfolioData.length; i++) {
          String symbol = portfolioData[i]['symbol'];
          double newPrice = prices[symbol] ?? portfolioData[i]['value'];
          double purchasePrice = portfolioData[i]['purchasePrice'];
          
          // Update price
          portfolioData[i]['value'] = newPrice;
          
          // Update change percentage
          double changePercentage = purchasePrice > 0 
              ? ((newPrice - purchasePrice) / purchasePrice) * 100 
              : 0.0;
          portfolioData[i]['change'] = double.parse(changePercentage.toStringAsFixed(2));
          
          // Update total value
          portfolioData[i]['totalValue'] = portfolioData[i]['amount'] * newPrice;
        }
        
        // Re-sort by value
        portfolioData.sort((a, b) => 
          (b['totalValue'] as double).compareTo(a['totalValue'] as double));
      });
      
      // In a real app, you might also update Firestore with current prices
    } catch (e) {
      print('Error updating portfolio prices: $e');
    }
  }

  // Helper widget that shows coin initial when image is not available
  Widget _buildCoinInitial(Map<String, dynamic> coin) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: Colors.teal.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Text(
          coin['symbol'].substring(0, 1).toUpperCase(),
          style: TextStyle(
            color: Colors.teal,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  // New widget to show login prompt for users who aren't logged in
  Widget _buildLoginPrompt() {
    return Container(
      padding: EdgeInsets.all(20),
      margin: EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        color: Colors.blueGrey.shade800.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.teal.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.account_balance_wallet,
            size: 60,
            color: Colors.teal.withOpacity(0.7),
          ),
          SizedBox(height: 16),
          Text(
            'Portfolio Tracking',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 12),
          Text(
            'Sign in to track your crypto investments and monitor their performance in real-time.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 16,
            ),
          ),
          SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => AuthPage()),
              ).then((_) {
                // Reload user data when returning from auth page
                _loadUserData();
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              elevation: 5,
            ),
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
    );
  }

  // New widget to show when user has an empty portfolio
  Widget _buildEmptyPortfolioMessage() {
    return Container(
      padding: EdgeInsets.all(20),
      margin: EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        color: Colors.blueGrey.shade800.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.amber.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.add_chart,
            size: 60,
            color: Colors.amber.withOpacity(0.7),
          ),
          SizedBox(height: 16),
          Text(
            'Portfolio Empty',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 12),
          Text(
            'You haven\'t added any cryptocurrencies to your portfolio yet. Add some from the Activity tab to start tracking.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 16,
            ),
          ),
          SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              _tabController.animateTo(1); // Switch to Activity tab
            },
            icon: Icon(Icons.add_circle_outline),
            label: Text('Add Cryptocurrencies'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amber,
              foregroundColor: Colors.black87,
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              elevation: 5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'My Profile',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          IconButton(
            icon: Icon(Icons.logout, color: Colors.white),
            onPressed: () async {
              // Implement real Firebase logout
              try {
                await _auth.signOut();
                Navigator.of(context).pushReplacementNamed('/login'); // Navigate to login screen
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Successfully logged out')),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error logging out: ${e.toString()}')),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  // Update profile header to hide values when not logged in
  Widget _buildProfileHeader(double totalValue) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              buildProfileImage(_user?.photoURL),
              SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _displayName,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    _user?.email ?? 'Crypto Enthusiast',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: 24),
          // Only show portfolio value card if user is logged in
          if (_user != null)
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  colors: [
                    Color(0xFF1A2980),
                    Color(0xFF26D0CE),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 10,
                    offset: Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total Portfolio Value',
                        style: TextStyle(
                          color: const Color.fromARGB(255, 17, 15, 15),
                          fontSize: 16,
                        ),
                      ),
                      if (_portfolioDataFetched)
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '+12.6% All Time', // In a real app, calculate this from historical data
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                  SizedBox(height: 8),
                  _portfolioDataFetched
                    ? Text(
                        '\$${totalValue.toStringAsFixed(2)}',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    : SizedBox(
                        height: 28,
                        width: 100,
                        child: LinearProgressIndicator(
                          backgroundColor: Colors.white24,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildActivityTab() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 16),
          Text(
            'Trending Cryptocurrencies',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          if (_isLoadingTrending)
            Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.teal),
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: _trendingCryptos.length,
              itemBuilder: (context, index) {
                final crypto = _trendingCryptos[index];
                final isPositive = crypto['change'] >= 0;
                
                return Container(
                  margin: EdgeInsets.only(bottom: 12),
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.blueGrey.shade700.withOpacity(0.3),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.teal.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Text(
                            crypto['symbol'].substring(0, 1),
                            style: TextStyle(
                              color: Colors.teal,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              crypto['name'],
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              crypto['symbol'],
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '\$${crypto['price']}',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            '${isPositive ? "+" : ""}${crypto['change']}%',
                            style: TextStyle(
                              color: isPositive ? Colors.green : Colors.red,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(width: 12),
                      Row(
                        children: [
                          IconButton(
                            icon: Icon(
                              crypto['isWatched'] ? Icons.star : Icons.star_border,
                              color: crypto['isWatched'] ? Colors.amber : Colors.white70,
                            ),
                            onPressed: () => _toggleWatchCrypto(crypto),
                            tooltip: crypto['isWatched'] ? 'Remove from watchlist' : 'Add to watchlist',
                          ),
                          IconButton(
                            icon: Icon(
                              Icons.add_circle_outline,
                              color: Colors.teal,
                            ),
                            onPressed: () => _addToPortfolio(crypto),
                            tooltip: 'Add to portfolio',
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          
          SizedBox(height: 24),
          
          // Price Alerts Section
          Text(
            'Price Alerts',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 16),
          
          Center(
            child: Column(
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.notifications_active_outlined,
                    size: 40,
                    color: Colors.white.withOpacity(0.7),
                  ),
                ),
                SizedBox(height: 16),
                Text(
                  'Get notified on price movements',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Set up alerts for cryptocurrencies in your watchlist',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
                SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: Text('Set Up Alerts'),
                ),
              ],
            ),
          ),
          
          SizedBox(height: 32),
        ],
      ),
    );
  }

  // New method for portfolio content
  Widget _buildPortfolioContent() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Show portfolio chart only if user is logged in
          if (_user != null)
            PortfolioTimelineGraph(
              portfolioData: portfolioData,
              totalPortfolioValue: portfolioData.fold<double>(
                0, (double sum, Map<String, dynamic> item) => sum + ((item['amount'] as num).toDouble() * (item['value'] as num).toDouble())),
              previousTotalValue: _getPreviousPortfolioValue(),
              height: 300, // Set appropriate height
              showTimeRangeSelector: true,
              showTitle: true,
            ),
            
          SizedBox(height: 16),
          
          // Portfolio stats summary
          if (_user != null && portfolioData.isNotEmpty)
            Container(
              margin: EdgeInsets.only(bottom: 16),
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: Colors.blueGrey.shade800.withOpacity(0.3),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatItem(
                    'Assets', 
                    portfolioData.length.toString(),
                    Icons.account_balance_wallet,
                    Colors.teal
                  ),
                  _buildStatItem(
                    'Best Performer', 
                    portfolioData.isNotEmpty 
                      ? '${portfolioData.reduce((a, b) => a['change'] > b['change'] ? a : b)['symbol']}'
                      : '-',
                    Icons.trending_up,
                    Colors.green
                  ),
                  _buildStatItem(
                    'Updates', 
                    'Live',
                    Icons.update,
                    Colors.amber
                  ),
                ],
              ),
            ),
          
          // Section title for portfolio assets
          if (_user != null && portfolioData.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Your Assets',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  
                  // Sort options dropdown
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Sort: Value',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                        Icon(Icons.arrow_drop_down, color: Colors.white70, size: 16),
                      ],
                    ),
                  ),
                ],
              ),
            ),

          // Show different content based on login status
          if (_user == null)
            // User not logged in - show login prompt
            _buildLoginPrompt()
          else if (portfolioData.isEmpty && _portfolioDataFetched)
            // User logged in but has empty portfolio
            _buildEmptyPortfolioMessage()
          else
            // User logged in with portfolio data - show the list
            // Use LimitedBox to ensure proper sizing within SingleChildScrollView
            LimitedBox(
              maxHeight: MediaQuery.of(context).size.height * 0.6, // Limit height to avoid layout issues
              child: ListView.builder(
                shrinkWrap: true, // Important for ListView inside SingleChildScrollView
                physics: BouncingScrollPhysics(), // Use physics that work well with SingleChildScrollView
                itemCount: portfolioData.length,
                itemBuilder: (context, index) {
                  final coin = portfolioData[index];
                  final isPositive = coin['change'] >= 0;
                  final totalValue = coin['amount'] * coin['value'];

                  return Container(
                    margin: EdgeInsets.only(bottom: 12),
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: Colors.blueGrey.shade700.withOpacity(0.3),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 4,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: InkWell(
                      onTap: () {
                        // Show detailed view of this asset
                        _showAssetDetails(coin);
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Row(
                        children: [
                          coin['image'] != null && coin['image'].toString().isNotEmpty
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: CachedNetworkImage(
                                    imageUrl: coin['image'],
                                    width: 40,
                                    height: 40,
                                    placeholder: (context, url) => Container(
                                      width: 40,
                                      height: 40,
                                      color: Colors.white10,
                                      child: Center(
                                        child: SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor: AlwaysStoppedAnimation<Color>(Colors.teal),
                                          ),
                                        ),
                                      ),
                                    ),
                                    errorWidget: (context, url, error) => _buildCoinInitial(coin),
                                  ),
                                )
                              : _buildCoinInitial(coin),
                          SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  coin['name'],
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  '${coin['amount'].toStringAsFixed(coin['amount'] > 100 ? 2 : 4)} ${coin['symbol'].toUpperCase()}',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '\$${totalValue.toStringAsFixed(2)}',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              SizedBox(height: 4),
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: isPositive 
                                      ? Colors.green.withOpacity(0.2) 
                                      : Colors.red.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  '${isPositive ? "+" : ""}${coin['change']}%',
                                  style: TextStyle(
                                    color: isPositive ? Colors.green : Colors.red,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  // Add this new helper method for the portfolio summary stats
  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            size: 20,
            color: color,
          ),
        ),
        SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: Colors.white60,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  // Add this method to show detailed asset information
  void _showAssetDetails(Map<String, dynamic> coin) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: BoxDecoration(
          color: Color(0xFF0D1F32),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with close button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${coin['name']} Details',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: Colors.white70),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              
              SizedBox(height: 20),
              
              // Asset summary card
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.blueGrey.shade800, Colors.blueGrey.shade900],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        coin['image'] != null && coin['image'].toString().isNotEmpty
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.network(
                                  coin['image'],
                                  width: 50,
                                  height: 50,
                                  errorBuilder: (_, __, ___) => _buildCoinInitial(coin),
                                ),
                              )
                            : _buildCoinInitial(coin),
                        SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                coin['name'],
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                coin['symbol'].toUpperCase(),
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: coin['change'] >= 0 
                                ? Colors.green.withOpacity(0.3) 
                                : Colors.red.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '${coin['change'] >= 0 ? "+" : ""}${coin['change']}%',
                            style: TextStyle(
                              color: coin['change'] >= 0 ? Colors.green : Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    
                    Divider(color: Colors.white24, height: 30),
                    
                    // Holdings info
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildAssetInfoItem('Amount', '${coin['amount']}'),
                        _buildAssetInfoItem('Value', '\$${(coin['amount'] * coin['value']).toStringAsFixed(2)}'),
                        _buildAssetInfoItem('Price', '\$${coin['value']}'),
                      ],
                    ),
                  ],
                ),
              ),
              
              SizedBox(height: 20),
              
              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        // Buy more
                        Navigator.pop(context);
                        _addToPortfolio({
                          'name': coin['name'],
                          'symbol': coin['symbol'],
                          'price': coin['value']
                        });
                      },
                      icon: Icon(Icons.add_circle),
                      label: Text('Buy More'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding: EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _sellFromPortfolio(coin);
                      },
                      icon: Icon(Icons.remove_circle),
                      label: Text('Sell'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        padding: EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
              
              SizedBox(height: 20),
              
              // Purchase history section
              Text(
                'Purchase History',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              
              SizedBox(height: 12),
              
              // Placeholder for purchase history
              Expanded(
                child: Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      'Purchase history will be displayed here',
                      style: TextStyle(color: Colors.white70),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper method for asset details modal
  Widget _buildAssetInfoItem(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white60,
            fontSize: 12,
          ),
        ),
        SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ],
    );
  }

  double _getPreviousPortfolioValue() {
    // In a real app, you would get this from historical data
    // For now, we'll estimate it based on the current data
    
    // Estimate previous value based on change percentages
    double previousValue = 0;
    
    for (var coin in portfolioData) {
      double currentValue = coin['amount'] * coin['value'];
      double changePercent = coin['change'] / 100;
      
      // Calculate previous value using the change percentage
      double previousCoinValue = currentValue / (1 + changePercent);
      previousValue += previousCoinValue;
    }
    
    return previousValue;
  }
  
  Future<void> _sellFromPortfolio(Map<String, dynamic> coin) async {
    if (_user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please sign in to manage your portfolio')),
      );
      return;
    }
    
    // Show dialog to enter amount to sell
    TextEditingController amountController = TextEditingController();
    double? enteredAmount;
    
    // Use a try-catch block to safely show and handle the dialog
    try {
      enteredAmount = await showDialog<double>(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: Colors.blueGrey.shade800,
          title: Text(
            'Sell ${coin['name']}',
            style: TextStyle(color: Colors.white),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Current Price: \$${coin['value']}',
                style: TextStyle(color: Colors.white70),
              ),
              Text(
                'Your Balance: ${coin['amount']} ${coin['symbol'].toUpperCase()}',
                style: TextStyle(color: Colors.white70),
              ),
              SizedBox(height: 16),
              TextField(
                controller: amountController,
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                style: TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Amount to Sell',
                  labelStyle: TextStyle(color: Colors.white70),
                  border: OutlineInputBorder(),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white30),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel', style: TextStyle(color: Colors.white70)),
            ),
            ElevatedButton(
              onPressed: () {
                if (amountController.text.isEmpty) return;
                try {
                  double amount = double.parse(amountController.text);
                  if (amount <= 0) throw Exception("Amount must be positive");
                  if (amount > coin['amount']) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('You cannot sell more than you own')),
                    );
                    return;
                  }
                  Navigator.pop(context, amount);
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Please enter a valid positive number')),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
              ),
              child: Text('Sell', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
    } catch (e) {
      // Handle any errors with showing the dialog
      print('Error showing sell dialog: $e');
      return;
    }
    
    if (enteredAmount == null) return;
    
    // Show a non-blocking loading indicator as a snackbar
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.transparent,),
                  strokeWidth: 2,
                ),
              ),
              SizedBox(width: 12),
              Text('Processing transaction...'),
            ],
          ),
          duration: Duration(seconds: 30), // Long duration, will dismiss manually
        ),
      );
    }
    
    try {
      // Get the reference to the portfolio item
      DocumentReference portfolioRef = _firestore
          .collection('users')
          .doc(_user!.uid)
          .collection('portfolio')
          .doc(coin['id']);
          
      // Get current data
      DocumentSnapshot portfolioDoc = await portfolioRef.get();
      if (!portfolioDoc.exists) {
        throw Exception('Portfolio item not found');
      }
      
      Map<String, dynamic> portfolioData = portfolioDoc.data() as Map<String, dynamic>;
      double currentAmount = (portfolioData['amount'] as num).toDouble();
      
      if (enteredAmount >= currentAmount) {
        // Selling all - remove the document
        await portfolioRef.delete();
      } else {
        // Selling part - update the amount
        await portfolioRef.update({
          'amount': currentAmount - enteredAmount,
          'lastUpdated': DateTime.now(),
        });
      }
      
      // Dismiss loading indicator and show success message
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Successfully sold $enteredAmount ${coin['symbol']}'),
            backgroundColor: Colors.green,
          ),
        );
      }
      
      // Force refresh of portfolio data asynchronously
      if (mounted) {
        _loadUserPortfolio();
      }
      
    } catch (e) {
      // Show error message if the widget is still mounted
      if (mounted) {
        // Clear any showing snackbars
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error selling from portfolio: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
        print('Error selling from portfolio: $e');
      }
    }
  }
}

Widget buildProfileImage(String? imageUrl) {
  if (imageUrl == null || imageUrl.isEmpty) {
    return _buildFallbackAvatar();
  }
  
  return ClipOval(
    child: CachedNetworkImage(
      imageUrl: imageUrl,
      width: 60,
      height: 60,
      fit: BoxFit.cover,
      placeholder: (context, url) => CircularProgressIndicator(),
      errorWidget: (context, url, error) {
        print('Error loading profile image: $error');
        return _buildFallbackAvatar();
      },
    ),
  );
}

Widget _buildFallbackAvatar() {
  final user = FirebaseAuth.instance.currentUser;
  final displayName = user?.displayName ?? user?.email?.split('@')[0] ?? 'User';
  
  return CircleAvatar(
    radius: 30,
    backgroundColor: Colors.deepPurple.shade300,
    child: Text(
      displayName.isNotEmpty ? displayName[0].toUpperCase() : 'U',
      style: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
    ),
  );
}
