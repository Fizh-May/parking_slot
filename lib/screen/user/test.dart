import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TestFirestorePage extends StatefulWidget {
  const TestFirestorePage({super.key});

  @override
  State<TestFirestorePage> createState() => _TestFirestorePageState();
}

class _TestFirestorePageState extends State<TestFirestorePage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _slotController = TextEditingController();

  Future<void> _submitData() async {
    if (_nameController.text.isEmpty || _slotController.text.isEmpty) return;

    await FirebaseFirestore.instance.collection('parking_test').add({
      'userName': _nameController.text,
      'slot': _slotController.text,
      'createdAt': Timestamp.now(),
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('✅ Data sent to Firebase')),
    );

    _nameController.clear();
    _slotController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Test Firebase POST'),
        backgroundColor: Colors.blueGrey,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'User name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _slotController,
              decoration: const InputDecoration(
                labelText: 'Parking slot',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _submitData,
                child: const Text('Send to Firebase'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
