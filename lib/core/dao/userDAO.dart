import 'package:app_final/core/database/me_app_database.dart';
import '../models/user.dart';

/// classe de acesso aos dados que executa queries SQL para gerenciar o usuário local no SQLite
class UserDAO {
  static const String table = 'users';

   // insere um novo usuário na tabela local do banco
   Future<int> insertUser(User user) async {
     final db = await AppDatabase().database;
     return await db.insert(table, user.toMap());
   }

  // recupera o usuário que possui sessão ativa no aplicativo
  Future<User?> getLoggedUser() async {
     final db = await AppDatabase().database;
     final result = await db.query(table, limit: 1);
     return result.isNotEmpty ? User.fromMap(result.first) : null;
  }

  // remove todos os usuários da tabela local limpando a sessão antiga
  Future<void> clearUsers() async {
     final db = await AppDatabase().database;
     await db.delete(table);
  }

  // atualiza as informações cadastrais do usuário no banco local
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

  // remove um usuário específico da tabela pelo ID correspondente
  Future<int> deleteUser(String id) async {
     final db = await AppDatabase().database;
     final result = await db.delete(
       table,
       where: 'id = ?',
       whereArgs: [id],
     );
     return result;
  }

  // retorna todos os usuários cadastrados localmente ordenados por nome de forma ascendente
  Future<List<User>> findAllUsers() async {
     final db = await AppDatabase().database;
     final result = await db.query(
       table,
       orderBy: 'name ASC',
     );
     return result.map((element) => User.fromMap(element)).toList();
  }
}