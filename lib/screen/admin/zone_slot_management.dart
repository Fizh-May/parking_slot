import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/data.dart';
import '../../services/parking_service.dart';

class ZoneSlotManagement extends StatelessWidget {
  const ZoneSlotManagement({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
              child: Text(
                'No parking zones available',
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: zones.length,
            itemBuilder: (context, index) {
              final zone = zones[index];
              return ZoneListItem(zone: zone);
            },
          );
        },
      ),
    );
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
        // ui loading page
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

        final slots = slotsSnapshot.data!.docs.map((doc) => Slot.fromFirestore(doc)).toList();
        final totalSlots = slots.length;
        final availableSlots = slots.where((slot) => slot.status == SlotStatus.available).length;
        final reservedSlots = slots.where((slot) => slot.status == SlotStatus.reserved).length;
        final occupiedSlots = slots.where((slot) => slot.status == SlotStatus.occupied).length;

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
                  spacing: 80,
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

  // widget status (icon color, slot status, ..)
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
        title: Text(
            'Slots in $zoneName',
            style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold
            )),
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
    );
  }

  Widget _buildSlotCard(BuildContext context, DocumentSnapshot slotDoc) {
    final slot = Slot.fromFirestore(slotDoc);
    Color color;
    switch (slot.status) {
      case SlotStatus.available:
        color = Colors.green;
        break;
      case SlotStatus.reserved:
        color = Colors.orange;
        break;
      case SlotStatus.occupied:
        color = Colors.red;
        break;
    }

    return Card(
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        onPressed: () async {
          String currentStatus = slot.status.toString().split('.').last;
          String newStatus = await _showStatusDialog(context, currentStatus);
          if (newStatus.isNotEmpty) {
            await _updateSlotStatus(slot.id, newStatus);
          }
        },
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.local_parking,
              size: 40,
              color: Colors.white,
            ),
            const SizedBox(height: 8),
            Text(
              slot.slotName,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Future<String> _showStatusDialog(BuildContext context, String currentStatus) async {
    String newStatus = currentStatus;
    List<String> statuses = ['available', 'reserved', 'occupied'];
    List<String> displayNames = ['Available', 'Reserved', 'Occupied'];

    await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Change Slot Status',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 16),

                DropdownButton<String>(
                  value: newStatus,
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      newStatus = newValue;
                      Navigator.of(context).pop(newValue);
                    }
                  },
                  items: List.generate(statuses.length, (index) {
                    return DropdownMenuItem<String>(
                      value: statuses[index],
                      child: Text(displayNames[index]),
                    );
                  }),
                ),
              ],
            ),
          ),
        );
      },
    );

    return newStatus;
  }


  Future<void> _updateSlotStatus(String slotId, String newStatus) async {
    try {
      final parkingService = ParkingService();
      await parkingService.updateSlotStatus(slotId, newStatus);

      // Update the zone counts
      await _updateZoneCounts(zoneId);
    } catch (e) {
      print('Error updating slot status: $e');
    }
  }

  Future<void> _updateZoneCounts(String zoneId) async {
    try {
      // Get all slots for this zone
      final slotsSnapshot = await FirebaseFirestore.instance
          .collection('parking_slots')
          .where('zoneId', isEqualTo: zoneId)
          .get();

      final slots = slotsSnapshot.docs.map((doc) => Slot.fromFirestore(doc)).toList();

      final availableSlots = slots.where((slot) => slot.status == SlotStatus.available).length;
      final reservedSlots = slots.where((slot) => slot.status == SlotStatus.reserved).length;
      final occupiedSlots = slots.where((slot) => slot.status == SlotStatus.occupied).length;
      final totalSlots = slots.length;

      // Update the zone document with new counts
      final zoneRef = FirebaseFirestore.instance.collection('zones').doc(zoneId);
      await zoneRef.update({
        'availableSlots': availableSlots,
        'reservedSlots': reservedSlots,
        'occupiedSlots': occupiedSlots,
        'totalSlots': totalSlots,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error updating zone counts: $e');
    }
  }
}
