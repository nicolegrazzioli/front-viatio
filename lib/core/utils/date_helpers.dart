class DateHelpers {
  /// Faz o parse seguro de uma data vinda do banco de dados ou da API (ISO-8601 ou dd/MM/yyyy)
  static DateTime? parseDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return null;
    
    // Tenta formato ISO
    try {
      return DateTime.parse(dateStr);
    } catch (_) {}

    // Tenta formato dd/MM/yyyy (legado)
    try {
      final parts = dateStr.split('/');
      if (parts.length == 3) {
        return DateTime(int.parse(parts[2]), int.parse(parts[1]), int.parse(parts[0]));
      }
    } catch (_) {}

    return null;
  }

  /// Formata um DateTime para exibição na UI no padrão dd/MM/yyyy
  static String formatDate(DateTime date) {
    return "${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}";
  }
}
