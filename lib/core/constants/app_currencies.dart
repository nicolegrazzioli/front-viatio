class AppCurrencies {
  static const String brl = 'BRL';
  static const String usd = 'USD';
  static const String eur = 'EUR';

  static const List<String> all = [brl, usd, eur];

  static bool isEuro(String currency) {
    return currency == eur || currency == 'Euro';
  }

  static bool isUsd(String currency) {
    return currency == usd || currency == 'Dólar';
  }

  static bool isBrl(String currency) {
    return currency == brl || currency == 'Real';
  }
}
