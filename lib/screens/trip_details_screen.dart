import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:app_final/screens/home_screen.dart';
import '../core/theme/app_colors.dart';
import '../widgets/custom_bottom_nav_bar.dart';
import '../widgets/search_filter_bar.dart';
import '../widgets/custom_fab.dart';
import 'new_trip_screen.dart';
import 'new_expense_screen.dart';
import 'balances_screen.dart';
import '../core/models/trip.dart';
import '../core/models/expense.dart';
import '../core/dao/expense_dao.dart';
import 'package:provider/provider.dart';
import '../core/providers/trip_provider.dart';
import '../core/providers/auth_provider.dart';

class TripDetailsScreen extends StatefulWidget {
  final Trip trip;

  const TripDetailsScreen({super.key, required this.trip});

  @override
  State<TripDetailsScreen> createState() => _TripDetailsScreenState();
}

class _TripDetailsScreenState extends State<TripDetailsScreen> {
  List<Expense>? _expenses;
  double _totalAmount = 0.0;
  Map<String, double> _categoryTotals = {};

  String _searchQuery = '';
  String _sortOption = 'Recentes (Padrão)';
  String? _filterCategory;

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

  List<Expense> get _filteredAndSortedExpenses {
    if (_expenses == null) return [];
    var list = _expenses!.where((e) {
      final q = _searchQuery.toLowerCase();
      final matchesQuery = e.title.toLowerCase().contains(q) ||
                           e.date.contains(q) ||
                           e.category.toLowerCase().contains(q) ||
                           e.amount.toString().contains(q) ||
                           e.amountBrl.toString().contains(q);
      
      final matchesFilter = _filterCategory == null || e.category == _filterCategory;
      return matchesQuery && matchesFilter;
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
  void initState() {
    super.initState();
    _loadExpenses();
  }

  Future<void> _loadExpenses({bool fetchApi = true}) async {
    if (widget.trip.id == null) return;
    final expenses = await ExpenseDAO().getExpensesByTrip(widget.trip.id!, fetchApi: fetchApi);
    
    double total = 0.0;
    Map<String, double> catTotals = {};
    
    for (var exp in expenses) {
      total += exp.amountBrl;
      catTotals[exp.category] = (catTotals[exp.category] ?? 0.0) + exp.amountBrl;
    }
    
    if (mounted) {
      setState(() {
        _expenses = expenses;
        _totalAmount = total;
        _categoryTotals = catTotals;
      });
    }
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
                child: Text("Ordenar gastos por", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
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

  void _showFilterModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.cardBackground,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        final options = [null, ...categories.map((c) => c.name)];
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text("Filtrar por Categoria", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              ),
              Expanded(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: options.length,
                  itemBuilder: (context, index) {
                    final option = options[index];
                    final title = option ?? "Todas as categorias";
                    return ListTile(
                      title: Text(title, style: const TextStyle(color: Colors.white)),
                      trailing: _filterCategory == option ? const Icon(Icons.check, color: AppColors.moneyGreen) : null,
                      onTap: () {
                        setState(() => _filterCategory = option);
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.trip.title,
          style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.normal),
        ),
        centerTitle: true,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            color: AppColors.darkBackground,
            onSelected: (value) {
              if (value == 'edit') {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => NewTripScreen(trip: widget.trip),
                  ),
                ).then((_) => _loadExpenses(fetchApi: false));
              } else if (value == 'delete') {
                _showDeleteDialog(context);
              }
            },
            itemBuilder: (BuildContext context) => [
              const PopupMenuItem<String>(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(Icons.edit, color: Colors.white, size: 20),
                    SizedBox(width: 8),
                    Text('Editar Viagem', style: TextStyle(color: Colors.white)),
                  ],
                ),
              ),
              const PopupMenuItem<String>(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete, color: Colors.red, size: 20),
                    SizedBox(width: 8),
                    Text('Excluir Viagem', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 16),
            // Valor Total Dinâmico
            Text(
              "R\$ ${_totalAmount.toStringAsFixed(2)}",
              style: const TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: AppColors.moneyGreen,
              ),
            ),
            const SizedBox(height: 40),
            
            // Gráfico de Pizza Dinâmico
            if (_totalAmount > 0)
              SizedBox(
                height: 180,
                child: PieChart(
                  PieChartData(
                    sectionsSpace: 4,
                    centerSpaceRadius: 0,
                    sections: _categoryTotals.entries.map((entry) {
                      // Find category color from the mocked categories list in home_screen
                      final cat = categories.firstWhere(
                        (c) => c.name == entry.key, 
                        orElse: () => categories[0]
                      );
                      return PieChartSectionData(
                        color: cat.color,
                        value: entry.value,
                        title: '',
                        radius: 90,
                      );
                    }).toList(),
                  ),
                ),
              )
            else
              const SizedBox(height: 180, child: Center(child: Text("Nenhum gasto registrado", style: TextStyle(color: Colors.white54)))),
            const SizedBox(height: 40),
            
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: SearchFilterBar(
                onFilterTap: _showFilterModal,
                onSortTap: _showSortModal,
                isFilterActive: _filterCategory != null,
                isSortActive: _sortOption != 'Recentes (Padrão)',
                searchHint: "pesquisar",
                onSearchChanged: (val) {
                  setState(() {
                    _searchQuery = val;
                  });
                },
              ),
            ),
            const SizedBox(height: 16),
            
            Expanded(
              child: _filteredAndSortedExpenses.isEmpty
                  ? const Center(child: Text("Nenhum gasto encontrado.", style: TextStyle(color: Colors.white54, fontSize: 16)))
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      itemCount: _filteredAndSortedExpenses.length,
                      itemBuilder: (context, index) {
                        final expense = _filteredAndSortedExpenses[index];
                        final cat = categories.firstWhere((c) => c.name == expense.category, orElse: () => categories[0]);
                        final currencySymbol = expense.currency == 'Euro' ? '€' : (expense.currency == 'Dólar' ? '\$' : 'R\$');
                        
                        return Column(
                          children: [
                            if (index == 0 || _filteredAndSortedExpenses[index].date != _filteredAndSortedExpenses[index-1].date)
                              Padding(
                                padding: const EdgeInsets.only(top: 16, bottom: 8),
                                child: Align(
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    expense.date,
                                    style: const TextStyle(color: Colors.white, fontSize: 16),
                                  ),
                                ),
                              ),
                            _buildExpenseItem(expense, cat, "$currencySymbol ${expense.amount.toStringAsFixed(2)}", "R\$ ${expense.amountBrl.toStringAsFixed(2)}"),
                            const Divider(color: AppColors.silverBorder, height: 1),
                            if (index == _filteredAndSortedExpenses.length - 1)
                              const SizedBox(height: 80), // Padding extra no final
                          ],
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      
      floatingActionButton: CustomFAB(
        rightPadding: 32.0,
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => NewExpenseScreen(tripId: widget.trip.id!, tripTitle: widget.trip.title)),
          );
          _loadExpenses(fetchApi: false); // Atualiza a lista e totais
        },
      ),
      
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: 0,
        onTap: (index) {
          if (index == 0) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const HomeScreen()),
            );
          } else if (index == 1) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const BalancesScreen()),
            );
          }
        },
      ),
    );
  }

  Widget _buildExpenseItem(Expense expense, Category category, String originalAmount, String convertedAmount) {
    return Dismissible(
      key: ValueKey(expense.id ?? expense.title), 
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
            title: const Text("Excluir Gasto", style: TextStyle(color: Colors.white)),
            content: const Text("Tem certeza que deseja excluir este gasto?", style: TextStyle(color: Colors.white70)),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Cancelar", style: TextStyle(color: Colors.white))),
              TextButton(
                onPressed: () async {
                  await ExpenseDAO().deleteExpense(expense.id!);
                  final user = context.read<AuthProvider>().currentUser;
                  if (user != null) {
                    await context.read<TripProvider>().loadTrips(user.id!, fetchApi: false);
                  }
                  if (mounted) {
                    Navigator.pop(ctx, true);
                    _loadExpenses(fetchApi: false);
                  }
                }, 
                child: const Text("Excluir", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold))
              ),
            ],
          ),
        );
      },
      child: InkWell(
        onTap: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => NewExpenseScreen(
                tripId: widget.trip.id!,
                tripTitle: widget.trip.title,
                expense: expense,
              ),
            ),
          ).then((_) => _loadExpenses(fetchApi: false));
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12.0),
          child: Row(
            children: [
              // Ícone
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.silverBorder, width: 1),
                ),
                child: Icon(category.icon, color: category.color),
              ),
              const SizedBox(width: 16),
              // Textos
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(expense.title, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 4),
                    Text(category.name, style: const TextStyle(color: Colors.white70, fontSize: 14)),
                  ],
                ),
              ),
              // Valores
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(originalAmount, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 4),
                  Text(convertedAmount, style: const TextStyle(color: Colors.white70, fontSize: 14)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDeleteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext ctx) {
        return AlertDialog(
          backgroundColor: AppColors.cardBackground,
          title: const Text("Excluir Viagem", style: TextStyle(color: Colors.white)),
          content: const Text(
            "Tem certeza que deseja excluir esta viagem? Todos os gastos serão perdidos.",
            style: TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("Cancelar", style: TextStyle(color: Colors.white)),
            ),
            TextButton(
              onPressed: () async {
                final user = context.read<AuthProvider>().currentUser;
                if (user != null) {
                  await context.read<TripProvider>().removeTrip(widget.trip.id!, user.id!);
                }
                if (mounted) {
                  Navigator.pop(ctx); // Fechar dialog
                  Navigator.pop(context); // Voltar para a home
                }
              },
              child: const Text("Excluir", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }
}

