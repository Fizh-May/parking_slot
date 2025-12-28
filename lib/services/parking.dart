import 'package:cloud_firestore/cloud_firestore.dart';

class ParkingService {
  final _db = FirebaseFirestore.instance;

  // Create Parking Slot
  Future<void> createParkingSlot(String slotId, String slotLocation) async {
    final ref = _db.collection('parking_slots').doc(slotId);

    await ref.set({
      'slotLocation': slotLocation,
      'isAvailable': true,
      'isOccupied': false,
      'isReserved': false,
    });
  }

  // Update Parking Slot Status
  Future<void> updateParkingSlotStatus(String slotId, bool isAvailable, bool isOccupied, bool isReserved) async {
    final ref = _db.collection('parking_slots').doc(slotId);

    await ref.update({
      'isAvailable': isAvailable,
      'isOccupied': isOccupied,
      'isReserved': isReserved,
    });
  }

  // Create Reservation
  Future<void> createReservation(String reservationId, String userId, String slotId, Timestamp reservationStartTime, Timestamp reservationEndTime) async {
    final ref = _db.collection('reservations').doc(reservationId);

    await ref.set({
      'userId': userId,
      'slotId': slotId,
      'reservationStartTime': reservationStartTime,
      'reservationEndTime': reservationEndTime,
      'status': 'active',
      'extendedDuration': false,
    });
  }

  // Update Reservation Status
  Future<void> updateReservationStatus(String reservationId, String status, {bool extendedDuration = false}) async {
    final ref = _db.collection('reservations').doc(reservationId);

    await ref.update({
      'status': status,
      'extendedDuration': extendedDuration,
    });
  }

  // Create Parking Usage History
  Future<void> createParkingUsageHistory(String historyId, String userId, String slotId, Timestamp usageStartTime, Timestamp usageEndTime, String reservationId) async {
    final ref = _db.collection('parking_usage_history').doc(historyId);

    await ref.set({
      'userId': userId,
      'slotId': slotId,
      'usageStartTime': usageStartTime,
      'usageEndTime': usageEndTime,
      'reservationId': reservationId,
      'status': 'completed',
    });
  }

  // Update Parking Usage History Status
  Future<void> updateParkingUsageHistoryStatus(String historyId, String status) async {
    final ref = _db.collection('parking_usage_history').doc(historyId);

    await ref.update({
      'status': status,
    });
  }
}
