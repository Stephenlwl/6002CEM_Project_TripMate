import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_cancellable_tile_provider/flutter_map_cancellable_tile_provider.dart';
import 'package:latlong2/latlong.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import '../model/trip_model.dart';
import '../model/activity_model.dart';
import '../services/activity_service.dart';

class SchedulePage extends StatefulWidget {
  final Trip trip;
  const SchedulePage({Key? key, required this.trip}) : super(key: key);

  @override
  State<SchedulePage> createState() => _SchedulePageState();
}

class _SchedulePageState extends State<SchedulePage> {
  StreamSubscription<QuerySnapshot>? _activitySubscription;

  // Controllers and state
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _time = TextEditingController();
  final _address = TextEditingController();
  final _notes = TextEditingController();
  final MapController _map = MapController();

  String? _displayTime,
      _sortTime,
      _wikiImageUrl,
      _wikiDescription,
      _selectedCategory;
  double? _pickedLat, _pickedLng;
  bool _loadingWiki = false;
  Timer? _debounce;

  List<Map<String, dynamic>> _searchResults = [];

  final _categories = ['Meal', 'Hotel', 'Attraction', 'Transport', 'Others'];
  final Map<String, Color> categoryColors = {
    'Meal': Colors.orange,
    'Hotel': Colors.blue,
    'Attraction': Colors.green,
    'Transport': Colors.purple,
    'Others': Colors.grey,
  };

  // Date selection
  late final List<DateTime> _tripDates;
  late DateTime _selectedDate;
  int _selectedIndex = 0;
  String imageUrl = '';

  @override
  void initState() {
    super.initState();
    fetchCountryImage();
    _tripDates = _generateTripDates(widget.trip.startDate, widget.trip.endDate);
    _selectedDate = _tripDates.first;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchActivitiesByDate(_selectedDate);
    });
  }

  int getCountdownDays(DateTime startDate) {
    return startDate.difference(DateTime.now()).inDays;
  }

  List<DateTime> _generateTripDates(DateTime s, DateTime e) => List.generate(
    e.difference(s).inDays + 1,
    (i) => s.add(Duration(days: i)),
  );

  // Date selection handler
  void _onDateTap(int i) {
    setState(() {
      _selectedIndex = i;
      _selectedDate = _tripDates[i];
      _resetForm();
    });
    _fetchActivitiesByDate(_selectedDate);
  }

  // Clean up info
  void _resetForm() {
    _name.clear();
    _displayTime = null;
    _address.clear();
    _pickedLat = _pickedLng = null;
    _searchResults.clear();
    _wikiImageUrl = _wikiDescription = null;
    _selectedCategory = null;
  }

  Future<void> fetchCountryImage() async {
    final country = widget.trip.destination;
    final pixalbayApiKey = '35193368-4e77f65738df9f6044ab18420';
    final url =
        'https://pixabay.com/api/?key=$pixalbayApiKey&q=$country&image_type=photo&orientation=horizontal&category=places';
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['hits'] != null && data['hits'].isNotEmpty) {
        setState(() {
          imageUrl = data['hits'][0]['webformatURL'];
        });
      }
    }
  }

  // Load from provider
  void _fetchActivitiesByDate(DateTime date) {
    final dateFormat = DateFormat('dd-MM-yyyy').format(date);
    Provider.of<ActivityService>(
      context,
      listen: false,
    ).fetchActivities(widget.trip.id, dateFormat);
  }

  // Time picker
  Future<void> _pickTime() async {
    final t = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (t != null) {
      setState(() {
        _displayTime = t.format(context);
        _sortTime =
            '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
        _time.text = _displayTime!;
      });
    }
  }

  // Search with debounce to ensure results
  void _searchPlace(String q) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () async {
      if (q.isEmpty) return;
      // display the available relevant location as a selection from the nominatim openstreetmap api
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/search?q=$q&format=json&limit=10',
      );
      final resp = await http.get(url, headers: {'User-Agent': 'tripmate-app'});
      if (resp.statusCode == 200) {
        final results = List<Map<String, dynamic>>.from(json.decode(resp.body));
        if (mounted) setState(() => _searchResults = results);
      }
    });
  }

  // Place selection
  Future<void> _selectPlace(Map<String, dynamic> place) async {
    final lat = double.tryParse(place['lat']);
    final lng = double.tryParse(place['lon']);
    if (lat == null || lng == null) return;

    setState(() {
      _address.text = place['display_name'];
      _pickedLat = lat;
      _pickedLng = lng;
      _searchResults.clear();
      _loadingWiki = true;
      _wikiImageUrl = _wikiDescription = null;
    });

    //delay the map move until the widget is rendered
    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        _map.move(LatLng(lat, lng), 14);
      } catch (e) {
        debugPrint('MapController not ready: $e');
      }
    });

    await _fetchWikipediaData(place['display_name']);
    if (mounted) {
      setState(() => _loadingWiki = false);
    }
  }

  // Wikipedia fetch
  Future<void> _fetchWikipediaData(String name) async {
    final location = Uri.encodeComponent(name.split(',').first.trim());
    final url = Uri.parse(
      'https://en.wikipedia.org/api/rest_v1/page/summary/$location',
    );
    try {
      final resp = await http.get(url).timeout(const Duration(seconds: 5));
      if (resp.statusCode == 200) {
        final jsonW = json.decode(resp.body);

        if (mounted) {
          setState(() {
            _wikiDescription = jsonW['extract'];
            _wikiImageUrl =
                (jsonW['originalimage']?['source'] as String?) ??
                (jsonW['thumbnail']?['source'] as String?);
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _wikiDescription = 'No description available.';
            _wikiImageUrl = null;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _wikiDescription = 'Failed to load description.';
          _wikiImageUrl = null;
        });
      }
    }
  }

  // Add activity
  Future<void> _addActivity(ActivityService svc) async {
    if (!_formKey.currentState!.validate()) return;

    final a = Activity(
      id: '',
      name: _name.text.trim(),
      displayTime: _displayTime!,
      sortTime: _sortTime!,
      address: _address.text.trim(),
      date: DateFormat('dd-MM-yyyy').format(_selectedDate),
      notes: _notes.text.trim(),
      category: _selectedCategory ?? 'Others',
      latitude: _pickedLat,
      longitude: _pickedLng,
      imageUrl: _wikiImageUrl,
      description: _wikiDescription,
    );
    await svc.addActivity(widget.trip.id, a);

    _formKey.currentState!.reset();
    setState(() {
      _displayTime = _sortTime = null;
    });
    _resetForm();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _activitySubscription?.cancel();
    _name.dispose();
    _time.dispose();
    _address.dispose();
    _notes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final countdown = getCountdownDays(widget.trip.startDate)+1;
    final startDate = widget.trip.startDate;
    final endDate = widget.trip.endDate;
    final dateFormat = DateFormat('dd-MM-yyyy');
    final svc = Provider.of<ActivityService>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Trip Schedule'),
        backgroundColor: Colors.deepPurple.shade50,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Activity form & list in scroll view
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    Card(
                      elevation: 5,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Trip Title
                            Text(
                              widget.trip.title,
                              style: Theme.of(
                                context,
                              ).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.deepPurple.shade700,
                              ),
                            ),
                            const SizedBox(height: 16),

                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Trip Image
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child:
                                      imageUrl.isNotEmpty
                                          ? Image.network(
                                            imageUrl,
                                            height: 130,
                                            width: 120,
                                            fit: BoxFit.cover,
                                          )
                                          : Container(
                                            height: 130,
                                            width: 120,
                                            color: Colors.grey.shade200,
                                            child: const Center(
                                              child: Column(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  CircularProgressIndicator(),
                                                  SizedBox(height: 8),
                                                  Text(
                                                    'Loading...',
                                                    style: TextStyle(
                                                      fontSize: 10,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                ),
                                const SizedBox(width: 16),

                                // Trip Info
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          const Icon(
                                            Icons.travel_explore,
                                            color: Colors.orangeAccent,
                                            size: 18,
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            widget.trip.tripType,
                                            style: const TextStyle(
                                              fontSize: 16,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          const Icon(
                                            Icons.place,
                                            color: Colors.orangeAccent,
                                            size: 18,
                                          ),
                                          const SizedBox(width: 6),
                                          Expanded(
                                            child: Text(
                                              widget.trip.destination,
                                              style: const TextStyle(
                                                fontSize: 16,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          const Icon(
                                            Icons.date_range,
                                            color: Colors.teal,
                                            size: 18,
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            "${dateFormat.format(startDate)} → ${dateFormat.format(endDate)}",
                                            style: const TextStyle(
                                              fontSize: 14,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          const Icon(
                                            Icons.event,
                                            color: Colors.deepOrangeAccent,
                                            size: 18,
                                          ),
                                          const SizedBox(width: 6),
                                          if (countdown > 1)
                                            Text(
                                              "Starts in $countdown days",
                                              style: const TextStyle(
                                                fontSize: 12,
                                                color: Colors.green,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            )
                                          else if (now.isAfter(startDate) &&
                                              now.isBefore(
                                                endDate.add(
                                                  const Duration(days: 1),
                                                ),
                                              ))
                                            const Text(
                                              "Currently ongoing",
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.orange,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            )
                                          else if (now.isAfter(endDate))
                                            const Text(
                                              "Trip ended",
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.redAccent,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            )
                                          else if (countdown <= 1 &&
                                              startDate != now)
                                            Text(
                                              "Trip starts on Tomorrow!",
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.blueAccent,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 12),

                            // trip records date tabs
                            SizedBox(
                              height: 60,
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                itemCount: _tripDates.length,
                                itemBuilder: (_, i) {
                                  final d = _tripDates[i];
                                  final sel = i == _selectedIndex;
                                  return GestureDetector(
                                    onTap: () => _onDateTap(i),
                                    child: Container(
                                      width: 50,
                                      margin: const EdgeInsets.symmetric(
                                        horizontal: 5,
                                      ),
                                      decoration: BoxDecoration(
                                        color:
                                            sel
                                                ? Colors.deepPurple
                                                : Colors.grey.shade300,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      alignment: Alignment.center,
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            DateFormat('E').format(d),
                                            style: TextStyle(
                                              fontSize: 11,
                                              color:
                                                  sel
                                                      ? Colors.white
                                                      : Colors.black,
                                            ),
                                          ),
                                          Text(
                                            '${d.day}',
                                            style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.bold,
                                              color:
                                                  sel
                                                      ? Colors.white
                                                      : Colors.black,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Add activity card
                    Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const Text(
                                'Add New Activity',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 12),
                              // Name, time, address, etc.
                              TextFormField(
                                controller: _name,
                                decoration: const InputDecoration(
                                  labelText: 'Activity Name',
                                  prefixIcon: Icon(Icons.local_activity),
                                  border: OutlineInputBorder(),
                                ),
                                validator:
                                    (v) =>
                                        v == null || v.isEmpty
                                            ? 'Enter activity name'
                                            : null,
                              ),
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: _time,
                                readOnly: true,
                                onTap: _pickTime,
                                decoration: const InputDecoration(
                                  labelText: 'Time',
                                  prefixIcon: Icon(Icons.access_time),
                                  border: OutlineInputBorder(),
                                ),
                                validator:
                                    (v) =>
                                        v == null || v.isEmpty
                                            ? 'Select time'
                                            : null,
                              ),
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: _address,
                                onChanged: _searchPlace,
                                decoration: const InputDecoration(
                                  labelText: 'Location',
                                  prefixIcon: Icon(Icons.location_on),
                                  border: OutlineInputBorder(),
                                ),
                                validator:
                                    (v) =>
                                        v == null || v.isEmpty
                                            ? 'Select location'
                                            : null,
                              ),
                              if (_searchResults.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                ConstrainedBox(
                                  constraints: const BoxConstraints(
                                    maxHeight: 180,
                                  ),
                                  child: ListView.separated(
                                    shrinkWrap: true,
                                    itemCount: _searchResults.length,
                                    separatorBuilder:
                                        (_, __) => const Divider(height: 1),
                                    itemBuilder: (_, idx) {
                                      final pl = _searchResults[idx];
                                      return ListTile(
                                        title: Text(pl['display_name']),
                                        onTap: () => _selectPlace(pl),
                                      );
                                    },
                                  ),
                                ),
                              ],
                              const SizedBox(height: 12),
                              if (_pickedLat != null)
                                SizedBox(
                                  height: 200,
                                  child: FlutterMap(
                                    mapController: _map,
                                    options: MapOptions(
                                      initialCenter: LatLng(
                                        _pickedLat!,
                                        _pickedLng!,
                                      ),
                                      initialZoom: 14,
                                    ),
                                    children: [
                                      TileLayer(
                                        urlTemplate:
                                            'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                        tileProvider:
                                            CancellableNetworkTileProvider(),
                                        userAgentPackageName:
                                            'com.example.tripmate_application',
                                      ),
                                      MarkerLayer(
                                        markers: [
                                          Marker(
                                            point: LatLng(
                                              _pickedLat!,
                                              _pickedLng!,
                                            ),
                                            width: 40,
                                            height: 40,
                                            child: const Icon(
                                              Icons.location_pin,
                                              color: Colors.red,
                                              size: 40,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              const SizedBox(height: 12),
                              if (_loadingWiki)
                                Center(
                                  child: Column(
                                    children: const [
                                      CircularProgressIndicator(),
                                      SizedBox(height: 8),
                                      Text(
                                        'The description and image is loading...',
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ),
                                ),
                              if (_wikiImageUrl != null)
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.network(
                                    _wikiImageUrl!,
                                    height: 180,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              const SizedBox(height: 8),
                              if (_wikiDescription != null)
                                Text(
                                  _wikiDescription!,
                                  textAlign: TextAlign.justify,
                                  style: const TextStyle(fontSize: 14),
                                ),
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: _notes,
                                decoration: const InputDecoration(
                                  labelText: 'Notes (Optional)',
                                  prefixIcon: Icon(Icons.note_alt_sharp),
                                  border: OutlineInputBorder(),
                                ),
                              ),
                              const SizedBox(height: 12),
                              DropdownButtonFormField<String>(
                                value: _selectedCategory,
                                decoration: const InputDecoration(
                                  labelText: 'Category',
                                  prefixIcon: Icon(Icons.category),
                                  border: OutlineInputBorder(),
                                ),
                                items:
                                    _categories
                                        .map(
                                          (context) => DropdownMenuItem(
                                            value: context,
                                            child: Text(context),
                                          ),
                                        )
                                        .toList(),
                                onChanged:
                                    (v) =>
                                        setState(() => _selectedCategory = v),
                                validator:
                                    (v) => v == null ? 'Select category' : null,
                              ),
                              const SizedBox(height: 24),
                              ElevatedButton.icon(
                                icon: const Icon(Icons.add),
                                label: const Text('Add Activity'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.deepPurple.shade50,
                                  foregroundColor: Colors.black87,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                    horizontal: 20,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                onPressed: () => _addActivity(svc),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Activities list
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "Schedule – ${DateFormat('dd MMM yyyy').format(_selectedDate)}",
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Consumer<ActivityService>(
                      builder: (context, svc, _) {
                        final activities = svc.activities;
                        return activities.isEmpty
                            ? const Center(
                              child: Text("No activities for this day."),
                            )
                            : ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: activities.length,
                              separatorBuilder:
                                  (_, __) => const SizedBox(height: 10),
                              itemBuilder: (_, idx) {
                                final a = activities[idx];
                                return Dismissible(
                                  key: Key(a.id),
                                  direction: DismissDirection.endToStart,
                                  confirmDismiss: (_) async {
                                    return await showDialog<bool>(
                                          context: context,
                                          builder:
                                              (ctx) => AlertDialog(
                                                title: const Text(
                                                  "Delete Activity?",
                                                ),
                                                content: const Text(
                                                  "Are you sure you want to delete this activity?",
                                                ),
                                                actions: [
                                                  TextButton(
                                                    onPressed:
                                                        () => Navigator.of(
                                                          ctx,
                                                        ).pop(false),
                                                    child: const Text("Cancel"),
                                                  ),
                                                  TextButton(
                                                    onPressed:
                                                        () => Navigator.of(
                                                          ctx,
                                                        ).pop(true),
                                                    child: const Text("Delete"),
                                                  ),
                                                ],
                                              ),
                                        ) ??
                                        false;
                                  },
                                  onDismissed: (_) async {
                                    await svc.deleteActivity(
                                      widget.trip.id,
                                      a.id,
                                    );
                                    _fetchActivitiesByDate(_selectedDate);
                                  },
                                  background: Container(
                                    alignment: Alignment.centerRight,
                                    padding: const EdgeInsets.only(right: 20),
                                    decoration: BoxDecoration(
                                      color: Colors.red,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Icon(
                                      Icons.delete,
                                      color: Colors.white,
                                    ),
                                  ),
                                  child: Card(
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    elevation: 3,
                                    child: ListTile(
                                      leading: const Icon(
                                        Icons.place,
                                        color: Colors.purple,
                                      ),
                                      title: Text(
                                        '${a.displayTime} • ${a.name}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      subtitle: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(a.address),
                                          if (a.notes?.isNotEmpty == true)
                                            Text(
                                              'Note: ${a.notes}',
                                              style: const TextStyle(
                                                height: 1.4,
                                              ),
                                            ),
                                        ],
                                      ),
                                      trailing: Chip(
                                        label: Text(a.category ?? 'Misc'),
                                        backgroundColor:
                                            categoryColors[a.category] ??
                                            Colors.grey,
                                        labelStyle: const TextStyle(
                                          color: Colors.white,
                                        ),
                                      ),
                                      isThreeLine: a.notes?.isNotEmpty ?? false,
                                    ),
                                  ),
                                );
                              },
                            );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
