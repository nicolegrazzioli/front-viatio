import 'dart:convert';
import '../models/wallet.dart';
import '../api/api_client.dart';
import '../database/me_app_database.dart';
import 'package:sqflite/sqflite.dart';

class WalletDAO {
  Future<int> insertWallet(Wallet wallet) async {
    final db = await AppDatabase().database;
    return await db.insert('wallets', wallet.toMap());
  }

  Future<List<Wallet>> getWalletsByUser(String userId, {bool fetchApi = true}) async {
    final db = await AppDatabase().database;

    if (fetchApi) {
      try {
        final response = await ApiClient.get('/wallets');
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));
        
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

    final List<Map<String, dynamic>> maps = await db.query(
      'wallets',
      where: 'user_id = ?',
      whereArgs: [userId],
    );

    return List.generate(maps.length, (i) => Wallet.fromMap(maps[i]));
  }

  Future<Wallet?> getWallet(String userId, String currency) async {
    final db = await AppDatabase().database;
    final List<Map<String, dynamic>> maps = await db.query(
      'wallets',
      where: 'user_id = ? AND currency = ?',
      whereArgs: [userId, currency],
    );
    if (maps.isNotEmpty) {
      return Wallet.fromMap(maps.first);
    }
    return null;
  }

  Future<int> updateWallet(Wallet wallet) async {
    final db = await AppDatabase().database;
    return await db.update(
      'wallets',
      wallet.toMap(),
      where: 'user_id = ? AND currency = ?',
      whereArgs: [wallet.userId, wallet.currency],
    );
  }

  Future<int> deleteWallet(String userId, String currency) async {
    final db = await AppDatabase().database;
    return await db.delete(
      'wallets',
      where: 'user_id = ? AND currency = ?',
      whereArgs: [userId, currency],
    );
  }
}
