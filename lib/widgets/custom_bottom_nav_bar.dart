import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';

/// barra de navegação inferior com recorte central para o botão "+" suspenso
class CustomBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const CustomBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return BottomAppBar(
      color: AppColors.darkBackground,
      shape: const CircularNotchedRectangle(),
      notchMargin: 8.0,
      elevation: 0,
      child: SizedBox(
        height: 60,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Expanded(
              child: InkWell(
                onTap: () => onTap(0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      currentIndex == 0 ? Icons.home : Icons.home_outlined,
                      size: 28,
                      // ignore: deprecated_member_use
                      color: currentIndex == 0 ? AppColors.offWhite : AppColors.offWhite.withOpacity(0.6),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 70), // espaço no meio para o "+" flutuante
            Expanded(
              child: InkWell(
                onTap: () => onTap(1),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      currentIndex == 1 ? Icons.account_balance_wallet : Icons.account_balance_wallet_outlined,
                      size: 28,
                      color: currentIndex == 1 ? AppColors.offWhite : AppColors.offWhite.withOpacity(0.6),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
