import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
import 'package:provider/provider.dart';
import 'package:app_final/core/database/me_app_database.dart';
import 'package:app_final/core/providers/auth_provider.dart';
import 'package:app_final/core/providers/trip_provider.dart';
import 'package:app_final/core/providers/wallet_provider.dart';
import 'package:app_final/core/providers/expense_provider.dart';
import 'app_widget.dart';

void main() async {
  // garante que as ligações do framework estejam prontas antes de inicializar o app
  WidgetsFlutterBinding.ensureInitialized();

  debugPrint("--- Iniciando Aplicativo ---");

  // instancia o AuthProvider para recuperar a sessão do usuário
  final authProvider = AuthProvider();

  try {
    if (kIsWeb) {
      // configura o suporte de banco de dados para a plataforma web
      debugPrint("Configurando databaseFactory para Web...");
      databaseFactory = databaseFactoryFfiWeb;
    }
    
    // realiza a conexão e criação do banco de dados SQLite
    debugPrint("Tentando inicializar o banco de dados...");
    await AppDatabase().database;
    debugPrint("Banco de dados inicializado com sucesso!");
    
    // inicia a sessão buscando o usuário local no SQLite usando o AuthProvider
    await authProvider.initSession();
    
  } catch (e) {
    debugPrint("ERRO ao inicializar: $e");
  }

  // inicializa o aplicativo injetando os estados no MultiProvider
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: authProvider),
        ChangeNotifierProvider(create: (_) => TripProvider()),
        ChangeNotifierProvider(create: (_) => WalletProvider()),
        ChangeNotifierProvider(create: (_) => ExpenseProvider()),
      ],
      child: const MyApp(),
    ),
  );
}
