import '/customloader.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import '../auth/login.dart'; // Import LoginPage for redirection

class LogoutPage extends StatefulWidget {
  const LogoutPage({super.key});

  @override
  _LogoutPageState createState() => _LogoutPageState();
}

class _LogoutPageState extends State<LogoutPage> {
  @override
  void initState() {
    super.initState();
    _signOutAndRedirect();
  }

  Future<void> _signOutAndRedirect() async {
    User? user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      // Remove session from Firebase Realtime Database
      await FirebaseDatabase.instance.ref("users/${user.uid}/session").remove();
      await FirebaseAuth.instance.signOut();
    }

    // Navigate to LoginPage after logout
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CustomSpinner(), // Show loading indicator while logging out
      ),
    );
  }
}
