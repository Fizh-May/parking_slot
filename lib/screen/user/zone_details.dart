import 'package:flutter/material.dart';
import '../../models/data.dart';
import '../../services/parking_service.dart';
import 'slot_detail.dart';

class ZoneDetailsScreen extends StatelessWidget {
  final Zone zone;

  const ZoneDetailsScreen({super.key, required this.zone});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(zone.name, style: TextStyle(fontSize: 25, color: Colors.white)),
        backgroundColor: Colors.blue,
      ),
      body: FutureBuilder<List<Slot>>(
        future: ParkingService().getSlotsByZone(zone.id),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          final zoneSlots = snapshot.data ?? [];

          return Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                color: Colors.grey[100],
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildLegendItem(Colors.green, 'Available'),
                    _buildLegendItem(Colors.orange, 'Reserved'),
                    _buildLegendItem(Colors.red, 'Occupied'),
                  ],
                ),
              ),
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.2,
                  ),
                  itemCount: zoneSlots.length,
                  itemBuilder: (context, index) {
                    final slot = zoneSlots[index];
                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => SlotDetailScreen(slot: slot),
                          ),
                        );
                      },
                      child: Card(
                        color: getStatusColor(slot.status),
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.local_parking,
                                color: Colors.white,
                                size: 32,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                slot.slotName,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (slot.status == SlotStatus.occupied || slot.status == SlotStatus.reserved)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text(
                                    _getTimeRemaining(slot),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildLegendItem(Color color, String text) {
    return Row(
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
        Text(text, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  String _getTimeRemaining(Slot slot) {
    if (slot.reservedEnd == null) return '';

    final now = DateTime.now();
    final remaining = slot.reservedEnd!.difference(now);

    if (remaining.isNegative) return 'Expired';

    final hours = remaining.inHours;
    final minutes = remaining.inMinutes % 60;

    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else {
      return '${minutes}m';
    }
  }
}
