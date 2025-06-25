class Trip {
  String id;
  String title;
  String destination;
  DateTime startDate;
  DateTime endDate;
  String userId;
  List<String> collaborators;

  Trip({
    required this.id,
    required this.title,
    required this.destination,
    required this.startDate,
    required this.endDate,
    required this.userId,
    required this.collaborators,
  });

  Trip copyWith({
    String? id,
    String? title,
    String? destination,
    DateTime? startDate,
    DateTime? endDate,
    String? userId,
    List<String>? collaborators,
  }) {
    return Trip(
      id: id ?? this.id,
      title: title ?? this.title,
      destination: destination ?? this.destination,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      userId: userId ?? this.userId,
      collaborators: collaborators ?? this.collaborators,
    );
  }

  Map<String, dynamic> toMap() => {
    'title': title,
    'destination': destination,
    'startDate': startDate.toIso8601String(),
    'endDate': endDate.toIso8601String(),
    'userId': userId,
    'collaborators': collaborators,
  };

  factory Trip.fromMap(String id, Map<String, dynamic> map) => Trip(
    id: id,
    title: map['title'],
    destination: map['destination'],
    startDate: DateTime.parse(map['startDate']),
    endDate: DateTime.parse(map['endDate']),
    userId: map['userId'],
    collaborators: List<String>.from(map['collaborators'] ?? []),
  );

}
