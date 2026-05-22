import 'dart:convert';
import 'package:uuid/uuid.dart';
import '../models/currency_transaction.dart';
import '../api/api_client.dart';
import '../database/me_app_database.dart';
import 'package:sqflite/sqflite.dart';

class CurrencyTransactionDAO {
  final _uuid = const Uuid();

  String _toApiDate(String date) {
    final parts = date.split('/');
    if (parts.length == 3) {
      return "${parts[2]}-${parts[1]}-${parts[0]}";
    }
    return date;
  }

  String _fromApiDate(String date) {
    final parts = date.split('-');
    if (parts.length == 3) {
      return "${parts[2]}/${parts[1]}/${parts[0]}";
    }
    return date;
  }

  Future<String> insertTransaction(CurrencyTransaction transaction) async {
    final db = await AppDatabase().database;
    final String transactionId = transaction.id ?? _uuid.v4();

    final newTx = CurrencyTransaction(
      id: transactionId,
      userId: transaction.userId,
      amount: transaction.amount,
      currency: transaction.currency,
      amountBrl: transaction.amountBrl,
      source: transaction.source,
      date: transaction.date,
      vetRate: transaction.vetRate,
      description: transaction.description,
      photoPath: transaction.photoPath,
    );

    await db.insert(
      'currency_transactions', 
      {...newTx.toMap(), 'is_synced': 0},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    _syncInsertTransaction(newTx);

    return transactionId;
  }

  Future<void> _syncInsertTransaction(CurrencyTransaction transaction) async {
    try {
      await ApiClient.post('/currency-transactions', {
        'id': transaction.id,
        'amount': transaction.amount,
        'currency': transaction.currency,
        'amountBrl': transaction.amountBrl,
        'source': transaction.source,
        'date': _toApiDate(transaction.date),
        'vetRate': transaction.vetRate,
        'description': transaction.description,
        'photoPath': transaction.photoPath,
      });
      final db = await AppDatabase().database;
      await db.update('currency_transactions', {'is_synced': 1}, where: 'id = ?', whereArgs: [transaction.id]);
    } catch (e) {
      print("Offline: Transação salva apenas localmente. Erro API: $e");
    }
  }

  Future<void> syncUnsyncedTransactions() async {
    final db = await AppDatabase().database;
    final unsynced = await db.query('currency_transactions', where: 'is_synced = ?', whereArgs: [0]);
    for (var map in unsynced) {
      final transaction = CurrencyTransaction.fromMap(map);
      _syncInsertTransaction(transaction);
    }
  }

  Future<List<CurrencyTransaction>> getTransactionsByUser(String userId, {bool fetchApi = true}) async {
    final db = await AppDatabase().database;

    if (fetchApi) {
      try {
        final response = await ApiClient.get('/currency-transactions');
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));
        
        final List<String> apiIds = [];
        for (var e in data) {
          final txId = e['id'];
          apiIds.add(txId);
          final localData = await db.query('currency_transactions', where: 'id = ?', whereArgs: [txId]);
          
          if (localData.isNotEmpty && localData.first['is_synced'] == 0) {
            continue;
          }
          
          final tx = CurrencyTransaction(
            id: txId,
            userId: userId,
            amount: e['amount']?.toDouble() ?? 0.0,
            currency: e['currency'],
            amountBrl: e['amountBrl']?.toDouble() ?? 0.0,
            source: e['source'],
            date: _fromApiDate(e['date']),
            vetRate: e['vetRate']?.toDouble() ?? 1.0,
            description: e['description'],
            photoPath: e['photoPath'],
          );
          await db.insert(
            'currency_transactions', 
            {...tx.toMap(), 'is_synced': 1},
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }

        // Remove transações que foram apagadas no backend
        final localSynced = await db.query('currency_transactions', where: 'user_id = ? AND is_synced = ?', whereArgs: [userId, 1]);
        for (var local in localSynced) {
          if (!apiIds.contains(local['id'])) {
            await db.delete('currency_transactions', where: 'id = ?', whereArgs: [local['id']]);
          }
        }
      }
    } catch (e) {
      print("Offline: Buscando transações locais do SQLite. Erro API: $e");
    }
    }

    final List<Map<String, dynamic>> maps = await db.query(
      'currency_transactions',
      where: 'user_id = ?',
      whereArgs: [userId],
    );

    return List.generate(maps.length, (i) => CurrencyTransaction.fromMap(maps[i]));
  }

  Future<int> updateTransaction(CurrencyTransaction transaction) async {
    final db = await AppDatabase().database;
    await db.update(
      'currency_transactions',
      {...transaction.toMap(), 'is_synced': 0},
      where: 'id = ?',
      whereArgs: [transaction.id],
    );
    _syncInsertTransaction(transaction);
    return 1;
  }

  Future<int> deleteTransaction(String id) async {
    final db = await AppDatabase().database;
    await db.delete('currency_transactions', where: 'id = ?', whereArgs: [id]);

    try {
      await ApiClient.delete('/currency-transactions/$id');
    } catch (e) {
      print("Offline: Falha ao deletar transação na API. Erro: $e");
    }
    return 1;
  }
}
