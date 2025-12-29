import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
class UsageHistory extends StatelessWidget {
  const UsageHistory({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Usage History',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('usage_history').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Error loading history'));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final history = snapshot.data!.docs;
          return ListView.builder(
            itemCount: history.length,
            itemBuilder: (context, index) {
              final record = history[index];
              return ListTile(
                title: Text('User: ${record['userId'] ?? 'Unknown'}'),
                subtitle: Text('Slot: ${record['slotId'] ?? 'Unknown'}'),
                trailing: Text(
                  '${(record['usageStartTime'] as Timestamp).toDate()} - ${(record['usageEndTime'] as Timestamp).toDate()}',
                ),
              );
            },
          );
        },
      ),
    );
  }
}