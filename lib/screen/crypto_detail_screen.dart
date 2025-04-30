import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/crypto_model.dart';

class CryptoDetailScreen extends StatefulWidget {
  final CryptoModel crypto;

  const CryptoDetailScreen({super.key, required this.crypto});

  @override
  _CryptoDetailScreenState createState() => _CryptoDetailScreenState();
}

class _CryptoDetailScreenState extends State<CryptoDetailScreen> 
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Color?> _gradientAnimation;
  final bool _isFavorite = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(seconds: 3),
    )..repeat(reverse: true);
    
    _gradientAnimation = ColorTween(
      begin: Colors.blue.shade900,
      end: Colors.purple.shade900,
    ).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  List<FlSpot> _createSampleData() {
    return [
      FlSpot(0, widget.crypto.currentPrice * 0.9),
      FlSpot(1, widget.crypto.currentPrice * 0.95),
      FlSpot(2, widget.crypto.currentPrice * 1.1),
      FlSpot(3, widget.crypto.currentPrice * 0.85),
      FlSpot(4, widget.crypto.currentPrice * 1.2),
      FlSpot(5, widget.crypto.currentPrice * 1.15),
      FlSpot(6, widget.crypto.currentPrice),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = !kIsWeb;
    
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .doc(FirebaseAuth.instance.currentUser?.uid)
                .collection('watchlist')
                .doc(widget.crypto.id)
                .snapshots(),
            builder: (context, snapshot) {
              final isInWatchlist = snapshot.data?.exists ?? false;
              return IconButton(
                icon: Icon(
                  isInWatchlist ? Icons.star : Icons.star_border,
                  color: isInWatchlist ? Colors.amber : Colors.white,
                  size: 30,
                ),
                onPressed: () async {
                  try {
                    if (FirebaseAuth.instance.currentUser == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Please sign in to use watchlist'))
                      );
                      return;
                    }

                    final docRef = FirebaseFirestore.instance
                        .collection('users')
                        .doc(FirebaseAuth.instance.currentUser!.uid)
                        .collection('watchlist')
                        .doc(widget.crypto.id);

                    if (isInWatchlist) {
                      await docRef.delete();
                    } else {
                      await docRef.set({
                        'id': widget.crypto.id,
                        'name': widget.crypto.name,
                        'symbol': widget.crypto.symbol,
                        'price': widget.crypto.currentPrice,
                        'change': widget.crypto.priceChangePercentage24h,
                        'image': widget.crypto.image,
                        'addedAt': FieldValue.serverTimestamp(),
                      });
                    }
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: ${e.toString()}'))
                    );
                  }
                },
              );
            },
          ),
        ],
      ),
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  _gradientAnimation.value!,
                  Colors.black,
                ],
              ),
            ),
            child: SafeArea(
              child: SingleChildScrollView(
                child: Padding(
                  padding: EdgeInsets.only(
                    top: isMobile ? 10 : 20,
                    bottom: 20,
                  ),
                  child: Column(
                    children: [
                      Hero(
                        tag: 'crypto-${widget.crypto.id}',
                        child: CircleAvatar(
                          radius: 50,
                          backgroundColor: Colors.white.withOpacity(0.2),
                          child: Image.network(
                            widget.crypto.image,
                            errorBuilder: (context, error, stackTrace) => 
                              Icon(Icons.currency_bitcoin, size: 60, color: Colors.white),
                          ),
                        ),
                      ),
                      SizedBox(height: 20),
                      Text(
                        widget.crypto.name,
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        widget.crypto.symbol.toUpperCase(),
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.white70,
                        ),
                      ),
                      SizedBox(height: 20),
                      Container(
                        height: 200,
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: LineChart(
                          LineChartData(
                            gridData: FlGridData(show: false),
                            titlesData: FlTitlesData(show: false),
                            borderData: FlBorderData(show: false),
                            minX: 0,
                            maxX: 6,
                            minY: widget.crypto.currentPrice * 0.8,
                            maxY: widget.crypto.currentPrice * 1.3,
                            lineBarsData: [
                              LineChartBarData(
                                spots: _createSampleData(),
                                isCurved: true,
                                color: widget.crypto.priceChangePercentage24h >= 0
                                    ? Colors.green
                                    : Colors.red,
                                barWidth: 3,
                                isStrokeCapRound: true,
                                dotData: FlDotData(show: true),
                                belowBarData: BarAreaData(show: false),
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: 20),
                      _buildPriceInfo(isMobile),
                      SizedBox(height: 30),
                      _buildStatCardsRow(isMobile, 
                        'Market Cap', 
                        '\$${_formatLargeNumber(widget.crypto.marketCap)}', 
                        Icons.assessment,
                        'Volume (24h)', 
                        '\$${_formatLargeNumber(widget.crypto.totalVolume)}', 
                        Icons.trending_up,
                      ),
                      SizedBox(height: 10),
                      _buildStatCardsRow(isMobile,
                        'All Time High', 
                        '\$${widget.crypto.ath.toStringAsFixed(2)}', 
                        Icons.leaderboard,
                        'Circulating Supply', 
                        _formatLargeNumber(widget.crypto.circulatingSupply), 
                        Icons.monetization_on,
                      ),
                      SizedBox(height: 30),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 20),
                        child: ElevatedButton.icon(
                          icon: Icon(Icons.add_chart),
                          label: Text('Add to Portfolio'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            minimumSize: Size(double.infinity, 50),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: () => _showAddPortfolioDialog(),
                        ),
                      ),
                      SizedBox(height: 30),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  String _formatLargeNumber(double? number) {
    if (number == null) return 'N/A';
    
    if (number >= 1000000000) {
      return '${(number / 1000000000).toStringAsFixed(2)}B';
    } else if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(2)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(2)}K';
    } else {
      return number.toStringAsFixed(2);
    }
  }
  
  Future<void> _showAddPortfolioDialog() async {
    try {
      if (FirebaseAuth.instance.currentUser == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Please sign in to add to portfolio'))
        );
        return;
      }

      final docRef = FirebaseFirestore.instance
          .collection('users')
          .doc(FirebaseAuth.instance.currentUser!.uid)
          .collection('portfolio')
          .doc(widget.crypto.id);

      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Add to Portfolio'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Enter amount to add:'),
              TextFormField(
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: 'Amount in ${widget.crypto.symbol.toUpperCase()}'
                ),
                onChanged: (value) {
                  // Store the entered amount
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                await docRef.set({
                  'id': widget.crypto.id,
                  'name': widget.crypto.name,
                  'symbol': widget.crypto.symbol,
                  'currentPrice': widget.crypto.currentPrice,
                  'amount': 1.0,
                  'image': widget.crypto.image,
                  'addedAt': FieldValue.serverTimestamp(),
                }, SetOptions(merge: true));
                
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Added to portfolio'),
                    backgroundColor: Colors.green,
                  )
                );
              },
              child: Text('Add'),
            ),
          ],
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        )
      );
    }
  }

  Widget _buildPriceInfo(bool isMobile) {
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Current Price',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.white70,
                ),
              ),
              Text(
                '\$${widget.crypto.currentPrice.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 10),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '24h Change',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.white70,
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: widget.crypto.priceChangePercentage24h >= 0
                      ? Colors.green.withOpacity(0.2)
                      : Colors.red.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${widget.crypto.priceChangePercentage24h >= 0 ? '+' : ''}${widget.crypto.priceChangePercentage24h.toStringAsFixed(2)}%',
                  style: TextStyle(
                    fontSize: 18,
                    color: widget.crypto.priceChangePercentage24h >= 0
                        ? Colors.green
                        : Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatCardsRow(
    bool isMobile, 
    String title1, 
    String value1, 
    IconData icon1,
    String title2, 
    String value2, 
    IconData icon2,
  ) {
    if (isMobile) {
      return Padding(
        padding: EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          children: [
            _buildStatCard(title1, value1, icon1),
            SizedBox(height: 10),
            _buildStatCard(title2, value2, icon2),
          ],
        ),
      );
    } else {
      return Padding(
        padding: EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          children: [
            Expanded(child: _buildStatCard(title1, value1, icon1)),
            SizedBox(width: 10),
            Expanded(child: _buildStatCard(title2, value2, icon2)),
          ],
        ),
      );
    }
  }

  Widget _buildStatCard(String title, String value, IconData icon) {
    return Card(
      color: Colors.white.withOpacity(0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Colors.white70, size: 20),
                SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}