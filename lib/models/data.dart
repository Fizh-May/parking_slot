import 'package:flutter/material.dart';

enum SlotStatus { available, reserved, occupied }

class Zone {
  final String id;
  final String name;
  final int totalSlots;
  final int availableSlots;
  final int reservedSlots;
  final int occupiedSlots;

  Zone({
    required this.id,
    required this.name,
    required this.totalSlots,
    required this.availableSlots,
    required this.reservedSlots,
    required this.occupiedSlots,
  });
}

class Slot {
  final String id;
  final String zoneId;
  final String name;
  final SlotStatus status;
  final DateTime? reservedStart;
  final DateTime? reservedEnd;
  final String? userId;

  Slot({
    required this.id,
    required this.zoneId,
    required this.name,
    required this.status,
    this.reservedStart,
    this.reservedEnd,
    this.userId,
  });
}

class Booking {
  final String id;
  final String userId;
  final String slotId;
  final DateTime startTime;
  final DateTime endTime;
  final DateTime createdAt;
  final bool isActive;

  Booking({
    required this.id,
    required this.userId,
    required this.slotId,
    required this.startTime,
    required this.endTime,
    required this.createdAt,
    required this.isActive,
  });
}

// Sample data
List<Zone> sampleZones = [
  Zone(
    id: 'zone1',
    name: 'Zone A - Ground Floor',
    totalSlots: 10,
    availableSlots: 5,
    reservedSlots: 3,
    occupiedSlots: 2,
  ),
  Zone(
    id: 'zone2',
    name: 'Zone B - First Floor',
    totalSlots: 8,
    availableSlots: 4,
    reservedSlots: 2,
    occupiedSlots: 2,
  ),
  Zone(
    id: 'zone3',
    name: 'Zone C - Second Floor',
    totalSlots: 12,
    availableSlots: 7,
    reservedSlots: 3,
    occupiedSlots: 2,
  ),
];

List<Slot> sampleSlots = [
  // Zone A slots
  Slot(id: 'slot1', zoneId: 'zone1', name: 'A01', status: SlotStatus.available),
  Slot(id: 'slot2', zoneId: 'zone1', name: 'A02', status: SlotStatus.available),
  Slot(id: 'slot3', zoneId: 'zone1', name: 'A03', status: SlotStatus.reserved, reservedStart: DateTime.now().add(Duration(hours: 1)), reservedEnd: DateTime.now().add(Duration(hours: 3)), userId: 'user1'),
  Slot(id: 'slot4', zoneId: 'zone1', name: 'A04', status: SlotStatus.occupied, reservedStart: DateTime.now().subtract(Duration(hours: 1)), reservedEnd: DateTime.now().add(Duration(hours: 1)), userId: 'user2'),
  Slot(id: 'slot5', zoneId: 'zone1', name: 'A05', status: SlotStatus.available),
  Slot(id: 'slot6', zoneId: 'zone1', name: 'A06', status: SlotStatus.reserved, reservedStart: DateTime.now().add(Duration(hours: 2)), reservedEnd: DateTime.now().add(Duration(hours: 4)), userId: 'user3'),
  Slot(id: 'slot7', zoneId: 'zone1', name: 'A07', status: SlotStatus.available),
  Slot(id: 'slot8', zoneId: 'zone1', name: 'A08', status: SlotStatus.occupied, reservedStart: DateTime.now().subtract(Duration(minutes: 30)), reservedEnd: DateTime.now().add(Duration(hours: 2)), userId: 'user4'),
  Slot(id: 'slot9', zoneId: 'zone1', name: 'A09', status: SlotStatus.available),
  Slot(id: 'slot10', zoneId: 'zone1', name: 'A10', status: SlotStatus.available),

  // Zone B slots
  Slot(id: 'slot11', zoneId: 'zone2', name: 'B01', status: SlotStatus.available),
  Slot(id: 'slot12', zoneId: 'zone2', name: 'B02', status: SlotStatus.reserved, reservedStart: DateTime.now().add(Duration(hours: 1)), reservedEnd: DateTime.now().add(Duration(hours: 2)), userId: 'user5'),
  Slot(id: 'slot13', zoneId: 'zone2', name: 'B03', status: SlotStatus.occupied, reservedStart: DateTime.now().subtract(Duration(hours: 2)), reservedEnd: DateTime.now().add(Duration(hours: 1)), userId: 'user6'),
  Slot(id: 'slot14', zoneId: 'zone2', name: 'B04', status: SlotStatus.available),
  Slot(id: 'slot15', zoneId: 'zone2', name: 'B05', status: SlotStatus.available),
  Slot(id: 'slot16', zoneId: 'zone2', name: 'B06', status: SlotStatus.reserved, reservedStart: DateTime.now().add(Duration(hours: 3)), reservedEnd: DateTime.now().add(Duration(hours: 5)), userId: 'user7'),
  Slot(id: 'slot17', zoneId: 'zone2', name: 'B07', status: SlotStatus.occupied, reservedStart: DateTime.now().subtract(Duration(minutes: 45)), reservedEnd: DateTime.now().add(Duration(hours: 3)), userId: 'user8'),
  Slot(id: 'slot18', zoneId: 'zone2', name: 'B08', status: SlotStatus.available),

  // Zone C slots
  Slot(id: 'slot19', zoneId: 'zone3', name: 'C01', status: SlotStatus.available),
  Slot(id: 'slot20', zoneId: 'zone3', name: 'C02', status: SlotStatus.available),
  Slot(id: 'slot21', zoneId: 'zone3', name: 'C03', status: SlotStatus.reserved, reservedStart: DateTime.now().add(Duration(hours: 2)), reservedEnd: DateTime.now().add(Duration(hours: 4)), userId: 'user9'),
  Slot(id: 'slot22', zoneId: 'zone3', name: 'C04', status: SlotStatus.occupied, reservedStart: DateTime.now().subtract(Duration(hours: 1)), reservedEnd: DateTime.now().add(Duration(hours: 2)), userId: 'user10'),
  Slot(id: 'slot23', zoneId: 'zone3', name: 'C05', status: SlotStatus.available),
  Slot(id: 'slot24', zoneId: 'zone3', name: 'C06', status: SlotStatus.available),
  Slot(id: 'slot25', zoneId: 'zone3', name: 'C07', status: SlotStatus.reserved, reservedStart: DateTime.now().add(Duration(hours: 1)), reservedEnd: DateTime.now().add(Duration(hours: 3)), userId: 'user11'),
  Slot(id: 'slot26', zoneId: 'zone3', name: 'C08', status: SlotStatus.available),
  Slot(id: 'slot27', zoneId: 'zone3', name: 'C09', status: SlotStatus.occupied, reservedStart: DateTime.now().subtract(Duration(minutes: 30)), reservedEnd: DateTime.now().add(Duration(hours: 1)), userId: 'user12'),
  Slot(id: 'slot28', zoneId: 'zone3', name: 'C10', status: SlotStatus.available),
  Slot(id: 'slot29', zoneId: 'zone3', name: 'C11', status: SlotStatus.available),
  Slot(id: 'slot30', zoneId: 'zone3', name: 'C12', status: SlotStatus.reserved, reservedStart: DateTime.now().add(Duration(hours: 4)), reservedEnd: DateTime.now().add(Duration(hours: 6)), userId: 'user13'),
];

List<Booking> sampleBookings = [
  Booking(
    id: 'booking1',
    userId: 'user1',
    slotId: 'slot3',
    startTime: DateTime.now().add(Duration(hours: 1)),
    endTime: DateTime.now().add(Duration(hours: 3)),
    createdAt: DateTime.now().subtract(Duration(hours: 2)),
    isActive: true,
  ),
  Booking(
    id: 'booking2',
    userId: 'user2',
    slotId: 'slot4',
    startTime: DateTime.now().subtract(Duration(hours: 1)),
    endTime: DateTime.now().add(Duration(hours: 1)),
    createdAt: DateTime.now().subtract(Duration(hours: 3)),
    isActive: true,
  ),
  Booking(
    id: 'booking3',
    userId: 'user3',
    slotId: 'slot6',
    startTime: DateTime.now().add(Duration(hours: 2)),
    endTime: DateTime.now().add(Duration(hours: 4)),
    createdAt: DateTime.now().subtract(Duration(hours: 1)),
    isActive: true,
  ),
  Booking(
    id: 'booking4',
    userId: 'user4',
    slotId: 'slot8',
    startTime: DateTime.now().subtract(Duration(minutes: 30)),
    endTime: DateTime.now().add(Duration(hours: 2)),
    createdAt: DateTime.now().subtract(Duration(hours: 4)),
    isActive: true,
  ),
  Booking(
    id: 'booking5',
    userId: 'user5',
    slotId: 'slot12',
    startTime: DateTime.now().add(Duration(hours: 1)),
    endTime: DateTime.now().add(Duration(hours: 2)),
    createdAt: DateTime.now().subtract(Duration(hours: 2)),
    isActive: true,
  ),
  Booking(
    id: 'booking6',
    userId: 'user6',
    slotId: 'slot13',
    startTime: DateTime.now().subtract(Duration(hours: 2)),
    endTime: DateTime.now().add(Duration(hours: 1)),
    createdAt: DateTime.now().subtract(Duration(hours: 5)),
    isActive: true,
  ),
  Booking(
    id: 'booking7',
    userId: 'user7',
    slotId: 'slot16',
    startTime: DateTime.now().add(Duration(hours: 3)),
    endTime: DateTime.now().add(Duration(hours: 5)),
    createdAt: DateTime.now().subtract(Duration(hours: 1)),
    isActive: true,
  ),
  Booking(
    id: 'booking8',
    userId: 'user8',
    slotId: 'slot17',
    startTime: DateTime.now().subtract(Duration(minutes: 45)),
    endTime: DateTime.now().add(Duration(hours: 3)),
    createdAt: DateTime.now().subtract(Duration(hours: 3)),
    isActive: true,
  ),
  Booking(
    id: 'booking9',
    userId: 'user9',
    slotId: 'slot21',
    startTime: DateTime.now().add(Duration(hours: 2)),
    endTime: DateTime.now().add(Duration(hours: 4)),
    createdAt: DateTime.now().subtract(Duration(hours: 2)),
    isActive: true,
  ),
  Booking(
    id: 'booking10',
    userId: 'user10',
    slotId: 'slot22',
    startTime: DateTime.now().subtract(Duration(hours: 1)),
    endTime: DateTime.now().add(Duration(hours: 2)),
    createdAt: DateTime.now().subtract(Duration(hours: 4)),
    isActive: true,
  ),
  Booking(
    id: 'booking11',
    userId: 'user11',
    slotId: 'slot25',
    startTime: DateTime.now().add(Duration(hours: 1)),
    endTime: DateTime.now().add(Duration(hours: 3)),
    createdAt: DateTime.now().subtract(Duration(hours: 1)),
    isActive: true,
  ),
  Booking(
    id: 'booking12',
    userId: 'user12',
    slotId: 'slot27',
    startTime: DateTime.now().subtract(Duration(minutes: 30)),
    endTime: DateTime.now().add(Duration(hours: 1)),
    createdAt: DateTime.now().subtract(Duration(hours: 2)),
    isActive: true,
  ),
  Booking(
    id: 'booking13',
    userId: 'user13',
    slotId: 'slot30',
    startTime: DateTime.now().add(Duration(hours: 4)),
    endTime: DateTime.now().add(Duration(hours: 6)),
    createdAt: DateTime.now().subtract(Duration(hours: 3)),
    isActive: true,
  ),
];

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
