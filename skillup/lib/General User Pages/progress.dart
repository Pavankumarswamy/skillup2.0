import 'package:firebase_auth/firebase_auth.dart' as firebase;
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import '/General%20User%20Pages/certificateupload.dart'; // For certificate navigation

class ProgressPage extends StatefulWidget {
  const ProgressPage({super.key});

  @override
  State<ProgressPage> createState() => _ProgressPageState();
}

class _ProgressPageState extends State<ProgressPage> {
  final firebase.User? user = firebase.FirebaseAuth.instance.currentUser;
  List<Map<String, dynamic>> enrolledCourses = [];
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchProgress();
  }

  // Fetch enrolled courses and progress from Firebase
  Future<void> _fetchProgress() async {
    if (user == null) {
      setState(() {
        errorMessage = 'User not logged in';
        isLoading = false;
      });
      return;
    }

    try {
      final ref = FirebaseDatabase.instance.ref(
        'users/${user!.uid}/enrolled_courses',
      );
      final snapshot = await ref.get();

      if (snapshot.exists) {
        final data = snapshot.value as Map<dynamic, dynamic>;
        enrolledCourses =
            data.entries.map((entry) {
              final courseData = entry.value as Map<dynamic, dynamic>;
              return {
                'course_id': entry.key,
                'course_name':
                    courseData['course_name']?.toString() ?? 'Unknown Course',
                'completion_percentage':
                    (courseData['completion_percentage'] as num?)?.toInt() ?? 0,
                'certificate_id': courseData['certificate_id']?.toString(),
              };
            }).toList();
      } else {
        enrolledCourses = [];
      }

      setState(() {
        isLoading = false;
      });
    } catch (e) {
      debugPrint('Error fetching progress: $e');
      setState(() {
        errorMessage = 'Failed to load progress: $e';
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Progress'),
        backgroundColor: Colors.blue,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(25)),
        ),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.vertical(
              bottom: Radius.circular(25),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.blue.shade900,
                offset: const Offset(0, 5),
                blurRadius: 5,
                spreadRadius: 1.5,
              ),
            ],
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.blue.shade400, Colors.blue.shade800],
            ),
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User Info
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'User: ${user?.email ?? 'Not available'}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            // Progress List
            Expanded(
              child:
                  isLoading
                      ? const Center(
                        child: CircularProgressIndicator(color: Colors.blue),
                      )
                      : errorMessage != null
                      ? Center(
                        child: Text(
                          errorMessage!,
                          style: const TextStyle(color: Colors.red),
                        ),
                      )
                      : enrolledCourses.isEmpty
                      ? const Center(
                        child: Text(
                          'No courses enrolled yet.\nEnroll in courses to track progress!',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                      )
                      : ListView.builder(
                        itemCount: enrolledCourses.length,
                        itemBuilder: (context, index) {
                          final course = enrolledCourses[index];
                          return Card(
                            elevation: 4,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            margin: const EdgeInsets.symmetric(vertical: 8),
                            child: ListTile(
                              contentPadding: const EdgeInsets.all(16),
                              title: Text(
                                course['course_name'],
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 8),
                                  LinearProgressIndicator(
                                    value:
                                        course['completion_percentage'] / 100,
                                    backgroundColor: Colors.grey.shade300,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.blue.shade800,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Completion: ${course['completion_percentage']}%',
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                  if (course['certificate_id'] != null) ...[
                                    const SizedBox(height: 8),
                                    TextButton(
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder:
                                                (context) =>
                                                    SearchAndUploadPage(),
                                          ),
                                        );
                                      },
                                      child: Text(
                                        'View Certificate',
                                        style: TextStyle(
                                          color: Colors.blue.shade800,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          );
                        },
                      ),
            ),
          ],
        ),
      ),
    );
  }
}
