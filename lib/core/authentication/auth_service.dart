import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../api/api_client.dart';
import '../api/sync_service.dart';
import '../dao/userDAO.dart';

class AuthService {
  static User? currentUser;

  static Future<void> initSession() async {
    currentUser = await UserDAO().getLoggedUser();
    if (currentUser != null) {
      SyncService.syncAllUnsynced();
    }
  }

  Future<bool> register(User user) async {
    try {
      final response = await ApiClient.post('/auth/register', {
        'name': user.name,
        'email': user.email,
        'password': user.password,
      });
      
      return response.statusCode == 200;
    } catch (e) {
      print("Erro no registro: $e");
      return false;
    }
  }

  Future<User?> login(String email, String password) async {
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
        
        currentUser = loggedUser;
        SyncService.syncAllUnsynced(); // Tenta sincronizar registros criados offline
        return loggedUser;
      }
    } catch (e) {
      print("Erro no login: $e");
    }
    return null;
  }

  Future<void> logout() async {
    currentUser = null;
    await UserDAO().clearUsers();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('jwt_token');
  }
}