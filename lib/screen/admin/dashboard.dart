import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/parking_service.dart';
import '../../models/data.dart';

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
