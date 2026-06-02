import '../repositories/trip_repository.dart';
import '../repositories/expense_repository.dart';
import '../repositories/currency_transaction_repository.dart';
import 'package:flutter/foundation.dart';

/// sincronização local-nuvem com controle de concorrência para evitar execuções redundantes simultâneas
class SyncEngine {
  static final SyncEngine _instance = SyncEngine._internal();
  factory SyncEngine() => _instance;
  SyncEngine._internal();

  final TripRepository _tripRepo = TripRepository();
  final ExpenseRepository _expenseRepo = ExpenseRepository();
  final CurrencyTransactionRepository _currencyTransactionRepo = CurrencyTransactionRepository();

  // sinaliza se um ciclo de sincronização em segundo plano já está em andamento
  bool _isSyncing = false;

  /// envio sequencial das tabelas pendentes de sincronização offline respeitando a integridade referencial
  Future<void> syncAllUnsynced() async {
    if (_isSyncing) return;
    _isSyncing = true;
    try {
      if (kDebugMode) {
        print("SyncEngine: Iniciando sincronização em background...");
      }
      
      await _tripRepo.syncUnsyncedTrips();
      await _expenseRepo.syncUnsyncedExpenses();
      await _currencyTransactionRepo.syncUnsyncedTransactions();
      
      if (kDebugMode) {
        print("SyncEngine: Sincronização concluída.");
      }
    } catch (e) {
      if (kDebugMode) {
        print("SyncEngine: Erro durante a sincronização: $e");
      }
    } finally {
      _isSyncing = false;
    }
  }
}
