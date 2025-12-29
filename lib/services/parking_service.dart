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
      await slotRef.update({
        'status': status,
        'isReserved': status == 'reserved',  // You can also use boolean fields for specific statuses
        'isOccupied': status == 'occupied',  // Update occupied status as well if needed
      });
    } catch (e) {
      print('Error updating slot status: $e');
      throw Exception('Error updating slot status');
    }
  }
}