import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../dao/userDAO.dart';
import '../api/api_client.dart';

class UserRepository {
  final UserDAO _dao = UserDAO();

  Future<User?> getLoggedUser() async {
    return await _dao.getLoggedUser();
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
      debugPrint("Erro no registro: $e");
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

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('jwt_token', token);

        final loggedUser = User(
          id: userData['id'],
          name: userData['name'],
          email: userData['email'],
          password: "---",
        );
        
        await _dao.clearUsers();
        await _dao.insertUser(loggedUser);
        
        return loggedUser;
      }
    } catch (e) {
      debugPrint("Erro no login: $e");
    }
    return null;
  }

  Future<void> logout() async {
    await _dao.clearUsers();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('jwt_token');
  }
}
