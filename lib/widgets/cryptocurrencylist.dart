import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:crypto_flutter_app/services/coin_gecko_service.dart';
import 'package:crypto_flutter_app/screen/crypto_detail_screen.dart';
import 'package:crypto_flutter_app/models/crypto_model.dart';
import 'package:crypto_flutter_app/widgets/gradient_background.dart'; // Import GradientBackground
import 'dart:async';
// Add import for ImageFilter

class CryptoCurrencyList extends StatefulWidget {
  const CryptoCurrencyList({super.key});

  @override
  _CryptoCurrencyListState createState() => _CryptoCurrencyListState();
}

class _CryptoCurrencyListState extends State<CryptoCurrencyList>
    with TickerProviderStateMixin {
  late AnimationController _backgroundAnimationController;
  late Animation<Color?> _backgroundColorAnimation;
  List<Map<String, dynamic>> cryptocurrencies = [];
  Timer? timer; // Declare a timer variable
  
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = "";
  final bool _isWeb = kIsWeb; // Check if running on web platform

  @override
  void initState() {
    super.initState();
    
    // Background animation controller
    _backgroundAnimationController = AnimationController(
      vsync: this,
      duration: Duration(seconds: 5),
    )..repeat(reverse: true);

    // Gradient color animation
    _backgroundColorAnimation = ColorTween(
      begin: Color.fromARGB(255, 252, 235, 3), // Neon green
      end: Color.fromARGB(255, 72, 0, 255), // Neon magenta
    ).animate(_backgroundAnimationController);

    // Fetch real data immediately when the widget initializes
    fetchCryptocurrencies();

    // Timer for real-time updates - use a longer interval to prevent API rate limits
    timer = Timer.periodic(Duration(seconds: 60), (timer) {
      fetchCryptocurrencies();
    });
  }

  Future<void> fetchCryptocurrencies() async {
    if (!mounted) return;
    
    try {
      setState(() {
        _isLoading = true;
        _hasError = false;
      });
      
      CoinGeckoService service = CoinGeckoService();
      List<Map<String, dynamic>> coins = await service.getAllCoins();
      
      if (mounted) { // Check if the widget is still mounted
        setState(() {
          cryptocurrencies = coins;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error fetching cryptocurrencies: $e');
      if (mounted) {
        setState(() {
          _hasError = true;
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    timer?.cancel(); // Cancel the timer
    _backgroundAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Get screen dimensions
    final screenWidth = MediaQuery.of(context).size.width;
    
    // Determine if the app is running on a mobile device
    final isMobile = !kIsWeb;
    
    // For mobile devices, limit the number of visible cryptos to 2 based on screen size
    final displayCount = isMobile ? 2 : cryptocurrencies.length;

    // Use GradientBackground instead of the custom animated background for consistency
    return GradientBackground(
      child: Column(
        children: [
          SizedBox(height: 20),
          
          // Loading indicator or error message
          if (_isLoading && cryptocurrencies.isEmpty)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: Colors.white),
                    SizedBox(height: 20),
                    Text(
                      'Loading cryptocurrencies...',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ],
                ),
              ),
            )
          else if (_hasError)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, color: Colors.red, size: 40),
                    SizedBox(height: 20),
                    Text(
                      'Failed to load data',
                      style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 10),
                    Text(
                      'Please check your internet connection',
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                    SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: fetchCryptocurrencies,
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.purple.shade800,
                        backgroundColor: Colors.white,
                      ),
                      child: Text('Retry'),
                    ),
                  ],
                ),
              ),
            )
          else
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (isMobile) 
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                      child: Text(
                        'Top Cryptocurrencies',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          shadows: [
                            Shadow(
                              blurRadius: 5,
                              color: Colors.black.withOpacity(0.3),
                              offset: Offset(1, 1),
                            ),
                          ],
                        ),
                      ),
                    ),
                  Expanded(
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: cryptocurrencies.length,
                      itemBuilder: (context, index) {
                        final crypto = cryptocurrencies[index];
                        return AnimatedHoverCard(
                          crypto,
                          isMobile: isMobile,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => CryptoDetailScreen(
                                  crypto: CryptoModel(
                                    id: crypto['id'],
                                    name: crypto['name'],
                                    symbol: crypto['symbol'],
                                    image: crypto['image'],
                                    currentPrice: crypto['current_price']?.toDouble() ?? 0.0,
                                    priceChangePercentage24h: crypto['price_change_percentage_24h']?.toDouble() ?? 0.0,
                                    marketCapRank: crypto['market_cap_rank'] ?? 0,
                                    circulatingSupply: crypto['circulating_supply']?.toDouble() ?? 0.0,
                                    ath: crypto['ath']?.toDouble() ?? 0.0,
                                    marketCap: crypto['market_cap']?.toDouble(),
                                    totalVolume: crypto['total_volume']?.toDouble(),
                                    high24h: crypto['high_24h']?.toDouble(),
                                    low24h: crypto['low_24h']?.toDouble(),
                                  ),
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                  // Show "Swipe for more" hint on mobile
                  if (isMobile)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 10.0),
                        child: Text(
                          'Swipe for more →',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class AnimatedHoverCard extends StatefulWidget {
  final Map<String, dynamic> crypto;
  final VoidCallback onTap;
  final bool isMobile; // Add flag to determine if mobile
  
  const AnimatedHoverCard(
    this.crypto, {
    super.key, 
    required this.onTap, 
    this.isMobile = false,
  });

  @override
  _AnimatedHoverCardState createState() => _AnimatedHoverCardState();
}

class _AnimatedHoverCardState extends State<AnimatedHoverCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _hoverController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _hoverController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 300),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
        CurvedAnimation(parent: _hoverController, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _hoverController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Get screen width
    final screenWidth = MediaQuery.of(context).size.width;
    
    // Calculate card width and height to make more square-shaped
    double cardWidth, cardHeight;
    
    if (widget.isMobile) {
      // For mobile: wider cards that are more square
      cardWidth = screenWidth * 0.45; // 45% of screen width
      cardHeight = cardWidth * 1.1; // Almost square (slightly taller)
    } else {
      // For web: keep the original style
      cardWidth = screenWidth * 0.25;
      cardHeight = cardWidth * 1.2;
    }
        
    // Adjust font size for mobile
    final double nameFontSize = widget.isMobile ? 16 : 18;
    final double symbolFontSize = widget.isMobile ? 14 : 16;
    final double priceFontSize = widget.isMobile ? 16 : 18;
    
    return GestureDetector(
      onTap: () {
        widget.onTap();
        _hoverController.reverse();
      },
      onTapDown: (_) => _hoverController.forward(),
      onTapUp: (_) => _hoverController.reverse(),
      onTapCancel: () => _hoverController.reverse(),
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          width: cardWidth,
          height: cardHeight,
          margin: EdgeInsets.symmetric(
            horizontal: widget.isMobile ? 8 : 10, 
            vertical: widget.isMobile ? 15 : 20
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              colors: [Colors.blue.withOpacity(0.5), Colors.purple.withOpacity(0.5)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 10,
                offset: Offset(5, 5),
              ),
            ],
          ),
          child: Padding(
            padding: EdgeInsets.all(widget.isMobile ? 12 : 15),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Hero(
                  tag: 'crypto-${widget.crypto['id']}',
                  child: Image.network(
                    widget.crypto['image'], 
                    height: widget.isMobile ? 60 : 70,
                    errorBuilder: (context, error, stackTrace) => 
                      Icon(Icons.currency_bitcoin, size: widget.isMobile ? 60 : 70, color: Colors.white),
                  ),
                ),
                SizedBox(height: widget.isMobile ? 10 : 15),
                Text(
                  widget.crypto['name'], 
                  style: TextStyle(
                    fontSize: nameFontSize, 
                    fontWeight: FontWeight.bold, 
                    color: Colors.white
                  ),
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 5),
                Text(
                  widget.crypto['symbol'].toUpperCase(),
                  style: TextStyle(
                    fontSize: symbolFontSize, 
                    fontWeight: FontWeight.w400, 
                    color: Colors.white70
                  ),
                ),
                SizedBox(height: widget.isMobile ? 10 : 15),
                Text(
                  "\$${widget.crypto['current_price'].toStringAsFixed(2)}",
                  style: TextStyle(
                    fontSize: priceFontSize, 
                    fontWeight: FontWeight.bold, 
                    color: Colors.greenAccent
                  ),
                ),
                SizedBox(height: 5),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: widget.crypto['price_change_percentage_24h'] >= 0
                        ? Colors.green.withOpacity(0.2)
                        : Colors.red.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    "${widget.crypto['price_change_percentage_24h'] >= 0 ? '+' : ''}${widget.crypto['price_change_percentage_24h'].toStringAsFixed(2)}%",
                    style: TextStyle(
                      fontSize: symbolFontSize, 
                      fontWeight: FontWeight.bold, 
                      color: widget.crypto['price_change_percentage_24h'] >= 0 
                          ? Colors.greenAccent 
                          : Colors.redAccent
                    ),
                  ),
                ),
                
                // Add market cap rank badge
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.amber.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          "Rank #${widget.crypto['market_cap_rank']}",
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.amber,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
