import 'package:flutter/material.dart';
import 'package:app_final/screens/home_screen.dart';
import 'package:app_final/screens/register_screen.dart';
import 'package:app_final/core/authentication/auth_service.dart';
import '../core/theme/app_colors.dart';
// statefull -- as coisas mudam de estado, ocupa mais espaço operacional

/*
 if (valido) {
        final user = AuthService().login(
          _emailController.text, _passwordController.text;
        )
      }
* */

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  //variavel iniciando nome com _ fica oculta (como se fosse private)
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>(); //cria e inicializa
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _login() async {
    if (_formKey.currentState!.validate()) {
      final user = await AuthService().login(
        _emailController.text.trim(),
        _passwordController.text,
      );
      if (!mounted) return;
      
      if (user != null) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const HomeScreen(),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('E-mail ou senha incorretos!'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 60),
                  // Logo
                  const Center(
                    child: Text(
                      "Viatio",
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontFamily: 'Plus Jakarta Sans',
                      ),
                    ),
                  ),
                  const SizedBox(height: 60),
                  const Center(
                    child: Text(
                      "Bem vindo(a) de volta!",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                  
                  // E-mail input
                  TextFormField(
                    controller: _emailController,
                    style: const TextStyle(color: Colors.white),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Por favor, insira o e-mail';
                      }
                      return null;
                    },
                    decoration: InputDecoration(
                      labelText: "E-mail",
                      labelStyle: const TextStyle(color: Colors.white70),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: const BorderSide(color: AppColors.silverBorder),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: const BorderSide(color: AppColors.neonGreen),
                      ),
                      errorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: const BorderSide(color: Colors.red),
                      ),
                      focusedErrorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: const BorderSide(color: Colors.red),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Senha input
                  TextFormField(
                    controller: _passwordController,
                    obscureText: true,
                    style: const TextStyle(color: Colors.white),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Por favor, insira a senha';
                      }
                      return null;
                    },
                    decoration: InputDecoration(
                      labelText: "Senha",
                      labelStyle: const TextStyle(color: Colors.white70),
                      suffixIcon: const Icon(Icons.remove_red_eye_outlined, color: Colors.white70),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: const BorderSide(color: AppColors.silverBorder),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: const BorderSide(color: AppColors.neonGreen),
                      ),
                      errorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: const BorderSide(color: Colors.red),
                      ),
                      focusedErrorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: const BorderSide(color: Colors.red),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {
                        // Esqueci a senha futuro
                      },
                      child: const Text(
                        "Esqueci a senha",
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  SizedBox(
                    height: 55,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.bottomGreen,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      ),
                      onPressed: _login,
                      child: const Text("Entrar", style: TextStyle(color: Colors.white, fontSize: 18)),
                    ),
                  ),
                  
                  const SizedBox(height: 60),
                  const Center(
                    child: Text("Ainda não tem uma conta?", style: TextStyle(color: Colors.white70, fontSize: 16)),
                  ),
                  const SizedBox(height: 16),
                  
                  SizedBox(
                    height: 55,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        side: const BorderSide(color: AppColors.silverBorder),
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const RegisterScreen(),
                          ),
                        );
                      },
                      child: const Text("Cadastre-se", style: TextStyle(color: Colors.white, fontSize: 18)),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

