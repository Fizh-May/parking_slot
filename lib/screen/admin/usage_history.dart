import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UsageHistory extends StatefulWidget {
  const UsageHistory({super.key});

  @override
  State<UsageHistory> createState() => _UsageHistoryState();
}

class _UsageHistoryState extends State<UsageHistory> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _searchType = 'user'; // 'user' or 'slot'

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: _searchType == 'user' ? 'Search by user name...' : 'Search by slot ID...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        setState(() {
                          _searchQuery = '';
                        });
                      },
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    filled: true,
                    fillColor: Colors.grey[100],
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value.toLowerCase();
                    });
                  },
                ),
                const SizedBox(height: 8),
                // Search Type Toggle
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _searchType = 'user';
                            _searchQuery = '';
                            _searchController.clear();
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _searchType == 'user' ? Colors.blue : Colors.grey[300],
                          foregroundColor: _searchType == 'user' ? Colors.white : Colors.black,
                        ),
                        child: const Text('Search by User'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _searchType = 'slot';
                            _searchQuery = '';
                            _searchController.clear();
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _searchType == 'slot' ? Colors.blue : Colors.grey[300],
                          foregroundColor: _searchType == 'slot' ? Colors.white : Colors.black,
                        ),
                        child: const Text('Search by Slot'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // History List
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('usage_history')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Center(child: Text('Error loading history'));
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final history = snapshot.data!.docs;

                // Filter history based on search
                final filteredHistory = _searchQuery.isEmpty
                    ? history
                    : history.where((record) {
                        if (_searchType == 'user') {
                          // For user search, we'll need to check user data
                          return true; // Will be filtered in the FutureBuilder
                        } else {
                          // For slot search
                          final slotId = record['slotId']?.toString().toLowerCase() ?? '';
                          return slotId.contains(_searchQuery);
                        }
                      }).toList();

                if (filteredHistory.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.history,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _searchQuery.isEmpty
                              ? 'No usage history available'
                              : 'No results found for "${_searchController.text}"',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.only(bottom: 16),
                  itemCount: filteredHistory.length,
                  itemBuilder: (context, index) {
                    final record = filteredHistory[index];
                    return FutureBuilder<DocumentSnapshot>(
                      future: FirebaseFirestore.instance.collection('users').doc(record['userId']).get(),
                      builder: (context, userSnapshot) {
                        if (userSnapshot.connectionState == ConnectionState.waiting) {
                          return const Card(
                            margin: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                            child: ListTile(
                              title: Text('Loading...'),
                              leading: CircularProgressIndicator(),
                            ),
                          );
                        }
                        if (userSnapshot.hasError) {
                          return Card(
                            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                            child: ListTile(
                              title: Text('User: ${record['userId'] ?? 'Unknown'}'),
                              subtitle: Text('Slot: ${record['slotId'] ?? 'Unknown'}'),
                            ),
                          );
                        }
                        final userData = userSnapshot.data;
                        final userName = userData?['displayName'] ?? record['userId'] ?? 'Unknown';

                        // Filter by user name if searching by user
                        if (_searchQuery.isNotEmpty && _searchType == 'user') {
                          if (!userName.toLowerCase().contains(_searchQuery)) {
                            return const SizedBox.shrink();
                          }
                        }

                        return Card(
                          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          child: ListTile(
                            leading: const Icon(
                              Icons.history,
                              color: Colors.blue,
                              size: 32,
                            ),
                            title: Text(
                              'User: $userName',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Slot: ${record['slotId'] ?? 'Unknown'}'),
                                Text(
                                  'Duration: ${_formatDuration((record['usageStartTime'] as Timestamp).toDate(), (record['usageEndTime'] as Timestamp).toDate())}',
                                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                                ),
                              ],
                            ),
                            trailing: Text(
                              _formatDateTime((record['timestamp'] as Timestamp).toDate()),
                              style: const TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
  }

  String _formatDuration(DateTime start, DateTime end) {
    final duration = end.difference(start);
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else {
      return '${minutes}m';
    }
  }
}