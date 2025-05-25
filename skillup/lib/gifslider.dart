// import 'package:cetmock/auth/login.dart';
// import 'package:flutter/material.dart';

// void main() {
//   runApp(MaterialApp(
//     home: GifViewerPage(),
//     routes: {
//       '/login': (context) => LoginPage(),
//     },
//   ));
// }

// class GifViewerPage extends StatefulWidget {
//   const GifViewerPage({super.key});

//   @override
//   _GifViewerPageState createState() => _GifViewerPageState();
// }

// class _GifViewerPageState extends State<GifViewerPage>
//     with SingleTickerProviderStateMixin {
//   int currentIndex = 0;
//   late AnimationController _buttonController;
//   late Animation<double> _buttonScale;

//   final List<Map<String, String>> gifData = [
//     {
//       'gif': 'assets/1.gif',
//       'description': 'Learn a skill from your friends who know it well.',
//       'buttonText': 'Learn Now'
//     },
//     {
//       'gif': 'assets/2.gif',
//       'description': 'Showcase your skills and shine!',
//       'buttonText': 'Showcase'
//     },
//     {
//       'gif': 'assets/3.gif',
//       'description': 'Discuss and increase your talent.',
//       'buttonText': 'Discuss'
//     },
//   ];

//   @override
//   void initState() {
//     super.initState();
//     _buttonController =
//         AnimationController(vsync: this, duration: Duration(milliseconds: 200))
//           ..addListener(() {
//             setState(() {});
//           });
//     _buttonScale = Tween<double>(begin: 1.0, end: 0.95).animate(
//         CurvedAnimation(parent: _buttonController, curve: Curves.easeInOut));
//   }

//   @override
//   void dispose() {
//     _buttonController.dispose();
//     super.dispose();
//   }

//   void _nextGif() {
//     setState(() {
//       if (currentIndex < gifData.length - 1) {
//         currentIndex++;
//       } else {
//         Navigator.pushReplacementNamed(context, '/login');
//       }
//     });
//     _buttonController.forward().then((_) {
//       _buttonController.reverse();
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     final currentData = gifData[currentIndex];

//     return Scaffold(
//       body: Container(
//         decoration: BoxDecoration(
//           gradient: LinearGradient(
//             colors: [Colors.white, Colors.blueAccent],
//             begin: Alignment.topCenter,
//             end: Alignment.bottomCenter,
//           ),
//         ),
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: <Widget>[
//             Image.asset(
//               currentData['gif']!,
//               width: 500,
//               height: 500,
//               fit: BoxFit.contain,
//             ),
//             SizedBox(height: 30),
//             Padding(
//               padding: const EdgeInsets.symmetric(horizontal: 16.0),
//               child: Text(
//                 currentData['description']!,
//                 textAlign: TextAlign.center,
//                 style: TextStyle(
//                   fontSize: 18,
//                   fontWeight: FontWeight.bold,
//                   color: Colors.black,
//                 ),
//               ),
//             ),
//             SizedBox(height: 40),
//             Padding(
//               padding: const EdgeInsets.symmetric(horizontal: 16.0),
//               child: GestureDetector(
//                 onTapDown: (_) => _buttonController.forward(),
//                 onTapUp: (_) => _nextGif(),
//                 child: Transform.scale(
//                   scale: _buttonScale.value,
//                   child: Container(
//                     width: double.infinity,
//                     padding: EdgeInsets.symmetric(vertical: 16),
//                     decoration: BoxDecoration(
//                       color: const Color.fromARGB(255, 68, 0, 255),
//                       borderRadius: BorderRadius.circular(30),
//                     ),
//                     alignment: Alignment.center,
//                     child: Text(
//                       currentData['buttonText']!,
//                       style: TextStyle(
//                         fontSize: 18,
//                         fontWeight: FontWeight.w600,
//                         color: Colors.white,
//                       ),
//                     ),
//                   ),
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
