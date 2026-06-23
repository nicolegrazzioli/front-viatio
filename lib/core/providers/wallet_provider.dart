import 'package:flutter/foundation.dart';
import '../models/wallet.dart';
import '../models/currency_transaction.dart';
import '../repositories/wallet_repository.dart';
import '../repositories/currency_transaction_repository.dart';
import '../database/me_app_database.dart';
import '../constants/app_currencies.dart';

/// gerencia o estado financeiro da carteira de viagens do usuário em reais e moedas estrangeiras
class WalletProvider extends ChangeNotifier {
  // lista das carteiras virtuais
  List<Wallet>? _wallets;
  // histórico de compras de moeda
  List<CurrencyTransaction>? _transactions;
  // valor total estimado da carteira convertido em BRL
  double _totalBalanceBrl = 0.0;
  // sinalizador de carregamento
  bool _isLoading = false;

  List<Wallet>? get wallets => _wallets;
  List<CurrencyTransaction>? get transactions => _transactions;
  double get totalBalanceBrl => _totalBalanceBrl;
  bool get isLoading => _isLoading;

  /// busca as transações e as carteiras, garante que USD e EUR sempre existam na lista e calcula o valor total geral em BRL
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

  /// recalcula o saldo restante e o custo médio (VET) de uma moeda subtraindo os gastos das compras efetuadas
  Future<void> recalculateWallet(String userId, String currency) async {
    if (currency == AppCurrencies.brl) return;
    
    final db = await AppDatabase().database;
    final walletRepo = WalletRepository();
    
    // 1. soma das compras (CurrencyTransactions)
    final txs = await db.query('currency_transactions', 
        where: 'user_id = ? AND currency = ? AND is_deleted = 0', 
        whereArgs: [userId, currency]);
    
    double totalBought = 0.0;
    double totalBrl = 0.0;
    
    for (var tx in txs) {
      totalBought += (tx['amount'] as num?)?.toDouble() ?? 0.0;
      totalBrl += (tx['amount_brl'] as num?)?.toDouble() ?? 0.0;
    }

    // 2. soma dos gastos (todas as despesas na moeda)
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

    // 3. os gastos fixam o VET da data em que ocorreram 
  }

  /// insere uma nova compra de moeda, recalcula o saldo da carteira e atualiza o estado local
  Future<void> addTransaction(CurrencyTransaction transaction) async {
    await CurrencyTransactionRepository().insertTransaction(transaction);
    await recalculateWallet(transaction.userId, transaction.currency);
    await loadWalletData(transaction.userId, fetchApi: false);
  }

  /// edita uma transação de compra existente e recalcula as carteiras afetadas pela mudança
  Future<void> editTransaction(CurrencyTransaction newTx, CurrencyTransaction oldTx) async {
    await CurrencyTransactionRepository().updateTransaction(newTx);
    await recalculateWallet(newTx.userId, newTx.currency);
    if (newTx.currency != oldTx.currency) {
      await recalculateWallet(oldTx.userId, oldTx.currency);
    }
    await loadWalletData(newTx.userId, fetchApi: false);
  }

  /// remove logicamente uma compra de moeda e atualiza os saldos afetados
  Future<void> removeTransaction(CurrencyTransaction transaction) async {
    await CurrencyTransactionRepository().deleteTransaction(transaction.id!);
    await recalculateWallet(transaction.userId, transaction.currency);
    await loadWalletData(transaction.userId, fetchApi: false);
  }
}
