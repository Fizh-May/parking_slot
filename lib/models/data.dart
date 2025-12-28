import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

enum SlotStatus { available, reserved, occupied }

class Zone {
  final String id;
  final String name;
  final int totalSlots;
  final int availableSlots;
  final int reservedSlots;
  final int occupiedSlots;
  final DateTime createdAt;
  final DateTime updatedAt;

  Zone({
    required this.id,
    required this.name,
    required this.totalSlots,
    required this.availableSlots,
    required this.reservedSlots,
    required this.occupiedSlots,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Zone.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Zone(
      id: data['id'] ?? doc.id,
      name: data['name'] ?? '',
      totalSlots: data['totalSlots'] ?? 0,
      availableSlots: data['availableSlots'] ?? 0,
      reservedSlots: data['reservedSlots'] ?? 0,
      occupiedSlots: data['occupiedSlots'] ?? 0,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'name': name,
      'totalSlots': totalSlots,
      'availableSlots': availableSlots,
      'reservedSlots': reservedSlots,
      'occupiedSlots': occupiedSlots,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }
}

class Slot {
  final String id;
  final String zoneId;
  final String slotLocation;
  final String slotName;
  final bool isAvailable;
  final bool isOccupied;
  final bool isReserved;
  final SlotStatus status;
  final DateTime? reservedStart;
  final DateTime? reservedEnd;
  final String? userId;
  final DateTime createdAt;
  final DateTime updatedAt;

  Slot({
    required this.id,
    required this.zoneId,
    required this.slotLocation,
    required this.slotName,
    required this.isAvailable,
    required this.isOccupied,
    required this.isReserved,
    required this.status,
    this.reservedStart,
    this.reservedEnd,
    this.userId,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Slot.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Slot(
      id: data['id'] ?? doc.id,
      zoneId: data['zoneId'] ?? '',
      slotLocation: data['slotLocation'] ?? '',
      slotName: data['slotName'] ?? '',
      isAvailable: data['isAvailable'] ?? true,
      isOccupied: data['isOccupied'] ?? false,
      isReserved: data['isReserved'] ?? false,
      status: _parseSlotStatus(data['status']),
      reservedStart: (data['reservedStart'] as Timestamp?)?.toDate(),
      reservedEnd: (data['reservedEnd'] as Timestamp?)?.toDate(),
      userId: data['userId'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'zoneId': zoneId,
      'slotLocation': slotLocation,
      'slotName': slotName,
      'isAvailable': isAvailable,
      'isOccupied': isOccupied,
      'isReserved': isReserved,
      'status': status.toString().split('.').last,
      'reservedStart': reservedStart != null ? Timestamp.fromDate(reservedStart!) : null,
      'reservedEnd': reservedEnd != null ? Timestamp.fromDate(reservedEnd!) : null,
      'userId': userId,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  static SlotStatus _parseSlotStatus(String? status) {
    switch (status) {
      case 'reserved':
        return SlotStatus.reserved;
      case 'occupied':
        return SlotStatus.occupied;
      case 'available':
      default:
        return SlotStatus.available;
    }
  }
}

class Reservation {
  final String id;
  final String userId;
  final String slotId;
  final DateTime reservationStartTime;
  final DateTime reservationEndTime;
  final String status;
  final bool extendedDuration;
  final DateTime createdAt;
  final bool isActive;
  final DateTime? checkInTime;
  final DateTime? checkOutTime;
  final double? totalCost;

  Reservation({
    required this.id,
    required this.userId,
    required this.slotId,
    required this.reservationStartTime,
    required this.reservationEndTime,
    required this.status,
    required this.extendedDuration,
    required this.createdAt,
    required this.isActive,
    this.checkInTime,
    this.checkOutTime,
    this.totalCost,
  });

  factory Reservation.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Reservation(
      id: data['id'] ?? doc.id,
      userId: data['userId'] ?? '',
      slotId: data['slotId'] ?? '',
      reservationStartTime: (data['reservationStartTime'] as Timestamp).toDate(),
      reservationEndTime: (data['reservationEndTime'] as Timestamp).toDate(),
      status: data['status'] ?? 'active',
      extendedDuration: data['extendedDuration'] ?? false,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isActive: data['isActive'] ?? true,
      checkInTime: (data['checkInTime'] as Timestamp?)?.toDate(),
      checkOutTime: (data['checkOutTime'] as Timestamp?)?.toDate(),
      totalCost: data['totalCost']?.toDouble(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'userId': userId,
      'slotId': slotId,
      'reservationStartTime': Timestamp.fromDate(reservationStartTime),
      'reservationEndTime': Timestamp.fromDate(reservationEndTime),
      'status': status,
      'extendedDuration': extendedDuration,
      'createdAt': Timestamp.fromDate(createdAt),
      'isActive': isActive,
      'checkInTime': checkInTime != null ? Timestamp.fromDate(checkInTime!) : null,
      'checkOutTime': checkOutTime != null ? Timestamp.fromDate(checkOutTime!) : null,
      'totalCost': totalCost,
    };
  }
}

class ParkingUsageHistory {
  final String id;
  final String userId;
  final String slotId;
  final DateTime usageStartTime;
  final DateTime usageEndTime;
  final String reservationId;
  final String status;

  ParkingUsageHistory({
    required this.id,
    required this.userId,
    required this.slotId,
    required this.usageStartTime,
    required this.usageEndTime,
    required this.reservationId,
    required this.status,
  });

  factory ParkingUsageHistory.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return ParkingUsageHistory(
      id: doc.id,
      userId: data['userId'] ?? '',
      slotId: data['slotId'] ?? '',
      usageStartTime: (data['usageStartTime'] as Timestamp).toDate(),
      usageEndTime: (data['usageEndTime'] as Timestamp).toDate(),
      reservationId: data['reservationId'] ?? '',
      status: data['status'] ?? 'completed',
    );
  }
}



// Helper functions
Color getStatusColor(SlotStatus status) {
  switch (status) {
    case SlotStatus.available:
      return Colors.green;
    case SlotStatus.reserved:
      return Colors.orange;
    case SlotStatus.occupied:
      return Colors.red;
  }
}

String getStatusText(SlotStatus status) {
  switch (status) {
    case SlotStatus.available:
      return 'Available';
    case SlotStatus.reserved:
      return 'Reserved';
    case SlotStatus.occupied:
      return 'Occupied';
  }
}
