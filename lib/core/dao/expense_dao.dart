import 'dart:convert';
import 'package:uuid/uuid.dart';
import '../models/expense.dart';
import '../api/api_client.dart';
import '../database/me_app_database.dart';
import 'package:sqflite/sqflite.dart';

class ExpenseDAO {
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
      description: expense.description,
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
        'description': expense.description,
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
      final expense = Expense.fromMap(map);
      _syncInsertExpense(expense);
    }
  }

  Future<List<Expense>> getExpensesByTrip(String tripId) async {
    final db = await AppDatabase().database;

    // 1. Tentar buscar da API para atualizar o banco local
    try {
      final response = await ApiClient.get('/expenses/trip/$tripId');
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));
        
        // Removemos o delete
        
        for (var e in data) {
          final expId = e['id'];
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
            description: e['description'],
            photoPath: e['photoPath'],
          );
          
          await db.insert(
            'expenses', 
            {...exp.toMap(), 'is_synced': 1},
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
      }
    } catch (e) {
      print("Offline: Buscando gastos locais do SQLite. Erro API: $e");
    }

    // 2. Retornar os dados do banco local
    final List<Map<String, dynamic>> maps = await db.query(
      'expenses',
      where: 'trip_id = ?',
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
    await db.delete('expenses', where: 'id = ?', whereArgs: [id]);

    try {
      await ApiClient.delete('/expenses/$id');
    } catch (e) {
      print("Offline: Falha ao deletar gasto na API. Erro: $e");
    }
    return 1;
  }
}
