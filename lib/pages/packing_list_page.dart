import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../model/trip_model.dart';
import '../model/packing_item_model.dart';

class PackingListPage extends StatefulWidget {
  final Trip trip;
  const PackingListPage({super.key, required this.trip});

  @override
  State<PackingListPage> createState() => _PackingListPageState();
}

class _PackingListPageState extends State<PackingListPage> {
  final TextEditingController _controller = TextEditingController();
  List<PackingItem> items = [];

  @override
  void initState() {
    super.initState();
    _loadPackingItems();
  }

  // fetching trips data
  Future<void> _loadPackingItems() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('trips')
        .doc(widget.trip.id)
        .collection('packing')
        .get();

    final loadedItems = snapshot.docs.map((doc) {
      final data = doc.data();
      return PackingItem(
        id: doc.id,
        name: data['name'],
        isPacked: data['isPacked'] ?? false,
      );
    }).toList();

    setState(() => items = loadedItems);
  }

  // save items to trips table db
  Future<void> _addItem() async {
    final text = _controller.text.trim();
    if (text.isNotEmpty) {
      final docRef = await FirebaseFirestore.instance
          .collection('trips')
          .doc(widget.trip.id)
          .collection('packing')
          .add({'name': text, 'isPacked': false});

      setState(() {
        items.add(PackingItem(id: docRef.id, name: text, isPacked: false));
        _controller.clear();
      });
    }
  }

  // save the packed toggle to db
  Future<void> _togglePacked(PackingItem item, bool value) async {
    await FirebaseFirestore.instance
        .collection('trips')
        .doc(widget.trip.id)
        .collection('packing')
        .doc(item.id)
        .update({'isPacked': value});

    setState(() {
      item.isPacked = value;
    });
  }

  // delete the items from trips db
  Future<void> _removeItem(PackingItem item) async {
    await FirebaseFirestore.instance
        .collection('trips')
        .doc(widget.trip.id)
        .collection('packing')
        .doc(item.id)
        .delete();

    setState(() => items.remove(item));
  }

  // body interface
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Packing List')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _controller,
              decoration: InputDecoration(
                labelText: 'Add item',
                suffixIcon: IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: _addItem,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: ListView.builder(
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final item = items[index];
                  return Dismissible(
                    key: Key(item.id),
                    background: Container(color: Colors.red),
                    onDismissed: (_) => _removeItem(item),
                    child: ListTile(
                      title: Text(item.name),
                      trailing: Checkbox(
                        value: item.isPacked,
                        onChanged: (val) => _togglePacked(item, val!),
                      ),
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
