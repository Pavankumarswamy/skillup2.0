// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:razorpay_flutter/razorpay_flutter.dart';
// import 'package:flutter/material.dart';
// import 'package:firebase_database/firebase_database.dart';
// import 'course.dart';

// class SearchCoursesPage extends StatefulWidget {
//   const SearchCoursesPage({super.key});

//   @override
//   _SearchCoursesPageState createState() => _SearchCoursesPageState();
// }

// class _SearchCoursesPageState extends State<SearchCoursesPage> {
//   final DatabaseReference _userRef = FirebaseDatabase.instance.ref("users");
//   final DatabaseReference _database = FirebaseDatabase.instance.ref("courses");
//   List<Map<String, dynamic>> _allCourses = [];
//   List<Map<String, dynamic>> _filteredCourses = [];
//   final TextEditingController _searchController = TextEditingController();
//   late Razorpay _razorpay;
//   bool _hasMembership = false; // Track user's membership status

//   @override
//   void initState() {
//     super.initState();
//     _fetchCourses();
//     _searchController.addListener(_filterCourses);

//     _razorpay = Razorpay();

//     // Listen to payment success and failure
//     _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
//     _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
//     _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);

//     // Check user's membership status
//     _checkMembershipStatus();
//   }

//   @override
//   void dispose() {
//     super.dispose();

//     _searchController.dispose();
//     _razorpay.clear();
//   }

//   void _checkMembershipStatus() async {
//     final user = FirebaseAuth.instance.currentUser;
//     if (user != null) {
//       DatabaseReference userRef =
//           FirebaseDatabase.instance.ref("users/${user.uid}");
//       userRef.once().then((snapshot) {
//         if (snapshot.snapshot.exists && snapshot.snapshot.value != null) {
//           var userData =
//               Map<String, dynamic>.from(snapshot.snapshot.value as Map);
//           setState(() {
//             _hasMembership =
//                 userData['membershipPlan'] == "true"; // Check membership plan
//           });
//         }
//       });
//     }
//   }

//   void _handlePaymentSuccess(
//       PaymentSuccessResponse response, String courseId) async {
//     print("Payment Successful: ${response.paymentId}");

//     final userId = FirebaseAuth.instance.currentUser?.uid;
//     if (userId == null) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text("Error: User not logged in")),
//       );
//       return;
//     }

//     try {
//       // Add the course to the user's purchasedCourses collection
//       await _userRef
//           .child(userId)
//           .child("purchasedCourses")
//           .child(courseId)
//           .set(true);

//       // Update the UI to reflect the purchase
//       setState(() {
//         // Find the course in the filtered list and mark it as purchased
//         final courseIndex = _filteredCourses.indexWhere(
//           (course) => course["courseId"] == courseId,
//         );
//         if (courseIndex != -1) {
//           _filteredCourses[courseIndex]["isPurchased"] = true;
//         }
//       });

//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//             content: Text("Payment Successful! Course added to your account.")),
//       );
//     } catch (error) {
//       print("Failed to update purchased courses: $error");
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text("Failed to update purchased courses: $error")),
//       );
//     }
//   }

//   void _handlePaymentError(PaymentFailureResponse response) {
//     print("Payment Failed: ${response.message}");
//     // Show failure message
//   }

//   void _handleExternalWallet(ExternalWalletResponse response) {
//     print("External Wallet: ${response.walletName}");
//     // Handle external wallet payment
//   }

//   void _fetchCourses() {
//     _database.onValue.listen((event) {
//       if (event.snapshot.value != null) {
//         Map<dynamic, dynamic> values =
//             event.snapshot.value as Map<dynamic, dynamic>;
//         List<Map<String, dynamic>> tempCourses = [];

//         values.forEach((key, value) {
//           if (value["status"] == "verified") {
//             // Check if status is verified
//             tempCourses.add({
//               "courseId": key,
//               "title": value["title"] ?? "No Title",
//               "category": value["category"] ?? "No Category",
//               "price": value["price"] ?? "0",
//               "language": value["language"] ?? "Unknown",
//               "imageUrl":
//                   value["imageUrl"] ?? "https://via.placeholder.com/400",
//             });
//           }
//         });

//         setState(() {
//           _allCourses = tempCourses;
//           _filteredCourses = tempCourses;
//         });
//       }
//     });
//   }

//   void _filterCourses() {
//     String query = _searchController.text.toLowerCase();
//     setState(() {
//       _filteredCourses = _allCourses.where((course) {
//         return course["title"].toLowerCase().contains(query) ||
//             course["category"].toLowerCase().contains(query) ||
//             course["language"].toLowerCase().contains(query);
//       }).toList();
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       extendBodyBehindAppBar: true,
//       appBar: AppBar(
//         title: Text("Search Courses"),
//         centerTitle: true,
//         backgroundColor: Colors.transparent,
//         elevation: 0,
//       ),
//       body: Container(
//         decoration: BoxDecoration(
//           gradient: LinearGradient(
//             colors: [Colors.white, Colors.blue.shade200], // White to Sky Blue
//             begin: Alignment.topCenter,
//             end: Alignment.bottomCenter,
//           ),
//         ),
//         child: Column(
//           children: [
//             SizedBox(height: kToolbarHeight + 20), // Adjust for AppBar spacing
//             Padding(
//               padding: EdgeInsets.symmetric(horizontal: 16),
//               child: TextField(
//                 controller: _searchController,
//                 decoration: InputDecoration(
//                   hintText: "Search by title, category, or language",
//                   prefixIcon: Icon(Icons.search),
//                   border: OutlineInputBorder(
//                     borderRadius: BorderRadius.circular(12),
//                   ),
//                   filled: true,
//                   fillColor: Colors.white.withOpacity(0.8),
//                 ),
//               ),
//             ),
//             SizedBox(height: 10),
//             Expanded(
//               child: _filteredCourses.isEmpty
//                   ? Center(child: Text("No courses found"))
//                   : ListView.builder(
//                       padding: EdgeInsets.all(16),
//                       itemCount: _filteredCourses.length,
//                       itemBuilder: (context, index) {
//                         final course = _filteredCourses[index];
//                         return Card(
//                           elevation: 6,
//                           shape: RoundedRectangleBorder(
//                             borderRadius: BorderRadius.circular(16),
//                           ),
//                           child: Container(
//                             decoration: BoxDecoration(
//                               gradient: LinearGradient(
//                                 colors: [
//                                   const Color.fromARGB(255, 255, 255, 255),
//                                   const Color.fromARGB(167, 241, 241, 241)
//                                 ],
//                                 begin: Alignment.topLeft,
//                                 end: Alignment.bottomRight,
//                               ),
//                               borderRadius: BorderRadius.circular(16),
//                             ),
//                             padding: const EdgeInsets.all(12),
//                             child: Column(
//                               crossAxisAlignment: CrossAxisAlignment.start,
//                               children: [
//                                 Row(
//                                   children: [
//                                     ClipRRect(
//                                       borderRadius: BorderRadius.circular(8),
//                                       child: Image.network(
//                                         course["imageUrl"],
//                                         width: 70,
//                                         height: 70,
//                                         fit: BoxFit.cover,
//                                       ),
//                                     ),
//                                     SizedBox(width: 12),
//                                     Expanded(
//                                       child: Column(
//                                         crossAxisAlignment:
//                                             CrossAxisAlignment.start,
//                                         children: [
//                                           Text(
//                                             course["title"],
//                                             style: TextStyle(
//                                               fontSize: 16,
//                                               fontWeight: FontWeight.bold,
//                                             ),
//                                           ),
//                                           SizedBox(height: 4),
//                                           Text(
//                                             "Category: ${course["category"]} | Language: ${course["language"]}",
//                                             style: TextStyle(
//                                               fontSize: 12,
//                                               color: Colors.grey[600],
//                                             ),
//                                           ),
//                                         ],
//                                       ),
//                                     ),
//                                     Text(
//                                       "₹${course["price"]}",
//                                       style: TextStyle(
//                                         fontSize: 16,
//                                         fontWeight: FontWeight.bold,
//                                         color: Colors.green[700],
//                                       ),
//                                     ),
//                                   ],
//                                 ),
//                                 SizedBox(height: 12),
//                                 Row(
//                                   mainAxisAlignment:
//                                       MainAxisAlignment.spaceBetween,
//                                   children: [
//                                     FutureBuilder<DataSnapshot>(
//                                       future: _userRef
//                                           .child(FirebaseAuth
//                                               .instance.currentUser!.uid)
//                                           .child("purchasedCourses")
//                                           .child(course["courseId"])
//                                           .get(),
//                                       builder: (context, snapshot) {
//                                         if (snapshot.connectionState ==
//                                             ConnectionState.waiting) {
//                                           return const CircularProgressIndicator();
//                                         }

//                                         bool isPurchased = snapshot.hasData &&
//                                             snapshot.data!.value == true;

//                                         // Show 'View Course' button if the user has a membership or has purchased the course
//                                         if (_hasMembership || isPurchased) {
//                                           return TextButton(
//                                             onPressed: () {
//                                               Navigator.push(
//                                                 context,
//                                                 MaterialPageRoute(
//                                                   builder: (context) =>
//                                                       CourseContentPage(
//                                                     courseId:
//                                                         course["courseId"],
//                                                   ),
//                                                 ),
//                                               );
//                                             },
//                                             child: const Text("View Course"),
//                                           );
//                                         }

//                                         // Show 'Buy Now' button only if the user has NOT purchased the course
//                                         return ElevatedButton(
//                                           style: ElevatedButton.styleFrom(
//                                             backgroundColor: Colors.blue,
//                                             shape: RoundedRectangleBorder(
//                                               borderRadius:
//                                                   BorderRadius.circular(8),
//                                             ),
//                                           ),
//                                           onPressed: () {
//                                             var courseId = course[
//                                                 "courseId"]; // Get the courseId
//                                             var options = {
//                                               'key':
//                                                   'rzp_live_C4QRSwJt17HkUA', // Razorpay API key
//                                               'amount': (int.parse(
//                                                           course["price"]) *
//                                                       100)
//                                                   .toString(), // Convert price to paise
//                                               'name': course["title"],
//                                               'description': 'Course Payment',
//                                               'prefill': {
//                                                 'contact':
//                                                     "", // Optional: prefill user contact
//                                                 'email': FirebaseAuth.instance
//                                                         .currentUser?.email ??
//                                                     '',
//                                               },
//                                               'external': {
//                                                 'wallets': [
//                                                   'paytm',
//                                                   'phonepe'
//                                                 ] // Optional: enable wallets
//                                               }
//                                             };

//                                             try {
//                                               _razorpay.open(options);

//                                               // Handle successful payment
//                                               _razorpay.on(
//                                                   Razorpay
//                                                       .EVENT_PAYMENT_SUCCESS,
//                                                   (PaymentSuccessResponse
//                                                       response) {
//                                                 _handlePaymentSuccess(
//                                                     response, courseId);
//                                               });
//                                             } catch (e) {
//                                               print("Error: $e");
//                                             }
//                                           },
//                                           child: const Text("Buy Now"),
//                                         );
//                                       },
//                                     ),
//                                     TextButton(
//                                       onPressed: () {
//                                         Navigator.push(
//                                           context,
//                                           MaterialPageRoute(
//                                             builder: (context) =>
//                                                 CourseContentPage(
//                                               courseId: course["courseId"],
//                                             ),
//                                           ),
//                                         );
//                                       },
//                                       child: const Text("Course Contents"),
//                                     )
//                                   ],
//                                 ),
//                               ],
//                             ),
//                           ),
//                         );
//                       },
//                     ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
import 'package:firebase_auth/firebase_auth.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'course.dart';

class SearchCoursesPage extends StatefulWidget {
  const SearchCoursesPage({super.key});

  @override
  _SearchCoursesPageState createState() => _SearchCoursesPageState();
}

class _SearchCoursesPageState extends State<SearchCoursesPage> {
  final DatabaseReference _userRef = FirebaseDatabase.instance.ref("users");
  final DatabaseReference _database = FirebaseDatabase.instance.ref("courses");
  List<Map<String, dynamic>> _allCourses = [];
  List<Map<String, dynamic>> _filteredCourses = [];
  final TextEditingController _searchController = TextEditingController();
  late Razorpay _razorpay;
  bool _hasMembership = false; // Track user's membership status

  @override
  void initState() {
    super.initState();
    _fetchCourses();
    _searchController.addListener(_filterCourses);

    _razorpay = Razorpay();
    // We register error and external wallet events globally.
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);

    _checkMembershipStatus();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _razorpay.clear();
    super.dispose();
  }

  void _checkMembershipStatus() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      DatabaseReference userRef =
          FirebaseDatabase.instance.ref("users/${user.uid}");
      userRef.once().then((snapshot) {
        if (snapshot.snapshot.exists && snapshot.snapshot.value != null) {
          var userData =
              Map<String, dynamic>.from(snapshot.snapshot.value as Map);
          setState(() {
            // Adjust condition as needed; here we assume membershipPlan not equal to "none" means active membership.
            _hasMembership = userData['membershipPlan'] != "none";
          });
        }
      });
    }
  }

  // Updated to accept the courseId from the Buy Now button.
  void _handlePaymentSuccess(
      PaymentSuccessResponse response, String courseId) async {
    print("Payment Successful: ${response.paymentId}");

    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error: User not logged in")),
      );
      return;
    }

    try {
      // Append the course to the user's purchasedCourses list by setting its value to true.
      await _userRef
          .child(userId)
          .child("purchasedCourses")
          .child(courseId)
          .set(true);

      // Update UI to mark course as purchased.
      setState(() {
        final courseIndex = _filteredCourses
            .indexWhere((course) => course["courseId"] == courseId);
        if (courseIndex != -1) {
          _filteredCourses[courseIndex]["isPurchased"] = true;
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("Payment Successful! Course added to your account.")),
      );
    } catch (error) {
      print("Failed to update purchased courses: $error");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to update purchased courses: $error")),
      );
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    print("Payment Failed: ${response.message}");
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Payment Failed: ${response.message}")),
    );
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    print("External Wallet: ${response.walletName}");
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("External Wallet: ${response.walletName}")),
    );
  }

  void _fetchCourses() {
    _database.onValue.listen((event) {
      if (event.snapshot.value != null) {
        Map<dynamic, dynamic> values =
            event.snapshot.value as Map<dynamic, dynamic>;
        List<Map<String, dynamic>> tempCourses = [];

        values.forEach((key, value) {
          if (value["status"] == "verified") {
            // Only add verified courses.
            tempCourses.add({
              "courseId": key,
              "title": value["title"] ?? "No Title",
              "category": value["category"] ?? "No Category",
              "price": value["price"] ?? "0",
              "language": value["language"] ?? "Unknown",
              "imageUrl":
                  value["imageUrl"] ?? "https://via.placeholder.com/400",
            });
          }
        });

        setState(() {
          _allCourses = tempCourses;
          _filteredCourses = tempCourses;
        });
      }
    });
  }

  void _filterCourses() {
    String query = _searchController.text.toLowerCase();
    setState(() {
      _filteredCourses = _allCourses.where((course) {
        return course["title"].toLowerCase().contains(query) ||
            course["category"].toLowerCase().contains(query) ||
            course["language"].toLowerCase().contains(query);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text("Search Courses"),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.white, Colors.blue.shade200], // White to Sky Blue
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          children: [
            SizedBox(height: kToolbarHeight + 20), // For AppBar spacing
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: "Search by title, category, or language",
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.8),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: _filteredCourses.isEmpty
                  ? const Center(child: Text("No courses found"))
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _filteredCourses.length,
                      itemBuilder: (context, index) {
                        final course = _filteredCourses[index];
                        return Card(
                          elevation: 6,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [
                                  Color.fromARGB(255, 255, 255, 255),
                                  Color.fromARGB(167, 241, 241, 241)
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.network(
                                        course["imageUrl"],
                                        width: 70,
                                        height: 70,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            course["title"],
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            "Category: ${course["category"]} | Language: ${course["language"]}",
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Text(
                                      "₹${course["price"]}",
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.green[700],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    FutureBuilder<DataSnapshot>(
                                      future: _userRef
                                          .child(FirebaseAuth
                                              .instance.currentUser!.uid)
                                          .child("purchasedCourses")
                                          .child(course["courseId"])
                                          .get(),
                                      builder: (context, snapshot) {
                                        if (snapshot.connectionState ==
                                            ConnectionState.waiting) {
                                          return const CircularProgressIndicator();
                                        }

                                        bool isPurchased = snapshot.hasData &&
                                            snapshot.data!.value == true;

                                        // If the user has membership or already purchased the course, show "View Course".
                                        if (_hasMembership || isPurchased) {
                                          return TextButton(
                                            onPressed: () {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (context) =>
                                                      CourseContentPage(
                                                    courseId:
                                                        course["courseId"],
                                                  ),
                                                ),
                                              );
                                            },
                                            child: const Text("View Course"),
                                          );
                                        }

                                        // Otherwise, show "Buy Now" button.
                                        return ElevatedButton(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.blue,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                          ),
                                          onPressed: () {
                                            final courseId = course[
                                                "courseId"]; // Capture the courseId locally.
                                            var options = {
                                              'key':
                                                  'rzp_live_HJl9NwyBSY9rwV', // Razorpay API key
                                              'amount': (int.parse(
                                                          course["price"]) *
                                                      100)
                                                  .toString(), // Price in paise
                                              'name': course["title"],
                                              'description': 'Course Payment',
                                              'prefill': {
                                                'contact':
                                                    "", // Optionally prefill user contact
                                                'email': FirebaseAuth.instance
                                                        .currentUser?.email ??
                                                    '',
                                              },
                                              'external': {
                                                'wallets': ['paytm', 'phonepe']
                                              }
                                            };

                                            try {
                                              _razorpay.open(options);
                                              // Register success event here to capture the specific courseId.
                                              _razorpay.on(
                                                  Razorpay
                                                      .EVENT_PAYMENT_SUCCESS,
                                                  (PaymentSuccessResponse
                                                      response) {
                                                _handlePaymentSuccess(
                                                    response, courseId);
                                              });
                                            } catch (e) {
                                              print("Error: $e");
                                            }
                                          },
                                          child: const Text("Buy Now"),
                                        );
                                      },
                                    ),
                                    TextButton(
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                CourseContentPage(
                                              courseId: course["courseId"],
                                            ),
                                          ),
                                        );
                                      },
                                      child: const Text("Course Contents"),
                                    )
                                  ],
                                ),
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
