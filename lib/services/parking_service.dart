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

  Future<List<Slot>> getSlotsByZone(String zoneId) async {
    try {
      final snapshot = await _db.collection('parking_slots')
          .where('zoneId', isEqualTo: zoneId)
          .get();
      return snapshot.docs.map((doc) => Slot.fromFirestore(doc)).toList();
    } catch (e) {
      print('Error getting slots by zone: $e');
      return [];
    }
  }

  Future<Slot?> getSlot(String slotId) async {
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

  Future<bool> updateSlotStatus(String slotId, SlotStatus status, {
    DateTime? reservedStart,
    DateTime? reservedEnd,
    String? userId,
  }) async {
    try {
      Map<String, dynamic> updateData = {
        'status': status.toString().split('.').last,
        'updatedAt': Timestamp.now(),
      };

      if (reservedStart != null) updateData['reservedStart'] = Timestamp.fromDate(reservedStart);
      if (reservedEnd != null) updateData['reservedEnd'] = Timestamp.fromDate(reservedEnd);
      if (userId != null) updateData['userId'] = userId;

      // Update boolean flags based on status
      updateData['isAvailable'] = status == SlotStatus.available;
      updateData['isReserved'] = status == SlotStatus.reserved;
      updateData['isOccupied'] = status == SlotStatus.occupied;

      await _db.collection('parking_slots').doc(slotId).update(updateData);
      return true;
    } catch (e) {
      print('Error updating slot status: $e');
      return false;
    }
  }

  // Reservations
  Future<List<Reservation>> getReservations() async {
    try {
      final snapshot = await _db.collection('reservations').get();
      return snapshot.docs.map((doc) => Reservation.fromFirestore(doc)).toList();
    } catch (e) {
      print('Error getting reservations: $e');
      return [];
    }
  }

  Future<List<Reservation>> getUserReservations(String userId) async {
    try {
      final snapshot = await _db.collection('reservations')
          .where('userId', isEqualTo: userId)
          .where('isActive', isEqualTo: true)
          .get();
      return snapshot.docs.map((doc) => Reservation.fromFirestore(doc)).toList();
    } catch (e) {
      print('Error getting user reservations: $e');
      return [];
    }
  }

  Future<String?> createReservation({
    required String userId,
    required String slotId,
    required DateTime startTime,
    required DateTime endTime,
  }) async {
    try {
      // Check for conflicts
      final conflict = await _checkReservationConflict(slotId, startTime, endTime);
      if (conflict) {
        return null; // Conflict exists
      }

      final reservationId = _db.collection('reservations').doc().id;
      final reservation = Reservation(
        id: reservationId,
        userId: userId,
        slotId: slotId,
        reservationStartTime: startTime,
        reservationEndTime: endTime,
        status: 'active',
        extendedDuration: false,
        createdAt: DateTime.now(),
        isActive: true,
      );

      await _db.collection('reservations').doc(reservationId).set(reservation.toFirestore());

      // Update slot status
      await updateSlotStatus(slotId, SlotStatus.reserved,
        reservedStart: startTime,
        reservedEnd: endTime,
        userId: userId,
      );

      return reservationId;
    } catch (e) {
      print('Error creating reservation: $e');
      return null;
    }
  }

  Future<bool> extendReservation(String reservationId, DateTime newEndTime) async {
    try {
      final reservationDoc = await _db.collection('reservations').doc(reservationId).get();
      if (!reservationDoc.exists) return false;

      final reservation = Reservation.fromFirestore(reservationDoc);

      // Check for conflicts with new time
      final conflict = await _checkReservationConflict(
        reservation.slotId,
        reservation.reservationStartTime,
        newEndTime,
        excludeReservationId: reservationId,
      );

      if (conflict) return false;

      await _db.collection('reservations').doc(reservationId).update({
        'reservationEndTime': Timestamp.fromDate(newEndTime),
        'extendedDuration': true,
        'updatedAt': Timestamp.now(),
      });

      // Update slot
      await updateSlotStatus(reservation.slotId, SlotStatus.reserved,
        reservedStart: reservation.reservationStartTime,
        reservedEnd: newEndTime,
        userId: reservation.userId,
      );

      return true;
    } catch (e) {
      print('Error extending reservation: $e');
      return false;
    }
  }

  Future<bool> cancelReservation(String reservationId) async {
    try {
      final reservationDoc = await _db.collection('reservations').doc(reservationId).get();
      if (!reservationDoc.exists) return false;

      final reservation = Reservation.fromFirestore(reservationDoc);

      await _db.collection('reservations').doc(reservationId).update({
        'status': 'cancelled',
        'isActive': false,
        'updatedAt': Timestamp.now(),
      });

      // Free up the slot
      await updateSlotStatus(reservation.slotId, SlotStatus.available);

      return true;
    } catch (e) {
      print('Error cancelling reservation: $e');
      return false;
    }
  }

  // Usage History
  Future<List<ParkingUsageHistory>> getUsageHistory({String? userId, String? slotId}) async {
    try {
      Query query = _db.collection('parking_usage_history');

      if (userId != null) {
        query = query.where('userId', isEqualTo: userId);
      }

      if (slotId != null) {
        query = query.where('slotId', isEqualTo: slotId);
      }

      final snapshot = await query.orderBy('usageStartTime', descending: true).get();
      return snapshot.docs.map((doc) => ParkingUsageHistory.fromFirestore(doc)).toList();
    } catch (e) {
      print('Error getting usage history: $e');
      return [];
    }
  }

  // Helper methods
  Future<bool> _checkReservationConflict(String slotId, DateTime startTime, DateTime endTime, {String? excludeReservationId}) async {
    try {
      final query = _db.collection('reservations')
          .where('slotId', isEqualTo: slotId)
          .where('isActive', isEqualTo: true)
          .where('status', isEqualTo: 'active');

      final snapshot = await query.get();

      for (var doc in snapshot.docs) {
        if (excludeReservationId != null && doc.id == excludeReservationId) continue;

        final reservation = Reservation.fromFirestore(doc);

        // Check for time overlap
        if (startTime.isBefore(reservation.reservationEndTime) &&
            endTime.isAfter(reservation.reservationStartTime)) {
          return true; // Conflict found
        }
      }

      return false; // No conflict
    } catch (e) {
      print('Error checking reservation conflict: $e');
      return true; // Assume conflict on error
    }
  }

  // Real-time streams
  Stream<List<Slot>> getSlotsStream() {
    return _db.collection('parking_slots').snapshots().map(
      (snapshot) => snapshot.docs.map((doc) => Slot.fromFirestore(doc)).toList(),
    );
  }

  Stream<List<Reservation>> getReservationsStream() {
    return _db.collection('reservations').snapshots().map(
      (snapshot) => snapshot.docs.map((doc) => Reservation.fromFirestore(doc)).toList(),
    );
  }

  // Seed sample data to Firebase
  Future<void> seedSampleData() async {
    try {
      print('Starting to seed sample data...');

      // Sample zones data
      final sampleZones = [
        {
          'id': 'zone1',
          'name': 'Zone A - Ground Floor',
          'totalSlots': 10,
          'availableSlots': 5,
          'reservedSlots': 3,
          'occupiedSlots': 2,
          'createdAt': Timestamp.now(),
          'updatedAt': Timestamp.now(),
        },
        {
          'id': 'zone2',
          'name': 'Zone B - First Floor',
          'totalSlots': 8,
          'availableSlots': 4,
          'reservedSlots': 2,
          'occupiedSlots': 2,
          'createdAt': Timestamp.now(),
          'updatedAt': Timestamp.now(),
        },
        {
          'id': 'zone3',
          'name': 'Zone C - Second Floor',
          'totalSlots': 12,
          'availableSlots': 7,
          'reservedSlots': 3,
          'occupiedSlots': 2,
          'createdAt': Timestamp.now(),
          'updatedAt': Timestamp.now(),
        },
      ];

      // Sample slots data
      final sampleSlots = [
        // Zone A slots
        {'id': 'slot1', 'zoneId': 'zone1', 'slotLocation': 'Ground Floor', 'slotName': 'A01', 'isAvailable': true, 'isOccupied': false, 'isReserved': false, 'status': 'available', 'createdAt': Timestamp.now(), 'updatedAt': Timestamp.now()},
        {'id': 'slot2', 'zoneId': 'zone1', 'slotLocation': 'Ground Floor', 'slotName': 'A02', 'isAvailable': true, 'isOccupied': false, 'isReserved': false, 'status': 'available', 'createdAt': Timestamp.now(), 'updatedAt': Timestamp.now()},
        {'id': 'slot3', 'zoneId': 'zone1', 'slotLocation': 'Ground Floor', 'slotName': 'A03', 'isAvailable': false, 'isOccupied': false, 'isReserved': true, 'status': 'reserved', 'reservedStart': Timestamp.fromDate(DateTime.now().add(Duration(hours: 1))), 'reservedEnd': Timestamp.fromDate(DateTime.now().add(Duration(hours: 3))), 'userId': 'user1', 'createdAt': Timestamp.now(), 'updatedAt': Timestamp.now()},
        {'id': 'slot4', 'zoneId': 'zone1', 'slotLocation': 'Ground Floor', 'slotName': 'A04', 'isAvailable': false, 'isOccupied': true, 'isReserved': false, 'status': 'occupied', 'reservedStart': Timestamp.fromDate(DateTime.now().subtract(Duration(hours: 1))), 'reservedEnd': Timestamp.fromDate(DateTime.now().add(Duration(hours: 1))), 'userId': 'user2', 'createdAt': Timestamp.now(), 'updatedAt': Timestamp.now()},
        {'id': 'slot5', 'zoneId': 'zone1', 'slotLocation': 'Ground Floor', 'slotName': 'A05', 'isAvailable': true, 'isOccupied': false, 'isReserved': false, 'status': 'available', 'createdAt': Timestamp.now(), 'updatedAt': Timestamp.now()},
        {'id': 'slot6', 'zoneId': 'zone1', 'slotLocation': 'Ground Floor', 'slotName': 'A06', 'isAvailable': false, 'isOccupied': false, 'isReserved': true, 'status': 'reserved', 'reservedStart': Timestamp.fromDate(DateTime.now().add(Duration(hours: 2))), 'reservedEnd': Timestamp.fromDate(DateTime.now().add(Duration(hours: 4))), 'userId': 'user3', 'createdAt': Timestamp.now(), 'updatedAt': Timestamp.now()},
        {'id': 'slot7', 'zoneId': 'zone1', 'slotLocation': 'Ground Floor', 'slotName': 'A07', 'isAvailable': true, 'isOccupied': false, 'isReserved': false, 'status': 'available', 'createdAt': Timestamp.now(), 'updatedAt': Timestamp.now()},
        {'id': 'slot8', 'zoneId': 'zone1', 'slotLocation': 'Ground Floor', 'slotName': 'A08', 'isAvailable': false, 'isOccupied': true, 'isReserved': false, 'status': 'occupied', 'reservedStart': Timestamp.fromDate(DateTime.now().subtract(Duration(minutes: 30))), 'reservedEnd': Timestamp.fromDate(DateTime.now().add(Duration(hours: 2))), 'userId': 'user4', 'createdAt': Timestamp.now(), 'updatedAt': Timestamp.now()},
        {'id': 'slot9', 'zoneId': 'zone1', 'slotLocation': 'Ground Floor', 'slotName': 'A09', 'isAvailable': true, 'isOccupied': false, 'isReserved': false, 'status': 'available', 'createdAt': Timestamp.now(), 'updatedAt': Timestamp.now()},
        {'id': 'slot10', 'zoneId': 'zone1', 'slotLocation': 'Ground Floor', 'slotName': 'A10', 'isAvailable': true, 'isOccupied': false, 'isReserved': false, 'status': 'available', 'createdAt': Timestamp.now(), 'updatedAt': Timestamp.now()},
        // Zone B slots
        {'id': 'slot11', 'zoneId': 'zone2', 'slotLocation': 'First Floor', 'slotName': 'B01', 'isAvailable': true, 'isOccupied': false, 'isReserved': false, 'status': 'available', 'createdAt': Timestamp.now(), 'updatedAt': Timestamp.now()},
        {'id': 'slot12', 'zoneId': 'zone2', 'slotLocation': 'First Floor', 'slotName': 'B02', 'isAvailable': false, 'isOccupied': false, 'isReserved': true, 'status': 'reserved', 'reservedStart': Timestamp.fromDate(DateTime.now().add(Duration(hours: 1))), 'reservedEnd': Timestamp.fromDate(DateTime.now().add(Duration(hours: 2))), 'userId': 'user5', 'createdAt': Timestamp.now(), 'updatedAt': Timestamp.now()},
        {'id': 'slot13', 'zoneId': 'zone2', 'slotLocation': 'First Floor', 'slotName': 'B03', 'isAvailable': false, 'isOccupied': true, 'isReserved': false, 'status': 'occupied', 'reservedStart': Timestamp.fromDate(DateTime.now().subtract(Duration(hours: 2))), 'reservedEnd': Timestamp.fromDate(DateTime.now().add(Duration(hours: 1))), 'userId': 'user6', 'createdAt': Timestamp.now(), 'updatedAt': Timestamp.now()},
        {'id': 'slot14', 'zoneId': 'zone2', 'slotLocation': 'First Floor', 'slotName': 'B04', 'isAvailable': true, 'isOccupied': false, 'isReserved': false, 'status': 'available', 'createdAt': Timestamp.now(), 'updatedAt': Timestamp.now()},
        {'id': 'slot15', 'zoneId': 'zone2', 'slotLocation': 'First Floor', 'slotName': 'B05', 'isAvailable': true, 'isOccupied': false, 'isReserved': false, 'status': 'available', 'createdAt': Timestamp.now(), 'updatedAt': Timestamp.now()},
        {'id': 'slot16', 'zoneId': 'zone2', 'slotLocation': 'First Floor', 'slotName': 'B06', 'isAvailable': false, 'isOccupied': false, 'isReserved': true, 'status': 'reserved', 'reservedStart': Timestamp.fromDate(DateTime.now().add(Duration(hours: 3))), 'reservedEnd': Timestamp.fromDate(DateTime.now().add(Duration(hours: 5))), 'userId': 'user7', 'createdAt': Timestamp.now(), 'updatedAt': Timestamp.now()},
        {'id': 'slot17', 'zoneId': 'zone2', 'slotLocation': 'First Floor', 'slotName': 'B07', 'isAvailable': false, 'isOccupied': true, 'isReserved': false, 'status': 'occupied', 'reservedStart': Timestamp.fromDate(DateTime.now().subtract(Duration(minutes: 45))), 'reservedEnd': Timestamp.fromDate(DateTime.now().add(Duration(hours: 3))), 'userId': 'user8', 'createdAt': Timestamp.now(), 'updatedAt': Timestamp.now()},
        {'id': 'slot18', 'zoneId': 'zone2', 'slotLocation': 'First Floor', 'slotName': 'B08', 'isAvailable': true, 'isOccupied': false, 'isReserved': false, 'status': 'available', 'createdAt': Timestamp.now(), 'updatedAt': Timestamp.now()},
        // Zone C slots
        {'id': 'slot19', 'zoneId': 'zone3', 'slotLocation': 'Second Floor', 'slotName': 'C01', 'isAvailable': true, 'isOccupied': false, 'isReserved': false, 'status': 'available', 'createdAt': Timestamp.now(), 'updatedAt': Timestamp.now()},
        {'id': 'slot20', 'zoneId': 'zone3', 'slotLocation': 'Second Floor', 'slotName': 'C02', 'isAvailable': true, 'isOccupied': false, 'isReserved': false, 'status': 'available', 'createdAt': Timestamp.now(), 'updatedAt': Timestamp.now()},
        {'id': 'slot21', 'zoneId': 'zone3', 'slotLocation': 'Second Floor', 'slotName': 'C03', 'isAvailable': false, 'isOccupied': false, 'isReserved': true, 'status': 'reserved', 'reservedStart': Timestamp.fromDate(DateTime.now().add(Duration(hours: 2))), 'reservedEnd': Timestamp.fromDate(DateTime.now().add(Duration(hours: 4))), 'userId': 'user9', 'createdAt': Timestamp.now(), 'updatedAt': Timestamp.now()},
        {'id': 'slot22', 'zoneId': 'zone3', 'slotLocation': 'Second Floor', 'slotName': 'C04', 'isAvailable': false, 'isOccupied': true, 'isReserved': false, 'status': 'occupied', 'reservedStart': Timestamp.fromDate(DateTime.now().subtract(Duration(hours: 1))), 'reservedEnd': Timestamp.fromDate(DateTime.now().add(Duration(hours: 2))), 'userId': 'user10', 'createdAt': Timestamp.now(), 'updatedAt': Timestamp.now()},
        {'id': 'slot23', 'zoneId': 'zone3', 'slotLocation': 'Second Floor', 'slotName': 'C05', 'isAvailable': true, 'isOccupied': false, 'isReserved': false, 'status': 'available', 'createdAt': Timestamp.now(), 'updatedAt': Timestamp.now()},
        {'id': 'slot24', 'zoneId': 'zone3', 'slotLocation': 'Second Floor', 'slotName': 'C06', 'isAvailable': true, 'isOccupied': false, 'isReserved': false, 'status': 'available', 'createdAt': Timestamp.now(), 'updatedAt': Timestamp.now()},
        {'id': 'slot25', 'zoneId': 'zone3', 'slotLocation': 'Second Floor', 'slotName': 'C07', 'isAvailable': false, 'isOccupied': false, 'isReserved': true, 'status': 'reserved', 'reservedStart': Timestamp.fromDate(DateTime.now().add(Duration(hours: 1))), 'reservedEnd': Timestamp.fromDate(DateTime.now().add(Duration(hours: 3))), 'userId': 'user11', 'createdAt': Timestamp.now(), 'updatedAt': Timestamp.now()},
        {'id': 'slot26', 'zoneId': 'zone3', 'slotLocation': 'Second Floor', 'slotName': 'C08', 'isAvailable': true, 'isOccupied': false, 'isReserved': false, 'status': 'available', 'createdAt': Timestamp.now(), 'updatedAt': Timestamp.now()},
        {'id': 'slot27', 'zoneId': 'zone3', 'slotLocation': 'Second Floor', 'slotName': 'C09', 'isAvailable': false, 'isOccupied': true, 'isReserved': false, 'status': 'occupied', 'reservedStart': Timestamp.fromDate(DateTime.now().subtract(Duration(minutes: 30))), 'reservedEnd': Timestamp.fromDate(DateTime.now().add(Duration(hours: 1))), 'userId': 'user12', 'createdAt': Timestamp.now(), 'updatedAt': Timestamp.now()},
        {'id': 'slot28', 'zoneId': 'zone3', 'slotLocation': 'Second Floor', 'slotName': 'C10', 'isAvailable': true, 'isOccupied': false, 'isReserved': false, 'status': 'available', 'createdAt': Timestamp.now(), 'updatedAt': Timestamp.now()},
        {'id': 'slot29', 'zoneId': 'zone3', 'slotLocation': 'Second Floor', 'slotName': 'C11', 'isAvailable': true, 'isOccupied': false, 'isReserved': false, 'status': 'available', 'createdAt': Timestamp.now(), 'updatedAt': Timestamp.now()},
        {'id': 'slot30', 'zoneId': 'zone3', 'slotLocation': 'Second Floor', 'slotName': 'C12', 'isAvailable': false, 'isOccupied': false, 'isReserved': true, 'status': 'reserved', 'reservedStart': Timestamp.fromDate(DateTime.now().add(Duration(hours: 4))), 'reservedEnd': Timestamp.fromDate(DateTime.now().add(Duration(hours: 6))), 'userId': 'user13', 'createdAt': Timestamp.now(), 'updatedAt': Timestamp.now()},
      ];

      // Sample reservations data
      final sampleReservations = [
        {'id': 'reservation1', 'userId': 'user1', 'slotId': 'slot3', 'reservationStartTime': Timestamp.fromDate(DateTime.now().add(Duration(hours: 1))), 'reservationEndTime': Timestamp.fromDate(DateTime.now().add(Duration(hours: 3))), 'status': 'active', 'extendedDuration': false, 'createdAt': Timestamp.fromDate(DateTime.now().subtract(Duration(hours: 2))), 'isActive': true},
        {'id': 'reservation2', 'userId': 'user2', 'slotId': 'slot4', 'reservationStartTime': Timestamp.fromDate(DateTime.now().subtract(Duration(hours: 1))), 'reservationEndTime': Timestamp.fromDate(DateTime.now().add(Duration(hours: 1))), 'status': 'active', 'extendedDuration': false, 'createdAt': Timestamp.fromDate(DateTime.now().subtract(Duration(hours: 3))), 'isActive': true},
        {'id': 'reservation3', 'userId': 'user3', 'slotId': 'slot6', 'reservationStartTime': Timestamp.fromDate(DateTime.now().add(Duration(hours: 2))), 'reservationEndTime': Timestamp.fromDate(DateTime.now().add(Duration(hours: 4))), 'status': 'active', 'extendedDuration': false, 'createdAt': Timestamp.fromDate(DateTime.now().subtract(Duration(hours: 1))), 'isActive': true},
        {'id': 'reservation4', 'userId': 'user4', 'slotId': 'slot8', 'reservationStartTime': Timestamp.fromDate(DateTime.now().subtract(Duration(minutes: 30))), 'reservationEndTime': Timestamp.fromDate(DateTime.now().add(Duration(hours: 2))), 'status': 'active', 'extendedDuration': false, 'createdAt': Timestamp.fromDate(DateTime.now().subtract(Duration(hours: 4))), 'isActive': true},
        {'id': 'reservation5', 'userId': 'user5', 'slotId': 'slot12', 'reservationStartTime': Timestamp.fromDate(DateTime.now().add(Duration(hours: 1))), 'reservationEndTime': Timestamp.fromDate(DateTime.now().add(Duration(hours: 2))), 'status': 'active', 'extendedDuration': false, 'createdAt': Timestamp.fromDate(DateTime.now().subtract(Duration(hours: 2))), 'isActive': true},
        {'id': 'reservation6', 'userId': 'user6', 'slotId': 'slot13', 'reservationStartTime': Timestamp.fromDate(DateTime.now().subtract(Duration(hours: 2))), 'reservationEndTime': Timestamp.fromDate(DateTime.now().add(Duration(hours: 1))), 'status': 'active', 'extendedDuration': false, 'createdAt': Timestamp.fromDate(DateTime.now().subtract(Duration(hours: 5))), 'isActive': true},
        {'id': 'reservation7', 'userId': 'user7', 'slotId': 'slot16', 'reservationStartTime': Timestamp.fromDate(DateTime.now().add(Duration(hours: 3))), 'reservationEndTime': Timestamp.fromDate(DateTime.now().add(Duration(hours: 5))), 'status': 'active', 'extendedDuration': false, 'createdAt': Timestamp.fromDate(DateTime.now().subtract(Duration(hours: 1))), 'isActive': true},
        {'id': 'reservation8', 'userId': 'user8', 'slotId': 'slot17', 'reservationStartTime': Timestamp.fromDate(DateTime.now().subtract(Duration(minutes: 45))), 'reservationEndTime': Timestamp.fromDate(DateTime.now().add(Duration(hours: 3))), 'status': 'active', 'extendedDuration': false, 'createdAt': Timestamp.fromDate(DateTime.now().subtract(Duration(hours: 3))), 'isActive': true},
        {'id': 'reservation9', 'userId': 'user9', 'slotId': 'slot21', 'reservationStartTime': Timestamp.fromDate(DateTime.now().add(Duration(hours: 2))), 'reservationEndTime': Timestamp.fromDate(DateTime.now().add(Duration(hours: 4))), 'status': 'active', 'extendedDuration': false, 'createdAt': Timestamp.fromDate(DateTime.now().subtract(Duration(hours: 2))), 'isActive': true},
        {'id': 'reservation10', 'userId': 'user10', 'slotId': 'slot22', 'reservationStartTime': Timestamp.fromDate(DateTime.now().subtract(Duration(hours: 1))), 'reservationEndTime': Timestamp.fromDate(DateTime.now().add(Duration(hours: 2))), 'status': 'active', 'extendedDuration': false, 'createdAt': Timestamp.fromDate(DateTime.now().subtract(Duration(hours: 4))), 'isActive': true},
        {'id': 'reservation11', 'userId': 'user11', 'slotId': 'slot25', 'reservationStartTime': Timestamp.fromDate(DateTime.now().add(Duration(hours: 1))), 'reservationEndTime': Timestamp.fromDate(DateTime.now().add(Duration(hours: 3))), 'status': 'active', 'extendedDuration': false, 'createdAt': Timestamp.fromDate(DateTime.now().subtract(Duration(hours: 1))), 'isActive': true},
        {'id': 'reservation12', 'userId': 'user12', 'slotId': 'slot27', 'reservationStartTime': Timestamp.fromDate(DateTime.now().subtract(Duration(minutes: 30))), 'reservationEndTime': Timestamp.fromDate(DateTime.now().add(Duration(hours: 1))), 'status': 'active', 'extendedDuration': false, 'createdAt': Timestamp.fromDate(DateTime.now().subtract(Duration(hours: 2))), 'isActive': true},
        {'id': 'reservation13', 'userId': 'user13', 'slotId': 'slot30', 'reservationStartTime': Timestamp.fromDate(DateTime.now().add(Duration(hours: 4))), 'reservationEndTime': Timestamp.fromDate(DateTime.now().add(Duration(hours: 6))), 'status': 'active', 'extendedDuration': false, 'createdAt': Timestamp.fromDate(DateTime.now().subtract(Duration(hours: 3))), 'isActive': true},
      ];

      // Add zones
      for (var zone in sampleZones) {
        await _db.collection('zones').doc(zone['id'] as String).set(zone);
        print('Added zone: ${zone['name']}');
      }

      // Add slots to their respective zones
      for (var slot in sampleSlots) {
        final zoneId = slot['zoneId'] as String;
        final slotId = slot['id'] as String;
        await _db.collection('zones').doc(zoneId).collection('slots').doc(slotId).set(slot);
        print('Added slot: ${slot['slotName']} to zone $zoneId');
      }

      // Add reservations
      for (var reservation in sampleReservations) {
        await _db.collection('reservations').doc(reservation['id'] as String).set(reservation);
        print('Added reservation: ${reservation['id']}');
      }

      print('Sample data seeding completed successfully!');
    } catch (e) {
      print('Error seeding sample data: $e');
      rethrow;
    }
  }
}
