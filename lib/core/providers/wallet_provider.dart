import 'package:flutter/foundation.dart';
import '../models/wallet.dart';
import '../models/currency_transaction.dart';
import '../repositories/wallet_repository.dart';
import '../repositories/currency_transaction_repository.dart';
import '../repositories/expense_repository.dart';
import '../database/me_app_database.dart';
import '../constants/app_currencies.dart';

class WalletProvider extends ChangeNotifier {
  List<Wallet>? _wallets;
  List<CurrencyTransaction>? _transactions;
  double _totalBalanceBrl = 0.0;
  bool _isLoading = false;

  List<Wallet>? get wallets => _wallets;
  List<CurrencyTransaction>? get transactions => _transactions;
  double get totalBalanceBrl => _totalBalanceBrl;
  bool get isLoading => _isLoading;

  Future<void> loadWalletData(String userId, {bool fetchApi = true}) async {
    _isLoading = true;
    notifyListeners();

    final transactionsData = await CurrencyTransactionRepository().getTransactionsByUser(userId, fetchApi: fetchApi);
    
    if (fetchApi) {
      await WalletRepository().getWalletsByUser(userId, fetchApi: true);
    }
    
    final walletsData = await WalletRepository().getWalletsByUser(userId, fetchApi: false);
    
    bool hasEUR = false;
    bool hasUSD = false;
    
    for (var w in walletsData) {
       if (AppCurrencies.isEuro(w.currency)) hasEUR = true;
       if (AppCurrencies.isUsd(w.currency)) hasUSD = true;
    }
    
    if (!hasEUR) walletsData.insert(0, Wallet(userId: userId, currency: AppCurrencies.eur, balance: 0, averageVet: 0));
    if (!hasUSD) walletsData.insert(0, Wallet(userId: userId, currency: AppCurrencies.usd, balance: 0, averageVet: 0));
    
    double total = 0.0;
    for (var w in walletsData) {
      total += (w.balance * w.averageVet);
    }
    
    _wallets = walletsData;
    _transactions = transactionsData;
    _totalBalanceBrl = total;
    _isLoading = false;
    notifyListeners();
  }

  Future<void> recalculateWallet(String userId, String currency) async {
    if (currency == AppCurrencies.brl) return;
    
    final db = await AppDatabase().database;
    final walletRepo = WalletRepository();
    
    // 1. Soma das compras (CurrencyTransactions)
    final txs = await db.query('currency_transactions', 
        where: 'user_id = ? AND currency = ? AND is_deleted = 0', 
        whereArgs: [userId, currency]);
    
    double totalBought = 0.0;
    double totalBrl = 0.0;
    
    for (var tx in txs) {
      totalBought += (tx['amount'] as num?)?.toDouble() ?? 0.0;
      totalBrl += (tx['amount_brl'] as num?)?.toDouble() ?? 0.0;
    }

    // 2. Soma dos gastos (Todas as despesas na moeda)
    final expenseResult = await db.rawQuery('''
      SELECT SUM(e.amount) as spent 
      FROM expenses e
      JOIN trips t ON e.trip_id = t.id
      WHERE t.user_id = ? AND e.currency = ? AND e.is_deleted = 0 AND t.is_deleted = 0
    ''', [userId, currency]);
    
    double totalSpent = (expenseResult.first['spent'] as num?)?.toDouble() ?? 0.0;
    
    double remainingBalance = totalBought - totalSpent;
    
    double newVet = 0.0;
    if (totalBought > 0) {
      newVet = totalBrl / totalBought;
    }
    
    final currentWallet = await walletRepo.getWallet(userId, currency);
    double? oldVet = currentWallet?.averageVet;

    final newWallet = Wallet(
      userId: userId,
      currency: currency,
      balance: remainingBalance,
      averageVet: newVet,
    );
    
    if (currentWallet == null) {
      await walletRepo.insertWallet(newWallet);
    } else {
      await walletRepo.updateWallet(newWallet);
    }

    // 3. Atualização Dinâmica do VET nos Gastos
    if (oldVet != null && oldVet != newVet) {
      await ExpenseRepository().updateDynamicVetForTrips(userId, currency);
      // Dispara a sincronização em background para o backend receber a cascata
      await ExpenseRepository().syncUnsyncedExpenses();
    }
  }

  Future<void> addTransaction(CurrencyTransaction transaction) async {
    await CurrencyTransactionRepository().insertTransaction(transaction);
    await recalculateWallet(transaction.userId, transaction.currency);
    await loadWalletData(transaction.userId, fetchApi: false);
  }

  Future<void> editTransaction(CurrencyTransaction newTx, CurrencyTransaction oldTx) async {
    await CurrencyTransactionRepository().updateTransaction(newTx);
    await recalculateWallet(newTx.userId, newTx.currency);
    if (newTx.currency != oldTx.currency) {
      await recalculateWallet(oldTx.userId, oldTx.currency);
    }
    await loadWalletData(newTx.userId, fetchApi: false);
  }

  Future<void> removeTransaction(CurrencyTransaction transaction) async {
    await CurrencyTransactionRepository().deleteTransaction(transaction.id!);
    await recalculateWallet(transaction.userId, transaction.currency);
    await loadWalletData(transaction.userId, fetchApi: false);
  }
}
