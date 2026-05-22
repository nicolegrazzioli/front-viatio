class Trip {
  final String? id;
  final String userId;
  final String title;
  final String startDate;
  final String? endDate;
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
      'start_date': startDate,
      'end_date': endDate,
      'cover_type': coverType,
    };
  }

  factory Trip.fromMap(Map<String, dynamic> map) {
    return Trip(
      id: map['id']?.toString(),
      userId: map['user_id']?.toString() ?? '',
      title: map['title'],
      startDate: map['start_date'],
      endDate: map['end_date'],
      coverType: map['cover_type'],
    );
  }
}
