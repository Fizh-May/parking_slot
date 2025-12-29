import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
