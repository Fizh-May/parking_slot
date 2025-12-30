import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ZoneSlotManagement extends StatelessWidget {
  const ZoneSlotManagement({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Parking Zones Management',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black),),
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
                return ZoneListItem(zone: zone);
              },
            ),
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

  // _loadZones method for refresh functionality
  Future<void> _loadZones() async {
    // No need to load zones manually, StreamBuilder does this
  }
}

class ZoneListItem extends StatelessWidget {
  final DocumentSnapshot zone;

  const ZoneListItem({super.key, required this.zone});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('parking_slots')
          .where('zoneId', isEqualTo: zone.id)
          .snapshots(),
      builder: (context, slotsSnapshot) {
        if (slotsSnapshot.connectionState == ConnectionState.waiting) {
          return const Card(
            margin: EdgeInsets.only(bottom: 16),
            child: ListTile(
              leading: SizedBox(
                width: 40,
                height: 40,
                child: CircularProgressIndicator(),
              ),
              title: Text('Loading...'),
            ),
          );
        }
        if (slotsSnapshot.hasError) {
          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            child: ListTile(
              leading: const Icon(
                Icons.error,
                color: Colors.red,
                size: 40,
              ),
              title: Text(zone['name']),
              subtitle: const Text('Error loading slot count'),
            ),
          );
        }

        final slots = slotsSnapshot.data!.docs;
        final totalSlots = slots.length;
        final availableSlots = slots.where((slot) => slot['status'] == 'available').length;
        final reservedSlots = slots.where((slot) => slot['status'] == 'reserved').length;
        final occupiedSlots = slots.where((slot) => slot['status'] == 'occupied').length;

        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          child: ListTile(
            leading: const Icon(
              Icons.local_parking,
              color: Colors.blue,
              size: 40,
            ),
            title: Text(
              zone['name'],
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Total Slots: $totalSlots'),
                Wrap(
                  spacing: 16,
                  runSpacing: 4,
                  children: [
                    _buildStatusRow(Colors.green, 'Available: $availableSlots'),
                    _buildStatusRow(Colors.orange, 'Reserved: $reservedSlots'),
                    _buildStatusRow(Colors.red, 'Occupied: $occupiedSlots'),
                  ],
                ),
              ],
            ),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SlotManagement(zoneId: zone.id, zoneName: zone['name']),
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
}

class SlotManagement extends StatelessWidget {
  final String zoneId;
  final String zoneName;

  const SlotManagement({super.key, required this.zoneId, required this.zoneName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Slots in $zoneName', style: const TextStyle(color: Colors.white)),
        backgroundColor: Colors.blue,
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
              return _buildSlotCard(context, slot);
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

  Widget _buildSlotCard(BuildContext context, DocumentSnapshot slot) {
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

    return GestureDetector(
      onTap: () async {
        // Show a dialog for the user to select a new status
        String newStatus = await _showStatusDialog(context, status);
        if (newStatus.isNotEmpty) {
          await _updateSlotStatus(slot.id, newStatus);
        }
      },
      child: Card(
        color: color,
        child: Center(
          child: Text(
            slot['slotName'],
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
          ),
        ),
      ),
    );
  }

  // Show a dialog for selecting status
  Future<String> _showStatusDialog(BuildContext context, String currentStatus) async {
    String newStatus = currentStatus;

    // Define status options
    List<String> statuses = ['available', 'reserved', 'occupied'];

    await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Select Slot Status'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: statuses.map((status) {
              return RadioListTile<String>(
                title: Text(status),
                value: status,
                groupValue: newStatus,
                onChanged: (value) {
                  newStatus = value!;
                  Navigator.of(context).pop();
                },
              );
            }).toList(),
          ),
        );
      },
    );

    return newStatus;
  }

  // Update slot status in Firestore
  Future<void> _updateSlotStatus(String slotId, String newStatus) async {
    try {
      final slotRef = FirebaseFirestore.instance.collection('parking_slots').doc(slotId);
      await slotRef.update({
        'status': newStatus,
        'isReserved': newStatus == 'reserved',
        'isOccupied': newStatus == 'occupied',
        'isAvailable': newStatus == 'available',
      });
    } catch (e) {
      print('Error updating slot status: $e');
    }
  }
}
