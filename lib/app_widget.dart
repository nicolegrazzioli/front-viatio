import 'package:app_final/screens/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:app_final/screens/home_screen.dart';
import 'package:app_final/core/authentication/auth_service.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Viatio',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: AuthService.currentUser == null ? LoginScreen() : const HomeScreen(),
    );
  }
}