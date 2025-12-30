import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'user_history.dart';

class UserManagement extends StatelessWidget {
  const UserManagement({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('User Management',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black)),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('users').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Error loading users'));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final users = snapshot.data!.docs;

          if (users.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.people, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'No users found',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundImage: user['photoURL'] != null && user['photoURL'].isNotEmpty
                        ? NetworkImage(user['photoURL'])
                        : null,
                    backgroundColor: Colors.blue[100],
                    child: user['photoURL'] == null || user['photoURL'].isEmpty
                        ? Icon(
                            Icons.person,
                            color: Colors.blue[700],
                          )
                        : null,
                  ),
                  title: Text(
                    user['displayName'] ?? user['email'] ?? 'Unknown User',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(user['email'] ?? ''),
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) => _handleUserAction(context, value, user),
                    itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                      const PopupMenuItem<String>(
                        value: 'view_history',
                        child: Row(
                          children: [
                            Icon(Icons.history, color: Colors.blue),
                            SizedBox(width: 8),
                            Text('View History Usage'),
                          ],
                        ),
                      ),
                      const PopupMenuItem<String>(
                        value: 'delete_user',
                        child: Row(
                          children: [
                            Icon(Icons.delete, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Delete User'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _handleUserAction(BuildContext context, String action, DocumentSnapshot user) {
    switch (action) {
      case 'view_history':
        _viewUserHistory(context, user);
        break;
      case 'delete_user':
        _deleteUser(context, user);
        break;
    }
  }

  void _viewUserHistory(BuildContext context, DocumentSnapshot user) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UserHistoryScreen(
          userId: user.id,
          userName: user['displayName'] ?? user['email'] ?? 'Unknown User',
        ),
      ),
    );
  }

  void _deleteUser(BuildContext context, DocumentSnapshot user) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete User'),
          content: Text(
            'Are you sure you want to delete "${user['displayName'] ?? user['email'] ?? 'this user'}"? '
            'This action cannot be undone and will remove all associated data.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop(); // Close dialog
                await _performDeleteUser(context, user);
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _performDeleteUser(BuildContext context, DocumentSnapshot user) async {
    try {
      // Show loading indicator
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Deleting user...')),
      );

      // Delete user document from Firestore
      await FirebaseFirestore.instance.collection('users').doc(user.id).delete();

      // Also delete any reservations associated with this user
      final reservations = await FirebaseFirestore.instance
          .collection('reservations')
          .where('userId', isEqualTo: user.id)
          .get();

      for (var reservation in reservations.docs) {
        await reservation.reference.delete();
      }

      // Also delete any usage history associated with this user
      final usageHistory = await FirebaseFirestore.instance
          .collection('usage_history')
          .where('userId', isEqualTo: user.id)
          .get();

      for (var history in usageHistory.docs) {
        await history.reference.delete();
      }

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('User "${user['displayName'] ?? user['email']}" deleted successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error deleting user: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
