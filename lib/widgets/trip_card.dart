import 'package:flutter/material.dart';
import '../model/trip_model.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class TripCard extends StatefulWidget {
  final Trip trip;
  const TripCard({super.key, required this.trip});

  @override
  State<TripCard> createState() => _TripCardState();
}

class _TripCardState extends State<TripCard> {
  String imageUrl = '';
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchCountryImage();
  }

  int getCountdownDays(DateTime startDate) {
    return startDate.difference(DateTime.now()).inDays;
  }

  Future<void> fetchCountryImage() async {
    final country = widget.trip.destination;
    final apiKey = '35193368-4e77f65738df9f6044ab18420';
    final url = 'https://pixabay.com/api/?key=$apiKey&q=$country&image_type=photo&orientation=horizontal&category=places';
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['hits'] != null && data['hits'].isNotEmpty) {
        setState(() {
          imageUrl = data['hits'][0]['webformatURL'];
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
      }
    } else {
      setState(() => isLoading = false);
    }
  }

  @override
  void didUpdateWidget(covariant TripCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.trip.destination != widget.trip.destination) {
      fetchCountryImage();
    }
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final countdown = getCountdownDays(widget.trip.startDate)+1;
    final startDate = widget.trip.startDate;
    final endDate = widget.trip.endDate;
    final dateFormat = DateFormat('dd-MM-yyyy');

    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(context, '/tripDetail', arguments: widget.trip);
      },
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 4,
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Trip Image
            isLoading
                ? const SizedBox(
                  height: 140,
                  child: Center(child: CircularProgressIndicator()),
                )
                : imageUrl.isNotEmpty
                ? Image.network(
                  imageUrl,
                  height: 140,
                  width: double.infinity,
                  fit: BoxFit.fitWidth,
                )
                : Container(
                  height: 120,
                  width: double.infinity,
                  color: Colors.grey[300],
                  child: const Center(child: Icon(Icons.image_not_supported)),
                ),

            // Trip Info
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.trip.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.place,
                        size: 14,
                        color: Colors.orangeAccent,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          widget.trip.destination,
                          style: const TextStyle(
                            color: Colors.black87,
                            fontSize: 14,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.travel_explore,
                        size: 14,
                        color: Colors.orangeAccent,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          widget.trip.tripType,
                          style: const TextStyle(
                            color: Colors.black87,
                            fontSize: 14,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.date_range,
                        size: 14,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${dateFormat.format(widget.trip.startDate)} → ${dateFormat.format(widget.trip.endDate)}',
                        style: const TextStyle(
                          color: Colors.black45,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.group, size: 14, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(
                        '${widget.trip.collaborators.length} collaborator(s)',
                        style: const TextStyle(
                          color: Colors.black45,
                          fontSize: 12,
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
                          now.isBefore(endDate.add(const Duration(days: 1))))
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
                      else if (countdown <= 1 && startDate != now)
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
      ),
    );
  }
}
