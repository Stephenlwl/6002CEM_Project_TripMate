class Activity {
  String id;
  String name;
  String displayTime;
  String sortTime;
  String address;
  String date;
  String? notes;
  String? category;
  double? latitude;
  double? longitude;
  String? imageUrl;
  String? description;

  Activity({
    required this.id,
    required this.name,
    required this.displayTime,
    required this.sortTime,
    required this.address,
    required this.date,
    this.notes,
    this.category,
    this.latitude,
    this.longitude,
    this.imageUrl,
    this.description,
  });

  Activity copyWith({
    String? id,
    String? name,
    String? displayTime,
    String? sortTime,
    String? address,
    String? date,
    String? notes,
    String? category,
    double? latitude,
    double? longitude,
    String? imageUrl,
    String? description,

  }) {
    return Activity(
      id: id ?? this.id,
      name: name ?? this.name,
      displayTime: displayTime ?? this.displayTime,
      sortTime:  sortTime ?? this.sortTime,
      address: address ?? this.address,
      date: date ?? this.date,
      notes: notes ?? this.notes,
      category: category ?? this.category,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      imageUrl: imageUrl ?? this.imageUrl,
      description: description ?? this.description,
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'displayTime': displayTime,
    'sortTime': sortTime,
    'address': address,
    'date': date,
    'notes': notes,
    'category': category,
    'latitude': latitude,
    'longitude': longitude,
    'imageUrl': imageUrl,
    'description': description,
  };

  factory Activity.fromMap(String id, Map<String, dynamic> map) => Activity(
    id: id,
    name: map['name'] ?? '',
    displayTime: map['displayTime'] ?? '',
    sortTime: map['sortTime'] ?? '',
    address: map['address'] ?? '',
    date: map['date'] ?? '',
    notes: map['notes'] ?? '',
    category: map['category'] ?? '',
    latitude: map['latitude'] ?? '',
    longitude: map['longitude'] ?? '',
    imageUrl: map['imageUrl'] ?? '',
    description: map['description'] ?? '',

  );

}