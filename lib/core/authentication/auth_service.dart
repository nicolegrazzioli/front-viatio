import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../api/api_client.dart';
import '../api/sync_service.dart';
import '../dao/userDAO.dart';

/// autenticação do usuário, gerencia o login, registro, logout e estado da sessão
class AuthService {
  // guarda os dados do usuário autenticado na sessão do aplicativo
  static User? currentUser;

  /// inicializa a sessão buscando o usuário logado no banco de dados local e inicia a sincronização offline se existir
  static Future<void> initSession() async {
    currentUser = await UserDAO().getLoggedUser();
    if (currentUser != null) {
      SyncService.syncAllUnsynced();
    }
  }

  /// registra um novo usuário na API e retorna true se o cadastro for bem-sucedido
  Future<bool> register(User user) async {
    try {
      final response = await ApiClient.post('/auth/register', {
        'name': user.name,
        'email': user.email,
        'password': user.password,
      });
      
      return response.statusCode == 200;
    } catch (e) {
      debugPrint("Erro no registro: $e");
      return false;
    }
  }

  /// realiza a autenticação do usuário, salva o token JWT localmente, armazena os dados do usuário no banco local e inicia a sincronização offline
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

        // salva o token JWT localmente
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('jwt_token', token);

        final loggedUser = User(
          id: userData['id'],
          name: userData['name'],
          email: userData['email'],
          password: "---", // não salva a senha no front
        );
        
        await UserDAO().clearUsers();
        await UserDAO().insertUser(loggedUser);
        
        currentUser = loggedUser;
        SyncService.syncAllUnsynced(); // tenta sincronizar registros criados offline
        return loggedUser;
      }
    } catch (e) {
      debugPrint("Erro no login: $e");
    }
    return null;
  }

  /// encerra a sessão do usuário limpando os dados locais e removendo o token JWT do SharedPreferences
  Future<void> logout() async {
    currentUser = null;
    await UserDAO().clearUsers();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('jwt_token');
  }
}
