import '/customloader.dart';

import '../General%20User%20Pages/userdash.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'dart:async';

class EmailVerificationPage extends StatefulWidget {
  const EmailVerificationPage({super.key});

  @override
  _EmailVerificationPageState createState() => _EmailVerificationPageState();
}

class _EmailVerificationPageState extends State<EmailVerificationPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _isEmailVerified = false;
  bool _isLoading = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _checkEmailVerified();

    // Auto-refresh email verification status every 5 seconds
    _timer = Timer.periodic(const Duration(seconds: 5), (timer) {
      _checkEmailVerified();
    });
  }

  @override
  void dispose() {
    _timer?.cancel(); // Stop the timer when the widget is disposed
    super.dispose();
  }

  Future<void> _checkEmailVerified() async {
    setState(() {
      _isLoading = true;
    });

    User? user = _auth.currentUser;
    await user?.reload();
    bool verified = user?.emailVerified ?? false;

    if (verified) {
      _timer?.cancel(); // Stop checking once verified
      _navigateToHome();
    } else {
      setState(() {
        _isEmailVerified = verified;
        _isLoading = false;
      });
    }
  }

  Future<void> _sendVerificationEmail() async {
    try {
      User? user = _auth.currentUser;
      await user?.sendEmailVerification();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("Verification email sent! Check your inbox.")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error sending email: $e")),
      );
    }
  }

  Future<void> _logout() async {
    User? user = _auth.currentUser;
    if (user != null) {
      await FirebaseDatabase.instance.ref("users/${user.uid}/session").remove();
    }
    await _auth.signOut();

    if (mounted) {
      Navigator.pushNamedAndRemoveUntil(context, "/", (route) => false);
    }
  }

  void _navigateToHome() {
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => UserDashboardPage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromRGBO(28, 156, 231, 1),
      body: Center(
        child: _isLoading
            ? const CustomSpinner()
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    "Verify Your Email",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    "A verification email has been sent to your registered email. Please check your inbox and verify your email.",
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _sendVerificationEmail,
                    child: const Text("Resend Email"),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _checkEmailVerified,
                    child: const Text("Continue"),
                  ),
                  const SizedBox(height: 20),
                  TextButton(
                    onPressed: _logout,
                    child: const Text(
                      "Logout",
                      style: TextStyle(
                        color: Colors.red,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
