import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../models/expense.dart';
import '../api/api_client.dart';
import '../dao/expense_dao.dart';

/// repositório que faz a mediação entre as chamadas da API de gastos e a persistência no banco local SQLite
class ExpenseRepository {
  final ExpenseDAO _dao = ExpenseDAO();

  // formata um DateTime para string no formato YYYY-MM-DD
  String _toApiDate(DateTime date) {
    return "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
  }

  // converte uma string de data recebida da API em DateTime
  DateTime _fromApiDate(String date) {
    try {
      return DateTime.parse(date);
    } catch (e) {
      return DateTime.now();
    }
  }

  /// insere um novo gasto localmente e dispara a tentativa de sincronização com o servidor
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

  // envia as informações de um gasto para a API e atualiza a flag is_synced local ao obter sucesso
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
      debugPrint("Offline: Gasto salvo apenas localmente. Erro API: $e");
    }
  }

  /// localiza e sincroniza todos os gastos salvos ou deletados em modo offline com a API do servidor
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

  /// busca gastos na API para atualizar o banco de dados local com tratamento offline e remove inconsistências deletadas
  Future<List<Expense>> getExpensesByTrip(String tripId, {bool fetchApi = true}) async {
    if (fetchApi) {
      try {
        final response = await ApiClient.get('/expenses/trip/$tripId');
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
            
            if (localData != null) {
              await _dao.updateExpense(exp, isSynced: 1);
            } else {
              await _dao.insertExpense(exp, isSynced: 1);
            }
          }

          final localSynced = await _dao.getSyncedExpenses(tripId);
          for (var local in localSynced) {
            if (!apiIds.contains(local['id'])) {
              await _dao.deleteExpenseHard(local['id'] as String);
            }
          }
        }
      } catch (e) {
        debugPrint("Offline: Buscando gastos locais do SQLite. Erro API: $e");
      }
    }

    return await _dao.getExpensesByTrip(tripId);
  }

  /// edita um gasto existente localmente e envia a atualização para o servidor
  Future<int> updateExpense(Expense expense) async {
    int rows = await _dao.updateExpense(expense, isSynced: 0);
    _syncInsertExpense(expense);
    return rows;
  }

  /// marca um gasto local como excluído e solicita a remoção no servidor
  Future<int> deleteExpense(String id) async {
    await _dao.markAsDeleted(id);
    _syncDeleteExpense(id);
    return 1;
  }

  // faz a chamada de remoção na API e remove fisicamente o gasto do SQLite local após a confirmação
  Future<void> _syncDeleteExpense(String id) async {
    try {
      await ApiClient.delete('/expenses/$id');
      await _dao.deleteExpenseHard(id);
    } catch (e) {
      debugPrint("Offline: Deleção de gasto agendada. Erro API: $e");
    }
  }

  /// expõe a busca pelo VET histórico de uma moeda com base na data do gasto
  Future<double> getHistoricalVet(String userId, String currency, DateTime targetDate) {
    return _dao.getHistoricalVet(userId, currency, targetDate);
  }
}

