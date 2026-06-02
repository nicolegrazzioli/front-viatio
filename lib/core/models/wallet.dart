/// modelo de dados que representa o saldo de uma determinada moeda estrangeira na carteira do usuário
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

  // mapeia os dados da carteira para o formato chave-valor estruturado para persistência no SQLite
  Map<String, dynamic> toMap() {
    return {
      'user_id': userId,
      'currency': currency,
      'balance': balance,
      'average_vet': averageVet,
    };
  }

  // cria uma instância de Wallet de acordo com os registros retornados do banco local
  factory Wallet.fromMap(Map<String, dynamic> map) {
    return Wallet(
      userId: map['user_id']?.toString() ?? '',
      currency: map['currency'],
      balance: map['balance'],
      averageVet: map['average_vet'],
    );
  }
}
