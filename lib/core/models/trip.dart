import '../utils/date_helpers.dart';

class Trip {
  final String? id;
  final String userId;
  final String title;
  final DateTime startDate;
  final DateTime? endDate;
  final String coverType;

  Trip({
    this.id,
    required this.userId,
    required this.title,
    required this.startDate,
    this.endDate,
    required this.coverType,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'title': title,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate?.toIso8601String(),
      'cover_type': coverType,
    };
  }

  factory Trip.fromMap(Map<String, dynamic> map) {
    return Trip(
      id: map['id']?.toString(),
      userId: map['user_id']?.toString() ?? '',
      title: map['title'],
      startDate: DateHelpers.parseDate(map['start_date']) ?? DateTime.now(),
      endDate: DateHelpers.parseDate(map['end_date']),
      coverType: map['cover_type'],
    );
  }
}
