import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserRequests extends StatelessWidget {
  const UserRequests({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('users').where('isActive', isEqualTo: false).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Error loading requests'));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final requests = snapshot.data!.docs;
          if (requests.isEmpty) {
            return const Center(
              child: Text(
                'No pending user requests',
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
            );
          }
          return ListView.builder(
            itemCount: requests.length,
            itemBuilder: (context, index) {
              final request = requests[index];
              return Card(
                margin: const EdgeInsets.all(8.0),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundImage: NetworkImage(request['photoURL'] ?? ''),
                  ),
                  title: Text(request['displayName'] ?? request['email']),
                  subtitle: Text(request['email']),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.check, color: Colors.green),
                        onPressed: () async {
                          // Approve request
                          await FirebaseFirestore.instance.collection('users').doc(request.id).update({
                            'isActive': true,
                          });
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('User approved')),
                          );
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.red),
                        onPressed: () async {
                          // Reject request - delete user
                          await FirebaseFirestore.instance.collection('users').doc(request.id).delete();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('User rejected and removed')),
                          );
                        },
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
}
