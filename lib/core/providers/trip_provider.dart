import 'package:flutter/foundation.dart';
import '../models/trip.dart';
import '../repositories/trip_repository.dart';
import '../repositories/expense_repository.dart';

/// gerencia o estado das viagens do usuário na tela, incluindo o cálculo total em reais de cada viagem
class TripProvider extends ChangeNotifier {
  // lista das viagens carregadas
  List<Trip>? _trips;
  // mapa que associa o ID da viagem ao valor total acumulado em BRL
  Map<String, double> _tripAmounts = {};
  // indica se os dados das viagens estão sendo carregados
  bool _isLoading = false;

  List<Trip>? get trips => _trips;
  Map<String, double> get tripAmounts => _tripAmounts;
  bool get isLoading => _isLoading;

  /// busca as viagens do banco de dados local ou API e calcula a soma total de gastos convertidos em BRL para cada viagem
  Future<void> loadTrips(String userId, {bool fetchApi = true}) async {
    _isLoading = true;
    notifyListeners();

    final dbTrips = await TripRepository().getTripsByUser(userId, fetchApi: fetchApi);
    
    final expenseRepo = ExpenseRepository();
    Map<String, double> amounts = {};
    
    for (var trip in dbTrips) {
      final expenses = await expenseRepo.getExpensesByTrip(trip.id!, fetchApi: fetchApi);
      double total = 0.0;
      for (var exp in expenses) {
        total += exp.amountBrl;
      }
      amounts[trip.id!] = total;
    }

    _trips = dbTrips;
    _tripAmounts = amounts;
    _isLoading = false;
    notifyListeners();
  }

  /// insere uma nova viagem e atualiza a interface local de forma reativa
  Future<void> addTrip(Trip trip) async {
    await TripRepository().insertTrip(trip);
    // Recarrega as viagens localmente (sem chamar a API para ser rápido)
    await loadTrips(trip.userId, fetchApi: false);
  }

  /// atualiza os dados de uma viagem existente localmente
  Future<void> editTrip(Trip trip) async {
    await TripRepository().updateTrip(trip);
    await loadTrips(trip.userId, fetchApi: false);
  }

  /// remove uma viagem do banco local e atualiza a lista exibida
  Future<void> removeTrip(String tripId, String userId) async {
    await TripRepository().deleteTrip(tripId);
    await loadTrips(userId, fetchApi: false);
  }
}
