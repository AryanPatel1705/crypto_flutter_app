

class CryptoModel {
  final String id;
  final String symbol;
  final String name;
  final String image;
  double currentPrice;  // Remove final to allow updates
  double priceChangePercentage24h;  // Remove final to allow updates
  final double? marketCap;
  final double? totalVolume;
  final double? high24h;
  final double? low24h;
  final int marketCapRank; 
  final double circulatingSupply;
  final double ath;

  
  CryptoModel({
    required this.id,
    required this.symbol,
    required this.name,
    required this.image,
    required this.currentPrice,
    required this.priceChangePercentage24h,
    required this.marketCapRank,
    this.marketCap,
    required this.circulatingSupply,
    required this.ath,
    this.totalVolume,
    this.high24h,
    this.low24h,
  });
  
  // Factory constructor to create a CryptoModel from JSON
  factory CryptoModel.fromJson(Map<String, dynamic> json) {
    return CryptoModel(
      id: json['id'],
      symbol: json['symbol'],
      name: json['name'],
      image: json['image'] ?? '',
      currentPrice: (json['current_price'] ?? 0.0).toDouble(),
      priceChangePercentage24h: (json['price_change_percentage_24h'] ?? 0.0).toDouble(),
      marketCap: json['market_cap']?.toDouble(),
      totalVolume: json['total_volume']?.toDouble(),
      high24h: json['high_24h']?.toDouble(),
      low24h: json['low_24h']?.toDouble(),
      marketCapRank: json['market_cap_rank'] ?? 0,
      circulatingSupply: (json['circulating_supply'] ?? 0.0).toDouble(),
      ath: (json['ath'] ?? 0.0).toDouble(),
    );
  }
}