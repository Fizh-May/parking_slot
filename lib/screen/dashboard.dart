import 'package:flutter/material.dart';
import '../models/data.dart';
import '../services/parking_service.dart';
import 'zone_details.dart';
import '../services/auth.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final ParkingService _parkingService = ParkingService();
  List<Zone> _zones = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadZones();
  }

  Future<void> _loadZones() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final zones = await _parkingService.getZones();

      setState(() {
        _zones = zones;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load zones: $e';
        _isLoading = false;
      });
    }
  }

  Future<Map<String, int>> _getZoneStats(String zoneId) async {
    try {
      final slots = await _parkingService.getSlotsByZone(zoneId);
      int available = 0;
      int reserved = 0;
      int occupied = 0;

      for (var slot in slots) {
        switch (slot.status) {
          case SlotStatus.available:
            available++;
            break;
          case SlotStatus.reserved:
            reserved++;
            break;
          case SlotStatus.occupied:
            occupied++;
            break;
        }
      }

      return {
        'available': available,
        'reserved': reserved,
        'occupied': occupied,
      };
    } catch (e) {
      return {'available': 0, 'reserved': 0, 'occupied': 0};
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Parking Zones", style: TextStyle(fontSize: 25, color: Colors.white)),
        backgroundColor: Colors.blue,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () async {
              await AuthService().signOut();
              Navigator.of(context).pushReplacementNamed('/login');
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error, size: 64, color: Colors.red),
                      const SizedBox(height: 16),
                      Text(_error!, textAlign: TextAlign.center),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadZones,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadZones,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _zones.length,
                    itemBuilder: (context, index) {
                      final zone = _zones[index];
                      return FutureBuilder<Map<String, int>>(
                        future: _getZoneStats(zone.id),
                        builder: (context, snapshot) {
                          final stats = snapshot.data ?? {'available': 0, 'reserved': 0, 'occupied': 0};

                          return Card(
                            margin: const EdgeInsets.only(bottom: 16),
                            child: ListTile(
                              leading: const Icon(
                                Icons.local_parking,
                                color: Colors.blue,
                                size: 40,
                              ),
                              title: Text(
                                zone.name,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Total Slots: ${zone.totalSlots}'),
                                  Wrap(
                                    spacing: 16,
                                    runSpacing: 4,
                                    children: [
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Container(
                                            width: 12,
                                            height: 12,
                                            decoration: const BoxDecoration(
                                              color: Colors.green,
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                          Text('Available: ${stats['available']}'),
                                        ],
                                      ),
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Container(
                                            width: 12,
                                            height: 12,
                                            decoration: const BoxDecoration(
                                              color: Colors.orange,
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                          Text('Reserved: ${stats['reserved']}'),
                                        ],
                                      ),
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Container(
                                            width: 12,
                                            height: 12,
                                            decoration: const BoxDecoration(
                                              color: Colors.red,
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                          Text('Occupied: ${stats['occupied']}'),
                                        ],
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              trailing: const Icon(Icons.arrow_forward_ios),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ZoneDetailsScreen(zone: zone),
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
    );
  }
}
