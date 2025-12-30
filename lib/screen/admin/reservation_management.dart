import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ReservationManagement extends StatefulWidget {
  const ReservationManagement({super.key});

  @override
  State<ReservationManagement> createState() => _ReservationManagementState();
}

class _ReservationManagementState extends State<ReservationManagement> {
  String _selectedFilter = 'all'; // all, active, completed, cancelled

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              PopupMenuButton<String>(
                onSelected: (value) {
                  setState(() {
                    _selectedFilter = value;
                  });
                },
                itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                  const PopupMenuItem<String>(
                    value: 'all',
                    child: Text('All Reservations'),
                  ),
                  const PopupMenuItem<String>(
                    value: 'active',
                    child: Text('Active Only'),
                  ),
                  const PopupMenuItem<String>(
                    value: 'completed',
                    child: Text('Completed Only'),
                  ),
                  const PopupMenuItem<String>(
                    value: 'cancelled',
                    child: Text('Cancelled Only'),
                  ),
                ],
                icon: const Icon(Icons.filter_list),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('reservations')
                  .orderBy('startTime', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Center(child: Text('Error loading reservations'));
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final allReservations = snapshot.data!.docs;

                // Filter reservations based on selected filter
                final reservations = _selectedFilter == 'all'
                    ? allReservations
                    : allReservations.where((doc) => doc['status'] == _selectedFilter).toList();

                if (reservations.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.book_online, size: 64, color: Colors.grey),
                        const SizedBox(height: 16),
                        Text(
                          'No ${_selectedFilter == 'all' ? '' : _selectedFilter} reservations found',
                          style: const TextStyle(fontSize: 18, color: Colors.grey),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: reservations.length,
                  itemBuilder: (context, index) {
                    final reservation = reservations[index];
                    final userId = reservation['userId'];

                    // Truy vấn tên người dùng từ collection 'users'
                    return FutureBuilder<DocumentSnapshot>(
                      future: FirebaseFirestore.instance.collection('users').doc(userId).get(),
                      builder: (context, userSnapshot) {
                        if (userSnapshot.connectionState == ConnectionState.waiting) {
                          return const Card(
                            margin: EdgeInsets.only(bottom: 8),
                            child: Padding(
                              padding: EdgeInsets.all(16),
                              child: Center(child: CircularProgressIndicator()),
                            ),
                          );
                        }

                        if (userSnapshot.hasError) {
                          return const Card(
                            margin: EdgeInsets.only(bottom: 8),
                            child: Padding(
                              padding: EdgeInsets.all(16),
                              child: Center(child: Text('Error loading user data')),
                            ),
                          );
                        }

                        // Kiểm tra dữ liệu của người dùng
                        final userData = userSnapshot.data;
                        final userName = userData?['displayName'] ?? 'Unknown';
                        final userEmail = userData?['email'] ?? '';

                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            userName,
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                          ),
                                          Text(
                                            userEmail,
                                            style: const TextStyle(fontSize: 12, color: Colors.grey),
                                          ),
                                        ],
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
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    const Icon(Icons.local_parking, size: 16, color: Colors.grey),
                                    const SizedBox(width: 4),
                                    Text('Slot: ${reservation['slotId'] ?? 'Unknown'}'),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    const Icon(Icons.access_time, size: 16, color: Colors.grey),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        'Start: ${_formatTimestamp(reservation['startTime'])}',
                                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(Icons.access_time_filled, size: 16, color: Colors.grey),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        'End: ${_formatTimestamp(reservation['endTime'])}',
                                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: _buildActionButtons(reservation),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
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

  List<Widget> _buildActionButtons(DocumentSnapshot reservation) {
    final status = reservation['status'];
    final List<Widget> buttons = [];

    if (status == 'active') {
      // Extend reservation button
      buttons.add(
        TextButton.icon(
          onPressed: () => _extendReservation(reservation),
          icon: const Icon(Icons.update, size: 16),
          label: const Text('Extend'),
          style: TextButton.styleFrom(foregroundColor: Colors.blue),
        ),
      );

      // Cancel reservation button
      buttons.add(
        TextButton.icon(
          onPressed: () => _cancelReservation(reservation),
          icon: const Icon(Icons.cancel, size: 16),
          label: const Text('Cancel'),
          style: TextButton.styleFrom(foregroundColor: Colors.red),
        ),
      );
    } else if (status == 'completed') {
      // View details button
      buttons.add(
        TextButton.icon(
          onPressed: () => _viewReservationDetails(reservation),
          icon: const Icon(Icons.visibility, size: 16),
          label: const Text('Details'),
          style: TextButton.styleFrom(foregroundColor: Colors.green),
        ),
      );
    }

    return buttons;
  }

  void _extendReservation(DocumentSnapshot reservation) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        final TextEditingController hoursController = TextEditingController();
        return AlertDialog(
          title: const Text('Extend Reservation'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Enter additional hours to extend:'),
              const SizedBox(height: 16),
              TextField(
                controller: hoursController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Hours',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                final hours = int.tryParse(hoursController.text);
                if (hours != null && hours > 0) {
                  await _performExtendReservation(reservation, hours);
                  if (mounted) Navigator.of(context).pop();
                }
              },
              child: const Text('Extend'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _performExtendReservation(DocumentSnapshot reservation, int hours) async {
    try {
      final currentEndTime = (reservation['endTime'] as Timestamp).toDate();
      final newEndTime = currentEndTime.add(Duration(hours: hours));

      await FirebaseFirestore.instance
          .collection('reservations')
          .doc(reservation.id)
          .update({
        'endTime': Timestamp.fromDate(newEndTime),
        'extendedDuration': true,
      });

      // Update slot reservation end time
      await FirebaseFirestore.instance
          .collection('parking_slots')
          .doc(reservation['slotId'])
          .update({
        'reservedEnd': Timestamp.fromDate(newEndTime),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Reservation extended by $hours hours'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error extending reservation: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _cancelReservation(DocumentSnapshot reservation) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Cancel Reservation'),
          content: const Text('Are you sure you want to cancel this reservation?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('No'),
            ),
            TextButton(
              onPressed: () async {
                await _performCancelReservation(reservation);
                if (mounted) Navigator.of(context).pop();
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Yes, Cancel'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _performCancelReservation(DocumentSnapshot reservation) async {
    try {
      await FirebaseFirestore.instance
          .collection('reservations')
          .doc(reservation.id)
          .update({'status': 'cancelled'});

      // Update slot status back to available
      await FirebaseFirestore.instance
          .collection('parking_slots')
          .doc(reservation['slotId'])
          .update({
        'isReserved': false,
        'isAvailable': true,
        'reservedStart': null,
        'reservedEnd': null,
        'status': 'available',
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Reservation cancelled successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error cancelling reservation: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _viewReservationDetails(DocumentSnapshot reservation) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Reservation Details'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Reservation ID: ${reservation.id}'),
              const SizedBox(height: 8),
              Text('Slot ID: ${reservation['slotId']}'),
              const SizedBox(height: 8),
              Text('Status: ${reservation['status']}'),
              const SizedBox(height: 8),
              Text('Start Time: ${_formatTimestamp(reservation['startTime'])}'),
              const SizedBox(height: 8),
              Text('End Time: ${_formatTimestamp(reservation['endTime'])}'),
              const SizedBox(height: 8),
              if (reservation.data() != null && (reservation.data() as Map<String, dynamic>).containsKey('extendedDuration') && reservation['extendedDuration'] == true)
                const Text('Duration Extended: Yes', style: TextStyle(color: Colors.blue)),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  // Function to get color based on status
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

  // Function to format Firestore Timestamps
  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return 'Unknown'; // Handle null values
    try {
      if (timestamp is Timestamp) {
        final dateTime = timestamp.toDate();
        return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
      }
      return 'Invalid Timestamp'; // Handle cases where the type is not Timestamp
    } catch (e) {
      print('Error formatting timestamp: $e');
      return 'Invalid date'; // Return 'Invalid date' for errors
    }
  }
}
