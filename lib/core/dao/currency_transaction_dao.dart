import 'package:uuid/uuid.dart';
import '../models/currency_transaction.dart';
import '../database/me_app_database.dart';
import 'package:sqflite/sqflite.dart';

/// classe de acesso aos dados que executa queries SQL para as transações de compra de moeda estrangeira no SQLite
class CurrencyTransactionDAO {
  final _uuid = const Uuid();

  // insere ou substitui uma transação de compra de moeda no banco de dados local gerando um UUID se necessário
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

  // retorna todas as transações que ainda não foram sincronizadas com a nuvem
  Future<List<Map<String, dynamic>>> getUnsyncedTransactions() async {
    final db = await AppDatabase().database;
    return await db.query('currency_transactions', where: 'is_synced = ?', whereArgs: [0]);
  }

  // retorna todas as transações de um usuário específico que já foram sincronizadas
  Future<List<Map<String, dynamic>>> getSyncedTransactions(String userId) async {
    final db = await AppDatabase().database;
    return await db.query('currency_transactions', where: 'user_id = ? AND is_synced = ?', whereArgs: [userId, 1]);
  }

  // busca uma transação específica no banco local através do ID correspondente
  Future<Map<String, dynamic>?> getTransactionById(String txId) async {
    final db = await AppDatabase().database;
    final result = await db.query('currency_transactions', where: 'id = ?', whereArgs: [txId]);
    return result.isNotEmpty ? result.first : null;
  }

  // recupera a lista de todas as transações ativas de um usuário que não foram marcadas como deletadas
  Future<List<CurrencyTransaction>> getTransactionsByUser(String userId) async {
    final db = await AppDatabase().database;
    final List<Map<String, dynamic>> maps = await db.query(
      'currency_transactions',
      where: 'user_id = ? AND is_deleted = 0',
      whereArgs: [userId],
    );
    return List.generate(maps.length, (i) => CurrencyTransaction.fromMap(maps[i]));
  }

  // atualiza os dados de uma transação de moeda localmente e redefine o status de sincronização para pendente
  Future<int> updateTransaction(CurrencyTransaction transaction, {int isSynced = 0}) async {
    final db = await AppDatabase().database;
    return await db.update(
      'currency_transactions',
      {...transaction.toMap(), 'is_synced': isSynced},
      where: 'id = ?',
      whereArgs: [transaction.id],
    );
  }

  // marca logicamente uma transação como deletada e define is_synced como zero para sincronizar a exclusão com o servidor
  Future<int> markAsDeleted(String id) async {
    final db = await AppDatabase().database;
    return await db.update('currency_transactions', {'is_deleted': 1, 'is_synced': 0}, where: 'id = ?', whereArgs: [id]);
  }

  // atualiza apenas o status de sincronização de uma transação pelo ID
  Future<int> updateSyncStatus(String id, int isSynced) async {
    final db = await AppDatabase().database;
    return await db.update('currency_transactions', {'is_synced': isSynced}, where: 'id = ?', whereArgs: [id]);
  }

  // exclui permanentemente (hard delete) o registro de uma transação do banco local
  Future<int> deleteTransactionHard(String id) async {
    final db = await AppDatabase().database;
    return await db.delete('currency_transactions', where: 'id = ?', whereArgs: [id]);
  }
}
