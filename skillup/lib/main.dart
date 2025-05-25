import '/General%20User%20Pages/certificates.dart';
import '/General%20User%20Pages/logout.dart';
import '/General%20User%20Pages/settings.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../General%20User%20Pages/userdash.dart';
import '../auth/login.dart';
import 'wrapper.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart'; // Firebase Core
import 'package:flutter/foundation.dart'; // For kIsWeb

const supabaseUrl = 'https://vduoxfcddksibwrpiuqd.supabase.co';
const supabaseKey =
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZkdW94ZmNkZGtzaWJ3cnBpdXFkIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MzkxOTY4MjAsImV4cCI6MjA1NDc3MjgyMH0.GPLhjbM1JJ1_Hk6AqyRnvirFaW3bpkG91YMZ0qhGhpQ';

void main() async {
  // Ensure Flutter binding is initialized
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(url: supabaseUrl, anonKey: supabaseKey);
  // Initialize Firebase
  try {
    if (kIsWeb) {
      await Firebase.initializeApp(
        options: const FirebaseOptions(
          apiKey: "AIzaSyDC9yV_qkXDcUS9_YPsWVeOjOUCb597fEY",
          authDomain: "csedu-1.firebaseapp.com",
          databaseURL: "https://csedu-1-default-rtdb.firebaseio.com",
          projectId: "csedu-1",
          storageBucket: "csedu-1.firebasestorage.app",
          messagingSenderId: "894403809910",
          appId: "1:894403809910:web:196342047e0117295d4557",
          measurementId: "G-R6WPHRGHZE",
        ),
      );
    } else {
      await Firebase.initializeApp();
    }
    debugPrint("Firebase initialized successfully!");
  } catch (e) {
    debugPrint("Error initializing Firebase: $e");
  }

  // Run the app
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false, // Remove debug banner
      title: 'Skill Up', // App name
      theme: ThemeData(
        primarySwatch: Colors.blue, // Default theme color
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      initialRoute: '/', // Initial route set to Wrapper
      routes: {
        '/': (context) => const Wrapper(), // Wrapper for authentication state
        '/login': (context) => const LoginPage(), // Login page
        '/home': (context) => UserDashboardPage(),
        '/settings': (context) => SettingsPage(),
        '/logout': (context) => LogoutPage(),
        '/wrapper': (context) => Wrapper(),
        'certificate': (context) => CertificatesPage(), // Home screen
      },
    );
  }
}
