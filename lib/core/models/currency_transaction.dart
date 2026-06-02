import '../utils/date_helpers.dart';

/// modelo de dados que representa uma transação de compra de moeda estrangeira
class CurrencyTransaction {
  final String? id;
  final String userId;
  final double amount;
  final String currency;
  final double amountBrl;
  final String source;
  final DateTime date;
  final double vetRate;

  final String? photoPath;

  CurrencyTransaction({
    this.id,
    required this.userId,
    required this.amount,
    required this.currency,
    required this.amountBrl,
    required this.source,
    required this.date,
    required this.vetRate,

    this.photoPath,
  });

  // converte o objeto de transação para um mapa de chave e valor compatível com o SQLite
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'amount': amount,
      'currency': currency,
      'amount_brl': amountBrl,
      'source': source,
      'date': date.toIso8601String(),
      'vet_rate': vetRate,

      'photo_path': photoPath,
    };
  }

  // constrói uma instância de CurrencyTransaction a partir de dados recuperados do banco
  factory CurrencyTransaction.fromMap(Map<String, dynamic> map) {
    return CurrencyTransaction(
      id: map['id']?.toString(),
      userId: map['user_id']?.toString() ?? '',
      amount: map['amount'],
      currency: map['currency'],
      amountBrl: map['amount_brl'],
      source: map['source'],
      date: DateHelpers.parseDate(map['date']) ?? DateTime.now(),
      vetRate: map['vet_rate'],

      photoPath: map['photo_path'],
    );
  }
}
