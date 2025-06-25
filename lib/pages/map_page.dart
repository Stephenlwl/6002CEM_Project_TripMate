import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../model/trip_model.dart';

class MapPage extends StatefulWidget {
  final Trip trip;

  const MapPage({super.key, required this.trip});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  final List<Marker> _markers = [];
  final MapController _mapController = MapController();

  Future<void> _loadPins() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('trips')
        .doc(widget.trip.id)
        .collection('locations')
        .get();

    final loadedMarkers = snapshot.docs.map((doc) {
      final data = doc.data();
      return Marker(
        point: LatLng(data['lat'], data['lng']),
        width: 30,
        height: 30,
        child: const Icon(Icons.location_pin, color: Colors.red, size: 30),
      );
    }).toList();

    setState(() => _markers.addAll(loadedMarkers));
  }

  Future<void> _addPin(LatLng point) async {
    await FirebaseFirestore.instance
        .collection('trips')
        .doc(widget.trip.id)
        .collection('locations')
        .add({
      'lat': point.latitude,
      'lng': point.longitude,
    });

    setState(() {
      _markers.add(
        Marker(
          point: point,
          width: 30,
          height: 30,
          child: const Icon(Icons.location_pin, color: Colors.red, size: 30),
        ),
      );
    });
  }

  @override
  void initState() {
    super.initState();
    _loadPins();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Offline Map')),
      body: FlutterMap(
        mapController: _mapController,
        options: MapOptions(
          initialCenter: LatLng(5.4164, 100.3327),
          initialZoom: 13.0,
          onTap: (tapPosition, latlng) => _addPin(latlng),
        ),
        children: [
          TileLayer(
            urlTemplate: "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
            subdomains: ['a', 'b', 'c'],
          ),
          MarkerLayer(markers: _markers),
        ],
      ),
    );
  }
}
