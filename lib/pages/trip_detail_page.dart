import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../model/trip_model.dart';

class TripDetailPage extends StatelessWidget {
  final Trip trip;

  const TripDetailPage({super.key, required this.trip});

  int getCountdownDays(DateTime startDate) {
    return startDate.difference(DateTime.now()).inDays;
  }

  @override
  Widget build(BuildContext context) {
    final countdown = getCountdownDays(trip.startDate);
    final dateFormat = DateFormat('yyyy-MM-dd');

    return Scaffold(
      appBar: AppBar(title: const Text('Trip Details')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(trip.title, style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 10),
            Text("Destination: ${trip.destination}"),
            Text("Start: ${dateFormat.format(trip.startDate)}"),
            Text("End: ${dateFormat.format(trip.endDate)}"),
            const SizedBox(height: 10),
            Text("Collaborators: ${trip.collaborators.length}"),
            const SizedBox(height: 20),
            if (countdown >= 0)
              Text(
                "Trip starts in $countdown days",
                style: const TextStyle(color: Colors.teal, fontSize: 16),
              ),
            if (countdown < 0)
              const Text(
                "This trip has already started",
                style: TextStyle(color: Colors.grey),
              ),
            const SizedBox(height: 30),
            ElevatedButton.icon(
              icon: const Icon(Icons.checklist),
              label: const Text('Packing List'),
              onPressed: () {
                Navigator.pushNamed(context, '/packing', arguments: trip);
              },
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.schedule),
              label: const Text('Daily Schedule'),
              onPressed: () {
                Navigator.pushNamed(context, '/schedule', arguments: trip);
              },
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.note),
              label: const Text('Notes & Reminders'),
              onPressed: () {
                Navigator.pushNamed(context, '/notes', arguments: trip);
              },
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.map),
              label: const Text('Map'),
              onPressed: () {
                Navigator.pushNamed(context, '/map', arguments: trip);
              },
            ),
          ],
        ),
      ),
    );
  }
}
