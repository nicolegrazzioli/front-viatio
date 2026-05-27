import 'dart:convert';
import 'package:intl/intl.dart';
import '../models/expense.dart';
import '../api/api_client.dart';
import '../dao/expense_dao.dart';

class ExpenseRepository {
  final ExpenseDAO _dao = ExpenseDAO();

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
    final expenseId = await _dao.insertExpense(expense, isSynced: 0);
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
      if (expense.id != null) {
        await _dao.updateSyncStatus(expense.id!, 1);
      }
    } catch (e) {
      print("Offline: Gasto salvo apenas localmente. Erro API: \$e");
    }
  }

  Future<void> syncUnsyncedExpenses() async {
    final unsynced = await _dao.getUnsyncedExpenses();
    for (var map in unsynced) {
      final id = map['id'] as String;
      if (map['is_deleted'] == 1) {
        await _syncDeleteExpense(id);
      } else {
        final expense = Expense.fromMap(map);
        await _syncInsertExpense(expense);
      }
    }
  }

  Future<List<Expense>> getExpensesByTrip(String tripId, {bool fetchApi = true}) async {
    if (fetchApi) {
      try {
        final response = await ApiClient.get('/expenses/trip/\$tripId');
        if (response.statusCode == 200) {
          final List<dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));
          final List<String> apiIds = [];
          
          for (var e in data) {
            final expId = e['id'];
            apiIds.add(expId);
            
            final localData = await _dao.getExpenseById(expId);
            if (localData != null && localData['is_synced'] == 0) {
              continue;
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
            
            await _dao.insertExpense(exp, isSynced: 1);
          }

          final localSynced = await _dao.getSyncedExpenses(tripId);
          for (var local in localSynced) {
            if (!apiIds.contains(local['id'])) {
              await _dao.deleteExpenseHard(local['id'] as String);
            }
          }
        }
      } catch (e) {
        print("Offline: Buscando gastos locais do SQLite. Erro API: \$e");
      }
    }

    return await _dao.getExpensesByTrip(tripId);
  }

  Future<int> updateExpense(Expense expense) async {
    int rows = await _dao.updateExpense(expense, isSynced: 0);
    _syncInsertExpense(expense);
    return rows;
  }

  Future<int> deleteExpense(String id) async {
    await _dao.markAsDeleted(id);
    _syncDeleteExpense(id);
    return 1;
  }

  Future<void> _syncDeleteExpense(String id) async {
    try {
      await ApiClient.delete('/expenses/\$id');
      await _dao.deleteExpenseHard(id);
    } catch (e) {
      print("Offline: Deleção de gasto agendada. Erro API: \$e");
    }
  }

  Future<double> getTripVet(String userId, String tripId, String currency) {
    return _dao.getTripVet(userId, tripId, currency);
  }

  Future<void> updateDynamicVetForTrips(String userId, String currency) {
    return _dao.updateDynamicVetForTrips(userId, currency);
  }
}

