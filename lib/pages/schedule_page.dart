import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../model/trip_model.dart';

class SchedulePage extends StatefulWidget {
  final Trip trip;
  const SchedulePage({super.key, required this.trip});

  @override
  State<SchedulePage> createState() => _SchedulePageState();
}

class _SchedulePageState extends State<SchedulePage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _timeController = TextEditingController();
  List<Map<String, dynamic>> activities = [];

  @override
  void initState() {
    super.initState();
    _loadActivities();
  }

  Future<void> _loadActivities() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('trips')
        .doc(widget.trip.id)
        .collection('schedule')
        .orderBy('time')
        .get();

    final loadedActivities = snapshot.docs.map((doc) {
      final data = doc.data();
      return {
        'id': doc.id,
        'name': data['name'],
        'time': data['time']
      };
    }).toList();

    setState(() => activities = loadedActivities);
  }

  Future<void> _addActivity() async {
    final name = _nameController.text.trim();
    final time = _timeController.text.trim();
    if (name.isNotEmpty && time.isNotEmpty) {
      final docRef = await FirebaseFirestore.instance
          .collection('trips')
          .doc(widget.trip.id)
          .collection('schedule')
          .add({'name': name, 'time': time});

      setState(() {
        activities.add({'id': docRef.id, 'name': name, 'time': time});
        _nameController.clear();
        _timeController.clear();
      });
    }
  }

  Future<void> _removeActivity(String id) async {
    await FirebaseFirestore.instance
        .collection('trips')
        .doc(widget.trip.id)
        .collection('schedule')
        .doc(id)
        .delete();

    setState(() => activities.removeWhere((activity) => activity['id'] == id));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Schedule')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Activity Name'),
            ),
            TextField(
              controller: _timeController,
              decoration: const InputDecoration(labelText: 'Time (e.g. 10:00 AM)'),
            ),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              icon: const Icon(Icons.add),
              label: const Text('Add Activity'),
              onPressed: _addActivity,
            ),
            const SizedBox(height: 10),
            Expanded(
              child: ListView.builder(
                itemCount: activities.length,
                itemBuilder: (context, index) {
                  final activity = activities[index];
                  return Dismissible(
                    key: Key(activity['id']),
                    background: Container(color: Colors.red),
                    onDismissed: (_) => _removeActivity(activity['id']),
                    child: ListTile(
                      leading: const Icon(Icons.schedule),
                      title: Text(activity['name']),
                      subtitle: Text(activity['time']),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
