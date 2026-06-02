/// siglas de moedas e funções utilitárias para verificação de tipos de moeda suportadas no app
class AppCurrencies {
  static const String brl = 'BRL';
  static const String usd = 'USD';
  static const String eur = 'EUR';

  // lista com todas as moedas suportadas pelo sistema
  static const List<String> all = [brl, usd, eur];

  // verifica se a string corresponde à moeda euro (EUR)
  static bool isEuro(String currency) {
    return currency == eur || currency == 'Euro';
  }

  // verifica se a string corresponde à moeda dólar (USD)
  static bool isUsd(String currency) {
    return currency == usd || currency == 'Dólar';
  }

  // verifica se a string corresponde à moeda real (BRL)
  static bool isBrl(String currency) {
    return currency == brl || currency == 'Real';
  }
}
