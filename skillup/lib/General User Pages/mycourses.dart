import '/General%20User%20Pages/course.dart';
import '/customloader.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

class MyCoursesPage extends StatefulWidget {
  const MyCoursesPage({super.key});

  @override
  _MyCoursesPageState createState() => _MyCoursesPageState();
}

class _MyCoursesPageState extends State<MyCoursesPage> {
  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  final User? _user = FirebaseAuth.instance.currentUser;

  List<Map<String, dynamic>> _displayedCourses = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchCourses();
  }

  void _fetchCourses() async {
    if (_user == null) return;

    DatabaseReference userRef = _database.child("users/${_user.uid}");
    DatabaseEvent userEvent = await userRef.once();
    Map<dynamic, dynamic>? userData =
        userEvent.snapshot.value as Map<dynamic, dynamic>?;

    if (userData != null) {
      bool membershipPlan = userData['membershipPlan'] == 'true' ||
          userData['membershipPlan'] == true;

      if (membershipPlan) {
        // Fetch all verified courses
        DatabaseReference coursesRef = _database.child("courses");
        DatabaseEvent coursesEvent = await coursesRef.once();

        if (coursesEvent.snapshot.value != null) {
          Map<dynamic, dynamic> allCourses =
              coursesEvent.snapshot.value as Map<dynamic, dynamic>;
          List<Map<String, dynamic>> tempCourses = [];

          allCourses.forEach((courseId, courseData) {
            if (courseData["status"] == "verified") {
              tempCourses.add({
                "courseId": courseId,
                "title": courseData["title"] ?? "No Title",
                "description": courseData["description"] ?? "No Description",
                "imageUrl": courseData["imageUrl"] ?? "",
              });
            }
          });

          setState(() {
            _displayedCourses = tempCourses;
            _isLoading = false;
          });
        }
      } else {
        // Fetch only purchased verified courses
        DatabaseReference userCoursesRef =
            _database.child("users/${_user.uid}/purchasedCourses");

        DatabaseEvent userCoursesEvent = await userCoursesRef.once();

        if (userCoursesEvent.snapshot.value != null) {
          Map<dynamic, dynamic> purchasedCourses =
              userCoursesEvent.snapshot.value as Map<dynamic, dynamic>;

          List<Map<String, dynamic>> tempCourses = [];

          for (var courseId in purchasedCourses.keys) {
            DatabaseReference courseRef = _database.child("courses/$courseId");
            DatabaseEvent courseEvent = await courseRef.once();

            if (courseEvent.snapshot.value != null) {
              Map<dynamic, dynamic> courseData =
                  courseEvent.snapshot.value as Map<dynamic, dynamic>;

              if (courseData["status"] == "verified") {
                tempCourses.add({
                  "courseId": courseId,
                  "title": courseData["title"] ?? "No Title",
                  "description": courseData["description"] ?? "No Description",
                  "imageUrl": courseData["imageUrl"] ?? "",
                });
              }
            }
          }

          setState(() {
            _displayedCourses = tempCourses;
            _isLoading = false;
          });
        } else {
          setState(() {
            _isLoading = false;
          });
        }
      }
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("MY Courses"),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CustomSpinner())
          : _displayedCourses.isEmpty
              ? const Center(child: Text("No courses available."))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _displayedCourses.length,
                  itemBuilder: (context, index) {
                    final course = _displayedCourses[index];

                    return GestureDetector(
                      onTap: () {
                        // Navigate to CourseContentPage with courseId
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                CourseContentPage(courseId: course["courseId"]),
                          ),
                        );
                      },
                      child: Card(
                        margin: const EdgeInsets.only(bottom: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 4,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ClipRRect(
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(12),
                                topRight: Radius.circular(12),
                              ),
                              child: AspectRatio(
                                aspectRatio: 16 / 9,
                                child: course["imageUrl"].isNotEmpty
                                    ? Image.network(
                                        course["imageUrl"],
                                        fit: BoxFit.cover,
                                      )
                                    : Container(
                                        color: Colors.grey[300],
                                        child: const Icon(Icons.image,
                                            size: 50, color: Colors.grey),
                                      ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    course["title"],
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    course["description"],
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(color: Colors.grey[700]),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
