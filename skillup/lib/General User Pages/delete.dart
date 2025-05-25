import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class DeleteSessionsPage extends StatefulWidget {
  const DeleteSessionsPage({super.key});

  @override
  _DeleteSessionsPageState createState() => _DeleteSessionsPageState();
}

class _DeleteSessionsPageState extends State<DeleteSessionsPage> {
  final DatabaseReference _database = FirebaseDatabase.instance.ref();

  Future<void> updateUsersAndDeleteSessions() async {
    try {
      DatabaseReference usersRef = _database.child("users");
      DatabaseEvent event = await usersRef.once();
      DataSnapshot snapshot = event.snapshot;

      if (snapshot.value != null && snapshot.value is Map) {
        Map<dynamic, dynamic> users = snapshot.value as Map<dynamic, dynamic>;

        for (var userId in users.keys) {
          DatabaseReference userRef = usersRef.child(userId);
          DatabaseReference sessionRef = userRef.child("session");

          // Update membershipPlan to "true"
          await userRef.update({"membershipPlan": "true"});
          // Delete session data
          await sessionRef.remove();

          print("Updated membershipPlan and deleted session for user: $userId");
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  "All users updated and session data deleted successfully")),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("No users found in the database")),
        );
      }
    } catch (e) {
      print("Error updating users and deleting sessions: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text("Error updating users and deleting sessions: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Update Users & Delete Sessions")),
      body: Center(
        child: ElevatedButton(
          onPressed: updateUsersAndDeleteSessions,
          style: ElevatedButton.styleFrom(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            backgroundColor: Colors.red,
          ),
          child: Text("Update Users & Delete Sessions"),
        ),
      ),
    );
  }
}
