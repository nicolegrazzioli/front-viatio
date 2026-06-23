import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';

/// barra de ferramentas combinada contendo campo de pesquisa de texto e botões para filtragem e ordenação de listas
class SearchFilterBar extends StatelessWidget {
  final VoidCallback? onFilterTap;
  final VoidCallback? onSortTap;
  final ValueChanged<String>? onSearchChanged;
  final String searchHint;
  final bool showFilter;
  final bool isFilterActive;
  final bool isSortActive;

  const SearchFilterBar({
    super.key,
    this.onFilterTap,
    this.onSortTap,
    this.onSearchChanged,
    this.searchHint = "pesquisar",
    this.showFilter = true,
    this.isFilterActive = false,
    this.isSortActive = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // botões de filtro e ordenação (metade)
        Expanded(
          child: Row(
            children: [
              // botão filtrar (opcional, nao tem na home)
              if (showFilter) ...[
                Expanded(
                  child: Container(
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.darkBackground,
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(
                        color: isFilterActive ? AppColors.moneyGreen : AppColors.silverBorder,
                        width: isFilterActive ? 2.0 : 1.0,
                      ),
                    ),
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      icon: const Icon(Icons.filter_alt_outlined, color: Colors.white, size: 24),
                      onPressed: onFilterTap,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              // botão ordenar
              Expanded(
                child: Container(
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.darkBackground,
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(
                      color: isSortActive ? AppColors.moneyGreen : AppColors.silverBorder,
                      width: isSortActive ? 2.0 : 1.0,
                    ),
                  ),
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    icon: const Icon(Icons.sort, color: Colors.white, size: 24),
                    onPressed: onSortTap,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        // barra de pesquisa (a outra metade)
        Expanded(
          child: Container(
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.darkBackground,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: AppColors.silverBorder),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    onChanged: onSearchChanged,
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                    decoration: InputDecoration(
                      hintText: searchHint,
                      hintStyle: const TextStyle(color: Colors.white70, fontSize: 16),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ),
                const Icon(Icons.search, color: Colors.white70, size: 20),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
