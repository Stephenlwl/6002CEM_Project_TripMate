import 'package:flutter/material.dart';
import '../model/activity_model.dart';
import '../model/trip_model.dart';

class ActivityTile extends StatelessWidget {
  final Trip trip;
  final Activity activity;

  const ActivityTile({
    super.key,
    required this.trip,
    required this.activity,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        Navigator.pushNamed(context, '/schedule', arguments: trip);
      },
      child: ListTile(
        title: Text(activity.name),
        subtitle: Text(activity.time),
        leading: const Icon(Icons.schedule),
      ),
    );
  }
}
