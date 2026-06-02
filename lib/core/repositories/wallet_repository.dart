import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../models/wallet.dart';
import '../api/api_client.dart';
import '../dao/wallet_dao.dart';
import '../database/me_app_database.dart';
import 'package:sqflite/sqflite.dart';

/// repositório que faz a mediação entre as chamadas da API de carteiras e o armazenamento SQLite local
class WalletRepository {
  final WalletDAO _dao = WalletDAO();

  /// insere uma nova carteira de saldo no banco de dados local
  Future<int> insertWallet(Wallet wallet) async {
    return await _dao.insertWallet(wallet);
  }

  /// busca carteiras na API para atualizar o banco de dados local com tratamento offline e resolve remoções remotas
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
        debugPrint("Offline: Buscando carteiras locais do SQLite. Erro API: $e");
      }
    }

    return await _dao.getWalletsByUser(userId, fetchApi: false);
  }

  /// busca uma carteira específica de um usuário filtrada pela moeda correspondente
  Future<Wallet?> getWallet(String userId, String currency) async {
    return await _dao.getWallet(userId, currency);
  }

  /// atualiza as informações de saldo e VET de uma carteira específica no banco local
  Future<int> updateWallet(Wallet wallet) async {
    return await _dao.updateWallet(wallet);
  }

  /// remove a carteira do banco local
  Future<int> deleteWallet(String userId, String currency) async {
    return await _dao.deleteWallet(userId, currency);
  }
}
