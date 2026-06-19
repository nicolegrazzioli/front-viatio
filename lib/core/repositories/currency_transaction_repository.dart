import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../models/currency_transaction.dart';
import '../api/api_client.dart';
import '../dao/currency_transaction_dao.dart';

/// repositório que faz a mediação entre as chamadas da API de transações e a persistência no banco local SQLite
class CurrencyTransactionRepository {
  final CurrencyTransactionDAO _dao = CurrencyTransactionDAO();

  // formata um objeto DateTime para string no formato YYYY-MM-DD aceito pelo banco de dados do servidor
  String _toApiDate(DateTime date) {
    return "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
  }

  // faz o parse de uma string de data da API convertendo de volta para DateTime
  DateTime _fromApiDate(String date) {
    try {
      return DateTime.parse(date);
    } catch (e) {
      return DateTime.now();
    }
  }

  /// insere uma nova compra de moeda localmente e inicia a tentativa assíncrona de sincronização com a API
  Future<String> insertTransaction(CurrencyTransaction transaction) async {
    final txId = await _dao.insertTransaction(transaction, isSynced: 0);
    final newTx = CurrencyTransaction(
      id: txId,
      userId: transaction.userId,
      amount: transaction.amount,
      currency: transaction.currency,
      amountBrl: transaction.amountBrl,
      source: transaction.source,
      date: transaction.date,
      vetRate: transaction.vetRate,
      photoPath: transaction.photoPath,
    );
    _syncInsertTransaction(newTx);
    return txId;
  }

  // envia uma nova transação de compra para a API e atualiza o status de sincronização local ao obter sucesso
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
        'photoPath': transaction.photoPath,
      });
      if (transaction.id != null) {
        await _dao.updateSyncStatus(transaction.id!, 1);
      }
    } catch (e) {
      debugPrint("Offline: Transação salva apenas localmente. Erro API: $e");
    }
  }

  /// localiza e sincroniza com a API todas as transações que foram criadas, modificadas ou deletadas offline
  Future<void> syncUnsyncedTransactions() async {
    final unsynced = await _dao.getUnsyncedTransactions();
    for (var map in unsynced) {
      final id = map['id'] as String;
      if (map['is_deleted'] == 1) {
        await _syncDeleteTransaction(id);
      } else {
        final transaction = CurrencyTransaction.fromMap(map);
        await _syncInsertTransaction(transaction);
      }
    }
  }

  /// busca transações na API para atualizar o banco de dados local com tratamento offline e resolve deleções remotas
  Future<List<CurrencyTransaction>> getTransactionsByUser(String userId, {bool fetchApi = true}) async {
    if (fetchApi) {
      try {
        await syncUnsyncedTransactions(); // PUSH: Empurra as ações offline pendentes antes de puxar novidades
        
        final response = await ApiClient.get('/currency-transactions');
        if (response.statusCode == 200) {
          final List<dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));
          final List<String> apiIds = [];
          
          for (var e in data) {
            final txId = e['id'];
            apiIds.add(txId);
            
            final localData = await _dao.getTransactionById(txId);
            if (localData != null && localData['is_synced'] == 0) {
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
              photoPath: e['photoPath'],
            );
            
            if (localData != null) {
              await _dao.updateTransaction(tx, isSynced: 1);
            } else {
              await _dao.insertTransaction(tx, isSynced: 1);
            }
          }

          final localSynced = await _dao.getSyncedTransactions(userId);
          for (var local in localSynced) {
            if (!apiIds.contains(local['id'])) {
              await _dao.deleteTransactionHard(local['id'] as String);
            }
          }
        }
      } catch (e) {
        debugPrint("Offline: Buscando transações locais do SQLite. Erro API: $e");
      }
    }
    return await _dao.getTransactionsByUser(userId);
  }

  /// atualiza as informações da transação localmente e sincroniza o novo estado com o servidor
  Future<int> updateTransaction(CurrencyTransaction transaction) async {
    await _dao.updateTransaction(transaction, isSynced: 0);
    _syncInsertTransaction(transaction);
    return 1;
  }

  /// deleta logicamente a transação localmente e envia o pedido de exclusão física ao servidor
  Future<int> deleteTransaction(String id) async {
    await _dao.markAsDeleted(id);
    _syncDeleteTransaction(id);
    return 1;
  }

  // executa a exclusão de uma transação na API e limpa o registro de forma permanente no SQLite ao obter sucesso
  Future<void> _syncDeleteTransaction(String id) async {
    try {
      await ApiClient.delete('/currency-transactions/$id');
      await _dao.deleteTransactionHard(id);
    } catch (e) {
      debugPrint("Offline: Deleção de transação agendada. Erro API: $e");
    }
  }
}
