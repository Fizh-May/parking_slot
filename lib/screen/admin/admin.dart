import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/auth.dart';
import '../../services/user.dart';
import 'dashboard.dart';
import 'zone_slot_management.dart';
import 'reservation_management.dart';
import 'usage_history.dart';
import 'user_management.dart';
import 'user_requests.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  int _selectedIndex = 0;
  bool _isSecurity = false;
  bool _isLoading = true;

  List<String> _titles = [];
  List<Widget> _widgetOptions = [];
  List<IconData> _icons = [];

  @override
  void initState() {
    super.initState();
    _initializeUserRole();
  }

  Future<void> _initializeUserRole() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _isSecurity = await UserService().isSecurity(user.uid);
    }

    if (_isSecurity) {
      _titles = [
        'Dashboard',
        'Zone Slot Management',
        'Reservation Management',
      ];

      _widgetOptions = <Widget>[
        const AdminDashboard(),
        const ZoneSlotManagement(),
        const ReservationManagement(),
      ];

      _icons = [
        Icons.dashboard,
        Icons.local_parking,
        Icons.book_online,
      ];
    } else {
      _titles = [
        'Dashboard',
        'Zone Slot Management',
        'Reservation Management',
        'Usage History',
        'User Management',
        'User Requests'
      ];

      _widgetOptions = <Widget>[
        const AdminDashboard(),
        const ZoneSlotManagement(),
        const ReservationManagement(),
        const UsageHistory(),
        const UserManagement(),
        const UserRequests(),
      ];

      _icons = [
        Icons.dashboard,
        Icons.local_parking,
        Icons.book_online,
        Icons.history,
        Icons.people,
        Icons.pending,
      ];
    }

    // Reset selected index if it's out of bounds for the current role
    if (_selectedIndex >= _titles.length) {
      _selectedIndex = 0;
    }

    setState(() {
      _isLoading = false;
    });
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isLoading ? 'Loading...' : _titles[_selectedIndex],
          style: TextStyle(fontSize: 25, color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.blue,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () async {
              await AuthService().signOut();
              if (mounted) {
                Navigator.of(context).pushReplacementNamed('/login');
              }
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _widgetOptions.elementAt(_selectedIndex),
      bottomNavigationBar: _isLoading
          ? null
          : Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(_icons.length, (index) {
                  return IconButton(
                    icon: Icon(_icons[index], size: 30, color: _selectedIndex == index ? Colors.blue : Colors.grey),
                    onPressed: () {
                      setState(() {
                        _selectedIndex = index;
                      });
                    },
                  );
                }),
              ),
            ),
    );
  }
}
