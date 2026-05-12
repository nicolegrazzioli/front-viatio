import 'package:app_final/core/dao/userDAO.dart';
import '../models/user.dart';

class AuthService {
  static User? currentUser;
  final UserDAO _userDAO = UserDAO();

  Future<bool> register(User user) async {
    try {
      await _userDAO.insertUser(user);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<User?> login(String email, String password) async {
    final user = await _userDAO.getUser(email, password);
    if (user != null) {
      currentUser = user;
    }
    return user;
  }

  void logout() {
    currentUser = null;
  }
}