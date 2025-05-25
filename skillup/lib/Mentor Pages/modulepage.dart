import '/Mentor%20Pages/addquation.dart';
import '/Mentor%20Pages/appenddata.dart';
import '/Mentor%20Pages/quiz.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

class AttachModulesPage12 extends StatefulWidget {
  final String courseId;

  const AttachModulesPage12({super.key, required this.courseId});

  @override
  _AttachModulesPageState createState() => _AttachModulesPageState();
}

class _AttachModulesPageState extends State<AttachModulesPage12> {
  final DatabaseReference databaseReference = FirebaseDatabase.instance.ref();
  late String courseId;
  List<Map<String, dynamic>> modules = [];

  @override
  void initState() {
    super.initState();
    courseId = widget.courseId;
    _loadModules();
  }

  void _loadModules() async {
    databaseReference
        .child('courses')
        .child(courseId)
        .child('modules')
        .once()
        .then((DatabaseEvent event) {
      if (event.snapshot.value != null) {
        Map<dynamic, dynamic> loadedModules =
            Map.from(event.snapshot.value as Map);
        List<Map<String, dynamic>> tempModules = [];

        loadedModules.forEach((key, value) {
          Map<String, dynamic> moduleData = Map<String, dynamic>.from(value)
            ..putIfAbsent('index', () => int.parse(key.split('_')[1]));
          moduleData['moduleId'] = key;
          tempModules.add(moduleData);
        });

        tempModules
            .sort((a, b) => (a['index'] as int).compareTo(b['index'] as int));

        setState(() {
          modules = tempModules;
        });
      } else {
        setState(() {
          modules = [];
        });
      }
    }).catchError((error) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load modules: $error')));
    });
  }

  void _addModule() {
    int newIndex = modules.isNotEmpty ? modules.last['index'] + 1 : 0;

    Map<String, dynamic> newModule = {
      'title': 'New Module',
      'index': newIndex,
      'type': 'text',
    };

    String newModuleKey = 'module_$newIndex';
    databaseReference
        .child('courses')
        .child(courseId)
        .child('modules')
        .child(newModuleKey)
        .set(newModule)
        .then((_) {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        databaseReference
            .child('mentorcourse')
            .child(user.uid)
            .child(courseId)
            .child('modules')
            .child(newModuleKey)
            .set(newModule)
            .then((_) {
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Module added successfully')));
          _loadModules();
        }).catchError((error) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text('Failed to update mentor reference: $error')));
        });
      }
    }).catchError((error) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to add module: $error')));
    });
  }

  void _deleteModule(String moduleId) {
    databaseReference
        .child('courses')
        .child(courseId)
        .child('modules')
        .child(moduleId)
        .remove()
        .then((_) {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        databaseReference
            .child('mentorcourse')
            .child(user.uid)
            .child(courseId)
            .child('modules')
            .child(moduleId)
            .remove()
            .then((_) {
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Module deleted successfully')));
          _loadModules();
        }).catchError((error) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text('Failed to update mentor reference: $error')));
        });
      }
    }).catchError((error) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete module: $error')));
    });
  }

  void _editModule(String moduleId, Map<String, dynamic> module) {
    TextEditingController titleController =
        TextEditingController(text: module['title']);
    TextEditingController indexController =
        TextEditingController(text: module['index'].toString());

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Edit Module'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: InputDecoration(labelText: 'Module Title'),
              ),
              TextField(
                controller: indexController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: 'Module Index'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                if (titleController.text.isNotEmpty &&
                    indexController.text.isNotEmpty) {
                  int parsedIndex = int.tryParse(indexController.text) ?? 0;
                  Map<String, dynamic> updatedModule = {
                    'title': titleController.text,
                    'index': parsedIndex,
                  };
                  databaseReference
                      .child('courses')
                      .child(courseId)
                      .child('modules')
                      .child(moduleId)
                      .update(updatedModule)
                      .then((_) {
                    User? user = FirebaseAuth.instance.currentUser;
                    if (user != null) {
                      databaseReference
                          .child('mentorcourse')
                          .child(user.uid)
                          .child(courseId)
                          .child('modules')
                          .child(moduleId)
                          .update(updatedModule)
                          .then((_) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text('Module updated successfully')));
                        _loadModules();
                      }).catchError((error) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text(
                                'Failed to update mentor reference: $error')));
                      });
                    }
                  }).catchError((error) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content:
                            Text('Failed to update course reference: $error')));
                  });
                }
              },
              child: Text('Save'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  void _navigateToAppendContentPage(Map<String, dynamic> module) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AppendContentModulePage1(
          courseId: courseId,
          moduleIndex: module['index'],
          moduleName: module['title'],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Modules page of $courseId'),
        backgroundColor: Colors.blue,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(
                25), // Rounded corners at the bottom of the AppBar  QuizPage
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.quiz, color: const Color.fromARGB(255, 7, 7, 7)),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AddQuestionPage(courseId: courseId),
                  // Pass courseId here
                ),
              );
            },
          ),
          IconButton(
            icon: Icon(Icons.dataset_linked_rounded,
                color: const Color.fromARGB(255, 7, 7, 7)),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => QuizPage(courseId: courseId),
                  // Pass courseId here
                ),
              );
            },
          ),
        ],
        flexibleSpace: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.vertical(
              bottom: Radius.circular(25), // Match the rounded corners
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.blue.shade900, // Darker shadow for 3D effect
                offset: Offset(0, 5), // Shadow position (below the AppBar)
                blurRadius: 5, // Soften the shadow
                spreadRadius: 1.5, // Extend the shadow
              ),
            ],
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.blue.shade400, // Lighter blue at the top
                Colors.blue.shade800, // Darker blue at the bottom
              ],
            ),
          ),
        ),
      ),
      body: modules.isEmpty
          ? Center(
              child: Text(
                'No modules available',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
              ),
            )
          : ListView.builder(
              itemCount: modules.length,
              itemBuilder: (context, index) {
                var module = modules[index];

                return Card(
                  elevation: 5,
                  margin: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          module['title'] ?? 'No Title',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Index: ${module['index']}',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.blueAccent,
                          ),
                        ),
                        SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            ElevatedButton(
                              onPressed: () =>
                                  _editModule(module['moduleId'], module),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orange,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child: Text('Edit'),
                            ),
                            ElevatedButton(
                              onPressed: () =>
                                  _deleteModule(module['moduleId']),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child: Text('Delete'),
                            ),
                          ],
                        ),
                        SizedBox(height: 12),
                        GestureDetector(
                          onTap: () => _navigateToAppendContentPage(module),
                          child: Container(
                            padding: EdgeInsets.symmetric(vertical: 12),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: Colors.blue,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              'Append Content',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addModule,
        backgroundColor: Color.fromARGB(255, 43, 171, 251),
        child: Icon(Icons.add),
      ),
    );
  }
}
