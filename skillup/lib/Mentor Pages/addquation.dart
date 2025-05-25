// import 'package:flutter/material.dart';
// import 'package:firebase_database/firebase_database.dart';

// class AddQuestionPage extends StatefulWidget {
//   final String courseId;

//   const AddQuestionPage({super.key, required this.courseId});

//   @override
//   _AddQuestionPageState createState() => _AddQuestionPageState();
// }

// class _AddQuestionPageState extends State<AddQuestionPage> {
//   final DatabaseReference _database = FirebaseDatabase.instance.ref("courses");
//   final TextEditingController _questionController = TextEditingController();
//   final TextEditingController _op1Controller = TextEditingController();
//   final TextEditingController _op2Controller = TextEditingController();
//   final TextEditingController _op3Controller = TextEditingController();
//   final TextEditingController _op4Controller = TextEditingController();
//   final TextEditingController _rightOptionController = TextEditingController();
//   final TextEditingController _hintController = TextEditingController();
//   final TextEditingController _explanationController = TextEditingController();
//   String _selectedCategory = "easy";

//   void _addQuestion() {
//     String id = DateTime.now().millisecondsSinceEpoch.toString();
//     Map<String, dynamic> questionData = {
//       'question_$id': {
//         'CONTENT': """
//         {'id': '$id',
//         'question': '${_questionController.text}',
//         'op1': '${_op1Controller.text}',
//         'op2': '${_op2Controller.text}',
//         'op3': '${_op3Controller.text}',
//         'op4': '${_op4Controller.text}',
//         'right_option': '${_rightOptionController.text}',
//         'hint': '${_hintController.text}',
//         'explanation': '${_explanationController.text}'};
//         """
//       }
//     };

//     _database
//         .child(widget.courseId)
//         .child('questions')
//         .child(_selectedCategory)
//         .update(questionData)
//         .then((_) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text("Question added successfully!")),
//       );
//       _clearFields();
//     }).catchError((error) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text("Failed to add question: $error")),
//       );
//     });
//   }

//   void _clearFields() {
//     _questionController.clear();
//     _op1Controller.clear();
//     _op2Controller.clear();
//     _op3Controller.clear();
//     _op4Controller.clear();
//     _rightOptionController.clear();
//     _hintController.clear();
//     _explanationController.clear();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text(widget.courseId),
//         backgroundColor: Colors.blue,
//         shape: RoundedRectangleBorder(
//           borderRadius: BorderRadius.vertical(
//             bottom: Radius.circular(
//                 25), // Rounded corners at the bottom of the AppBar
//           ),
//         ),
//         flexibleSpace: Container(
//           decoration: BoxDecoration(
//             borderRadius: BorderRadius.vertical(
//               bottom: Radius.circular(25), // Match the rounded corners
//             ),
//             boxShadow: [
//               BoxShadow(
//                 color: const Color.fromARGB(
//                     168, 32, 32, 32), // Darker shadow for 3D effect
//                 offset: Offset(0, 5), // Shadow position (below the AppBar)
//                 blurRadius: 2, // Soften the shadow
//                 spreadRadius: 1.5, // Extend the shadow
//               ),
//             ],
//             gradient: LinearGradient(
//               begin: Alignment.topCenter,
//               end: Alignment.bottomCenter,
//               colors: [
//                 Colors.blue.shade400, // Lighter blue at the top
//                 Colors.blue.shade800, // Darker blue at the bottom
//               ],
//             ),
//           ),
//         ),
//       ),
//       body: Container(
//         decoration: BoxDecoration(
//           gradient: LinearGradient(
//             begin: Alignment.topLeft,
//             end: Alignment.bottomRight,
//             colors: [
//               const Color.fromARGB(255, 253, 254, 255),
//               const Color.fromARGB(255, 113, 141, 160),
//               Colors.blue,
//             ],
//             stops: const [0.1, 0.5, 0.9],
//           ),
//         ),
//         child: SingleChildScrollView(
//           padding: const EdgeInsets.all(20),
//           child: Transform(
//             transform: Matrix4.identity()
//               ..setEntry(3, 2, 0.001)
//               ..rotateX(0.008),
//             alignment: Alignment.center,
//             child: Container(
//               padding: const EdgeInsets.all(25),
//               decoration: BoxDecoration(
//                 color: Colors.white,
//                 borderRadius: BorderRadius.circular(25),
//                 boxShadow: [
//                   BoxShadow(
//                     color: Colors.blue.withOpacity(0.15),
//                     blurRadius: 25,
//                     spreadRadius: 2,
//                     offset: const Offset(0, 10),
//                   ),
//                 ],
//               ),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.stretch,
//                 children: [
//                   _buildCategoryDropdown(),
//                   const SizedBox(height: 25),
//                   _buildInputField(_questionController, "Question", Icons.quiz),
//                   _buildInputField(
//                       _op1Controller, "Option 1", Icons.radio_button_checked),
//                   _buildInputField(
//                       _op2Controller, "Option 2", Icons.radio_button_checked),
//                   _buildInputField(
//                       _op3Controller, "Option 3", Icons.radio_button_checked),
//                   _buildInputField(
//                       _op4Controller, "Option 4", Icons.radio_button_checked),
//                   _buildInputField(_rightOptionController, "Correct Answer",
//                       Icons.check_circle),
//                   _buildInputField(
//                       _hintController, "Hint", Icons.lightbulb_outline_rounded),
//                   _buildInputField(
//                       _explanationController, "Explanation", Icons.description),
//                   const SizedBox(height: 30),
//                   _buildAddButton(),
//                 ],
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildCategoryDropdown() {
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 20),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(15),
//         border: Border.all(color: Colors.blue.shade300, width: 1.5),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.blue.shade100,
//             blurRadius: 12,
//             offset: const Offset(0, 6),
//           ),
//         ],
//       ),
//       child: DropdownButtonHideUnderline(
//         child: DropdownButton<String>(
//           value: _selectedCategory,
//           isExpanded: true,
//           icon: Icon(Icons.arrow_drop_down_circle,
//               color: Colors.blue.shade700, size: 28),
//           style: TextStyle(
//             fontSize: 16,
//             color: Colors.blue.shade900,
//             fontWeight: FontWeight.w600,
//           ),
//           dropdownColor: Colors.white,
//           borderRadius:
//               BorderRadius.circular(15), // Rounded corners for dropdown menu
//           items: ["easy", "medium", "hard"].map((String value) {
//             return DropdownMenuItem<String>(
//               value: value,
//               child: Padding(
//                 padding: const EdgeInsets.symmetric(vertical: 8.0),
//                 child: Text(
//                   value.toUpperCase(),
//                   style: TextStyle(
//                     color: Colors.blue.shade800,
//                     fontSize: 16,
//                   ),
//                 ),
//               ),
//             );
//           }).toList(),
//           onChanged: (String? newValue) {
//             setState(() => _selectedCategory = newValue!);
//           },
//         ),
//       ),
//     );
//   }

//   Widget _buildInputField(
//       TextEditingController controller, String label, IconData icon) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 10),
//       child: TextField(
//         controller: controller,
//         maxLines: null,
//         decoration: InputDecoration(
//           labelText: label,
//           labelStyle: TextStyle(
//             color: Colors.blue.shade600,
//             fontWeight: FontWeight.w500,
//           ),
//           prefixIcon: Container(
//             margin: const EdgeInsets.only(right: 15),
//             decoration: BoxDecoration(
//               border: Border(
//                 right: BorderSide(
//                   color: Colors.blue.shade200,
//                   width: 1.5,
//                 ),
//               ),
//             ),
//             child: Padding(
//               padding: const EdgeInsets.symmetric(horizontal: 12),
//               child: Icon(icon, color: Colors.blue.shade700),
//             ),
//           ),
//           filled: true,
//           fillColor: Colors.blue.shade50.withOpacity(0.8),
//           border: OutlineInputBorder(
//             borderRadius: BorderRadius.circular(15),
//             borderSide: BorderSide.none,
//           ),
//           contentPadding: const EdgeInsets.symmetric(
//             vertical: 18,
//             horizontal: 20,
//           ),
//           floatingLabelBehavior: FloatingLabelBehavior.never,
//         ),
//         style: TextStyle(
//           color: Colors.blue.shade900,
//           fontSize: 15,
//         ),
//       ),
//     );
//   }

//   Widget _buildAddButton() {
//     return MouseRegion(
//       onEnter: (_) => setState(() {}),
//       child: AnimatedContainer(
//         duration: const Duration(milliseconds: 200),
//         decoration: BoxDecoration(
//           borderRadius: BorderRadius.circular(15),
//           boxShadow: [
//             BoxShadow(
//               color: Colors.blueAccent.withOpacity(0.4),
//               blurRadius: 10,
//               offset: const Offset(0, 4),
//             ),
//           ],
//         ),
//         child: ElevatedButton(
//           onPressed: _addQuestion,
//           style: ElevatedButton.styleFrom(
//             backgroundColor: Colors.blue.shade700,
//             foregroundColor: Colors.white,
//             elevation: 8,
//             padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 35),
//             shape: RoundedRectangleBorder(
//               borderRadius: BorderRadius.circular(15),
//             ),
//             textStyle: const TextStyle(
//               fontSize: 17,
//               fontWeight: FontWeight.bold,
//               letterSpacing: 1.1,
//             ),
//           ),
//           child: const Text("ADD QUESTION"),
//         ),
//       ),
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class AddQuestionPage extends StatefulWidget {
  final String courseId;

  const AddQuestionPage({super.key, required this.courseId});

  @override
  _AddQuestionPageState createState() => _AddQuestionPageState();
}

class _AddQuestionPageState extends State<AddQuestionPage> {
  final DatabaseReference _database = FirebaseDatabase.instance.ref("courses");
  final TextEditingController _contentController = TextEditingController();
  String _selectedCategory = "easy";

  void _addQuestion() {
    String id = DateTime.now().millisecondsSinceEpoch.toString();
    Map<String, dynamic> questionData = {
      'question_$id': {
        'id': id,
        'CONTENT': _contentController.text, // Directly store the content
      }
    };

    _database
        .child(widget.courseId)
        .child('questions')
        .child(_selectedCategory)
        .update(questionData)
        .then((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Question added successfully!")),
      );
      _clearFields();
    }).catchError((error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to add question: $error")),
      );
    });
  }

  void _clearFields() {
    _contentController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.courseId),
        backgroundColor: Colors.blue,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(25),
          ),
        ),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.vertical(
              bottom: Radius.circular(25),
            ),
            boxShadow: [
              BoxShadow(
                color: const Color.fromARGB(168, 32, 32, 32),
                offset: Offset(0, 5),
                blurRadius: 2,
                spreadRadius: 1.5,
              ),
            ],
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.blue.shade400,
                Colors.blue.shade800,
              ],
            ),
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color.fromARGB(255, 253, 254, 255),
              const Color.fromARGB(255, 113, 141, 160),
              Colors.blue,
            ],
            stops: const [0.1, 0.5, 0.9],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Transform(
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.001)
              ..rotateX(0.008),
            alignment: Alignment.center,
            child: Container(
              padding: const EdgeInsets.all(25),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(25),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.withOpacity(0.15),
                    blurRadius: 25,
                    spreadRadius: 2,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildCategoryDropdown(),
                  const SizedBox(height: 25),
                  _buildContentField(),
                  const SizedBox(height: 30),
                  _buildAddButton(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.blue.shade300, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.shade100,
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedCategory,
          isExpanded: true,
          icon: Icon(Icons.arrow_drop_down_circle,
              color: Colors.blue.shade700, size: 28),
          style: TextStyle(
            fontSize: 16,
            color: Colors.blue.shade900,
            fontWeight: FontWeight.w600,
          ),
          dropdownColor: Colors.white,
          borderRadius: BorderRadius.circular(15),
          items: ["easy", "medium", "hard"].map((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Text(
                  value.toUpperCase(),
                  style: TextStyle(
                    color: Colors.blue.shade800,
                    fontSize: 16,
                  ),
                ),
              ),
            );
          }).toList(),
          onChanged: (String? newValue) {
            setState(() => _selectedCategory = newValue!);
          },
        ),
      ),
    );
  }

  Widget _buildContentField() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: TextField(
        controller: _contentController,
        maxLines: null,
        decoration: InputDecoration(
          labelText: "Content",
          labelStyle: TextStyle(
            color: Colors.blue.shade600,
            fontWeight: FontWeight.w500,
          ),
          prefixIcon: Container(
            margin: const EdgeInsets.only(right: 15),
            decoration: BoxDecoration(
              border: Border(
                right: BorderSide(
                  color: Colors.blue.shade200,
                  width: 1.5,
                ),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Icon(Icons.text_fields, color: Colors.blue.shade700),
            ),
          ),
          filled: true,
          fillColor: Colors.blue.shade50.withOpacity(0.8),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(
            vertical: 18,
            horizontal: 20,
          ),
          floatingLabelBehavior: FloatingLabelBehavior.never,
        ),
        style: TextStyle(
          color: Colors.blue.shade900,
          fontSize: 15,
        ),
      ),
    );
  }

  Widget _buildAddButton() {
    return MouseRegion(
      onEnter: (_) => setState(() {}),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.blueAccent.withOpacity(0.4),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: _addQuestion,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue.shade700,
            foregroundColor: Colors.white,
            elevation: 8,
            padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 35),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            textStyle: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.1,
            ),
          ),
          child: const Text("ADD QUESTION"),
        ),
      ),
    );
  }
}
