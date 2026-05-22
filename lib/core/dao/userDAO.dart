import 'package:app_final/core/database/me_app_database.dart';
import '../models/user.dart';

class UserDAO {
  static const String table = 'users';

   Future<int> insertUser(User user) async {
     final db = await AppDatabase().database;
     return await db.insert(table, user.toMap());
   }

  Future<User?> getLoggedUser() async {
     final db = await AppDatabase().database;
     final result = await db.query(table, limit: 1);
     return result.isNotEmpty ? User.fromMap(result.first) : null;
  }

  Future<void> clearUsers() async {
     final db = await AppDatabase().database;
     await db.delete(table);
  }

  Future<int> updateUser(User user) async {
     final db = await AppDatabase().database;
     final result = await db.update(
       table,
       user.toMap(),
       where: 'id = ?',
       whereArgs: [user.id],
     );
     return result;
  }

  Future<int> deleteUser(String id) async {
     final db = await AppDatabase().database;
     final result = await db.delete(
       table,
       where: 'id = ?',
       whereArgs: [id],
     );
     return result;
  }

  Future<List<User>> findAllUsers() async {
     final db = await AppDatabase().database;
     final result = await db.query(
       table,
       orderBy: 'name ASC',
     );
     return result.map((element) => User.fromMap(element)).toList();
  }
}