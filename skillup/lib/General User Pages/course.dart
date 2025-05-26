import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/services.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';
import 'dart:convert';
import '/Mentor Pages/quiz.dart';

class CourseContentPage extends StatefulWidget {
  final String courseId;
  const CourseContentPage({super.key, required this.courseId});

  @override
  _CourseContentPageState createState() => _CourseContentPageState();
}

class _CourseContentPageState extends State<CourseContentPage> {
  final DatabaseReference _database = FirebaseDatabase.instance.ref("courses");
  List<Map<String, dynamic>> _modules = [];
  Map<int, bool> _expandedModules = {};
  String courseName = "";
  String courseDescription = "";
  String courseImage = "";
  String courseCategory = "";
  String courseLanguage = "";
  String courseLevel = "";
  String courseDuration = "";
  String coursePrice = "";
  bool _isFullScreen = false;

  // Gradient colors for consistent theming
  final List<Color> _appBarGradient = [
    const Color(0xFF2196F3),
    const Color(0xFF6200EA),
  ];
  final List<Color> _cardGradient = [
    const Color(0xFF2962FF),
    const Color(0xFF7C4DFF),
  ];
  final Color _backgroundColor = const Color(0xFFF8F9FA);

  @override
  void initState() {
    super.initState();
    _fetchCourseData();
    _fetchModules();
  }

  void _fetchCourseData() {
    _database.child(widget.courseId).onValue.listen((event) {
      if (event.snapshot.value != null) {
        Map<dynamic, dynamic> values =
            event.snapshot.value as Map<dynamic, dynamic>;

        setState(() {
          courseName = values["courseId"] ?? "No Name";
          courseDescription = values["description"] ?? "No Description";
          courseImage = values["imageUrl"] ?? "";
          courseCategory = values["category"] ?? "";
          courseLanguage = values["language"] ?? "";
          courseLevel = values["level"] ?? "";
          courseDuration = values["duration"] ?? "";
          coursePrice = values["price"] ?? "";
        });
      }
    });
  }

  void _fetchModules() async {
    User? user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      print("User not logged in!");
      return;
    }

    String userId = user.uid;

    DatabaseReference userRef = FirebaseDatabase.instance.ref("users/$userId");

    userRef.once().then((DatabaseEvent event) {
      Map<dynamic, dynamic>? userData =
          event.snapshot.value as Map<dynamic, dynamic>?;

      if (userData != null) {
        bool membershipPlan =
            userData['membershipPlan'] == 'true' ||
            userData['membershipPlan'] == true;

        _database.child(widget.courseId).child("modules").once().then((event) {
          if (event.snapshot.value != null) {
            Map<dynamic, dynamic> values =
                event.snapshot.value as Map<dynamic, dynamic>;
            List<Map<String, dynamic>> tempModules = [];

            values.forEach((key, value) {
              Map<String, dynamic> moduleData = Map<String, dynamic>.from(
                value,
              );
              int moduleIndex = moduleData["index"] ?? 0;
              String title = moduleData["title"] ?? "No Title";

              List<dynamic> parsedContent = [];
              bool hasPurchased =
                  userData['purchasedCourses'] != null &&
                  userData['purchasedCourses'][widget.courseId] == true;

              if (membershipPlan || hasPurchased) {
                try {
                  parsedContent = json.decode(moduleData["content"]);
                } catch (e) {
                  print("Error parsing content: $e");
                }
              }

              tempModules.add({
                "moduleId": key,
                "heading": title,
                "index": moduleIndex,
                "content":
                    (membershipPlan || hasPurchased) ? parsedContent : null,
                "locked": !(membershipPlan || hasPurchased),
              });
            });

            tempModules.sort((a, b) => a["index"].compareTo(b["index"]));

            setState(() {
              _modules = tempModules;
              _expandedModules = {
                for (var module in tempModules) module["index"]: false,
              };
            });
          }
        });
      }
    });
  }

  void _toggleFullScreen(bool isFullScreen) {
    setState(() {
      _isFullScreen = isFullScreen;
      if (isFullScreen) {
        SystemChrome.setPreferredOrientations([
          DeviceOrientation.landscapeLeft,
          DeviceOrientation.landscapeRight,
        ]);
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
      } else {
        SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      }
    });
  }

  Widget _buildYouTubePlayer(String videoUrl) {
    String? videoId = YoutubePlayerController.convertUrlToId(videoUrl);
    if (videoId == null || videoId.isEmpty) {
      return const Text('Invalid YouTube URL');
    }

    YoutubePlayerController controller = YoutubePlayerController.fromVideoId(
      videoId: videoId,
      autoPlay: false,
      params: const YoutubePlayerParams(
        showControls: true,
        showFullscreenButton: true,
        enableCaption: false,
        strictRelatedVideos: true,
      ),
    );

    // controller.listen((value) {
    //   if (value.isFullScreen != _isFullScreen) {
    //     _toggleFullScreen(value.isFullScreen);
    //   }
    // });

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.blue, width: 3),
        borderRadius: BorderRadius.circular(25),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: YoutubePlayer(
          controller: controller,
          aspectRatio: 16 / 9,
          backgroundColor: Colors.black,
        ),
      ),
    );
  }

  Widget _buildContentBlock(Map<String, dynamic> block) {
    String type = block.keys.first;
    dynamic content = block[type];

    if (type == "html") {
      return Html(data: content);
    } else if (type == "text") {
      return Text(
        content,
        style: TextStyle(
          fontSize: 16,
          color: const Color.fromARGB(255, 58, 58, 58),
          height: 1.5,
        ),
      );
    } else if (type == "youtubevideo") {
      return _buildYouTubePlayer(content);
    } else if (type == "imageurl") {
      return _buildImage(content);
    } else if (type == "code") {
      return _buildCodeBlock(content);
    } else {
      return Text(
        "Unsupported content type",
        style: TextStyle(color: Colors.red),
      );
    }
  }

  Widget _buildImage(String imageUrl) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 6,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.network(
          imageUrl,
          fit: BoxFit.cover,
          loadingBuilder: (context, child, progress) {
            return progress == null
                ? child
                : SizedBox(
                  height: 200,
                  child: Center(
                    child: CircularProgressIndicator(color: _appBarGradient[0]),
                  ),
                );
          },
          errorBuilder:
              (context, error, stackTrace) => Container(
                color: Colors.grey[200],
                child: Center(
                  child: Icon(Icons.broken_image, color: Colors.grey[400]),
                ),
              ),
        ),
      ),
    );
  }

  Widget _buildCodeBlock(String codeContent) {
    return Container(
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 0, 0, 0),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SelectableText(
                codeContent.replaceAll('\\n', '\n'),
                style: TextStyle(
                  fontFamily: 'FiraCode',
                  fontSize: 14,
                  color: const Color.fromARGB(255, 210, 210, 210),
                ),
              ),
            ),
          ),
          Positioned(
            top: 8,
            right: 8,
            child: IconButton(
              icon: Icon(Icons.copy, color: Colors.white70),
              onPressed: () {
                Clipboard.setData(ClipboardData(text: codeContent)).then((_) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Code copied!'),
                      backgroundColor: const Color.fromARGB(255, 255, 255, 255),
                    ),
                  );
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar:
          _isFullScreen
              ? null
              : AppBar(
                title: Text('Modules page of $courseName'),
                backgroundColor: Colors.blue,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(
                    bottom: Radius.circular(25),
                  ),
                ),
                actions: [
                  IconButton(
                    icon: Icon(
                      Icons.quiz,
                      color: const Color.fromARGB(255, 7, 7, 7),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => QuizPage(courseId: courseName),
                        ),
                      );
                    },
                  ),
                ],
                flexibleSpace: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.vertical(
                      bottom: Radius.circular(25),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blue.shade900,
                        offset: Offset(0, 5),
                        blurRadius: 5,
                        spreadRadius: 1.5,
                      ),
                    ],
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.blue.shade400, Colors.blue.shade800],
                    ),
                  ),
                ),
              ),
      body: Container(
        decoration: BoxDecoration(color: _backgroundColor),
        child:
            _modules.isEmpty
                ? Center(
                  child: CircularProgressIndicator(color: _appBarGradient[0]),
                )
                : ListView(
                  padding: EdgeInsets.all(16),
                  children: [
                    _buildCourseHeader(),
                    SizedBox(height: 24),
                    _buildCourseDetails(),
                    SizedBox(height: 32),
                    ..._modules.map(_buildModuleCard),
                  ],
                ),
      ),
    );
  }

  Widget _buildCourseHeader() {
    return Column(
      children: [
        Hero(
          tag: 'course-image-${widget.courseId}',
          child: _buildImage(courseImage),
        ),
        SizedBox(height: 20),
        Text(
          courseDescription,
          style: TextStyle(fontSize: 16, color: Colors.grey[700], height: 1.6),
        ),
      ],
    );
  }

  Widget _buildCourseDetails() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: _cardGradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDetailRow("Category", courseCategory),
          _buildDetailRow("Language", courseLanguage),
          _buildDetailRow("Level", courseLevel),
          _buildDetailRow("Duration", "$courseDuration days"),
          _buildDetailRow("Price", "₹$coursePrice"),
        ],
      ),
    );
  }

  Widget _buildModuleCard(Map<String, dynamic> module) {
    final isExpanded = _expandedModules[module["index"]] ?? false;
    final bool isLocked = module["locked"] ?? false;

    return AnimatedContainer(
      duration: Duration(milliseconds: 300),
      margin: EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 6,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 0,
        child: Column(
          children: [
            ListTile(
              contentPadding: EdgeInsets.symmetric(horizontal: 16),
              title: Row(
                children: [
                  Expanded(
                    child: Text(
                      module["heading"],
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isLocked ? Colors.grey : Colors.blueAccent,
                      ),
                    ),
                  ),
                  if (isLocked) Icon(Icons.lock, color: Colors.red),
                ],
              ),
              trailing: Icon(
                isExpanded ? Icons.expand_less : Icons.expand_more,
                color: isLocked ? Colors.grey : Colors.blueAccent,
              ),
              onTap: () {
                if (isLocked) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("Purchase this course to unlock content."),
                      backgroundColor: Colors.red,
                    ),
                  );
                } else {
                  setState(() {
                    _expandedModules[module["index"]] = !isExpanded;
                  });
                }
              },
            ),
            if (isExpanded && !isLocked)
              Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  children:
                      (module["content"] as List<dynamic>)
                          .map(
                            (block) => Padding(
                              padding: EdgeInsets.only(bottom: 12),
                              child: _buildContentBlock(block),
                            ),
                          )
                          .toList(),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Text(
            "$label: ",
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.white.withOpacity(0.9),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
