import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:fl_chart/fl_chart.dart';
import '../models/crypto_model.dart';

class CryptoService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _coinGeckoApiUrl = 'https://api.coingecko.com/api/v3';

  Future<Map<String, double>> getPricesBySymbols(List<String> symbols) async {
    try {
      // Convert symbols to lowercase as CoinGecko uses lowercase
      final symbolParams = symbols.map((s) => s.toLowerCase()).join(',');
      
      final response = await http.get(
        Uri.parse('$_coinGeckoApiUrl/simple/price?ids=$symbolParams&vs_currencies=usd')
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final Map<String, double> prices = {};
        
        data.forEach((symbol, priceData) {
          if (priceData is Map && priceData['usd'] != null) {
            prices[symbol] = priceData['usd'].toDouble();
          }
        });
        
        return prices;
      } else {
        throw Exception('Failed to load prices: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching prices: $e');
      throw Exception('Failed to fetch prices: $e');
    }
  }

  Future<void> addToWatchlist(CryptoModel crypto) async {
    await _firestore.collection('watchlist').doc(crypto.id).set({
      'name': crypto.name,
      'symbol': crypto.symbol,
      'currentPrice': crypto.currentPrice,
      'image': crypto.image,
      'marketCapRank': crypto.marketCapRank,
      'circulatingSupply': crypto.circulatingSupply,
      'ath': crypto.ath,
      'priceChangePercentage24h': crypto.priceChangePercentage24h,
      'historicalPerformance': {
        'daily': [],
        'weekly': [],
        'monthly': []
      },
      'targetAllocation': 0.0,
      'transactions': []
    }, SetOptions(merge: true));
  }

  Future<void> updatePortfolioPerformance(String userId, String cryptoId, 
      Map<String, dynamic> performanceData) async {
    await _firestore.collection('users').doc(userId)
      .collection('portfolio').doc(cryptoId)
      .update({
        'historicalPerformance': FieldValue.arrayUnion([performanceData]),
        'lastUpdated': FieldValue.serverTimestamp()
      });
  }

  Future<void> addPortfolioTransaction(String userId, String cryptoId,
      Map<String, dynamic> transactionData) async {
    await _firestore.collection('users').doc(userId)
      .collection('portfolio').doc(cryptoId)
      .update({
        'transactions': FieldValue.arrayUnion([transactionData]),
        'lastUpdated': FieldValue.serverTimestamp()
      });
  }

  // Method to fetch user's watchlist
  Future<List<CryptoModel>> fetchWatchlist() async {
    QuerySnapshot snapshot = await _firestore.collection('watchlist').get();
    return snapshot.docs.map((doc) {
      return CryptoModel(
        id: doc.id,
        name: doc['name'],
        symbol: doc['symbol'],
        currentPrice: doc['currentPrice'],
        image: doc['image'],
        marketCapRank: doc['marketCapRank'], // Map other necessary fields
        circulatingSupply: doc['circulatingSupply'],
        ath: doc['ath'],
        priceChangePercentage24h: doc['priceChangePercentage24h'],
      );
    }).toList();
  }

  static const String apiBaseUrl = 'https://api.coingecko.com/api/v3';

  // Fetch cryptocurrency list
  Future<List<CryptoModel>> fetchCryptos() async {
    try {
      final response = await http.get(Uri.parse(
        '$apiBaseUrl/coins/markets?vs_currency=usd&order=market_cap_desc&per_page=20&page=1'
      ));

      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);
        return data.map((item) => CryptoModel.fromJson(item)).toList();
      } else {
        throw Exception('Failed to load cryptocurrencies');
      }
    } catch (e) {
      // If the API fails, return mock data for demonstration
      return _getMockCryptocurrencies();
    }
  }

  // Fetch historical price data for a cryptocurrency
  Future<Map<String, List<FlSpot>>> fetchHistoricalData(String coinId, String timeframe) async {
    // In a real app, you would call the CoinGecko API with the appropriate parameters
    // For this example, we'll return mock data
    return _getMockHistoricalData(coinId, timeframe);
  }

  // Mock data for demonstration
  List<CryptoModel> _getMockCryptocurrencies() {
    return [
      CryptoModel(
        id: 'bitcoin',
        symbol: 'btc',
        name: 'Bitcoin',
        image: 'https://assets.coingecko.com/coins/images/1/large/bitcoin.png',
        currentPrice: 45000.0,
        marketCap: 850000000000.0,
        marketCapRank: 1,
        totalVolume: 28000000000.0,
        priceChangePercentage24h: 2.5,
        circulatingSupply: 19000000.0,
        ath: 69000.0,
      ),
      CryptoModel(
        id: 'ethereum',
        symbol: 'eth',
        name: 'Ethereum',
        image: 'https://assets.coingecko.com/coins/images/279/large/ethereum.png',
        currentPrice: 3000.0,
        marketCap: 350000000000.0,
        marketCapRank: 2,
        totalVolume: 18000000000.0,
        priceChangePercentage24h: 1.8,
        circulatingSupply: 120000000.0,
        ath: 4800.0,
      ),
      // Add more mock cryptocurrencies as needed
    ];
  }
  
  // Generate mock historical data based on timeframe
  Map<String, List<FlSpot>> _getMockHistoricalData(String coinId, String timeframe) {
    final Map<String, List<FlSpot>> result = {};
    
    // Number of data points for each timeframe
    final int dataPoints = _getDataPointsForTimeframe(timeframe);
    
    // Generate random data with a somewhat realistic trend
    List<FlSpot> spots = [];
    double basePrice = coinId == 'bitcoin' ? 42000 : 2800;
    double volatility = coinId == 'bitcoin' ? 2000 : 150;
    
    for (int i = 0; i < dataPoints; i++) {
      // Create a slightly random walk with some trend
      final double change = (DateTime.now().millisecondsSinceEpoch % 100) / 100 - 0.5;
      basePrice += change * volatility;
      
      // Ensure price doesn't go below a reasonable value
      if (basePrice < volatility) basePrice = volatility;
      
      spots.add(FlSpot(i.toDouble(), basePrice));
    }
    
    result[timeframe] = spots;
    return result;
  }

  // Determine number of data points based on timeframe
  int _getDataPointsForTimeframe(String timeframe) {
    switch (timeframe) {
      case '1d':
        return 24;  // 24 hours
      case '7d':
        return 7;   // 7 days
      case '1m':
        return 30;  // 30 days
      case '6m':
        return 26;  // 26 weeks
      case '1y':
        return 52;  // 52 weeks
      case 'all':
        return 40;  // 40 units (could be months/years)
      default:
        return 24;
    }
  }
}
