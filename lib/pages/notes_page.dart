import 'package:flutter/material.dart';
import '../model/trip_model.dart';

class NotesPage extends StatefulWidget {
  final Trip trip;

  const NotesPage({super.key, required this.trip});

  @override
  State<NotesPage> createState() => _NotesPageState();
}

class _NotesPageState extends State<NotesPage> {
  final List<String> notes = [];
  final TextEditingController _noteController = TextEditingController();

  void _addNote() {
    final text = _noteController.text.trim();
    if (text.isNotEmpty) {
      setState(() {
        notes.add(text);
        _noteController.clear();
      });
    }
  }

  void _removeNote(int index) {
    setState(() => notes.removeAt(index));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notes & Reminders')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _noteController,
              decoration: InputDecoration(
                labelText: 'Enter note or reminder',
                suffixIcon: IconButton(
                  icon: const Icon(Icons.add_alert),
                  onPressed: _addNote,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: ListView.builder(
                itemCount: notes.length,
                itemBuilder: (context, index) {
                  return Dismissible(
                    key: Key(notes[index]),
                    background: Container(color: Colors.redAccent),
                    onDismissed: (_) => _removeNote(index),
                    child: ListTile(
                      leading: const Icon(Icons.note),
                      title: Text(notes[index]),
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
