import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:app_final/screens/login_screen.dart';
import 'package:app_final/screens/trip_details_screen.dart';
import 'package:app_final/screens/new_trip_screen.dart';
import '../core/theme/app_colors.dart';
import '../widgets/custom_bottom_nav_bar.dart';
import '../widgets/search_filter_bar.dart';
import '../widgets/custom_fab.dart';
import 'balances_screen.dart';
import '../core/models/trip.dart';
import '../core/providers/auth_provider.dart';
import '../core/providers/trip_provider.dart';
import '../core/providers/wallet_provider.dart';
import '../core/constants/app_categories.dart';
import '../core/utils/numeric_helpers.dart';
import '../core/utils/date_helpers.dart';

// modelos de informações que virão do backvia JSON

class Category {
  final String name;
  final IconData icon;
  final Color color;

  Category({required this.name, required this.icon, required this.color});
}

final List<Category> categories = [
  Category(
    name: AppCategories.food,
    icon: Icons.restaurant,
    color: const Color(0xFFFF7043),
  ),
  Category(
    name: AppCategories.market,
    icon: Icons.shopping_basket,
    color: const Color(0xFF66BB6A),
  ),
  Category(
    name: AppCategories.transport,
    icon: Icons.directions_car,
    color: const Color(0xFF42A5F5),
  ),
  Category(
    name: AppCategories.lodging,
    icon: Icons.hotel,
    color: const Color(0xFF7986CB),
  ),
  Category(
    name: AppCategories.leisure,
    icon: Icons.confirmation_number,
    color: const Color(0xFFEC407A),
  ),
  Category(
    name: AppCategories.shopping,
    icon: Icons.local_mall,
    color: const Color(0xFF26C6DA),
  ),
  Category(
    name: AppCategories.bureaucracy,
    icon: Icons.assignment,
    color: const Color(0xFF78909C),
  ),
  Category(
    name: AppCategories.health,
    icon: Icons.local_hospital,
    color: const Color(0xFFFFCA28),
  ),
];

/// tela principal do aplicativo que exibe a listagem de viagens cadastradas e o saldo total consolidado do usuário
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

/// gerencia o estado das buscas, ordenação e carregamento assíncrono das viagens e saldos na inicialização da home
class _HomeScreenState extends State<HomeScreen> {
  final ScrollController _scrollController = ScrollController();
  String _searchQuery = '';
  String _sortOption = 'Recentes (Padrão)';

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = context.read<AuthProvider>().currentUser;
      if (user != null && user.id != null) {
        context.read<TripProvider>().loadTrips(user.id!);
        context.read<WalletProvider>().loadWalletData(user.id!);
      }
    });
  }

  // filtra a lista de viagens e ordena por data ou valor gasto de acordo com as preferências selecionadas
  List<Trip> _getFilteredAndSortedTrips(
    List<Trip>? trips,
    Map<String, double> amounts,
  ) {
    if (trips == null) return [];
    var list = trips.where((t) {
      final q = _searchQuery.toLowerCase();
      final sd = DateHelpers.formatDate(t.startDate);
      final ed = t.endDate != null ? DateHelpers.formatDate(t.endDate!) : '';
      return t.title.toLowerCase().contains(q) ||
          sd.contains(q) ||
          ed.contains(q);
    }).toList();

    list.sort((a, b) {
      if (_sortOption == 'Recentes (Padrão)') {
        final dateCompare = b.startDate.compareTo(a.startDate);
        if (dateCompare != 0) return dateCompare;
        return (b.id ?? '').compareTo(a.id ?? '');
      } else if (_sortOption == 'Antigos') {
        final dateCompare = a.startDate.compareTo(b.startDate);
        if (dateCompare != 0) return dateCompare;
        return (a.id ?? '').compareTo(b.id ?? '');
      } else if (_sortOption == 'Maior Gasto') {
        return (amounts[b.id!] ?? 0).compareTo(amounts[a.id!] ?? 0);
      } else if (_sortOption == 'Menor Gasto') {
        return (amounts[a.id!] ?? 0).compareTo(amounts[b.id!] ?? 0);
      }
      return 0;
    });
    return list;
  }

  void _showSortModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.cardBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        final options = [
          'Recentes (Padrão)',
          'Antigos',
          'Maior Gasto',
          'Menor Gasto',
        ];
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  "Ordenar viagens por",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              ...options.map(
                (option) => ListTile(
                  title: Text(
                    option,
                    style: const TextStyle(color: Colors.white),
                  ),
                  trailing: _sortOption == option
                      ? const Icon(Icons.check, color: AppColors.moneyGreen)
                      : null,
                  onTap: () {
                    setState(() => _sortOption = option);
                    Navigator.pop(context);
                  },
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final tripProvider = context.watch<TripProvider>();
    final walletProvider = context.watch<WalletProvider>();

    final user = authProvider.currentUser;
    final isLoading = tripProvider.isLoading || walletProvider.isLoading;
    final sortedTrips = _getFilteredAndSortedTrips(
      tripProvider.trips,
      tripProvider.tripAmounts,
    );

    // fixa a viagem "Dia a Dia" sempre no topo da lista - gastos de moeda fora de viagens especificas, para atualizar o saldo
    final diaADiaIndex = sortedTrips.indexWhere(
      (t) => t.title.toLowerCase() == 'dia a dia',
    );
    if (diaADiaIndex != -1) {
      final diaADiaTrip = sortedTrips.removeAt(diaADiaIndex);
      sortedTrips.insert(0, diaADiaTrip);
    }

    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      resizeToAvoidBottomInset: false,
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.moneyGreen),
            )
          : SafeArea(
              child: SingleChildScrollView(
                controller: _scrollController,
                child: Column(
                  children: [

                    // header
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                      child: Column(
                        children: [
                          // logo Viatio e logout
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const SizedBox(
                                width: 48,
                              ), 
                              Image.asset('assets/img/logo.png', height: 32),
                              IconButton(
                                icon: const Icon(
                                  Icons.logout,
                                  color: Colors.red,
                                ),
                                onPressed: () {
                                  authProvider.logout();
                                  Navigator.pushAndRemoveUntil(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const LoginScreen(),
                                    ),
                                    (route) => false,
                                  );
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 32),

                          // olá e saldo
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text(
                                "Olá, ${user?.name.split(' ')[0] ?? 'Nicole'}",
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
                                    "R\$ ${NumericHelpers.formatBrl(walletProvider.totalBalanceBrl)}",
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

                          // barra de pesquisa e filtros 
                          SearchFilterBar(
                            showFilter:
                                false, // filtro oculto na Home
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
                    sortedTrips.isEmpty
                        ? const Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: 40.0,
                              vertical: 40.0,
                            ),
                            child: Center(
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
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            itemCount: sortedTrips.length,
                            itemBuilder: (context, index) {
                              final trip = sortedTrips[index];
                              return _buildTripCard(
                                context,
                                trip,
                                tripProvider.tripAmounts[trip.id!] ?? 0.0,
                              );
                            },
                          ),
                  ],
                ),
              ),
            ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: CustomFAB(
        onPressed: () {
          if (user == null || user.id == null) return;
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => NewTripScreen(userId: user.id!),
            ),
          );
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

  Widget _buildTripCard(BuildContext context, Trip trip, double tripAmount) {
    // coverType pode ter uma URL http, assets/ ou ser vazio
    bool isNetwork = trip.coverType.startsWith('http');
    bool hasImage = trip.coverType.isNotEmpty;
    bool isDiaADia = trip.title.toLowerCase() == 'dia a dia';

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TripDetailsScreen(trip: trip),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        height: isDiaADia ? 70 : 120,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          image: hasImage
              ? DecorationImage(
                  image: isNetwork
                      ? NetworkImage(trip.coverType) as ImageProvider
                      : AssetImage(trip.coverType),
                  fit: BoxFit.cover,
                  colorFilter: ColorFilter.mode(
                    Colors.black.withValues(alpha: 0.4),
                    BlendMode.darken,
                  ),
                )
              : null,
          color: !hasImage ? const Color(0xFF1E293B) : null,
        ),
        padding: const EdgeInsets.all(16),
        child: isDiaADia
            ? Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    trip.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    "R\$ ${NumericHelpers.formatCurrency(tripAmount)}",
                    style: const TextStyle(
                      color: AppColors.moneyGreen,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              )
            : Column(
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
                        trip.endDate != null
                            ? "${DateHelpers.formatDate(trip.startDate)} - ${DateHelpers.formatDate(trip.endDate!)}"
                            : DateHelpers.formatDate(trip.startDate),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        "R\$ ${NumericHelpers.formatCurrency(tripAmount)}",
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
