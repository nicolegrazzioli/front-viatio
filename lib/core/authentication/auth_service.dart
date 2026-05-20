import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../api/api_client.dart';

class AuthService {
  static User? currentUser;

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

        // Salva o token JWT localmente
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('jwt_token', token);

        // O backend precisa devolver os dados do usuário, mas nossa rota /auth/login retorna só o token.
        // Como o JWT tem as infos, ou o backend manda um /profile, por agora mockamos o currentUser
        // com o e-mail, e depois o ideal seria um endpoint para buscar os dados completos.
        // Por ora, para não quebrar a tela:
        final tempUser = User(id: 0, name: "Usuário", email: email, password: "---");
        currentUser = tempUser;
        return tempUser;
      }
    } catch (e) {
      print("Erro no login: $e");
    }
    return null;
  }

  Future<void> logout() async {
    currentUser = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('jwt_token');
  }
}