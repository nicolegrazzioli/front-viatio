import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../dao/userDAO.dart';
import '../api/sync_service.dart';
import '../api/api_client.dart';
import 'dart:convert';

class AuthProvider extends ChangeNotifier {
  User? _currentUser;
  bool _isLoading = false;

  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;

  Future<void> initSession() async {
    _isLoading = true;
    notifyListeners();

    _currentUser = await UserDAO().getLoggedUser();
    
    if (_currentUser != null) {
      SyncService.syncAllUnsynced();
    }
    
    _isLoading = false;
    notifyListeners();
  }

  Future<bool> register(User user) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await ApiClient.post('/auth/register', {
        'name': user.name,
        'email': user.email,
        'password': user.password,
      });
      
      _isLoading = false;
      notifyListeners();
      return response.statusCode == 200;
    } catch (e) {
      print("Erro no registro: $e");
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await ApiClient.post('/auth/login', {
        'email': email,
        'password': password,
      });

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        final token = data['token'];
        final userData = data['user'];

        // Salva o token JWT localmente
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('jwt_token', token);

        final loggedUser = User(
          id: userData['id'],
          name: userData['name'],
          email: userData['email'],
          password: "---", // não salvamos a senha no front
        );
        
        await UserDAO().clearUsers();
        await UserDAO().insertUser(loggedUser);
        
        _currentUser = loggedUser;
        SyncService.syncAllUnsynced(); // Tenta sincronizar registros criados offline
        
        _isLoading = false;
        notifyListeners();
        return true;
      }
    } catch (e) {
      print("Erro no login: $e");
    }
    
    _isLoading = false;
    notifyListeners();
    return false;
  }

  Future<void> logout() async {
    _currentUser = null;
    await UserDAO().clearUsers();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('jwt_token');
    notifyListeners();
  }
}
