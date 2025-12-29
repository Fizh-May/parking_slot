import 'package:flutter/material.dart';
import 'package:parking_slot/screen/user/dashboard.dart';
import 'package:parking_slot/screen/user/waiting_active.dart';
import 'package:parking_slot/screen/admin/admin.dart';
import 'package:parking_slot/services/auth.dart';
import 'package:parking_slot/services/user.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // Logo
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.white.withOpacity(0.5),
                        blurRadius: 24,
                        spreadRadius: 3,
                      ),
                    ],
                  ),
                  child: const CircleAvatar(
                    radius: 78,
                    backgroundColor: Colors.white,
                    backgroundImage: AssetImage('assets/images/logo.png'),
                  ),
                ),

                const SizedBox(height: 32),

                // Title
                const Text(
                  'ParkFlow',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 30,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                  ),
                ),

                const SizedBox(height: 10),

                // Subtitle
                const Text(
                  'Manage your resident parking instantly.\nSign in to reserve your spot.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 15,
                    height: 1.5,
                  ),
                ),

                const SizedBox(height: 28),

                // Google Button
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black87,
                      elevation: 3,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    onPressed: () async {
                      final user = await AuthService().signInWithGoogle();

                      if (user != null) {
                        await UserService().createUserIfNotExists(user);
                        await UserService().updateLastLogin(user);
                        final userService = UserService();
                        final isActive = await userService.isUserActive(user.uid);
                        if (isActive){
                          final isAdmin = await userService.isAdmin(user.uid);
                          if (isAdmin) {
                            Navigator.pushAndRemoveUntil(
                              context,
                              MaterialPageRoute(builder: (_) => AdminScreen()),
                                  (route) => false,
                            );
                          } else {
                            Navigator.pushAndRemoveUntil(
                              context,
                              MaterialPageRoute(builder: (_) => DashboardScreen()),
                                  (route) => false,
                            );
                          }
                        } else {
                          Navigator.push(context, MaterialPageRoute(builder: (context) {
                            return WaitingActiveScreen();
                          },));
                        }

                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Google Sign-In failed'),
                          ),
                        );
                      }
                    },
                    child: const Text('Continue with Google'),
                  ),
                ),

                const SizedBox(height: 24),

                // Footer
                Column(
                  children: const [
                    Text(
                      'Need help getting access?',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      'Contact Management',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
