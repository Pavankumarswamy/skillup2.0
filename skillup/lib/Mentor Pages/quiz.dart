// import 'dart:convert'; // Import this to decode the JSON string
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/material.dart';
// import 'package:firebase_database/firebase_database.dart';

// class QuizPage extends StatefulWidget {
//   final String courseId;
//   QuizPage({required this.courseId});

//   @override
//   _QuizPageState createState() => _QuizPageState();
// }

// class _QuizPageState extends State<QuizPage> {
//   List<Map<String, dynamic>> questions = [];
//   int currentQuestionIndex = 0;
//   int score = 0;
//   bool answered = false;
//   String? selectedAnswer;

//   @override
//   void initState() {
//     super.initState();
//     fetchQuestions();
//   }

//   void fetchQuestions() async {
//     try {
//       DatabaseReference ref = FirebaseDatabase.instance
//           .ref("courses/${widget.courseId}/questions/easy");

//       DatabaseEvent event = await ref.once();

//       if (event.snapshot.value != null) {
//         Map<dynamic, dynamic> data =
//             event.snapshot.value as Map<dynamic, dynamic>;

//         setState(() {
//           questions = data.values.map((e) {
//             // Get the raw JSON string
//             var content = e['CONTENT'];

//             // Remove any unwanted characters (like the semicolon at the end)
//             var cleanContent = content.replaceAll(";", "");

//             // Decode the cleaned-up JSON string
//             var decodedContent = json.decode(cleanContent);

//             return {
//               'id': decodedContent['id'],
//               'question': decodedContent['question'],
//               'op1': decodedContent['op1'],
//               'op2': decodedContent['op2'],
//               'op3': decodedContent['op3'],
//               'op4': decodedContent['op4'],
//               'right_option': decodedContent['right_option'],
//               'hint': decodedContent['hint'],
//               'explanation': decodedContent['explanation'],
//             };
//           }).toList();
//         });
//       } else {
//         setState(() {
//           // Handle empty or missing data
//           questions = [];
//         });
//         print("No questions found for this course.");
//       }
//     } catch (e) {
//       setState(() {
//         questions = [];
//       });
//       print("Error fetching questions: $e");
//     }
//   }

//   void checkAnswer(String answer) {
//     setState(() {
//       answered = true;
//       selectedAnswer = answer;
//       if (answer == questions[currentQuestionIndex]['right_option']) {
//         score++;
//       }
//     });
//   }

//   void nextQuestion() {
//     if (currentQuestionIndex < questions.length - 1) {
//       setState(() {
//         currentQuestionIndex++;
//         answered = false;
//         selectedAnswer = null;
//       });
//     } else {
//       showResult();
//     }
//   }

//   void showResult() {
//     String userId = FirebaseAuth.instance.currentUser?.uid ?? "Unknown User";
//     String courseId = widget.courseId;

//     DatabaseReference resultsRef =
//         FirebaseDatabase.instance.ref('results/$courseId/$userId');

//     DatabaseReference newAttemptRef = resultsRef.push();

//     newAttemptRef.set({
//       'score': score,
//       'total': questions.length,
//       'timestamp': DateTime.now().toIso8601String(),
//     }).then((_) {
//       showDialog(
//         context: context,
//         builder: (context) => AlertDialog(
//           title: Text("Quiz Completed!"),
//           content: Text("Your Score: $score / ${questions.length}"),
//           actions: [
//             TextButton(
//               onPressed: () {
//                 Navigator.pop(context);
//                 Navigator.pushNamed(context, '/');
//               },
//               child: Text("OK"),
//             ),
//           ],
//         ),
//       );
//     }).catchError((error) {
//       print("Error saving result: $error");
//     });
//   }

//   int getAttemptNumber(String userId, String courseId) {
//     return 1;
//   }

//   @override
//   Widget build(BuildContext context) {
//     if (questions.isEmpty) {
//       return Scaffold(
//         backgroundColor: Colors.black,
//         appBar: _buildAppBar(),
//         body: Center(
//           child: Column(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               const CircularProgressIndicator(
//                 color: Color.fromARGB(255, 0, 145, 255),
//               ),
//               const SizedBox(height: 20),
//               Text(
//                 "Initializing Quiz Protocol...",
//                 style: TextStyle(
//                   color: Colors.cyanAccent,
//                   fontSize: 18,
//                   fontFamily: 'RobotoMono',
//                 ),
//               ),
//             ],
//           ),
//         ),
//       );
//     }

//     var question = questions[currentQuestionIndex];
//     return Scaffold(
//       backgroundColor: Colors.black,
//       appBar: _buildAppBar(),
//       body: SafeArea(
//         child: Padding(
//           padding: const EdgeInsets.all(20.0),
//           child: LayoutBuilder(
//             builder: (context, constraints) {
//               return SingleChildScrollView(
//                 child: ConstrainedBox(
//                   constraints: BoxConstraints(
//                     minHeight: constraints.maxHeight,
//                   ),
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     mainAxisSize: MainAxisSize.min,
//                     children: [
//                       _buildProgressIndicator(),
//                       const SizedBox(height: 30),
//                       _buildQuestionCard(question),
//                       const SizedBox(height: 20),
//                       ..._buildAnswerOptions(question),
//                       if (answered) _buildFeedbackSection(question),
//                       // Add safe area padding at the bottom
//                       SizedBox(height: MediaQuery.of(context).padding.bottom),
//                     ],
//                   ),
//                 ),
//               );
//             },
//           ),
//         ),
//       ),
//     );
//   }

//   AppBar _buildAppBar() {
//     return AppBar(
//       title: Text(
//         "Quiz",
//         style: TextStyle(
//           color: Colors.cyanAccent,
//           fontSize: 24,
//           fontFamily: 'Orbitron',
//           shadows: [
//             Shadow(
//               color: Colors.blueAccent,
//               blurRadius: 10,
//             ),
//           ],
//         ),
//       ),
//       centerTitle: true,
//       backgroundColor: Colors.black,
//       elevation: 0,
//       iconTheme: const IconThemeData(color: Colors.cyanAccent),
//     );
//   }

//   Widget _buildProgressIndicator() {
//     return Row(
//       mainAxisAlignment: MainAxisAlignment.center,
//       children: [
//         Text(
//           "Question ${currentQuestionIndex + 1}/${questions.length}",
//           style: TextStyle(
//             color: Colors.cyanAccent,
//             fontSize: 16,
//             fontFamily: 'RobotoMono',
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _buildQuestionCard(Map<String, dynamic> question) {
//     return Container(
//       width: double.infinity,
//       padding: const EdgeInsets.all(20),
//       decoration: BoxDecoration(
//         color: Colors.black,
//         borderRadius: BorderRadius.circular(15),
//         border: Border.all(color: Colors.cyanAccent, width: 2),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.cyanAccent.withOpacity(0.2),
//             blurRadius: 20,
//             spreadRadius: 2,
//           ),
//         ],
//       ),
//       child: Text(
//         "Q${currentQuestionIndex + 1}: ${question['question']}",
//         style: TextStyle(
//           color: Colors.white,
//           fontSize: 20,
//           fontWeight: FontWeight.bold,
//           fontFamily: 'RobotoMono',
//         ),
//       ),
//     );
//   }

//   List<Widget> _buildAnswerOptions(Map<String, dynamic> question) {
//     return [
//       question['op1'],
//       question['op2'],
//       question['op3'],
//       question['op4'],
//     ].map((option) {
//       final isCorrect = option == question['right_option'];
//       final isSelected = option == selectedAnswer;

//       return ConstrainedBox(
//         constraints: BoxConstraints(
//           maxHeight: 80, // Limit option height
//         ),
//         child: Padding(
//           padding: const EdgeInsets.symmetric(vertical: 8.0),
//           child: AnimatedContainer(
//             duration: const Duration(milliseconds: 300),
//             decoration: BoxDecoration(
//               gradient: answered
//                   ? (isCorrect
//                       ? const LinearGradient(
//                           colors: [Colors.green, Colors.lightGreen])
//                       : (isSelected
//                           ? const LinearGradient(
//                               colors: [Colors.red, Colors.redAccent])
//                           : null))
//                   : const LinearGradient(
//                       colors: [Colors.blueAccent, Colors.purpleAccent],
//                     ),
//               borderRadius: BorderRadius.circular(10),
//               boxShadow: [
//                 if (!answered)
//                   BoxShadow(
//                     color: Colors.blueAccent.withOpacity(0.3),
//                     blurRadius: 10,
//                     spreadRadius: 2,
//                   ),
//               ],
//             ),
//             child: Material(
//               color: Colors.transparent,
//               child: InkWell(
//                 onTap: answered ? null : () => checkAnswer(option),
//                 borderRadius: BorderRadius.circular(10),
//                 child: Container(
//                   padding: const EdgeInsets.all(16),
//                   decoration: BoxDecoration(
//                     borderRadius: BorderRadius.circular(10),
//                     border: Border.all(
//                       color: Colors.cyanAccent.withOpacity(0.5),
//                       width: 1,
//                     ),
//                   ),
//                   child: Row(
//                     children: [
//                       if (answered && isCorrect)
//                         const Icon(Icons.check_circle, color: Colors.white),
//                       if (answered && isSelected && !isCorrect)
//                         const Icon(Icons.cancel, color: Colors.white),
//                       Expanded(
//                         child: Text(
//                           option,
//                           style: TextStyle(
//                             color: Colors.white,
//                             fontSize: 16,
//                             fontFamily: 'RobotoMono',
//                           ),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//             ),
//           ),
//         ),
//       );
//     }).toList();
//   }

//   Widget _buildFeedbackSection(Map<String, dynamic> question) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         const SizedBox(height: 20),
//         _buildInfoCard(
//           title: "HINT",
//           content: question['hint'],
//           color: Colors.amberAccent,
//         ),
//         const SizedBox(height: 20),
//         _buildInfoCard(
//           title: "EXPLANATION",
//           content: question['explanation'],
//           color: Colors.cyanAccent,
//         ),
//         const SizedBox(height: 30),
//         Center(
//           child: ElevatedButton(
//             onPressed: nextQuestion,
//             style: ElevatedButton.styleFrom(
//               backgroundColor: Colors.transparent,
//               padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
//               shape: RoundedRectangleBorder(
//                 borderRadius: BorderRadius.circular(25),
//                 side: const BorderSide(color: Colors.cyanAccent, width: 2),
//               ),
//               elevation: 10,
//               shadowColor: Colors.cyanAccent.withOpacity(0.3),
//             ),
//             child: ShaderMask(
//               shaderCallback: (bounds) => const LinearGradient(
//                 colors: [Colors.cyanAccent, Colors.blueAccent],
//               ).createShader(bounds),
//               child: const Row(
//                 mainAxisSize: MainAxisSize.min,
//                 children: [
//                   Text(
//                     'NEXT QUESTION',
//                     style: TextStyle(
//                       fontSize: 16,
//                       fontWeight: FontWeight.bold,
//                       color: Colors.white,
//                     ),
//                   ),
//                   SizedBox(width: 10),
//                   Icon(Icons.arrow_forward, color: Colors.white),
//                 ],
//               ),
//             ),
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _buildInfoCard(
//       {required String title, required String content, required Color color}) {
//     return Container(
//       width: double.infinity,
//       padding: const EdgeInsets.all(15),
//       decoration: BoxDecoration(
//         color: color.withOpacity(0.1),
//         borderRadius: BorderRadius.circular(10),
//         border: Border.all(color: color.withOpacity(0.3), width: 1),
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Text(
//             title,
//             style: TextStyle(
//               color: color,
//               fontSize: 14,
//               fontWeight: FontWeight.bold,
//               fontFamily: 'RobotoMono',
//               letterSpacing: 1.2,
//             ),
//           ),
//           const SizedBox(height: 8),
//           Text(
//             content,
//             style: TextStyle(
//               color: Colors.white.withOpacity(0.9),
//               fontSize: 14,
//               fontFamily: 'RobotoMono',
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
import 'dart:async';
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'dart:math';

class QuizPage extends StatefulWidget {
  final String courseId;
  const QuizPage({super.key, required this.courseId});

  @override
  _QuizPageState createState() => _QuizPageState();
}

class _QuizPageState extends State<QuizPage> {
  List<Map<String, dynamic>> questions = [];
  int currentQuestionIndex = 0;
  int score = 0;
  bool answered = false;
  String? selectedAnswer;
  int hintCount = 3;
  bool showHint = false;
  Timer? _timer;
  int _timeLeft = 7 * 60; // 7 minutes

  @override
  void initState() {
    super.initState();
    fetchQuestions();
    startTimer();
  }

  void startTimer() {
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (_timeLeft > 0) {
        setState(() {
          _timeLeft--;
        });
      } else {
        _timer?.cancel();
        showResult();
      }
    });
  }

  void navigateToQuestion(int index) {
    setState(() {
      currentQuestionIndex = index;
      answered = false;
      selectedAnswer = null;
      showHint = false;
    });
  }

  void fetchQuestions() async {
    try {
      List<String> levels = ['easy', 'medium', 'hard'];
      Map<String, List<Map<String, dynamic>>> categorizedQuestions = {
        'easy': [],
        'medium': [],
        'hard': [],
      };

      for (String level in levels) {
        DatabaseReference ref = FirebaseDatabase.instance
            .ref("courses/${widget.courseId}/questions/$level");

        DatabaseEvent event = await ref.once();

        if (event.snapshot.value != null) {
          Map<dynamic, dynamic> data =
              event.snapshot.value as Map<dynamic, dynamic>;

          data.forEach((key, value) {
            if (value.containsKey('CONTENT')) {
              var content = value['CONTENT'];
              var cleanContent = content.replaceAll(";", "").trim();
              Map<String, dynamic> decodedContent;

              try {
                // Try parsing as JSON directly (Type 2)
                decodedContent = json.decode(cleanContent);
              } catch (_) {
                // If parsing fails, assume it's Type 1 and fix formatting
                String formattedJson = cleanContent
                    .replaceAll(
                        "'", "\"") // Convert single quotes to double quotes
                    .replaceAllMapped(RegExp(r'(\w+)\s*:\s*'), (match) {
                  return '"${match.group(1)}": ';
                }) // Ensure keys are properly formatted
                    .replaceAllMapped(RegExp(r'":\s*"([^"]*?)"'), (match) {
                  return '": "${match.group(1).replaceAll('"', '\\"')}"';
                }); // Escape existing double quotes inside values

                decodedContent = json.decode(formattedJson);
              }

              categorizedQuestions[level]?.add({
                'id': decodedContent['id'],
                'question': decodedContent['question'],
                'op1': decodedContent['op1'],
                'op2': decodedContent['op2'],
                'op3': decodedContent['op3'],
                'op4': decodedContent['op4'],
                'right_option': decodedContent['right_option'] ?? '',
                'hint': decodedContent['hint'],
                'explanation': decodedContent['explanation'],
              });
            }
          });
        }
      }

      // Shuffle individual difficulty lists
      categorizedQuestions['easy']?.shuffle(Random());
      categorizedQuestions['medium']?.shuffle(Random());
      categorizedQuestions['hard']?.shuffle(Random());

      // Select 10 questions with a fair mix (3 easy, 3 medium, 4 hard)
      List<Map<String, dynamic>> selectedQuestions = [
        ...categorizedQuestions['easy']!.take(3),
        ...categorizedQuestions['medium']!.take(3),
        ...categorizedQuestions['hard']!.take(4),
      ];

      // Shuffle final selection for randomness
      selectedQuestions.shuffle(Random());

      setState(() {
        questions = selectedQuestions;
      });
    } catch (e) {
      setState(() {
        questions = [];
      });
      print("Error fetching questions: $e");
    }
  }

  void checkAnswer(String answer) {
    setState(() {
      answered = true;
      selectedAnswer = answer;
      if (answer == questions[currentQuestionIndex]['right_option']) {
        score++;
      }
    });
  }

  void nextQuestion() {
    if (currentQuestionIndex < questions.length - 1) {
      setState(() {
        currentQuestionIndex++;
        answered = false;
        selectedAnswer = null;
        showHint = false; // Reset hint visibility for the next question
      });
    } else {
      showResult();
    }
  }

  void revealHint() {
    if (hintCount > 0) {
      setState(() {
        showHint = true;
        hintCount--;
      });
    }
  }

  void showResult() {
    String userId = FirebaseAuth.instance.currentUser?.uid ?? "Unknown User";
    String courseId = widget.courseId;

    DatabaseReference resultsRef =
        FirebaseDatabase.instance.ref('results/$courseId/$userId');

    DatabaseReference newAttemptRef = resultsRef.push();

    newAttemptRef.set({
      'score': score,
      'total': questions.length,
      'timestamp': DateTime.now().toIso8601String(),
    }).then((_) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text("Quiz Completed!"),
          content: Text("Your Score: $score / ${questions.length}"),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/');
              },
              child: Text("OK"),
            ),
          ],
        ),
      );
    }).catchError((error) {
      print("Error saving result: $error");
    });
  }

  @override
  Widget build(BuildContext context) {
    if (questions.isEmpty) {
      return Scaffold(
        backgroundColor: Colors.black,
        appBar: _buildAppBar(),
        body: Center(
          child: CircularProgressIndicator(color: Colors.cyanAccent),
        ),
      );
    }

    var question = questions[currentQuestionIndex];

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: _buildAppBar(),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildProgressIndicator(),
              const SizedBox(height: 30),
              // Question navigation menu - Balls
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: List.generate(
                    questions.length,
                    (index) {
                      bool isAnswered = index <= currentQuestionIndex &&
                          answered; // Check if the question has been answered
                      return GestureDetector(
                        onTap: () => navigateToQuestion(index),
                        child: Container(
                          margin: EdgeInsets.all(5),
                          width: 35,
                          height: 35,
                          decoration: BoxDecoration(
                            color: isAnswered
                                ? Colors.green
                                : (index == currentQuestionIndex
                                    ? Colors.blue
                                    : Colors.grey),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              "${index + 1}",
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 20),
              AnimatedSwitcher(
                duration: Duration(milliseconds: 500),
                transitionBuilder: (Widget child, Animation<double> animation) {
                  return FadeTransition(opacity: animation, child: child);
                },
                child: _buildQuestionCard(question,
                    key: ValueKey(currentQuestionIndex)),
              ),
              const SizedBox(height: 20),
              ..._buildAnswerOptions(question),
              if (answered) _buildFeedbackSection(question),
              // Always show Previous and Next buttons
              Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Previous button
                    if (currentQuestionIndex >
                        0) // Only show "Previous" button if we're not on the first question
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            setState(() {
                              currentQuestionIndex--;
                              answered = false;
                              selectedAnswer = null;
                              showHint = false;
                            });
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            padding: EdgeInsets.symmetric(
                                horizontal: 20, vertical: 15),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(25),
                              side: BorderSide(
                                  color: Colors.cyanAccent, width: 2),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.arrow_back, color: Colors.white),
                              SizedBox(width: 10),
                              Text("PREVIOUS",
                                  style: TextStyle(color: Colors.white)),
                            ],
                          ),
                        ),
                      ),
                    // Next button
                    Expanded(
                      child: ElevatedButton(
                        onPressed: nextQuestion,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          padding: EdgeInsets.symmetric(
                              horizontal: 20, vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                            side:
                                BorderSide(color: Colors.cyanAccent, width: 2),
                          ),
                        ),
                        child: Row(
                          children: [
                            Text("NEXT", style: TextStyle(color: Colors.white)),
                            SizedBox(width: 10),
                            Icon(Icons.arrow_forward, color: Colors.white),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildAnswerOptions(Map<String, dynamic> question) {
    return [
      question['op1'],
      question['op2'],
      question['op3'],
      question['op4'],
    ].map((option) {
      final isCorrect = option == question['right_option'];
      final isSelected = option == selectedAnswer;

      return ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: 80, // Limit option height
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            decoration: BoxDecoration(
              gradient: answered
                  ? (isCorrect
                      ? const LinearGradient(
                          colors: [Colors.green, Colors.lightGreen])
                      : (isSelected
                          ? const LinearGradient(
                              colors: [Colors.red, Colors.redAccent])
                          : null))
                  : const LinearGradient(
                      colors: [Colors.blueAccent, Colors.purpleAccent],
                    ),
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                if (!answered)
                  BoxShadow(
                    color: Colors.blueAccent.withOpacity(0.3),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: answered ? null : () => checkAnswer(option),
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: Colors.cyanAccent.withOpacity(0.5),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      if (answered && isCorrect)
                        const Icon(Icons.check_circle, color: Colors.white),
                      if (answered && isSelected && !isCorrect)
                        const Icon(Icons.cancel, color: Colors.white),
                      Expanded(
                        child: Text(
                          option,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontFamily: 'RobotoMono',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }).toList();
  }

  AppBar _buildAppBar() {
    return AppBar(
      title: Text("Quiz", style: TextStyle(color: Colors.cyanAccent)),
      centerTitle: true,
      backgroundColor: Colors.black,
      elevation: 0,
      iconTheme: IconThemeData(color: Colors.cyanAccent),
      actions: [
        IconButton(
          icon: Icon(Icons.lightbulb,
              color: hintCount > 0 ? Colors.yellow : Colors.grey),
          tooltip:
              hintCount > 0 ? "Reveal Hint ($hintCount left)" : "No hints left",
          onPressed: hintCount > 0 ? revealHint : null,
        ),
      ],
    );
  }

  Widget _buildProgressIndicator() {
    Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          "Question ${currentQuestionIndex + 1}/${questions.length}",
          style: TextStyle(color: Colors.cyanAccent),
        ),
        Text(
          "${(_timeLeft ~/ 60).toString().padLeft(2, '0')}:${(_timeLeft % 60).toString().padLeft(2, '0')}",
          style:
              TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold),
        ),
      ],
    );
    return Center(
      child: Text(
        "Question ${currentQuestionIndex + 1}/${questions.length}",
        style: TextStyle(color: Colors.cyanAccent),
      ),
    );
  }

  Widget _buildQuestionCard(Map<String, dynamic> question, {Key? key}) {
    return Container(
      key: key,
      width: double.infinity,
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.cyanAccent, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Q${currentQuestionIndex + 1}: ${question['question']}",
            style: TextStyle(
                color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
          ),
          if (showHint) ...[
            const SizedBox(height: 10),
            Text("Hint: ${question['hint']}",
                style: TextStyle(color: Colors.yellowAccent)),
          ],
        ],
      ),
    );
  }

  Widget _buildFeedbackSection(Map<String, dynamic> question) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 10),
        _buildInfoCard(
          title: "EXPLANATION",
          content: question['explanation'],
          color: Colors.cyanAccent,
        ),
        const SizedBox(height: 15),
        // You can remove the button row in this section to avoid duplication
      ],
    );
  }

  Widget _buildInfoCard(
      {required String title, required String content, required Color color}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: color,
              fontSize: 14,
              fontWeight: FontWeight.bold,
              fontFamily: 'RobotoMono',
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 14,
              fontFamily: 'RobotoMono',
            ),
          ),
        ],
      ),
    );
  }
}
