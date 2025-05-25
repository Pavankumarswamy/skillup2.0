// import 'dart:convert';
// import 'dart:io';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:firebase_database/firebase_database.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:youtube_player_flutter/youtube_player_flutter.dart';
// import 'package:flutter_html/flutter_html.dart';
// import 'package:flutter_highlight/flutter_highlight.dart';
// import 'package:flutter_highlight/themes/monokai-sublime.dart';
// import 'package:google_sign_in/google_sign_in.dart';
// import 'package:file_picker/file_picker.dart';
// import 'package:http/http.dart' as http;
// import 'package:permission_handler/permission_handler.dart';
// import 'package:device_info_plus/device_info_plus.dart';
// import 'package:video_player/video_player.dart';
// import 'package:confetti/confetti.dart';
// import 'package:cloudinary_public/cloudinary_public.dart';

// class AppendContentModulePage1 extends StatefulWidget {
//   final String courseId;
//   final int moduleIndex;
//   final String moduleName;

//   const AppendContentModulePage1({
//     super.key,
//     required this.courseId,
//     required this.moduleIndex,
//     required this.moduleName,
//   });

//   @override
//   _AppendContentModulePageState createState() =>
//       _AppendContentModulePageState();
// }

// class _AppendContentModulePageState extends State<AppendContentModulePage1>
//     with SingleTickerProviderStateMixin {
//   TextEditingController contentController = TextEditingController();
//   TextEditingController titleController = TextEditingController(
//     text: 'Uploaded Video',
//   );
//   TextEditingController descriptionController = TextEditingController(
//     text: 'Uploaded via Flutter app',
//   );
//   String selectedType = 'html';
//   String currentContent = '';
//   bool isPopupVisible = false;
//   File? _mediaFile;
//   VideoPlayerController? _videoController;
//   String? _uploadStatus;
//   double? _uploadProgress;
//   final _formKey = GlobalKey<FormState>();
//   final _confettiController = ConfettiController(
//     duration: const Duration(seconds: 3),
//   );
//   late AnimationController _buttonAnimationController;
//   late Animation<double> _buttonScaleAnimation;

//   final GoogleSignIn _googleSignIn = GoogleSignIn(
//     serverClientId:
//         '894403809910-54q1iesdkppkg3f2m438bsb01dp8p0fa.apps.googleusercontent.com',
//     scopes: ['https://www.googleapis.com/auth/youtube.upload'],
//   );

//   final cloudinary = CloudinaryPublic('dnedosgc6', 'ml_default', cache: false);

//   @override
//   void initState() {
//     super.initState();
//     _fetchModuleContent();
//     _buttonAnimationController = AnimationController(
//       vsync: this,
//       duration: const Duration(milliseconds: 100),
//     );
//     _buttonScaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
//       CurvedAnimation(
//         parent: _buttonAnimationController,
//         curve: Curves.easeInOut,
//       ),
//     );
//   }

//   void _fetchModuleContent() async {
//     DatabaseReference contentRef = FirebaseDatabase.instance
//         .ref()
//         .child('courses')
//         .child(widget.courseId)
//         .child('modules')
//         .child('module_${widget.moduleIndex}')
//         .child('content');

//     contentRef
//         .once()
//         .then((DatabaseEvent event) {
//           if (event.snapshot.value != null) {
//             try {
//               setState(() {
//                 currentContent = event.snapshot.value as String;
//               });
//             } catch (e) {
//               print("Error parsing content: $e");
//               setState(() {
//                 currentContent = '[]';
//               });
//             }
//           }
//         })
//         .catchError((error) {
//           ScaffoldMessenger.of(context).showSnackBar(
//             SnackBar(content: Text('Failed to fetch module content: $error')),
//           );
//         });
//   }

//   void _appendContent() async {
//     if (contentController.text.isNotEmpty) {
//       String newContent;
//       if (selectedType == "html" || selectedType == "code") {
//         String sanitizedContent = contentController.text
//             .replaceAll('"', '\\"')
//             .replaceAll('\n', '\\n');
//         newContent = '{"$selectedType": "$sanitizedContent"}';
//       } else {
//         newContent = '{"media": "${contentController.text}"}';
//       }

//       List<dynamic> contentList = [];
//       if (currentContent.isNotEmpty) {
//         try {
//           contentList = jsonDecode(currentContent);
//         } catch (e) {
//           print("Error decoding existing content: $e");
//           contentList = [];
//         }
//       }

//       contentList.add(jsonDecode(newContent));
//       String updatedContent = jsonEncode(contentList);

//       DatabaseReference contentRef = FirebaseDatabase.instance
//           .ref()
//           .child('courses')
//           .child(widget.courseId)
//           .child('modules')
//           .child('module_${widget.moduleIndex}')
//           .child('content');

//       contentRef
//           .set(updatedContent)
//           .then((_) {
//             setState(() {
//               currentContent = updatedContent;
//             });
//             contentController.clear();

//             User? user = FirebaseAuth.instance.currentUser;
//             if (user != null) {
//               DatabaseReference mentorContentRef = FirebaseDatabase.instance
//                   .ref()
//                   .child('mentorcourse')
//                   .child(user.uid)
//                   .child(widget.courseId)
//                   .child('modules')
//                   .child('module_${widget.moduleIndex}')
//                   .child('content');

//               mentorContentRef
//                   .set(updatedContent)
//                   .then((_) {
//                     ScaffoldMessenger.of(context).showSnackBar(
//                       SnackBar(content: Text('Content added successfully')),
//                     );
//                   })
//                   .catchError((error) {
//                     ScaffoldMessenger.of(context).showSnackBar(
//                       SnackBar(
//                         content: Text(
//                           'Failed to update mentor reference: $error',
//                         ),
//                       ),
//                     );
//                   });
//             }

//             setState(() {
//               isPopupVisible = false;
//             });
//           })
//           .catchError((error) {
//             ScaffoldMessenger.of(context).showSnackBar(
//               SnackBar(content: Text('Failed to save content: $error')),
//             );
//           });
//     }
//   }

//   void _appendMediaContent(String mediaUrl) async {
//     String newContent = '{"media": "$mediaUrl"}';
//     List<dynamic> contentList = [];
//     if (currentContent.isNotEmpty) {
//       try {
//         contentList = jsonDecode(currentContent);
//       } catch (e) {
//         print("Error decoding existing content: $e");
//         contentList = [];
//       }
//     }

//     contentList.add(jsonDecode(newContent));
//     String updatedContent = jsonEncode(contentList);

//     DatabaseReference contentRef = FirebaseDatabase.instance
//         .ref()
//         .child('courses')
//         .child(widget.courseId)
//         .child('modules')
//         .child('module_${widget.moduleIndex}')
//         .child('content');

//     contentRef
//         .set(updatedContent)
//         .then((_) {
//           setState(() {
//             currentContent = updatedContent;
//           });
//           _mediaFile = null;
//           _videoController?.dispose();
//           _videoController = null;

//           User? user = FirebaseAuth.instance.currentUser;
//           if (user != null) {
//             DatabaseReference mentorContentRef = FirebaseDatabase.instance
//                 .ref()
//                 .child('mentorcourse')
//                 .child(user.uid)
//                 .child(widget.courseId)
//                 .child('modules')
//                 .child('module_${widget.moduleIndex}')
//                 .child('content');

//             mentorContentRef
//                 .set(updatedContent)
//                 .then((_) {
//                   ScaffoldMessenger.of(context).showSnackBar(
//                     SnackBar(content: Text('Media added successfully')),
//                   );
//                 })
//                 .catchError((error) {
//                   ScaffoldMessenger.of(context).showSnackBar(
//                     SnackBar(
//                       content: Text(
//                         'Failed to update mentor reference: $error',
//                       ),
//                     ),
//                   );
//                 });
//           }

//           setState(() {
//             isPopupVisible = false;
//             _uploadStatus = null;
//             _uploadProgress = null;
//           });
//           _confettiController.play();
//         })
//         .catchError((error) {
//           ScaffoldMessenger.of(context).showSnackBar(
//             SnackBar(content: Text('Failed to save media: $error')),
//           );
//         });
//   }

//   void _appendVideoContent(String videoUrl) async {
//     String newContent = '{"media": "$videoUrl"}';
//     List<dynamic> contentList = [];
//     if (currentContent.isNotEmpty) {
//       try {
//         contentList = jsonDecode(currentContent);
//       } catch (e) {
//         print("Error decoding existing content: $e");
//         contentList = [];
//       }
//     }

//     contentList.add(jsonDecode(newContent));
//     String updatedContent = jsonEncode(contentList);

//     DatabaseReference contentRef = FirebaseDatabase.instance
//         .ref()
//         .child('courses')
//         .child(widget.courseId)
//         .child('modules')
//         .child('module_${widget.moduleIndex}')
//         .child('content');

//     contentRef
//         .set(updatedContent)
//         .then((_) {
//           setState(() {
//             currentContent = updatedContent;
//           });
//           titleController.clear();
//           descriptionController.clear();
//           _mediaFile = null;
//           _videoController?.dispose();
//           _videoController = null;

//           User? user = FirebaseAuth.instance.currentUser;
//           if (user != null) {
//             DatabaseReference mentorContentRef = FirebaseDatabase.instance
//                 .ref()
//                 .child('mentorcourse')
//                 .child(user.uid)
//                 .child(widget.courseId)
//                 .child('modules')
//                 .child('module_${widget.moduleIndex}')
//                 .child('content');

//             mentorContentRef
//                 .set(updatedContent)
//                 .then((_) {
//                   ScaffoldMessenger.of(context).showSnackBar(
//                     SnackBar(content: Text('Video added successfully')),
//                   );
//                 })
//                 .catchError((error) {
//                   ScaffoldMessenger.of(context).showSnackBar(
//                     SnackBar(
//                       content: Text(
//                         'Failed to update mentor reference: $error',
//                       ),
//                     ),
//                   );
//                 });
//           }

//           setState(() {
//             isPopupVisible = false;
//             _uploadStatus = null;
//             _uploadProgress = null;
//           });
//           _confettiController.play();
//         })
//         .catchError((error) {
//           ScaffoldMessenger.of(context).showSnackBar(
//             SnackBar(content: Text('Failed to save video: $error')),
//           );
//         });
//   }

//   Future<void> _pickMedia() async {
//     final result = await FilePicker.platform.pickFiles(allowMultiple: false);
//     if (result != null && result.files.single.path != null) {
//       final file = File(result.files.single.path!);
//       if (await file.exists()) {
//         setState(() {
//           _mediaFile = file;
//           _uploadStatus = null;
//           _uploadProgress = null;
//           _videoController?.dispose();
//           _videoController = null;
//           if (file.path.endsWith('.mp4') ||
//               file.path.endsWith('.mov') ||
//               file.path.endsWith('.avi')) {
//             _videoController = VideoPlayerController.file(file)
//               ..initialize().then((_) => setState(() {}));
//           }
//         });
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text(
//               'File selected: ${file.path.split('/').last}. Starting upload...',
//             ),
//           ),
//         );
//         await _uploadMedia();
//       }
//     }
//   }

//   Future<void> _uploadMedia() async {
//     if (_mediaFile == null) {
//       ScaffoldMessenger.of(
//         context,
//       ).showSnackBar(const SnackBar(content: Text('No file selected')));
//       return;
//     }
//     try {
//       setState(() {
//         _uploadStatus = 'Uploading to Cloudinary...';
//         _uploadProgress = null;
//       });

//       final response = await cloudinary.uploadFile(
//         CloudinaryFile.fromFile(
//           _mediaFile!.path,
//           resourceType: CloudinaryResourceType.Auto,
//         ),
//         onProgress: (bytes, totalBytes) {
//           setState(() {
//             _uploadProgress = bytes / totalBytes;
//           });
//         },
//       );

//       _appendMediaContent(response.secureUrl);
//     } catch (e) {
//       setState(() {
//         _uploadStatus = 'Error: $e';
//         _uploadProgress = null;
//       });
//       ScaffoldMessenger.of(
//         context,
//       ).showSnackBar(SnackBar(content: Text('Error: $e')));
//     }
//   }

//   Future<void> _pickVideo() async {
//     final result = await FilePicker.platform.pickFiles(
//       type: FileType.video,
//       allowMultiple: false,
//     );
//     if (result != null && result.files.single.path != null) {
//       final file = File(result.files.single.path!);
//       if (await file.exists()) {
//         setState(() {
//           _mediaFile = file;
//           _videoController?.dispose();
//           _videoController = VideoPlayerController.file(file)
//             ..initialize().then((_) => setState(() {}));
//         });
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text(
//               'Video selected: ${file.path.split('/').last}. Starting upload...',
//             ),
//           ),
//         );
//         await _handleUpload();
//       }
//     }
//   }

//   Future<void> _handleUpload() async {
//     if (!_formKey.currentState!.validate()) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Please enter a valid title')),
//       );
//       return;
//     }
//     if (_mediaFile == null) {
//       ScaffoldMessenger.of(
//         context,
//       ).showSnackBar(const SnackBar(content: Text('No video selected')));
//       return;
//     }
//     try {
//       setState(() {
//         _uploadStatus = 'Authenticating...';
//         _uploadProgress = null;
//       });
//       await _googleSignIn.signOut();
//       final GoogleSignInAccount? account = await _googleSignIn.signIn();
//       if (account == null) {
//         setState(() => _uploadStatus = 'Authentication canceled by user');
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text('Authentication canceled by user')),
//         );
//         return;
//       }
//       final GoogleSignInAuthentication auth = await account.authentication;
//       final String? accessToken = auth.accessToken;
//       if (accessToken == null) {
//         setState(() => _uploadStatus = 'Failed to get access token');
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text('Failed to get access token')),
//         );
//         return;
//       }

//       setState(() => _uploadStatus = 'Requesting permission...');
//       PermissionStatus permissionStatus;
//       if (Platform.isAndroid &&
//           (await DeviceInfoPlugin().androidInfo).version.sdkInt >= 33) {
//         permissionStatus = await Permission.videos.request();
//       } else {
//         permissionStatus = await Permission.storage.request();
//       }
//       if (!permissionStatus.isGranted) {
//         setState(() => _uploadStatus = 'Permission denied');
//         ScaffoldMessenger.of(
//           context,
//         ).showSnackBar(const SnackBar(content: Text('Permission denied')));
//         return;
//       }

//       setState(() => _uploadStatus = 'Uploading video...');
//       final videoId = await _uploadVideo(_mediaFile!, accessToken);
//       if (videoId != null) {
//         final videoUrl = 'https://www.youtube.com/watch?v=$videoId';
//         _appendVideoContent(videoUrl);
//       } else {
//         setState(() {
//           _uploadStatus = 'Upload failed';
//           _uploadProgress = null;
//         });
//         ScaffoldMessenger.of(
//           context,
//         ).showSnackBar(const SnackBar(content: Text('Upload failed')));
//       }
//     } catch (e) {
//       setState(() {
//         _uploadStatus = 'Error: $e';
//         _uploadProgress = null;
//       });
//       ScaffoldMessenger.of(
//         context,
//       ).showSnackBar(SnackBar(content: Text('Error: $e')));
//     }
//   }

//   Future<String?> _uploadVideo(File videoFile, String accessToken) async {
//     try {
//       final initUri = Uri.parse(
//         'https://www.googleapis.com/upload/youtube/v3/videos?part=snippet,status,contentDetails&uploadType=resumable',
//       );
//       final metadata = jsonEncode({
//         'snippet': {
//           'title': titleController.text,
//           'description': descriptionController.text,
//           'tags': ['flutter', 'upload'],
//           'categoryId': '22',
//           'defaultLanguage': 'en',
//         },
//         'status': {
//           'privacyStatus': 'public',
//           'embeddable': true,
//           'license': 'youtube',
//           'notifySubscribers': true,
//         },
//         'contentDetails': {'selfDeclaredMadeForKids': false},
//       });
//       final initRequest =
//           http.Request('POST', initUri)
//             ..headers['Authorization'] = 'Bearer $accessToken'
//             ..headers['Content-Type'] = 'application/json'
//             ..headers['X-Upload-Content-Type'] = 'video/*'
//             ..body = metadata;

//       final initResponse = await http.Client().send(initRequest);
//       final initResponseBody = await http.Response.fromStream(initResponse);
//       if (initResponse.statusCode != 200 && initResponse.statusCode != 201) {
//         throw Exception('Failed to initiate upload: ${initResponseBody.body}');
//       }

//       final uploadUrl = initResponse.headers['location'];
//       if (uploadUrl == null) {
//         throw Exception('Upload URL not found in response headers');
//       }

//       final uploadUri = Uri.parse(uploadUrl);
//       final fileStream = videoFile.openRead();
//       final fileLength = await videoFile.length();
//       int bytesSent = 0;

//       final uploadRequest =
//           http.StreamedRequest('PUT', uploadUri)
//             ..headers['Authorization'] = 'Bearer $accessToken'
//             ..headers['Content-Type'] = 'video/*'
//             ..headers['Content-Length'] = fileLength.toString();
//       fileStream.listen(
//         (data) {
//           bytesSent += data.length;
//           setState(() {
//             _uploadProgress = bytesSent / fileLength;
//           });
//           uploadRequest.sink.add(data);
//         },
//         onDone: () => uploadRequest.sink.close(),
//         onError: (e) => throw Exception('Stream error: $e'),
//       );

//       final uploadResponse = await http.Client().send(uploadRequest);
//       final uploadResponseBody = await http.Response.fromStream(uploadResponse);
//       if (uploadResponse.statusCode == 200 ||
//           uploadResponse.statusCode == 201) {
//         final jsonResponse = jsonDecode(uploadResponseBody.body);
//         return jsonResponse['id'];
//       } else {
//         throw Exception('Upload failed: ${uploadResponseBody.body}');
//       }
//     } catch (e) {
//       rethrow;
//     }
//   }

//   void _showContentTypeSelection() {
//     showDialog(
//       context: context,
//       builder: (context) {
//         return AlertDialog(
//           title: Center(
//             child: Text(
//               'Select Content Type',
//               style: TextStyle(
//                 fontSize: 20,
//                 fontWeight: FontWeight.bold,
//                 color: Colors.blue.shade800,
//               ),
//             ),
//           ),
//           content: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               _buildContentTypeButton(
//                 'HTML',
//                 Colors.blue.shade100,
//                 Colors.blue.shade800,
//               ),
//               SizedBox(height: 10),
//               _buildContentTypeButton(
//                 'Media Upload',
//                 Colors.blue.shade100,
//                 Colors.blue.shade800,
//               ),
//               SizedBox(height: 10),
//               _buildContentTypeButton(
//                 'YouTube Video',
//                 Colors.blue.shade100,
//                 Colors.blue.shade800,
//               ),
//               SizedBox(height: 10),
//               _buildContentTypeButton(
//                 'Code',
//                 Colors.blue.shade100,
//                 Colors.blue.shade800,
//               ),
//               SizedBox(height: 10),
//               _buildContentTypeButton(
//                 'Video Upload',
//                 Colors.blue.shade100,
//                 Colors.blue.shade800,
//               ),
//             ],
//           ),
//           shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.circular(15),
//           ),
//           backgroundColor: Colors.blue.shade50,
//         );
//       },
//     );
//   }

//   Widget _buildContentTypeButton(
//     String text,
//     Color backgroundColor,
//     Color textColor,
//   ) {
//     return SizedBox(
//       width: 180,
//       child: ElevatedButton(
//         onPressed: () {
//           Navigator.pop(context);
//           _startAddingContent(text.toLowerCase().replaceAll(' ', ''));
//         },
//         style: ElevatedButton.styleFrom(
//           backgroundColor: backgroundColor,
//           foregroundColor: textColor,
//           padding: const EdgeInsets.symmetric(vertical: 15),
//           shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.circular(10),
//             side: BorderSide(color: Colors.blue.shade300, width: 2.5),
//           ),
//           elevation: 3,
//         ),
//         child: Text(
//           text,
//           style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
//         ),
//       ),
//     );
//   }

//   void _startAddingContent(String type) {
//     setState(() {
//       selectedType = type;
//       isPopupVisible = true;
//       _uploadStatus = null;
//       _uploadProgress = null;
//       _mediaFile = null;
//       _videoController?.dispose();
//       _videoController = null;
//       if (type != 'videoupload') {
//         titleController.text = 'Uploaded Video';
//         descriptionController.text = 'Uploaded via Flutter app';
//       }
//     });
//   }

//   void _cancelAddingContent() {
//     setState(() {
//       isPopupVisible = false;
//       contentController.clear();
//       titleController.clear();
//       descriptionController.clear();
//       _mediaFile = null;
//       _videoController?.dispose();
//       _videoController = null;
//       _uploadStatus = null;
//       _uploadProgress = null;
//     });
//   }

//   Widget _buildContentBlock(String blockType, String content) {
//     try {
//       List<dynamic> parsedContentList =
//           content.startsWith('[') ? jsonDecode(content) : [jsonDecode(content)];

//       if (blockType == 'HTML') {
//         return Column(
//           mainAxisSize: MainAxisSize.min,
//           children:
//               parsedContentList.expand((item) {
//                 return [
//                   if (item is Map && item.containsKey('html'))
//                     Html(data: item['html'])
//                   else
//                     Text('No HTML content available'),
//                   SizedBox(height: 20),
//                 ];
//               }).toList(),
//         );
//       } else if (blockType == 'media') {
//         return Column(
//           mainAxisSize: MainAxisSize.min,
//           children:
//               parsedContentList.expand((item) {
//                 if (item is Map && item.containsKey('media')) {
//                   String url = item['media'];
//                   if (url.contains('youtube.com') || url.contains('youtu.be')) {
//                     return [_buildYouTubePlayer(url), SizedBox(height: 20)];
//                   } else if (url.endsWith('.mp4') ||
//                       url.endsWith('.mov') ||
//                       url.endsWith('.avi')) {
//                     return [_buildCloudinaryVideo(url), SizedBox(height: 20)];
//                   } else {
//                     return [_buildImage(url), SizedBox(height: 20)];
//                   }
//                 }
//                 return [
//                   Text('No media content available'),
//                   SizedBox(height: 20),
//                 ];
//               }).toList(),
//         );
//       } else if (blockType == 'code') {
//         return Column(
//           mainAxisSize: MainAxisSize.min,
//           children:
//               parsedContentList.expand((item) {
//                 return [
//                   if (item is Map && item.containsKey('code'))
//                     Stack(
//                       children: [
//                         Container(
//                           padding: EdgeInsets.all(10),
//                           margin: EdgeInsets.only(top: 10),
//                           decoration: BoxDecoration(
//                             color: Colors.black,
//                             borderRadius: BorderRadius.circular(8),
//                           ),
//                           child: SingleChildScrollView(
//                             scrollDirection: Axis.horizontal,
//                             child: HighlightView(
//                               item['code'],
//                               language: 'html',
//                               theme: monokaiSublimeTheme,
//                               padding: EdgeInsets.all(10),
//                               textStyle: TextStyle(
//                                 fontFamily: 'Courier New',
//                                 fontSize: 14,
//                               ),
//                             ),
//                           ),
//                         ),
//                         Positioned(
//                           top: 5,
//                           right: 5,
//                           child: IconButton(
//                             icon: Icon(
//                               Icons.copy,
//                               color: Colors.white70,
//                               size: 18,
//                             ),
//                             onPressed: () {
//                               Clipboard.setData(
//                                 ClipboardData(text: item['code']),
//                               ).then((_) {
//                                 ScaffoldMessenger.of(context).showSnackBar(
//                                   SnackBar(
//                                     content: Text('Code copied to clipboard!'),
//                                   ),
//                                 );
//                               });
//                             },
//                           ),
//                         ),
//                       ],
//                     )
//                   else
//                     Text('No code content available'),
//                   SizedBox(height: 20),
//                 ];
//               }).toList(),
//         );
//       } else {
//         return Text('Unknown content type');
//       }
//     } catch (e) {
//       return Text('Error rendering content: $e');
//     }
//   }

//   Widget _buildYouTubePlayer(String videoUrl) {
//     String videoId = YoutubePlayer.convertUrlToId(videoUrl) ?? '';
//     if (videoId.isEmpty) {
//       return Text('Invalid video URL');
//     }

//     YoutubePlayerController controller = YoutubePlayerController(
//       initialVideoId: videoId,
//       flags: YoutubePlayerFlags(
//         autoPlay: false,
//         mute: false,
//         enableCaption: false,
//       ),
//     );

//     return Container(
//       decoration: BoxDecoration(
//         border: Border.all(color: Colors.blue, width: 3),
//         borderRadius: BorderRadius.circular(25),
//       ),
//       child: ClipRRect(
//         borderRadius: BorderRadius.circular(22),
//         child: YoutubePlayer(
//           controller: controller,
//           showVideoProgressIndicator: true,
//         ),
//       ),
//     );
//   }

//   Widget _buildCloudinaryVideo(String videoUrl) {
//     VideoPlayerController controller = VideoPlayerController.network(videoUrl);
//     return FutureBuilder(
//       future: controller.initialize(),
//       builder: (context, snapshot) {
//         if (snapshot.connectionState == ConnectionState.done) {
//           return Container(
//             decoration: BoxDecoration(
//               border: Border.all(color: Colors.blue, width: 3),
//               borderRadius: BorderRadius.circular(25),
//             ),
//             child: ClipRRect(
//               borderRadius: BorderRadius.circular(22),
//               child: AspectRatio(
//                 aspectRatio: controller.value.aspectRatio,
//                 child: Stack(
//                   alignment: Alignment.center,
//                   children: [
//                     VideoPlayer(controller),
//                     IconButton(
//                       icon: Icon(
//                         controller.value.isPlaying
//                             ? Icons.pause
//                             : Icons.play_arrow,
//                         color: Colors.white,
//                         size: 40,
//                       ),
//                       onPressed: () {
//                         setState(() {
//                           controller.value.isPlaying
//                               ? controller.pause()
//                               : controller.play();
//                         });
//                       },
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//           );
//         }
//         return Center(child: CircularProgressIndicator());
//       },
//     );
//   }

//   Widget _buildImage(String imageUrl) {
//     try {
//       return Container(
//         decoration: BoxDecoration(
//           borderRadius: BorderRadius.circular(25),
//           border: Border.all(color: Colors.blue, width: 3),
//         ),
//         child: ClipRRect(
//           borderRadius: BorderRadius.circular(25),
//           child: Image.network(
//             imageUrl,
//             fit: BoxFit.cover,
//             loadingBuilder: (context, child, loadingProgress) {
//               if (loadingProgress == null) return child;
//               return Center(
//                 child: CircularProgressIndicator(
//                   value:
//                       loadingProgress.expectedTotalBytes != null
//                           ? loadingProgress.cumulativeBytesLoaded /
//                               loadingProgress.expectedTotalBytes!
//                           : null,
//                 ),
//               );
//             },
//             errorBuilder:
//                 (context, error, stackTrace) =>
//                     Center(child: Icon(Icons.error, color: Colors.red)),
//           ),
//         ),
//       );
//     } catch (e) {
//       return Center(child: Text('Error loading image: $e'));
//     }
//   }

//   Widget _renderContent(String content) {
//     try {
//       List<dynamic> contentList =
//           content.startsWith('[') ? jsonDecode(content) : [jsonDecode(content)];

//       return Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children:
//             contentList.map((item) {
//               if (item is Map) {
//                 if (item.containsKey('html')) {
//                   return _buildContentBlock('HTML', jsonEncode([item]));
//                 } else if (item.containsKey('media') ||
//                     item.containsKey('imageurl') ||
//                     item.containsKey('youtubevideo')) {
//                   // Handle legacy imageurl and youtubevideo for backward compatibility
//                   if (item.containsKey('imageurl')) {
//                     item['media'] = item['imageurl'];
//                   } else if (item.containsKey('youtubevideo')) {
//                     item['media'] = item['youtubevideo'];
//                   }
//                   return _buildContentBlock('media', jsonEncode([item]));
//                 } else if (item.containsKey('code')) {
//                   return _buildContentBlock('code', jsonEncode([item]));
//                 } else {
//                   return Text('Unknown content type');
//                 }
//               } else {
//                 return Text('Invalid content format');
//               }
//             }).toList(),
//       );
//     } catch (e) {
//       return Text('Error rendering content: $e');
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text(widget.moduleName),
//         backgroundColor: Colors.blue,
//         shape: const RoundedRectangleBorder(
//           borderRadius: BorderRadius.vertical(bottom: Radius.circular(25)),
//         ),
//         flexibleSpace: Container(
//           decoration: const BoxDecoration(
//             borderRadius: BorderRadius.vertical(bottom: Radius.circular(25)),
//             boxShadow: [
//               BoxShadow(
//                 color: Color.fromARGB(168, 32, 32, 32),
//                 offset: Offset(0, 5),
//                 blurRadius: 2,
//                 spreadRadius: 1.5,
//               ),
//             ],
//             gradient: LinearGradient(
//               begin: Alignment.topCenter,
//               end: Alignment.bottomCenter,
//               colors: [
//                 Color.fromARGB(255, 66, 165, 245),
//                 Color.fromARGB(255, 21, 101, 192),
//               ],
//             ),
//           ),
//         ),
//       ),
//       body: Stack(
//         children: [
//           GestureDetector(
//             onTap: () => FocusScope.of(context).requestFocus(FocusNode()),
//             child: SingleChildScrollView(
//               child: Padding(
//                 padding: const EdgeInsets.all(16),
//                 child: Column(
//                   mainAxisAlignment: MainAxisAlignment.start,
//                   crossAxisAlignment: CrossAxisAlignment.center,
//                   children: [
//                     Card(
//                       elevation: 8,
//                       shadowColor: const Color.fromARGB(255, 0, 0, 0),
//                       shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(16),
//                       ),
//                       child: Padding(
//                         padding: const EdgeInsets.all(16),
//                         child: Column(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//                             Center(
//                               child: Text(
//                                 widget.moduleName.toUpperCase(),
//                                 style: const TextStyle(
//                                   fontSize: 20,
//                                   fontWeight: FontWeight.bold,
//                                   color: Colors.blue,
//                                 ),
//                               ),
//                             ),
//                             const SizedBox(height: 20),
//                             const Divider(),
//                             const SizedBox(height: 10),
//                             const Text(
//                               'Current Content: ',
//                               style: TextStyle(
//                                 fontSize: 16,
//                                 fontWeight: FontWeight.bold,
//                               ),
//                             ),
//                             const SizedBox(height: 10),
//                             currentContent.isNotEmpty
//                                 ? _renderContent(currentContent)
//                                 : const Text(
//                                   'No content added yet.',
//                                   style: TextStyle(
//                                     fontSize: 14,
//                                     color: Colors.grey,
//                                   ),
//                                 ),
//                           ],
//                         ),
//                       ),
//                     ),
//                     const SizedBox(height: 20),
//                     isPopupVisible
//                         ? Card(
//                           elevation: 5,
//                           shape: RoundedRectangleBorder(
//                             borderRadius: BorderRadius.circular(12),
//                           ),
//                           child: Padding(
//                             padding: const EdgeInsets.all(16),
//                             child: Column(
//                               crossAxisAlignment: CrossAxisAlignment.start,
//                               children: [
//                                 Text(
//                                   selectedType == 'videoupload'
//                                       ? 'Upload Video'
//                                       : selectedType == 'mediaupload'
//                                       ? 'Upload Media'
//                                       : 'Add ${selectedType.capitalize()} Content',
//                                   style: const TextStyle(
//                                     fontSize: 18,
//                                     fontWeight: FontWeight.bold,
//                                     color: Colors.blueAccent,
//                                   ),
//                                 ),
//                                 const SizedBox(height: 10),
//                                 if (selectedType == 'videoupload') ...[
//                                   Form(
//                                     key: _formKey,
//                                     child: Column(
//                                       children: [
//                                         TextFormField(
//                                           controller: titleController,
//                                           decoration: InputDecoration(
//                                             labelText: 'Video Title',
//                                             border: OutlineInputBorder(
//                                               borderRadius:
//                                                   BorderRadius.circular(10),
//                                             ),
//                                           ),
//                                           validator: (value) {
//                                             if (value == null || value.isEmpty)
//                                               return 'Title is required';
//                                             if (value.length > 100)
//                                               return 'Title must be 100 characters or less';
//                                             return null;
//                                           },
//                                         ),
//                                         const SizedBox(height: 10),
//                                         TextFormField(
//                                           controller: descriptionController,
//                                           decoration: InputDecoration(
//                                             labelText: 'Description (Optional)',
//                                             border: OutlineInputBorder(
//                                               borderRadius:
//                                                   BorderRadius.circular(10),
//                                             ),
//                                           ),
//                                           maxLines: 3,
//                                           validator: (value) {
//                                             if (value != null &&
//                                                 value.length > 5000) {
//                                               return 'Description must be 5000 characters or less';
//                                             }
//                                             return null;
//                                           },
//                                         ),
//                                         const SizedBox(height: 10),
//                                         const Text(
//                                           'Note: Use horizontal (16:9) videos longer than 60 seconds for standard format.',
//                                           style: TextStyle(
//                                             fontStyle: FontStyle.italic,
//                                             color: Colors.black54,
//                                           ),
//                                           textAlign: TextAlign.center,
//                                         ),
//                                         const SizedBox(height: 10),
//                                         if (_mediaFile != null &&
//                                             _videoController != null) ...[
//                                           AspectRatio(
//                                             aspectRatio:
//                                                 _videoController!
//                                                     .value
//                                                     .aspectRatio,
//                                             child: VideoPlayer(
//                                               _videoController!,
//                                             ),
//                                           ),
//                                           const SizedBox(height: 8),
//                                           Text(
//                                             'Selected: ${_mediaFile!.path.split('/').last}',
//                                             style: const TextStyle(
//                                               fontStyle: FontStyle.italic,
//                                             ),
//                                           ),
//                                         ],
//                                         const SizedBox(height: 10),
//                                         GestureDetector(
//                                           onTapDown:
//                                               (_) =>
//                                                   _buttonAnimationController
//                                                       .forward(),
//                                           onTapUp:
//                                               (_) =>
//                                                   _buttonAnimationController
//                                                       .reverse(),
//                                           onTapCancel:
//                                               () =>
//                                                   _buttonAnimationController
//                                                       .reverse(),
//                                           child: ScaleTransition(
//                                             scale: _buttonScaleAnimation,
//                                             child: ElevatedButton.icon(
//                                               onPressed:
//                                                   _uploadStatus != null &&
//                                                           _uploadStatus!
//                                                               .contains(
//                                                                 'Uploading',
//                                                               )
//                                                       ? null
//                                                       : _pickVideo,
//                                               icon: const Icon(
//                                                 Icons.video_library,
//                                               ),
//                                               label: const Text('Select Video'),
//                                               style: ElevatedButton.styleFrom(
//                                                 backgroundColor:
//                                                     Colors.blueAccent,
//                                                 foregroundColor: Colors.white,
//                                                 shape: RoundedRectangleBorder(
//                                                   borderRadius:
//                                                       BorderRadius.circular(8),
//                                                 ),
//                                               ),
//                                             ),
//                                           ),
//                                         ),
//                                         if (_uploadStatus != null &&
//                                             _uploadStatus!.contains(
//                                               'Uploading',
//                                             )) ...[
//                                           const SizedBox(height: 10),
//                                           LinearProgressIndicator(
//                                             value: _uploadProgress,
//                                             backgroundColor: Colors.grey[300],
//                                             valueColor:
//                                                 const AlwaysStoppedAnimation(
//                                                   Colors.blueAccent,
//                                                 ),
//                                           ),
//                                           const SizedBox(height: 8),
//                                           Text(
//                                             _uploadProgress != null
//                                                 ? 'Upload Progress: ${(_uploadProgress! * 100).toStringAsFixed(1)}%'
//                                                 : 'Uploading...',
//                                           ),
//                                         ],
//                                       ],
//                                     ),
//                                   ),
//                                 ] else if (selectedType == 'mediaupload') ...[
//                                   Column(
//                                     children: [
//                                       const Text(
//                                         'Note: Supports images, videos, and other files.',
//                                         style: TextStyle(
//                                           fontStyle: FontStyle.italic,
//                                           color: Colors.black54,
//                                         ),
//                                         textAlign: TextAlign.center,
//                                       ),
//                                       const SizedBox(height: 10),
//                                       if (_mediaFile != null) ...[
//                                         if (_videoController != null &&
//                                             _videoController!
//                                                 .value
//                                                 .isInitialized) ...[
//                                           AspectRatio(
//                                             aspectRatio:
//                                                 _videoController!
//                                                     .value
//                                                     .aspectRatio,
//                                             child: VideoPlayer(
//                                               _videoController!,
//                                             ),
//                                           ),
//                                         ] else ...[
//                                           Image.file(
//                                             _mediaFile!,
//                                             height: 200,
//                                             fit: BoxFit.cover,
//                                             errorBuilder:
//                                                 (context, error, stackTrace) =>
//                                                     const Icon(
//                                                       Icons.error,
//                                                       color: Colors.red,
//                                                     ),
//                                           ),
//                                         ],
//                                         const SizedBox(height: 8),
//                                         Text(
//                                           'Selected: ${_mediaFile!.path.split('/').last}',
//                                           style: const TextStyle(
//                                             fontStyle: FontStyle.italic,
//                                           ),
//                                         ),
//                                       ],
//                                       const SizedBox(height: 10),
//                                       GestureDetector(
//                                         onTapDown:
//                                             (_) =>
//                                                 _buttonAnimationController
//                                                     .forward(),
//                                         onTapUp:
//                                             (_) =>
//                                                 _buttonAnimationController
//                                                     .reverse(),
//                                         onTapCancel:
//                                             () =>
//                                                 _buttonAnimationController
//                                                     .reverse(),
//                                         child: ScaleTransition(
//                                           scale: _buttonScaleAnimation,
//                                           child: ElevatedButton.icon(
//                                             onPressed:
//                                                 _uploadStatus != null &&
//                                                         _uploadStatus!.contains(
//                                                           'Uploading',
//                                                         )
//                                                     ? null
//                                                     : _pickMedia,
//                                             icon: const Icon(Icons.upload_file),
//                                             label: const Text('Select File'),
//                                             style: ElevatedButton.styleFrom(
//                                               backgroundColor:
//                                                   Colors.blueAccent,
//                                               foregroundColor: Colors.white,
//                                               shape: RoundedRectangleBorder(
//                                                 borderRadius:
//                                                     BorderRadius.circular(8),
//                                               ),
//                                             ),
//                                           ),
//                                         ),
//                                       ),
//                                       if (_uploadStatus != null &&
//                                           _uploadStatus!.contains(
//                                             'Uploading',
//                                           )) ...[
//                                         const SizedBox(height: 10),
//                                         LinearProgressIndicator(
//                                           value: _uploadProgress,
//                                           backgroundColor: Colors.grey[300],
//                                           valueColor:
//                                               const AlwaysStoppedAnimation(
//                                                 Colors.blueAccent,
//                                               ),
//                                         ),
//                                         const SizedBox(height: 8),
//                                         Text(
//                                           _uploadProgress != null
//                                               ? 'Upload Progress: ${(_uploadProgress! * 100).toStringAsFixed(1)}%'
//                                               : 'Uploading...',
//                                         ),
//                                       ],
//                                     ],
//                                   ),
//                                 ] else ...[
//                                   TextField(
//                                     controller: contentController,
//                                     decoration: InputDecoration(
//                                       labelText:
//                                           selectedType == 'html'
//                                               ? 'Enter HTML'
//                                               : selectedType == 'youtubevideo'
//                                               ? 'Enter YouTube URL'
//                                               : selectedType == 'code'
//                                               ? 'Enter Code'
//                                               : '',
//                                       border: OutlineInputBorder(
//                                         borderRadius: BorderRadius.circular(10),
//                                       ),
//                                     ),
//                                     maxLines:
//                                         selectedType == 'html' ||
//                                                 selectedType == 'code'
//                                             ? 5
//                                             : 2,
//                                   ),
//                                 ],
//                                 const SizedBox(height: 20),
//                                 Row(
//                                   mainAxisAlignment: MainAxisAlignment.start,
//                                   children: [
//                                     TextButton(
//                                       onPressed: _cancelAddingContent,
//                                       style: TextButton.styleFrom(
//                                         foregroundColor: Colors.redAccent,
//                                       ),
//                                       child: const Text('Cancel'),
//                                     ),
//                                     const SizedBox(width: 10),
//                                     if (selectedType != 'videoupload' &&
//                                         selectedType != 'mediaupload')
//                                       ElevatedButton(
//                                         onPressed: _appendContent,
//                                         style: ElevatedButton.styleFrom(
//                                           backgroundColor: Colors.blueAccent,
//                                           foregroundColor: Colors.white,
//                                           shape: RoundedRectangleBorder(
//                                             borderRadius: BorderRadius.circular(
//                                               8,
//                                             ),
//                                           ),
//                                         ),
//                                         child: const Text('Save'),
//                                       ),
//                                   ],
//                                 ),
//                               ],
//                             ),
//                           ),
//                         )
//                         : const SizedBox.shrink(),
//                   ],
//                 ),
//               ),
//             ),
//           ),
//           Align(
//             alignment: Alignment.topCenter,
//             child: ConfettiWidget(
//               confettiController: _confettiController,
//               blastDirectionality: BlastDirectionality.explosive,
//               colors: [
//                 Colors.blue.shade400,
//                 Colors.blue.shade800,
//                 Colors.white,
//               ],
//             ),
//           ),
//         ],
//       ),
//       floatingActionButton: FloatingActionButton(
//         onPressed: _showContentTypeSelection,
//         backgroundColor: Colors.blue,
//         child: const Icon(Icons.add, color: Colors.white),
//       ),
//     );
//   }

//   @override
//   void dispose() {
//     contentController.dispose();
//     titleController.dispose();
//     descriptionController.dispose();
//     _videoController?.dispose();
//     _confettiController.dispose();
//     _buttonAnimationController.dispose();
//     super.dispose();
//   }
// }

// extension StringExtension on String {
//   String capitalize() => "${this[0].toUpperCase()}${substring(1)}";
// }
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter_highlight/flutter_highlight.dart';
import 'package:flutter_highlight/themes/monokai-sublime.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:file_picker/file_picker.dart';
import 'package:cloudinary_public/cloudinary_public.dart';
import 'package:confetti/confetti.dart';

class AppendContentModulePage1 extends StatefulWidget {
  final String courseId;
  final int moduleIndex;
  final String moduleName;

  const AppendContentModulePage1({
    super.key,
    required this.courseId,
    required this.moduleIndex,
    required this.moduleName,
  });

  @override
  _AppendContentModulePageState createState() =>
      _AppendContentModulePageState();
}

class _AppendContentModulePageState extends State<AppendContentModulePage1>
    with SingleTickerProviderStateMixin {
  TextEditingController contentController = TextEditingController();
  TextEditingController titleController = TextEditingController(
    text: 'Uploaded Video',
  );
  TextEditingController descriptionController = TextEditingController(
    text: 'Uploaded via Flutter app',
  );
  String selectedType = 'html';
  String currentContent = '';
  bool isPopupVisible = false;
  PlatformFile? _mediaFile; // Use PlatformFile for web compatibility
  String? _uploadStatus;
  double? _uploadProgress;
  final _formKey = GlobalKey<FormState>();
  final _confettiController = ConfettiController(
    duration: const Duration(seconds: 3),
  );
  late AnimationController _buttonAnimationController;
  late Animation<double> _buttonScaleAnimation;

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    clientId:
        '894403809910-54q1iesdkppkg3f2m438bsb01dp8p0fa.apps.googleusercontent.com',
    scopes: ['email', 'profile'],
  );

  final cloudinary = CloudinaryPublic('dnedosgc6', 'ml_default', cache: false);

  @override
  void initState() {
    super.initState();
    _fetchModuleContent();
    _buttonAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _buttonScaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(
        parent: _buttonAnimationController,
        curve: Curves.easeInOut,
      ),
    );
  }

  void _fetchModuleContent() async {
    DatabaseReference contentRef = FirebaseDatabase.instance
        .ref()
        .child('courses')
        .child(widget.courseId)
        .child('modules')
        .child('module_${widget.moduleIndex}')
        .child('content');

    try {
      final event = await contentRef.once();
      if (event.snapshot.value != null) {
        setState(() {
          currentContent = event.snapshot.value as String? ?? '[]';
        });
      } else {
        setState(() {
          currentContent = '[]';
        });
      }
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to fetch module content: $error')),
      );
    }
  }

  void _appendContent() async {
    if (!_formKey.currentState!.validate()) return;
    if (contentController.text.isEmpty &&
        selectedType != 'mediaupload' &&
        selectedType != 'videoupload') {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Content cannot be empty')));
      return;
    }

    String newContent;
    if (selectedType == 'html' || selectedType == 'code') {
      String sanitizedContent = contentController.text
          .replaceAll('"', '\\"')
          .replaceAll('\n', '\\n');
      newContent = '{"$selectedType": "$sanitizedContent"}';
    } else {
      newContent = '{"media": "${contentController.text}"}';
    }

    List<dynamic> contentList = [];
    if (currentContent.isNotEmpty) {
      try {
        contentList = jsonDecode(currentContent);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error decoding existing content: $e')),
        );
        contentList = [];
      }
    }

    contentList.add(jsonDecode(newContent));
    String updatedContent = jsonEncode(contentList);

    DatabaseReference contentRef = FirebaseDatabase.instance
        .ref()
        .child('courses')
        .child(widget.courseId)
        .child('modules')
        .child('module_${widget.moduleIndex}')
        .child('content');

    try {
      await contentRef.set(updatedContent);
      setState(() {
        currentContent = updatedContent;
      });
      contentController.clear();

      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        DatabaseReference mentorContentRef = FirebaseDatabase.instance
            .ref()
            .child('mentorcourse')
            .child(user.uid)
            .child(widget.courseId)
            .child('modules')
            .child('module_${widget.moduleIndex}')
            .child('content');

        await mentorContentRef.set(updatedContent);
      }

      setState(() {
        isPopupVisible = false;
      });
      _confettiController.play();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Content added successfully')),
      );
    } catch (error) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to save content: $error')));
    }
  }

  void _appendMediaContent(String mediaUrl) async {
    String newContent = '{"media": "$mediaUrl"}';
    List<dynamic> contentList = [];
    if (currentContent.isNotEmpty) {
      try {
        contentList = jsonDecode(currentContent);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error decoding existing content: $e')),
        );
        contentList = [];
      }
    }

    contentList.add(jsonDecode(newContent));
    String updatedContent = jsonEncode(contentList);

    DatabaseReference contentRef = FirebaseDatabase.instance
        .ref()
        .child('courses')
        .child(widget.courseId)
        .child('modules')
        .child('module_${widget.moduleIndex}')
        .child('content');

    try {
      await contentRef.set(updatedContent);
      setState(() {
        currentContent = updatedContent;
        _mediaFile = null;
        _uploadStatus = null;
        _uploadProgress = null;
      });

      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        DatabaseReference mentorContentRef = FirebaseDatabase.instance
            .ref()
            .child('mentorcourse')
            .child(user.uid)
            .child(widget.courseId)
            .child('modules')
            .child('module_${widget.moduleIndex}')
            .child('content');

        await mentorContentRef.set(updatedContent);
      }

      setState(() {
        isPopupVisible = false;
      });
      _confettiController.play();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Media added successfully')));
    } catch (error) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to save media: $error')));
    }
  }

  Future<void> _pickMedia() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        allowMultiple: false,
      );
      if (result != null && result.files.single.bytes != null) {
        setState(() {
          _mediaFile = result.files.single;
          _uploadStatus = null;
          _uploadProgress = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'File selected: ${_mediaFile!.name}. Starting upload...',
            ),
          ),
        );
        await _uploadMedia();
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('No file selected')));
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error picking file: $e')));
    }
  }

  Future<void> _uploadMedia() async {
    if (_mediaFile == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('No file selected')));
      return;
    }

    try {
      setState(() {
        _uploadStatus = 'Uploading to Cloudinary...';
        _uploadProgress = null;
      });

      final response = await cloudinary.uploadFile(
        CloudinaryFile.fromBytesData(
          _mediaFile!.bytes!,
          identifier: _mediaFile!.name,
          resourceType: CloudinaryResourceType.Auto,
        ),
        onProgress: (bytes, totalBytes) {
          setState(() {
            _uploadProgress = bytes / totalBytes;
          });
        },
      );

      _appendMediaContent(response.secureUrl);
    } catch (e) {
      setState(() {
        _uploadStatus = 'Error: $e';
        _uploadProgress = null;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error uploading file: $e')));
    }
  }

  Future<void> _pickVideo() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid title')),
      );
      return;
    }

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.video,
        allowMultiple: false,
      );
      if (result != null && result.files.single.bytes != null) {
        setState(() {
          _mediaFile = result.files.single;
          _uploadStatus = null;
          _uploadProgress = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Video selected: ${_mediaFile!.name}. Starting upload...',
            ),
          ),
        );
        await _uploadMedia();
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('No video selected')));
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error picking video: $e')));
    }
  }

  void _showContentTypeSelection() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Center(
            child: Text(
              'Select Content Type',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.blueAccent,
              ),
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildContentTypeButton(
                'HTML',
                Colors.blue.shade100,
                Colors.blue.shade800,
              ),
              const SizedBox(height: 10),
              _buildContentTypeButton(
                'Media Upload',
                Colors.blue.shade100,
                Colors.blue.shade800,
              ),
              const SizedBox(height: 10),
              _buildContentTypeButton(
                'YouTube Video',
                Colors.blue.shade100,
                Colors.blue.shade800,
              ),
              const SizedBox(height: 10),
              _buildContentTypeButton(
                'Code',
                Colors.blue.shade100,
                Colors.blue.shade800,
              ),
              const SizedBox(height: 10),
              _buildContentTypeButton(
                'Video Upload',
                Colors.blue.shade100,
                Colors.blue.shade800,
              ),
            ],
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          backgroundColor: Colors.blue.shade50,
        );
      },
    );
  }

  Widget _buildContentTypeButton(
    String text,
    Color backgroundColor,
    Color textColor,
  ) {
    return SizedBox(
      width: 180,
      child: ElevatedButton(
        onPressed: () {
          Navigator.pop(context);
          _startAddingContent(text.toLowerCase().replaceAll(' ', ''));
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: textColor,
          padding: const EdgeInsets.symmetric(vertical: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: BorderSide(color: Colors.blue.shade300, width: 2.5),
          ),
          elevation: 3,
        ),
        child: Text(
          text,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
      ),
    );
  }

  void _startAddingContent(String type) {
    setState(() {
      selectedType = type;
      isPopupVisible = true;
      _uploadStatus = null;
      _uploadProgress = null;
      _mediaFile = null;
      contentController.clear();
      if (type != 'videoupload') {
        titleController.text = 'Uploaded Video';
        descriptionController.text = 'Uploaded via Flutter app';
      }
    });
  }

  void _cancelAddingContent() {
    setState(() {
      isPopupVisible = false;
      contentController.clear();
      titleController.clear();
      descriptionController.clear();
      _mediaFile = null;
      _uploadStatus = null;
      _uploadProgress = null;
    });
  }

  Widget _buildContentBlock(String blockType, String content) {
    try {
      List<dynamic> parsedContentList =
          content.startsWith('[') ? jsonDecode(content) : [jsonDecode(content)];

      if (blockType == 'HTML') {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children:
              parsedContentList.expand((item) {
                return [
                  if (item is Map && item.containsKey('html'))
                    Html(data: item['html'])
                  else
                    const Text('No HTML content available'),
                  const SizedBox(height: 20),
                ];
              }).toList(),
        );
      } else if (blockType == 'media') {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children:
              parsedContentList.expand((item) {
                if (item is Map && item.containsKey('media')) {
                  String url = item['media'];
                  if (url.contains('youtube.com') || url.contains('youtu.be')) {
                    return [
                      _buildYouTubePlayer(url),
                      const SizedBox(height: 20),
                    ];
                  } else if (url.endsWith('.mp4') ||
                      url.endsWith('.mov') ||
                      url.endsWith('.avi')) {
                    return [
                      _buildCloudinaryVideo(url),
                      const SizedBox(height: 20),
                    ];
                  } else {
                    return [_buildImage(url), const SizedBox(height: 20)];
                  }
                }
                return [
                  const Text('No media content available'),
                  const SizedBox(height: 20),
                ];
              }).toList(),
        );
      } else if (blockType == 'code') {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children:
              parsedContentList.expand((item) {
                return [
                  if (item is Map && item.containsKey('code'))
                    Stack(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          margin: const EdgeInsets.only(top: 10),
                          decoration: BoxDecoration(
                            color: Colors.black,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: HighlightView(
                              item['code'],
                              language: 'html',
                              theme: monokaiSublimeTheme,
                              padding: const EdgeInsets.all(10),
                              textStyle: const TextStyle(
                                fontFamily: 'Courier New',
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          top: 5,
                          right: 5,
                          child: IconButton(
                            icon: const Icon(
                              Icons.copy,
                              color: Colors.white70,
                              size: 18,
                            ),
                            onPressed: () {
                              Clipboard.setData(
                                ClipboardData(text: item['code']),
                              ).then((_) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Code copied to clipboard!'),
                                  ),
                                );
                              });
                            },
                          ),
                        ),
                      ],
                    )
                  else
                    const Text('No code content available'),
                  const SizedBox(height: 20),
                ];
              }).toList(),
        );
      } else {
        return const Text('Unknown content type');
      }
    } catch (e) {
      return Text('Error rendering content: $e');
    }
  }

  Widget _buildYouTubePlayer(String videoUrl) {
    String? videoId = YoutubePlayer.convertUrlToId(videoUrl);
    if (videoId == null || videoId.isEmpty) {
      return const Text('Invalid YouTube URL');
    }

    YoutubePlayerController controller = YoutubePlayerController(
      initialVideoId: videoId,
      flags: const YoutubePlayerFlags(
        autoPlay: false,
        mute: false,
        enableCaption: false,
      ),
    );

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.blue, width: 3),
        borderRadius: BorderRadius.circular(25),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: YoutubePlayer(
          controller: controller,
          showVideoProgressIndicator: true,
          onEnded: (_) => controller.dispose(),
        ),
      ),
    );
  }

  Widget _buildCloudinaryVideo(String videoUrl) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.blue, width: 3),
        borderRadius: BorderRadius.circular(25),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Image.network(
          videoUrl.replaceAll(
            '.mp4',
            '.jpg',
          ), // Use Cloudinary thumbnail for preview
          fit: BoxFit.cover,
          errorBuilder:
              (context, error, stackTrace) =>
                  const Icon(Icons.error, color: Colors.red),
        ),
      ),
    );
  }

  Widget _buildImage(String imageUrl) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: Colors.blue, width: 3),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Image.network(
          imageUrl,
          fit: BoxFit.cover,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Center(
              child: CircularProgressIndicator(
                value:
                    loadingProgress.expectedTotalBytes != null
                        ? loadingProgress.cumulativeBytesLoaded /
                            loadingProgress.expectedTotalBytes!
                        : null,
              ),
            );
          },
          errorBuilder:
              (context, error, stackTrace) =>
                  const Icon(Icons.error, color: Colors.red),
        ),
      ),
    );
  }

  Widget _renderContent(String content) {
    try {
      List<dynamic> contentList =
          content.startsWith('[') ? jsonDecode(content) : [jsonDecode(content)];

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children:
            contentList.map((item) {
              if (item is Map) {
                if (item.containsKey('html')) {
                  return _buildContentBlock('HTML', jsonEncode([item]));
                } else if (item.containsKey('media') ||
                    item.containsKey('imageurl') ||
                    item.containsKey('youtubevideo')) {
                  if (item.containsKey('imageurl'))
                    item['media'] = item['imageurl'];
                  if (item.containsKey('youtubevideo'))
                    item['media'] = item['youtubevideo'];
                  return _buildContentBlock('media', jsonEncode([item]));
                } else if (item.containsKey('code')) {
                  return _buildContentBlock('code', jsonEncode([item]));
                } else {
                  return const Text('Unknown content type');
                }
              } else {
                return const Text('Invalid content format');
              }
            }).toList(),
      );
    } catch (e) {
      return Text('Error rendering content: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.moduleName),
        backgroundColor: Colors.blue,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(25)),
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(25)),
            boxShadow: [
              BoxShadow(
                color: Color.fromARGB(168, 32, 32, 32),
                offset: Offset(0, 5),
                blurRadius: 2,
                spreadRadius: 1.5,
              ),
            ],
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color.fromARGB(255, 66, 165, 245),
                Color.fromARGB(255, 21, 101, 192),
              ],
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          GestureDetector(
            onTap: () => FocusScope.of(context).requestFocus(FocusNode()),
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Card(
                      elevation: 8,
                      shadowColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Center(
                              child: Text(
                                widget.moduleName.toUpperCase(),
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue,
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            const Divider(),
                            const SizedBox(height: 10),
                            const Text(
                              'Current Content: ',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 10),
                            currentContent.isNotEmpty
                                ? _renderContent(currentContent)
                                : const Text(
                                  'No content added yet.',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey,
                                  ),
                                ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    if (isPopupVisible)
                      Card(
                        elevation: 5,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  selectedType == 'videoupload'
                                      ? 'Upload Video'
                                      : selectedType == 'mediaupload'
                                      ? 'Upload Media'
                                      : 'Add ${selectedType.capitalize()} Content',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blueAccent,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                if (selectedType == 'videoupload') ...[
                                  TextFormField(
                                    controller: titleController,
                                    decoration: InputDecoration(
                                      labelText: 'Video Title',
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                    validator: (value) {
                                      if (value == null || value.isEmpty)
                                        return 'Title is required';
                                      if (value.length > 100)
                                        return 'Title must be 100 characters or less';
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 10),
                                  TextFormField(
                                    controller: descriptionController,
                                    decoration: InputDecoration(
                                      labelText: 'Description (Optional)',
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                    maxLines: 3,
                                    validator: (value) {
                                      if (value != null &&
                                          value.length > 5000) {
                                        return 'Description must be 5000 characters or less';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 10),
                                  const Text(
                                    'Note: Use horizontal (16:9) videos longer than 60 seconds for standard format.',
                                    style: TextStyle(
                                      fontStyle: FontStyle.italic,
                                      color: Colors.black54,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 10),
                                  if (_mediaFile != null) ...[
                                    Text(
                                      'Selected: ${_mediaFile!.name}',
                                      style: const TextStyle(
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                  ],
                                  GestureDetector(
                                    onTapDown:
                                        (_) =>
                                            _buttonAnimationController
                                                .forward(),
                                    onTapUp:
                                        (_) =>
                                            _buttonAnimationController
                                                .reverse(),
                                    onTapCancel:
                                        () =>
                                            _buttonAnimationController
                                                .reverse(),
                                    child: ScaleTransition(
                                      scale: _buttonScaleAnimation,
                                      child: ElevatedButton.icon(
                                        onPressed:
                                            _uploadStatus != null &&
                                                    _uploadStatus!.contains(
                                                      'Uploading',
                                                    )
                                                ? null
                                                : _pickVideo,
                                        icon: const Icon(Icons.video_library),
                                        label: const Text('Select Video'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.blueAccent,
                                          foregroundColor: Colors.white,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  if (_uploadStatus != null &&
                                      _uploadStatus!.contains('Uploading')) ...[
                                    const SizedBox(height: 10),
                                    LinearProgressIndicator(
                                      value: _uploadProgress,
                                      backgroundColor: Colors.grey[300],
                                      valueColor: const AlwaysStoppedAnimation(
                                        Colors.blueAccent,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      _uploadProgress != null
                                          ? 'Upload Progress: ${(_uploadProgress! * 100).toStringAsFixed(1)}%'
                                          : 'Uploading...',
                                    ),
                                  ],
                                ] else if (selectedType == 'mediaupload') ...[
                                  Column(
                                    children: [
                                      const Text(
                                        'Note: Supports images, videos, and other files.',
                                        style: TextStyle(
                                          fontStyle: FontStyle.italic,
                                          color: Colors.black54,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                      const SizedBox(height: 10),
                                      if (_mediaFile != null) ...[
                                        Text(
                                          'Selected: ${_mediaFile!.name}',
                                          style: const TextStyle(
                                            fontStyle: FontStyle.italic,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                      ],
                                      GestureDetector(
                                        onTapDown:
                                            (_) =>
                                                _buttonAnimationController
                                                    .forward(),
                                        onTapUp:
                                            (_) =>
                                                _buttonAnimationController
                                                    .reverse(),
                                        onTapCancel:
                                            () =>
                                                _buttonAnimationController
                                                    .reverse(),
                                        child: ScaleTransition(
                                          scale: _buttonScaleAnimation,
                                          child: ElevatedButton.icon(
                                            onPressed:
                                                _uploadStatus != null &&
                                                        _uploadStatus!.contains(
                                                          'Uploading',
                                                        )
                                                    ? null
                                                    : _pickMedia,
                                            icon: const Icon(Icons.upload_file),
                                            label: const Text('Select File'),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor:
                                                  Colors.blueAccent,
                                              foregroundColor: Colors.white,
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                      if (_uploadStatus != null &&
                                          _uploadStatus!.contains(
                                            'Uploading',
                                          )) ...[
                                        const SizedBox(height: 10),
                                        LinearProgressIndicator(
                                          value: _uploadProgress,
                                          backgroundColor: Colors.grey[300],
                                          valueColor:
                                              const AlwaysStoppedAnimation(
                                                Colors.blueAccent,
                                              ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          _uploadProgress != null
                                              ? 'Upload Progress: ${(_uploadProgress! * 100).toStringAsFixed(1)}%'
                                              : 'Uploading...',
                                        ),
                                      ],
                                    ],
                                  ),
                                ] else ...[
                                  TextFormField(
                                    controller: contentController,
                                    decoration: InputDecoration(
                                      labelText:
                                          selectedType == 'html'
                                              ? 'Enter HTML'
                                              : selectedType == 'youtubevideo'
                                              ? 'Enter YouTube URL'
                                              : selectedType == 'code'
                                              ? 'Enter Code'
                                              : '',
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                    maxLines:
                                        selectedType == 'html' ||
                                                selectedType == 'code'
                                            ? 5
                                            : 2,
                                    validator: (value) {
                                      if (value == null || value.isEmpty)
                                        return 'Content cannot be empty';
                                      return null;
                                    },
                                  ),
                                ],
                                const SizedBox(height: 20),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  children: [
                                    TextButton(
                                      onPressed: _cancelAddingContent,
                                      style: TextButton.styleFrom(
                                        foregroundColor: Colors.redAccent,
                                      ),
                                      child: const Text('Cancel'),
                                    ),
                                    const SizedBox(width: 10),
                                    if (selectedType != 'videoupload' &&
                                        selectedType != 'mediaupload')
                                      ElevatedButton(
                                        onPressed: _appendContent,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.blueAccent,
                                          foregroundColor: Colors.white,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                        ),
                                        child: const Text('Save'),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              colors: [
                Colors.blue.shade400,
                Colors.blue.shade800,
                Colors.white,
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showContentTypeSelection,
        backgroundColor: Colors.blue,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  @override
  void dispose() {
    contentController.dispose();
    titleController.dispose();
    descriptionController.dispose();
    _confettiController.dispose();
    _buttonAnimationController.dispose();
    super.dispose();
  }
}

extension StringExtension on String {
  String capitalize() => "${this[0].toUpperCase()}${substring(1)}";
}
