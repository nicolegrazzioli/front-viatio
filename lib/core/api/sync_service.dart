import 'package:flutter/foundation.dart';
import '../repositories/trip_repository.dart';
import '../repositories/expense_repository.dart';
import '../repositories/currency_transaction_repository.dart';

/// orquestrador de sincronização local-nuvem
/// responsável por disparar em lote os processos de upload das entidades pendentes de sincronização
class SyncService {
  /// executa o upload sequencial de todas as viagens, gastos e transações que foram modificados offline
  static Future<void> syncAllUnsynced() async {
    try {
      // sincroniza viagens (trips) pendentes
      await TripRepository().syncUnsyncedTrips();
      
      // sincroniza gastos (expenses) pendentes
      await ExpenseRepository().syncUnsyncedExpenses();
      
      // sincroniza compras de moedas (currency transactions) pendentes
      await CurrencyTransactionRepository().syncUnsyncedTransactions();
      
      debugPrint("Sincronização em background concluída.");
    } catch (e) {
      debugPrint("Falha na sincronização em background: $e");
    }
  }
}
