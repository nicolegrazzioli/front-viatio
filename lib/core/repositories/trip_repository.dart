import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../models/trip.dart';
import '../api/api_client.dart';
import '../dao/trip_dao.dart';

/// repositório que faz a mediação entre as chamadas da API de viagens e a persistência no banco local SQLite
class TripRepository {
  final TripDAO _dao = TripDAO();

  // formata um DateTime para string no formato YYYY-MM-DD
  String _toApiDate(DateTime date) {
    return "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
  }

  // converte uma string de data da API em DateTime
  DateTime _fromApiDate(String date) {
    try {
      return DateTime.parse(date);
    } catch (e) {
      return DateTime.now();
    }
  }

  /// insere uma nova viagem localmente e envia o pedido de criação para o servidor
  Future<String> insertTrip(Trip trip) async {
    final tripId = await _dao.insertTrip(trip, isSynced: 0);
    // Cria uma cópia com o ID gerado para envio
    final newTrip = Trip(
      id: tripId,
      userId: trip.userId,
      title: trip.title,
      startDate: trip.startDate,
      endDate: trip.endDate,
      coverType: trip.coverType,
    );
    _syncInsertTrip(newTrip);
    return tripId;
  }

  // envia as informações de uma viagem para a API e atualiza a flag is_synced local
  Future<void> _syncInsertTrip(Trip trip) async {
    try {
      await ApiClient.post('/trips', {
        'id': trip.id,
        'title': trip.title,
        'startDate': _toApiDate(trip.startDate),
        'endDate': trip.endDate != null ? _toApiDate(trip.endDate!) : null,
        'coverType': trip.coverType,
      });
      if (trip.id != null) {
        await _dao.updateSyncStatus(trip.id!, 1);
      }
    } catch (e) {
      debugPrint("Offline: Viagem salva apenas localmente. Erro API: $e");
    }
  }

  /// localiza e sincroniza todas as viagens modificadas ou deletadas offline com a API
  Future<void> syncUnsyncedTrips() async {
    final unsynced = await _dao.getUnsyncedTrips();
    for (var map in unsynced) {
      final id = map['id'] as String;
      if (map['is_deleted'] == 1) {
        await _syncDeleteTrip(id);
      } else {
        final trip = Trip.fromMap(map);
        await _syncInsertTrip(trip);
      }
    }
  }

  /// busca viagens na API para atualizar o banco local com tratamento offline e remove inconsistências deletadas
  Future<List<Trip>> getTripsByUser(String userId, {bool fetchApi = true}) async {
    if (fetchApi) {
      try {
        await syncUnsyncedTrips(); // PUSH: Empurra as ações offline pendentes antes de puxar novidades
        
        final response = await ApiClient.get('/trips');
        if (response.statusCode == 200) {
          final List<dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));
          final List<String> apiIds = [];
          
          for (var e in data) {
            final tripId = e['id'];
            apiIds.add(tripId);
            
            final localData = await _dao.getTripById(tripId);
            if (localData != null && localData['is_synced'] == 0) {
              continue; // Pula atualização para não sobrescrever dados editados/criados offline
            }
            
            final trip = Trip(
              id: tripId,
              userId: userId,
              title: e['title'],
              startDate: _fromApiDate(e['startDate']),
              endDate: e['endDate'] != null ? _fromApiDate(e['endDate']) : null,
              coverType: e['coverType'] ?? 'cidade',
            );
            
            if (localData != null) {
              await _dao.updateTrip(trip, isSynced: 1);
            } else {
              await _dao.insertTrip(trip, isSynced: 1);
            }
          }

          final localSynced = await _dao.getSyncedTrips(userId);
          for (var local in localSynced) {
            if (!apiIds.contains(local['id'])) {
              await _dao.deleteTripHard(local['id'] as String);
            }
          }
        }
      } catch (e) {
        debugPrint("Offline: Buscando viagens locais do SQLite. Erro API: $e");
      }
    }

    return await _dao.getTripsByUser(userId);
  }

  /// edita os dados de uma viagem localmente e envia a atualização para o servidor
  Future<int> updateTrip(Trip trip) async {
    int rows = await _dao.updateTrip(trip, isSynced: 0);
    _syncInsertTrip(trip);
    return rows;
  }

  /// deleta logicamente uma viagem localmente e solicita a exclusão na API
  Future<int> deleteTrip(String id) async {
    await _dao.markAsDeleted(id);
    _syncDeleteTrip(id);
    return 1;
  }

  // faz a chamada de remoção de viagem na API e limpa o registro de forma permanente no SQLite
  Future<void> _syncDeleteTrip(String id) async {
    try {
      await ApiClient.delete('/trips/$id');
      await _dao.deleteTripHard(id);
    } catch (e) {
      debugPrint("Offline: Deleção de viagem agendada. Erro API: $e");
    }
  }
}
