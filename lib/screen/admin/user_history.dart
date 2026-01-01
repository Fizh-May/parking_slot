import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserHistoryScreen extends StatelessWidget {
  final String userId;
  final String userName;

  const UserHistoryScreen({
    super.key,
    required this.userId,
    required this.userName,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          '$userName\'s History',
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.blue,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Container(
        color: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 10),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('usage_history')
                      .where('userId', isEqualTo: userId)
                      .orderBy('timestamp', descending: true)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return const Center(child: Text('Error loading history'));
                    }
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    // Check if snapshot.data is null or empty
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.history, size: 64, color: Colors.grey),
                            const SizedBox(height: 16),
                            Text(
                              'No usage history for $userName',
                              style: const TextStyle(fontSize: 18, color: Colors.grey),
                            ),
                          ],
                        ),
                      );
                    }

                    final history = snapshot.data!.docs;

                    return ListView.builder(
                      itemCount: history.length,
                      itemBuilder: (context, index) {
                        final record = history[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Usage Session',
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                          ),
                                          Text(
                                            userName,
                                            style: const TextStyle(fontSize: 12, color: Colors.black),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.green,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Text(
                                        'Completed',
                                        style: TextStyle(color: Colors.white, fontSize: 12),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    const Icon(Icons.local_parking, size: 16, color: Colors.grey),
                                    const SizedBox(width: 4),
                                    Text('Slot Name: ${record['slotName'] ?? record['slotId'] ?? 'Unknown'}'),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    const Icon(Icons.local_parking, size: 16, color: Colors.grey),
                                    const SizedBox(width: 4),
                                    Text('Slot ID: ${record['slotId'] ?? record['slotId'] ?? 'Unknown'}'),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    const Icon(Icons.access_time, size: 16, color: Colors.grey),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        'Start: ${_formatTimestamp(record['usageStartTime'])}',
                                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(Icons.access_time_filled, size: 16, color: Colors.grey),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        'End: ${_formatTimestamp(record['usageEndTime'])}',
                                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    const Icon(Icons.timer, size: 16, color: Colors.grey),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Duration: ${_formatDuration(record['usageStartTime'], record['usageEndTime'])}',
                                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDuration(dynamic startTimestamp, dynamic endTimestamp) {
    if (startTimestamp == null || endTimestamp == null) return 'Unknown';
    try {
      if (startTimestamp is Timestamp && endTimestamp is Timestamp) {
        final start = startTimestamp.toDate();
        final end = endTimestamp.toDate();
        final duration = end.difference(start);
        final hours = duration.inHours;
        final minutes = duration.inMinutes % 60;
        if (hours > 0) {
          return '${hours}h ${minutes}m';
        } else {
          return '${minutes}m';
        }
      }
      return 'Invalid Duration';
    } catch (e) {
      print('Error formatting duration: $e');
      return 'Invalid duration';
    }
  }

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return 'Unknown';
    try {
      if (timestamp is Timestamp) {
        final dateTime = timestamp.toDate();
        return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
      }
      return 'Invalid Timestamp';
    } catch (e) {
      print('Error formatting timestamp: $e');
      return 'Invalid date';
    }
  }
}
