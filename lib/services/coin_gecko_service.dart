import 'dart:convert';
import 'package:http/http.dart' as http;

class CoinGeckoService {
  final String baseUrl = 'https://api.coingecko.com/api/v3';
  
  Future<List<Map<String, dynamic>>> getAllCoins() async {
    final response = await http.get(Uri.parse('$baseUrl/coins/markets?vs_currency=usd'));

    if (response.statusCode == 200) {
      return List<Map<String, dynamic>>.from(json.decode(response.body));
    } else {
      throw Exception('Failed to load coins');
    }
  }

  Future<Map<String, dynamic>> getCoinDetails(String coinId) async {
    final response = await http.get(Uri.parse('$baseUrl/coins/$coinId'));

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load coin details');
    }
  }

  Future<Map<String, dynamic>> getCoinMarketChart(String coinId, int days) async {
    final response = await http.get(Uri.parse('$baseUrl/coins/$coinId/market_chart?vs_currency=usd&days=$days'));

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load market chart');
    }
  }
}
