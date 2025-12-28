import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth.dart';
import '../services/parking_service.dart';
import '../models/data.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  int _selectedIndex = 0;

  static const List<Widget> _widgetOptions = <Widget>[
    AdminDashboard(),
    ZoneSlotManagement(),
    ReservationManagement(),
    UsageHistory(),
    UserManagement(),
    UserRequests(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Panel', style: TextStyle(fontSize: 35, color: Colors.white),),
        backgroundColor: Colors.blue,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () async {
              await AuthService().signOut();
              Navigator.of(context).pushReplacementNamed('/login');
            },
          ),
        ],
      ),
      body: _widgetOptions.elementAt(_selectedIndex),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.local_parking),
            label: 'Zones/Slots',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.book_online),
            label: 'Reservations',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: 'History',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people),
            label: 'Users',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.pending),
            label: 'Requests',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.blue,
        onTap: _onItemTapped,
      ),
    );
  }
}

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int availableSlots = 0;
  int reservedSlots = 0;
  int occupiedSlots = 0;
  int todaysBookings = 0;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    try {
      final parkingService = ParkingService();

      // Get all slots
      final allSlots = await parkingService.getSlots();
      int totalAvailable = 0;
      int totalReserved = 0;
      int totalOccupied = 0;

      for (final slot in allSlots) {
        switch (slot.status) {
          case SlotStatus.available:
            totalAvailable++;
            break;
          case SlotStatus.reserved:
            totalReserved++;
            break;
          case SlotStatus.occupied:
            totalOccupied++;
            break;
        }
      }

      // Get today's bookings
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final bookingsSnapshot = await FirebaseFirestore.instance
          .collection('reservations')
          .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('createdAt', isLessThan: Timestamp.fromDate(endOfDay))
          .get();

      setState(() {
        availableSlots = totalAvailable;
        reservedSlots = totalReserved;
        occupiedSlots = totalOccupied;
        todaysBookings = bookingsSnapshot.docs.length;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading dashboard data: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Admin Dashboard',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : GridView.count(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    children: [
                      _buildDashboardCard('Available Slots', availableSlots.toString(), Colors.green, Icons.check_circle),
                      _buildDashboardCard('Reserved Slots', reservedSlots.toString(), Colors.yellow, Icons.schedule),
                      _buildDashboardCard('Occupied Slots', occupiedSlots.toString(), Colors.red, Icons.car_rental),
                      _buildDashboardCard('Today\'s Bookings', todaysBookings.toString(), Colors.blue, Icons.calendar_today),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardCard(String title, String value, Color color, IconData icon) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 48, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color),
            ),
            const SizedBox(height: 4),
            Text(title, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

class ZoneSlotManagement extends StatelessWidget {
  const ZoneSlotManagement({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Parking Zones Management',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('zones').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Error loading zones'));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final zones = snapshot.data!.docs;
          return ListView.builder(
            itemCount: zones.length,
            itemBuilder: (context, index) {
              final zone = zones[index];
              return ZoneListItem(zone: zone);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Add new zone
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

class ZoneListItem extends StatelessWidget {
  final DocumentSnapshot zone;

  const ZoneListItem({super.key, required this.zone});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<QuerySnapshot>(
      future: FirebaseFirestore.instance
          .collection('parking_slots')
          .where('zoneId', isEqualTo: zone.id)
          .get(),
      builder: (context, slotsSnapshot) {
        if (slotsSnapshot.connectionState == ConnectionState.waiting) {
          return const ListTile(
            title: Text('Loading...'),
          );
        }
        if (slotsSnapshot.hasError) {
          return ListTile(
            title: Text(zone['name']),
            subtitle: const Text('Error loading slot count'),
          );
        }

        final slots = slotsSnapshot.data!.docs;
        final totalSlots = slots.length;
        final availableSlots = slots.where((slot) => slot['status'] == 'available').length;

        return ListTile(
          title: Text(zone['name']),
          subtitle: Text('Total slots: $totalSlots, Available: $availableSlots'),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => SlotManagement(zoneId: zone.id, zoneName: zone['name']),
              ),
            );
          },
        );
      },
    );
  }
}

class SlotManagement extends StatelessWidget {
  final String zoneId;
  final String zoneName;

  const SlotManagement({super.key, required this.zoneId, required this.zoneName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Slots in $zoneName'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('parking_slots')
            .where('zoneId', isEqualTo: zoneId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Error loading slots'));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final slots = snapshot.data!.docs;
          return GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            padding: const EdgeInsets.all(16),
            itemCount: slots.length,
            itemBuilder: (context, index) {
              final slot = slots[index];
              return _buildSlotCard(slot);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Add new slot
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildSlotCard(DocumentSnapshot slot) {
    Color color;
    String status = slot['status'];
    switch (status) {
      case 'available':
        color = Colors.green;
        break;
      case 'reserved':
        color = Colors.yellow;
        break;
      case 'occupied':
        color = Colors.red;
        break;
      default:
        color = Colors.grey;
    }

    return Card(
      color: color,
      child: Center(
        child: Text(
          slot['slotName'],
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
        ),
      ),
    );
  }
}

class ReservationManagement extends StatelessWidget {
  const ReservationManagement({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reservation Management',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('reservations').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Error loading reservations'));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final reservations = snapshot.data!.docs;
          return ListView.builder(
            itemCount: reservations.length,
            itemBuilder: (context, index) {
              final reservation = reservations[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'User: ${reservation['userId'] ?? 'Unknown'}',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: _getStatusColor(reservation['status']),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              reservation['status'] ?? 'Unknown',
                              style: const TextStyle(color: Colors.white, fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text('Slot: ${reservation['slotId'] ?? 'Unknown'}'),
                      const SizedBox(height: 4),
                      Text(
                        'Start: ${_formatTimestamp(reservation['reservationStartTime'])}',
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      Text(
                        'End: ${_formatTimestamp(reservation['reservationEndTime'])}',
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
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

  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'active':
        return Colors.green;
      case 'completed':
        return Colors.blue;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return 'Unknown';
    try {
      if (timestamp is Timestamp) {
        final dateTime = timestamp.toDate();
        return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
      }
      return timestamp.toString();
    } catch (e) {
      return 'Invalid date';
    }
  }
}

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
                trailing: Text('${record['checkIn'] ?? 'Unknown'} - ${record['checkOut'] ?? 'Unknown'}'),
              );
            },
          );
        },
      ),
    );
  }
}

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

class UserRequests extends StatelessWidget {
  const UserRequests({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('User Requests',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
      ),
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
