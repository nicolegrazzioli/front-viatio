import 'package:flutter/foundation.dart';
import '../repositories/trip_repository.dart';
import '../repositories/expense_repository.dart';
import '../repositories/currency_transaction_repository.dart';

/// Orquestrador de sincronização local-nuvem.
/// Responsável por disparar em lote os processos de upload das entidades pendentes de sincronização.
class SyncService {
  /// Executa o upload sequencial de todas as viagens, gastos e transações que foram modificados offline.
  static Future<void> syncAllUnsynced() async {
    try {
      // Sincroniza Viagens (Trips) pendentes
      await TripRepository().syncUnsyncedTrips();
      
      // Sincroniza Gastos (Expenses) pendentes
      await ExpenseRepository().syncUnsyncedExpenses();
      
      // Sincroniza Compras de Moedas (Currency Transactions) pendentes
      await CurrencyTransactionRepository().syncUnsyncedTransactions();
      
      debugPrint("Sincronização em background concluída.");
    } catch (e) {
      debugPrint("Falha na sincronização em background: $e");
    }
  }
}
