class Wallet {
  final String userId;
  final String currency;
  final double balance;
  final double averageVet;

  Wallet({
    required this.userId,
    required this.currency,
    required this.balance,
    required this.averageVet,
  });

  Map<String, dynamic> toMap() {
    return {
      'user_id': userId,
      'currency': currency,
      'balance': balance,
      'average_vet': averageVet,
    };
  }

  factory Wallet.fromMap(Map<String, dynamic> map) {
    return Wallet(
      userId: map['user_id']?.toString() ?? '',
      currency: map['currency'],
      balance: map['balance'],
      averageVet: map['average_vet'],
    );
  }
}
