import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
import 'package:provider/provider.dart';
import 'package:app_final/core/database/me_app_database.dart';
import 'package:app_final/core/providers/auth_provider.dart';
import 'package:app_final/core/providers/trip_provider.dart';
import 'package:app_final/core/providers/wallet_provider.dart';
import 'app_widget.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  print("--- Iniciando Aplicativo ---");

  final authProvider = AuthProvider();

  try {
    if (kIsWeb) {
      print("Configurando databaseFactory para Web...");
      databaseFactory = databaseFactoryFfiWeb;
    }
    
    print("Tentando inicializar o banco de dados...");
    await AppDatabase().database;
    print("Banco de dados inicializado com sucesso!");
    
    // Inicia a sessão buscando o usuário do SQLite através do Provider
    await authProvider.initSession();
    
  } catch (e) {
    print("ERRO ao inicializar: $e");
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: authProvider),
        ChangeNotifierProvider(create: (_) => TripProvider()),
        ChangeNotifierProvider(create: (_) => WalletProvider()),
      ],
      child: const MyApp(),
    ),
  );
}
