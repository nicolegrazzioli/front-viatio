import '../dao/trip_dao.dart';
import '../dao/expense_dao.dart';
import '../dao/currency_transaction_dao.dart';

class SyncService {
  static Future<void> syncAllUnsynced() async {
    try {
      await TripDAO().syncUnsyncedTrips();
      await ExpenseDAO().syncUnsyncedExpenses();
      await CurrencyTransactionDAO().syncUnsyncedTransactions();
      print("Sincronização em background concluída.");
    } catch (e) {
      print("Falha na sincronização em background: $e");
    }
  }
}
