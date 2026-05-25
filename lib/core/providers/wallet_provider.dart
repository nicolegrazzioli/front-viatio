import 'package:flutter/foundation.dart';
import '../models/wallet.dart';
import '../models/currency_transaction.dart';
import '../dao/wallet_dao.dart';
import '../dao/currency_transaction_dao.dart';

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

    final walletsData = await WalletDAO().getWalletsByUser(userId);
    final transactionsData = await CurrencyTransactionDAO().getTransactionsByUser(userId, fetchApi: fetchApi);
    
    bool hasEUR = false;
    bool hasUSD = false;
    
    for (var w in walletsData) {
       if (w.currency == 'EUR' || w.currency == 'Euro') hasEUR = true;
       if (w.currency == 'USD' || w.currency == 'Dólar') hasUSD = true;
    }
    
    if (!hasEUR) walletsData.insert(0, Wallet(userId: userId, currency: 'EUR', balance: 0, averageVet: 0));
    if (!hasUSD) walletsData.insert(0, Wallet(userId: userId, currency: 'USD', balance: 0, averageVet: 0));
    
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

  Future<void> addTransaction(CurrencyTransaction transaction) async {
    await CurrencyTransactionDAO().insertTransaction(transaction);
    
    // Atualiza o wallet localmente
    final walletDao = WalletDAO();
    final wallet = await walletDao.getWallet(transaction.userId, transaction.currency);
    
    if (wallet == null) {
      // Cria a carteira caso não exista
      final newVet = transaction.amountBrl / transaction.amount;
      await walletDao.insertWallet(Wallet(
        userId: transaction.userId,
        currency: transaction.currency,
        balance: transaction.amount,
        averageVet: newVet,
      ));
    } else {
      // Atualiza o saldo e recalcula VET
      double totalBrlAntigo = wallet.balance * wallet.averageVet;
      double novoTotalBrl = totalBrlAntigo + transaction.amountBrl;
      double newBalance = wallet.balance + transaction.amount;
      double newVet = novoTotalBrl / newBalance;

      await walletDao.updateWallet(Wallet(
        userId: transaction.userId,
        currency: transaction.currency,
        balance: newBalance,
        averageVet: newVet,
      ));
    }

    await loadWalletData(transaction.userId, fetchApi: false);
  }

  Future<void> removeTransaction(CurrencyTransaction transaction) async {
    await CurrencyTransactionDAO().deleteTransaction(transaction.id!);
    
    final walletDao = WalletDAO();
    final wallet = await walletDao.getWallet(transaction.userId, transaction.currency);
    if (wallet != null) {
      final newBalance = wallet.balance - transaction.amount;
      if (newBalance <= 0) {
        await walletDao.deleteWallet(transaction.userId, transaction.currency);
      } else {
        // Recalcula o VET real
        double totalBrlAntigo = wallet.balance * wallet.averageVet;
        double novoTotalBrl = totalBrlAntigo - transaction.amountBrl;
        double newVet = novoTotalBrl / newBalance;

        await walletDao.updateWallet(Wallet(
          userId: transaction.userId,
          currency: transaction.currency,
          balance: newBalance,
          averageVet: newVet,
        ));
      }
    }

    await loadWalletData(transaction.userId, fetchApi: false);
  }
}
