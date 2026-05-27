import '../repositories/trip_repository.dart';
import '../repositories/expense_repository.dart';
import '../repositories/currency_transaction_repository.dart';

class SyncService {
  static Future<void> syncAllUnsynced() async {
    try {
      await TripRepository().syncUnsyncedTrips();
      await ExpenseRepository().syncUnsyncedExpenses();
      await CurrencyTransactionRepository().syncUnsyncedTransactions();
      print("Sincronização em background concluída.");
    } catch (e) {
      print("Falha na sincronização em background: $e");
    }
  }
}
