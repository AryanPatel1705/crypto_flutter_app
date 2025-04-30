

import 'package:crypto_flutter_app/models/crypto_model.dart';

class CryptoCurrency {
  final String id;
  final String name;
  final String symbol;
  final String imageUrl;
  final double currentPrice;
  final double priceChangePercentage24h;
  final double marketCap;
  final double totalVolume;
  final double circulatingSupply;

  CryptoCurrency({
    required this.id,
    required this.name,
    required this.symbol,
    required this.imageUrl,
    required this.currentPrice,
    required this.priceChangePercentage24h,
    required this.marketCap,
    required this.totalVolume,
    required this.circulatingSupply,
  });

  // Optional: Add a factory constructor to create from API response
  factory CryptoCurrency.fromJson(Map<String, dynamic> json) {
    return CryptoCurrency(
      id: json['id'],
      name: json['name'],
      symbol: json['symbol'],
      imageUrl: json['image'],
      currentPrice: json['current_price'].toDouble(),
      priceChangePercentage24h: json['price_change_percentage_24h'].toDouble(),
      marketCap: json['market_cap'].toDouble(),
      totalVolume: json['total_volume'].toDouble(),
      circulatingSupply: json['circulating_supply'].toDouble(),
    );
  }

  static fromCryptoModel(CryptoModel crypto) {}
}