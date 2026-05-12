import 'package:flutter/material.dart';
import 'package:app_final/screens/home_screen.dart';
import 'package:app_final/screens/login_screen.dart';
import '../core/theme/app_colors.dart';
import '../widgets/custom_bottom_nav_bar.dart';
import 'balances_screen.dart';
import '../core/models/user.dart';
import '../core/dao/userDAO.dart';
import '../core/authentication/auth_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _showPasswordFields = false;
  User? _currentUser;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  
  final TextEditingController _currentPasswordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    User? user = AuthService.currentUser;
    if (user == null) {
      user = await UserDAO().getUser('nicole@exemplo.com', '123');
      if (user == null) {
        final newUser = User(name: "Nicole Grazzioli", email: "nicole@exemplo.com", password: "123");
        await UserDAO().insertUser(newUser);
        user = await UserDAO().getUser('nicole@exemplo.com', '123');
      }
      AuthService.currentUser = user;
    }
    
    if (user != null && mounted) {
      setState(() {
        _currentUser = user;
        _nameController.text = user!.name;
        _emailController.text = user!.email;
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Widget _buildTextField(String label, TextEditingController controller, {bool obscure = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextFormField(
        controller: controller,
        obscureText: obscure,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.white70),
          suffixIcon: obscure ? const Icon(Icons.remove_red_eye_outlined, color: Colors.white70) : null,
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: const BorderSide(color: AppColors.silverBorder),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: const BorderSide(color: AppColors.neonGreen),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  RichText(
                    text: TextSpan(
                      children: [
                        const TextSpan(
                          text: "pila.",
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        WidgetSpan(
                          child: Container(
                            margin: const EdgeInsets.only(left: 2),
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: const BoxDecoration(
                              color: AppColors.bottomGreen,
                              borderRadius: BorderRadius.all(Radius.circular(20)),
                            ),
                            child: const Text(
                              "go",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          alignment: PlaceholderAlignment.middle,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  children: [
                    const SizedBox(height: 24),
                    const Text(
                      "Meu perfil",
                      style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 24),
                    // Fields
                    _buildTextField("Nome", _nameController),
                    _buildTextField("E-mail", _emailController),
                    
                    const SizedBox(height: 8),
                    
                    // Accordion for Password
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _showPasswordFields = !_showPasswordFields;
                        });
                      },
                      child: Row(
                        children: [
                          Icon(
                            _showPasswordFields ? Icons.keyboard_arrow_down : Icons.arrow_forward_ios,
                            color: Colors.white,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            "Alterar senha",
                            style: TextStyle(color: Colors.white, fontSize: 18),
                          ),
                        ],
                      ),
                    ),
                    
                    if (_showPasswordFields) ...[
                      const SizedBox(height: 24),
                      _buildTextField("Senha atual", _currentPasswordController, obscure: true),
                      _buildTextField("Nova senha", _newPasswordController, obscure: true),
                      _buildTextField("Confirmar senha", _confirmPasswordController, obscure: true),
                    ],
                    
                    const SizedBox(height: 32),
                    
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.bottomGreen,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        ),
                        onPressed: () async {
                          if (_currentUser == null) return;
                          
                          String finalPassword = _currentUser!.password;
                          
                          if (_showPasswordFields) {
                            if (_currentPasswordController.text != _currentUser!.password) {
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('A senha atual está incorreta.', style: TextStyle(color: Colors.white)), backgroundColor: Colors.red));
                              return;
                            }
                            if (_newPasswordController.text.trim().isEmpty || _newPasswordController.text != _confirmPasswordController.text) {
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('As novas senhas não coincidem.', style: TextStyle(color: Colors.white)), backgroundColor: Colors.red));
                              return;
                            }
                            finalPassword = _newPasswordController.text;
                          }
                          
                          User updatedUser = User(
                            id: _currentUser!.id,
                            name: _nameController.text.trim(),
                            email: _emailController.text.trim(),
                            password: finalPassword,
                          );
                          
                          await UserDAO().updateUser(updatedUser);
                          _currentUser = updatedUser;
                          
                          if (_showPasswordFields) {
                            _currentPasswordController.clear();
                            _newPasswordController.clear();
                            _confirmPasswordController.clear();
                            setState(() => _showPasswordFields = false);
                          }

                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Perfil atualizado com sucesso!'),
                                backgroundColor: AppColors.moneyGreen,
                              ),
                            );
                          }
                        },
                        child: const Text("Salvar", style: TextStyle(color: Colors.white, fontSize: 18)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Botão de Logout
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: TextButton(
                        style: TextButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                            side: const BorderSide(color: Colors.red, width: 1.5),
                          ),
                        ),
                        onPressed: () {
                          AuthService().logout();
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(builder: (context) => const LoginScreen()),
                            (route) => false,
                          );
                        },
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.logout, color: Colors.red),
                            SizedBox(width: 8),
                            Text("Sair da conta", style: TextStyle(color: Colors.red, fontSize: 18)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: 2,
        onTap: (index) {
          if (index == 0) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const HomeScreen()),
            );
          } else if (index == 1) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const BalancesScreen()),
            );
          }
        },
      ),
    );
  }
}
