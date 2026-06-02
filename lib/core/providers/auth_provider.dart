import 'package:flutter/foundation.dart';
import '../models/user.dart';
import '../repositories/user_repository.dart';
import '../api/sync_service.dart';
import '../api/api_client.dart';

/// gerencia o estado global de autenticação do usuário e notifica as telas sobre mudanças de sessão
class AuthProvider extends ChangeNotifier {
  // armazena o usuário atualmente autenticado
  User? _currentUser;
  // indica se há um processo de autenticação em andamento
  bool _isLoading = false;

  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;

  AuthProvider() {
    // vincula o logout global ao evento de não autorizado da API
    ApiClient.onUnauthorized = logout;
  }

  /// inicializa o estado de sessão verificando o armazenamento local e iniciando a sincronização offline
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

  /// executa o fluxo de registro de um novo usuário notificando mudanças de estado para a interface
  Future<bool> register(User user) async {
    _isLoading = true;
    notifyListeners();

    final success = await UserRepository().register(user);
    _isLoading = false;
    notifyListeners();
    return success;
  }

  /// realiza o login do usuário, armazena seus dados localmente e dispara o sincronizador offline
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

  /// efetua o logout limpando o usuário em memória e o token JWT local
  Future<void> logout() async {
    _currentUser = null;
    await UserRepository().logout();
    notifyListeners();
  }
}
