/// categorias padrão de gastos de viagem suportadas pelo aplicativo
class AppCategories {
  static const String food = 'Alimentação';
  static const String market = 'Mercado';
  static const String transport = 'Transporte';
  static const String lodging = 'Hospedagem';
  static const String leisure = 'Lazer';
  static const String shopping = 'Compras';
  static const String bureaucracy = 'Burocracia (visto, taxa, seguro)';
  static const String health = 'Saúde (farmácia, consulta)';

  // lista agrupada com todas as categorias de gastos disponíveis
  static const List<String> all = [
    food, market, transport, lodging,
    leisure, shopping, bureaucracy, health
  ];
}
