import 'package:app_final/screens/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:app_final/screens/home_screen.dart';
import 'package:provider/provider.dart';
import 'package:app_final/core/providers/auth_provider.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    
    return MaterialApp(
      title: 'Viatio',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: authProvider.currentUser == null ? const LoginScreen() : const HomeScreen(),
    );
  }
}