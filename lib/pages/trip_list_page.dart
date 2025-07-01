import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:country_state_picker/country_state_picker.dart';
import '../services/trip_service.dart';
import '../model/trip_model.dart';
import '../widgets/trip_card.dart';

class TripListPage extends StatefulWidget {
  const TripListPage({super.key});

  @override
  State<TripListPage> createState() => _TripListPageState();
}

class _TripListPageState extends State<TripListPage> {

  String selectedFilter = 'All';
  final List<String> tripCategories = [
    'All',
    'Family Vacation',
    'Friends Trip',
    'Work Trip',
    'Weekend Getaway',
    'Backpacking Adventure',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null && user.uid.isNotEmpty) {
        await Provider.of<TripService>(
          context,
          listen: false,
        ).fetchTrips(user.uid);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final tripService = Provider.of<TripService>(context);

    final filteredTrips = selectedFilter == 'All'
        ? tripService.trips
        : tripService.trips
        .where((trip) => trip.tripType == selectedFilter)
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Trips'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (context.mounted) {
                Navigator.of(context).pushReplacementNamed('/');
              }
            },
          ),
        ],
      ),
      body: tripService.isLoading
          ? const SizedBox(
        height: 200,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 12),
              Text(
                'Loading your travel record, please be patient...',
                style: TextStyle(fontSize: 14),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      )
          : Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Text(
                  'Filter by:',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: selectedFilter,
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade100,
                    ),
                    items: tripCategories.map((category) {
                      return DropdownMenuItem<String>(
                        value: category,
                        child: Text(category),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedFilter = value!;
                      });
                    },
                  ),
                ),
              ],
            ),
          ),

          if (filteredTrips.isEmpty)
            const Expanded(
                child: Center(child: Text('No trips found')))
          else
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: GridView.builder(
                  itemCount: filteredTrips.length,
                  gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 15,
                    mainAxisSpacing: 15,
                    childAspectRatio: 0.75,
                  ),
                  itemBuilder: (context, index) {
                    final trip = filteredTrips[index];
                    return Stack(
                      children: [
                        TripCard(trip: trip),
                        Positioned(
                          top: 145,
                          right: 8,
                          child: IconButton(
                            icon: const Icon(
                              Icons.delete_outline_rounded,
                              color: Colors.red,
                            ),
                            onPressed: () =>
                                _confirmDelete(context, trip.id),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
        ],
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

  void _confirmDelete(BuildContext context, String tripId) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Delete Trip Record?"),
        content: const Text("Are you sure you want to delete this trip record?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context); // Close the dialog
              try {
                await Provider.of<TripService>(context, listen: false)
                    .deleteTrip(tripId);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Trip deleted successfully"),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("Failed to delete trip: $e"),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text(
              "Delete",
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
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
  String country = '';
  String state = '';
  DateTime? startDate;
  DateTime? endDate;

  final List<String> tripType = [
    'Family Vacation',
    'Friends Trip',
    'Work Trip',
    'Weekend Getaway',
    'Backpacking Adventure',
  ];
  String? selectedTripType;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text(
        'Add Trip',
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: 'Choose your trip type',
                border: OutlineInputBorder(),
              ),
              value: selectedTripType,
              items: tripType.map((title) {
                return DropdownMenuItem<String>(
                  value: title,
                  child: Text(title),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  selectedTripType = value;
                  titleController.text = value!;
                });
              },
            ),
            const SizedBox(height: 16),
            TextField(
              controller: titleController,
              decoration: const InputDecoration(
                labelText: 'Trip Title',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.title),
              ),
            ),
            const SizedBox(height: 16),
            CountryStatePicker(
              onCountryChanged: (value) => setState(() => country = value),
              onStateChanged: (value) => setState(() => state = value),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              icon: const Icon(Icons.date_range),
              onPressed: () async {
                final tomorrow = DateTime.now().add(const Duration(days: 1));
                final picked = await showDatePicker(
                  context: context,
                  initialDate: tomorrow,
                  firstDate: tomorrow,
                  lastDate: DateTime(2100),
                );
                if (picked != null) setState(() => startDate = picked);
              },
              label: Text(
                startDate == null
                    ? 'Select Start Date'
                    : 'Start: ${startDate!.toLocal().toString().split(' ')[0]}',
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFC3BEF0),
                foregroundColor: Colors.black,
              ),
            ),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              icon: const Icon(Icons.date_range),
              onPressed: startDate == null
                  ? null
                  : () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: startDate!,
                  firstDate: startDate!,
                  lastDate: DateTime(2100),
                );
                if (picked != null) setState(() => endDate = picked);
              },
              label: Text(
                endDate == null
                    ? 'Select End Date'
                    : 'End: ${endDate!.toLocal().toString().split(' ')[0]}',
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFDEFCF9),
                foregroundColor: Colors.black,
              ),
            ),
            const SizedBox(height: 10),
            if (country.isNotEmpty && state.isNotEmpty)
              Text(
                'Location: $country, $state',
                style: const TextStyle(color: Colors.black54),
              )
            else if (country.isNotEmpty)
              Text(
                'Location:  $country',
                style: const TextStyle(color: Colors.black54),
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
                country.isNotEmpty &&
                state.isNotEmpty &&
                startDate != null &&
                endDate != null) {
              final newTrip = Trip(
                id: '',
                tripType: selectedTripType.toString(),
                title: titleController.text,
                destination: '$country, $state',
                startDate: startDate!,
                endDate: endDate!,
                userId: user.uid,
                collaborators: [user.uid],
              );
              Provider.of<TripService>(context, listen: false)
                  .addTrip(newTrip);
              Navigator.pop(context);
            } else if (user != null &&
                titleController.text.isNotEmpty &&
                country.isNotEmpty &&
                startDate != null &&
                endDate != null) {
              final newTrip = Trip(
                id: '',
                tripType: selectedTripType.toString(),
                title: titleController.text,
                destination: country,
                startDate: startDate!,
                endDate: endDate!,
                userId: user.uid,
                collaborators: [user.uid],
              );
              Provider.of<TripService>(context, listen: false)
                  .addTrip(newTrip);
              Navigator.pop(context);
            }
          },
          child: const Text('Add'),
        ),
      ],
    );
  }
}
