import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/data.dart';
import '../../services/parking_service.dart';


class BookingScreen extends StatefulWidget {
  final Slot slot;

  const BookingScreen({super.key, required this.slot});

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  final _formKey = GlobalKey<FormState>();
  DateTime? _startDate;
  TimeOfDay? _startTime;
  DateTime? _endDate;
  TimeOfDay? _endTime;
  bool _isLoading = false;


  @override
  void initState() {
    super.initState();
    // Set default start time to now, rounded to nearest 15 minutes
    final now = DateTime.now();
    _startDate = DateTime(now.year, now.month, now.day);
    _startTime = TimeOfDay(hour: now.hour, minute: (now.minute ~/ 15) * 15);

    // Set default end time to 2 hours later (maximum allowed)
    final endTime = now.add(const Duration(hours: 2));
    _endDate = DateTime(endTime.year, endTime.month, endTime.day);
    _endTime = TimeOfDay(hour: endTime.hour, minute: endTime.minute);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Book Parking Slot', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.blue,
      ),
      body: FutureBuilder<Zone?>(
        future: ParkingService().getZone(widget.slot.zoneId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          final zone = snapshot.data;
          if (zone == null) {
            return const Center(child: Text('Zone not found'));
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Slot Information Card
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
                                color: getStatusColor(widget.slot.status),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Slot ${widget.slot.slotName}',
                                      style: const TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      'Zone: ${zone.name}',
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
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Start Date & Time
                  const Text(
                    'Start Date & Time',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _selectStartDate(context),
                          icon: const Icon(Icons.calendar_today),
                          label: Text(_startDate == null
                              ? 'Select Date'
                              : '${_startDate!.day}/${_startDate!.month}/${_startDate!.year}'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _selectStartTime(context),
                          icon: const Icon(Icons.access_time),
                          label: Text(_startTime == null
                              ? 'Select Time'
                              : '${_startTime!.hour}:${_startTime!.minute.toString().padLeft(2, '0')}'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // End Date & Time
                  const Text(
                    'End Date & Time',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _selectEndDate(context),
                          icon: const Icon(Icons.calendar_today),
                          label: Text(_endDate == null
                              ? 'Select Date'
                              : '${_endDate!.day}/${_endDate!.month}/${_endDate!.year}'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _selectEndTime(context),
                          icon: const Icon(Icons.access_time),
                          label: Text(_endTime == null
                              ? 'Select Time'
                              : '${_endTime!.hour}:${_endTime!.minute.toString().padLeft(2, '0')}'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Duration Display
                  if (_startDate != null && _startTime != null && _endDate != null && _endTime != null)
                    Card(
                      color: Colors.blue.shade50,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            const Text(
                              'Booking Duration',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _calculateDuration(),
                              style: const TextStyle(fontSize: 18, color: Colors.blue),
                            ),
                          ],
                        ),
                      ),
                    ),

                  const SizedBox(height: 32),

                  // Book Button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : () => _bookSlot(zone),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                        'Confirm Booking',
                        style: TextStyle(fontSize: 18, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _selectStartDate(BuildContext context) async {
    final DateTime now = DateTime.now();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _startDate ?? now,
      firstDate: now, // Can only book from today onwards
      lastDate: now, // Can only book within the same day
    );
    if (picked != null) {
      setState(() {
        _startDate = picked;
        // Reset end date to same day
        _endDate = picked;
      });
    }
  }

  Future<void> _selectStartTime(BuildContext context) async {
    final DateTime now = DateTime.now();
    final TimeOfDay minTime = TimeOfDay(hour: now.hour, minute: (now.minute ~/ 15) * 15);

    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _startTime ?? minTime,
    );

    if (picked != null) {
      // Validate that start time is not in the past
      final selectedDateTime = DateTime(
        _startDate!.year,
        _startDate!.month,
        _startDate!.day,
        picked.hour,
        picked.minute,
      );

      if (selectedDateTime.isBefore(now)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cannot select a time in the past')),
        );
        return;
      }

      setState(() {
        _startTime = picked;
        // Auto-set end time to 2 hours later, but not exceeding the day
        final startDateTime = DateTime(
          _startDate!.year,
          _startDate!.month,
          _startDate!.day,
          picked.hour,
          picked.minute,
        );
        final proposedEndTime = startDateTime.add(const Duration(hours: 2));
        final endOfDay = DateTime(_startDate!.year, _startDate!.month, _startDate!.day, 23, 59);

        final actualEndTime = proposedEndTime.isBefore(endOfDay) ? proposedEndTime : endOfDay;

        _endDate = DateTime(actualEndTime.year, actualEndTime.month, actualEndTime.day);
        _endTime = TimeOfDay(hour: actualEndTime.hour, minute: actualEndTime.minute);
      });
    }
  }

  Future<void> _selectEndDate(BuildContext context) async {
    // End date must be the same as start date (same day booking only)
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Bookings must be within the same day')),
    );
  }

  Future<void> _selectEndTime(BuildContext context) async {
    if (_startDate == null || _startTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select start time first')),
      );
      return;
    }

    final startDateTime = DateTime(
      _startDate!.year,
      _startDate!.month,
      _startDate!.day,
      _startTime!.hour,
      _startTime!.minute,
    );

    final maxEndTime = startDateTime.add(const Duration(hours: 2));
    final endOfDay = DateTime(_startDate!.year, _startDate!.month, _startDate!.day, 23, 59);
    final actualMaxTime = maxEndTime.isBefore(endOfDay) ? maxEndTime : endOfDay;

    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _endTime ?? TimeOfDay.fromDateTime(actualMaxTime),
    );

    if (picked != null) {
      final selectedEndTime = DateTime(
        _startDate!.year,
        _startDate!.month,
        _startDate!.day,
        picked.hour,
        picked.minute,
      );

      // Validate end time constraints
      if (selectedEndTime.isBefore(startDateTime)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('End time must be after start time')),
        );
        return;
      }

      if (selectedEndTime.isAfter(actualMaxTime)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Maximum booking duration is 2 hours')),
        );
        return;
      }

      setState(() {
        _endTime = picked;
      });
    }
  }

  String _calculateDuration() {
    if (_startDate == null || _startTime == null || _endDate == null || _endTime == null) {
      return '';
    }

    final startDateTime = DateTime(
      _startDate!.year,
      _startDate!.month,
      _startDate!.day,
      _startTime!.hour,
      _startTime!.minute,
    );

    final endDateTime = DateTime(
      _endDate!.year,
      _endDate!.month,
      _endDate!.day,
      _endTime!.hour,
      _endTime!.minute,
    );

    final duration = endDateTime.difference(startDateTime);

    if (duration.isNegative) {
      return 'Invalid duration';
    }

    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;

    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else {
      return '${minutes}m';
    }
  }

  Future<void> _bookSlot(Zone zone) async {
    if (!_formKey.currentState!.validate()) return;

    if (_startDate == null || _startTime == null || _endDate == null || _endTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select all date and time fields')),
      );
      return;
    }

    final startDateTime = DateTime(
      _startDate!.year,
      _startDate!.month,
      _startDate!.day,
      _startTime!.hour,
      _startTime!.minute,
    );

    final endDateTime = DateTime(
      _endDate!.year,
      _endDate!.month,
      _endDate!.day,
      _endTime!.hour,
      _endTime!.minute,
    );

    if (startDateTime.isAfter(endDateTime) || startDateTime.isAtSameMomentAs(endDateTime)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('End time must be after start time')),
      );
      return;
    }

    if (startDateTime.isBefore(DateTime.now())) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Start time cannot be in the past')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Check if user already has an active booking
      final existingBookings = await FirebaseFirestore.instance
          .collection('reservations')
          .where('userId', isEqualTo: user.uid)
          .where('status', whereIn: ['active', 'occupied'])
          .get();

      if (existingBookings.docs.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('You can only have one active booking at a time')),
        );
        setState(() {
          _isLoading = false;
        });
        return;
      }

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Booking failed: ${e.toString()}')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
}