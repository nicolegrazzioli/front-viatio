import 'package:flutter/foundation.dart';
import '../models/trip.dart';
import '../dao/trip_dao.dart';
import '../dao/expense_dao.dart';

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

    final dbTrips = await TripDAO().getTripsByUser(userId, fetchApi: fetchApi);
    
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

    _trips = dbTrips;
    _tripAmounts = amounts;
    _isLoading = false;
    notifyListeners();
  }

  Future<void> addTrip(Trip trip) async {
    await TripDAO().insertTrip(trip);
    // Recarrega as viagens localmente (sem chamar a API para ser rápido)
    await loadTrips(trip.userId, fetchApi: false);
  }

  Future<void> editTrip(Trip trip) async {
    await TripDAO().updateTrip(trip);
    await loadTrips(trip.userId, fetchApi: false);
  }

  Future<void> removeTrip(String tripId, String userId) async {
    await TripDAO().deleteTrip(tripId);
    await loadTrips(userId, fetchApi: false);
  }
}
