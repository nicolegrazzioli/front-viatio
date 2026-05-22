import 'package:flutter/material.dart';
import 'package:app_final/screens/login_screen.dart';
import 'package:app_final/screens/trip_details_screen.dart';
import 'package:app_final/screens/new_trip_screen.dart';
import '../core/models/user.dart';
import '../core/theme/app_colors.dart';
import '../widgets/custom_bottom_nav_bar.dart';
import '../widgets/search_filter_bar.dart';
import '../widgets/custom_fab.dart';
import 'balances_screen.dart';
import '../core/models/trip.dart';
import '../core/dao/trip_dao.dart';
import '../core/dao/userDAO.dart';
import '../core/dao/expense_dao.dart';
import '../core/dao/wallet_dao.dart';
import '../core/authentication/auth_service.dart';

// --- MOCK API E MODELOS ---
// Estes modelos representam as informações que virão do seu back-end em Java futuramente via JSON.

class Category {
  final String name;
  final IconData icon;
  final Color color;

  Category({required this.name, required this.icon, required this.color});
}

final List<Category> categories = [
  Category(
    name: 'Alimentação',
    icon: Icons.restaurant,
    color: const Color(0xFFFF7043),
  ),
  Category(
    name: 'Mercado',
    icon: Icons.shopping_basket,
    color: const Color(0xFF66BB6A),
  ),
  Category(
    name: 'Transporte',
    icon: Icons.directions_car,
    color: const Color(0xFF42A5F5),
  ),
  Category(
    name: 'Hospedagem',
    icon: Icons.hotel,
    color: const Color(0xFF7986CB),
  ),
  Category(
    name: 'Lazer',
    icon: Icons.confirmation_number,
    color: const Color(0xFFEC407A),
  ),
  Category(
    name: 'Compras',
    icon: Icons.local_mall,
    color: const Color(0xFF26C6DA),
  ),
  Category(
    name: 'Burocracia (visto, taxa, seguro)',
    icon: Icons.assignment,
    color: const Color(0xFF78909C),
  ),
  Category(
    name: 'Saúde (farmácia, consulta)',
    icon: Icons.local_hospital,
    color: const Color(0xFFFFCA28),
  ),
];

// (ApiService mock foi removido para usar os DAOs)

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  User? _currentUser;
  List<Trip>? _trips;
  Map<String, double> _tripAmounts = {};
  double _totalBalanceBrl = 0.0;
  bool _isLoading = true;
  
  String _searchQuery = '';
  String _sortOption = 'Recentes (Padrão)';

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

  List<Trip> get _filteredAndSortedTrips {
    if (_trips == null) return [];
    var list = _trips!.where((t) {
      final q = _searchQuery.toLowerCase();
      return t.title.toLowerCase().contains(q) ||
             t.startDate.contains(q) ||
             (t.endDate?.contains(q) ?? false);
    }).toList();
    
    list.sort((a, b) {
      if (_sortOption == 'Recentes (Padrão)') {
        final d1 = _parseDate(a.startDate);
        final d2 = _parseDate(b.startDate);
        final dateCompare = d2.compareTo(d1);
        if (dateCompare != 0) return dateCompare;
        return (b.id ?? '').compareTo(a.id ?? '');
      } else if (_sortOption == 'Antigos') {
        final d1 = _parseDate(a.startDate);
        final d2 = _parseDate(b.startDate);
        final dateCompare = d1.compareTo(d2);
        if (dateCompare != 0) return dateCompare;
        return (a.id ?? '').compareTo(b.id ?? '');
      } else if (_sortOption == 'Maior Gasto') {
        return (_tripAmounts[b.id!] ?? 0).compareTo(_tripAmounts[a.id!] ?? 0);
      } else if (_sortOption == 'Menor Gasto') {
        return (_tripAmounts[a.id!] ?? 0).compareTo(_tripAmounts[b.id!] ?? 0);
      }
      return 0;
    });
    return list;
  }

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData({bool fetchApi = true}) async {
    User? user = AuthService.currentUser;
    if (user == null) return;

    // Busca viagens do banco
    final dbTrips = await TripDAO().getTripsByUser(user!.id!, fetchApi: fetchApi);
    
    // Calcula o valor total (BRL) para cada viagem somando os gastos
    final expenseDAO = ExpenseDAO();
    Map<String, double> amounts = {};
    for (var trip in dbTrips) {
      final expenses = await expenseDAO.getExpensesByTrip(trip.id!);
      double total = 0.0;
      for (var exp in expenses) {
        total += exp.amountBrl;
      }
      amounts[trip.id!] = total;
    }

    // Calcula saldo total das carteiras
    double totalWalletBrl = 0.0;
    final wallets = await WalletDAO().getWalletsByUser(user!.id!);
    for (var w in wallets) {
      totalWalletBrl += w.balance * w.averageVet;
    }

    if (mounted) {
      print("Usuário logado: ${user?.name} (ID: ${user?.id})");
      print("Total de viagens buscadas: ${dbTrips.length}");
      setState(() {
        _currentUser = user;
        _trips = dbTrips;
        _tripAmounts = amounts;
        _totalBalanceBrl = totalWalletBrl;
        _isLoading = false;
      });
    }
  }

  void _showSortModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.cardBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        final options = ['Recentes (Padrão)', 'Antigos', 'Maior Gasto', 'Menor Gasto'];
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text("Ordenar viagens por", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.moneyGreen))
          : SafeArea(
              child: Column(
                children: [
                  // --- HEADER ---
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                    child: Column(
                      children: [
                        // Logo Viatio e Logout
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const SizedBox(width: 48), // Espaço para centralizar o título
                            const Text(
                              "Viatio",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Plus Jakarta Sans',
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.logout, color: Colors.red),
                              onPressed: () {
                                AuthService().logout();
                                Navigator.pushAndRemoveUntil(
                                  context,
                                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                                  (route) => false,
                                );
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 32),

                        // Saudação e Saldo
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              "Olá, ${_currentUser?.name.split(' ')[0] ?? 'Nicole'}",
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                const Text(
                                  "Saldo",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  "R\$ ${_totalBalanceBrl.toStringAsFixed(2).replaceAll('.', ',')}",
                                  style: const TextStyle(
                                    color: AppColors.moneyGreen,
                                    fontSize: 24,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Barra de Pesquisa e Filtros (Widget Compartilhado)
                        SearchFilterBar(
                          showFilter: false, // Ocultamos na Home conforme planejado
                          isSortActive: _sortOption != 'Recentes (Padrão)',
                          onSortTap: _showSortModal,
                          searchHint: "pesquisar viagem",
                          onSearchChanged: (value) {
                            setState(() {
                              _searchQuery = value;
                            });
                          },
                        ),
                      ],
                    ),
                  ),

                  // --- LISTA DE VIAGENS ---
                  Expanded(
                    child: _filteredAndSortedTrips.isEmpty
                        ? const Center(
                            child: Padding(
                              padding: EdgeInsets.symmetric(horizontal: 40.0),
                              child: Text(
                                "Nenhuma viagem encontrada.\nCrie uma nova clicando no botão +",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.white54, 
                                  fontSize: 18, 
                                  height: 1.5,
                                ),
                              ),
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            itemCount: _filteredAndSortedTrips.length,
                            itemBuilder: (context, index) {
                              final trip = _filteredAndSortedTrips[index];
                              return _buildTripCard(context, trip);
                            },
                          ),
                  ),
                ],
              ),
            ),
      floatingActionButton: CustomFAB(
        onPressed: () async {
          if (_currentUser == null) return;
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => NewTripScreen(userId: _currentUser!.id!),
            ),
          );
          _loadData(fetchApi: false); // Recarrega instantaneamente do banco local
        },
      ),
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: 0,
        onTap: (index) {
          if (index == 1) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const BalancesScreen()),
            );
          }
        },
      ),
    );
  }

  Widget _buildTripCard(BuildContext context, Trip trip) {
    // coverType pode ter uma URL http, assets/ ou ser vazio
    bool isNetwork = trip.coverType.startsWith('http');
    bool hasImage = trip.coverType.isNotEmpty;
    double tripAmount = _tripAmounts[trip.id!] ?? 0.0;
    
    return GestureDetector(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TripDetailsScreen(trip: trip),
          ),
        );
        _loadData(fetchApi: false); // Recarrega instantaneamente do banco local
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        height: 120,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          image: hasImage
              ? DecorationImage(
                  image: isNetwork 
                      ? NetworkImage(trip.coverType) as ImageProvider 
                      : AssetImage(trip.coverType),
                  fit: BoxFit.cover,
                  colorFilter: ColorFilter.mode(
                    Colors.black.withOpacity(0.4),
                    BlendMode.darken,
                  ),
                )
              : null,
          color: !hasImage ? const Color(0xFF1E293B) : null,
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              trip.title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  trip.endDate != null ? "${trip.startDate} - ${trip.endDate}" : trip.startDate,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                ),
                Text(
                  "R\$ ${tripAmount.toStringAsFixed(2)}",
                  style: const TextStyle(
                    color: AppColors.moneyGreen,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
