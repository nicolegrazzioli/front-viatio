import 'package:flutter/foundation.dart';
import '../models/user.dart';
import '../repositories/user_repository.dart';
import '../api/sync_service.dart';

class AuthProvider extends ChangeNotifier {
  User? _currentUser;
  bool _isLoading = false;

  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;

  Future<void> initSession() async {
    _isLoading = true;
    notifyListeners();

    _currentUser = await UserRepository().getLoggedUser();
    
    if (_currentUser != null) {
      SyncService.syncAllUnsynced();
    }
    
    _isLoading = false;
    notifyListeners();
  }

  Future<bool> register(User user) async {
    _isLoading = true;
    notifyListeners();

    final success = await UserRepository().register(user);
    _isLoading = false;
    notifyListeners();
    return success;
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    notifyListeners();

    final loggedUser = await UserRepository().login(email, password);
    if (loggedUser != null) {
      _currentUser = loggedUser;
      SyncService.syncAllUnsynced();
      _isLoading = false;
      notifyListeners();
      return true;
    }
    
    _isLoading = false;
    notifyListeners();
    return false;
  }

  Future<void> logout() async {
    _currentUser = null;
    await UserRepository().logout();
    notifyListeners();
  }
}
