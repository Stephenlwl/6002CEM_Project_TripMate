import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/trip_service.dart';
import '../model/trip_model.dart';
import '../widgets/trip_card.dart';

class TripListPage extends StatefulWidget {
  const TripListPage({super.key});

  @override
  State<TripListPage> createState() => _TripListPageState();
}

class _TripListPageState extends State<TripListPage> {
  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      Provider.of<TripService>(context, listen: false).fetchTrips(user.uid);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tripService = Provider.of<TripService>(context);

    return Scaffold(
      appBar: AppBar(title: const Text('My Trips')),
      body: tripService.trips.isEmpty
          ? const Center(child: Text('No trips found'))
          : ListView.builder(
        itemCount: tripService.trips.length,
        itemBuilder: (context, index) {
          final trip = tripService.trips[index];
          return Stack(
            children: [
              TripCard(trip: trip),
              Positioned(
                top: 8,
                right: 8,
                child: IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => tripService.deleteTrip(trip.id),
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: const Text('New Trip'),
        backgroundColor: const Color(0xFFCCA8E9),
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) => AddTripDialog(),
          );
        },
      ),
    );
  }
}

class AddTripDialog extends StatefulWidget {
  @override
  State<AddTripDialog> createState() => _AddTripDialogState();
}

class _AddTripDialogState extends State<AddTripDialog> {
  final titleController = TextEditingController();
  final destinationController = TextEditingController();
  DateTime? startDate;
  DateTime? endDate;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Trip'),
      content: SingleChildScrollView(
        child: Column(
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(labelText: 'Trip Title'),
            ),
            TextField(
              controller: destinationController,
              decoration: const InputDecoration(labelText: 'Destination'),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () async {
                final tomorrow = DateTime.now().add(const Duration(days: 1));
                startDate = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime.now(),
                  lastDate: DateTime(2100),
                );
                setState(() {});
              },
              child: Text(startDate == null
                  ? 'Select Start Date'
                  : 'Start: ${startDate!.toLocal()}'.split(' ')[0]),
            ),
            ElevatedButton(
              onPressed: () async {
                endDate = await showDatePicker(
                  context: context,
                  initialDate: startDate!,
                  firstDate: startDate!,
                  lastDate: DateTime(2100),
                );
                setState(() {});
              },
              child: Text(endDate == null
                  ? 'Select End Date'
                  : 'End: ${endDate!.toLocal()}'.split(' ')[0]),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            final user = FirebaseAuth.instance.currentUser;
            if (user != null &&
                titleController.text.isNotEmpty &&
                destinationController.text.isNotEmpty &&
                startDate != null &&
                endDate != null) {
              final newTrip = Trip(
                id: '',
                title: titleController.text,
                destination: destinationController.text,
                startDate: startDate!,
                endDate: endDate!,
                userId: user.uid,
                collaborators: [user.uid],
              );
              Provider.of<TripService>(context, listen: false).addTrip(newTrip);
              Navigator.pop(context);
            }
          },
          child: const Text('Add'),
        ),
      ],
    );
  }
}
