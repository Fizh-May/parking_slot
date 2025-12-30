import 'package:flutter/material.dart';
import '../../services/auth.dart';
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

  final List<String> _titles = [
    'Dashboard',
    'Zone Slot Management',
    'Reservation Management',
    'Usage History',
    'User Management',
    'User Requests'
  ];

  final List<Widget> _widgetOptions = <Widget>[
    const AdminDashboard(),
    const ZoneSlotManagement(),
    const ReservationManagement(),
    const UsageHistory(),
    const UserManagement(),
    const UserRequests(),
  ];

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
          _titles[_selectedIndex],
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
      body: _widgetOptions.elementAt(_selectedIndex),
      bottomNavigationBar: Container(
        color: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            IconButton(
              icon: Icon(Icons.dashboard, size: 30, color: _selectedIndex == 0 ? Colors.blue : Colors.grey,),
              onPressed: () {
                setState(() {
                  _selectedIndex = 0;
                });
              },
            ),

            IconButton(
              icon: Icon(Icons.local_parking, size: 30, color: _selectedIndex == 1 ? Colors.blue : Colors.grey,),
              onPressed: () {
                setState(() {
                  _selectedIndex = 1;
                });
              },
            ),

            IconButton(
              icon: Icon(Icons.book_online, size: 30, color: _selectedIndex == 2 ? Colors.blue : Colors.grey,),
              onPressed: () {
                setState(() {
                  _selectedIndex = 2;
                });
              },
            ),

            IconButton(
              icon: Icon(Icons.history, size: 30, color: _selectedIndex == 3 ? Colors.blue : Colors.grey,),
              onPressed: () {
                setState(() {
                  _selectedIndex = 3;
                });
              },
            ),

            IconButton(
              icon: Icon(Icons.people,size: 30,color: _selectedIndex == 4 ? Colors.blue : Colors.grey,),
              onPressed: () {
                setState(() {
                  _selectedIndex = 4;
                });
              },
            ),

            IconButton(
              icon: Icon(Icons.pending,size: 30,color: _selectedIndex == 5 ? Colors.blue : Colors.grey),
              onPressed: () {setState(() {
                  _selectedIndex = 5;
                });
              },
            ),
          ],
        ),
      ),
    );
  }
}
