import 'dart:convert';
import 'package:uuid/uuid.dart';
import '../models/expense.dart';
import '../api/api_client.dart';
import '../database/me_app_database.dart';
import 'package:sqflite/sqflite.dart';
import 'package:intl/intl.dart';

class ExpenseDAO {
  final _uuid = const Uuid();

  String _toApiDate(String date) {
    try {
      final d = DateFormat('dd/MM/yyyy').parse(date);
      return DateFormat('yyyy-MM-dd').format(d);
    } catch (e) {
      return date;
    }
  }

  String _fromApiDate(String date) {
    try {
      final d = DateFormat('yyyy-MM-dd').parse(date);
      return DateFormat('dd/MM/yyyy').format(d);
    } catch (e) {
      return date;
    }
  }

  Future<String> insertExpense(Expense expense) async {
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

    // Salva localmente como não sincronizado
    await db.insert(
      'expenses', 
      {...newExpense.toMap(), 'is_synced': 0},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    _syncInsertExpense(newExpense);

    return expenseId;
  }

  Future<void> _syncInsertExpense(Expense expense) async {
    try {
      await ApiClient.post('/expenses', {
        'id': expense.id,
        'tripId': expense.tripId,
        'title': expense.title,
        'amount': expense.amount,
        'currency': expense.currency,
        'category': expense.category,
        'date': _toApiDate(expense.date),
        'isAverageCost': expense.isAverageCost,
        'exchangeRate': expense.exchangeRate,
        'amountBrl': expense.amountBrl,

        'photoPath': expense.photoPath,
      });
      // Se sucesso, marca como sincronizado
      final db = await AppDatabase().database;
      await db.update('expenses', {'is_synced': 1}, where: 'id = ?', whereArgs: [expense.id]);
    } catch (e) {
      print("Offline: Gasto salvo apenas localmente. Erro API: $e");
    }
  }

  Future<void> syncUnsyncedExpenses() async {
    final db = await AppDatabase().database;
    final unsynced = await db.query('expenses', where: 'is_synced = ?', whereArgs: [0]);
    for (var map in unsynced) {
      if (map['is_deleted'] == 1) {
        _syncDeleteExpense(map['id'] as String);
      } else {
        final expense = Expense.fromMap(map);
        _syncInsertExpense(expense);
      }
    }
  }

  Future<List<Expense>> getExpensesByTrip(String tripId, {bool fetchApi = true}) async {
    final db = await AppDatabase().database;

    // 1. Tentar buscar da API para atualizar o banco local
    if (fetchApi) {
      try {
        final response = await ApiClient.get('/expenses/trip/$tripId');
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));
        
        // Removemos o delete
        
        final List<String> apiIds = [];
        for (var e in data) {
          final expId = e['id'];
          apiIds.add(expId);
          final localData = await db.query('expenses', where: 'id = ?', whereArgs: [expId]);
          
          if (localData.isNotEmpty && localData.first['is_synced'] == 0) {
            continue; // Pula para não sobrescrever
          }
          
          final exp = Expense(
            id: expId,
            tripId: e['tripId'],
            title: e['title'],
            amount: e['amount']?.toDouble() ?? 0.0,
            currency: e['currency'],
            category: e['category'],
            date: _fromApiDate(e['date']),
            isAverageCost: e['isAverageCost'] ?? false,
            exchangeRate: e['exchangeRate']?.toDouble() ?? 1.0,
            amountBrl: e['amountBrl']?.toDouble() ?? 0.0,

            photoPath: e['photoPath'],
          );
          
          await db.insert(
            'expenses', 
            {...exp.toMap(), 'is_synced': 1},
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }

        // Remove despesas que foram apagadas no backend
        final localSynced = await db.query('expenses', where: 'trip_id = ? AND is_synced = ?', whereArgs: [tripId, 1]);
        for (var local in localSynced) {
          if (!apiIds.contains(local['id'])) {
            await db.delete('expenses', where: 'id = ?', whereArgs: [local['id']]);
          }
        }
      }
    } catch (e) {
      print("Offline: Buscando gastos locais do SQLite. Erro API: $e");
    }
    }

    // 2. Retornar os dados do banco local que não estão marcados como deletados
    final List<Map<String, dynamic>> maps = await db.query(
      'expenses',
      where: 'trip_id = ? AND is_deleted = 0',
      whereArgs: [tripId],
    );

    return List.generate(maps.length, (i) => Expense.fromMap(maps[i]));
  }

  Future<int> updateExpense(Expense expense) async {
    final db = await AppDatabase().database;
    await db.update(
      'expenses',
      {...expense.toMap(), 'is_synced': 0},
      where: 'id = ?',
      whereArgs: [expense.id],
    );
    
    _syncInsertExpense(expense);
    return 1;
  }

  Future<int> deleteExpense(String id) async {
    final db = await AppDatabase().database;
    await db.update('expenses', {'is_deleted': 1, 'is_synced': 0}, where: 'id = ?', whereArgs: [id]);

    _syncDeleteExpense(id);
    return 1;
  }

  Future<void> _syncDeleteExpense(String id) async {
    try {
      await ApiClient.delete('/expenses/$id');
      final db = await AppDatabase().database;
      await db.delete('expenses', where: 'id = ?', whereArgs: [id]);
    } catch (e) {
      print("Offline: Deleção de gasto agendada. Erro API: $e");
    }
  }

  Future<double> getTripVet(String userId, String tripId, String currency) async {
    final db = await AppDatabase().database;
    final tripRes = await db.query('trips', where: 'id = ?', whereArgs: [tripId]);
    if (tripRes.isEmpty) return 1.0;
    
    final endDateStr = tripRes.first['end_date'] as String?;
    DateTime? cutoffDate;
    if (endDateStr != null && endDateStr.isNotEmpty) {
      try {
        final parts = endDateStr.split('/');
        cutoffDate = DateTime(int.parse(parts[2]), int.parse(parts[1]), int.parse(parts[0]), 23, 59, 59);
      } catch(e) {}
    }
    
    final txs = await db.query('currency_transactions', where: 'user_id = ? AND currency = ? AND is_deleted = 0', whereArgs: [userId, currency]);
    double totalBought = 0.0;
    double totalBrl = 0.0;
    
    for (var tx in txs) {
      DateTime txDate = DateTime.now();
      try {
        final parts = (tx['date'] as String).split('/');
        txDate = DateTime(int.parse(parts[2]), int.parse(parts[1]), int.parse(parts[0]));
      } catch(e) {}
      
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
        final parts = (tx['date'] as String).split('/');
        date = DateTime(int.parse(parts[2]), int.parse(parts[1]), int.parse(parts[0]));
      } catch(e) {}
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
          final parts = endDateStr.split('/');
          cutoffDate = DateTime(int.parse(parts[2]), int.parse(parts[1]), int.parse(parts[0]), 23, 59, 59);
        } catch(e) {}
      }
      
      double totalBought = 0.0;
      double totalBrl = 0.0;
      for (var tx in parsedTxs) {
        if (cutoffDate == null || (tx['date'] as DateTime).isBefore(cutoffDate!) || (tx['date'] as DateTime).isAtSameMomentAs(cutoffDate!)) {
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
