import '/Mentor%20Pages/modulepage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

class ManageCoursesPage extends StatefulWidget {
  const ManageCoursesPage({super.key});

  @override
  _ManageCoursesPageState createState() => _ManageCoursesPageState();
}

class _ManageCoursesPageState extends State<ManageCoursesPage> {
  final DatabaseReference databaseReference = FirebaseDatabase.instance.ref();
  late String mentorId;
  List<Map<String, dynamic>> nonVerifiedCourses = [];

  @override
  void initState() {
    super.initState();
    _loadCourses();
  }

  void _loadCourses() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      mentorId = user.uid;

      databaseReference
          .child('mentorcourse')
          .child(mentorId)
          .once()
          .then((DatabaseEvent event) {
        if (event.snapshot.value != null) {
          Map<dynamic, dynamic> courses = Map.from(event.snapshot.value as Map);
          List<Map<String, dynamic>> tempCourses = [];

          courses.forEach((key, value) {
            if (value['status'] != 'verified') {
              tempCourses
                  .add(Map<String, dynamic>.from(value)..['courseId'] = key);
            }
          });

          setState(() {
            nonVerifiedCourses = tempCourses;
          });
        } else {
          setState(() {
            nonVerifiedCourses = [];
          });
        }
      }).catchError((error) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to load courses: $error')));
      });
    }
  }

  void _verifyCourse(String courseId) {
    Map<String, dynamic> updateData = {'status': 'ready'};

    // Update status in both 'mentorcourse' and 'courses'
    Future.wait([
      databaseReference
          .child('mentorcourse')
          .child(mentorId)
          .child(courseId)
          .update(updateData),
      databaseReference.child('courses').child(courseId).update(updateData),
    ]).then((_) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Course is now Ready!')));
      _loadCourses();
    }).catchError((error) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update course status: $error')));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(kToolbarHeight),
        child: ClipRRect(
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(20),
            bottomRight: Radius.circular(20),
          ),
          child: AppBar(
            title: Center(
              child: Text("Manage your course"),
            ),
            backgroundColor: Colors.transparent, // Removed color
            elevation: 0, // Optional: Removes shadow for a cleaner look
          ),
        ),
      ),
      body: nonVerifiedCourses.isEmpty
          ? Center(
              child: Text(
                'No non-verified courses available',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
              ),
            )
          : ListView.builder(
              itemCount: nonVerifiedCourses.length,
              itemBuilder: (context, index) {
                var course = nonVerifiedCourses[index];

                return GestureDetector(
                    onTap: () {
                      if (course['status'] == "not verified" ||
                          course['status'] == "Error") {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => AttachModulesPage12(
                                courseId: course['courseId']),
                          ),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content: Text(
                                  'You can only edit courses that are not verified or have errors.')),
                        );
                      }
                    },
                    child: Card(
                      elevation: 5,
                      margin:
                          EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Hero(
                              tag: course[
                                  'courseId'], // Unique tag for Hero animation
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(15),
                                child: Image(
                                  image: NetworkImage(
                                    course['imageUrl'] ??
                                        'https://telugumahasabhalu.42web.io/wp-content/uploads/2025/01/images-3.png', // Fallback URL
                                  ),
                                  fit: BoxFit.cover, // Adjust the fit as needed
                                  width: double.infinity,
                                  height: 200, // Adjust the height as needed
                                ),
                              ),
                            ),
                            SizedBox(height: 12),
                            Text(
                              course['title'] ?? 'No Title',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              course['description'] ?? 'No Description',
                              style: TextStyle(
                                  fontSize: 16, color: Colors.grey[700]),
                            ),
                            SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  "Status: ${course['status']}",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.red,
                                  ),
                                ),
                                Text(
                                  "Id: ${course['courseId']}",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: const Color.fromARGB(255, 3, 3, 3),
                                  ),
                                ),
                                ElevatedButton(
                                  onPressed: () async {
                                    bool confirm = await showDialog(
                                      context: context,
                                      builder: (BuildContext context) {
                                        return AlertDialog(
                                          title: Text("Confirm Verification"),
                                          content: Text(
                                              "Are you sure you want to verify this course?"),
                                          actions: [
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.of(context)
                                                      .pop(false), // Cancel
                                              child: Text("Cancel"),
                                            ),
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.of(context)
                                                      .pop(true), // Confirm
                                              child: Text("Confirm"),
                                            ),
                                          ],
                                        );
                                      },
                                    );

                                    if (confirm == true) {
                                      _verifyCourse(course['courseId']);
                                    }
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  child: Text("Verify",
                                      style: TextStyle(color: Colors.white)),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ));
              },
            ),
    );
  }
}
