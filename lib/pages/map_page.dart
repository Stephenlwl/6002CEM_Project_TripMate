import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../model/trip_model.dart';

class MapPage extends StatefulWidget {
  final Trip trip;

  const MapPage({super.key, required this.trip});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  final MapController _mapController = MapController();
  final List<Marker> _markers = [];

  static const LatLng _defaultCenter = LatLng(5.4164, 100.3327);

  final Map<String, Color> categoryColors = {
    'Meal': Colors.orange,
    'Hotel': Colors.blue,
    'Attraction': Colors.green,
    'Transport': Colors.purple,
    'Others': Colors.grey,
  };

  @override
  void initState() {
    super.initState();
    _initializeMap();
  }

  Future<void> _initializeMap() async {
    final location = '${widget.trip.destination}';
    final center = await _getCoordinatesFromLocation(location);

    _mapController.move(center, 12);
    _loadPins();
  }

  Future<LatLng> _getCoordinatesFromLocation(String location) async {
    final encodedLocation = Uri.encodeComponent(location);
    final url = Uri.parse('https://nominatim.openstreetmap.org/search?q=$encodedLocation&format=json&limit=1');

    try {
      final response = await http.get(url, headers: {
        'User-Agent': 'tripmate-app'
      });

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data != null && data.isNotEmpty) {
          final lat = double.tryParse(data[0]['lat']);
          final lon = double.tryParse(data[0]['lon']);
          if (lat != null && lon != null) {
            return LatLng(lat, lon);
          }
        }
      }
    } catch (e) {
      debugPrint('Geocoding error: $e');
    }

    // fallback to Penang
    return LatLng(5.4164, 100.3327);
  }

  Future<void> _loadPins() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('trips')
        .doc(widget.trip.id)
        .collection('schedule')
        .get();

    final loadedMarkers = snapshot.docs.map((doc) {
      final data = doc.data();
      final lat = data['latitude'];
      final lng = data['longitude'];

      if (lat == null || lng == null) return null;

      final category = data['category'] ?? 'Others';
      final color = categoryColors[category] ?? Colors.grey;

      return Marker(
        point: LatLng(lat, lng),
        width: 40,
        height: 40,
        child: GestureDetector(
          onTap: () => _showActivityDetails(doc.id, data),
          child: Icon(Icons.location_pin, size: 40, color: color),
        ),
      );
    }).whereType<Marker>().toList();

    setState(() => _markers.addAll(loadedMarkers));
  }

  Future<void> _showActivityDetails(String docId, Map<String, dynamic> data) async {
    await showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (data['imageUrl'] != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(data['imageUrl'], height: 180, width: double.infinity, fit: BoxFit.cover),
                ),
              const SizedBox(height: 12),
              Text(data['name'] ?? 'No name', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Row(children: [
                const Icon(Icons.calendar_today, size: 16),
                const SizedBox(width: 6),
                Text(data['date'] ?? 'No date'),
                const SizedBox(width: 12),
                const Icon(Icons.access_time, size: 16),
                const SizedBox(width: 6),
                Text(data['displayTime'] ?? 'No time'),
              ]),
              const SizedBox(height: 8),
              Row(children: [
                const Icon(Icons.category, size: 16),
                const SizedBox(width: 6),
                Text(data['category'] ?? 'Others', style: const TextStyle(fontWeight: FontWeight.bold)),
              ]),
              const SizedBox(height: 8),
              if (data['address'] != null)
                Text(data['address'], style: const TextStyle(color: Colors.black87)),
              const SizedBox(height: 8),
              if (data['description'] != null)
                Text(data['description'], style: const TextStyle(color: Colors.black54)),
              const SizedBox(height: 8),
              if (data['notes'] != null && data['notes'].toString().isNotEmpty)
                Text('Note: ${data['notes']}', style: const TextStyle(color: Colors.black87)),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ElevatedButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                    label: const Text('Close'),
                  ),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
                    onPressed: () async {
                      await FirebaseFirestore.instance
                          .collection('trips')
                          .doc(widget.trip.id)
                          .collection('schedule')
                          .doc(docId)
                          .delete();
                      Navigator.pop(context);
                      setState(() {
                        _markers.clear();
                      });
                      _loadPins();
                    },
                    icon: const Icon(Icons.delete),
                    label: const Text('Delete'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Trip Map')),
      body: FlutterMap(
        mapController: _mapController,
        options: MapOptions(
          initialCenter: _defaultCenter,
          initialZoom: 13.0,
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
            subdomains: const ['a', 'b', 'c'],
            userAgentPackageName: 'com.example.tripmate_application',
          ),
          MarkerLayer(markers: _markers),
        ],
      ),
    );
  }
}