import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/data.dart';
import '../../services/parking_service.dart';

class ActiveBookingsScreen extends StatefulWidget {
  const ActiveBookingsScreen({super.key});

  @override
  State<ActiveBookingsScreen> createState() => _ActiveBookingsScreenState();
}

class _ActiveBookingsScreenState extends State<ActiveBookingsScreen> {
  final ParkingService _parkingService = ParkingService();
  Timer? _expiredCheckTimer;

  @override
  void initState() {
    super.initState();
    // Check for expired reservations periodically
    _startExpiredCheckTimer();
  }

  @override
  void dispose() {
    // Cancel the timer when the widget is disposed
    _expiredCheckTimer?.cancel();
    super.dispose();
  }

  void _startExpiredCheckTimer() {
    // Check every minute for expired reservations
    _expiredCheckTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
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
        title: const Text('My Active Bookings', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.blue,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('reservations')
            .where('userId', isEqualTo: user.uid)
            .where('status', whereIn: ['active', 'occupied'])
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Error loading bookings'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final bookings = snapshot.data!.docs;

          if (bookings.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.local_parking, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'No active bookings',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Book a parking slot to get started',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: bookings.length,
            itemBuilder: (context, index) {
              final booking = bookings[index];
              return _buildBookingCard(booking);
            },
          );
        },
      ),
    );
  }

  Widget _buildBookingCard(DocumentSnapshot booking) {
    final slotId = booking['slotId'] as String;
    final startTime = (booking['startTime'] as Timestamp).toDate();
    final endTime = (booking['endTime'] as Timestamp).toDate();
    final status = booking['status'] as String;

    // Fetch Slot details first
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance
          .collection('parking_slots')
          .doc(slotId)
          .get(),
      builder: (context, slotSnapshot) {
        if (slotSnapshot.connectionState == ConnectionState.waiting) {
          return const CircularProgressIndicator();
        }
        if (slotSnapshot.hasError) {
          return Text('Error loading slot: ${slotSnapshot.error}');
        }

        if (!slotSnapshot.hasData || !slotSnapshot.data!.exists) {
          return const Text('Slot not found');
        }

        final slotData = slotSnapshot.data!;
        final slot = Slot.fromFirestore(slotData);

        // Now fetch Zone details based on slot's zoneId
        return FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance
              .collection('zones')
              .doc(slot.zoneId)
              .get(),
          builder: (context, zoneSnapshot) {
            if (zoneSnapshot.connectionState == ConnectionState.waiting) {
              return const CircularProgressIndicator();
            }
            if (zoneSnapshot.hasError) {
              return Text('Error loading zone: ${zoneSnapshot.error}');
            }

            if (!zoneSnapshot.hasData || !zoneSnapshot.data!.exists) {
              return const Text('Zone not found');
            }

            final zoneData = zoneSnapshot.data!;
            final zone = Zone.fromFirestore(zoneData);

            final now = DateTime.now();
            final isActive = now.isAfter(startTime) && now.isBefore(endTime);
            final timeRemaining = endTime.difference(now);

            return Card(
              margin: const EdgeInsets.only(bottom: 16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.local_parking,
                          color: status == 'occupied' ? Colors.red : Colors.blue,
                          size: 32,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Slot ${slot.slotName}',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                zone.name,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: status == 'occupied' ? Colors.red : Colors.green,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            status == 'occupied' ? 'In Use' : 'Reserved',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const Icon(Icons.access_time, color: Colors.blue, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Start: ${_formatDateTime(startTime)}',
                          style: const TextStyle(fontSize: 14),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.access_time_filled, color: Colors.red, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'End: ${_formatDateTime(endTime)}',
                          style: const TextStyle(fontSize: 14),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Padding(
                      padding: const EdgeInsets.only(left: 28),
                      child: Text(
                        'Note: Extend time can only be extended by a maximum of 2 hours and can only be done once',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.black,
                          fontWeight: FontWeight.bold, // Use fontWeight.bold for bold text
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (isActive && timeRemaining.isNegative == false)
                      Row(
                        children: [
                          const Icon(Icons.timer, color: Colors.orange, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Time Remaining: ${_formatDuration(timeRemaining)}',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.orange,
                            ),
                          ),
                        ],
                      ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _extendBooking(booking),
                            icon: const Icon(Icons.add),
                            label: const Text('Extend Time'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _cancelBooking(booking),
                            icon: const Icon(Icons.cancel),
                            label: const Text('Cancel'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _extendBooking(DocumentSnapshot booking) async {
    final currentEndTime = (booking['endTime'] as Timestamp).toDate();
    final originalStartTime = (booking['startTime'] as Timestamp).toDate();

    // Calculate maximum allowed end time (4 hours from original start time)
    final maxAllowedEndTime = originalStartTime.add(const Duration(hours: 4));
    final endOfDay = DateTime(currentEndTime.year, currentEndTime.month, currentEndTime.day, 23, 59);
    final absoluteMaxTime = maxAllowedEndTime.isBefore(endOfDay) ? maxAllowedEndTime : endOfDay;

    // Check if already at maximum extension
    if (currentEndTime.isAtSameMomentAs(absoluteMaxTime) || currentEndTime.isAfter(absoluteMaxTime)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Maximum extension limit reached (4 hours total)')),
        );
      }
      return;
    }

    // Calculate maximum extension time (2 hours from current end time, but not exceeding 4 hours total)
    final maxExtensionFromCurrent = currentEndTime.add(const Duration(hours: 2));
    final maxPossibleEndTime = maxExtensionFromCurrent.isBefore(absoluteMaxTime) ? maxExtensionFromCurrent : absoluteMaxTime;

    // Show time picker for extension with constraints
    final TimeOfDay? selectedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(currentEndTime.add(const Duration(hours: 1))), // Suggest 1 hour extension
      helpText: 'Select new end time (extend by 1-2 hours, max 4 hours total)',
    );

    if (selectedTime == null || !mounted) return;

    final newEndTime = DateTime(
      currentEndTime.year,
      currentEndTime.month,
      currentEndTime.day,
      selectedTime.hour,
      selectedTime.minute,
    );

    if (newEndTime.isBefore(currentEndTime)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('New end time must be after current end time')),
        );
      }
      return;
    }

    // Check extension duration (must be 1-2 hours)
    final extensionDuration = newEndTime.difference(currentEndTime);
    if (extensionDuration < const Duration(hours: 1) || extensionDuration > const Duration(hours: 2)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Extension must be between 1-2 hours')),
        );
      }
      return;
    }

    // Check if extension exceeds 4-hour total limit
    if (newEndTime.isAfter(absoluteMaxTime)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cannot extend beyond 4 hours from start time')),
        );
      }
      return;
    }

    // Check for conflicts
    final conflictQuery = await FirebaseFirestore.instance
        .collection('reservations')
        .where('slotId', isEqualTo: booking['slotId'])
        .where('status', whereIn: ['active', 'occupied'])
        .get();

    bool hasConflict = false;
    for (var doc in conflictQuery.docs) {
      if (doc.id == booking.id) continue; // Skip current booking

      final existingStart = (doc['startTime'] as Timestamp).toDate();
      final existingEnd = (doc['endTime'] as Timestamp).toDate();

      if (currentEndTime.isBefore(existingEnd) && newEndTime.isAfter(existingStart)) {
        hasConflict = true;
        break;
      }
    }

    if (hasConflict) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cannot extend - slot is booked by someone else')),
        );
      }
      return;
    }

    try {
      await FirebaseFirestore.instance
          .collection('reservations')
          .doc(booking.id)
          .update({
        'endTime': Timestamp.fromDate(newEndTime),
        'extendedDuration': true,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Booking extended successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to extend booking: $e')),
        );
      }
    }
  }

  Future<void> _cancelBooking(DocumentSnapshot booking) async {
    final confirmed = await showDialog<bool>(  // Confirm cancellation
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Booking'),
        content: const Text('Are you sure you want to cancel this booking?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Yes'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      final slotId = booking['slotId'] as String;

      // Update reservation status to cancelled
      await FirebaseFirestore.instance
          .collection('reservations')
          .doc(booking.id)
          .update({'status': 'cancelled'});

      // Update slot status back to available
      await _parkingService.updateSlotStatus(slotId, 'available');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Booking cancelled successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to cancel booking: $e')),
        );
      }
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  String _formatDuration(Duration duration) {
    if (duration.isNegative) return 'Expired';

    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;

    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else {
      return '${minutes}m';
    }
  }
}