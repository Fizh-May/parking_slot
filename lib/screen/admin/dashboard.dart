import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/data.dart';

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('parking_slots').snapshots(),
              builder: (context, slotsSnapshot) {
                if (slotsSnapshot.hasError) {
                  return const Center(child: Text('Error loading slots'));
                }

                if (slotsSnapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final slots = slotsSnapshot.data!.docs.map((doc) => Slot.fromFirestore(doc)).toList();
                int availableSlots = slots.where((slot) => slot.status == SlotStatus.available).length;
                int reservedSlots = slots.where((slot) => slot.status == SlotStatus.reserved).length;
                int occupiedSlots = slots.where((slot) => slot.status == SlotStatus.occupied).length;

                return StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance.collection('zones').snapshots(),
                  builder: (context, zonesSnapshot) {
                    if (zonesSnapshot.hasError) {
                      return const Center(child: Text('Error loading zones'));
                    }

                    if (zonesSnapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    return GridView.count(
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      children: [
                        _buildDashboardCard('Available Slots', availableSlots.toString(), Colors.green, Icons.check_circle),
                        _buildDashboardCard('Reserved Slots', reservedSlots.toString(), Colors.orange, Icons.schedule),
                        _buildDashboardCard('Occupied Slots', occupiedSlots.toString(), Colors.red, Icons.car_rental),
                        _buildDashboardCard('Total Zones', zonesSnapshot.data!.docs.length.toString(), Colors.blue, Icons.location_on),
                      ],
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
