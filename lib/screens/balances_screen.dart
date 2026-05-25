import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme/app_colors.dart';
import '../widgets/custom_bottom_nav_bar.dart';
import '../widgets/custom_fab.dart';
import '../widgets/search_filter_bar.dart';
import 'home_screen.dart';
import 'new_currency_purchase_screen.dart';
import '../core/models/currency_transaction.dart';
import '../core/providers/auth_provider.dart';
import '../core/providers/wallet_provider.dart';

class BalancesScreen extends StatefulWidget {
  const BalancesScreen({super.key});

  @override
  State<BalancesScreen> createState() => _BalancesScreenState();
}

class _BalancesScreenState extends State<BalancesScreen> {
  final ScrollController _scrollController = ScrollController();

  String _searchQuery = '';
  String _sortOption = 'Recentes (Padrão)';
  String? _filterCurrency;
  String? _filterSource;

  DateTime _parseDate(String dateStr) {
    try {
      final parts = dateStr.split('/');
      if (parts.length == 3) {
        return DateTime(int.parse(parts[2]), int.parse(parts[1]), int.parse(parts[0]));
      }
    } catch (e) {
      // ignore
    }
    return DateTime.now();
  }

  List<CurrencyTransaction> _getFilteredAndSortedTransactions(List<CurrencyTransaction>? transactions) {
    if (transactions == null) return [];
    var list = transactions.where((t) {
      final q = _searchQuery.toLowerCase();
      final matchesQuery = t.currency.toLowerCase().contains(q) ||
                           t.source.toLowerCase().contains(q) ||
                           t.date.contains(q);
      
      final matchesCurrency = _filterCurrency == null || t.currency == _filterCurrency;
      final matchesSource = _filterSource == null || t.source == _filterSource;
      
      return matchesQuery && matchesCurrency && matchesSource;
    }).toList();
    
    list.sort((a, b) {
      if (_sortOption == 'Recentes (Padrão)') {
        final d1 = _parseDate(a.date);
        final d2 = _parseDate(b.date);
        final dateCompare = d2.compareTo(d1);
        if (dateCompare != 0) return dateCompare;
        return (b.id ?? '').compareTo(a.id ?? ''); 
      } else if (_sortOption == 'Antigos') {
        final d1 = _parseDate(a.date);
        final d2 = _parseDate(b.date);
        final dateCompare = d1.compareTo(d2);
        if (dateCompare != 0) return dateCompare;
        return (a.id ?? '').compareTo(b.id ?? '');
      } else if (_sortOption == 'Maior Valor') {
        return b.amountBrl.compareTo(a.amountBrl);
      } else if (_sortOption == 'Menor Valor') {
        return a.amountBrl.compareTo(b.amountBrl);
      }
      return 0;
    });
    return list;
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollCarousel(bool forward) {
    final double target = forward 
        ? _scrollController.offset + (MediaQuery.of(context).size.width * 0.45 + 16)
        : _scrollController.offset - (MediaQuery.of(context).size.width * 0.45 + 16);
    
    _scrollController.animateTo(
      target.clamp(0, _scrollController.position.maxScrollExtent),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _showSortModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.cardBackground,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        final options = ['Recentes (Padrão)', 'Antigos', 'Maior Valor', 'Menor Valor'];
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text("Ordenar compras por", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              ),
              ...options.map((option) => ListTile(
                title: Text(option, style: const TextStyle(color: Colors.white)),
                trailing: _sortOption == option ? const Icon(Icons.check, color: AppColors.moneyGreen) : null,
                onTap: () {
                  setState(() => _sortOption = option);
                  Navigator.pop(context);
                },
              )),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  void _showFilterModal(List<String> currencies, List<String> sources) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.cardBackground,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return SafeArea(
          child: DefaultTabController(
            length: 2,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const TabBar(
                  tabs: [
                    Tab(text: "Moeda"),
                    Tab(text: "Origem"),
                  ],
                  labelColor: AppColors.moneyGreen,
                  unselectedLabelColor: Colors.white,
                  indicatorColor: AppColors.moneyGreen,
                ),
                SizedBox(
                  height: 300,
                  child: TabBarView(
                    children: [
                      // Moeda
                      ListView(
                        children: [
                          ListTile(
                            title: const Text("Todas as moedas", style: TextStyle(color: Colors.white)),
                            trailing: _filterCurrency == null ? const Icon(Icons.check, color: AppColors.moneyGreen) : null,
                            onTap: () {
                              setState(() => _filterCurrency = null);
                              Navigator.pop(context);
                            },
                          ),
                          ...currencies.map((c) => ListTile(
                            title: Text(c, style: const TextStyle(color: Colors.white)),
                            trailing: _filterCurrency == c ? const Icon(Icons.check, color: AppColors.moneyGreen) : null,
                            onTap: () {
                              setState(() => _filterCurrency = c);
                              Navigator.pop(context);
                            },
                          )),
                        ],
                      ),
                      // Origem
                      ListView(
                        children: [
                          ListTile(
                            title: const Text("Todas as origens", style: TextStyle(color: Colors.white)),
                            trailing: _filterSource == null ? const Icon(Icons.check, color: AppColors.moneyGreen) : null,
                            onTap: () {
                              setState(() => _filterSource = null);
                              Navigator.pop(context);
                            },
                          ),
                          ...sources.map((s) => ListTile(
                            title: Text(s, style: const TextStyle(color: Colors.white)),
                            trailing: _filterSource == s ? const Icon(Icons.check, color: AppColors.moneyGreen) : null,
                            onTap: () {
                              setState(() => _filterSource = s);
                              Navigator.pop(context);
                            },
                          )),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Color _getCurrencyColor(String currency) {
    if (currency == 'Euro' || currency == 'EUR') return const Color(0xFFFFD700); // Gold
    if (currency == 'Dólar' || currency == 'USD') return AppColors.dollarColor;
    
    // Gera uma cor consistente baseada no nome da moeda
    int hash = 0;
    for (int i = 0; i < currency.length; i++) {
      hash = currency.codeUnitAt(i) + ((hash << 5) - hash);
    }
    final double hue = (hash % 360).abs().toDouble();
    return HSVColor.fromAHSV(1.0, hue, 0.6, 0.9).toColor();
  }

  String _getCurrencyCode(String currency) {
    if (currency == 'Euro' || currency == 'EUR') return 'EUR';
    if (currency == 'Dólar' || currency == 'USD') return 'USD';
    if (currency == 'Libra' || currency == 'GBP') return 'GBP';
    return currency.toUpperCase().substring(0, currency.length >= 3 ? 3 : currency.length);
  }

  String _getCurrencySymbol(String currency) {
    if (currency == 'Euro' || currency == 'EUR') return '€';
    if (currency == 'Dólar' || currency == 'USD') return 'US\$';
    if (currency == 'Libra' || currency == 'GBP') return '£';
    return _getCurrencyCode(currency);
  }

  Widget _buildCurrencyCard(String code, String balance, String convertedValue, String vet, Color cardColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cardColor.withOpacity(0.5), width: 1),
        boxShadow: [
          BoxShadow(color: cardColor.withOpacity(0.15), blurRadius: 8, spreadRadius: -2, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(code, style: const TextStyle(color: AppColors.offWhite, fontSize: 18, fontWeight: FontWeight.bold)),
          const Spacer(),
          Text(balance, style: const TextStyle(color: AppColors.offWhite, fontSize: 26, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(convertedValue, style: const TextStyle(color: AppColors.offWhite, fontSize: 18)),
          Text("VET: $vet", style: const TextStyle(color: AppColors.offWhite, fontSize: 16)),
        ],
      ),
    );
  }

  Widget _buildPurchaseItem(BuildContext context, CurrencyTransaction transaction, Color color) {
    return Dismissible(
      key: ValueKey(transaction.id ?? transaction.date),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: Colors.red,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      confirmDismiss: (direction) async {
        return await showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: AppColors.cardBackground,
            title: const Text("Excluir Compra", style: TextStyle(color: Colors.white)),
            content: const Text("Tem certeza que deseja excluir esta compra de moeda?", style: TextStyle(color: Colors.white70)),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Cancelar", style: TextStyle(color: Colors.white))),
              TextButton(
                onPressed: () async {
                  await context.read<WalletProvider>().removeTransaction(transaction);
                  if (mounted) {
                    Navigator.pop(ctx, true);
                  }
                }, 
                child: const Text("Excluir", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold))
              ),
            ],
          ),
        );
      },
      child: InkWell(
        onTap: () {
          final user = context.read<AuthProvider>().currentUser;
          if (user == null) return;
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => NewCurrencyPurchaseScreen(
                  userId: user.id!,
                  transaction: transaction,
                ),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12.0),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.silverBorder, width: 1),
                  ),
                  child: Icon(Icons.currency_exchange, color: color),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(transaction.currency, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w500)),
                      const SizedBox(height: 4),
                      Text(transaction.source, style: const TextStyle(color: Colors.white70, fontSize: 14)),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text("${_getCurrencySymbol(transaction.currency)} ${transaction.amount.toStringAsFixed(2)}", style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 4),
                    Text("R\$ ${transaction.amountBrl.toStringAsFixed(2)}", style: const TextStyle(color: AppColors.offWhite, fontSize: 14)),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final walletProvider = context.watch<WalletProvider>();

    final user = authProvider.currentUser;
    final wallets = walletProvider.wallets;
    final transactions = walletProvider.transactions;
    final sortedTransactions = _getFilteredAndSortedTransactions(transactions);

    if (walletProvider.isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.darkBackground,
        body: Center(child: CircularProgressIndicator(color: AppColors.moneyGreen)),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text(
          "Saldos",
          style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.normal),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 16),
            Text(
              "R\$ ${walletProvider.totalBalanceBrl.toStringAsFixed(2)}", // Soma de todas as moedas convertidas pelo VET
              style: const TextStyle(
                color: AppColors.moneyGreen,
                fontSize: 30,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            
            // Carrossel de Moedas Infinito
            if (wallets == null || wallets.isEmpty)
              const SizedBox(
                height: 160,
                child: Center(
                  child: Text(
                    "Nenhum saldo registrado.\nCompre moedas clicando no +",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white54, fontSize: 16),
                  ),
                ),
              )
            else if (wallets.length == 1)
              SizedBox(
                height: 160,
                child: Center(
                  child: SizedBox(
                    width: MediaQuery.of(context).size.width * 0.8, // Largura mais centralizada para 1 item
                    child: _buildCurrencyCard(
                      _getCurrencyCode(wallets[0].currency), 
                      wallets[0].balance.toStringAsFixed(2), 
                      "R\$ ${(wallets[0].balance * wallets[0].averageVet).toStringAsFixed(2)}", 
                      "R\$ ${wallets[0].averageVet.toStringAsFixed(2)}", 
                      _getCurrencyColor(wallets[0].currency),
                    ),
                  ),
                ),
              )
            else
              SizedBox(
                height: 160,
                child: Stack(
                  children: [
                    ListView.builder(
                      controller: _scrollController,
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      itemCount: wallets.length,
                      itemBuilder: (context, index) {
                        final wallet = wallets[index];
                        final color = _getCurrencyColor(wallet.currency);
                        final converted = wallet.balance * wallet.averageVet;
                        return Container(
                          width: MediaQuery.of(context).size.width * 0.45, // Ocupa metade da tela para ter 2 cards
                          margin: const EdgeInsets.symmetric(horizontal: 8.0),
                          child: _buildCurrencyCard(
                            _getCurrencyCode(wallet.currency), 
                            wallet.balance.toStringAsFixed(2), 
                            "R\$ ${converted.toStringAsFixed(2)}", 
                            "R\$ ${wallet.averageVet.toStringAsFixed(2)}", 
                            color,
                          ),
                        );
                      },
                    ),
                    if (wallets.length > 2) ...[
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.only(left: 4),
                          decoration: BoxDecoration(color: Colors.black26, shape: BoxShape.circle),
                          child: IconButton(
                            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
                            onPressed: () => _scrollCarousel(false),
                          ),
                        ),
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Container(
                          margin: const EdgeInsets.only(right: 4),
                          decoration: BoxDecoration(color: Colors.black26, shape: BoxShape.circle),
                          child: IconButton(
                            icon: const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 20),
                            onPressed: () => _scrollCarousel(true),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            
            const SizedBox(height: 32),
            
            // Barra de Busca e Filtros
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: SearchFilterBar(
                isFilterActive: _filterCurrency != null || _filterSource != null,
                isSortActive: _sortOption != 'Recentes (Padrão)',
                onFilterTap: () {
                  final currencies = wallets?.map((w) => w.currency).toList() ?? [];
                  final sources = transactions?.map((t) => t.source).toSet().toList() ?? [];
                  _showFilterModal(currencies, sources);
                },
                onSortTap: _showSortModal,
                onSearchChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Lista de Compras de Moeda
            Expanded(
              child: sortedTransactions.isEmpty
                ? const Center(child: Text("Nenhuma compra encontrada.", style: TextStyle(color: Colors.white54)))
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    itemCount: sortedTransactions.length,
                    itemBuilder: (context, index) {
                      final transaction = sortedTransactions[index];
                      final color = _getCurrencyColor(transaction.currency);
                      
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (index == 0 || sortedTransactions[index].date != sortedTransactions[index-1].date)
                            Padding(
                              padding: const EdgeInsets.only(top: 24, bottom: 8),
                              child: Text(
                                transaction.date,
                                style: const TextStyle(color: Colors.white, fontSize: 16),
                              ),
                            ),
                          _buildPurchaseItem(context, transaction, color),
                          const Divider(color: AppColors.silverBorder, height: 1),
                          if (index == sortedTransactions.length - 1)
                            const SizedBox(height: 80),
                        ],
                      );
                    },
                  ),
            ),
          ],
        ),
      ),
      
      floatingActionButton: CustomFAB(
        onPressed: () {
          if (user == null) return;
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => NewCurrencyPurchaseScreen(userId: user.id!),
            ),
          );
        },
      ),
      
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: 1, // 1 é o índice de "Saldos"
        onTap: (index) {
          if (index == 0) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const HomeScreen()),
            );
          }
        },
      ),
    );
  }
}
