import '../dao/trip_dao.dart';
import '../dao/expense_dao.dart';
import '../dao/currency_transaction_dao.dart';
import 'package:flutter/foundation.dart';

class SyncEngine {
  static final SyncEngine _instance = SyncEngine._internal();
  factory SyncEngine() => _instance;
  SyncEngine._internal();

  final TripDAO _tripDAO = TripDAO();
  final ExpenseDAO _expenseDAO = ExpenseDAO();
  final CurrencyTransactionDAO _currencyTransactionDAO = CurrencyTransactionDAO();

  bool _isSyncing = false;

  Future<void> syncAllUnsynced() async {
    if (_isSyncing) return;
    _isSyncing = true;
    try {
      if (kDebugMode) {
        print("SyncEngine: Iniciando sincronização em background...");
      }
      
      await _tripDAO.syncUnsyncedTrips();
      await _expenseDAO.syncUnsyncedExpenses();
      await _currencyTransactionDAO.syncUnsyncedTransactions();
      
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
