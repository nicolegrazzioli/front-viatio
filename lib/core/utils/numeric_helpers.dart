/// funções auxiliares para manipulação, parse e formatação de valores numéricos e moedas
class NumericHelpers {
  /// converte uma string contendo valores decimais (com ponto ou vírgula) em double
  static double parseAmount(String text) {
    if (text.trim().isEmpty) return 0.0;
    final normalized = text.replaceAll(',', '.');
    return double.tryParse(normalized) ?? 0.0;
  }

  /// formata valores numéricos para string contendo duas casas decimais com separação por ponto
  static String formatCurrency(double amount) {
    return amount.toStringAsFixed(2);
  }

  /// formata valores numéricos para representação monetária brasileira utilizando a vírgula como decimal
  static String formatBrl(double amount) {
    return amount.toStringAsFixed(2).replaceAll('.', ',');
  }
}
