import '/Mentor%20Pages/quiz.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/services.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'dart:convert';

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
    User? user = FirebaseAuth.instance.currentUser; // Get current user

    if (user == null) {
      print("User not logged in!");
      return;
    }

    String userId = user.uid; // Get user ID from Firebase Auth

    DatabaseReference userRef = FirebaseDatabase.instance.ref("users/$userId");

    userRef.once().then((DatabaseEvent event) {
      Map<dynamic, dynamic>? userData =
          event.snapshot.value as Map<dynamic, dynamic>?;

      if (userData != null) {
        bool membershipPlan =
            userData['membershipPlan'] == 'true' ||
            userData['membershipPlan'] == true;

        // Fetch module names regardless of purchase status
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

              // If the user has a membership plan, show the content
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
                    (membershipPlan || hasPurchased)
                        ? parsedContent
                        : null, // Show content only if purchased or with membership
                "locked":
                    !(membershipPlan ||
                        hasPurchased), // Lock the module if not purchased or not having membership
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
        // Allow landscape for full-screen
        SystemChrome.setPreferredOrientations([
          DeviceOrientation.landscapeLeft,
          DeviceOrientation.landscapeRight,
        ]);
        // Hide system UI for immersive experience
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
      } else {
        // Restore portrait on exit
        SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
        // Show system UI
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      }
    });
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
      String? videoId = YoutubePlayer.convertUrlToId(content);
      if (videoId == null || videoId.isEmpty) {
        return Text(
          "Invalid YouTube video URL",
          style: TextStyle(color: Colors.red),
        );
      }
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: YoutubePlayerWidget(
          videoId: videoId,
          onFullScreenToggle: _toggleFullScreen,
        ),
      );
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
                  if (isLocked)
                    Icon(Icons.lock, color: Colors.red), // Lock icon if locked
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

class YoutubePlayerWidget extends StatefulWidget {
  final String videoId;
  final Function(bool) onFullScreenToggle;

  const YoutubePlayerWidget({
    super.key,
    required this.videoId,
    required this.onFullScreenToggle,
  });

  @override
  _YoutubePlayerWidgetState createState() => _YoutubePlayerWidgetState();
}

class _YoutubePlayerWidgetState extends State<YoutubePlayerWidget> {
  late YoutubePlayerController _controller;
  bool _lastFullScreenState = false;

  @override
  void initState() {
    super.initState();
    _controller = YoutubePlayerController(
      initialVideoId: widget.videoId,
      flags: YoutubePlayerFlags(
        autoPlay: false,
        disableDragSeek: true,
        enableCaption: false,
        showLiveFullscreenButton: true,
      ),
    );
  }

  void _handleFullScreenChange(bool isFullScreen) {
    if (isFullScreen != _lastFullScreenState) {
      _lastFullScreenState = isFullScreen;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        widget.onFullScreenToggle(isFullScreen);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: _controller,
      builder: (context, YoutubePlayerValue value, child) {
        if (value.isReady) {
          _handleFullScreenChange(value.isFullScreen);
        }
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
            child: YoutubePlayer(
              controller: _controller,
              showVideoProgressIndicator: true,
              progressColors: ProgressBarColors(
                playedColor: Colors.blueAccent,
                handleColor: Colors.blueAccent[400]!,
              ),
              aspectRatio: 16 / 9,
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
