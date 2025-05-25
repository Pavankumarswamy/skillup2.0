import '/admin%20screens/dashboard%20admin.dart';
import '/auth/login.dart';
import '/customloader.dart';
import '../General%20User%20Pages/userdash.dart';
import '../Mentor%20Pages/dashboard.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import '../auth/verification.dart';

class Wrapper extends StatefulWidget {
  const Wrapper({super.key});

  @override
  _WrapperState createState() => _WrapperState();
}

class _WrapperState extends State<Wrapper> {
  bool _isSplashScreenVisible = true;

  Future<String?> _getUserRole(String uid) async {
    try {
      DatabaseReference userRef = FirebaseDatabase.instance.ref("users/$uid");
      final snapshot = await userRef.get();

      if (snapshot.exists) {
        // User profile exists, return the role
        Map<dynamic, dynamic> userData =
            snapshot.value as Map<dynamic, dynamic>;
        return userData['role'] as String? ?? "user";
      } else {
        // User profile doesn't exist, create a default profile
        await userRef.set({
          "email": FirebaseAuth.instance.currentUser?.email?.trim() ?? "",
          "createdAt": ServerValue.timestamp,
          "role": "user",
          "membershipPlan": "false",
          "membershipExpiry": "none",
          "profileImage":
              "https://res.cloudinary.com/dnedosgc6/image/upload/v1747375531/ivsknjzcnwu5emninkm2.png",
        });
        return "user"; // Default role for new users
      }
    } catch (e) {
      debugPrint("Error fetching or creating user profile: $e");
      return null; // Return null to trigger error screen
    }
  }

  @override
  void initState() {
    super.initState();
    _showSplashScreen();
  }

  void _showSplashScreen() {
    Future.delayed(const Duration(seconds: 7), () {
      setState(() {
        _isSplashScreenVisible =
            false; // Hide the splash screen after 7 seconds
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body:
          _isSplashScreenVisible
              ? Center(
                child: Image.asset(
                  'assets/logo.gif', // Full-screen splash loading GIF
                  width: double.infinity,
                  height: double.infinity,
                  fit: BoxFit.cover, // Makes the GIF cover the screen
                ),
              )
              : StreamBuilder<User?>(
                stream: FirebaseAuth.instance.authStateChanges(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CustomSpinner());
                  } else if (snapshot.hasError) {
                    return _errorScreen("An error occurred. Please try again.");
                  } else if (!snapshot.hasData || snapshot.data == null) {
                    return LoginPage();
                  }

                  User? user = snapshot.data;
                  if (user != null && user.emailVerified) {
                    return FutureBuilder<String?>(
                      future: _getUserRole(user.uid),
                      builder: (context, roleSnapshot) {
                        if (roleSnapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(child: CustomSpinner());
                        }

                        if (roleSnapshot.hasError || !roleSnapshot.hasData) {
                          return _errorScreen(
                            "Failed to fetch or create user profile.",
                          );
                        }

                        String role =
                            roleSnapshot.data ?? "user"; // Default role

                        switch (role) {
                          case "mentor":
                            return const MentorDashboard();
                          case "admin":
                            return AdminCoursesPage();
                          case "user":
                          default:
                            return UserDashboardPage();
                        }
                      },
                    );
                  } else {
                    return const EmailVerificationPage();
                  }
                },
              ),
    );
  }

  Widget _errorScreen(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            message,
            style: const TextStyle(color: Colors.red, fontSize: 16),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          ElevatedButton(
            onPressed: () {
              setState(() {}); // Retry by rebuilding the widget
            },
            child: const Text("Retry"),
          ),
        ],
      ),
    );
  }
}
