import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/data.dart';
import '../../services/parking_service.dart';
import 'zone_details.dart';
import 'active_bookings.dart';
import '../../services/auth.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final ParkingService _parkingService = ParkingService();
  Timer? _expiredCheckTimer;

  @override
  void initState() {
    super.initState();
    // Check for expired reservations when the dashboard loads
    _parkingService.checkAndUpdateExpiredReservations();
    // Start periodic check for expired reservations
    _startExpiredCheckTimer();
  }

  @override
  void dispose() {
    // Cancel the timer when the widget is disposed
    _expiredCheckTimer?.cancel();
    super.dispose();
  }

  void _startExpiredCheckTimer() {
    // Check every 3 seconds for expired reservations
    _expiredCheckTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (mounted) {
        _parkingService.checkAndUpdateExpiredReservations();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Please log in to view your bookings')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Parking Zones", style: TextStyle(fontSize: 25, color: Colors.white)),
        backgroundColor: Colors.blue,
        actions: [
          IconButton(
            icon: const Icon(Icons.book_online, color: Colors.white),
            tooltip: 'My Bookings',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ActiveBookingsScreen(),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () async {
              await AuthService().signOut();
              Navigator.of(context).pushReplacementNamed('/login');
            },
          ),
        ],
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

          final zones = snapshot.data!.docs.map((doc) {
            return Zone.fromFirestore(doc);
          }).toList();

          if (zones.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.local_parking, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'No parking zones available',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: _loadZones,
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: zones.length,
              itemBuilder: (context, index) {
                final zone = zones[index];
                return _buildZoneCard(zone);
              },
            ),
          );
        },
      ),
    );
  }

  // This method is used for each Zone to load the stats and display
  Widget _buildZoneCard(Zone zone) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('parking_slots')
          .where('zoneId', isEqualTo: zone.id)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(child: Text('Error loading slots'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final slots = snapshot.data!.docs.map((doc) {
          return Slot.fromFirestore(doc);
        }).toList();

        int available = 0, reserved = 0, occupied = 0;

        for (var slot in slots) {
          switch (slot.status) {
            case SlotStatus.available:
              available++;
              break;
            case SlotStatus.reserved:
              reserved++;
              break;
            case SlotStatus.occupied:
              occupied++;
              break;
          }
        }

        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          child: ListTile(
            leading: const Icon(
              Icons.local_parking,
              color: Colors.blue,
              size: 40,
            ),
            title: Text(
              zone.name,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Total Slots: ${zone.totalSlots}'),
                Wrap(
                  spacing: 16,
                  runSpacing: 4,
                  children: [
                    _buildStatusRow(Colors.green, 'Available: $available'),
                    _buildStatusRow(Colors.orange, 'Reserved: $reserved'),
                    _buildStatusRow(Colors.red, 'Occupied: $occupied'),
                  ],
                ),
              ],
            ),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ZoneDetailsScreen(zone: zone),
                ),
              );
            },
          ),
        );
      },
    );
  }

  // Helper method to create status rows (Available, Reserved, Occupied)
  Widget _buildStatusRow(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(label),
      ],
    );
  }

  // _loadZones method is no longer needed because the StreamBuilder listens to changes
  Future<void> _loadZones() async {
    // No need to load zones manually, StreamBuilder does this
  }
}
