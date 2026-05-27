import 'package:flutter/foundation.dart';
import '../models/trip.dart';
import '../repositories/trip_repository.dart';
import '../repositories/expense_repository.dart';

class TripProvider extends ChangeNotifier {
  List<Trip>? _trips;
  Map<String, double> _tripAmounts = {};
  bool _isLoading = false;

  List<Trip>? get trips => _trips;
  Map<String, double> get tripAmounts => _tripAmounts;
  bool get isLoading => _isLoading;

  Future<void> loadTrips(String userId, {bool fetchApi = true}) async {
    _isLoading = true;
    notifyListeners();

    final dbTrips = await TripRepository().getTripsByUser(userId, fetchApi: fetchApi);
    
    final expenseRepo = ExpenseRepository();
    Map<String, double> amounts = {};
    
    for (var trip in dbTrips) {
      final expenses = await expenseRepo.getExpensesByTrip(trip.id!, fetchApi: false);
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

  Future<void> addTrip(Trip trip) async {
    await TripRepository().insertTrip(trip);
    // Recarrega as viagens localmente (sem chamar a API para ser rápido)
    await loadTrips(trip.userId, fetchApi: false);
  }

  Future<void> editTrip(Trip trip) async {
    await TripRepository().updateTrip(trip);
    await loadTrips(trip.userId, fetchApi: false);
  }

  Future<void> removeTrip(String tripId, String userId) async {
    await TripRepository().deleteTrip(tripId);
    await loadTrips(userId, fetchApi: false);
  }
}
