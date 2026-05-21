import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
import 'package:app_final/core/database/me_app_database.dart';
import 'package:app_final/core/authentication/auth_service.dart';
import 'app_widget.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  print("--- Iniciando Aplicativo ---");

  try {
    if (kIsWeb) {
      print("Configurando databaseFactory para Web...");
      databaseFactory = databaseFactoryFfiWeb;
    }
    
    print("Tentando inicializar o banco de dados...");
    await AppDatabase().database;
    print("Banco de dados inicializado com sucesso!");
    
    // Inicia a sessão buscando o usuário do SQLite
    await AuthService.initSession();
    
  } catch (e) {
    print("ERRO ao inicializar: $e");
  }

  runApp(const MyApp());
}
