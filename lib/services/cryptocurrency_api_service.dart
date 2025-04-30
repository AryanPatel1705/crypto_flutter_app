import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;

class CryptoCurrency {
  final String id;
  final String name;
  final String symbol;
  final double currentPrice;
  final double priceChangePercentage24h;
  final double marketCap;
  final double volume24h;
  final String imageUrl;
  final List<List<dynamic>>? sparklineData;

  CryptoCurrency({
    required this.id,
    required this.name,
    required this.symbol,
    required this.currentPrice,
    required this.priceChangePercentage24h,
    required this.marketCap,
    required this.volume24h,
    required this.imageUrl,
    this.sparklineData,
  });

  factory CryptoCurrency.fromJson(Map<String, dynamic> json) {
    return CryptoCurrency(
      id: json['id'],
      name: json['name'],
      symbol: json['symbol'],
      currentPrice: json['current_price'].toDouble(),
      priceChangePercentage24h: json['price_change_percentage_24h']?.toDouble() ?? 0.0,
      marketCap: json['market_cap']?.toDouble() ?? 0.0,
      volume24h: json['total_volume']?.toDouble() ?? 0.0,
      imageUrl: json['image'],
      sparklineData: json['sparkline_in_7d']?['price'] != null 
          ? List<List<dynamic>>.from(
              json['sparkline_in_7d']['price'].asMap().entries
                .map((entry) => [entry.key, entry.value])
            )
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'symbol': symbol,
      'current_price': currentPrice,
      'price_change_percentage_24h': priceChangePercentage24h,
      'market_cap': marketCap,
      'total_volume': volume24h,
      'image': imageUrl,
      'sparkline_in_7d': sparklineData != null 
          ? {'price': sparklineData!.map((point) => point[1]).toList()} 
          : null,
    };
  }

  @override
  String toString() {
    return 'CryptoCurrency(id: $id, name: $name, symbol: $symbol, currentPrice: $currentPrice)';
  }
}

class HistoricalDataPoint {
  final DateTime timestamp;
  final double price;

  HistoricalDataPoint({required this.timestamp, required this.price});

  factory HistoricalDataPoint.fromJson(List<dynamic> json) {
    return HistoricalDataPoint(
      timestamp: DateTime.fromMillisecondsSinceEpoch(json[0].toInt()),
      price: json[1].toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'timestamp': timestamp.millisecondsSinceEpoch,
      'price': price,
    };
  }
}

enum TimeInterval { day, week, month, threeMonth, year, all }

class CryptoPortfolio {
  final String userId;
  final List<PortfolioItem> holdings;
  final double totalValue;

  CryptoPortfolio({
    required this.userId,
    required this.holdings,
    required this.totalValue,
  });

  factory CryptoPortfolio.fromJson(Map<String, dynamic> json) {
    return CryptoPortfolio(
      userId: json['user_id'],
      holdings: (json['holdings'] as List)
          .map((item) => PortfolioItem.fromJson(item))
          .toList(),
      totalValue: json['total_value'].toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'holdings': holdings.map((holding) => holding.toJson()).toList(),
      'total_value': totalValue,
    };
  }
}

class PortfolioItem {
  final String coinId;
  final String name;
  final String symbol;
  final double amount;
  final double valueUsd;
  final double averageBuyPrice;
  final double profitLoss;
  final double profitLossPercentage;

  PortfolioItem({
    required this.coinId,
    required this.name,
    required this.symbol,
    required this.amount,
    required this.valueUsd,
    required this.averageBuyPrice,
    required this.profitLoss,
    required this.profitLossPercentage,
  });

  factory PortfolioItem.fromJson(Map<String, dynamic> json) {
    return PortfolioItem(
      coinId: json['coin_id'],
      name: json['name'],
      symbol: json['symbol'],
      amount: json['amount'].toDouble(),
      valueUsd: json['value_usd'].toDouble(),
      averageBuyPrice: json['average_buy_price'].toDouble(),
      profitLoss: json['profit_loss'].toDouble(),
      profitLossPercentage: json['profit_loss_percentage'].toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'coin_id': coinId,
      'name': name,
      'symbol': symbol,
      'amount': amount,
      'value_usd': valueUsd,
      'average_buy_price': averageBuyPrice,
      'profit_loss': profitLoss,
      'profit_loss_percentage': profitLossPercentage,
    };
  }
}

class CryptoApiService {
  static const String baseUrl = 'https://api.coingecko.com/api/v3';
  static const String mockBaseUrl = 'https://your-backend.com/api'; // Replace with your backend
  final http.Client client;
  final bool useMockData;
  final Random _random = Random();
  
  // In-memory cache
  final Map<String, dynamic> _cache = {};
  final Map<String, DateTime> _cacheExpiry = {};
  final Duration _cacheDuration = Duration(minutes: 5);

  CryptoApiService({
    http.Client? client, 
    this.useMockData = false
  }) : client = client ?? http.Client();

  // Get trending cryptocurrencies
  Future<List<CryptoCurrency>> getTrendingCoins() async {
    if (useMockData) {
      return _getMockTrendingCoins();
    }

    const cacheKey = 'trending_coins';
    if (_isCacheValid(cacheKey)) {
      return (_cache[cacheKey] as List)
          .map((json) => CryptoCurrency.fromJson(json))
          .toList();
    }

    try {
      final response = await client.get(
        Uri.parse('$baseUrl/coins/markets?vs_currency=usd&order=market_cap_desc&per_page=10&page=1&sparkline=true'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        final List<CryptoCurrency> coins = data
            .map((json) => CryptoCurrency.fromJson(json))
            .toList();
        
        _updateCache(cacheKey, data);
        return coins;
      } else {
        throw Exception('Failed to load trending coins: ${response.statusCode}');
      }
    } catch (e) {
      // Fallback to mock data if API fails
      return _getMockTrendingCoins();
    }
  }

  // Get detailed information about a specific cryptocurrency
  Future<CryptoCurrency> getCoinDetails(String coinId) async {
    if (useMockData) {
      return _getMockCoinDetails(coinId);
    }

    final cacheKey = 'coin_details_$coinId';
    if (_isCacheValid(cacheKey)) {
      return CryptoCurrency.fromJson(_cache[cacheKey]);
    }

    try {
      final response = await client.get(
        Uri.parse('$baseUrl/coins/$coinId?localization=false&tickers=false&market_data=true&sparkline=true'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        // Transform CoinGecko API response to our CryptoCurrency model
        final marketData = data['market_data'];
        final transformedData = {
          'id': data['id'],
          'name': data['name'],
          'symbol': data['symbol'],
          'current_price': marketData['current_price']['usd'],
          'price_change_percentage_24h': marketData['price_change_percentage_24h'],
          'market_cap': marketData['market_cap']['usd'],
          'total_volume': marketData['total_volume']['usd'],
          'image': data['image']['large'],
          'sparkline_in_7d': marketData['sparkline_7d']
        };
        
        final coin = CryptoCurrency.fromJson(transformedData);
        _updateCache(cacheKey, transformedData);
        return coin;
      } else {
        throw Exception('Failed to load coin details: ${response.statusCode}');
      }
    } catch (e) {
      // Fallback to mock data if API fails
      return _getMockCoinDetails(coinId);
    }
  }

  // Get historical price data for a cryptocurrency
  Future<List<HistoricalDataPoint>> getHistoricalData(
    String coinId,
    TimeInterval interval,
  ) async {
    if (useMockData) {
      return _getMockHistoricalData(coinId, interval);
    }

    final cacheKey = 'historical_${coinId}_${interval.toString()}';
    if (_isCacheValid(cacheKey)) {
      return (_cache[cacheKey] as List)
          .map((json) => HistoricalDataPoint.fromJson(json))
          .toList();
    }

    String days;
    switch (interval) {
      case TimeInterval.day:
        days = '1';
        break;
      case TimeInterval.week:
        days = '7';
        break;
      case TimeInterval.month:
        days = '30';
        break;
      case TimeInterval.threeMonth:
        days = '90';
        break;
      case TimeInterval.year:
        days = '365';
        break;
      case TimeInterval.all:
        days = 'max';
        break;
    }

    try {
      final response = await client.get(
        Uri.parse('$baseUrl/coins/$coinId/market_chart?vs_currency=usd&days=$days'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> prices = data['prices'];
        final List<HistoricalDataPoint> historicalData = prices
            .map((price) => HistoricalDataPoint.fromJson(price))
            .toList();
        
        _updateCache(cacheKey, prices);
        return historicalData;
      } else {
        throw Exception('Failed to load historical data: ${response.statusCode}');
      }
    } catch (e) {
      // Fallback to mock data if API fails
      return _getMockHistoricalData(coinId, interval);
    }
  }

  // Get user's cryptocurrency portfolio
  Future<CryptoPortfolio> getUserPortfolio(String userId) async {
    if (useMockData) {
      return _getMockPortfolio(userId);
    }

    final cacheKey = 'portfolio_$userId';
    if (_isCacheValid(cacheKey)) {
      return CryptoPortfolio.fromJson(_cache[cacheKey]);
    }

    try {
      final response = await client.get(
        Uri.parse('$mockBaseUrl/portfolio/$userId'),
        headers: {'Authorization': 'Bearer your-auth-token'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final portfolio = CryptoPortfolio.fromJson(data);
        
        _updateCache(cacheKey, data);
        return portfolio;
      } else {
        throw Exception('Failed to load portfolio: ${response.statusCode}');
      }
    } catch (e) {
      // Fallback to mock data if API fails
      return _getMockPortfolio(userId);
    }
  }

  // Get cryptocurrency market statistics
  Future<Map<String, dynamic>> getMarketStats() async {
    if (useMockData) {
      return _getMockMarketStats();
    }

    const cacheKey = 'market_stats';
    if (_isCacheValid(cacheKey)) {
      return _cache[cacheKey];
    }

    try {
      final response = await client.get(
        Uri.parse('$baseUrl/global'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body)['data'];
        
        _updateCache(cacheKey, data);
        return data;
      } else {
        throw Exception('Failed to load market stats: ${response.statusCode}');
      }
    } catch (e) {
      // Fallback to mock data if API fails
      return _getMockMarketStats();
    }
  }

  // MOCK DATA GENERATION
  List<CryptoCurrency> _getMockTrendingCoins() {
    return [
      CryptoCurrency(
        id: 'bitcoin',
        name: 'Bitcoin',
        symbol: 'BTC',
        currentPrice: 37500 + (_random.nextDouble() * 2000 - 1000),
        priceChangePercentage24h: _random.nextDouble() * 10 - 5,
        marketCap: 720000000000,
        volume24h: 25000000000,
        imageUrl: 'https://assets.coingecko.com/coins/images/1/large/bitcoin.png',
        sparklineData: _generateMockSparklineData(37000, 38000),
      ),
      CryptoCurrency(
        id: 'ethereum',
        name: 'Ethereum',
        symbol: 'ETH',
        currentPrice: 2200 + (_random.nextDouble() * 200 - 100),
        priceChangePercentage24h: _random.nextDouble() * 12 - 6,
        marketCap: 265000000000,
        volume24h: 15000000000,
        imageUrl: 'https://assets.coingecko.com/coins/images/279/large/ethereum.png',
        sparklineData: _generateMockSparklineData(2000, 2300),
      ),
      CryptoCurrency(
        id: 'cardano',
        name: 'Cardano',
        symbol: 'ADA',
        currentPrice: 0.45 + (_random.nextDouble() * 0.1 - 0.05),
        priceChangePercentage24h: _random.nextDouble() * 15 - 7.5,
        marketCap: 16000000000,
        volume24h: 500000000,
        imageUrl: 'https://assets.coingecko.com/coins/images/975/large/cardano.png',
        sparklineData: _generateMockSparklineData(0.4, 0.5),
      ),
      CryptoCurrency(
        id: 'solana',
        name: 'Solana',
        symbol: 'SOL',
        currentPrice: 120 + (_random.nextDouble() * 20 - 10),
        priceChangePercentage24h: _random.nextDouble() * 20 - 10,
        marketCap: 50000000000,
        volume24h: 2000000000,
        imageUrl: 'https://assets.coingecko.com/coins/images/4128/large/solana.png',
        sparklineData: _generateMockSparklineData(110, 130),
      ),
      CryptoCurrency(
        id: 'binancecoin',
        name: 'Binance Coin',
        symbol: 'BNB',
        currentPrice: 320 + (_random.nextDouble() * 30 - 15),
        priceChangePercentage24h: _random.nextDouble() * 8 - 4,
        marketCap: 48000000000,
        volume24h: 1500000000,
        imageUrl: 'https://assets.coingecko.com/coins/images/825/large/binance-coin-logo.png',
        sparklineData: _generateMockSparklineData(310, 330),
      ),
      CryptoCurrency(
        id: 'ripple',
        name: 'XRP',
        symbol: 'XRP',
        currentPrice: 0.60 + (_random.nextDouble() * 0.1 - 0.05),
        priceChangePercentage24h: _random.nextDouble() * 10 - 5,
        marketCap: 32000000000,
        volume24h: 1200000000,
        imageUrl: 'https://assets.coingecko.com/coins/images/44/large/xrp-symbol-white-128.png',
        sparklineData: _generateMockSparklineData(0.55, 0.65),
      ),
      CryptoCurrency(
        id: 'polkadot',
        name: 'Polkadot',
        symbol: 'DOT',
        currentPrice: 6.5 + (_random.nextDouble() * 1 - 0.5),
        priceChangePercentage24h: _random.nextDouble() * 12 - 6,
        marketCap: 8000000000,
        volume24h: 300000000,
        imageUrl: 'https://assets.coingecko.com/coins/images/12171/large/polkadot.png',
        sparklineData: _generateMockSparklineData(6, 7),
      ),
      CryptoCurrency(
        id: 'dogecoin',
        name: 'Dogecoin',
        symbol: 'DOGE',
        currentPrice: 0.08 + (_random.nextDouble() * 0.02 - 0.01),
        priceChangePercentage24h: _random.nextDouble() * 15 - 7.5,
        marketCap: 11000000000,
        volume24h: 700000000,
        imageUrl: 'https://assets.coingecko.com/coins/images/5/large/dogecoin.png',
        sparklineData: _generateMockSparklineData(0.07, 0.09),
      ),
      CryptoCurrency(
        id: 'avalanche-2',
        name: 'Avalanche',
        symbol: 'AVAX',
        currentPrice: 28 + (_random.nextDouble() * 4 - 2),
        priceChangePercentage24h: _random.nextDouble() * 18 - 9,
        marketCap: 10000000000,
        volume24h: 500000000,
        imageUrl: 'https://assets.coingecko.com/coins/images/12559/large/Avalanche_Circle_RedWhite_Trans.png',
        sparklineData: _generateMockSparklineData(26, 30),
      ),
      CryptoCurrency(
        id: 'chainlink',
        name: 'Chainlink',
        symbol: 'LINK',
        currentPrice: 15 + (_random.nextDouble() * 2 - 1),
        priceChangePercentage24h: _random.nextDouble() * 14 - 7,
        marketCap: 8500000000,
        volume24h: 400000000,
        imageUrl: 'https://assets.coingecko.com/coins/images/877/large/chainlink-new-logo.png',
        sparklineData: _generateMockSparklineData(14, 16),
      ),
    ];
  }

  CryptoCurrency _getMockCoinDetails(String coinId) {
    // Generate mock data for the requested coin
    final coins = _getMockTrendingCoins();
    final coin = coins.firstWhere(
      (c) => c.id == coinId,
      orElse: () => CryptoCurrency(
        id: coinId,
        name: coinId.substring(0, 1).toUpperCase() + coinId.substring(1),
        symbol: coinId.substring(0, 3).toUpperCase(),
        currentPrice: 100 + _random.nextDouble() * 900,
        priceChangePercentage24h: _random.nextDouble() * 20 - 10,
        marketCap: 1000000000 + _random.nextDouble() * 10000000000,
        volume24h: 100000000 + _random.nextDouble() * 1000000000,
        imageUrl: 'https://assets.coingecko.com/coins/images/1/large/bitcoin.png',
        sparklineData: _generateMockSparklineData(90, 110),
      ),
    );
    
    return coin;
  }

  List<HistoricalDataPoint> _getMockHistoricalData(
    String coinId,
    TimeInterval interval,
  ) {
    final coin = _getMockCoinDetails(coinId);
    final basePrice = coin.currentPrice;
    
    int dataPoints;
    double volatility;
    DateTime startDate = DateTime.now();
    
    switch (interval) {
      case TimeInterval.day:
        dataPoints = 24;
        volatility = 0.02;
        startDate = DateTime.now().subtract(Duration(days: 1));
        break;
      case TimeInterval.week:
        dataPoints = 7 * 24;
        volatility = 0.05;
        startDate = DateTime.now().subtract(Duration(days: 7));
        break;
      case TimeInterval.month:
        dataPoints = 30;
        volatility = 0.1;
        startDate = DateTime.now().subtract(Duration(days: 30));
        break;
      case TimeInterval.threeMonth:
        dataPoints = 90;
        volatility = 0.2;
        startDate = DateTime.now().subtract(Duration(days: 90));
        break;
      case TimeInterval.year:
        dataPoints = 365;
        volatility = 0.4;
        startDate = DateTime.now().subtract(Duration(days: 365));
        break;
      case TimeInterval.all:
        dataPoints = 1000;
        volatility = 0.8;
        startDate = DateTime.now().subtract(Duration(days: 1000));
        break;
    }
    
    final List<HistoricalDataPoint> historicalData = [];
    double currentPrice = basePrice;
    
    for (int i = 0; i < dataPoints; i++) {
      final timestamp = startDate.add(Duration(
        hours: (interval == TimeInterval.day || interval == TimeInterval.week) 
            ? i 
            : 0,
        days: (interval != TimeInterval.day && interval != TimeInterval.week) 
            ? i 
            : 0,
      ));
      
      // Apply random walk with trend
      final randomChange = (_random.nextDouble() * 2 - 1) * volatility;
      final trendFactor = 0.001; // Slight upward trend
      currentPrice = currentPrice * (1 + randomChange + trendFactor);
      if (currentPrice < 0) currentPrice = 0.01;
      
      historicalData.add(HistoricalDataPoint(
        timestamp: timestamp,
        price: currentPrice,
      ));
    }
    
    return historicalData;
  }

  CryptoPortfolio _getMockPortfolio(String userId) {
    final coins = _getMockTrendingCoins().take(5).toList();
    final List<PortfolioItem> holdings = [];
    double totalValue = 0;
    
    for (final coin in coins) {
      final amount = _random.nextDouble() * 10 + 0.1;
      final averageBuyPrice = coin.currentPrice * (0.8 + _random.nextDouble() * 0.4);
      final valueUsd = amount * coin.currentPrice;
      final profitLoss = valueUsd - (amount * averageBuyPrice);
      final profitLossPercentage = (profitLoss / (amount * averageBuyPrice)) * 100;
      
      holdings.add(PortfolioItem(
        coinId: coin.id,
        name: coin.name,
        symbol: coin.symbol,
        amount: amount,
        valueUsd: valueUsd,
        averageBuyPrice: averageBuyPrice,
        profitLoss: profitLoss,
        profitLossPercentage: profitLossPercentage,
      ));
      
      totalValue += valueUsd;
    }
    
    return CryptoPortfolio(
      userId: userId,
      holdings: holdings,
      totalValue: totalValue,
    );
  }

  Map<String, dynamic> _getMockMarketStats() {
    return {
      'active_cryptocurrencies': 10000 + _random.nextInt(2000),
      'markets': 600 + _random.nextInt(100),
      'total_market_cap': {
        'usd': 1500000000000 + _random.nextInt(200000000000),
      },
      'total_volume': {
        'usd': 80000000000 + _random.nextInt(20000000000),
      },
      'market_cap_percentage': {
        'btc': 40 + _random.nextDouble() * 10,
        'eth': 15 + _random.nextDouble() * 5,
      },
      'market_cap_change_percentage_24h_usd': _random.nextDouble() * 10 - 5,
    };
  }

  List<List<dynamic>> _generateMockSparklineData(double min, double max) {
    final List<List<dynamic>> sparklineData = [];
    double lastPrice = min + _random.nextDouble() * (max - min);
    
    for (int i = 0; i < 168; i++) { // 7 days hourly data
      final change = (0.5 - _random.nextDouble()) * 0.02; // -1% to +1%
      lastPrice = lastPrice * (1 + change);
      if (lastPrice < min) lastPrice = min;
      if (lastPrice > max) lastPrice = max;
      
      sparklineData.add([i, lastPrice]);
    }
    
    return sparklineData;
  }

  // Cache management
  bool _isCacheValid(String key) {
    if (!_cache.containsKey(key) || !_cacheExpiry.containsKey(key)) {
      return false;
    }
    return _cacheExpiry[key]!.isAfter(DateTime.now());
  }

  void _updateCache(String key, dynamic data) {
    _cache[key] = data;
    _cacheExpiry[key] = DateTime.now().add(_cacheDuration);
  }

  void clearCache() {
    _cache.clear();
    _cacheExpiry.clear();
  }

  // Clean up resources
  void dispose() {
    client.close();
  }
}

// StreamController for real-time price updates
class CryptoPriceService {
  static final CryptoPriceService _instance = CryptoPriceService._internal();
  factory CryptoPriceService() => _instance;
  
  final Map<String, StreamController<CryptoCurrency>> _priceControllers = {};
  final CryptoApiService _apiService = CryptoApiService();
  final Map<String, Timer> _updateTimers = {};
  final Random _random = Random();
  
  CryptoPriceService._internal();
  
  Stream<CryptoCurrency> getPriceUpdates(String coinId) {
    if (!_priceControllers.containsKey(coinId)) {
      _priceControllers[coinId] = StreamController<CryptoCurrency>.broadcast();
      _startPriceUpdates(coinId);
    }
    return _priceControllers[coinId]!.stream;
  }
  
  void _startPriceUpdates(String coinId) async {
    // Get initial price data
    CryptoCurrency coin = await _apiService.getCoinDetails(coinId);
    _priceControllers[coinId]?.add(coin);
    
    // Set up periodic updates every 10 seconds
    _updateTimers[coinId] = Timer.periodic(Duration(seconds: 10), (timer) async {
      try {
        // In a real app, fetch fresh data from API
        // Here we simulate price changes
        final priceChange = (0.5 - _random.nextDouble()) * 0.02; // -1% to +1%
        final newPrice = coin.currentPrice * (1 + priceChange);
        
        coin = CryptoCurrency(
          id: coin.id,
          name: coin.name,
          symbol: coin.symbol,
          currentPrice: newPrice,
          priceChangePercentage24h: coin.priceChangePercentage24h + priceChange * 100,
          marketCap: coin.marketCap * (1 + priceChange),
          volume24h: coin.volume24h,
          imageUrl: coin.imageUrl,
          sparklineData: coin.sparklineData,
        );
        
        _priceControllers[coinId]?.add(coin);
      } catch (e) {
        print('Error updating price for $coinId: $e');
      }
    });
  }
  
  void stopPriceUpdates(String coinId) {
    _updateTimers[coinId]?.cancel();
    _updateTimers.remove(coinId);
  }
  
  void dispose() {
    for (final coinId in _priceControllers.keys) {
      stopPriceUpdates(coinId);
      _priceControllers[coinId]?.close();
    }
    _priceControllers.clear();
    _apiService.dispose();
  }
}