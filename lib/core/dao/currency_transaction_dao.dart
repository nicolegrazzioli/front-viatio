import 'package:uuid/uuid.dart';
import '../models/currency_transaction.dart';
import '../database/me_app_database.dart';
import 'package:sqflite/sqflite.dart';

class CurrencyTransactionDAO {
  final _uuid = const Uuid();

  Future<String> insertTransaction(CurrencyTransaction transaction, {int isSynced = 0}) async {
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
      photoPath: transaction.photoPath,
    );

    await db.insert(
      'currency_transactions', 
      {...newTx.toMap(), 'is_synced': isSynced},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    return transactionId;
  }

  Future<List<Map<String, dynamic>>> getUnsyncedTransactions() async {
    final db = await AppDatabase().database;
    return await db.query('currency_transactions', where: 'is_synced = ?', whereArgs: [0]);
  }

  Future<List<Map<String, dynamic>>> getSyncedTransactions(String userId) async {
    final db = await AppDatabase().database;
    return await db.query('currency_transactions', where: 'user_id = ? AND is_synced = ?', whereArgs: [userId, 1]);
  }

  Future<Map<String, dynamic>?> getTransactionById(String txId) async {
    final db = await AppDatabase().database;
    final result = await db.query('currency_transactions', where: 'id = ?', whereArgs: [txId]);
    return result.isNotEmpty ? result.first : null;
  }

  Future<List<CurrencyTransaction>> getTransactionsByUser(String userId) async {
    final db = await AppDatabase().database;
    final List<Map<String, dynamic>> maps = await db.query(
      'currency_transactions',
      where: 'user_id = ? AND is_deleted = 0',
      whereArgs: [userId],
    );
    return List.generate(maps.length, (i) => CurrencyTransaction.fromMap(maps[i]));
  }

  Future<int> updateTransaction(CurrencyTransaction transaction, {int isSynced = 0}) async {
    final db = await AppDatabase().database;
    return await db.update(
      'currency_transactions',
      {...transaction.toMap(), 'is_synced': isSynced},
      where: 'id = ?',
      whereArgs: [transaction.id],
    );
  }

  Future<int> markAsDeleted(String id) async {
    final db = await AppDatabase().database;
    return await db.update('currency_transactions', {'is_deleted': 1, 'is_synced': 0}, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> updateSyncStatus(String id, int isSynced) async {
    final db = await AppDatabase().database;
    return await db.update('currency_transactions', {'is_synced': isSynced}, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deleteTransactionHard(String id) async {
    final db = await AppDatabase().database;
    return await db.delete('currency_transactions', where: 'id = ?', whereArgs: [id]);
  }
}
