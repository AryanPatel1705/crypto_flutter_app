// Create a file services/portfolio_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/crypto_model.dart';

class PortfolioService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get current user ID or throw an exception if not logged in
  String get _userId {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User not logged in');
    }
    return user.uid;
  }

  // Get portfolio collection reference for current user
  CollectionReference get _portfolioRef => 
      _firestore.collection('users').doc(_userId).collection('portfolio');

  // Add or update a crypto in the user's portfolio
  Future<void> addToPortfolio(CryptoModel crypto, double amount, double purchasePrice) async {
    try {
      // Check if the crypto already exists in the portfolio
      final querySnapshot = await _portfolioRef
          .where('cryptoId', isEqualTo: crypto.id)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        // Update existing entry
        final docId = querySnapshot.docs.first.id;
        final existingData = querySnapshot.docs.first.data() as Map<String, dynamic>;
        final existingAmount = existingData['amount'] as double? ?? 0.0;
        
        await _portfolioRef.doc(docId).update({
          'amount': existingAmount + amount,
          'lastUpdated': FieldValue.serverTimestamp(),
          'currentPrice': crypto.currentPrice,
        });
      } else {
        // Add new entry
        await _portfolioRef.add({
          'cryptoId': crypto.id,
          'name': crypto.name,
          'symbol': crypto.symbol,
          'image': crypto.image,
          'amount': amount,
          'purchasePrice': purchasePrice,
          'currentPrice': crypto.currentPrice,
          'dateAdded': FieldValue.serverTimestamp(),
          'lastUpdated': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      print('Error adding to portfolio: $e');
      rethrow;
    }
  }

  // Get stream of user's portfolio
  Stream<List<PortfolioItem>> getPortfolioStream() {
    try {
      return _portfolioRef.snapshots().map((snapshot) {
        return snapshot.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return PortfolioItem(
            id: doc.id,
            cryptoId: data['cryptoId'],
            name: data['name'],
            symbol: data['symbol'],
            image: data['image'] ?? '',
            amount: (data['amount'] as num).toDouble(),
            purchasePrice: (data['purchasePrice'] as num).toDouble(),
            currentPrice: (data['currentPrice'] as num).toDouble(),
          );
        }).toList();
      });
    } catch (e) {
      print('Error getting portfolio: $e');
      rethrow;
    }
  }

  // Remove crypto from portfolio
  Future<void> removeCrypto(String portfolioItemId) async {
    try {
      await _portfolioRef.doc(portfolioItemId).delete();
    } catch (e) {
      print('Error removing crypto: $e');
      rethrow;
    }
  }

  // Update amount of a crypto in portfolio
  Future<void> updateAmount(String portfolioItemId, double newAmount) async {
    try {
      await _portfolioRef.doc(portfolioItemId).update({
        'amount': newAmount,
        'lastUpdated': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error updating amount: $e');
      rethrow;
    }
  }

  // Get total portfolio value
  Future<double> getTotalPortfolioValue() async {
    try {
      final snapshot = await _portfolioRef.get();
      double total = 0;
      
      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final amount = (data['amount'] as num).toDouble();
        final currentPrice = (data['currentPrice'] as num).toDouble();
        total += amount * currentPrice;
      }
      
      return total;
    } catch (e) {
      print('Error calculating portfolio value: $e');
      return 0;
    }
  }
}

// Portfolio item model
class PortfolioItem {
  final String id;
  final String cryptoId;
  final String name;
  final String symbol;
  final String image;
  final double amount;
  final double purchasePrice;
  final double currentPrice;

  PortfolioItem({
    required this.id,
    required this.cryptoId,
    required this.name,
    required this.symbol,
    required this.image,
    required this.amount,
    required this.purchasePrice,
    required this.currentPrice,
  });

  // Calculate current value
  double get currentValue => amount * currentPrice;

  // Calculate purchase value
  double get purchaseValue => amount * purchasePrice;

  // Calculate profit/loss
  double get profitLoss => currentValue - purchaseValue;

  // Calculate profit/loss percentage
  double get profitLossPercentage => 
      purchaseValue > 0 ? (profitLoss / purchaseValue) * 100 : 0;
}