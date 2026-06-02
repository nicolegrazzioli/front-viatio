import '../models/wallet.dart';
import '../database/me_app_database.dart';

/// classe de acesso aos dados que executa queries SQL para gerenciar as carteiras virtuais (saldos) no SQLite
class WalletDAO {
  // insere uma nova carteira de saldo no banco local
  Future<int> insertWallet(Wallet wallet) async {
    final db = await AppDatabase().database;
    return await db.insert('wallets', wallet.toMap());
  }

  // busca todas as carteiras associadas a um usuário específico
  Future<List<Wallet>> getWalletsByUser(String userId, {bool fetchApi = false}) async {
    final db = await AppDatabase().database;
    final List<Map<String, dynamic>> maps = await db.query(
      'wallets',
      where: 'user_id = ?',
      whereArgs: [userId],
    );
    return List.generate(maps.length, (i) => Wallet.fromMap(maps[i]));
  }

  // recupera o registro de uma carteira com base no usuário e tipo de moeda
  Future<Wallet?> getWallet(String userId, String currency) async {
    final db = await AppDatabase().database;
    final List<Map<String, dynamic>> maps = await db.query(
      'wallets',
      where: 'user_id = ? AND currency = ?',
      whereArgs: [userId, currency],
    );
    if (maps.isNotEmpty) {
      return Wallet.fromMap(maps.first);
    }
    return null;
  }

  // atualiza o saldo e informações de uma carteira específica de um usuário
  Future<int> updateWallet(Wallet wallet) async {
    final db = await AppDatabase().database;
    return await db.update(
      'wallets',
      wallet.toMap(),
      where: 'user_id = ? AND currency = ?',
      whereArgs: [wallet.userId, wallet.currency],
    );
  }

  // remove do banco de dados local a carteira de um usuário referente a uma moeda específica
  Future<int> deleteWallet(String userId, String currency) async {
    final db = await AppDatabase().database;
    return await db.delete(
      'wallets',
      where: 'user_id = ? AND currency = ?',
      whereArgs: [userId, currency],
    );
  }
}
