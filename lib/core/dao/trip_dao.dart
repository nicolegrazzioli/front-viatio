import 'package:uuid/uuid.dart';
import '../models/trip.dart';
import '../database/me_app_database.dart';
import 'package:sqflite/sqflite.dart';

/// classe de acesso aos dados que executa queries SQL para gerenciar as viagens no SQLite
class TripDAO {
  final _uuid = const Uuid();

  // insere ou substitui uma viagem no banco local gerando um UUID se necessário
  Future<String> insertTrip(Trip trip, {int isSynced = 0}) async {
    final db = await AppDatabase().database;
    final String tripId = trip.id ?? _uuid.v4();
    
    final newTrip = Trip(
      id: tripId,
      userId: trip.userId,
      title: trip.title,
      startDate: trip.startDate,
      endDate: trip.endDate,
      coverType: trip.coverType,
    );

    await db.insert(
      'trips', 
      {...newTrip.toMap(), 'is_synced': isSynced},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    return tripId;
  }

  // retorna todas as viagens locais que ainda não foram sincronizadas com o servidor
  Future<List<Map<String, dynamic>>> getUnsyncedTrips() async {
    final db = await AppDatabase().database;
    return await db.query('trips', where: 'is_synced = ?', whereArgs: [0]);
  }

  // busca viagens sincronizadas associadas a um usuário específico
  Future<List<Map<String, dynamic>>> getSyncedTrips(String userId) async {
    final db = await AppDatabase().database;
    return await db.query('trips', where: 'user_id = ? AND is_synced = ?', whereArgs: [userId, 1]);
  }

  // retorna todas as viagens ativas de um usuário que não foram marcadas como deletadas
  Future<List<Trip>> getTripsByUser(String userId) async {
    final db = await AppDatabase().database;
    final List<Map<String, dynamic>> maps = await db.query(
      'trips',
      where: 'user_id = ? AND is_deleted = 0',
      whereArgs: [userId],
    );
    return List.generate(maps.length, (i) => Trip.fromMap(maps[i]));
  }

  // recupera o registro de uma viagem pelo seu ID único
  Future<Map<String, dynamic>?> getTripById(String tripId) async {
    final db = await AppDatabase().database;
    final result = await db.query('trips', where: 'id = ?', whereArgs: [tripId]);
    return result.isNotEmpty ? result.first : null;
  }

  // atualiza as informações de uma viagem e redefine o status de sincronização para pendente
  Future<int> updateTrip(Trip trip, {int isSynced = 0}) async {
    final db = await AppDatabase().database;
    return await db.update(
      'trips',
      {...trip.toMap(), 'is_synced': isSynced},
      where: 'id = ?',
      whereArgs: [trip.id],
    );
  }

  // marca uma viagem como deletada logicamente e sinaliza para sincronização de exclusão com o servidor
  Future<int> markAsDeleted(String id) async {
    final db = await AppDatabase().database;
    return await db.update('trips', {'is_deleted': 1, 'is_synced': 0}, where: 'id = ?', whereArgs: [id]);
  }

  // atualiza apenas o status de sincronização de uma viagem
  Future<int> updateSyncStatus(String id, int isSynced) async {
    final db = await AppDatabase().database;
    return await db.update('trips', {'is_synced': isSynced}, where: 'id = ?', whereArgs: [id]);
  }

  // exclui permanentemente o registro de uma viagem do banco local
  Future<int> deleteTripHard(String id) async {
    final db = await AppDatabase().database;
    return await db.delete('trips', where: 'id = ?', whereArgs: [id]);
  }
}
