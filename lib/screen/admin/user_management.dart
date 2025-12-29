import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserManagement extends StatelessWidget {
  const UserManagement({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('User Management',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
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
          return ListView.builder(
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundImage: NetworkImage(user['photoURL'] ?? ''),
                ),
                title: Text(user['displayName'] ?? user['email']),
                subtitle: Text(user['email']),
                trailing: PopupMenuButton<String>(
                  onSelected: (value) {
                    // Handle user actions
                  },
                  itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                    const PopupMenuItem<String>(
                      value: 'view_history',
                      child: Text('View History'),
                    ),
                    const PopupMenuItem<String>(
                      value: 'toggle_active',
                      child: Text('Toggle Active'),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
