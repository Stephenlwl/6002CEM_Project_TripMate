import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../model/trip_model.dart';

class PackingItem {
  String id;
  String name;
  bool isPacked;

  PackingItem({
    required this.id,
    required this.name,
    this.isPacked = false,
  });
}

class PackingListPage extends StatefulWidget {
  final Trip trip;

  const PackingListPage({super.key, required this.trip});

  @override
  State<PackingListPage> createState() => _PackingListPageState();
}

class _PackingListPageState extends State<PackingListPage> {
  final TextEditingController _controller = TextEditingController();
  List<PackingItem> items = [];

  final List<String> templates = [
    'Passport',
    'Toothbrush',
    'Shampoo',
    'Phone Charger',
    'Sunscreen',
    'Identity Card',
    'Sim Card',
    'Camera',
    'Snacks',
    'Travel Pillow',
    'Pen',
    'Keys',
  ];

  @override
  void initState() {
    super.initState();
    _loadPackingItems();
  }

  Future<void> _loadPackingItems() async {
    final snapshot =
        await FirebaseFirestore.instance
            .collection('trips')
            .doc(widget.trip.id)
            .collection('packing')
            .get();

    final loadedItems =
        snapshot.docs.map((doc) {
          final data = doc.data();
          return PackingItem(
            id: doc.id,
            name: data['name'],
            isPacked: data['isPacked'] ?? false,
          );
        }).toList();

    setState(() => items = loadedItems);
  }

  Future<void> _addItem([String? text]) async {
    final itemText = (text ?? _controller.text).trim();
    if (itemText.isNotEmpty) {
      final docRef = await FirebaseFirestore.instance
          .collection('trips')
          .doc(widget.trip.id)
          .collection('packing')
          .add({
            'name': itemText,
            'isPacked': false,
          });

      setState(() {
        items.add(
          PackingItem(
            id: docRef.id,
            name: itemText,
            isPacked: false,
          ),
        );
      });
    }
  }

  Future<void> _togglePacked(PackingItem item, bool value) async {
    await FirebaseFirestore.instance
        .collection('trips')
        .doc(widget.trip.id)
        .collection('packing')
        .doc(item.id)
        .update({'isPacked': value});

    setState(() => item.isPacked = value);
  }

  Future<void> _removeItem(PackingItem item) async {
    await FirebaseFirestore.instance
        .collection('trips')
        .doc(widget.trip.id)
        .collection('packing')
        .doc(item.id)
        .delete();

    setState(() => items.remove(item));
  }

  void _sortItemsByPackedStatus() {
    setState(() {
      items.sort((a, b) => a.isPacked ? 1 : -1);
    });
  }

  void _sortItemsAlphabetically() {
    setState(() {
      items.sort((a, b) => a.name.compareTo(b.name));
    });
  }

  @override
  Widget build(BuildContext context) {
    final packedCount = items.where((item) => item.isPacked).length;
    final progress = items.isEmpty ? 0.0 : packedCount / items.length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Packing List'),
        actions: [
          IconButton(
            tooltip: "Sort A-Z",
            icon: const Icon(Icons.sort_by_alpha),
            onPressed: _sortItemsAlphabetically,
          ),
          IconButton(
            tooltip: "Sort by Packed",
            icon: const Icon(Icons.check_box),
            onPressed: _sortItemsByPackedStatus,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Progress Indicator
            LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              color: Colors.green,
              backgroundColor: Colors.grey.shade300,
            ),
            const SizedBox(height: 6),
            Text(
              '${(progress * 100).toStringAsFixed(0)}% Packed',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 16),

            // Input Card
            Card(
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    TextField(
                      controller: _controller,
                      decoration: const InputDecoration(
                        labelText: 'Item Name',
                        prefixIcon: Icon(Icons.add_box_outlined),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurple.shade50,
                        foregroundColor: Colors.black,
                        minimumSize: const Size.fromHeight(45),
                      ),
                      onPressed: () {
                        final itemText = _controller.text.trim().toLowerCase();
                        final isDuplicate = items.any(
                          (item) => item.name.trim().toLowerCase() == itemText,
                        );

                        if (itemText.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Item name cannot be empty"),
                            ),
                          );
                          return;
                        }

                        if (isDuplicate) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("This item is already in the list"),
                            ),
                          );
                          return;
                        }

                        _addItem();
                      },
                      icon: const Icon(Icons.add),
                      label: const Text('Add Item'),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Template Chips
            Align(
              alignment: Alignment.centerLeft,
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children:
                    templates.map((template) {
                      final isAlreadyAdded = items.any(
                        (item) =>
                            item.name.toLowerCase() == template.toLowerCase(),
                      );

                      return FilterChip(
                        label: Text(template),
                        backgroundColor:
                            isAlreadyAdded
                                ? Colors.grey.shade300
                                : Colors.deepPurple.shade50,
                        onSelected: (_) {
                          if (!isAlreadyAdded) {
                            _addItem(template);
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('“$template” already added'),
                              ),
                            );
                          }
                        },
                      );
                    }).toList(),
              ),
            ),

            const SizedBox(height: 20),

            // Packing Items List
            Expanded(
              child:
                  items.isEmpty
                      ? const Center(child: Text("No packing items yet."))
                      : ListView.builder(
                        itemCount: items.length,
                        itemBuilder: (context, index) {
                          final item = items[index];
                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            child: Dismissible(
                              key: Key(item.id),
                              direction: DismissDirection.endToStart,
                              background: Container(
                                alignment: Alignment.centerRight,
                                padding: const EdgeInsets.only(right: 20),
                                decoration: BoxDecoration(
                                  color: Colors.red,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.delete,
                                  color: Colors.white,
                                ),
                              ),
                              onDismissed: (_) => _removeItem(item),
                              child: Card(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                elevation: 2,
                                child: ListTile(
                                  leading: Checkbox(
                                    value: item.isPacked,
                                    onChanged:
                                        (val) => _togglePacked(item, val!),
                                  ),
                                  title: Text(
                                    item.name,
                                    style: TextStyle(
                                      decoration:
                                          item.isPacked
                                              ? TextDecoration.lineThrough
                                              : null,
                                    ),
                                  ),
                                ),
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
