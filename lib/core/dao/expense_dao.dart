import 'package:uuid/uuid.dart';
import '../models/expense.dart';
import '../database/me_app_database.dart';
import 'package:sqflite/sqflite.dart';

class ExpenseDAO {
  final _uuid = const Uuid();

  Future<String> insertExpense(Expense expense, {int isSynced = 0}) async {
    final db = await AppDatabase().database;
    final String expenseId = expense.id ?? _uuid.v4();

    final newExpense = Expense(
      id: expenseId,
      tripId: expense.tripId,
      title: expense.title,
      amount: expense.amount,
      currency: expense.currency,
      category: expense.category,
      date: expense.date,
      isAverageCost: expense.isAverageCost,
      exchangeRate: expense.exchangeRate,
      amountBrl: expense.amountBrl,
      photoPath: expense.photoPath,
    );

    await db.insert(
      'expenses', 
      {...newExpense.toMap(), 'is_synced': isSynced},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    return expenseId;
  }

  Future<List<Map<String, dynamic>>> getUnsyncedExpenses() async {
    final db = await AppDatabase().database;
    return await db.query('expenses', where: 'is_synced = ?', whereArgs: [0]);
  }

  Future<List<Map<String, dynamic>>> getSyncedExpenses(String tripId) async {
    final db = await AppDatabase().database;
    return await db.query('expenses', where: 'trip_id = ? AND is_synced = ?', whereArgs: [tripId, 1]);
  }

  Future<Map<String, dynamic>?> getExpenseById(String expenseId) async {
    final db = await AppDatabase().database;
    final result = await db.query('expenses', where: 'id = ?', whereArgs: [expenseId]);
    return result.isNotEmpty ? result.first : null;
  }

  Future<List<Expense>> getExpensesByTrip(String tripId) async {
    final db = await AppDatabase().database;
    final List<Map<String, dynamic>> maps = await db.query(
      'expenses',
      where: 'trip_id = ? AND is_deleted = 0',
      whereArgs: [tripId],
    );
    return List.generate(maps.length, (i) => Expense.fromMap(maps[i]));
  }

  Future<int> updateExpense(Expense expense, {int isSynced = 0}) async {
    final db = await AppDatabase().database;
    return await db.update(
      'expenses',
      {...expense.toMap(), 'is_synced': isSynced},
      where: 'id = ?',
      whereArgs: [expense.id],
    );
  }

  Future<int> markAsDeleted(String id) async {
    final db = await AppDatabase().database;
    return await db.update('expenses', {'is_deleted': 1, 'is_synced': 0}, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> updateSyncStatus(String id, int isSynced) async {
    final db = await AppDatabase().database;
    return await db.update('expenses', {'is_synced': isSynced}, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deleteExpenseHard(String id) async {
    final db = await AppDatabase().database;
    return await db.delete('expenses', where: 'id = ?', whereArgs: [id]);
  }

  // Métodos de cálculo de VET que são puramente operações SQLite
  Future<double> getTripVet(String userId, String tripId, String currency) async {
    final db = await AppDatabase().database;
    final tripRes = await db.query('trips', where: 'id = ?', whereArgs: [tripId]);
    if (tripRes.isEmpty) return 1.0;
    
    final endDateStr = tripRes.first['end_date'] as String?;
    DateTime? cutoffDate;
    if (endDateStr != null && endDateStr.isNotEmpty) {
      try {
        final parsed = DateTime.parse(endDateStr);
        cutoffDate = DateTime(parsed.year, parsed.month, parsed.day, 23, 59, 59);
      } catch (e) {
        // Ignorar
      }
    }
    
    final txs = await db.query('currency_transactions', where: 'user_id = ? AND currency = ? AND is_deleted = 0', whereArgs: [userId, currency]);
    double totalBought = 0.0;
    double totalBrl = 0.0;
    
    for (var tx in txs) {
      DateTime txDate = DateTime.now();
      try {
        final parsed = DateTime.parse(tx['date'] as String);
        txDate = DateTime(parsed.year, parsed.month, parsed.day);
      } catch (e) {
        // Ignorar
      }
      
      if (cutoffDate == null || txDate.isBefore(cutoffDate) || txDate.isAtSameMomentAs(cutoffDate)) {
        totalBought += (tx['amount'] as num?)?.toDouble() ?? 0.0;
        totalBrl += (tx['amount_brl'] as num?)?.toDouble() ?? 0.0;
      }
    }
    
    if (totalBought > 0) {
      return totalBrl / totalBought;
    }
    
    return 0.0;
  }

  Future<void> updateDynamicVetForTrips(String userId, String currency) async {
    final db = await AppDatabase().database;
    final trips = await db.query('trips', where: 'user_id = ? AND is_deleted = 0', whereArgs: [userId]);
    final txs = await db.query('currency_transactions', where: 'user_id = ? AND currency = ? AND is_deleted = 0', whereArgs: [userId, currency]);
    
    final parsedTxs = txs.map((tx) {
      DateTime date = DateTime.now();
      try {
        final parsed = DateTime.parse(tx['date'] as String);
        date = DateTime(parsed.year, parsed.month, parsed.day);
      } catch (e) {
        // Ignorar
      }
      return {
        'date': date,
        'amount': (tx['amount'] as num?)?.toDouble() ?? 0.0,
        'amount_brl': (tx['amount_brl'] as num?)?.toDouble() ?? 0.0,
      };
    }).toList();

    for (var trip in trips) {
      final tripId = trip['id'] as String;
      final endDateStr = trip['end_date'] as String?;
      
      DateTime? cutoffDate;
      if (endDateStr != null && endDateStr.isNotEmpty) {
        try {
          final parsed = DateTime.parse(endDateStr);
          cutoffDate = DateTime(parsed.year, parsed.month, parsed.day, 23, 59, 59);
        } catch (e) {
          // Ignorar
        }
      }
      
      double totalBought = 0.0;
      double totalBrl = 0.0;
      for (var tx in parsedTxs) {
        if (cutoffDate == null || (tx['date'] as DateTime).isBefore(cutoffDate) || (tx['date'] as DateTime).isAtSameMomentAs(cutoffDate)) {
          totalBought += tx['amount'] as double;
          totalBrl += tx['amount_brl'] as double;
        }
      }
      
      double tripVet = 0.0;
      if (totalBought > 0) {
        tripVet = totalBrl / totalBought;
      } else {
        tripVet = 0.0;
      }
      
      if (tripVet > 0) {
        await db.rawUpdate('''
          UPDATE expenses 
          SET exchange_rate = ?, amount_brl = amount * ?, is_synced = 0
          WHERE trip_id = ? AND currency = ? AND is_average_cost = 1 AND is_deleted = 0 AND (exchange_rate != ? OR amount_brl != (amount * ?))
        ''', [tripVet, tripVet, tripId, currency, tripVet, tripVet]);
      }
    }
  }
}
