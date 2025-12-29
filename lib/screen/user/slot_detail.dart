import 'package:flutter/material.dart';
import '../../models/data.dart';
import 'booking.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SlotDetailScreen extends StatefulWidget {
  final Slot slot;

  const SlotDetailScreen({super.key, required this.slot});

  @override
  _SlotDetailScreenState createState() => _SlotDetailScreenState();
}

class _SlotDetailScreenState extends State<SlotDetailScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Slot ${widget.slot.slotName}', style: TextStyle(fontSize: 25, color: Colors.white)),
        backgroundColor: Colors.blue,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('parking_slots')
            .doc(widget.slot.id)  // Listen to the specific slot document
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('Slot not found'));
          }

          final updatedSlot = Slot.fromFirestore(snapshot.data!);

          // Check if the reservation has expired and update status if needed
          if (updatedSlot.reservedEnd != null && DateTime.now().isAfter(updatedSlot.reservedEnd!)) {
            if (updatedSlot.status != SlotStatus.available) {
              // Update Firestore to mark the slot as available
              _updateSlotStatusToAvailable(updatedSlot);
            }
          }

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.local_parking,
                              size: 48,
                              color: getStatusColor(updatedSlot.status),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Slot ${updatedSlot.slotName}',
                                    style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    'Zone: ${updatedSlot.zoneId}',  // Assuming you want to show the zoneId
                                    style: const TextStyle(
                                      fontSize: 16,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: getStatusColor(updatedSlot.status),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            getStatusText(updatedSlot.status),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Display the reservation details if reserved or occupied
                if (updatedSlot.status == SlotStatus.reserved || updatedSlot.status == SlotStatus.occupied)
                  Card(
                    margin: const EdgeInsets.only(top: 16),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Reservation Details',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              const Icon(Icons.access_time, color: Colors.blue),
                              const SizedBox(width: 8),
                              Text(
                                'Start: ${_formatDateTime(updatedSlot.reservedStart!)}',
                                style: const TextStyle(fontSize: 16),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(Icons.access_time_filled, color: Colors.red),
                              const SizedBox(width: 8),
                              Text(
                                'End: ${_formatDateTime(updatedSlot.reservedEnd!)}',
                                style: const TextStyle(fontSize: 16),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              const Icon(Icons.timer, color: Colors.orange),
                              const SizedBox(width: 8),
                              Text(
                                'Time Remaining: ${_getTimeRemaining(updatedSlot)}',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.orange,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                // Handle the slot availability for booking
                if (updatedSlot.status == SlotStatus.available)
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => BookingScreen(slot: updatedSlot),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      minimumSize: const Size(double.infinity, 48),
                    ),
                    child: const Text('Book This Slot'),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  // Update slot status to 'available' in Firestore
  Future<void> _updateSlotStatusToAvailable(Slot updatedSlot) async {
    try {
      await FirebaseFirestore.instance.collection('parking_slots').doc(updatedSlot.id).update({
        'status': 'available',
        'isAvailable': true,
        'isReserved': false,
        'isOccupied': false,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Slot status updated to Available')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating slot status: $e')),
        );
      }
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  String _getTimeRemaining(Slot updatedSlot) {
    if (updatedSlot.reservedEnd == null) return '';

    final now = DateTime.now();
    final remaining = updatedSlot.reservedEnd!.difference(now);

    if (remaining.isNegative) return 'Expired';

    final hours = remaining.inHours;
    final minutes = remaining.inMinutes % 60;

    if (hours > 0) {
      return '${hours}h ${minutes}m remaining';
    } else {
      return '${minutes}m remaining';
    }
  }

  String getStatusText(SlotStatus status) {
    switch (status) {
      case SlotStatus.reserved:
        return 'Reserved';
      case SlotStatus.occupied:
        return 'Occupied';
      case SlotStatus.available:
      default:
        return 'Available';
    }
  }

  Color getStatusColor(SlotStatus status) {
    switch (status) {
      case SlotStatus.reserved:
        return Colors.yellow; // Reserved = Yellow
      case SlotStatus.occupied:
        return Colors.red; // Occupied = Red
      case SlotStatus.available:
      default:
        return Colors.green; // Available = Green
    }
  }
}