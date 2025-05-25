// import 'dart:async';
// import 'dart:convert';
// import 'dart:io';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/material.dart';
// import 'package:firebase_database/firebase_database.dart';
// import 'package:razorpay_flutter/razorpay_flutter.dart';
// import 'package:cached_network_image/cached_network_image.dart';
// import 'package:image_picker/image_picker.dart';
// import 'package:http/http.dart' as http;
// import 'package:http_parser/http_parser.dart';
// import 'package:mime/mime.dart';
// import 'package:share_plus/share_plus.dart';
// import 'package:skillup/General%20User%20Pages/fab.dart';
// import 'package:skillup/General%20User%20Pages/hero.dart';
// import 'package:url_launcher/url_launcher.dart';
// import 'package:path_provider/path_provider.dart';
// import 'package:photo_view/photo_view.dart';
// import 'package:photo_view/photo_view_gallery.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:shimmer/shimmer.dart';
// import '/General%20User%20Pages/course.dart';

// class UserDashboardWidget extends StatefulWidget {
//   const UserDashboardWidget({super.key});

//   @override
//   _UserDashboardWidgetState createState() => _UserDashboardWidgetState();
// }

// class _UserDashboardWidgetState extends State<UserDashboardWidget>
//     with SingleTickerProviderStateMixin {
//   final DatabaseReference _database = FirebaseDatabase.instance.ref("courses");
//   final DatabaseReference _userRef = FirebaseDatabase.instance.ref("users");
//   final DatabaseReference _postsRef = FirebaseDatabase.instance.ref("posts");
//   final DatabaseReference _usersPostsRef = FirebaseDatabase.instance.ref(
//     "users_posts",
//   );
//   List<Map<String, dynamic>> _courses = [];
//   List<String> _categories = [];
//   late AnimationController _loadingController;
//   bool _isLoading = true;
//   bool _isUserDataLoading = true;
//   String? _membershipPlan;
//   String? _processingCourseId;
//   final Razorpay _razorpay = Razorpay();
//   bool _isDialogOpen = false;
//   final Map<String, Future<DataSnapshot>> _purchaseFutures = {};
//   final GlobalKey<_PostListWidgetState> _postListKey =
//       GlobalKey<_PostListWidgetState>();
//   int _lastPostId = -1;

//   @override
//   void initState() {
//     super.initState();
//     _loadingController = AnimationController(
//       vsync: this,
//       duration: const Duration(milliseconds: 1500),
//     )..repeat();
//     _fetchCourses();
//     _fetchUserData();

//     _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
//     _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
//     _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
//   }

//   @override
//   void dispose() {
//     _loadingController.dispose();
//     _razorpay.clear();
//     super.dispose();
//   }

//   void _fetchUserData() async {
//     var user = FirebaseAuth.instance.currentUser;
//     if (user == null) {
//       setState(() => _isUserDataLoading = false);
//       return;
//     }

//     try {
//       DataSnapshot snapshot = await _userRef.child(user.uid).get();
//       setState(() {
//         _membershipPlan = snapshot.child('membershipPlan').value.toString();
//         _isUserDataLoading = false;
//       });
//     } catch (e) {
//       setState(() => _isUserDataLoading = false);
//       _showSnackBar("Failed to fetch user data: $e", key: "user_data_error");
//     }
//   }

//   void _fetchCourses() {
//     setState(() => _isLoading = true);
//     _database.onValue.listen(
//       (event) {
//         if (event.snapshot.value != null) {
//           Map<dynamic, dynamic> values =
//               event.snapshot.value as Map<dynamic, dynamic>;
//           List<Map<String, dynamic>> tempCourses = [];
//           Set<String> categorySet = {};

//           values.forEach((key, value) {
//             if (value["status"] == "verified") {
//               tempCourses.add({
//                 "courseId": key,
//                 "title": value["title"] ?? "No Title",
//                 "category": value["category"] ?? "Uncategorized",
//                 "price": double.tryParse(value["price"].toString()) ?? 0.0,
//                 "language": value["language"] ?? "Unknown",
//                 "duration": value["duration"] ?? "0",
//                 "imageUrl":
//                     value["imageUrl"] ?? "https://via.placeholder.com/400",
//               });
//               categorySet.add(value["category"] ?? "Uncategorized");
//             }
//           });

//           setState(() {
//             _courses = tempCourses;
//             _categories = categorySet.toList();
//             _isLoading = false;
//           });
//         } else {
//           setState(() {
//             _courses = [];
//             _categories = [];
//             _isLoading = false;
//           });
//         }
//       },
//       onError: (error) {
//         setState(() => _isLoading = false);
//         _showSnackBar("Failed to fetch courses: $error", key: "courses_error");
//       },
//     );
//   }

//   void _startPayment(double price, String courseId) {
//     var options = {
//       'key': 'rzp_live_HJl9NwyBSY9rwV',
//       'amount': (price * 100).toInt(),
//       'name': 'Course Payment',
//       'description': 'Payment for course $courseId',
//       'prefill': {
//         'contact': '+91 8639122823',
//         'email': FirebaseAuth.instance.currentUser?.email ?? 'live@ggu.edu.in',
//       },
//       'theme': {'color': '#F37254'},
//     };

//     _razorpay.open(options);
//   }

//   void _handlePaymentSuccess(PaymentSuccessResponse response) {
//     final courseId = _processingCourseId;
//     final userId = FirebaseAuth.instance.currentUser?.uid;

//     if (userId == null || courseId == null) {
//       _showSnackBar(
//         "Error: User not logged in or course missing",
//         key: "payment_error",
//       );
//       setState(() => _processingCourseId = null);
//       return;
//     }

//     setState(() => _processingCourseId = null);

//     _userRef
//         .child(userId)
//         .child("purchasedCourses")
//         .child(courseId)
//         .set(true)
//         .then((_) {
//           _showSnackBar(
//             "Payment Successful! Course added to your account.",
//             key: "payment_success",
//           );
//           setState(() {
//             _purchaseFutures[courseId] = Future.value(
//               DataSnapshotMock(value: true, key: courseId),
//             );
//           });
//         })
//         .catchError((error) {
//           _showSnackBar(
//             "Failed to update purchased courses: $error",
//             key: "payment_error",
//           );
//         });
//   }

//   void _handlePaymentError(PaymentFailureResponse response) {
//     setState(() => _processingCourseId = null);
//     _showSnackBar("Payment Failed: ${response.message}", key: "payment_error");
//   }

//   void _handleExternalWallet(ExternalWalletResponse response) {
//     setState(() => _processingCourseId = null);
//     _showSnackBar(
//       "External Wallet Used: ${response.walletName}",
//       key: "payment_wallet",
//     );
//   }

//   String _formatCourseTitle(String title) {
//     const int maxLength = 20;
//     if (title.length > maxLength) {
//       return "${title.substring(0, maxLength - 3)}...";
//     } else {
//       return title.padRight(maxLength);
//     }
//   }

//   Widget _buildEnrollButton(String courseId, double price) {
//     if (_isUserDataLoading) {
//       return const SizedBox(
//         width: double.infinity,
//         height: 32,
//         child: ElevatedButton(
//           onPressed: null,
//           child: CircularProgressIndicator(),
//         ),
//       );
//     }

//     final bool isProcessing = courseId == _processingCourseId;

//     _purchaseFutures[courseId] ??=
//         _userRef
//             .child(FirebaseAuth.instance.currentUser!.uid)
//             .child("purchasedCourses")
//             .child(courseId)
//             .get();

//     return FutureBuilder<DataSnapshot>(
//       future: _purchaseFutures[courseId],
//       builder: (context, snapshot) {
//         if (snapshot.connectionState == ConnectionState.waiting) {
//           return const SizedBox(
//             width: double.infinity,
//             height: 32,
//             child: ElevatedButton(
//               onPressed: null,
//               child: CircularProgressIndicator(),
//             ),
//           );
//         }

//         bool isPurchased = snapshot.hasData && snapshot.data!.value == true;

//         return SizedBox(
//           width: double.infinity,
//           height: 32,
//           child: FilledButton(
//             key: ValueKey("enroll_$courseId"),
//             onPressed:
//                 isProcessing || _isDialogOpen
//                     ? null
//                     : () {
//                       if (_membershipPlan == "true" || isPurchased) {
//                         Navigator.push(
//                           context,
//                           MaterialPageRoute(
//                             builder:
//                                 (context) =>
//                                     CourseContentPage(courseId: courseId),
//                           ),
//                         );
//                       } else {
//                         setState(() => _processingCourseId = courseId);
//                         _startPayment(price, courseId);
//                       }
//                     },
//             style: FilledButton.styleFrom(
//               backgroundColor:
//                   isPurchased || _membershipPlan == "true"
//                       ? const Color.fromARGB(255, 10, 145, 255)
//                       : Colors.blue.shade900,
//               shape: RoundedRectangleBorder(
//                 borderRadius: BorderRadius.circular(8),
//               ),
//               padding: const EdgeInsets.symmetric(vertical: 8),
//             ),
//             child:
//                 isProcessing
//                     ? const CircularProgressIndicator(color: Colors.white)
//                     : Text(
//                       isPurchased || _membershipPlan == "true"
//                           ? "View Course"
//                           : "Enroll Now",
//                       style: const TextStyle(color: Colors.white, fontSize: 12),
//                     ),
//           ),
//         );
//       },
//     );
//   }

//   void _createPost() async {
//     final user = FirebaseAuth.instance.currentUser;
//     if (user == null) {
//       _showSnackBar("Please log in to create a post", key: "auth_error");
//       return;
//     }

//     final userId = user.uid;
//     final username = user.email?.split('@')[0] ?? "anonymous";
//     TextEditingController titleController = TextEditingController();
//     TextEditingController descriptionController = TextEditingController();
//     TextEditingController linkController = TextEditingController();
//     List<File> imageFiles = [];
//     bool isUploading = false;

//     setState(() {
//       _isDialogOpen = true;
//       debugPrint("Opening create post dialog, _isDialogOpen: $_isDialogOpen");
//     });

//     showDialog(
//       context: context,
//       barrierDismissible: false,
//       builder:
//           (dialogContext) => StatefulBuilder(
//             builder: (dialogContext, setState) {
//               return AlertDialog(
//                 title: const Text("Create Post"),
//                 content: SingleChildScrollView(
//                   child: Column(
//                     mainAxisSize: MainAxisSize.min,
//                     children: [
//                       TextField(
//                         controller: titleController,
//                         decoration: const InputDecoration(labelText: "Title"),
//                         maxLength: 100,
//                       ),
//                       TextField(
//                         controller: descriptionController,
//                         decoration: const InputDecoration(
//                           labelText: "Description",
//                         ),
//                         maxLines: 3,
//                         maxLength: 500,
//                       ),
//                       TextField(
//                         controller: linkController,
//                         decoration: const InputDecoration(
//                           labelText: "Link (Optional)",
//                         ),
//                         keyboardType: TextInputType.url,
//                       ),
//                       const SizedBox(height: 10),
//                       ElevatedButton(
//                         onPressed:
//                             isUploading || imageFiles.length >= 3
//                                 ? null
//                                 : () async {
//                                   final picker = ImagePicker();
//                                   final pickedFile = await picker.pickImage(
//                                     source: ImageSource.gallery,
//                                   );
//                                   if (pickedFile != null) {
//                                     final file = File(pickedFile.path);
//                                     final fileSize = await file.length();
//                                     if (fileSize > 10 * 1024 * 1024) {
//                                       _showSnackBar(
//                                         "Image size exceeds 10MB limit",
//                                         key: "image_error",
//                                       );
//                                       return;
//                                     }
//                                     setState(() {
//                                       imageFiles.add(file);
//                                     });
//                                   }
//                                 },
//                         child: Text(
//                           imageFiles.isEmpty
//                               ? "Pick Images"
//                               : "${imageFiles.length}/3 Images Selected",
//                         ),
//                       ),
//                       if (imageFiles.isNotEmpty)
//                         Wrap(
//                           spacing: 8,
//                           children:
//                               imageFiles
//                                   .map(
//                                     (file) => Image.file(
//                                       file,
//                                       width: 60,
//                                       height: 60,
//                                       fit: BoxFit.cover,
//                                     ),
//                                   )
//                                   .toList(),
//                         ),
//                       if (isUploading) const CircularProgressIndicator(),
//                     ],
//                   ),
//                 ),
//                 actions: [
//                   TextButton(
//                     onPressed: () {
//                       Navigator.pop(dialogContext);
//                       setState(() => _isDialogOpen = false);
//                       debugPrint(
//                         "Create post dialog cancelled, _isDialogOpen: $_isDialogOpen",
//                       );
//                     },
//                     child: const Text("Cancel"),
//                   ),
//                   ElevatedButton(
//                     onPressed:
//                         isUploading
//                             ? null
//                             : () async {
//                               final title = titleController.text.trim();
//                               final description =
//                                   descriptionController.text.trim();
//                               final link = linkController.text.trim();

//                               if (title.isEmpty ||
//                                   description.isEmpty ||
//                                   imageFiles.isEmpty) {
//                                 _showSnackBar(
//                                   "Title, description, and at least one image are required",
//                                   key: "post_error",
//                                 );
//                                 return;
//                               }

//                               setState(() => isUploading = true);
//                               debugPrint(
//                                 "Starting post creation for user: $userId",
//                               );

//                               try {
//                                 // Upload images to Cloudinary
//                                 List<String> imageUrls = [];
//                                 for (var imageFile in imageFiles) {
//                                   debugPrint(
//                                     "Uploading image: ${imageFile.path}",
//                                   );
//                                   if (!await imageFile.exists()) {
//                                     throw Exception(
//                                       "Image file does not exist: ${imageFile.path}",
//                                     );
//                                   }
//                                   final imageUrl = await _uploadToCloudinary(
//                                     imageFile,
//                                   );
//                                   if (imageUrl == null) {
//                                     throw Exception(
//                                       "Failed to upload image: ${imageFile.path}",
//                                     );
//                                   }
//                                   imageUrls.add(imageUrl);
//                                   debugPrint("Image uploaded: $imageUrl");
//                                 }

//                                 // Generate post ID
//                                 final postId = await _generatePostId();
//                                 debugPrint("Generated post ID: $postId");

//                                 // Prepare post data
//                                 final postData = {
//                                   "post_id": postId,
//                                   "user_id": userId,
//                                   "username": username,
//                                   "imageUrls": imageUrls,
//                                   "title": title,
//                                   "description": description,
//                                   "link": link,
//                                   "likeCount": 0,
//                                   "likes": {},
//                                   "comments": {},
//                                   "shareCount": 0,
//                                   "timestamp": ServerValue.timestamp,
//                                 };

//                                 // Write to Firebase
//                                 debugPrint("Writing post data to Firebase");
//                                 await _postsRef
//                                     .child(postId)
//                                     .set(jsonEncode(postData))
//                                     .catchError((error) {
//                                       throw Exception(
//                                         "Failed to write post to posts/$postId: $error",
//                                       );
//                                     });

//                                 debugPrint(
//                                   "Writing to users_posts/$userId/$postId",
//                                 );
//                                 await _usersPostsRef
//                                     .child(userId)
//                                     .child(postId)
//                                     .set(true)
//                                     .catchError((error) {
//                                       _postsRef.child(postId).remove();
//                                       throw Exception(
//                                         "Failed to write to users_posts/$userId/$postId: $error",
//                                       );
//                                     });

//                                 // Update local state via PostListWidget
//                                 final postListState = _postListKey.currentState;
//                                 if (postListState != null) {
//                                   postListState.setState(() {
//                                     postListState._posts.insert(0, {
//                                       "postNo": postId,
//                                       ...postData,
//                                     });
//                                     postListState._postCache[postId] = postData;
//                                   });
//                                 }

//                                 // Update shared preferences
//                                 final prefs =
//                                     await SharedPreferences.getInstance();
//                                 final cachedPostsJson =
//                                     prefs.getString("cached_posts") ?? "[]";
//                                 final cachedPosts =
//                                     (jsonDecode(cachedPostsJson)
//                                             as List<dynamic>)
//                                         .cast<Map<String, dynamic>>();
//                                 cachedPosts.insert(0, {
//                                   "postNo": postId,
//                                   ...postData,
//                                   "timestamp":
//                                       DateTime.now().millisecondsSinceEpoch,
//                                 });
//                                 if (cachedPosts.length > 100) {
//                                   cachedPosts.removeRange(
//                                     0,
//                                     cachedPosts.length - 100,
//                                   );
//                                 }
//                                 final updatedPostIds =
//                                     cachedPosts
//                                         .map((p) => p["postNo"] as String)
//                                         .toList();
//                                 await prefs.setString(
//                                   "cached_posts",
//                                   jsonEncode(cachedPosts),
//                                 );
//                                 await prefs.setStringList(
//                                   "cached_post_ids",
//                                   updatedPostIds,
//                                 );

//                                 debugPrint("Post created successfully");
//                                 Navigator.pop(dialogContext);
//                                 _showSnackBar(
//                                   "Post created successfully",
//                                   key: "post_success",
//                                 );
//                               } catch (e) {
//                                 debugPrint("Post creation failed: $e");
//                                 String errorMessage;
//                                 if (e.toString().contains(
//                                   "Image file does not exist",
//                                 )) {
//                                   errorMessage =
//                                       "Selected image is invalid. Please try another.";
//                                 } else if (e.toString().contains(
//                                   "exceeds 10MB limit",
//                                 )) {
//                                   errorMessage =
//                                       "Image size exceeds 10MB. Please reduce size.";
//                                 } else if (e.toString().contains(
//                                   "Failed to upload image",
//                                 )) {
//                                   errorMessage =
//                                       "Failed to upload image. Check your connection.";
//                                 } else if (e.toString().contains(
//                                   "Failed to write",
//                                 )) {
//                                   errorMessage =
//                                       "Failed to save post. Try again later.";
//                                 } else {
//                                   errorMessage = "Failed to create post: $e";
//                                 }
//                                 _showSnackBar(errorMessage, key: "post_error");
//                               } finally {
//                                 setState(() => isUploading = false);
//                               }
//                             },
//                     child: const Text("Post"),
//                   ),
//                 ],
//               );
//             },
//           ),
//     ).then((_) {
//       setState(() {
//         _isDialogOpen = false;
//         debugPrint("Create post dialog closed, _isDialogOpen: $_isDialogOpen");
//       });
//     });
//   }

//   Future<String?> _uploadToCloudinary(File imageFile) async {
//     const cloudName = "dnedosgc6";
//     const uploadPreset = "ml_default";
//     const maxRetries = 2;
//     int attempt = 0;

//     while (attempt <= maxRetries) {
//       attempt++;
//       debugPrint("Cloudinary upload attempt $attempt for ${imageFile.path}");

//       try {
//         final url = Uri.parse(
//           "https://api.cloudinary.com/v1_1/$cloudName/image/upload",
//         );
//         final mimeTypeData = lookupMimeType(imageFile.path)?.split('/');
//         final request =
//             http.MultipartRequest('POST', url)
//               ..fields['upload_preset'] = uploadPreset
//               ..files.add(
//                 await http.MultipartFile.fromPath(
//                   'file',
//                   imageFile.path,
//                   contentType:
//                       mimeTypeData != null
//                           ? MediaType(mimeTypeData[0], mimeTypeData[1])
//                           : MediaType('image', 'jpeg'),
//                 ),
//               );

//         final response = await request.send().timeout(
//           const Duration(seconds: 30),
//         );
//         final responseData = await http.Response.fromStream(response);

//         if (response.statusCode == 200) {
//           final jsonResponse =
//               jsonDecode(responseData.body) as Map<String, dynamic>;
//           final imageUrl = jsonResponse['secure_url'] as String?;
//           if (imageUrl == null) {
//             throw Exception("Cloudinary response missing secure_url");
//           }
//           return imageUrl;
//         } else {
//           debugPrint("Cloudinary error: ${responseData.body}");
//           if (attempt >= maxRetries) {
//             throw Exception("Cloudinary upload failed: ${responseData.body}");
//           }
//         }
//       } catch (e) {
//         debugPrint("Cloudinary upload error: $e");
//         if (attempt >= maxRetries) {
//           throw Exception("Upload error after $maxRetries attempts: $e");
//         }
//         await Future.delayed(const Duration(seconds: 2));
//       }
//     }
//     return null;
//   }

//   Future<String> _generatePostId() async {
//     const maxAttempts = 1000;
//     int attempt = 0;
//     int nextId = (_lastPostId + 1) % 100000;

//     debugPrint("Generating post ID starting from $nextId");

//     while (attempt < maxAttempts) {
//       final snapshot = await _postsRef.child(nextId.toString()).get();
//       if (!snapshot.exists) {
//         _lastPostId = nextId;
//         debugPrint("Post ID $nextId is available");
//         return nextId.toString();
//       }
//       nextId = (nextId + 1) % 100000;
//       attempt++;
//     }
//     throw Exception("No available post IDs after $maxAttempts attempts");
//   }

//   void _showSnackBar(String message, {required String key}) {
//     ScaffoldMessenger.of(context).hideCurrentSnackBar();
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         key: ValueKey(key),
//         content: Text(message),
//         duration: const Duration(seconds: 3),
//         action: SnackBarAction(
//           label: 'Dismiss',
//           onPressed: () => ScaffoldMessenger.of(context).hideCurrentSnackBar(),
//         ),
//       ),
//     );
//   }

//   Widget _buildCourseSkeleton() {
//     return Shimmer.fromColors(
//       baseColor: Colors.grey[300]!,
//       highlightColor: Colors.grey[100]!,
//       child: SizedBox(
//         width: 180,
//         child: Card(
//           elevation: 4,
//           shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.circular(12),
//           ),
//           margin: const EdgeInsets.all(8),
//           child: Padding(
//             padding: const EdgeInsets.all(8),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Container(
//                   height: 90,
//                   width: double.infinity,
//                   decoration: BoxDecoration(
//                     color: Colors.white,
//                     borderRadius: BorderRadius.circular(8),
//                   ),
//                 ),
//                 const SizedBox(height: 6),
//                 Container(height: 14, width: 100, color: Colors.white),
//                 const SizedBox(height: 4),
//                 Container(height: 10, width: 80, color: Colors.white),
//                 const SizedBox(height: 4),
//                 Container(height: 10, width: 50, color: Colors.white),
//                 const SizedBox(height: 6),
//                 Container(
//                   height: 32,
//                   width: double.infinity,
//                   decoration: BoxDecoration(
//                     color: Colors.white,
//                     borderRadius: BorderRadius.circular(8),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildHeroSliderSkeleton() {
//     return Shimmer.fromColors(
//       baseColor: Colors.grey[300]!,
//       highlightColor: Colors.grey[100]!,
//       child: SizedBox(
//         height: 180,
//         child: Stack(
//           alignment: Alignment.bottomCenter,
//           children: [
//             Container(
//               margin: const EdgeInsets.symmetric(horizontal: 16),
//               color: Colors.white,
//               width: double.infinity,
//               height: 180,
//             ),
//             Positioned(
//               bottom: 10,
//               child: Row(
//                 children: List.generate(
//                   5,
//                   (index) => Container(
//                     width: 8,
//                     height: 8,
//                     margin: const EdgeInsets.symmetric(horizontal: 4),
//                     decoration: const BoxDecoration(
//                       shape: BoxShape.circle,
//                       color: Colors.white,
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

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       floatingActionButton: FloatingActionButton(
//         onPressed: () {
//           debugPrint("FAB pressed, _isDialogOpen: $_isDialogOpen");
//           if (!_isDialogOpen) {
//             _createPost();
//           } else {
//             _showSnackBar(
//               "Please close the open dialog first",
//               key: "dialog_error",
//             );
//           }
//         },
//         backgroundColor: _isDialogOpen ? Colors.grey : Colors.blue.shade900,
//         child: const Icon(Icons.add, color: Colors.white),
//       ),
//       floatingActionButtonLocation: CustomFabLocation(),
//       body: Container(
//         decoration: BoxDecoration(
//           gradient: LinearGradient(
//             colors: [Colors.white, Colors.blue.shade100],
//             begin: Alignment.topCenter,
//             end: Alignment.bottomCenter,
//           ),
//         ),
//         child: CustomScrollView(
//           slivers: [
//             SliverPadding(
//               padding: const EdgeInsets.only(top: 19),
//               sliver: SliverList(
//                 delegate: SliverChildListDelegate([
//                   _isLoading ? _buildHeroSliderSkeleton() : const HeroSlider(),
//                   if (_categories.isNotEmpty)
//                     Padding(
//                       padding: const EdgeInsets.only(left: 15.0, top: 15),
//                       child: Wrap(
//                         spacing: 12,
//                         runSpacing: 12,
//                         children:
//                             _categories
//                                 .map(
//                                   (category) => StatefulBuilder(
//                                     builder: (context, setState) {
//                                       bool isTapped = false;
//                                       return GestureDetector(
//                                         onTapDown:
//                                             (_) =>
//                                                 setState(() => isTapped = true),
//                                         onTapUp:
//                                             (_) => setState(
//                                               () => isTapped = false,
//                                             ),
//                                         onTapCancel:
//                                             () => setState(
//                                               () => isTapped = false,
//                                             ),
//                                         onTap:
//                                             () => _showCategoryCourses(
//                                               context,
//                                               category,
//                                             ),
//                                         child: AnimatedScale(
//                                           scale: isTapped ? 0.90 : 1.0,
//                                           duration: const Duration(
//                                             milliseconds: 100,
//                                           ),
//                                           child: Container(
//                                             decoration: BoxDecoration(
//                                               boxShadow:
//                                                   isTapped
//                                                       ? [
//                                                         BoxShadow(
//                                                           color:
//                                                               Colors
//                                                                   .deepPurple
//                                                                   .shade200,
//                                                           blurRadius: 8,
//                                                           offset: const Offset(
//                                                             0,
//                                                             4,
//                                                           ),
//                                                         ),
//                                                       ]
//                                                       : [],
//                                               borderRadius:
//                                                   BorderRadius.circular(12),
//                                             ),
//                                             width:
//                                                 (_categories.length % 2 == 1 &&
//                                                         _categories.indexOf(
//                                                               category,
//                                                             ) ==
//                                                             _categories.length -
//                                                                 1)
//                                                     ? double.infinity
//                                                     : (MediaQuery.of(
//                                                               context,
//                                                             ).size.width -
//                                                             48) /
//                                                         2,
//                                             child: ActionChip(
//                                               avatar: Icon(
//                                                 Icons.book,
//                                                 size: 18,
//                                                 color: const Color.fromARGB(
//                                                   255,
//                                                   15,
//                                                   0,
//                                                   232,
//                                                 ),
//                                               ),
//                                               label: Text(
//                                                 category,
//                                                 style: const TextStyle(
//                                                   color: Color.fromARGB(
//                                                     255,
//                                                     0,
//                                                     0,
//                                                     0,
//                                                   ),
//                                                   fontSize: 16,
//                                                   fontFamily: 'Georgia',
//                                                 ),
//                                               ),
//                                               backgroundColor:
//                                                   isTapped
//                                                       ? Colors
//                                                           .deepPurple
//                                                           .shade100
//                                                       : Colors
//                                                           .deepPurple
//                                                           .shade50,
//                                               elevation: isTapped ? 8 : 2,
//                                               pressElevation: 12,
//                                               shape: RoundedRectangleBorder(
//                                                 borderRadius:
//                                                     BorderRadius.circular(12),
//                                               ),
//                                               onPressed:
//                                                   () => _showCategoryCourses(
//                                                     context,
//                                                     category,
//                                                   ),
//                                             ),
//                                           ),
//                                         ),
//                                       );
//                                     },
//                                   ),
//                                 )
//                                 .toList(),
//                       ),
//                     ),
//                 ]),
//               ),
//             ),
//             if (_isLoading)
//               SliverToBoxAdapter(
//                 child: SizedBox(
//                   height: 240,
//                   child: ListView.builder(
//                     scrollDirection: Axis.horizontal,
//                     itemCount: 3,
//                     itemBuilder: (context, index) => _buildCourseSkeleton(),
//                   ),
//                 ),
//               )
//             else if (_courses.isEmpty)
//               SliverToBoxAdapter(
//                 child: Center(
//                   child: Text(
//                     "No courses available",
//                     style: TextStyle(color: Colors.blue.shade900),
//                   ),
//                 ),
//               )
//             else
//               SliverToBoxAdapter(
//                 child: SizedBox(
//                   height: 240,
//                   child: ListView.builder(
//                     scrollDirection: Axis.horizontal,
//                     itemCount: _courses.length,
//                     itemBuilder: (context, index) {
//                       final course = _courses[index];
//                       bool isTapped = false;
//                       return StatefulBuilder(
//                         builder: (context, setState) {
//                           return GestureDetector(
//                             onTapDown: (_) => setState(() => isTapped = true),
//                             onTapUp: (_) => setState(() => isTapped = false),
//                             onTapCancel: () => setState(() => isTapped = false),
//                             onTap: () {
//                               Navigator.push(
//                                 context,
//                                 MaterialPageRoute(
//                                   builder:
//                                       (context) => CourseContentPage(
//                                         courseId: course["courseId"],
//                                       ),
//                                 ),
//                               );
//                             },
//                             child: AnimatedScale(
//                               scale: isTapped ? 0.95 : 1.0,
//                               duration: const Duration(milliseconds: 100),
//                               child: SizedBox(
//                                 width: 180,
//                                 child: Card(
//                                   key: ValueKey(course["courseId"]),
//                                   elevation: 4,
//                                   shape: RoundedRectangleBorder(
//                                     borderRadius: BorderRadius.circular(12),
//                                   ),
//                                   margin: const EdgeInsets.all(8),
//                                   child: Padding(
//                                     padding: const EdgeInsets.all(8),
//                                     child: Column(
//                                       crossAxisAlignment:
//                                           CrossAxisAlignment.start,
//                                       children: [
//                                         ClipRRect(
//                                           borderRadius: BorderRadius.circular(
//                                             8,
//                                           ),
//                                           child: CachedNetworkImage(
//                                             imageUrl: course["imageUrl"],
//                                             height: 90,
//                                             width: double.infinity,
//                                             fit: BoxFit.cover,
//                                             placeholder:
//                                                 (context, url) => Container(
//                                                   color: Colors.grey[200],
//                                                   child: const Center(
//                                                     child:
//                                                         CircularProgressIndicator(),
//                                                   ),
//                                                 ),
//                                             errorWidget:
//                                                 (context, url, error) =>
//                                                     Image.asset(
//                                                       'assets/placeholder.png',
//                                                       height: 90,
//                                                       width: double.infinity,
//                                                       fit: BoxFit.cover,
//                                                     ),
//                                           ),
//                                         ),
//                                         const SizedBox(height: 6),
//                                         Text(
//                                           _formatCourseTitle(course["title"]),
//                                           style: Theme.of(
//                                             context,
//                                           ).textTheme.titleSmall?.copyWith(
//                                             color: Colors.blue.shade900,
//                                             fontSize: 12,
//                                             fontFamily: 'RobotoMono',
//                                           ),
//                                           maxLines: 2,
//                                           overflow: TextOverflow.ellipsis,
//                                         ),
//                                         const SizedBox(height: 4),
//                                         Row(
//                                           children: [
//                                             Icon(
//                                               Icons.timer,
//                                               size: 12,
//                                               color: Colors.blue.shade700,
//                                             ),
//                                             const SizedBox(width: 4),
//                                             Expanded(
//                                               child: Text(
//                                                 "${course["duration"]} Days",
//                                                 style: TextStyle(
//                                                   color: Colors.blue.shade700,
//                                                   fontSize: 10,
//                                                 ),
//                                                 overflow: TextOverflow.ellipsis,
//                                               ),
//                                             ),
//                                           ],
//                                         ),
//                                         const SizedBox(height: 4),
//                                         Text(
//                                           "₹${course["price"]}",
//                                           style: TextStyle(
//                                             color: Colors.green.shade700,
//                                             fontSize: 10,
//                                           ),
//                                         ),
//                                         const SizedBox(height: 6),
//                                         _buildEnrollButton(
//                                           course["courseId"],
//                                           course["price"],
//                                         ),
//                                       ],
//                                     ),
//                                   ),
//                                 ),
//                               ),
//                             ),
//                           );
//                         },
//                       );
//                     },
//                   ),
//                 ),
//               ),
//             const SliverToBoxAdapter(
//               child: Text(
//                 "  Community Posts",
//                 style: TextStyle(
//                   fontWeight: FontWeight.bold,
//                   fontSize: 20,
//                   color: Color.fromARGB(255, 13, 71, 161),
//                 ),
//               ),
//             ),
//             PostListWidget(
//               key: _postListKey,
//               setDialogOpen:
//                   (value) => setState(() {
//                     debugPrint("setDialogOpen called with: $value");
//                     _isDialogOpen = value;
//                   }),
//             ),
//             const SliverToBoxAdapter(child: SizedBox(height: 98)),
//           ],
//         ),
//       ),
//     );
//   }

//   void _showCategoryCourses(BuildContext context, String category) {
//     final filteredCourses =
//         _courses.where((c) => c["category"] == category).toList();

//     setState(() {
//       _isDialogOpen = true;
//       debugPrint("Opening category dialog, _isDialogOpen: $_isDialogOpen");
//     });

//     showDialog(
//       context: context,
//       builder:
//           (context) => Dialog(
//             shape: RoundedRectangleBorder(
//               borderRadius: BorderRadius.circular(16),
//             ),
//             child: Container(
//               padding: const EdgeInsets.all(16),
//               decoration: BoxDecoration(
//                 gradient: LinearGradient(
//                   colors: [Colors.white, Colors.blue.shade50],
//                   begin: Alignment.topCenter,
//                   end: Alignment.bottomCenter,
//                 ),
//                 borderRadius: BorderRadius.circular(16),
//               ),
//               child: Column(
//                 mainAxisSize: MainAxisSize.min,
//                 children: [
//                   Text(
//                     category,
//                     style: Theme.of(context).textTheme.titleLarge?.copyWith(
//                       fontWeight: FontWeight.bold,
//                       color: Colors.blue.shade900,
//                     ),
//                   ),
//                   const SizedBox(height: 12),
//                   Flexible(
//                     child: ConstrainedBox(
//                       constraints: const BoxConstraints(maxHeight: 240),
//                       child:
//                           filteredCourses.isEmpty
//                               ? Center(
//                                 child: Text(
//                                   "No courses in this category",
//                                   style: TextStyle(color: Colors.blue.shade900),
//                                 ),
//                               )
//                               : ListView.builder(
//                                 scrollDirection: Axis.horizontal,
//                                 itemCount: filteredCourses.length,
//                                 itemBuilder: (context, index) {
//                                   final course = filteredCourses[index];
//                                   bool isTapped = false;
//                                   return StatefulBuilder(
//                                     builder: (context, setState) {
//                                       return GestureDetector(
//                                         onTapDown:
//                                             (_) =>
//                                                 setState(() => isTapped = true),
//                                         onTapUp:
//                                             (_) => setState(
//                                               () => isTapped = false,
//                                             ),
//                                         onTapCancel:
//                                             () => setState(
//                                               () => isTapped = false,
//                                             ),
//                                         onTap: () {
//                                           Navigator.push(
//                                             context,
//                                             MaterialPageRoute(
//                                               builder:
//                                                   (context) =>
//                                                       CourseContentPage(
//                                                         courseId:
//                                                             course["courseId"],
//                                                       ),
//                                             ),
//                                           );
//                                         },
//                                         child: AnimatedScale(
//                                           scale: isTapped ? 0.95 : 1.0,
//                                           duration: const Duration(
//                                             milliseconds: 100,
//                                           ),
//                                           child: SizedBox(
//                                             width: 180,
//                                             child: Card(
//                                               elevation: 4,
//                                               shape: RoundedRectangleBorder(
//                                                 borderRadius:
//                                                     BorderRadius.circular(12),
//                                               ),
//                                               margin: const EdgeInsets.all(8),
//                                               child: Padding(
//                                                 padding: const EdgeInsets.all(
//                                                   8,
//                                                 ),
//                                                 child: Column(
//                                                   crossAxisAlignment:
//                                                       CrossAxisAlignment.start,
//                                                   children: [
//                                                     ClipRRect(
//                                                       borderRadius:
//                                                           BorderRadius.circular(
//                                                             8,
//                                                           ),
//                                                       child: CachedNetworkImage(
//                                                         imageUrl:
//                                                             course["imageUrl"],
//                                                         height: 90,
//                                                         width: double.infinity,
//                                                         fit: BoxFit.cover,
//                                                         placeholder:
//                                                             (
//                                                               context,
//                                                               url,
//                                                             ) => Container(
//                                                               color:
//                                                                   Colors
//                                                                       .grey[200],
//                                                               child: const Center(
//                                                                 child:
//                                                                     CircularProgressIndicator(),
//                                                               ),
//                                                             ),
//                                                         errorWidget:
//                                                             (
//                                                               context,
//                                                               url,
//                                                               error,
//                                                             ) => Image.asset(
//                                                               'assets/placeholder.png',
//                                                               height: 90,
//                                                               width:
//                                                                   double
//                                                                       .infinity,
//                                                               fit: BoxFit.cover,
//                                                             ),
//                                                       ),
//                                                     ),
//                                                     const SizedBox(height: 6),
//                                                     Text(
//                                                       _formatCourseTitle(
//                                                         course["title"],
//                                                       ),
//                                                       style: Theme.of(context)
//                                                           .textTheme
//                                                           .titleSmall
//                                                           ?.copyWith(
//                                                             color:
//                                                                 Colors
//                                                                     .blue
//                                                                     .shade900,
//                                                             fontSize: 12,
//                                                             fontFamily:
//                                                                 'RobotoMono',
//                                                           ),
//                                                       maxLines: 2,
//                                                       overflow:
//                                                           TextOverflow.ellipsis,
//                                                     ),
//                                                     const SizedBox(height: 4),
//                                                     Row(
//                                                       children: [
//                                                         Icon(
//                                                           Icons.timer,
//                                                           size: 12,
//                                                           color:
//                                                               Colors
//                                                                   .blue
//                                                                   .shade700,
//                                                         ),
//                                                         const SizedBox(
//                                                           width: 4,
//                                                         ),
//                                                         Expanded(
//                                                           child: Text(
//                                                             "${course["duration"]} Days",
//                                                             style: TextStyle(
//                                                               color:
//                                                                   Colors
//                                                                       .blue
//                                                                       .shade700,
//                                                               fontSize: 10,
//                                                             ),
//                                                             overflow:
//                                                                 TextOverflow
//                                                                     .ellipsis,
//                                                           ),
//                                                         ),
//                                                       ],
//                                                     ),
//                                                     const SizedBox(height: 4),
//                                                     Text(
//                                                       "₹${course["price"]}",
//                                                       style: TextStyle(
//                                                         color:
//                                                             Colors
//                                                                 .green
//                                                                 .shade700,
//                                                         fontSize: 10,
//                                                       ),
//                                                     ),
//                                                     const SizedBox(height: 6),
//                                                     _buildEnrollButton(
//                                                       course["courseId"],
//                                                       course["price"],
//                                                     ),
//                                                   ],
//                                                 ),
//                                               ),
//                                             ),
//                                           ),
//                                         ),
//                                       );
//                                     },
//                                   );
//                                 },
//                               ),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ),
//     ).then(
//       (_) => setState(() {
//         _isDialogOpen = false;
//         debugPrint("Category dialog closed, _isDialogOpen: $_isDialogOpen");
//       }),
//     );
//   }
// }

// class DataSnapshotMock implements DataSnapshot {
//   @override
//   final dynamic value;
//   @override
//   final String key;

//   DataSnapshotMock({required this.value, required this.key});

//   @override
//   dynamic get priority => null;

//   @override
//   DatabaseReference get ref => throw UnimplementedError();

//   @override
//   bool get exists => value != null;

//   @override
//   DataSnapshot child(String path) => throw UnimplementedError();

//   @override
//   Iterable<DataSnapshot> get children => throw UnimplementedError();

//   @override
//   bool hasChild(String path) => throw UnimplementedError();
// }

// class PostListWidget extends StatefulWidget {
//   final Function(bool) setDialogOpen;

//   const PostListWidget({super.key, required this.setDialogOpen});

//   @override
//   State<PostListWidget> createState() => _PostListWidgetState();
// }

// class _PostListWidgetState extends State<PostListWidget> {
//   final DatabaseReference _postsRef = FirebaseDatabase.instance.ref("posts");
//   final DatabaseReference _usersPostsRef = FirebaseDatabase.instance.ref(
//     "users_posts",
//   );
//   final DatabaseReference _userRef = FirebaseDatabase.instance.ref("users");
//   List<Map<String, dynamic>> _posts = [];
//   bool _isPostsLoading = true;
//   final int _lastPostId = -1;
//   StreamSubscription<DatabaseEvent>? _postsSubscription;
//   final Map<String, Map<String, dynamic>> _postCache = {};
//   final Map<String, String?> _profileImageCache =
//       {}; // Cache for profile images
//   bool _isDialogOpen = false;

//   @override
//   void initState() {
//     super.initState();
//     _setupRealtimePostsListener();
//   }

//   @override
//   void dispose() {
//     _postsSubscription?.cancel();
//     super.dispose();
//   }

//   void _setupRealtimePostsListener() {
//     _postsSubscription = _postsRef.onValue.listen(
//       (event) async {
//         final prefs = await SharedPreferences.getInstance();
//         final cachedPostsJson = prefs.getString("cached_posts") ?? "[]";
//         List<Map<String, dynamic>> newPosts = [];

//         if (event.snapshot.value == null) {
//           setState(() {
//             _posts = [];
//             _isPostsLoading = false;
//           });
//           await prefs.setString("cached_posts", "[]");
//           await prefs.setStringList("cached_post_ids", []);
//           return;
//         }

//         try {
//           Map<String, dynamic> values;
//           if (event.snapshot.value is Map) {
//             values = Map<String, dynamic>.from(event.snapshot.value as Map);
//           } else if (event.snapshot.value is List) {
//             List<dynamic> list = event.snapshot.value as List<dynamic>;
//             values = {};
//             for (int i = 0; i < list.length; i++) {
//               if (list[i] != null) {
//                 values[i.toString()] = list[i];
//               }
//             }
//           } else {
//             throw Exception(
//               "Unexpected data type: ${event.snapshot.value.runtimeType}",
//             );
//           }

//           values.forEach((key, value) {
//             try {
//               final postData =
//                   jsonDecode(value as String) as Map<String, dynamic>;
//               postData["timestamp"] =
//                   postData["timestamp"] is int
//                       ? postData["timestamp"]
//                       : DateTime.now().millisecondsSinceEpoch;
//               _postCache[key] = postData;
//               newPosts.add({"postNo": key, ...postData});
//             } catch (e) {
//               print("Error parsing post $key: $e");
//             }
//           });

//           // Shuffle posts for random display
//           newPosts.shuffle();

//           if (newPosts.length > 100) {
//             newPosts = newPosts.sublist(0, 100);
//           }

//           final updatedPostIds =
//               newPosts.map((p) => p["postNo"] as String).toList();

//           // Save shuffled posts in cache
//           await prefs.setString("cached_posts", jsonEncode(newPosts));
//           await prefs.setStringList("cached_post_ids", updatedPostIds);

//           setState(() {
//             _posts = newPosts;
//             _isPostsLoading = false;
//           });
//         } catch (e) {
//           try {
//             final cachedPosts =
//                 (jsonDecode(cachedPostsJson) as List<dynamic>)
//                     .cast<Map<String, dynamic>>();

//             // Shuffle cached posts for random display
//             cachedPosts.shuffle();

//             setState(() {
//               _posts = cachedPosts;
//               _isPostsLoading = false;
//             });
//           } catch (cacheError) {
//             setState(() {
//               _posts = [];
//               _isPostsLoading = false;
//             });
//           }
//           _showSnackBar(
//             context,
//             "Failed to fetch posts: $e",
//             key: "posts_error",
//           );
//         }
//       },
//       onError: (error) {
//         SharedPreferences.getInstance().then((prefs) {
//           final cachedPostsJson = prefs.getString("cached_posts") ?? "[]";
//           try {
//             final cachedPosts =
//                 (jsonDecode(cachedPostsJson) as List<dynamic>)
//                     .cast<Map<String, dynamic>>();

//             // Shuffle cached posts for random display
//             cachedPosts.shuffle();

//             setState(() {
//               _posts = cachedPosts;
//               _isPostsLoading = false;
//             });
//           } catch (e) {
//             setState(() {
//               _posts = [];
//               _isPostsLoading = false;
//             });
//           }
//         });
//         _showSnackBar(
//           context,
//           "Failed to fetch posts: $error",
//           key: "posts_error",
//         );
//       },
//     );
//   }

//   void _toggleLike(String postId) async {
//     final user = FirebaseAuth.instance.currentUser;
//     if (user == null) {
//       _showSnackBar(context, "Please log in to like a post", key: "auth_error");
//       return;
//     }

//     try {
//       final postRef = _postsRef.child(postId);
//       final snapshot = await postRef.get();
//       if (!snapshot.exists) {
//         _showSnackBar(context, "Post no longer exists", key: "like_error");
//         return;
//       }

//       final postData =
//           jsonDecode(snapshot.value as String) as Map<String, dynamic>;
//       final likes = Map<String, dynamic>.from(postData["likes"] ?? {});

//       bool wasLiked = likes[user.uid] == true;
//       if (wasLiked) {
//         likes.remove(user.uid);
//         postData["likeCount"] = (postData["likeCount"] as int? ?? 0) - 1;
//       } else {
//         likes[user.uid] = true;
//         postData["likeCount"] = (postData["likeCount"] as int? ?? 0) + 1;
//       }

//       postData["likes"] = likes;
//       postData["timestamp"] = ServerValue.timestamp;

//       await postRef.set(jsonEncode(postData));

//       setState(() {
//         final postIndex = _posts.indexWhere((p) => p["postNo"] == postId);
//         if (postIndex != -1) {
//           _posts[postIndex] = {"postNo": postId, ...postData};
//         }
//         _postCache[postId] = postData;
//       });

//       final prefs = await SharedPreferences.getInstance();
//       await prefs.setString("cached_posts", jsonEncode(_posts));
//     } catch (e) {
//       _showSnackBar(context, "Failed to toggle like: $e", key: "like_error");
//     }
//   }

//   void _showComments(String postId, String username) {
//     TextEditingController commentController = TextEditingController();
//     bool isSubmitting = false;

//     setState(() {
//       _isDialogOpen = true;
//       widget.setDialogOpen(true);
//       debugPrint("Opening comments dialog, _isDialogOpen: $_isDialogOpen");
//     });

//     showDialog(
//       context: context,
//       barrierDismissible: false,
//       builder:
//           (dialogContext) => StatefulBuilder(
//             builder: (dialogContext, setState) {
//               return Dialog(
//                 shape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(12),
//                 ),
//                 child: Container(
//                   padding: const EdgeInsets.all(16),
//                   constraints: const BoxConstraints(maxHeight: 500),
//                   child: StreamBuilder<DatabaseEvent>(
//                     stream: _postsRef.child(postId).onValue,
//                     builder: (context, snapshot) {
//                       if (snapshot.connectionState == ConnectionState.waiting) {
//                         return const Center(child: CircularProgressIndicator());
//                       }

//                       if (!snapshot.hasData ||
//                           snapshot.data!.snapshot.value == null) {
//                         return const Center(child: Text("No comments yet"));
//                       }

//                       final postData =
//                           jsonDecode(snapshot.data!.snapshot.value as String)
//                               as Map<String, dynamic>;
//                       final comments = Map<String, dynamic>.from(
//                         postData["comments"] ?? {},
//                       );

//                       List<Map<String, dynamic>> commentList =
//                           comments.entries.map((e) {
//                             return {
//                               "commentId": e.key,
//                               "username": e.value["username"] ?? "anonymous",
//                               "text": e.value["text"] ?? "",
//                               "timestamp":
//                                   e.value["timestamp"] is int
//                                       ? e.value["timestamp"]
//                                       : DateTime.now().millisecondsSinceEpoch,
//                             };
//                           }).toList();

//                       commentList.sort(
//                         (a, b) =>
//                             (a["timestamp"] as int).compareTo(b["timestamp"]),
//                       );

//                       return Column(
//                         children: [
//                           const Text(
//                             "Comments",
//                             style: TextStyle(
//                               fontWeight: FontWeight.bold,
//                               fontSize: 18,
//                             ),
//                           ),
//                           const SizedBox(height: 8),
//                           Expanded(
//                             child: ListView.builder(
//                               itemCount: commentList.length,
//                               itemBuilder: (context, index) {
//                                 final comment = commentList[index];
//                                 return Card(
//                                   margin: const EdgeInsets.symmetric(
//                                     vertical: 4,
//                                   ),
//                                   elevation: 1,
//                                   child: Padding(
//                                     padding: const EdgeInsets.all(8),
//                                     child: Column(
//                                       crossAxisAlignment:
//                                           CrossAxisAlignment.start,
//                                       children: [
//                                         Row(
//                                           children: [
//                                             CircleAvatar(
//                                               radius: 16,
//                                               backgroundColor:
//                                                   Colors.blue.shade100,
//                                               child: Text(
//                                                 comment["username"][0]
//                                                     .toUpperCase(),
//                                                 style: TextStyle(
//                                                   color: Colors.blue.shade900,
//                                                   fontWeight: FontWeight.bold,
//                                                 ),
//                                               ),
//                                             ),
//                                             const SizedBox(width: 8),
//                                             Expanded(
//                                               child: Text(
//                                                 comment["username"],
//                                                 style: const TextStyle(
//                                                   fontWeight: FontWeight.bold,
//                                                   fontSize: 14,
//                                                 ),
//                                               ),
//                                             ),
//                                           ],
//                                         ),
//                                         const SizedBox(height: 4),
//                                         Text(
//                                           comment["text"],
//                                           style: const TextStyle(fontSize: 14),
//                                         ),
//                                       ],
//                                     ),
//                                   ),
//                                 );
//                               },
//                             ),
//                           ),
//                           const SizedBox(height: 8),
//                           TextField(
//                             controller: commentController,
//                             decoration: const InputDecoration(
//                               labelText: "Add a comment",
//                               border: OutlineInputBorder(),
//                             ),
//                             maxLines: 2,
//                             enabled: !isSubmitting,
//                           ),
//                           const SizedBox(height: 8),
//                           Row(
//                             mainAxisAlignment: MainAxisAlignment.end,
//                             children: [
//                               TextButton(
//                                 onPressed: () {
//                                   Navigator.pop(dialogContext);
//                                   this.setState(() {
//                                     _isDialogOpen = false;
//                                     widget.setDialogOpen(false);
//                                     debugPrint(
//                                       "Comments dialog closed, _isDialogOpen: $_isDialogOpen",
//                                     );
//                                   });
//                                 },
//                                 child: const Text("Close"),
//                               ),
//                               ElevatedButton(
//                                 onPressed:
//                                     isSubmitting
//                                         ? null
//                                         : () async {
//                                           if (commentController.text.isEmpty) {
//                                             _showSnackBar(
//                                               dialogContext,
//                                               "Comment cannot be empty",
//                                               key: "comment_error",
//                                             );
//                                             return;
//                                           }

//                                           final user =
//                                               FirebaseAuth.instance.currentUser;
//                                           if (user == null) {
//                                             _showSnackBar(
//                                               dialogContext,
//                                               "Please log in to comment",
//                                               key: "auth_error",
//                                             );
//                                             return;
//                                           }

//                                           setState(() => isSubmitting = true);

//                                           try {
//                                             final postRef = _postsRef.child(
//                                               postId,
//                                             );
//                                             final snapshot =
//                                                 await postRef.get();
//                                             if (!snapshot.exists) {
//                                               _showSnackBar(
//                                                 dialogContext,
//                                                 "Post no longer exists",
//                                                 key: "comment_error",
//                                               );
//                                               return;
//                                             }

//                                             final postData =
//                                                 jsonDecode(
//                                                       snapshot.value as String,
//                                                     )
//                                                     as Map<String, dynamic>;
//                                             final comments =
//                                                 Map<String, dynamic>.from(
//                                                   postData["comments"] ?? {},
//                                                 );

//                                             final commentId =
//                                                 DateTime.now()
//                                                     .millisecondsSinceEpoch
//                                                     .toString();
//                                             comments[commentId] = {
//                                               "text": commentController.text,
//                                               "username":
//                                                   user.email?.split('@')[0] ??
//                                                   "anonymous",
//                                               "timestamp":
//                                                   ServerValue.timestamp,
//                                             };

//                                             postData["comments"] = comments;
//                                             postData["timestamp"] =
//                                                 ServerValue.timestamp;

//                                             await postRef.set(
//                                               jsonEncode(postData),
//                                             );

//                                             commentController.clear();
//                                             setState(() {});
//                                           } catch (e) {
//                                             _showSnackBar(
//                                               dialogContext,
//                                               "Failed to add comment: $e",
//                                               key: "comment_error",
//                                             );
//                                           } finally {
//                                             setState(
//                                               () => isSubmitting = false,
//                                             );
//                                           }
//                                         },
//                                 child:
//                                     isSubmitting
//                                         ? const CircularProgressIndicator()
//                                         : const Text("Submit"),
//                               ),
//                             ],
//                           ),
//                         ],
//                       );
//                     },
//                   ),
//                 ),
//               );
//             },
//           ),
//     ).then((_) {
//       setState(() {
//         _isDialogOpen = false;
//         widget.setDialogOpen(false);
//         debugPrint(
//           "Comments dialog closed via then, _isDialogOpen: $_isDialogOpen",
//         );
//       });
//     });
//   }

//   Future<File?> _downloadImage(String imageUrl) async {
//     try {
//       final response = await http
//           .get(Uri.parse(imageUrl))
//           .timeout(const Duration(seconds: 10));
//       if (response.statusCode == 200) {
//         final tempDir = await getTemporaryDirectory();
//         final file = File(
//           '${tempDir.path}/post_image_${DateTime.now().millisecondsSinceEpoch}.jpg',
//         );
//         await file.writeAsBytes(response.bodyBytes);
//         return file;
//       }
//       return null;
//     } catch (e) {
//       return null;
//     }
//   }

//   void _sharePost(
//     String postId,
//     String username,
//     String link,
//     String description,
//     List<String> imageUrls,
//   ) async {
//     try {
//       final postRef = _postsRef.child(postId);
//       final snapshot = await postRef.get();
//       if (!snapshot.exists) {
//         _showSnackBar(context, "Post no longer exists", key: "share_error");
//         return;
//       }

//       final postData =
//           jsonDecode(snapshot.value as String) as Map<String, dynamic>;
//       postData["shareCount"] = (postData["shareCount"] as int? ?? 0) + 1;
//       postData["timestamp"] = ServerValue.timestamp;

//       await postRef.set(jsonEncode(postData));

//       setState(() {
//         final postIndex = _posts.indexWhere((p) => p["postNo"] == postId);
//         if (postIndex != -1) {
//           _posts[postIndex] = {"postNo": postId, ...postData};
//         }
//         _postCache[postId] = postData;
//       });

//       final prefs = await SharedPreferences.getInstance();
//       await prefs.setString("cached_posts", jsonEncode(_posts));

//       final shareText =
//           description.isNotEmpty
//               ? link.isNotEmpty
//                   ? "$description\nCheck out this post: $link"
//                   : description
//               : link.isNotEmpty
//               ? "Check out this post: $link"
//               : "Check out this post by $username!";

//       if (imageUrls.isNotEmpty) {
//         final imageFile = await _downloadImage(imageUrls[0]);
//         if (imageFile != null) {
//           await Share.shareXFiles([XFile(imageFile.path)], text: shareText);
//           await imageFile.delete();
//         } else {
//           await Share.share(shareText);
//           _showSnackBar(
//             context,
//             "Failed to download image, sharing text only",
//             key: "share_error",
//           );
//         }
//       } else {
//         await Share.share(shareText);
//       }
//     } catch (e) {
//       _showSnackBar(context, "Failed to share post: $e", key: "share_error");
//     }
//   }

//   void _showSnackBar(
//     BuildContext context,
//     String message, {
//     required String key,
//   }) {
//     ScaffoldMessenger.of(context).hideCurrentSnackBar();
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         key: ValueKey(key),
//         content: Text(message),
//         duration: const Duration(seconds: 3),
//         action: SnackBarAction(
//           label: 'Dismiss',
//           onPressed: () => ScaffoldMessenger.of(context).hideCurrentSnackBar(),
//         ),
//       ),
//     );
//   }

//   Widget _buildPostSkeleton() {
//     return Shimmer.fromColors(
//       baseColor: Colors.grey[300]!,
//       highlightColor: Colors.grey[100]!,
//       child: Card(
//         margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//         child: Padding(
//           padding: const EdgeInsets.all(16),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Row(
//                 children: [
//                   Container(
//                     width: 40,
//                     height: 40,
//                     decoration: const BoxDecoration(
//                       shape: BoxShape.circle,
//                       color: Colors.white,
//                     ),
//                   ),
//                   const SizedBox(width: 8),
//                   Container(width: 100, height: 14, color: Colors.white),
//                   const Spacer(),
//                   Container(width: 80, height: 12, color: Colors.white),
//                 ],
//               ),
//               const SizedBox(height: 8),
//               Container(
//                 height: 300,
//                 width: double.infinity,
//                 decoration: BoxDecoration(
//                   color: Colors.white,
//                   borderRadius: BorderRadius.circular(8),
//                 ),
//               ),
//               const SizedBox(height: 8),
//               Container(height: 14, width: 150, color: Colors.white),
//               const SizedBox(height: 4),
//               Container(
//                 height: 10,
//                 width: double.infinity,
//                 color: Colors.white,
//               ),
//               const SizedBox(height: 4),
//               Container(
//                 height: 10,
//                 width: double.infinity,
//                 color: Colors.white,
//               ),
//               const SizedBox(height: 8),
//               Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                 children: [
//                   Container(width: 60, height: 10, color: Colors.white),
//                   Container(width: 60, height: 10, color: Colors.white),
//                   Container(width: 60, height: 10, color: Colors.white),
//                 ],
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   void _showImageGallery(
//     BuildContext context,
//     List<String> imageUrls,
//     int initialIndex,
//   ) {
//     setState(() {
//       _isDialogOpen = true;
//       widget.setDialogOpen(true);
//       debugPrint("Opening image gallery, _isDialogOpen: $_isDialogOpen");
//     });
//     Navigator.push(
//       context,
//       MaterialPageRoute(
//         builder:
//             (context) => Scaffold(
//               appBar: AppBar(
//                 backgroundColor: Colors.black,
//                 leading: IconButton(
//                   icon: const Icon(Icons.close, color: Colors.white),
//                   onPressed: () {
//                     Navigator.pop(context);
//                     setState(() {
//                       _isDialogOpen = false;
//                       widget.setDialogOpen(false);
//                       debugPrint(
//                         "Image gallery closed, _isDialogOpen: $_isDialogOpen",
//                       );
//                     });
//                   },
//                 ),
//               ),
//               body: PhotoViewGallery.builder(
//                 itemCount: imageUrls.length,
//                 builder: (context, index) {
//                   return PhotoViewGalleryPageOptions(
//                     imageProvider: NetworkImage(imageUrls[index]),
//                     minScale: PhotoViewComputedScale.contained,
//                     maxScale: PhotoViewComputedScale.covered * 2,
//                   );
//                 },
//                 scrollPhysics: const BouncingScrollPhysics(),
//                 backgroundDecoration: const BoxDecoration(color: Colors.black),
//                 pageController: PageController(initialPage: initialIndex),
//               ),
//             ),
//       ),
//     ).then((_) {
//       setState(() {
//         _isDialogOpen = false;
//         widget.setDialogOpen(false);
//         debugPrint(
//           "Image gallery closed via then, _isDialogOpen: $_isDialogOpen",
//         );
//       });
//     });
//   }

//   Widget _buildPostCard(Map<String, dynamic> post) {
//     final postId = post["postNo"] as String? ?? "";
//     final userId = post["user_id"] as String? ?? "";
//     final username = post["username"] as String? ?? "anonymous";
//     final imageUrls = List<String>.from(post["imageUrls"] ?? []);
//     final title = post["title"] as String? ?? "";
//     final description = post["description"] as String? ?? "";
//     final link = post["link"] as String? ?? "";
//     final likeCount = post["likeCount"] as int? ?? 0;
//     final comments = Map<String, dynamic>.from(post["comments"] ?? {});
//     final shareCount = post["shareCount"] as int? ?? 0;

//     Widget buildImageCollage() {
//       if (imageUrls.isEmpty) {
//         return const SizedBox.shrink();
//       }

//       return LayoutBuilder(
//         builder: (context, constraints) {
//           final maxWidth = constraints.maxWidth;
//           const gap = 4.0;

//           if (imageUrls.length == 1) {
//             return GestureDetector(
//               onTap: () => _showImageGallery(context, imageUrls, 0),
//               child: ClipRRect(
//                 borderRadius: BorderRadius.circular(8),
//                 child: ConstrainedBox(
//                   constraints: const BoxConstraints(maxHeight: 400),
//                   child: SizedBox(
//                     width: maxWidth,
//                     child: AspectRatio(
//                       aspectRatio: 16 / 9,
//                       child: CachedNetworkImage(
//                         imageUrl: imageUrls[0],
//                         fit: BoxFit.cover,
//                         placeholder:
//                             (context, url) => Shimmer.fromColors(
//                               baseColor: Colors.grey[300]!,
//                               highlightColor: Colors.grey[100]!,
//                               child: Container(color: Colors.grey[200]),
//                             ),
//                         errorWidget:
//                             (context, url, error) => Container(
//                               color: Colors.grey[200],
//                               child: const Icon(Icons.error, color: Colors.red),
//                             ),
//                       ),
//                     ),
//                   ),
//                 ),
//               ),
//             );
//           } else if (imageUrls.length == 2) {
//             return Row(
//               children:
//                   imageUrls.asMap().entries.map((entry) {
//                     final index = entry.key;
//                     final url = entry.value;
//                     return Expanded(
//                       child: GestureDetector(
//                         onTap:
//                             () => _showImageGallery(context, imageUrls, index),
//                         child: Padding(
//                           padding: EdgeInsets.only(
//                             left: index == 0 ? 0 : gap / 2,
//                             right: index == 1 ? 0 : gap / 2,
//                           ),
//                           child: ClipRRect(
//                             borderRadius: BorderRadius.circular(8),
//                             child: AspectRatio(
//                               aspectRatio: 4 / 3,
//                               child: CachedNetworkImage(
//                                 imageUrl: url,
//                                 fit: BoxFit.cover,
//                                 placeholder:
//                                     (context, url) => Shimmer.fromColors(
//                                       baseColor: Colors.grey[300]!,
//                                       highlightColor: Colors.grey[100]!,
//                                       child: Container(color: Colors.grey[200]),
//                                     ),
//                                 errorWidget:
//                                     (context, url, error) => Container(
//                                       color: Colors.grey[200],
//                                       child: const Icon(
//                                         Icons.error,
//                                         color: Colors.red,
//                                       ),
//                                     ),
//                               ),
//                             ),
//                           ),
//                         ),
//                       ),
//                     );
//                   }).toList(),
//             );
//           } else if (imageUrls.length == 3) {
//             return Row(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Expanded(
//                   flex: 2,
//                   child: GestureDetector(
//                     onTap: () => _showImageGallery(context, imageUrls, 0),
//                     child: ClipRRect(
//                       borderRadius: BorderRadius.circular(8),
//                       child: AspectRatio(
//                         aspectRatio: 4 / 3,
//                         child: CachedNetworkImage(
//                           imageUrl: imageUrls[0],
//                           fit: BoxFit.cover,
//                           placeholder:
//                               (context, url) => Shimmer.fromColors(
//                                 baseColor: Colors.grey[300]!,
//                                 highlightColor: Colors.grey[100]!,
//                                 child: Container(color: Colors.grey[200]),
//                               ),
//                           errorWidget:
//                               (context, url, error) => Container(
//                                 color: Colors.grey[200],
//                                 child: const Icon(
//                                   Icons.error,
//                                   color: Colors.red,
//                                 ),
//                               ),
//                         ),
//                       ),
//                     ),
//                   ),
//                 ),
//                 const SizedBox(width: gap),
//                 Expanded(
//                   flex: 1,
//                   child: Column(
//                     children: [
//                       GestureDetector(
//                         onTap: () => _showImageGallery(context, imageUrls, 1),
//                         child: ClipRRect(
//                           borderRadius: BorderRadius.circular(8),
//                           child: AspectRatio(
//                             aspectRatio: 4 / 3,
//                             child: CachedNetworkImage(
//                               imageUrl: imageUrls[1],
//                               fit: BoxFit.cover,
//                               placeholder:
//                                   (context, url) => Shimmer.fromColors(
//                                     baseColor: Colors.grey[300]!,
//                                     highlightColor: Colors.grey[100]!,
//                                     child: Container(color: Colors.grey[200]),
//                                   ),
//                               errorWidget:
//                                   (context, url, error) => Container(
//                                     color: Colors.grey[200],
//                                     child: const Icon(
//                                       Icons.error,
//                                       color: Colors.red,
//                                     ),
//                                   ),
//                             ),
//                           ),
//                         ),
//                       ),
//                       const SizedBox(height: gap),
//                       GestureDetector(
//                         onTap: () => _showImageGallery(context, imageUrls, 2),
//                         child: ClipRRect(
//                           borderRadius: BorderRadius.circular(8),
//                           child: AspectRatio(
//                             aspectRatio: 4 / 3,
//                             child: CachedNetworkImage(
//                               imageUrl: imageUrls[2],
//                               fit: BoxFit.cover,
//                               placeholder:
//                                   (context, url) => Shimmer.fromColors(
//                                     baseColor: Colors.grey[300]!,
//                                     highlightColor: Colors.grey[100]!,
//                                     child: Container(color: Colors.grey[200]),
//                                   ),
//                               errorWidget:
//                                   (context, url, error) => Container(
//                                     color: Colors.grey[200],
//                                     child: const Icon(
//                                       Icons.error,
//                                       color: Colors.red,
//                                     ),
//                                   ),
//                             ),
//                           ),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ],
//             );
//           } else {
//             final displayCount = imageUrls.length > 4 ? 4 : imageUrls.length;
//             return GridView.count(
//               crossAxisCount: 2,
//               crossAxisSpacing: gap,
//               mainAxisSpacing: gap,
//               physics: const NeverScrollableScrollPhysics(),
//               shrinkWrap: true,
//               childAspectRatio: 4 / 3,
//               children: List.generate(displayCount, (index) {
//                 if (index == 3 && imageUrls.length > 4) {
//                   return GestureDetector(
//                     onTap: () => _showImageGallery(context, imageUrls, index),
//                     child: ClipRRect(
//                       borderRadius: BorderRadius.circular(8),
//                       child: Stack(
//                         fit: StackFit.expand,
//                         children: [
//                           CachedNetworkImage(
//                             imageUrl: imageUrls[index],
//                             fit: BoxFit.cover,
//                             placeholder:
//                                 (context, url) => Shimmer.fromColors(
//                                   baseColor: Colors.grey[300]!,
//                                   highlightColor: Colors.grey[100]!,
//                                   child: Container(color: Colors.grey[200]),
//                                 ),
//                             errorWidget:
//                                 (context, url, error) => Container(
//                                   color: Colors.grey[200],
//                                   child: const Icon(
//                                     Icons.error,
//                                     color: Colors.red,
//                                   ),
//                                 ),
//                           ),
//                           Container(
//                             color: Colors.black.withOpacity(0.4),
//                             child: Center(
//                               child: Text(
//                                 "+${imageUrls.length - 4}",
//                                 style: const TextStyle(
//                                   color: Colors.white,
//                                   fontSize: 24,
//                                   fontWeight: FontWeight.bold,
//                                 ),
//                               ),
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                   );
//                 }
//                 return GestureDetector(
//                   onTap: () => _showImageGallery(context, imageUrls, index),
//                   child: ClipRRect(
//                     borderRadius: BorderRadius.circular(8),
//                     child: CachedNetworkImage(
//                       imageUrl: imageUrls[index],
//                       fit: BoxFit.cover,
//                       placeholder:
//                           (context, url) => Shimmer.fromColors(
//                             baseColor: Colors.grey[300]!,
//                             highlightColor: Colors.grey[100]!,
//                             child: Container(color: Colors.grey[200]),
//                           ),
//                       errorWidget:
//                           (context, url, error) => Container(
//                             color: Colors.grey[200],
//                             child: const Icon(Icons.error, color: Colors.red),
//                           ),
//                     ),
//                   ),
//                 );
//               }),
//             );
//           }
//         },
//       );
//     }

//     return Card(
//       margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//       elevation: 2,
//       child: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Row(
//               children: [
//                 FutureBuilder<String?>(
//                   future:
//                       _profileImageCache.containsKey(userId)
//                           ? Future.value(_profileImageCache[userId])
//                           : _userRef
//                               .child(userId)
//                               .child("profileImage")
//                               .get()
//                               .then((snapshot) {
//                                 final imageUrl = snapshot.value as String?;
//                                 _profileImageCache[userId] = imageUrl;
//                                 return imageUrl;
//                               })
//                               .catchError((e) {
//                                 _profileImageCache[userId] = null;
//                                 return null;
//                               }),
//                   builder: (context, snapshot) {
//                     return CircleAvatar(
//                       radius: 20,
//                       backgroundColor: Colors.blue.shade100,
//                       backgroundImage:
//                           snapshot.hasData && snapshot.data != null
//                               ? CachedNetworkImageProvider(
//                                 snapshot.data!,
//                                 // errorListener:
//                                 // () => _profileImageCache[userId] = null,
//                               )
//                               : null,
//                       child:
//                           snapshot.hasData && snapshot.data == null
//                               ? Text(
//                                 username.isNotEmpty
//                                     ? username[0].toUpperCase()
//                                     : "?",
//                                 style: TextStyle(
//                                   color: Colors.blue.shade900,
//                                   fontWeight: FontWeight.bold,
//                                 ),
//                               )
//                               : null,
//                     );
//                   },
//                 ),
//                 const SizedBox(width: 8),
//                 Expanded(
//                   child: Text(
//                     username,
//                     style: TextStyle(
//                       fontWeight: FontWeight.bold,
//                       color: Colors.blue.shade900,
//                       fontSize: 16,
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//             const SizedBox(height: 12),
//             buildImageCollage(),
//             const SizedBox(height: 12),
//             Text(
//               title,
//               style: TextStyle(
//                 fontWeight: FontWeight.bold,
//                 color: Colors.blue.shade900,
//                 fontSize: 16,
//               ),
//             ),
//             const SizedBox(height: 4),
//             Text(
//               description,
//               style: TextStyle(color: Colors.blue.shade700, fontSize: 14),
//             ),
//             if (link.isNotEmpty) ...[
//               const SizedBox(height: 4),
//               InkWell(
//                 onTap: () async {
//                   final url = Uri.parse(link);
//                   if (await canLaunchUrl(url)) {
//                     await launchUrl(url);
//                   } else {
//                     _showSnackBar(
//                       context,
//                       "Cannot open link",
//                       key: "link_error",
//                     );
//                   }
//                 },
//                 child: Text(
//                   link,
//                   style: const TextStyle(
//                     color: Colors.blue,
//                     decoration: TextDecoration.underline,
//                     fontSize: 14,
//                   ),
//                 ),
//               ),
//             ],
//             const SizedBox(height: 8),
//             const Divider(),
//             StreamBuilder<DatabaseEvent>(
//               stream: _postsRef.child(postId).onValue,
//               builder: (context, snapshot) {
//                 bool isLiked = false;
//                 int currentLikeCount = likeCount;
//                 int currentCommentCount = comments.length;
//                 int currentShareCount = shareCount;

//                 if (snapshot.hasData && snapshot.data!.snapshot.value != null) {
//                   try {
//                     final postData =
//                         jsonDecode(snapshot.data!.snapshot.value as String)
//                             as Map<String, dynamic>;
//                     final likes = Map<String, dynamic>.from(
//                       postData["likes"] ?? {},
//                     );
//                     isLiked =
//                         likes[FirebaseAuth.instance.currentUser?.uid ?? ""] ==
//                         true;
//                     currentLikeCount = postData["likeCount"] as int? ?? 0;
//                     currentCommentCount =
//                         (postData["comments"] as Map<dynamic, dynamic>?)
//                             ?.length ??
//                         0;
//                     currentShareCount = postData["shareCount"] as int? ?? 0;
//                   } catch (e) {
//                     print("Error parsing post data in StreamBuilder: $e");
//                   }
//                 }

//                 return Row(
//                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                   children: [
//                     TextButton.icon(
//                       onPressed: () => _toggleLike(postId),
//                       icon: Icon(
//                         isLiked ? Icons.favorite : Icons.favorite_border,
//                         color: isLiked ? Colors.red : Colors.grey,
//                         size: 20,
//                       ),
//                       label: Text(
//                         "$currentLikeCount Likes",
//                         style: const TextStyle(
//                           color: Colors.grey,
//                           fontSize: 12,
//                         ),
//                       ),
//                     ),
//                     TextButton.icon(
//                       onPressed: () => _showComments(postId, username),
//                       icon: const Icon(
//                         Icons.comment,
//                         color: Colors.grey,
//                         size: 20,
//                       ),
//                       label: Text(
//                         "$currentCommentCount Comments",
//                         style: const TextStyle(
//                           color: Colors.grey,
//                           fontSize: 12,
//                         ),
//                       ),
//                     ),
//                     TextButton.icon(
//                       onPressed:
//                           () => _sharePost(
//                             postId,
//                             username,
//                             link,
//                             description,
//                             imageUrls,
//                           ),
//                       icon: const Icon(
//                         Icons.share,
//                         color: Colors.grey,
//                         size: 20,
//                       ),
//                       label: Text(
//                         "$currentShareCount Shares",
//                         style: const TextStyle(
//                           color: Colors.grey,
//                           fontSize: 12,
//                         ),
//                       ),
//                     ),
//                   ],
//                 );
//               },
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     if (_isPostsLoading) {
//       return SliverList(
//         delegate: SliverChildBuilderDelegate(
//           (context, index) => _buildPostSkeleton(),
//           childCount: 3,
//         ),
//       );
//     } else if (_posts.isEmpty) {
//       return SliverToBoxAdapter(
//         child: Padding(
//           padding: const EdgeInsets.all(16),
//           child: Text(
//             "No posts available",
//             style: TextStyle(color: Colors.blue.shade900),
//           ),
//         ),
//       );
//     } else {
//       return SliverList(
//         delegate: SliverChildBuilderDelegate((context, index) {
//           try {
//             return _buildPostCard(_posts[index]);
//           } catch (e) {
//             return Padding(
//               padding: const EdgeInsets.all(16),
//               child: Text(
//                 "Error loading post: $e",
//                 style: TextStyle(color: Colors.red.shade700),
//               ),
//             );
//           }
//         }, childCount: _posts.length),
//       );
//     }
//   }
// }
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';
import 'package:share_plus/share_plus.dart';
import 'package:skillup/General%20User%20Pages/fab.dart';
import 'package:skillup/General%20User%20Pages/hero.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:path_provider/path_provider.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shimmer/shimmer.dart';
import '/General%20User%20Pages/course.dart';

class UserDashboardWidget extends StatefulWidget {
  const UserDashboardWidget({super.key});

  @override
  _UserDashboardWidgetState createState() => _UserDashboardWidgetState();
}

class _UserDashboardWidgetState extends State<UserDashboardWidget>
    with SingleTickerProviderStateMixin {
  final DatabaseReference _database = FirebaseDatabase.instance.ref("courses");
  final DatabaseReference _userRef = FirebaseDatabase.instance.ref("users");
  final DatabaseReference _postsRef = FirebaseDatabase.instance.ref("posts");
  final DatabaseReference _usersPostsRef = FirebaseDatabase.instance.ref(
    "users_posts",
  );
  List<Map<String, dynamic>> _courses = [];
  List<String> _categories = [];
  late AnimationController _loadingController;
  bool _isLoading = true;
  bool _isUserDataLoading = true;
  String? _membershipPlan;
  String? _processingCourseId;
  final Razorpay _razorpay = Razorpay();
  bool _isDialogOpen = false;
  final Map<String, Future<DataSnapshot>> _purchaseFutures = {};
  final GlobalKey<_PostListWidgetState> _postListKey =
      GlobalKey<_PostListWidgetState>();

  @override
  void initState() {
    super.initState();
    _loadingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
    _fetchCourses();
    _fetchUserData();

    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  @override
  void dispose() {
    _loadingController.dispose();
    _razorpay.clear();
    super.dispose();
  }

  void _fetchUserData() async {
    var user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() => _isUserDataLoading = false);
      return;
    }

    try {
      DataSnapshot snapshot = await _userRef.child(user.uid).get();
      setState(() {
        _membershipPlan = snapshot.child('membershipPlan').value.toString();
        _isUserDataLoading = false;
      });
    } catch (e) {
      setState(() => _isUserDataLoading = false);
      _showSnackBar("Failed to fetch user data: $e", key: "user_data_error");
    }
  }

  void _fetchCourses() {
    setState(() => _isLoading = true);
    _database.onValue.listen(
      (event) {
        if (event.snapshot.value != null) {
          Map<dynamic, dynamic> values =
              event.snapshot.value as Map<dynamic, dynamic>;
          List<Map<String, dynamic>> tempCourses = [];
          Set<String> categorySet = {};

          values.forEach((key, value) {
            if (value["status"] == "verified") {
              tempCourses.add({
                "courseId": key,
                "title": value["title"] ?? "No Title",
                "category": value["category"] ?? "Uncategorized",
                "price": double.tryParse(value["price"].toString()) ?? 0.0,
                "language": value["language"] ?? "Unknown",
                "duration": value["duration"] ?? "0",
                "imageUrl":
                    value["imageUrl"] ?? "https://via.placeholder.com/400",
              });
              categorySet.add(value["category"] ?? "Uncategorized");
            }
          });

          setState(() {
            _courses = tempCourses;
            _categories = categorySet.toList();
            _isLoading = false;
          });
        } else {
          setState(() {
            _courses = [];
            _categories = [];
            _isLoading = false;
          });
        }
      },
      onError: (error) {
        setState(() => _isLoading = false);
        _showSnackBar("Failed to fetch courses: $error", key: "courses_error");
      },
    );
  }

  void _startPayment(double price, String courseId) {
    var options = {
      'key': 'rzp_live_HJl9NwyBSY9rwV',
      'amount': (price * 100).toInt(),
      'name': 'Course Payment',
      'description': 'Payment for course $courseId',
      'prefill': {
        'contact': '+91 8639122823',
        'email': FirebaseAuth.instance.currentUser?.email ?? 'live@ggu.edu.in',
      },
      'theme': {'color': '#F37254'},
    };

    _razorpay.open(options);
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) {
    final courseId = _processingCourseId;
    final userId = FirebaseAuth.instance.currentUser?.uid;

    if (userId == null || courseId == null) {
      _showSnackBar(
        "Error: User not logged in or course missing",
        key: "payment_error",
      );
      setState(() => _processingCourseId = null);
      return;
    }

    setState(() => _processingCourseId = null);

    _userRef
        .child(userId)
        .child("purchasedCourses")
        .child(courseId)
        .set(true)
        .then((_) {
          _showSnackBar(
            "Payment Successful! Course added to your account.",
            key: "payment_success",
          );
          setState(() {
            _purchaseFutures[courseId] = Future.value(
              DataSnapshotMock(value: true, key: courseId),
            );
          });
        })
        .catchError((error) {
          _showSnackBar(
            "Failed to update purchased courses: $error",
            key: "payment_error",
          );
        });
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    setState(() => _processingCourseId = null);
    _showSnackBar("Payment Failed: ${response.message}", key: "payment_error");
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    setState(() => _processingCourseId = null);
    _showSnackBar(
      "External Wallet Used: ${response.walletName}",
      key: "payment_wallet",
    );
  }

  String _formatCourseTitle(String title) {
    const int maxLength = 20;
    if (title.length > maxLength) {
      return "${title.substring(0, maxLength - 3)}...";
    } else {
      return title.padRight(maxLength);
    }
  }

  Widget _buildEnrollButton(String courseId, double price) {
    if (_isUserDataLoading) {
      return const SizedBox(
        width: double.infinity,
        height: 32,
        child: ElevatedButton(
          onPressed: null,
          child: CircularProgressIndicator(),
        ),
      );
    }

    final bool isProcessing = courseId == _processingCourseId;

    _purchaseFutures[courseId] ??=
        _userRef
            .child(FirebaseAuth.instance.currentUser!.uid)
            .child("purchasedCourses")
            .child(courseId)
            .get();

    return FutureBuilder<DataSnapshot>(
      future: _purchaseFutures[courseId],
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            width: double.infinity,
            height: 32,
            child: ElevatedButton(
              onPressed: null,
              child: CircularProgressIndicator(),
            ),
          );
        }

        bool isPurchased = snapshot.hasData && snapshot.data!.value == true;

        return SizedBox(
          width: double.infinity,
          height: 32,
          child: FilledButton(
            key: ValueKey("enroll_$courseId"),
            onPressed:
                isProcessing || _isDialogOpen
                    ? null
                    : () {
                      if (_membershipPlan == "true" || isPurchased) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (context) =>
                                    CourseContentPage(courseId: courseId),
                          ),
                        );
                      } else {
                        setState(() => _processingCourseId = courseId);
                        _startPayment(price, courseId);
                      }
                    },
            style: FilledButton.styleFrom(
              backgroundColor:
                  isPurchased || _membershipPlan == "true"
                      ? const Color.fromARGB(255, 10, 145, 255)
                      : Colors.blue.shade900,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(vertical: 8),
            ),
            child:
                isProcessing
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(
                      isPurchased || _membershipPlan == "true"
                          ? "View Course"
                          : "Enroll Now",
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
          ),
        );
      },
    );
  }

  void _createPost() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _showSnackBar("Please log in to create a post", key: "auth_error");
      return;
    }

    final userId = user.uid;
    final username = user.email?.split('@')[0] ?? "anonymous";
    TextEditingController titleController = TextEditingController();
    TextEditingController descriptionController = TextEditingController();
    TextEditingController linkController = TextEditingController();
    List<File> imageFiles = [];
    bool isUploading = false;

    setState(() {
      _isDialogOpen = true;
      debugPrint("Opening create post dialog, _isDialogOpen: $_isDialogOpen");
    });

    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (dialogContext) => StatefulBuilder(
            builder: (dialogContext, setState) {
              return AlertDialog(
                title: const Text("Create Post"),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: titleController,
                        decoration: const InputDecoration(labelText: "Title"),
                        maxLength: 100,
                      ),
                      TextField(
                        controller: descriptionController,
                        decoration: const InputDecoration(
                          labelText: "Description",
                        ),
                        maxLines: 3,
                        maxLength: 500,
                      ),
                      TextField(
                        controller: linkController,
                        decoration: const InputDecoration(
                          labelText: "Link (Optional)",
                        ),
                        keyboardType: TextInputType.url,
                      ),
                      const SizedBox(height: 10),
                      ElevatedButton(
                        onPressed:
                            isUploading || imageFiles.length >= 3
                                ? null
                                : () async {
                                  final picker = ImagePicker();
                                  final pickedFile = await picker.pickImage(
                                    source: ImageSource.gallery,
                                  );
                                  if (pickedFile != null) {
                                    final file = File(pickedFile.path);
                                    final fileSize = await file.length();
                                    if (fileSize > 10 * 1024 * 1024) {
                                      _showSnackBar(
                                        "Image size exceeds 10MB limit",
                                        key: "image_error",
                                      );
                                      return;
                                    }
                                    setState(() {
                                      imageFiles.add(file);
                                    });
                                  }
                                },
                        child: Text(
                          imageFiles.isEmpty
                              ? "Pick Images"
                              : "${imageFiles.length}/3 Images Selected",
                        ),
                      ),
                      if (imageFiles.isNotEmpty)
                        Wrap(
                          spacing: 8,
                          children:
                              imageFiles
                                  .map(
                                    (file) => Image.file(
                                      file,
                                      width: 60,
                                      height: 60,
                                      fit: BoxFit.cover,
                                    ),
                                  )
                                  .toList(),
                        ),
                      if (isUploading) const CircularProgressIndicator(),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.pop(dialogContext);
                      setState(() => _isDialogOpen = false);
                      debugPrint(
                        "Create post dialog cancelled, _isDialogOpen: $_isDialogOpen",
                      );
                    },
                    child: const Text("Cancel"),
                  ),
                  ElevatedButton(
                    onPressed:
                        isUploading
                            ? null
                            : () async {
                              final title = titleController.text.trim();
                              final description =
                                  descriptionController.text.trim();
                              final link = linkController.text.trim();

                              if (title.isEmpty ||
                                  description.isEmpty ||
                                  imageFiles.isEmpty) {
                                _showSnackBar(
                                  "Title, description, and at least one image are required",
                                  key: "post_error",
                                );
                                return;
                              }

                              setState(() => isUploading = true);
                              debugPrint(
                                "Starting post creation for user: $userId",
                              );

                              try {
                                // Upload images to Cloudinary
                                List<String> imageUrls = [];
                                for (var imageFile in imageFiles) {
                                  debugPrint(
                                    "Uploading image: ${imageFile.path}",
                                  );
                                  if (!await imageFile.exists()) {
                                    throw Exception(
                                      "Image file does not exist: ${imageFile.path}",
                                    );
                                  }
                                  final imageUrl = await _uploadToCloudinary(
                                    imageFile,
                                  );
                                  if (imageUrl == null) {
                                    throw Exception(
                                      "Failed to upload image: ${imageFile.path}",
                                    );
                                  }
                                  imageUrls.add(imageUrl);
                                  debugPrint("Image uploaded: $imageUrl");
                                }

                                // Generate post ID
                                final postId = await _generatePostId();
                                debugPrint("Generated post ID: $postId");

                                // Prepare post data
                                final postData = {
                                  "post_id": postId,
                                  "user_id": userId,
                                  "username": username,
                                  "imageUrls": imageUrls,
                                  "title": title,
                                  "description": description,
                                  "link": link,
                                  "likeCount": 0,
                                  "likes": {},
                                  "comments": {},
                                  "shareCount": 0,
                                  "timestamp": ServerValue.timestamp,
                                };

                                // Write to Firebase
                                debugPrint("Writing post data to Firebase");
                                await _postsRef
                                    .child(postId)
                                    .set(jsonEncode(postData))
                                    .catchError((error) {
                                      throw Exception(
                                        "Failed to write post to posts/$postId: $error",
                                      );
                                    });

                                debugPrint(
                                  "Writing to users_posts/$userId/$postId",
                                );
                                await _usersPostsRef
                                    .child(userId)
                                    .child(postId)
                                    .set(true)
                                    .catchError((error) {
                                      _postsRef.child(postId).remove();
                                      throw Exception(
                                        "Failed to write to users_posts/$userId/$postId: $error",
                                      );
                                    });

                                // Update local state via PostListWidget
                                final postListState = _postListKey.currentState;
                                if (postListState != null) {
                                  postListState.setState(() {
                                    postListState._posts.insert(0, {
                                      "postNo": postId,
                                      ...postData,
                                    });
                                    postListState._postCache[postId] = postData;
                                  });
                                }

                                // Update shared preferences
                                final prefs =
                                    await SharedPreferences.getInstance();
                                final cachedPostsJson =
                                    prefs.getString("cached_posts") ?? "[]";
                                final cachedPosts =
                                    (jsonDecode(cachedPostsJson)
                                            as List<dynamic>)
                                        .cast<Map<String, dynamic>>();
                                cachedPosts.insert(0, {
                                  "postNo": postId,
                                  ...postData,
                                  "timestamp":
                                      DateTime.now().millisecondsSinceEpoch,
                                });
                                if (cachedPosts.length > 100) {
                                  cachedPosts.removeLast();
                                }
                                final updatedPostIds =
                                    cachedPosts
                                        .map((p) => p["postNo"] as String)
                                        .toList();
                                await prefs.setString(
                                  "cached_posts",
                                  jsonEncode(cachedPosts),
                                );
                                await prefs.setStringList(
                                  "cached_post_ids",
                                  updatedPostIds,
                                );

                                debugPrint("Post created successfully");
                                Navigator.pop(dialogContext);
                                _showSnackBar(
                                  "Post created successfully",
                                  key: "post_success",
                                );
                              } catch (e) {
                                debugPrint("Post creation failed: $e");
                                String errorMessage;
                                if (e.toString().contains(
                                  "Image file does not exist",
                                )) {
                                  errorMessage =
                                      "Selected image is invalid. Please try another.";
                                } else if (e.toString().contains(
                                  "exceeds 10MB limit",
                                )) {
                                  errorMessage =
                                      "Image size exceeds 10MB. Please reduce size.";
                                } else if (e.toString().contains(
                                  "Failed to upload image",
                                )) {
                                  errorMessage =
                                      "Failed to upload image. Check your connection.";
                                } else if (e.toString().contains(
                                  "Failed to write",
                                )) {
                                  errorMessage =
                                      "Failed to save post. Try again later.";
                                } else {
                                  errorMessage = "Failed to create post: $e";
                                }
                                _showSnackBar(errorMessage, key: "post_error");
                              } finally {
                                setState(() => isUploading = false);
                              }
                            },
                    child: const Text("Post"),
                  ),
                ],
              );
            },
          ),
    ).then((_) {
      setState(() {
        _isDialogOpen = false;
        debugPrint("Create post dialog closed, _isDialogOpen: $_isDialogOpen");
      });
    });
  }

  Future<String?> _uploadToCloudinary(File imageFile) async {
    const cloudName = "dnedosgc6";
    const uploadPreset = "ml_default";
    const maxRetries = 2;
    int attempt = 0;

    while (attempt <= maxRetries) {
      attempt++;
      debugPrint("Cloudinary upload attempt $attempt for ${imageFile.path}");

      try {
        final url = Uri.parse(
          "https://api.cloudinary.com/v1_1/$cloudName/image/upload",
        );
        final mimeTypeData = lookupMimeType(imageFile.path)?.split('/');
        final request =
            http.MultipartRequest('POST', url)
              ..fields['upload_preset'] = uploadPreset
              ..files.add(
                await http.MultipartFile.fromPath(
                  'file',
                  imageFile.path,
                  contentType:
                      mimeTypeData != null
                          ? MediaType(mimeTypeData[0], mimeTypeData[1])
                          : MediaType('image', 'jpeg'),
                ),
              );

        final response = await request.send().timeout(
          const Duration(seconds: 30),
        );
        final responseData = await http.Response.fromStream(response);

        if (response.statusCode == 200) {
          final jsonResponse =
              jsonDecode(responseData.body) as Map<String, dynamic>;
          final imageUrl = jsonResponse['secure_url'] as String?;
          if (imageUrl == null) {
            throw Exception("Cloudinary response missing secure_url");
          }
          return imageUrl;
        } else {
          debugPrint("Cloudinary error: ${responseData.body}");
          if (attempt >= maxRetries) {
            throw Exception("Cloudinary upload failed: ${responseData.body}");
          }
        }
      } catch (e) {
        debugPrint("Cloudinary upload error: $e");
        if (attempt >= maxRetries) {
          throw Exception("Upload error after $maxRetries attempts: $e");
        }
        await Future.delayed(const Duration(seconds: 2));
      }
    }
    return null;
  }

  Future<String> _generatePostId() async {
    const maxAttempts = 1000;
    int attempt = 0;
    final random = DateTime.now().millisecondsSinceEpoch.toString();

    debugPrint("Generating post ID starting from $random");

    while (attempt < maxAttempts) {
      final snapshot = await _postsRef.child(random).get();
      if (!snapshot.exists) {
        debugPrint("Post ID $random is available");
        return random;
      }
      attempt++;
    }
    throw Exception("No available post IDs after $maxAttempts attempts");
  }

  void _showSnackBar(String message, {required String key}) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        key: ValueKey(key),
        content: Text(message),
        duration: const Duration(seconds: 3),
        action: SnackBarAction(
          label: 'Dismiss',
          onPressed: () => ScaffoldMessenger.of(context).hideCurrentSnackBar(),
        ),
      ),
    );
  }

  Widget _buildCourseSkeleton() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: SizedBox(
        width: 180,
        child: Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(8),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 90,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                const SizedBox(height: 6),
                Container(height: 14, width: 100, color: Colors.white),
                const SizedBox(height: 4),
                Container(height: 10, width: 80, color: Colors.white),
                const SizedBox(height: 4),
                Container(height: 10, width: 50, color: Colors.white),
                const SizedBox(height: 6),
                Container(
                  height: 32,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeroSliderSkeleton() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: SizedBox(
        height: 180,
        child: Stack(
          alignment: Alignment.bottomCenter,
          children: [
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              color: Colors.white,
              width: double.infinity,
              height: 180,
            ),
            Positioned(
              bottom: 10,
              child: Row(
                children: List.generate(
                  5,
                  (index) => Container(
                    width: 8,
                    height: 8,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          debugPrint("FAB pressed, _isDialogOpen: $_isDialogOpen");
          if (!_isDialogOpen) {
            _createPost();
          } else {
            _showSnackBar(
              "Please close the open dialog first",
              key: "dialog_error",
            );
          }
        },
        backgroundColor: _isDialogOpen ? Colors.grey : Colors.blue.shade900,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      floatingActionButtonLocation: CustomFabLocation(),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.white, Colors.blue.shade100],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.only(top: 19),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _isLoading ? _buildHeroSliderSkeleton() : const HeroSlider(),
                  if (_categories.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(left: 15.0, top: 15),
                      child: Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children:
                            _categories
                                .map(
                                  (category) => StatefulBuilder(
                                    builder: (context, setState) {
                                      bool isTapped = false;
                                      return GestureDetector(
                                        onTapDown:
                                            (_) =>
                                                setState(() => isTapped = true),
                                        onTapUp:
                                            (_) => setState(
                                              () => isTapped = false,
                                            ),
                                        onTapCancel:
                                            () => setState(
                                              () => isTapped = false,
                                            ),
                                        onTap:
                                            () => _showCategoryCourses(
                                              context,
                                              category,
                                            ),
                                        child: AnimatedScale(
                                          scale: isTapped ? 0.90 : 1.0,
                                          duration: const Duration(
                                            milliseconds: 100,
                                          ),
                                          child: Container(
                                            decoration: BoxDecoration(
                                              boxShadow:
                                                  isTapped
                                                      ? [
                                                        BoxShadow(
                                                          color:
                                                              Colors
                                                                  .deepPurple
                                                                  .shade200,
                                                          blurRadius: 8,
                                                          offset: const Offset(
                                                            0,
                                                            4,
                                                          ),
                                                        ),
                                                      ]
                                                      : [],
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            width:
                                                (_categories.length % 2 == 1 &&
                                                        _categories.indexOf(
                                                              category,
                                                            ) ==
                                                            _categories.length -
                                                                1)
                                                    ? double.infinity
                                                    : (MediaQuery.of(
                                                              context,
                                                            ).size.width -
                                                            48) /
                                                        2,
                                            child: ActionChip(
                                              avatar: Icon(
                                                Icons.book,
                                                size: 18,
                                                color: const Color.fromARGB(
                                                  255,
                                                  15,
                                                  0,
                                                  232,
                                                ),
                                              ),
                                              label: Text(
                                                category,
                                                style: const TextStyle(
                                                  color: Color.fromARGB(
                                                    255,
                                                    0,
                                                    0,
                                                    0,
                                                  ),
                                                  fontSize: 16,
                                                  fontFamily: 'Georgia',
                                                ),
                                              ),
                                              backgroundColor:
                                                  isTapped
                                                      ? Colors
                                                          .deepPurple
                                                          .shade100
                                                      : Colors
                                                          .deepPurple
                                                          .shade50,
                                              elevation: isTapped ? 8 : 2,
                                              pressElevation: 12,
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                              onPressed:
                                                  () => _showCategoryCourses(
                                                    context,
                                                    category,
                                                  ),
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                )
                                .toList(),
                      ),
                    ),
                ]),
              ),
            ),
            if (_isLoading)
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 240,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: 3,
                    itemBuilder: (context, index) => _buildCourseSkeleton(),
                  ),
                ),
              )
            else if (_courses.isEmpty)
              SliverToBoxAdapter(
                child: Center(
                  child: Text(
                    "No courses available",
                    style: TextStyle(color: Colors.blue.shade900),
                  ),
                ),
              )
            else
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 240,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _courses.length,
                    itemBuilder: (context, index) {
                      final course = _courses[index];
                      bool isTapped = false;
                      return StatefulBuilder(
                        builder: (context, setState) {
                          return GestureDetector(
                            onTapDown: (_) => setState(() => isTapped = true),
                            onTapUp: (_) => setState(() => isTapped = false),
                            onTapCancel: () => setState(() => isTapped = false),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (context) => CourseContentPage(
                                        courseId: course["courseId"],
                                      ),
                                ),
                              );
                            },
                            child: AnimatedScale(
                              scale: isTapped ? 0.95 : 1.0,
                              duration: const Duration(milliseconds: 100),
                              child: SizedBox(
                                width: 180,
                                child: Card(
                                  key: ValueKey(course["courseId"]),
                                  elevation: 4,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  margin: const EdgeInsets.all(8),
                                  child: Padding(
                                    padding: const EdgeInsets.all(8),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          child: CachedNetworkImage(
                                            imageUrl: course["imageUrl"],
                                            height: 90,
                                            width: double.infinity,
                                            fit: BoxFit.cover,
                                            placeholder:
                                                (context, url) => Container(
                                                  color: Colors.grey[200],
                                                  child: const Center(
                                                    child:
                                                        CircularProgressIndicator(),
                                                  ),
                                                ),
                                            errorWidget:
                                                (context, url, error) =>
                                                    Image.asset(
                                                      'assets/placeholder.png',
                                                      height: 90,
                                                      width: double.infinity,
                                                      fit: BoxFit.cover,
                                                    ),
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          _formatCourseTitle(course["title"]),
                                          style: Theme.of(
                                            context,
                                          ).textTheme.titleSmall?.copyWith(
                                            color: Colors.blue.shade900,
                                            fontSize: 12,
                                            fontFamily: 'RobotoMono',
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.timer,
                                              size: 12,
                                              color: Colors.blue.shade700,
                                            ),
                                            const SizedBox(width: 4),
                                            Expanded(
                                              child: Text(
                                                "${course["duration"]} Days",
                                                style: TextStyle(
                                                  color: Colors.blue.shade700,
                                                  fontSize: 10,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          "₹${course["price"]}",
                                          style: TextStyle(
                                            color: Colors.green.shade700,
                                            fontSize: 10,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        _buildEnrollButton(
                                          course["courseId"],
                                          course["price"],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ),
            const SliverToBoxAdapter(
              child: Text(
                "  Community Posts",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                  color: Color.fromARGB(255, 13, 71, 161),
                ),
              ),
            ),
            PostListWidget(
              key: _postListKey,
              setDialogOpen:
                  (value) => setState(() {
                    debugPrint("setDialogOpen called with: $value");
                    _isDialogOpen = value;
                  }),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 98)),
          ],
        ),
      ),
    );
  }

  void _showCategoryCourses(BuildContext context, String category) {
    final filteredCourses =
        _courses.where((c) => c["category"] == category).toList();

    setState(() {
      _isDialogOpen = true;
      debugPrint("Opening category dialog, _isDialogOpen: $_isDialogOpen");
    });

    showDialog(
      context: context,
      builder:
          (context) => Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.white, Colors.blue.shade50],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    category,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade900,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Flexible(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 240),
                      child:
                          filteredCourses.isEmpty
                              ? Center(
                                child: Text(
                                  "No courses in this category",
                                  style: TextStyle(color: Colors.blue.shade900),
                                ),
                              )
                              : ListView.builder(
                                scrollDirection: Axis.horizontal,
                                itemCount: filteredCourses.length,
                                itemBuilder: (context, index) {
                                  final course = filteredCourses[index];
                                  bool isTapped = false;
                                  return StatefulBuilder(
                                    builder: (context, setState) {
                                      return GestureDetector(
                                        onTapDown:
                                            (_) =>
                                                setState(() => isTapped = true),
                                        onTapUp:
                                            (_) => setState(
                                              () => isTapped = false,
                                            ),
                                        onTapCancel:
                                            () => setState(
                                              () => isTapped = false,
                                            ),
                                        onTap: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder:
                                                  (context) =>
                                                      CourseContentPage(
                                                        courseId:
                                                            course["courseId"],
                                                      ),
                                            ),
                                          );
                                        },
                                        child: AnimatedScale(
                                          scale: isTapped ? 0.95 : 1.0,
                                          duration: const Duration(
                                            milliseconds: 100,
                                          ),
                                          child: SizedBox(
                                            width: 180,
                                            child: Card(
                                              elevation: 4,
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                              margin: const EdgeInsets.all(8),
                                              child: Padding(
                                                padding: const EdgeInsets.all(
                                                  8,
                                                ),
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    ClipRRect(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            8,
                                                          ),
                                                      child: CachedNetworkImage(
                                                        imageUrl:
                                                            course["imageUrl"],
                                                        height: 90,
                                                        width: double.infinity,
                                                        fit: BoxFit.cover,
                                                        placeholder:
                                                            (
                                                              context,
                                                              url,
                                                            ) => Container(
                                                              color:
                                                                  Colors
                                                                      .grey[200],
                                                              child: const Center(
                                                                child:
                                                                    CircularProgressIndicator(),
                                                              ),
                                                            ),
                                                        errorWidget:
                                                            (
                                                              context,
                                                              url,
                                                              error,
                                                            ) => Image.asset(
                                                              'assets/placeholder.png',
                                                              height: 90,
                                                              width:
                                                                  double
                                                                      .infinity,
                                                              fit: BoxFit.cover,
                                                            ),
                                                      ),
                                                    ),
                                                    const SizedBox(height: 6),
                                                    Text(
                                                      _formatCourseTitle(
                                                        course["title"],
                                                      ),
                                                      style: Theme.of(context)
                                                          .textTheme
                                                          .titleSmall
                                                          ?.copyWith(
                                                            color:
                                                                Colors
                                                                    .blue
                                                                    .shade900,
                                                            fontSize: 12,
                                                            fontFamily:
                                                                'RobotoMono',
                                                          ),
                                                      maxLines: 2,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                    ),
                                                    const SizedBox(height: 4),
                                                    Row(
                                                      children: [
                                                        Icon(
                                                          Icons.timer,
                                                          size: 12,
                                                          color:
                                                              Colors
                                                                  .blue
                                                                  .shade700,
                                                        ),
                                                        const SizedBox(
                                                          width: 4,
                                                        ),
                                                        Expanded(
                                                          child: Text(
                                                            "${course["duration"]} Days",
                                                            style: TextStyle(
                                                              color:
                                                                  Colors
                                                                      .blue
                                                                      .shade700,
                                                              fontSize: 10,
                                                            ),
                                                            overflow:
                                                                TextOverflow
                                                                    .ellipsis,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                    const SizedBox(height: 4),
                                                    Text(
                                                      "₹${course["price"]}",
                                                      style: TextStyle(
                                                        color:
                                                            Colors
                                                                .green
                                                                .shade700,
                                                        fontSize: 10,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 6),
                                                    _buildEnrollButton(
                                                      course["courseId"],
                                                      course["price"],
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  );
                                },
                              ),
                    ),
                  ),
                ],
              ),
            ),
          ),
    ).then(
      (_) => setState(() {
        _isDialogOpen = false;
        debugPrint("Category dialog closed, _isDialogOpen: $_isDialogOpen");
      }),
    );
  }
}

class DataSnapshotMock implements DataSnapshot {
  @override
  final dynamic value;
  @override
  final String key;

  DataSnapshotMock({required this.value, required this.key});

  @override
  dynamic get priority => null;

  @override
  DatabaseReference get ref => throw UnimplementedError();

  @override
  bool get exists => value != null;

  @override
  DataSnapshot child(String path) => throw UnimplementedError();

  @override
  Iterable<DataSnapshot> get children => throw UnimplementedError();

  @override
  bool hasChild(String path) => throw UnimplementedError();
}

class PostListWidget extends StatefulWidget {
  final Function(bool) setDialogOpen;

  const PostListWidget({super.key, required this.setDialogOpen});

  @override
  State<PostListWidget> createState() => _PostListWidgetState();
}

class _PostListWidgetState extends State<PostListWidget> {
  final DatabaseReference _postsRef = FirebaseDatabase.instance.ref("posts");
  final DatabaseReference _usersPostsRef = FirebaseDatabase.instance.ref(
    "users_posts",
  );
  final DatabaseReference _userRef = FirebaseDatabase.instance.ref("users");
  List<Map<String, dynamic>> _posts = [];
  bool _isPostsLoading = true;
  StreamSubscription<DatabaseEvent>? _postsSubscription;
  final Map<String, Map<String, dynamic>> _postCache = {};
  final Map<String, String?> _profileImageCache = {};
  bool _isDialogOpen = false;

  @override
  void initState() {
    super.initState();
    _setupRealtimePostsListener();
  }

  @override
  void dispose() {
    _postsSubscription?.cancel();
    super.dispose();
  }

  void _setupRealtimePostsListener() {
    _postsSubscription = _postsRef.onValue.listen(
      (event) async {
        final prefs = await SharedPreferences.getInstance();
        final cachedPostsJson = prefs.getString("cached_posts") ?? "[]";
        List<Map<String, dynamic>> newPosts = [];

        if (event.snapshot.value == null) {
          setState(() {
            _posts = [];
            _isPostsLoading = false;
          });
          await prefs.setString("cached_posts", "[]");
          await prefs.setStringList("cached_post_ids", []);
          return;
        }

        try {
          Map<String, dynamic> values;
          if (event.snapshot.value is Map) {
            values = Map<String, dynamic>.from(event.snapshot.value as Map);
          } else if (event.snapshot.value is List) {
            List<dynamic> list = event.snapshot.value as List<dynamic>;
            values = {};
            for (int i = 0; i < list.length; i++) {
              if (list[i] != null) {
                values[i.toString()] = list[i];
              }
            }
          } else {
            throw Exception(
              "Unexpected data type: ${event.snapshot.value.runtimeType}",
            );
          }

          values.forEach((key, value) {
            try {
              final postData =
                  jsonDecode(value as String) as Map<String, dynamic>;
              postData["timestamp"] =
                  postData["timestamp"] is int
                      ? postData["timestamp"]
                      : DateTime.now().millisecondsSinceEpoch;
              _postCache[key] = postData;
              newPosts.add({"postNo": key, ...postData});
            } catch (e) {
              print("Error parsing post $key: $e");
            }
          });

          // Sort posts by timestamp in descending order (LIFO)
          newPosts.sort(
            (a, b) => (b["timestamp"] as int).compareTo(a["timestamp"]),
          );

          // Limit to 100 posts
          if (newPosts.length > 100) {
            newPosts = newPosts.sublist(0, 100);
          }

          final updatedPostIds =
              newPosts.map((p) => p["postNo"] as String).toList();

          // Save sorted posts in cache
          await prefs.setString("cached_posts", jsonEncode(newPosts));
          await prefs.setStringList("cached_post_ids", updatedPostIds);

          setState(() {
            _posts = newPosts;
            _isPostsLoading = false;
          });
        } catch (e) {
          try {
            final cachedPosts =
                (jsonDecode(cachedPostsJson) as List<dynamic>)
                    .cast<Map<String, dynamic>>();
            // Sort cached posts by timestamp
            cachedPosts.sort(
              (a, b) => (b["timestamp"] as int).compareTo(a["timestamp"]),
            );
            setState(() {
              _posts = cachedPosts;
              _isPostsLoading = false;
            });
          } catch (cacheError) {
            setState(() {
              _posts = [];
              _isPostsLoading = false;
            });
          }
          _showSnackBar(
            context,
            "Failed to fetch posts: $e",
            key: "posts_error",
          );
        }
      },
      onError: (error) {
        SharedPreferences.getInstance().then((prefs) {
          final cachedPostsJson = prefs.getString("cached_posts") ?? "[]";
          try {
            final cachedPosts =
                (jsonDecode(cachedPostsJson) as List<dynamic>)
                    .cast<Map<String, dynamic>>();
            // Sort cached posts by timestamp
            cachedPosts.sort(
              (a, b) => (b["timestamp"] as int).compareTo(a["timestamp"]),
            );
            setState(() {
              _posts = cachedPosts;
              _isPostsLoading = false;
            });
          } catch (e) {
            setState(() {
              _posts = [];
              _isPostsLoading = false;
            });
          }
        });
        _showSnackBar(
          context,
          "Failed to fetch posts: $error",
          key: "posts_error",
        );
      },
    );
  }

  void _toggleLike(String postId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _showSnackBar(context, "Please log in to like a post", key: "auth_error");
      return;
    }

    try {
      final postRef = _postsRef.child(postId);
      final snapshot = await postRef.get();
      if (!snapshot.exists) {
        _showSnackBar(context, "Post no longer exists", key: "like_error");
        return;
      }

      final postData =
          jsonDecode(snapshot.value as String) as Map<String, dynamic>;
      final likes = Map<String, dynamic>.from(postData["likes"] ?? {});

      bool wasLiked = likes[user.uid] == true;
      if (wasLiked) {
        likes.remove(user.uid);
        postData["likeCount"] = (postData["likeCount"] as int? ?? 0) - 1;
      } else {
        likes[user.uid] = true;
        postData["likeCount"] = (postData["likeCount"] as int? ?? 0) + 1;
      }

      postData["likes"] = likes;
      // Do NOT update timestamp to prevent reordering

      await postRef.set(jsonEncode(postData));

      // Update local state without changing order
      setState(() {
        final postIndex = _posts.indexWhere((p) => p["postNo"] == postId);
        if (postIndex != -1) {
          _posts[postIndex] = {"postNo": postId, ...postData};
          _postCache[postId] = postData;
        }
      });

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString("cached_posts", jsonEncode(_posts));
    } catch (e) {
      _showSnackBar(context, "Failed to toggle like: $e", key: "like_error");
    }
  }

  void _showComments(String postId, String username) {
    TextEditingController commentController = TextEditingController();
    bool isSubmitting = false;

    setState(() {
      _isDialogOpen = true;
      widget.setDialogOpen(true);
      debugPrint("Opening comments dialog, _isDialogOpen: $_isDialogOpen");
    });

    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (dialogContext) => StatefulBuilder(
            builder: (dialogContext, setState) {
              return Dialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  constraints: const BoxConstraints(maxHeight: 500),
                  child: StreamBuilder<DatabaseEvent>(
                    stream: _postsRef.child(postId).onValue,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (!snapshot.hasData ||
                          snapshot.data!.snapshot.value == null) {
                        return const Center(child: Text("No comments yet"));
                      }

                      final postData =
                          jsonDecode(snapshot.data!.snapshot.value as String)
                              as Map<String, dynamic>;
                      final comments = Map<String, dynamic>.from(
                        postData["comments"] ?? {},
                      );

                      List<Map<String, dynamic>> commentList =
                          comments.entries.map((e) {
                            return {
                              "commentId": e.key,
                              "username": e.value["username"] ?? "anonymous",
                              "text": e.value["text"] ?? "",
                              "timestamp":
                                  e.value["timestamp"] is int
                                      ? e.value["timestamp"]
                                      : DateTime.now().millisecondsSinceEpoch,
                            };
                          }).toList();

                      // Sort comments by timestamp (oldest first)
                      commentList.sort(
                        (a, b) =>
                            (a["timestamp"] as int).compareTo(b["timestamp"]),
                      );

                      return Column(
                        children: [
                          const Text(
                            "Comments",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Expanded(
                            child: ListView.builder(
                              itemCount: commentList.length,
                              itemBuilder: (context, index) {
                                final comment = commentList[index];
                                return Card(
                                  margin: const EdgeInsets.symmetric(
                                    vertical: 4,
                                  ),
                                  elevation: 1,
                                  child: Padding(
                                    padding: const EdgeInsets.all(8),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            CircleAvatar(
                                              radius: 16,
                                              backgroundColor:
                                                  Colors.blue.shade100,
                                              child: Text(
                                                comment["username"][0]
                                                    .toUpperCase(),
                                                style: TextStyle(
                                                  color: Colors.blue.shade900,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                comment["username"],
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 14,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          comment["text"],
                                          style: const TextStyle(fontSize: 14),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: commentController,
                            decoration: const InputDecoration(
                              labelText: "Add a comment",
                              border: OutlineInputBorder(),
                            ),
                            maxLines: 2,
                            enabled: !isSubmitting,
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              TextButton(
                                onPressed: () {
                                  Navigator.pop(dialogContext);
                                  this.setState(() {
                                    _isDialogOpen = false;
                                    widget.setDialogOpen(false);
                                    debugPrint(
                                      "Comments dialog closed, _isDialogOpen: $_isDialogOpen",
                                    );
                                  });
                                },
                                child: const Text("Close"),
                              ),
                              ElevatedButton(
                                onPressed:
                                    isSubmitting
                                        ? null
                                        : () async {
                                          if (commentController.text.isEmpty) {
                                            _showSnackBar(
                                              dialogContext,
                                              "Comment cannot be empty",
                                              key: "comment_error",
                                            );
                                            return;
                                          }

                                          final user =
                                              FirebaseAuth.instance.currentUser;
                                          if (user == null) {
                                            _showSnackBar(
                                              dialogContext,
                                              "Please log in to comment",
                                              key: "auth_error",
                                            );
                                            return;
                                          }

                                          setState(() => isSubmitting = true);

                                          try {
                                            final postRef = _postsRef.child(
                                              postId,
                                            );
                                            final snapshot =
                                                await postRef.get();
                                            if (!snapshot.exists) {
                                              _showSnackBar(
                                                dialogContext,
                                                "Post no longer exists",
                                                key: "comment_error",
                                              );
                                              return;
                                            }

                                            final postData =
                                                jsonDecode(
                                                      snapshot.value as String,
                                                    )
                                                    as Map<String, dynamic>;
                                            final comments =
                                                Map<String, dynamic>.from(
                                                  postData["comments"] ?? {},
                                                );

                                            final commentId =
                                                DateTime.now()
                                                    .millisecondsSinceEpoch
                                                    .toString();
                                            comments[commentId] = {
                                              "text": commentController.text,
                                              "username":
                                                  user.email?.split('@')[0] ??
                                                  "anonymous",
                                              "timestamp":
                                                  ServerValue.timestamp,
                                            };

                                            postData["comments"] = comments;
                                            // Do NOT update timestamp to prevent reordering

                                            await postRef.set(
                                              jsonEncode(postData),
                                            );

                                            // Update local state without changing order
                                            final postIndex = _posts.indexWhere(
                                              (p) => p["postNo"] == postId,
                                            );
                                            if (postIndex != -1) {
                                              _posts[postIndex] = {
                                                "postNo": postId,
                                                ...postData,
                                              };
                                              _postCache[postId] = postData;
                                            }

                                            final prefs =
                                                await SharedPreferences.getInstance();
                                            await prefs.setString(
                                              "cached_posts",
                                              jsonEncode(_posts),
                                            );

                                            commentController.clear();
                                            setState(() {});
                                          } catch (e) {
                                            _showSnackBar(
                                              dialogContext,
                                              "Failed to add comment: $e",
                                              key: "comment_error",
                                            );
                                          } finally {
                                            setState(
                                              () => isSubmitting = false,
                                            );
                                          }
                                        },
                                child:
                                    isSubmitting
                                        ? const CircularProgressIndicator()
                                        : const Text("Submit"),
                              ),
                            ],
                          ),
                        ],
                      );
                    },
                  ),
                ),
              );
            },
          ),
    ).then((_) {
      setState(() {
        _isDialogOpen = false;
        widget.setDialogOpen(false);
        debugPrint(
          "Comments dialog closed via then, _isDialogOpen: $_isDialogOpen",
        );
      });
    });
  }

  Future<File?> _downloadImage(String imageUrl) async {
    try {
      final response = await http
          .get(Uri.parse(imageUrl))
          .timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final tempDir = await getTemporaryDirectory();
        final file = File(
          '${tempDir.path}/post_image_${DateTime.now().millisecondsSinceEpoch}.jpg',
        );
        await file.writeAsBytes(response.bodyBytes);
        return file;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  void _sharePost(
    String postId,
    String username,
    String link,
    String description,
    List<String> imageUrls,
  ) async {
    try {
      final postRef = _postsRef.child(postId);
      final snapshot = await postRef.get();
      if (!snapshot.exists) {
        _showSnackBar(context, "Post no longer exists", key: "share_error");
        return;
      }

      final postData =
          jsonDecode(snapshot.value as String) as Map<String, dynamic>;
      postData["shareCount"] = (postData["shareCount"] as int? ?? 0) + 1;
      // Do NOT update timestamp to prevent reordering

      await postRef.set(jsonEncode(postData));

      // Update local state without changing order
      setState(() {
        final postIndex = _posts.indexWhere((p) => p["postNo"] == postId);
        if (postIndex != -1) {
          _posts[postIndex] = {"postNo": postId, ...postData};
          _postCache[postId] = postData;
        }
      });

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString("cached_posts", jsonEncode(_posts));

      final shareText =
          description.isNotEmpty
              ? link.isNotEmpty
                  ? "$description\nCheck out this post: $link"
                  : description
              : link.isNotEmpty
              ? "Check out this post: $link"
              : "Check out this post by $username!";

      if (imageUrls.isNotEmpty) {
        final imageFile = await _downloadImage(imageUrls[0]);
        if (imageFile != null) {
          await Share.shareXFiles([XFile(imageFile.path)], text: shareText);
          await imageFile.delete();
        } else {
          await Share.share(shareText);
          _showSnackBar(
            context,
            "Failed to download image, sharing text only",
            key: "share_error",
          );
        }
      } else {
        await Share.share(shareText);
      }
    } catch (e) {
      _showSnackBar(context, "Failed to share post: $e", key: "share_error");
    }
  }

  void _showSnackBar(
    BuildContext context,
    String message, {
    required String key,
  }) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        key: ValueKey(key),
        content: Text(message),
        duration: const Duration(seconds: 3),
        action: SnackBarAction(
          label: 'Dismiss',
          onPressed: () => ScaffoldMessenger.of(context).hideCurrentSnackBar(),
        ),
      ),
    );
  }

  Widget _buildPostSkeleton() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(width: 100, height: 14, color: Colors.white),
                  const Spacer(),
                  Container(width: 80, height: 12, color: Colors.white),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                height: 300,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              const SizedBox(height: 8),
              Container(height: 14, width: 150, color: Colors.white),
              const SizedBox(height: 4),
              Container(
                height: 10,
                width: double.infinity,
                color: Colors.white,
              ),
              const SizedBox(height: 4),
              Container(
                height: 10,
                width: double.infinity,
                color: Colors.white,
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(width: 60, height: 10, color: Colors.white),
                  Container(width: 60, height: 10, color: Colors.white),
                  Container(width: 60, height: 10, color: Colors.white),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showImageGallery(
    BuildContext context,
    List<String> imageUrls,
    int initialIndex,
  ) {
    setState(() {
      _isDialogOpen = true;
      widget.setDialogOpen(true);
      debugPrint("Opening image gallery, _isDialogOpen: $_isDialogOpen");
    });
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => Scaffold(
              appBar: AppBar(
                backgroundColor: Colors.black,
                leading: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () {
                    Navigator.pop(context);
                    setState(() {
                      _isDialogOpen = false;
                      widget.setDialogOpen(false);
                      debugPrint(
                        "Image gallery closed, _isDialogOpen: $_isDialogOpen",
                      );
                    });
                  },
                ),
              ),
              body: PhotoViewGallery.builder(
                itemCount: imageUrls.length,
                builder: (context, index) {
                  return PhotoViewGalleryPageOptions(
                    imageProvider: NetworkImage(imageUrls[index]),
                    minScale: PhotoViewComputedScale.contained,
                    maxScale: PhotoViewComputedScale.covered * 2,
                  );
                },
                scrollPhysics: const BouncingScrollPhysics(),
                backgroundDecoration: const BoxDecoration(color: Colors.black),
                pageController: PageController(initialPage: initialIndex),
              ),
            ),
      ),
    ).then((_) {
      setState(() {
        _isDialogOpen = false;
        widget.setDialogOpen(false);
        debugPrint(
          "Image gallery closed via then, _isDialogOpen: $_isDialogOpen",
        );
      });
    });
  }

  Widget _buildPostCard(Map<String, dynamic> post) {
    final postId = post["postNo"] as String? ?? "";
    final userId = post["user_id"] as String? ?? "";
    final username = post["username"] as String? ?? "anonymous";
    final imageUrls = List<String>.from(post["imageUrls"] ?? []);
    final title = post["title"] as String? ?? "";
    final description = post["description"] as String? ?? "";
    final link = post["link"] as String? ?? "";
    final likeCount = post["likeCount"] as int? ?? 0;
    final comments = Map<String, dynamic>.from(post["comments"] ?? {});
    final shareCount = post["shareCount"] as int? ?? 0;

    Widget buildImageCollage() {
      if (imageUrls.isEmpty) {
        return const SizedBox.shrink();
      }

      return LayoutBuilder(
        builder: (context, constraints) {
          final maxWidth = constraints.maxWidth;
          const gap = 4.0;

          if (imageUrls.length == 1) {
            return GestureDetector(
              onTap: () => _showImageGallery(context, imageUrls, 0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 400),
                  child: SizedBox(
                    width: maxWidth,
                    child: AspectRatio(
                      aspectRatio: 16 / 9,
                      child: CachedNetworkImage(
                        imageUrl: imageUrls[0],
                        fit: BoxFit.cover,
                        placeholder:
                            (context, url) => Shimmer.fromColors(
                              baseColor: Colors.grey[300]!,
                              highlightColor: Colors.grey[100]!,
                              child: Container(color: Colors.grey[200]),
                            ),
                        errorWidget:
                            (context, url, error) => Container(
                              color: Colors.grey[200],
                              child: const Icon(Icons.error, color: Colors.red),
                            ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          } else if (imageUrls.length == 2) {
            return Row(
              children:
                  imageUrls.asMap().entries.map((entry) {
                    final index = entry.key;
                    final url = entry.value;
                    return Expanded(
                      child: GestureDetector(
                        onTap:
                            () => _showImageGallery(context, imageUrls, index),
                        child: Padding(
                          padding: EdgeInsets.only(
                            left: index == 0 ? 0 : gap / 2,
                            right: index == 1 ? 0 : gap / 2,
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: AspectRatio(
                              aspectRatio: 4 / 3,
                              child: CachedNetworkImage(
                                imageUrl: url,
                                fit: BoxFit.cover,
                                placeholder:
                                    (context, url) => Shimmer.fromColors(
                                      baseColor: Colors.grey[300]!,
                                      highlightColor: Colors.grey[100]!,
                                      child: Container(color: Colors.grey[200]),
                                    ),
                                errorWidget:
                                    (context, url, error) => Container(
                                      color: Colors.grey[200],
                                      child: const Icon(
                                        Icons.error,
                                        color: Colors.red,
                                      ),
                                    ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
            );
          } else if (imageUrls.length == 3) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 2,
                  child: GestureDetector(
                    onTap: () => _showImageGallery(context, imageUrls, 0),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: AspectRatio(
                        aspectRatio: 4 / 3,
                        child: CachedNetworkImage(
                          imageUrl: imageUrls[0],
                          fit: BoxFit.cover,
                          placeholder:
                              (context, url) => Shimmer.fromColors(
                                baseColor: Colors.grey[300]!,
                                highlightColor: Colors.grey[100]!,
                                child: Container(color: Colors.grey[200]),
                              ),
                          errorWidget:
                              (context, url, error) => Container(
                                color: Colors.grey[200],
                                child: const Icon(
                                  Icons.error,
                                  color: Colors.red,
                                ),
                              ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: gap),
                Expanded(
                  flex: 1,
                  child: Column(
                    children: [
                      GestureDetector(
                        onTap: () => _showImageGallery(context, imageUrls, 1),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: AspectRatio(
                            aspectRatio: 4 / 3,
                            child: CachedNetworkImage(
                              imageUrl: imageUrls[1],
                              fit: BoxFit.cover,
                              placeholder:
                                  (context, url) => Shimmer.fromColors(
                                    baseColor: Colors.grey[300]!,
                                    highlightColor: Colors.grey[100]!,
                                    child: Container(color: Colors.grey[200]),
                                  ),
                              errorWidget:
                                  (context, url, error) => Container(
                                    color: Colors.grey[200],
                                    child: const Icon(
                                      Icons.error,
                                      color: Colors.red,
                                    ),
                                  ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: gap),
                      GestureDetector(
                        onTap: () => _showImageGallery(context, imageUrls, 2),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: AspectRatio(
                            aspectRatio: 4 / 3,
                            child: CachedNetworkImage(
                              imageUrl: imageUrls[2],
                              fit: BoxFit.cover,
                              placeholder:
                                  (context, url) => Shimmer.fromColors(
                                    baseColor: Colors.grey[300]!,
                                    highlightColor: Colors.grey[100]!,
                                    child: Container(color: Colors.grey[200]),
                                  ),
                              errorWidget:
                                  (context, url, error) => Container(
                                    color: Colors.grey[200],
                                    child: const Icon(
                                      Icons.error,
                                      color: Colors.red,
                                    ),
                                  ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          } else {
            final displayCount = imageUrls.length > 4 ? 4 : imageUrls.length;
            return GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: gap,
              mainAxisSpacing: gap,
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              childAspectRatio: 4 / 3,
              children: List.generate(displayCount, (index) {
                if (index == 3 && imageUrls.length > 4) {
                  return GestureDetector(
                    onTap: () => _showImageGallery(context, imageUrls, index),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          CachedNetworkImage(
                            imageUrl: imageUrls[index],
                            fit: BoxFit.cover,
                            placeholder:
                                (context, url) => Shimmer.fromColors(
                                  baseColor: Colors.grey[300]!,
                                  highlightColor: Colors.grey[100]!,
                                  child: Container(color: Colors.grey[200]),
                                ),
                            errorWidget:
                                (context, url, error) => Container(
                                  color: Colors.grey[200],
                                  child: const Icon(
                                    Icons.error,
                                    color: Colors.red,
                                  ),
                                ),
                          ),
                          Container(
                            color: Colors.black.withOpacity(0.4),
                            child: Center(
                              child: Text(
                                "+${imageUrls.length - 4}",
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }
                return GestureDetector(
                  onTap: () => _showImageGallery(context, imageUrls, index),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: CachedNetworkImage(
                      imageUrl: imageUrls[index],
                      fit: BoxFit.cover,
                      placeholder:
                          (context, url) => Shimmer.fromColors(
                            baseColor: Colors.grey[300]!,
                            highlightColor: Colors.grey[100]!,
                            child: Container(color: Colors.grey[200]),
                          ),
                      errorWidget:
                          (context, url, error) => Container(
                            color: Colors.grey[200],
                            child: const Icon(Icons.error, color: Colors.red),
                          ),
                    ),
                  ),
                );
              }),
            );
          }
        },
      );
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                FutureBuilder<String?>(
                  future:
                      _profileImageCache.containsKey(userId)
                          ? Future.value(_profileImageCache[userId])
                          : _userRef
                              .child(userId)
                              .child("profileImage")
                              .get()
                              .then((snapshot) {
                                final imageUrl = snapshot.value as String?;
                                _profileImageCache[userId] = imageUrl;
                                return imageUrl;
                              })
                              .catchError((e) {
                                _profileImageCache[userId] = null;
                                return null;
                              }),
                  builder: (context, snapshot) {
                    return CircleAvatar(
                      radius: 20,
                      backgroundColor: Colors.blue.shade100,
                      backgroundImage:
                          snapshot.hasData && snapshot.data != null
                              ? CachedNetworkImageProvider(snapshot.data!)
                              : null,
                      child:
                          snapshot.hasData && snapshot.data == null
                              ? Text(
                                username.isNotEmpty
                                    ? username[0].toUpperCase()
                                    : "?",
                                style: TextStyle(
                                  color: Colors.blue.shade900,
                                  fontWeight: FontWeight.bold,
                                ),
                              )
                              : null,
                    );
                  },
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    username,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade900,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            buildImageCollage(),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.blue.shade900,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              description,
              style: TextStyle(color: Colors.blue.shade700, fontSize: 14),
            ),
            if (link.isNotEmpty) ...[
              const SizedBox(height: 4),
              InkWell(
                onTap: () async {
                  final url = Uri.parse(link);
                  if (await canLaunchUrl(url)) {
                    await launchUrl(url);
                  } else {
                    _showSnackBar(
                      context,
                      "Cannot open link",
                      key: "link_error",
                    );
                  }
                },
                child: Text(
                  link,
                  style: const TextStyle(
                    color: Colors.blue,
                    decoration: TextDecoration.underline,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 8),
            const Divider(),
            StreamBuilder<DatabaseEvent>(
              stream: _postsRef.child(postId).onValue,
              builder: (context, snapshot) {
                bool isLiked = false;
                int currentLikeCount = likeCount;
                int currentCommentCount = comments.length;
                int currentShareCount = shareCount;

                if (snapshot.hasData && snapshot.data!.snapshot.value != null) {
                  try {
                    final postData =
                        jsonDecode(snapshot.data!.snapshot.value as String)
                            as Map<String, dynamic>;
                    final likes = Map<String, dynamic>.from(
                      postData["likes"] ?? {},
                    );
                    isLiked =
                        likes[FirebaseAuth.instance.currentUser?.uid ?? ""] ==
                        true;
                    currentLikeCount = postData["likeCount"] as int? ?? 0;
                    currentCommentCount =
                        (postData["comments"] as Map<dynamic, dynamic>?)
                            ?.length ??
                        0;
                    currentShareCount = postData["shareCount"] as int? ?? 0;
                  } catch (e) {
                    print("Error parsing post data in StreamBuilder: $e");
                  }
                }

                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton.icon(
                      onPressed: () => _toggleLike(postId),
                      icon: Icon(
                        isLiked ? Icons.favorite : Icons.favorite_border,
                        color: isLiked ? Colors.red : Colors.grey,
                        size: 20,
                      ),
                      label: Text(
                        "$currentLikeCount Likes",
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () => _showComments(postId, username),
                      icon: const Icon(
                        Icons.comment,
                        color: Colors.grey,
                        size: 20,
                      ),
                      label: Text(
                        "$currentCommentCount Comments",
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    TextButton.icon(
                      onPressed:
                          () => _sharePost(
                            postId,
                            username,
                            link,
                            description,
                            imageUrls,
                          ),
                      icon: const Icon(
                        Icons.share,
                        color: Colors.grey,
                        size: 20,
                      ),
                      label: Text(
                        "$currentShareCount Shares",
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isPostsLoading) {
      return SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) => _buildPostSkeleton(),
          childCount: 3,
        ),
      );
    } else if (_posts.isEmpty) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            "No posts available",
            style: TextStyle(color: Colors.blue.shade900),
          ),
        ),
      );
    } else {
      return SliverList(
        delegate: SliverChildBuilderDelegate((context, index) {
          try {
            return _buildPostCard(_posts[index]);
          } catch (e) {
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                "Error loading post: $e",
                style: TextStyle(color: Colors.red.shade700),
              ),
            );
          }
        }, childCount: _posts.length),
      );
    }
  }
}
