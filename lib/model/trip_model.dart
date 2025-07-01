import 'package:cloud_firestore/cloud_firestore.dart';

class Trip {
  String id;
  String tripType;
  String title;
  String destination;
  DateTime startDate;
  DateTime endDate;
  String userId;
  List<String> collaborators;

  Trip({
    required this.id,
    required this.tripType,
    required this.title,
    required this.destination,
    required this.startDate,
    required this.endDate,
    required this.userId,
    required this.collaborators,
  });

  Trip copyWith({
    String? id,
    String? tripType,
    String? title,
    String? destination,
    DateTime? startDate,
    DateTime? endDate,
    String? userId,
    List<String>? collaborators,
  }) {
    return Trip(
      id: id ?? this.id,
      tripType: tripType ?? this.tripType,
      title: title ?? this.title,
      destination: destination ?? this.destination,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      userId: userId ?? this.userId,
      collaborators: collaborators ?? this.collaborators,
    );
  }

  Map<String, dynamic> toMap() => {
    'tripType': tripType,
    'title': title,
    'destination': destination,
    'startDate': Timestamp.fromDate(startDate),
    'endDate': Timestamp.fromDate(endDate),
    'userId': userId,
    'collaborators': collaborators,
  };

  factory Trip.fromMap(String id, Map<String, dynamic> map) => Trip(
    id: id,
    tripType: map['tripType'] ?? '',
    title: map['title'] ?? '',
    destination: map['destination'] ?? '',
    startDate: (map['startDate'] as Timestamp).toDate(),
    endDate: (map['endDate'] as Timestamp).toDate(),
    userId: map['userId'] ?? '',
    collaborators: List<String>.from(map['collaborators'] ?? []),
  );

}
