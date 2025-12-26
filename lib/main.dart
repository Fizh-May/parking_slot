import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:parking_slot/screen/login.dart';
import 'firebase_options.dart';
import 'package:parking_slot/screen/test.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,

      //home: TestFirestorePage(),
      home: LoginScreen(),
    );
  }
}
