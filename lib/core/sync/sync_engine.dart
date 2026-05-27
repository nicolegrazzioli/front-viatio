import '../repositories/trip_repository.dart';
import '../repositories/expense_repository.dart';
import '../repositories/currency_transaction_repository.dart';
import 'package:flutter/foundation.dart';

class SyncEngine {
  static final SyncEngine _instance = SyncEngine._internal();
  factory SyncEngine() => _instance;
  SyncEngine._internal();

  final TripRepository _tripRepo = TripRepository();
  final ExpenseRepository _expenseRepo = ExpenseRepository();
  final CurrencyTransactionRepository _currencyTransactionRepo = CurrencyTransactionRepository();

  bool _isSyncing = false;

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
