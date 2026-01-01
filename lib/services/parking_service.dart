import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/data.dart';
class ParkingService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Zones
  Future<List<Zone>> getZones() async {
    try {
      final snapshot = await _db.collection('zones').get();
      return snapshot.docs.map((doc) => Zone.fromFirestore(doc)).toList();
    } catch (e) {
      print('Error getting zones: $e');
      return [];
    }
  }

  Future<Zone?> getZone(String zoneId) async {
    try {
      final doc = await _db.collection('zones').doc(zoneId).get();
      if (doc.exists) {
        return Zone.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      print('Error getting zone: $e');
      return null;
    }
  }

  // Slots
  Future<List<Slot>> getSlots() async {
    try {
      final snapshot = await _db.collection('parking_slots').get();
      return snapshot.docs.map((doc) => Slot.fromFirestore(doc)).toList();
    } catch (e) {
      print('Error getting slots: $e');
      return [];
    }
  }

  // Get slots by Zone ID
  Future<List<Slot>> getSlotsByZone(String zoneId) async {
    try {
      final snapshot = await _db.collection('parking_slots')
          .where('zoneId', isEqualTo: zoneId) // Filter by zoneId
          .get();
      return snapshot.docs.map((doc) => Slot.fromFirestore(doc)).toList();
    } catch (e) {
      print('Error getting slots by zone: $e');
      return [];
    }
  }

  // Get slot by ID
  Future<Slot?> getSlotById(String slotId) async {
    try {
      final doc = await _db.collection('parking_slots').doc(slotId).get();
      if (doc.exists) {
        return Slot.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      print('Error getting slot: $e');
      return null;
    }
  }

  // Create reservation
  Future<String> createReservation({
    required String userId,
    required String slotId,
    required DateTime startTime,
    required DateTime endTime,
  }) async {
    try {
      final reservationRef = await _db.collection('reservations').add({
        'userId': userId,
        'slotId': slotId,
        'startTime': Timestamp.fromDate(startTime),
        'endTime': Timestamp.fromDate(endTime),
        'status': 'active',
      });

      // Update slot status to reserved
      await _db.collection('parking_slots').doc(slotId).update({
        'isReserved': true,
        'isAvailable': false,
        'reservedStart': Timestamp.fromDate(startTime),
        'reservedEnd': Timestamp.fromDate(endTime),
        'userId': userId, // Associate user with the slot
      });

      return reservationRef.id;
    } catch (e) {
      print('Error creating reservation: $e');
      throw Exception('Failed to create reservation');
    }
  }

  // Check for booking conflicts
  Future<bool> checkSlotAvailability({
    required String slotId,
    required DateTime startTime,
    required DateTime endTime,
  }) async {
    try {
      final conflictQuery = await _db.collection('reservations')
          .where('slotId', isEqualTo: slotId)
          .where('status', isEqualTo: 'active')
          .get();

      for (var doc in conflictQuery.docs) {
        final existingStart = (doc['startTime'] as Timestamp).toDate();
        final existingEnd = (doc['endTime'] as Timestamp).toDate();

        if ((startTime.isBefore(existingEnd) && endTime.isAfter(existingStart))) {
          return false; // Conflict found
        }
      }
      return true; // No conflict
    } catch (e) {
      print('Error checking availability: $e');
      return false;
    }
  }

  // Cancel reservation (if needed)
  Future<void> cancelReservation(String reservationId, String slotId) async {
    try {
      // Update reservation status
      await _db.collection('reservations').doc(reservationId).update({
        'status': 'canceled',
      });

      // Update slot availability
      await _db.collection('parking_slots').doc(slotId).update({
        'isReserved': false,
        'isAvailable': true,
        'reservedStart': null,
        'reservedEnd': null,
      });
    } catch (e) {
      print('Error canceling reservation: $e');
      throw Exception('Failed to cancel reservation');
    }
  }
  Future<void> updateSlotStatus(String slotId, String status) async {
    try {
      final slotRef = _db.collection('parking_slots').doc(slotId);

      // Get current slot data to track transitions
      final currentSlotDoc = await slotRef.get();
      final currentData = currentSlotDoc.data();
      final currentStatus = currentData?['status'] as String?;
      final currentUserId = currentData?['userId'] as String?;
      final currentUsageStartTime = (currentData?['usageStartTime'] as Timestamp?)?.toDate();

      // Handle usage history tracking
      if (currentStatus == 'available' && status == 'occupied') {
        // Transition from available to occupied - start usage tracking
        await slotRef.update({
          'status': status,
          'isReserved': false,
          'isOccupied': true,
          'isAvailable': false,
          'usageStartTime': Timestamp.now(), // Record when usage started
          'updatedAt': Timestamp.now(),
        });
      } else if (currentStatus == 'occupied' && status == 'available') {
        // Transition from occupied to available - complete usage and save/update history
        if (currentUsageStartTime != null && currentUserId != null) {
        // Get slot name for display
        final slotDocForName = await _db.collection('parking_slots').doc(slotId).get();
        final slotName = slotDocForName.data()?['slotName'] ?? slotId;

          // Check if there's an in_progress usage history record
          final inProgressQuery = await _db.collection('usage_history')
              .where('slotId', isEqualTo: slotId)
              .where('userId', isEqualTo: currentUserId)
              .where('status', isEqualTo: 'in_progress')
              .get();

          if (inProgressQuery.docs.isNotEmpty) {
            // Update existing in_progress record
            await _db.collection('usage_history').doc(inProgressQuery.docs.first.id).update({
              'usageEndTime': Timestamp.now(),
              'status': 'completed',
            });
          } else {
            // Fallback: save new completed record (for walk-in users)
            await _db.collection('usage_history').add({
              'userId': currentUserId,
              'slotId': slotId,
              'slotName': slotName,
              'usageStartTime': Timestamp.fromDate(currentUsageStartTime),
              'usageEndTime': Timestamp.now(),
              'status': 'completed',
              'timestamp': Timestamp.now(),
            });
          }

          // Find and update associated reservation to completed
          final reservationQuery = await _db.collection('reservations')
              .where('slotId', isEqualTo: slotId)
              .where('userId', isEqualTo: currentUserId)
              .where('status', whereIn: ['active', 'occupied'])
              .get();

          for (var reservationDoc in reservationQuery.docs) {
            await _db.collection('reservations').doc(reservationDoc.id).update({
              'status': 'completed',
            });
          }
        }

        // Reset slot to available
        await slotRef.update({
          'status': status,
          'isReserved': false,
          'isOccupied': false,
          'isAvailable': true,
          'usageStartTime': null, // Clear usage start time
          'userId': null, // Clear user association
          'reservedStart': null, // Clear reservation times
          'reservedEnd': null,
          'updatedAt': Timestamp.now(),
        });
      } else if (currentStatus == 'reserved' && status == 'occupied') {
        // Transition from reserved to occupied - start usage tracking
        await slotRef.update({
          'status': status,
          'isReserved': false,
          'isOccupied': true,
          'isAvailable': false,
          'usageStartTime': Timestamp.now(),
          'updatedAt': Timestamp.now(),
        });
      } else {
        // Other transitions (reserved to available, etc.)
        await slotRef.update({
          'status': status,
          'isReserved': status == 'reserved',
          'isOccupied': status == 'occupied',
          'isAvailable': status == 'available',
          'updatedAt': Timestamp.now(),
        });
      }
    } catch (e) {
      print('Error updating slot status: $e');
      throw Exception('Error updating slot status');
    }
  }

  // Check and update expired reservations
  Future<void> checkAndUpdateExpiredReservations() async {
    try {
      final now = Timestamp.now();

      // Query all active reservations first (single field query)
      final activeReservations = await _db.collection('reservations')
          .where('status', isEqualTo: 'active')
          .get();

      // Filter expired reservations in memory
      final expiredReservations = activeReservations.docs.where((doc) {
        final endTime = doc['endTime'] as Timestamp;
        return endTime.compareTo(now) < 0; // endTime < now
      }).toList();

      for (var doc in expiredReservations) {
        final reservationId = doc.id;
        final slotId = doc['slotId'] as String;

        // Check current slot status
        final slotDocForStatus = await _db.collection('parking_slots').doc(slotId).get();
        final currentSlotStatus = slotDocForStatus.data()?['status'] as String?;

        // If slot is occupied (someone is actually parked), don't auto-complete the reservation
        // The reservation will remain active until security manually changes slot status
        if (currentSlotStatus == 'occupied') {
          continue;
        }

        // Update reservation status to completed
        await _db.collection('reservations').doc(reservationId).update({
          'status': 'completed',
        });

        // Update slot status to available (only if not occupied)
        await updateSlotStatus(slotId, 'available');
      }
    } catch (e) {
      print('Error checking expired reservations: $e');
    }
  }

  // Get real-time slots stream
  Stream<List<Slot>> getSlotsStream() {
    return _db.collection('parking_slots').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => Slot.fromFirestore(doc)).toList();
    });
  }

  // Get slots by zone stream
  Stream<List<Slot>> getSlotsByZoneStream(String zoneId) {
    return _db.collection('parking_slots')
        .where('zoneId', isEqualTo: zoneId)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => Slot.fromFirestore(doc)).toList();
    });
  }
}