import 'package:flutter/foundation.dart';
import '../models/expense.dart';
import '../repositories/expense_repository.dart';
import 'trip_provider.dart';
import 'wallet_provider.dart';

/// gerencia as operações de gastos na tela e coordena o recálculo automático de saldos e carteiras
class ExpenseProvider extends ChangeNotifier {
  final ExpenseRepository _expenseRepo = ExpenseRepository();
  bool _isLoading = false;

  bool get isLoading => _isLoading;

  /// insere ou atualiza um gasto localmente e atualiza os saldos das carteiras envolvidas na operação
  Future<void> saveAndRecalculate({
    required Expense expense,
    required bool isEdit,
    required String? oldCurrency,
    required String userId,
    required TripProvider tripProvider,
    required WalletProvider walletProvider,
  }) async {
    _isLoading = true;
    notifyListeners();

    if (isEdit) {
      await _expenseRepo.updateExpense(expense);
    } else {
      await _expenseRepo.insertExpense(expense);
    }

    await tripProvider.loadTrips(userId, fetchApi: false);
    
    await walletProvider.recalculateWallet(userId, expense.currency);
    await walletProvider.loadWalletData(userId, fetchApi: false);
    
    if (isEdit && oldCurrency != null && oldCurrency != expense.currency) {
      await walletProvider.recalculateWallet(userId, oldCurrency);
      await walletProvider.loadWalletData(userId, fetchApi: false);
    }

    _isLoading = false;
    notifyListeners();
  }

  /// remove logicamente um gasto do dispositivo e recarrega os saldos atualizados da carteira
  Future<void> deleteAndRecalculate({
    required Expense expense,
    required String userId,
    required TripProvider tripProvider,
    required WalletProvider walletProvider,
  }) async {
    _isLoading = true;
    notifyListeners();

    await _expenseRepo.deleteExpense(expense.id!);
    
    await tripProvider.loadTrips(userId, fetchApi: false);
    await walletProvider.recalculateWallet(userId, expense.currency);
    await walletProvider.loadWalletData(userId, fetchApi: false);

    _isLoading = false;
    notifyListeners();
  }
}
