import 'package:uuid/uuid.dart';
import '../models/expense.dart';
import '../database/me_app_database.dart';
import 'package:sqflite/sqflite.dart';

/// classe de acesso aos dados que executa queries SQL para gerenciar os gastos no SQLite
class ExpenseDAO {
  final _uuid = const Uuid();

  // insere ou substitui um gasto no banco local gerando um UUID se necessário
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

  // retorna a lista de gastos locais pendentes de sincronização
  Future<List<Map<String, dynamic>>> getUnsyncedExpenses() async {
    final db = await AppDatabase().database;
    return await db.query('expenses', where: 'is_synced = ?', whereArgs: [0]);
  }

  // busca gastos sincronizados associados a uma viagem específica
  Future<List<Map<String, dynamic>>> getSyncedExpenses(String tripId) async {
    final db = await AppDatabase().database;
    return await db.query('expenses', where: 'trip_id = ? AND is_synced = ?', whereArgs: [tripId, 1]);
  }

  // recupera o registro de um gasto pelo seu ID único
  Future<Map<String, dynamic>?> getExpenseById(String expenseId) async {
    final db = await AppDatabase().database;
    final result = await db.query('expenses', where: 'id = ?', whereArgs: [expenseId]);
    return result.isNotEmpty ? result.first : null;
  }

  // busca todos os gastos ativos associados a uma viagem que não foram marcados como excluídos
  Future<List<Expense>> getExpensesByTrip(String tripId) async {
    final db = await AppDatabase().database;
    final List<Map<String, dynamic>> maps = await db.query(
      'expenses',
      where: 'trip_id = ? AND is_deleted = 0',
      whereArgs: [tripId],
    );
    return List.generate(maps.length, (i) => Expense.fromMap(maps[i]));
  }

  // atualiza as informações de um gasto e redefine o status de sincronização para pendente
  Future<int> updateExpense(Expense expense, {int isSynced = 0}) async {
    final db = await AppDatabase().database;
    return await db.update(
      'expenses',
      {...expense.toMap(), 'is_synced': isSynced},
      where: 'id = ?',
      whereArgs: [expense.id],
    );
  }

  // marca um gasto como excluído logicamente e sinaliza para sincronização de deleção no servidor
  Future<int> markAsDeleted(String id) async {
    final db = await AppDatabase().database;
    return await db.update('expenses', {'is_deleted': 1, 'is_synced': 0}, where: 'id = ?', whereArgs: [id]);
  }

  // atualiza o status de sincronização de um gasto
  Future<int> updateSyncStatus(String id, int isSynced) async {
    final db = await AppDatabase().database;
    return await db.update('expenses', {'is_synced': isSynced}, where: 'id = ?', whereArgs: [id]);
  }

  // exclui permanentemente o registro de um gasto do banco local
  Future<int> deleteExpenseHard(String id) async {
    final db = await AppDatabase().database;
    return await db.delete('expenses', where: 'id = ?', whereArgs: [id]);
  }

  // calcula a média ponderada do VET considerando apenas as transações de compra efetuadas até a data informada
  Future<double> getHistoricalVet(String userId, String currency, DateTime targetDate) async {
    final db = await AppDatabase().database;
    final cutoffDate = DateTime(targetDate.year, targetDate.month, targetDate.day, 23, 59, 59);
    
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
      
      if (txDate.isBefore(cutoffDate) || txDate.isAtSameMomentAs(cutoffDate)) {
        totalBought += (tx['amount'] as num?)?.toDouble() ?? 0.0;
        totalBrl += (tx['amount_brl'] as num?)?.toDouble() ?? 0.0;
      }
    }
    
    if (totalBought > 0) {
      return totalBrl / totalBought;
    }
    
    return 0.0;
  }
}
