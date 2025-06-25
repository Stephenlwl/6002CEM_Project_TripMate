import 'package:flutter/material.dart';
import '../model/packing_item_model.dart';
import '../model/trip_model.dart';

class PackingItemTile extends StatelessWidget {
  final Trip trip;
  final PackingItem item;
  final ValueChanged<bool?> onChanged;

  const PackingItemTile({
    super.key,
    required this.trip,
    required this.item,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        Navigator.pushNamed(context, '/packing', arguments: trip);
      },
      child: ListTile(
        title: Text(item.name),
        trailing: Checkbox(
          value: item.isPacked,
          onChanged: onChanged,
        ),
      ),
    );
  }
}
