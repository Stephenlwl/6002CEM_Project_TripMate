import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../model/activity_model.dart';
import '../model/trip_model.dart';

class ActivityTile extends StatefulWidget {
  final Trip trip;
  final Activity activity;
  final Future<void> Function(Activity updatedActivity) onUpdate;
  final Future<void> Function(String activityId) onDelete;

  ActivityTile({
    super.key,
    required this.trip,
    required this.activity,
    required this.onUpdate,
    required this.onDelete,
  });

  @override
  State<ActivityTile> createState() => _ActivityTileState();
}

class _ActivityTileState extends State<ActivityTile> {
  late TextEditingController _time;
  String? _displayTime;
  String? _sortTime;

  final Map<String, Color> categoryColors = const {
    'Meal': Colors.orange,
    'Hotel': Colors.blue,
    'Attraction': Colors.green,
    'Transport': Colors.purple,
    'Others': Colors.grey,
  };

  @override
  void initState() {
    super.initState();
    _displayTime = widget.activity.displayTime;
    _sortTime = widget.activity.sortTime;
    _time = TextEditingController(text: _displayTime);
  }

  Future<void> _pickTime() async {
    final t = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (t != null) {
      final formatted = t.format(context);
      final sortable =
          '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
      setState(() {
        _displayTime = formatted;
        _sortTime = sortable;
        _time.text = formatted;
      });
    }
  }

  @override
  void dispose() {
    _time.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final formattedTime = _formatTime(widget.activity.displayTime);
    final icon = _getIconByCategory(widget.activity.category);
    final encodedAddress = Uri.encodeComponent(widget.activity.address);

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: InkWell(
        child: Row(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: widget.activity.imageUrl != null &&
                        widget.activity.imageUrl!.isNotEmpty
                        ? Image.network(
                      widget.activity.imageUrl!,
                      width: 120,
                      height: 100,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => const Icon(
                        Icons.image_not_supported,
                        size: 60,
                      ),
                    )
                        : Image.asset(
                      'assets/image_not_found.png',
                      width: 120,
                      height: 100,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: 120,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.visibility, size: 16, color: Colors.white),
                      label: const Text('View More', style: TextStyle(fontSize: 12)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurple.shade400,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        elevation: 2,
                      ),
                      onPressed: () {
                        // Replace this with your actual function
                        _showActivityDetails(widget.activity.id, context);
                      },
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Left: Icon and Activity Name
                        Expanded(
                          child: Row(
                            children: [
                              Icon(
                                icon,
                                color: categoryColors[widget.activity.category],
                                size: 20,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  widget.activity.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),

                        PopupMenuButton<String>(
                          icon: const Icon(Icons.more_vert),
                          onSelected: (value) {
                            if (value == 'edit') {
                              _showEditDialog(context);
                            } else if (value == 'delete') {
                              _confirmDelete(context);
                            }
                          },
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: 'edit',
                              child: Row(
                                children: [
                                  Icon(Icons.edit, color: Colors.blue),
                                  SizedBox(width: 8),
                                  Text('Edit'),
                                ],
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'delete',
                              child: Row(
                                children: [
                                  Icon(Icons.delete, color: Colors.red),
                                  SizedBox(width: 8),
                                  Text('Delete'),
                                ],
                              ),
                            ),
                          ],
                        )
                      ],
                    ),
                    Divider(),

                    const SizedBox(height: 8),
                    if (formattedTime != null && formattedTime.isNotEmpty)
                      Row(
                        children: [
                          const Text(
                            "Time: ",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(formattedTime),
                        ],
                      ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Address:",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          widget.activity.address,
                          style: const TextStyle(fontSize: 14, color: Colors.black87),
                        ),
                      ],
                    ),
                    if (widget.activity.address.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                icon: const Icon(
                                  Icons.map,
                                  color: Colors.white,
                                ),
                                label: const Text('Google Maps'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blueGrey.shade600,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  elevation: 3,
                                  textStyle: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                onPressed: () async {
                                  final googleMapsUrl =
                                      'https://www.google.com/maps/search/?api=1&query=$encodedAddress';
                                  if (await canLaunchUrl(
                                    Uri.parse(googleMapsUrl),
                                  )) {
                                    await launchUrl(
                                      Uri.parse(googleMapsUrl),
                                      mode: LaunchMode.externalApplication,
                                    );
                                  }
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton.icon(
                                icon: const Icon(
                                  Icons.navigation,
                                  color: Colors.white,
                                ),
                                label: const Text('Waze'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blueAccent.shade100,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  elevation: 3,
                                  textStyle: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                onPressed: () async {
                                  final wazeUrl =
                                      'https://waze.com/ul?q=$encodedAddress&navigate=yes';
                                  if (await canLaunchUrl(Uri.parse(wazeUrl))) {
                                    await launchUrl(
                                      Uri.parse(wazeUrl),
                                      mode: LaunchMode.externalApplication,
                                    );
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
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

  String? _formatTime(String rawTime) {
    try {
      final time = DateFormat.jm().parse(rawTime);
      return DateFormat('hh:mm a').format(time);
    } catch (e) {
      return rawTime;
    }
  }

  IconData _getIconByCategory(String? category) {
    switch (category?.toLowerCase()) {
      case 'meal':
        return Icons.restaurant;
      case 'hotel':
        return Icons.hotel;
      case 'attraction':
        return Icons.camera_alt;
      case 'transport':
        return Icons.directions_car;
      default:
        return Icons.location_on;
    }
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text("Delete Activity?"),
            content: const Text(
              "Are you sure you want to delete this activity?",
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Cancel"),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.pop(context);
                  try {
                    await widget.onDelete(widget.activity.id);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Activity deleted successfully"),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text("Failed to delete activity: $e"),
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

  Future<void> _showEditDialog(BuildContext context) async {
    final name = TextEditingController(text: widget.activity.name);
    final note = TextEditingController(text: widget.activity.notes);
    String selectedCategory = widget.activity.category ?? 'Others';

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder:
          (context) => Padding(
            padding: EdgeInsets.only(
              top: 16,
              left: 16,
              right: 16,
              bottom: MediaQuery.of(context).viewInsets.bottom + 16,
            ),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Edit Activity",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: name,
                    decoration: const InputDecoration(
                      labelText: "Activity Name",
                      prefixIcon: Icon(Icons.edit),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _time,
                    readOnly: true,
                    onTap: _pickTime,
                    decoration: const InputDecoration(
                      labelText: "Time",
                      prefixIcon: Icon(Icons.access_time),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: note,
                    decoration: const InputDecoration(
                      labelText: "Notes",
                      prefixIcon: Icon(Icons.note_alt_sharp),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: selectedCategory,
                    decoration: const InputDecoration(
                      labelText: "Category",
                      prefixIcon: Icon(Icons.category),
                      border: OutlineInputBorder(),
                    ),
                    items:
                        categoryColors.keys
                            .map(
                              (cat) => DropdownMenuItem(
                                value: cat,
                                child: Text(cat),
                              ),
                            )
                            .toList(),
                    onChanged: (value) => selectedCategory = value ?? 'Others',
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      OutlinedButton.icon(
                        icon: const Icon(Icons.close),
                        label: const Text("Cancel"),
                        onPressed: () => Navigator.pop(context),
                      ),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.save),
                        label: const Text("Save"),
                        onPressed: () async {
                          try {
                            final updated = widget.activity.copyWith(
                              name: name.text.trim(),
                              displayTime: _displayTime,
                              sortTime: _sortTime,
                              notes: note.text.trim(),
                              category: selectedCategory,
                            );
                            await widget.onUpdate(updated);
                            if (mounted) {
                              setState(
                                () {},
                              ); // refresh the tile with updated info
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    "Activity updated successfully",
                                  ),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            }
                            Navigator.pop(context);
                          } catch (e) {
                            Navigator.pop(context);
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    "Failed to update activity: $e",
                                  ),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          }
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
    );
  }
  Future<void> _showActivityDetails(String docId, BuildContext context) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.activity.imageUrl != null &&
                  widget.activity.imageUrl!.isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    widget.activity.imageUrl!,
                    height: 180,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                )
              else
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.asset(
                    'assets/image_not_found.png',
                    height: 180,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
              const SizedBox(height: 16),

              // Activity Name
              Text(
                widget.activity.name.isNotEmpty
                    ? widget.activity.name
                    : 'No Name',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),

              // Date & Time
              Row(
                children: [
                  const Icon(Icons.calendar_today, size: 16),
                  const SizedBox(width: 6),
                  Text(widget.activity.date),
                  const SizedBox(width: 16),
                  const Icon(Icons.access_time, size: 16),
                  const SizedBox(width: 6),
                  Text(widget.activity.displayTime),
                ],
              ),
              const SizedBox(height: 12),

              // Category
              Row(
                children: [
                  const Icon(Icons.category, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    widget.activity.category ?? 'Others',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Address
              if (widget.activity.address.isNotEmpty)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Address:",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.activity.address,
                      style: const TextStyle(color: Colors.black87),
                    ),
                  ],
                ),

              const SizedBox(height: 12),

              // Description
              if (widget.activity.description != null && widget.activity.description!.isNotEmpty)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Description:",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.activity.description!,
                      style: const TextStyle(color: Colors.black54),
                    ),
                  ],
                ),

              const SizedBox(height: 12),

              // Notes
              if (widget.activity.notes != null && widget.activity.notes!.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(top: 4),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.orange.shade200),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.note, size: 20, color: Colors.orange),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          widget.activity.notes!,
                          style: const TextStyle(color: Colors.black87),
                        ),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 20),

              // Action Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  OutlinedButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                    label: const Text('Close'),
                  ),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () {
                      _confirmDelete(context);
                      Navigator.pop(context);
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

}
