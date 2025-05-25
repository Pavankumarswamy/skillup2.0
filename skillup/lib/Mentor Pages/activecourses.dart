import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

class ActiveCoursesPage extends StatefulWidget {
  const ActiveCoursesPage({super.key});

  @override
  _ActiveCoursesPageState createState() => _ActiveCoursesPageState();
}

class _ActiveCoursesPageState extends State<ActiveCoursesPage> {
  final DatabaseReference databaseReference = FirebaseDatabase.instance.ref();
  List<Map<String, dynamic>> verifiedCourses = [];

  @override
  void initState() {
    super.initState();
    _loadCourses();
  }

  // Fetch verified courses where mentorId matches the logged-in user
  void _loadCourses() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      String userId = user.uid;

      try {
        DatabaseEvent event = await databaseReference.child('courses').once();
        if (event.snapshot.value != null) {
          Map<dynamic, dynamic> courses =
              Map.from(event.snapshot.value as Map); // Convert to Map
          List<Map<String, dynamic>> tempCourses = [];

          courses.forEach((key, value) {
            if (value['status'] == 'verified' && value['mentorId'] == userId) {
              tempCourses.add(Map<String, dynamic>.from(value));
            }
          });

          setState(() {
            verifiedCourses = tempCourses;
          });
        } else {
          setState(() {
            verifiedCourses = [];
          });
        }
      } catch (error) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to load courses: $error')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Verified Courses'),
      ),
      body: verifiedCourses.isEmpty
          ? const Center(child: Text('No verified courses available'))
          : ListView.builder(
              itemCount: verifiedCourses.length,
              itemBuilder: (context, index) {
                var course = verifiedCourses[index];
                return Container(
                  margin: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        // ignore: deprecated_member_use
                        color: Colors.grey.withOpacity(0.5),
                        spreadRadius: 2,
                        blurRadius: 7,
                        offset: const Offset(3, 3), // Bottom right shadow
                      ),
                      const BoxShadow(
                        color: Colors.white,
                        spreadRadius: 2,
                        blurRadius: 7,
                        offset: Offset(-3, -3), // Top left shadow
                      ),
                    ],
                  ),
                  child: Card(
                    elevation: 8,
                    shadowColor: Colors.blue[800],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: Colors.blue[300]!,
                        width: 1,
                      ),
                    ),
                    color: Colors.blue[50], // Classic off-white background
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              course["imageUrl"],
                              height: 120,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Image.asset('assets/placeholder.png',
                                    height: 120,
                                    width: double.infinity,
                                    fit: BoxFit.cover);
                              },
                              frameBuilder: (context, child, frame,
                                  wasSynchronouslyLoaded) {
                                return AnimatedOpacity(
                                  opacity: frame == null ? 0 : 1,
                                  duration: const Duration(milliseconds: 500),
                                  curve: Curves.easeOut,
                                  child: child,
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(course["title"] ?? "No Title",
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    color: Colors.blue.shade900,
                                  )),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(Icons.timer,
                                  size: 16, color: Colors.blue.shade700),
                              Text(" ${course["duration"] ?? 'N/A'} Days",
                                  style:
                                      TextStyle(color: Colors.blue.shade700)),
                              const Spacer(),
                              Text("₹${course["price"] ?? '0'}",
                                  style:
                                      TextStyle(color: Colors.green.shade700)),
                            ],
                          ),
                          const SizedBox(height: 12),
                          _buildEnrollButton(
                              course["courseId"], course["price"]),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }

  Widget _buildEnrollButton(String? courseId, dynamic price) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      onPressed: () {
        // Add enrollment logic here
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(' $courseId of course is active')),
        );
      },
      child: const Text('Active courses'),
    );
  }
}
