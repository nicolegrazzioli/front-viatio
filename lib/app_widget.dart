import 'package:app_final/screens/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:app_final/screens/home_screen.dart';
import 'package:provider/provider.dart';
import 'package:app_final/core/providers/auth_provider.dart';
import 'package:app_final/core/globals.dart';

// widget raiz do aplicativo que configura o MaterialApp e o tema visual
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // escuta o estado de autenticação para reconstruir a tela correspondente
    final authProvider = context.watch<AuthProvider>();
    
    return MaterialApp(
      title: 'Viatio',
      // vincula a chave global para controlar e exibir SnackBar
      scaffoldMessengerKey: scaffoldMessengerKey,
      debugShowCheckedModeBanner: false,
      // define as configurações do tema global do aplicativo
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        snackBarTheme: const SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
        ),
      ),
      // direciona para HomeScreen ou LoginScreen dependendo da existência do usuário
      home: authProvider.currentUser == null ? const LoginScreen() : const HomeScreen(),
    );
  }
}