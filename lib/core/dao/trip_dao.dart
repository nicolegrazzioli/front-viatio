import 'dart:convert';
import 'package:uuid/uuid.dart';
import '../models/trip.dart';
import '../api/api_client.dart';
import '../database/me_app_database.dart';

class TripDAO {
  final _uuid = const Uuid();

  String _toApiDate(String date) {
    final parts = date.split('/');
    if (parts.length == 3) {
      return "${parts[2]}-${parts[1]}-${parts[0]}";
    }
    return date;
  }

  String _fromApiDate(String date) {
    final parts = date.split('-');
    if (parts.length == 3) {
      return "${parts[2]}/${parts[1]}/${parts[0]}";
    }
    return date;
  }

  Future<String> insertTrip(Trip trip) async {
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

    await db.insert('trips', newTrip.toMap());

    // Sincroniza com a API sem bloquear o retorno
    _syncInsertTrip(newTrip);

    return tripId;
  }

  Future<void> _syncInsertTrip(Trip trip) async {
    try {
      await ApiClient.post('/trips', {
        'id': trip.id,
        'title': trip.title,
        'startDate': _toApiDate(trip.startDate),
        'endDate': trip.endDate != null ? _toApiDate(trip.endDate!) : null,
        'coverType': trip.coverType,
      });
    } catch (e) {
      print("Offline: Viagem salva apenas localmente. Erro API: $e");
    }
  }

  Future<List<Trip>> getTripsByUser(String userId) async {
    final db = await AppDatabase().database;
    
    // 1. Tentar buscar da API para atualizar o banco local
    try {
      final response = await ApiClient.get('/trips');
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));
        
        // Limpa as viagens antigas e salva as novas da API
        await db.delete('trips', where: 'user_id = ?', whereArgs: [userId]);
        
        for (var e in data) {
          final trip = Trip(
            id: e['id'],
            userId: userId,
            title: e['title'],
            startDate: _fromApiDate(e['startDate']),
            endDate: e['endDate'] != null ? _fromApiDate(e['endDate']) : null,
            coverType: e['coverType'],
          );
          await db.insert('trips', trip.toMap());
        }
      }
    } catch (e) {
      print("Offline: Buscando viagens locais do SQLite. Erro API: $e");
    }

    // 2. Retornar os dados do banco local
    final List<Map<String, dynamic>> maps = await db.query(
      'trips',
      where: 'user_id = ?',
      whereArgs: [userId],
    );

    return List.generate(maps.length, (i) => Trip.fromMap(maps[i]));
  }

  Future<int> updateTrip(Trip trip) async {
    return 1;
  }

  Future<int> deleteTrip(String id) async {
    final db = await AppDatabase().database;
    await db.delete('trips', where: 'id = ?', whereArgs: [id]);

    try {
      await ApiClient.delete('/trips/$id');
    } catch (e) {
      print("Offline: Falha ao deletar viagem na API. Erro: $e");
    }
    return 1;
  }
}
