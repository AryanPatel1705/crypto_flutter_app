import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:crypto_flutter_app/models/crypto_model.dart';
import 'dart:js' as js;

class CoinGeckoService {
  // Change this URL based on the API key type
  late final String _baseUrl;
  late final String _apiKey;
  late final bool _isProApiKey;
  
  // Singleton pattern
  static final CoinGeckoService _instance = CoinGeckoService._internal();
  
  factory CoinGeckoService() {
    return _instance;
  }
  
  CoinGeckoService._internal() {
    // Initialize API key
    _apiKey = _getApiKey();
    
    // Check if this is a demo key (starts with 'CG-')
    _isProApiKey = !_apiKey.startsWith('CG-');
    
    // Set the appropriate base URL
    _baseUrl = _isProApiKey 
        ? 'https://pro-api.coingecko.com/api/v3'
        : 'https://api.coingecko.com/api/v3';
  }
  
  String _getApiKey() {
    if (kIsWeb) {
      // Get API key from window object on web
      final dynamic apiKey = js.context.callMethod('getCoinGeckoApiKey');
      if (apiKey != null) {
        return apiKey.toString();
      }
    }
    
    // Fallback to a local constant
    const fallbackKey = 'CG-Xt39uAKKppngAphiX4SAhD9S';
    return fallbackKey;
  }
  
  // Add API key to headers or query parameters based on API type
  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    if (_isProApiKey) 'X-CG-Pro-API-Key': _apiKey,
  };
  
  // Add API key to URI if using demo key
  Uri _buildUri(String endpoint, Map<String, dynamic> queryParams) {
    // Add API key to query parameters for demo API
    if (!_isProApiKey) {
      queryParams['x_cg_demo_api_key'] = _apiKey;
    }
    
    return Uri.parse('$_baseUrl$endpoint').replace(
      queryParameters: queryParams.map((key, value) => MapEntry(key, value.toString())),
    );
  }
  
  // Fetch list of trending cryptocurrencies
  Future<List<CryptoModel>> getTrendingCryptoList() async {
    try {
      final response = await http.get(
        _buildUri('/search/trending', {}),
        headers: _headers,
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> coins = data['coins'];
        
        return coins.map((coin) {
          final item = coin['item'];
          return CryptoModel(
            id: item['id'],
            name: item['name'],
            symbol: item['symbol'],
            image: item['large'] ?? '',
            currentPrice: 0.0, // Price not included in trending endpoint
            priceChangePercentage24h: 0.0,
            marketCapRank: item['market_cap_rank'] ?? 0,
            circulatingSupply: 0.0,
            ath: 0.0,
          );
        }).toList();
      } else {
        print('Failed to load trending cryptocurrencies: ${response.statusCode}');
        print('Response: ${response.body}');
        return [];
      }
    } catch (e) {
      print('Error fetching trending cryptocurrencies: $e');
      return [];
    }
  }
  
  // Fetch cryptocurrency list with market data
  Future<List<CryptoModel>> getCryptoList({
    int page = 1,
    int perPage = 20,
    String vsCurrency = 'usd',
    String order = 'market_cap_desc',
  }) async {
    try {
      final queryParams = {
        'vs_currency': vsCurrency,
        'order': order,
        'per_page': perPage,
        'page': page,
        'sparkline': false,
        'price_change_percentage': '24h',
      };
      
      final response = await http.get(
        _buildUri('/coins/markets', queryParams),
        headers: _headers,
      );
      
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        
        return data.map((json) => CryptoModel(
          id: json['id'],
          name: json['name'],
          symbol: json['symbol'],
          image: json['image'] ?? '',
          currentPrice: json['current_price']?.toDouble() ?? 0.0,
          priceChangePercentage24h: json['price_change_percentage_24h']?.toDouble() ?? 0.0,
          marketCap: json['market_cap']?.toDouble(),
          totalVolume: json['total_volume']?.toDouble(),
          high24h: json['high_24h']?.toDouble(),
          low24h: json['low_24h']?.toDouble(),
          marketCapRank: json['market_cap_rank'] ?? 0,
          circulatingSupply: json['circulating_supply']?.toDouble() ?? 0.0,
          ath: json['ath']?.toDouble() ?? 0.0,
        )).toList();
      } else {
        print('Failed to load cryptocurrencies: ${response.statusCode}');
        print('Response: ${response.body}');
        return [];
      }
    } catch (e) {
      print('Error fetching cryptocurrencies: $e');
      return [];
    }
  }
  
  // Get historical market data for chart
  Future<List<List<double>>> getHistoricalMarketData(
    String id,  // This is a required positional parameter
    {
      String? vsCurrency = 'usd',  // These are optional named parameters
      int? days = 30,
      String? interval = 'daily',
    }
  ) async {
    try {
      final queryParams = {
        'vs_currency': vsCurrency,
        'days': days,
        'interval': interval,
      };
      
      final response = await http.get(
        _buildUri('/coins/$id/market_chart', queryParams),
        headers: _headers,
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> prices = data['prices'];
        
        return prices.map<List<double>>((price) {
          return [
            (price[0] as num).toDouble(), // timestamp
            (price[1] as num).toDouble(), // price
          ];
        }).toList();
      } else {
        print('Failed to load historical data: ${response.statusCode}');
        print('Response: ${response.body}');
        return [];
      }
    } catch (e) {
      print('Error fetching historical data: $e');
      return [];
    }
  }
  
  // Get detailed data for a specific cryptocurrency
  Future<Map<String, dynamic>?> getCryptoDetail(String id) async {
    try {
      final queryParams = {
        'localization': false,
        'tickers': true,
        'market_data': true,
        'community_data': true,
        'developer_data': false,
        'sparkline': true,
      };
      
      final response = await http.get(
        _buildUri('/coins/$id', queryParams),
        headers: _headers,
      );
      
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        print('Failed to load crypto detail: ${response.statusCode}');
        print('Response: ${response.body}');
        return null;
      }
    } catch (e) {
      print('Error fetching crypto detail: $e');
      return null;
    }
  }
  
  // Setup polling for price updates
  Stream<double> getLivePriceStream(String cryptoId) {
    // Create a controller for the price stream
    final controller = StreamController<double>.broadcast();
    
    // Poll for price updates every 10 seconds
    Timer.periodic(Duration(seconds: 10), (timer) async {
      try {
        final queryParams = {
          'ids': cryptoId,
          'vs_currencies': 'usd',
        };
        
        final response = await http.get(
          _buildUri('/simple/price', queryParams),
          headers: _headers,
        );
        
        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          final price = data[cryptoId]['usd'].toDouble();
          controller.add(price);
        } else {
          print('Failed to load price: ${response.statusCode}');
        }
      } catch (e) {
        print('Error fetching price: $e');
      }
    });
    
    // Return the stream and handle cleanup
    return controller.stream.asBroadcastStream(
      onCancel: (subscription) {
        controller.close();
      }
    );
  }
  
  // Search for cryptocurrencies
  Future<List<CryptoModel>> searchCryptos(String query) async {
    try {
      final response = await http.get(
        _buildUri('/search', {'query': query}),
        headers: _headers,
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> coins = data['coins'];
        
        return coins.map((coin) => CryptoModel(
          id: coin['id'],
          name: coin['name'],
          symbol: coin['symbol'],
          image: coin['large'] ?? '',
          currentPrice: 0.0,
          priceChangePercentage24h: 0.0,
          marketCapRank: coin['market_cap_rank'] ?? 0,
          circulatingSupply: 0.0,
          ath: 0.0,
        )).toList();
      } else {
        print('Failed to search cryptocurrencies: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('Error searching cryptocurrencies: $e');
      return [];
    }
  }
}