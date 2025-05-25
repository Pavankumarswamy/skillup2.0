import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'course_content_page.dart';

class AdminCoursesPage extends StatefulWidget {
  const AdminCoursesPage({super.key});

  @override
  _AdminCoursesPageState createState() => _AdminCoursesPageState();
}

class _AdminCoursesPageState extends State<AdminCoursesPage> {
  final DatabaseReference _database = FirebaseDatabase.instance.ref("courses");
  final DatabaseReference _database1 =
      FirebaseDatabase.instance.ref("mentorcourse");
  List<Map<String, dynamic>> _courses = [];

  @override
  void initState() {
    super.initState();
    _fetchCourses();
  }

  void _fetchCourses() {
    _database.onValue.listen((event) {
      if (event.snapshot.value != null) {
        Map<dynamic, dynamic> values =
            event.snapshot.value as Map<dynamic, dynamic>;
        List<Map<String, dynamic>> tempCourses = [];

        values.forEach((key, value) {
          if (value["status"] == "ready") {
            // Filter for 'ready' status
            List<Map<String, dynamic>> modules = [];
            Map<String, dynamic> indexUpdates = {};

            if (value["course_content"]?['modules'] != null) {
              Map<dynamic, dynamic> moduleData =
                  value["course_content"]['modules'];

              moduleData.forEach((moduleKey, moduleValue) {
                int correctIndex =
                    int.tryParse(moduleKey.replaceAll("module_", "")) ?? 0;
                int storedIndex = moduleValue["index"] ?? -1;

                if (storedIndex != correctIndex) {
                  indexUpdates["$moduleKey/index"] = correctIndex;
                }

                modules.add({
                  "module": moduleKey,
                  "index": correctIndex,
                  "heading": moduleValue["heading"] ?? "No Heading",
                  "content": moduleValue,
                });
              });

              modules.sort((a, b) => a["index"].compareTo(b["index"]));

              if (indexUpdates.isNotEmpty) {
                _database
                    .child("$key/course_content/modules")
                    .update(indexUpdates);
              }
            }

            tempCourses.add({
              "courseId": key,
              "title": value["title"] ?? "No Title",
              "category": value["category"] ?? "No Category",
              "price": value["price"] ?? "0",
              "language": value["language"] ?? "Unknown",
              "mentorId": value["mentorId"] ?? "N/A",
              "duration": value["duration"] ?? "0",
              "status": value["status"],
              "imageUrl":
                  value["imageUrl"] ?? "https://via.placeholder.com/400",
              "modules": modules,
            });
          }
        });

        setState(() {
          _courses = tempCourses;
        });
      }
    });
  }

  void _verifyCourse(String courseId) {
    _database.child(courseId).update({'status': 'verified'}).then((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Course Verified!"),
          backgroundColor: Colors.green,
        ),
      );
    }).catchError((error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error verifying course: $error"),
          backgroundColor: Colors.red,
        ),
      );
    });
  }

  // ignore: non_constant_identifier_names
  void _ErrorCourse(String courseId) {
    if (courseId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Invalid course ID!"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    DatabaseReference courseRef = _database.child(courseId);

    // Use .get() to fetch the data snapshot
    courseRef.get().then((DataSnapshot snapshot) {
      if (snapshot.exists) {
        // Fetch course data to get the mentorId
        Map<dynamic, dynamic> courseData =
            snapshot.value as Map<dynamic, dynamic>;
        String? mentorId = courseData['mentorId'];

        if (mentorId != null) {
          // Update course status to 'Error'
          DatabaseReference mentorCourseRef =
              _database1.child(mentorId).child(courseId);

          Future.wait([
            courseRef.update({'status': 'Error'}),
            mentorCourseRef.update({'status': 'Error'}),
          ]).then((_) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text("Course error updated!"),
                backgroundColor: const Color.fromARGB(255, 175, 76, 76),
              ),
            );
          }).catchError((error) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text("Error updating course status: $error"),
                backgroundColor: Colors.red,
              ),
            );
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Mentor ID not found for course!"),
              backgroundColor: Colors.red,
            ),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Course not found!"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }).catchError((error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error fetching course details: $error"),
          backgroundColor: Colors.red,
        ),
      );
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
            title: Text(
              "Admin Dashboard",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: const Color.fromARGB(255, 255, 255, 255),
              ),
            ),
            centerTitle: true,
            flexibleSpace: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blueAccent, Colors.purpleAccent],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
            elevation: 10, // Add shadow for depth
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color.fromARGB(255, 255, 255, 255),
              Colors.purpleAccent.shade100
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: _courses.isEmpty
            ? Center(
                child: CircularProgressIndicator(
                  color: Colors.blueAccent,
                ),
              )
            : ListView.builder(
                padding: EdgeInsets.all(16),
                itemCount: _courses.length,
                itemBuilder: (context, index) {
                  final course = _courses[index];
                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CourseContentPage(
                            courseId: course["courseId"],
                          ),
                        ),
                      );
                    },
                    child: AnimatedContainer(
                      duration: Duration(milliseconds: 300),
                      margin: EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        gradient: LinearGradient(
                          colors: [Colors.blueAccent, Colors.purpleAccent],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 10,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.vertical(
                              top: Radius.circular(16),
                            ),
                            child: Image.network(
                              course["imageUrl"],
                              width: double.infinity,
                              height: 180,
                              fit: BoxFit.cover,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  course["title"],
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                SizedBox(height: 8),
                                _buildDetailRow("Category", course["category"]),
                                _buildDetailRow("Language", course["language"]),
                                _buildDetailRow(
                                    "Duration", "${course["duration"]} mins"),
                                _buildDetailRow("Price", "₹${course["price"]}"),
                                SizedBox(height: 12),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    if (course["status"] == "ready")
                                      ElevatedButton(
                                        onPressed: () =>
                                            _verifyCourse(course["courseId"]),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.green,
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                        ),
                                        child: Text(
                                          "Verify",
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ElevatedButton(
                                      onPressed: () =>
                                          _ErrorCourse(course["courseId"]),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color.fromARGB(
                                            255, 255, 12, 12),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                      ),
                                      child: Text(
                                        "ERROR",
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
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
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(
            "$label: ",
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.white.withOpacity(0.8),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
