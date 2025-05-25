import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:firebase_database/firebase_database.dart';
import '/Mentor%20Pages/Manage%20Courses%20Page.dart';
import 'package:flutter/material.dart';
import 'dart:math';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';

final supabase = Supabase.instance.client;

class CreateCoursePage extends StatefulWidget {
  const CreateCoursePage({super.key});

  @override
  _CreateCoursePageState createState() => _CreateCoursePageState();
}

class _CreateCoursePageState extends State<CreateCoursePage> {
  final _formKey = GlobalKey<FormState>();

  String title = '';
  String description = '';
  String category = '';
  String level = '';
  String language = '';
  String mentorId = '';
  String price = '';
  String duration = '';
  String accessType = 'Free';
  String imageUrl = '';

  TextEditingController titleController = TextEditingController();
  TextEditingController descriptionController = TextEditingController();
  TextEditingController categoryController = TextEditingController();
  TextEditingController levelController = TextEditingController();
  TextEditingController languageController = TextEditingController();
  TextEditingController durationController = TextEditingController();
  TextEditingController priceController = TextEditingController();
  TextEditingController imageUrlController = TextEditingController();
  TextEditingController priseController = TextEditingController();

  final databaseReference = FirebaseDatabase.instance.ref();

  @override
  void dispose() {
    titleController.dispose();
    descriptionController.dispose();
    categoryController.dispose();
    languageController.dispose();
    durationController.dispose();
    imageUrlController.dispose();
    priceController.dispose();
    levelController.dispose();
    super.dispose();
  }

  Future<void> _pickAndUploadImage() async {
    final picker = ImagePicker();
    final XFile? pickedFile =
        await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      File imageFile = File(pickedFile.path);

      try {
        final String fileName =
            'images/${DateTime.now().millisecondsSinceEpoch}.jpg';
        await supabase.storage.from('image').upload(fileName, imageFile);

        final publicUrl = supabase.storage.from('image').getPublicUrl(fileName);
        setState(() {
          imageUrlController.text = publicUrl;
          imageUrl = publicUrl;
        });
      } catch (e) {
        print('Error uploading image: $e');
      }
    }
  }

  void _saveCourse() async {
    if (_formKey.currentState?.validate() ?? false) {
      fb_auth.User? user = fb_auth
          .FirebaseAuth.instance.currentUser; // ✅ Use Firebase User with prefix
      if (user != null) {
        mentorId = user.uid;

        String courseId = (10000 + Random().nextInt(90000)).toString();

        Map<String, dynamic> courseData = {
          'courseId': courseId,
          'title': title,
          'description': description,
          'imageUrl': imageUrl,
          'category': category,
          'level': level,
          'language': language,
          'mentorId': mentorId,
          'price': price,
          'duration': duration,
          'status': 'not verified',
          'course_content': {
            'quiz_modules': {'heading': 'none'},
          },
          'project_submission_status': 'none',
        };

        databaseReference
            .child('courses')
            .child(courseId)
            .set(courseData)
            .then((_) {
          databaseReference
              .child('mentorcourse')
              .child(mentorId)
              .child(courseId)
              .set(courseData)
              .then((_) {
            ScaffoldMessenger.of(context)
                .showSnackBar(SnackBar(content: Text('Course Created!')));

            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => ManageCoursesPage()),
            );
          }).catchError((error) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text('Failed to save to mentorcourse: $error')));
          });
        }).catchError((error) {
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Failed to create course: $error')));
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Center(child: Text("Create Course")),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: <Widget>[
              _buildCardInput(
                controller: titleController,
                label: 'Course Title',
                validator: (value) => value == null || value.isEmpty
                    ? 'Please enter a title'
                    : null,
                onChanged: (value) => title = value,
              ),
              SizedBox(height: 15),
              _buildCardInput(
                controller: descriptionController,
                label: 'Course Description',
                hintText: 'Applications of course, use cases...',
                validator: (value) => value == null || value.isEmpty
                    ? 'Please enter a description'
                    : null,
                onChanged: (value) => description = value,
                maxLines: 4,
              ),
              SizedBox(height: 15),
              _buildDropdownInput(
                label: 'Course Category',
                value: category.isEmpty ? null : category,
                items: [
                  'Coding Languages',
                  'Web Development',
                  'App Development',
                  'Full Stack Development',
                  'Artificial Intelligence',
                  'Database',
                  'Marketing'
                ],
                onChanged: (value) => setState(() => category = value ?? ''),
              ),
              SizedBox(height: 15),
              _buildImageInput(),
              SizedBox(height: 15),
              _buildDropdownInput(
                label: 'Language',
                value: language.isEmpty ? null : language,
                items: ['Telugu', 'Hindi', 'English'],
                onChanged: (value) => setState(() => language = value ?? ''),
              ),
              SizedBox(height: 15),
              _buildCardInput(
                controller: durationController,
                label: 'Duration (in days)',
                keyboardType: TextInputType.number,
                validator: (value) => value == null || value.isEmpty
                    ? 'Please enter a duration'
                    : null,
                onChanged: (value) => duration = value,
              ),
              SizedBox(height: 15),
              _buildCardInput(
                controller: priceController,
                label: 'prise',
                hintText: 'cost of course',
                validator: (value) => value == null || value.isEmpty
                    ? 'Please enter prise'
                    : null,
                onChanged: (value) => price = value,
                maxLines: 4,
              ),
              SizedBox(height: 20),
              _buildDropdownInput(
                label: 'Course Category',
                value: level.isEmpty ? null : level,
                items: ['EASY', 'MEDIUM', 'HARD'],
                onChanged: (value) => setState(() => level = value ?? ''),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _saveCourse,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 83, 160, 255),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  padding: EdgeInsets.symmetric(vertical: 16),
                ),
                child: Text('Create Course',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageInput() {
    return Card(
      elevation: 5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: imageUrlController,
                readOnly: true,
                decoration: InputDecoration(
                    labelText: 'Course Image', border: OutlineInputBorder()),
              ),
            ),
            IconButton(
                icon: Icon(Icons.image, color: Colors.blue),
                onPressed: _pickAndUploadImage),
          ],
        ),
      ),
    );
  }
}

Widget _buildCardInput({
  required TextEditingController controller,
  required String label,
  String? hintText,
  required String? Function(String?) validator,
  required Function(String) onChanged,
  int? maxLines,
  TextInputType? keyboardType,
}) {
  return Card(
    elevation: 5,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    child: Padding(
      padding: const EdgeInsets.all(8.0),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          hintText: hintText,
          border: OutlineInputBorder(),
        ),
        validator: validator,
        onChanged: onChanged,
        maxLines: maxLines ?? 1,
        keyboardType: keyboardType,
      ),
    ),
  );
}

Widget _buildDropdownInput({
  required String label,
  required String? value,
  required List<String> items,
  required Function(String?) onChanged,
}) {
  return Card(
    elevation: 5,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    child: Padding(
      padding: const EdgeInsets.all(8.0),
      child: DropdownButtonFormField<String>(
        value: value,
        items: items
            .map((item) => DropdownMenuItem(
                  value: item,
                  child: Text(item),
                ))
            .toList(),
        onChanged: onChanged,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(),
        ),
      ),
    ),
  );
}
