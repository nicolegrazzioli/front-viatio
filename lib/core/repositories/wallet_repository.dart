import 'dart:convert';
import '../models/wallet.dart';
import '../api/api_client.dart';
import '../dao/wallet_dao.dart';
import '../database/me_app_database.dart';
import 'package:sqflite/sqflite.dart';

class WalletRepository {
  final WalletDAO _dao = WalletDAO();

  Future<int> insertWallet(Wallet wallet) async {
    return await _dao.insertWallet(wallet);
  }

  Future<List<Wallet>> getWalletsByUser(String userId, {bool fetchApi = true}) async {
    if (fetchApi) {
      try {
        final response = await ApiClient.get('/wallets');
        if (response.statusCode == 200) {
          final List<dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));
          
          final db = await AppDatabase().database;
          final List<String> apiCurrencies = [];
          
          for (var e in data) {
            final currency = e['currency'];
            apiCurrencies.add(currency);
            final wallet = Wallet(
              userId: userId,
              currency: currency,
              balance: e['balance']?.toDouble() ?? 0.0,
              averageVet: e['averageVet']?.toDouble() ?? 0.0,
            );
            await db.insert(
              'wallets', 
              {...wallet.toMap(), 'is_synced': 1},
              conflictAlgorithm: ConflictAlgorithm.replace,
            );
          }
          
          final localSynced = await db.query('wallets', where: 'user_id = ? AND is_synced = ?', whereArgs: [userId, 1]);
          for (var local in localSynced) {
            if (!apiCurrencies.contains(local['currency'])) {
              await db.delete('wallets', where: 'user_id = ? AND currency = ?', whereArgs: [userId, local['currency']]);
            }
          }
        }
      } catch (e) {
        print("Offline: Buscando carteiras locais do SQLite. Erro API: $e");
      }
    }

    return await _dao.getWalletsByUser(userId, fetchApi: false);
  }

  Future<Wallet?> getWallet(String userId, String currency) async {
    return await _dao.getWallet(userId, currency);
  }

  Future<int> updateWallet(Wallet wallet) async {
    return await _dao.updateWallet(wallet);
  }

  Future<int> deleteWallet(String userId, String currency) async {
    return await _dao.deleteWallet(userId, currency);
  }
}
