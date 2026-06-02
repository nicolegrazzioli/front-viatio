import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';

/// botão flutuante de ação rápida (FAB) customizado com formato circular e destaque em verde neon
class CustomFAB extends StatelessWidget {
  final VoidCallback onPressed;

  const CustomFAB({
    super.key,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 70,
      height: 70,
      child: FloatingActionButton(
        onPressed: onPressed,
        backgroundColor: AppColors.neonGreen,
        elevation: 4,
        shape: const CircleBorder(),
        child: const Icon(
          Icons.add,
          color: Colors.white,
          size: 40,
        ),
      ),
    );
  }
}
