import '../utils/date_helpers.dart';

/// modelo de dados que representa um gasto registrado em uma viagem
class Expense {
  final String? id;
  final String tripId;
  final String title;
  final double amount;
  final String currency;
  final String category;
  final DateTime date;
  final bool isAverageCost;
  final double? exchangeRate;
  final double amountBrl;

  final String? photoPath;

  Expense({
    this.id,
    required this.tripId,
    required this.title,
    required this.amount,
    required this.currency,
    required this.category,
    required this.date,
    required this.isAverageCost,
    this.exchangeRate,
    required this.amountBrl,

    this.photoPath,
  });

  // converte o objeto de gasto para um mapa de chave e valor compatível com o SQLite
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'trip_id': tripId,
      'title': title,
      'amount': amount,
      'currency': currency,
      'category': category,
      'date': date.toIso8601String(),
      'is_average_cost': isAverageCost ? 1 : 0, // SQLite armazena booleanos como 0 ou 1
      'exchange_rate': exchangeRate,
      'amount_brl': amountBrl,

      'photo_path': photoPath,
    };
  }

  // constrói uma instância de Expense a partir de dados mapeados do banco
  factory Expense.fromMap(Map<String, dynamic> map) {
    return Expense(
      id: map['id']?.toString(),
      tripId: map['trip_id']?.toString() ?? '',
      title: map['title'],
      amount: map['amount'],
      currency: map['currency'],
      category: map['category'],
      date: DateHelpers.parseDate(map['date']) ?? DateTime.now(),
      isAverageCost: map['is_average_cost'] == 1,
      exchangeRate: map['exchange_rate'],
      amountBrl: map['amount_brl'],

      photoPath: map['photo_path'],
    );
  }
}
