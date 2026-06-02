/// conjunto de funções auxiliares para manipulação, conversão e formatação de datas
class DateHelpers {
  /// realiza a conversão segura de múltiplos formatos de data dinâmicos para DateTime
  static DateTime? parseDate(dynamic dateData) {
    if (dateData == null) return null;

    if (dateData is List && dateData.length >= 3) {
      return DateTime(dateData[0], dateData[1], dateData[2]);
    }
    
    String dateStr = dateData.toString();
    if (dateStr.isEmpty) return null;
    
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

  /// formata um objeto DateTime para string no formato legível nacional dd/MM/yyyy
  static String formatDate(DateTime date) {
    return "${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}";
  }
}
