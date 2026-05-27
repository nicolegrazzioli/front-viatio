import '../models/wallet.dart';
import '../database/me_app_database.dart';

class WalletDAO {
  Future<int> insertWallet(Wallet wallet) async {
    final db = await AppDatabase().database;
    return await db.insert('wallets', wallet.toMap());
  }

  Future<List<Wallet>> getWalletsByUser(String userId, {bool fetchApi = false}) async {
    final db = await AppDatabase().database;
    final List<Map<String, dynamic>> maps = await db.query(
      'wallets',
      where: 'user_id = ?',
      whereArgs: [userId],
    );
    return List.generate(maps.length, (i) => Wallet.fromMap(maps[i]));
  }

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

  Future<int> updateWallet(Wallet wallet) async {
    final db = await AppDatabase().database;
    return await db.update(
      'wallets',
      wallet.toMap(),
      where: 'user_id = ? AND currency = ?',
      whereArgs: [wallet.userId, wallet.currency],
    );
  }

  Future<int> deleteWallet(String userId, String currency) async {
    final db = await AppDatabase().database;
    return await db.delete(
      'wallets',
      where: 'user_id = ? AND currency = ?',
      whereArgs: [userId, currency],
    );
  }
}
