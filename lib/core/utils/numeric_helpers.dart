class NumericHelpers {
  /// Converte uma string monetária (com vírgula ou ponto) para double
  static double parseAmount(String text) {
    if (text.trim().isEmpty) return 0.0;
    final normalized = text.replaceAll(',', '.');
    return double.tryParse(normalized) ?? 0.0;
  }

  /// Formata um valor double para string com 2 casas decimais (padrão com ponto)
  static String formatCurrency(double amount) {
    return amount.toStringAsFixed(2);
  }

  /// Formata um valor double para string monetária no padrão brasileiro (com vírgula)
  static String formatBrl(double amount) {
    return amount.toStringAsFixed(2).replaceAll('.', ',');
  }
}
