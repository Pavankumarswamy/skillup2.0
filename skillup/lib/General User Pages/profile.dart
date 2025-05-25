import 'dart:convert';
import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:custom_image_crop/custom_image_crop.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase;
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:mime/mime.dart';
import 'package:http_parser/http_parser.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shimmer/shimmer.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final firebase.User? user = firebase.FirebaseAuth.instance.currentUser;
  String? _imageUrl;
  String? _username;
  bool _isUploading = false;
  bool _isProfileLoading = true;
  bool _isPostsLoading = true;
  bool _isDialogOpen = false;
  List<Map<String, dynamic>> _userPosts = [];
  final Map<String, Map<String, dynamic>> _postCache = {};

  // Firebase Database references
  final DatabaseReference _userRef = FirebaseDatabase.instance.ref("users");
  final DatabaseReference _postsRef = FirebaseDatabase.instance.ref("posts");
  final DatabaseReference _usersPostsRef = FirebaseDatabase.instance.ref(
    "users_posts",
  );

  // Cloudinary configuration
  static const String cloudName = "dnedosgc6";
  static const String uploadPreset = "ml_default";

  @override
  void initState() {
    super.initState();
    _initializeProfile();
    _setupRealtimePostsListener();
  }

  @override
  void dispose() {
    super.dispose();
  }

  // Initialize user profile and fetch data
  Future<void> _initializeProfile() async {
    if (user == null) {
      setState(() {
        _isProfileLoading = false;
        _isPostsLoading = false;
      });
      return;
    }

    try {
      final snapshot = await _userRef.child(user!.uid).get();
      if (!snapshot.exists) {
        // Create new profile
        await _userRef.child(user!.uid).set({
          'email': user!.email,
          'username':
              user!.email?.split('@')[0] ?? 'user_${user!.uid.substring(0, 6)}',
          'createdAt': ServerValue.timestamp,
        });
      }

      final data = snapshot.value as Map<dynamic, dynamic>?;
      setState(() {
        _imageUrl = data?['profileImage'] as String?;
        _username = data?['username'] as String? ?? user!.email?.split('@')[0];
        _isProfileLoading = false;
      });
    } catch (e) {
      debugPrint('Error initializing profile: $e');
      _showSnackBar('Failed to initialize profile: $e', key: 'profile_error');
      setState(() => _isProfileLoading = false);
    }
  }

  // Setup real-time listener for user posts
  void _setupRealtimePostsListener() {
    if (user == null) {
      setState(() {
        _isPostsLoading = false;
        _userPosts = [];
      });
      return;
    }

    _usersPostsRef
        .child(user!.uid)
        .onValue
        .listen(
          (event) async {
            final prefs = await SharedPreferences.getInstance();
            List<Map<String, dynamic>> newPosts = [];

            if (!event.snapshot.exists || event.snapshot.value == null) {
              setState(() {
                _userPosts = [];
                _isPostsLoading = false;
              });
              await prefs.setString('cached_user_posts_${user!.uid}', '[]');
              return;
            }

            try {
              List<String> postIds = [];
              final snapshotValue = event.snapshot.value;

              if (snapshotValue is Map) {
                final postMap = Map<String, dynamic>.from(snapshotValue);
                postIds = postMap.keys.toList();
              } else if (snapshotValue is List) {
                final postList = snapshotValue;
                for (int i = 0; i < postList.length; i++) {
                  if (postList[i] != null) {
                    postIds.add(i.toString());
                  }
                }
              } else {
                throw Exception(
                  'Unexpected data type: ${snapshotValue.runtimeType}',
                );
              }

              for (var postId in postIds) {
                final postSnapshot = await _postsRef.child(postId).get();
                if (postSnapshot.exists) {
                  try {
                    final postData =
                        jsonDecode(postSnapshot.value as String)
                            as Map<String, dynamic>;
                    postData['timestamp'] =
                        postData['timestamp'] is int
                            ? postData['timestamp']
                            : DateTime.now().millisecondsSinceEpoch;
                    _postCache[postId] = postData;
                    newPosts.add({'postNo': postId, ...postData});
                  } catch (e) {
                    debugPrint('Error parsing post $postId: $e');
                  }
                }
              }

              newPosts.sort(
                (a, b) =>
                    (b['timestamp'] as int).compareTo(a['timestamp'] as int),
              );

              if (newPosts.length > 100) {
                newPosts = newPosts.sublist(0, 100);
              }

              final cachedPostsJson = jsonEncode(newPosts);
              await prefs.setString(
                'cached_user_posts_${user!.uid}',
                cachedPostsJson,
              );

              setState(() {
                _userPosts = newPosts;
                _isPostsLoading = false;
              });
            } catch (e) {
              try {
                final cachedPostsJson =
                    prefs.getString('cached_user_posts_${user!.uid}') ?? '[]';
                final cachedPosts =
                    (jsonDecode(cachedPostsJson) as List<dynamic>)
                        .cast<Map<String, dynamic>>();
                setState(() {
                  _userPosts = cachedPosts;
                  _isPostsLoading = false;
                });
              } catch (cacheError) {
                setState(() {
                  _userPosts = [];
                  _isPostsLoading = false;
                });
              }
              _showSnackBar('Failed to fetch posts: $e', key: 'posts_error');
            }
          },
          onError: (error) {
            SharedPreferences.getInstance().then((prefs) {
              final cachedPostsJson =
                  prefs.getString('cached_user_posts_${user!.uid}') ?? '[]';
              try {
                final cachedPosts =
                    (jsonDecode(cachedPostsJson) as List<dynamic>)
                        .cast<Map<String, dynamic>>();
                setState(() {
                  _userPosts = cachedPosts;
                  _isPostsLoading = false;
                });
              } catch (e) {
                setState(() {
                  _userPosts = [];
                  _isPostsLoading = false;
                });
              }
            });
            _showSnackBar('Failed to fetch posts: $error', key: 'posts_error');
          },
        );
  }

  // Pick image from gallery and navigate to crop screen
  Future<void> _pickImage() async {
    if (_isUploading) {
      _showSnackBar('Upload in progress, please wait', key: 'upload_busy');
      return;
    }

    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);
      if (pickedFile == null) {
        _showSnackBar('No image selected', key: 'image_error');
        return;
      }

      final imageFile = File(pickedFile.path);
      // Navigate to crop screen
      final croppedImage = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CropImageScreen(imageFile: imageFile),
        ),
      );

      if (croppedImage != null && croppedImage is MemoryImage) {
        await _uploadImage(croppedImage);
      } else {
        _showSnackBar('Cropping cancelled', key: 'crop_cancel');
      }
    } catch (e) {
      debugPrint('Image pick error: $e');
      if (mounted) {
        _showSnackBar('Failed to pick image: $e', key: 'image_error');
      }
    }
  }

  // Upload image to Cloudinary
  Future<String?> _uploadToCloudinary(File imageFile) async {
    const maxRetries = 2;
    int attempt = 0;

    while (attempt <= maxRetries) {
      attempt++;
      debugPrint('Cloudinary upload attempt $attempt for ${imageFile.path}');

      try {
        final url = Uri.parse(
          'https://api.cloudinary.com/v1_1/$cloudName/image/upload',
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
            throw Exception('Cloudinary response missing secure_url');
          }
          debugPrint('Upload successful: $imageUrl');
          return imageUrl;
        } else {
          debugPrint('Cloudinary error: ${responseData.body}');
          if (attempt >= maxRetries) {
            throw Exception('Cloudinary upload failed: ${responseData.body}');
          }
        }
      } catch (e) {
        debugPrint('Cloudinary upload error: $e');
        if (attempt >= maxRetries) {
          throw Exception('Upload error after $maxRetries attempts: $e');
        }
        await Future.delayed(const Duration(seconds: 2));
      }
    }
    return null;
  }

  // Upload cropped image and save to Firebase
  Future<void> _uploadImage(MemoryImage croppedImage) async {
    if (user == null) {
      _showSnackBar('User not logged in', key: 'upload_error');
      return;
    }

    setState(() => _isUploading = true);

    try {
      // Convert MemoryImage to File
      final tempDir = await getTemporaryDirectory();
      final tempPath =
          '${tempDir.path}/cropped_image_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final imageFile = File(tempPath);
      await imageFile.writeAsBytes(croppedImage.bytes);

      if (!await imageFile.exists()) {
        throw Exception('Image file does not exist');
      }
      final fileSize = await imageFile.length();
      if (fileSize > 10 * 1024 * 1024) {
        throw Exception('Image size exceeds 10MB limit');
      }

      final imageUrl = await _uploadToCloudinary(imageFile);
      if (imageUrl == null) {
        throw Exception('Failed to upload image to Cloudinary');
      }

      await _userRef.child(user!.uid).update({'profileImage': imageUrl});

      if (mounted) {
        setState(() {
          _imageUrl = imageUrl;
          _isUploading = false;
        });
        _showSnackBar(
          'Profile image uploaded successfully',
          key: 'upload_success',
        );
      }

      // Clean up temporary file
      await imageFile.delete();
    } catch (e) {
      debugPrint('Upload error: $e');
      if (mounted) {
        setState(() => _isUploading = false);
        _showSnackBar('Failed to upload image: $e', key: 'upload_error');
      }
    }
  }

  // Update username
  Future<void> _updateUsername() async {
    if (user == null) return;

    final controller = TextEditingController(text: _username);
    bool isUpdating = false;

    showDialog(
      context: context,
      builder:
          (dialogContext) => StatefulBuilder(
            builder: (dialogContext, setState) {
              return AlertDialog(
                title: const Text('Update Username'),
                content: TextField(
                  controller: controller,
                  decoration: const InputDecoration(
                    labelText: 'Username',
                    hintText: 'Enter new username',
                  ),
                  maxLength: 20,
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(dialogContext),
                    child: const Text('Cancel'),
                  ),
                  ElevatedButton(
                    onPressed:
                        isUpdating
                            ? null
                            : () async {
                              final newUsername = controller.text.trim();
                              if (newUsername.isEmpty ||
                                  newUsername.length < 3) {
                                _showSnackBar(
                                  'Username must be at least 3 characters',
                                  key: 'username_error',
                                );
                                return;
                              }

                              setState(() => isUpdating = true);

                              try {
                                await _userRef.child(user!.uid).update({
                                  'username': newUsername,
                                });
                                if (mounted) {
                                  setState(() {
                                    _username = newUsername;
                                    isUpdating = false;
                                  });
                                  Navigator.pop(dialogContext);
                                  _showSnackBar(
                                    'Username updated successfully',
                                    key: 'username_success',
                                  );
                                }
                              } catch (e) {
                                if (mounted) {
                                  setState(() => isUpdating = false);
                                  _showSnackBar(
                                    'Failed to update username: $e',
                                    key: 'username_error',
                                  );
                                }
                              }
                            },
                    child:
                        isUpdating
                            ? const CircularProgressIndicator()
                            : const Text('Update'),
                  ),
                ],
              );
            },
          ),
    );
  }

  // Logout
  Future<void> _logout() async {
    try {
      await firebase.FirebaseAuth.instance.signOut();
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/login');
      }
    } catch (e) {
      _showSnackBar('Failed to logout: $e', key: 'logout_error');
    }
  }

  // Toggle like
  void _toggleLike(String postId) async {
    if (user == null) {
      _showSnackBar('Please log in to like a post', key: 'auth_error');
      return;
    }

    try {
      final postRef = _postsRef.child(postId);
      final snapshot = await postRef.get();
      if (!snapshot.exists) {
        _showSnackBar('Post no longer exists', key: 'like_error');
        return;
      }

      final postData =
          jsonDecode(snapshot.value as String) as Map<String, dynamic>;
      final likes = Map<String, dynamic>.from(postData['likes'] ?? {});
      bool wasLiked = likes[user!.uid] == true;

      if (wasLiked) {
        likes.remove(user!.uid);
        postData['likeCount'] = (postData['likeCount'] as int? ?? 0) - 1;
      } else {
        likes[user!.uid] = true;
        postData['likeCount'] = (postData['likeCount'] as int? ?? 0) + 1;
      }

      postData['likes'] = likes;
      postData['timestamp'] = ServerValue.timestamp;

      await postRef.set(jsonEncode(postData));

      if (mounted) {
        setState(() {
          final postIndex = _userPosts.indexWhere((p) => p['postNo'] == postId);
          if (postIndex != -1) {
            _userPosts[postIndex] = {'postNo': postId, ...postData};
          }
          _postCache[postId] = postData;
        });
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'cached_user_posts_${user!.uid}',
        jsonEncode(_userPosts),
      );
    } catch (e) {
      if (mounted) {
        _showSnackBar('Failed to toggle like: $e', key: 'like_error');
      }
    }
  }

  // Delete post
  Future<void> _deletePost(String postId) async {
    if (user == null) {
      _showSnackBar('Please log in to delete a post', key: 'auth_error');
      return;
    }

    try {
      // Verify post ownership
      final postRef = _postsRef.child(postId);
      final snapshot = await postRef.get();
      if (!snapshot.exists) {
        _showSnackBar('Post no longer exists', key: 'delete_error');
        return;
      }

      // Remove from posts
      await postRef.remove();

      // Remove from users_posts
      await _usersPostsRef.child(user!.uid).child(postId).remove();

      // Update local state
      if (mounted) {
        setState(() {
          _userPosts.removeWhere((post) => post['postNo'] == postId);
          _postCache.remove(postId);
        });
      }

      // Update cached posts
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'cached_user_posts_${user!.uid}',
        jsonEncode(_userPosts),
      );

      _showSnackBar('Post deleted successfully', key: 'delete_success');
    } catch (e) {
      debugPrint('Post delete error: $e');
      _showSnackBar('Failed to delete post: $e', key: 'delete_error');
    }
  }

  // Show edit post dialog
  void _showEditPostDialog(
    String postId,
    String currentTitle,
    String currentDescription,
    String currentLink,
  ) {
    final titleController = TextEditingController(text: currentTitle);
    final descriptionController = TextEditingController(
      text: currentDescription,
    );
    final linkController = TextEditingController(text: currentLink);
    bool isUpdating = false;

    showDialog(
      context: context,
      builder:
          (dialogContext) => StatefulBuilder(
            builder: (dialogContext, setState) {
              return AlertDialog(
                title: const Text('Edit Post'),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: titleController,
                        decoration: const InputDecoration(
                          labelText: 'Heading',
                          hintText: 'Enter post heading',
                        ),
                        maxLength: 100,
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: descriptionController,
                        decoration: const InputDecoration(
                          labelText: 'Description',
                          hintText: 'Enter post description',
                        ),
                        maxLength: 1000,
                        maxLines: 3,
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: linkController,
                        decoration: const InputDecoration(
                          labelText: 'Link (optional)',
                          hintText: 'Enter a valid URL',
                        ),
                        keyboardType: TextInputType.url,
                      ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(dialogContext),
                    child: const Text('Cancel'),
                  ),
                  ElevatedButton(
                    onPressed:
                        isUpdating
                            ? null
                            : () async {
                              final newTitle = titleController.text.trim();
                              final newDescription =
                                  descriptionController.text.trim();
                              final newLink = linkController.text.trim();

                              // Validation
                              if (newTitle.isEmpty) {
                                _showSnackBar(
                                  'Heading cannot be empty',
                                  key: 'post_validation_error',
                                );
                                return;
                              }
                              if (newLink.isNotEmpty) {
                                final uri = Uri.tryParse(newLink);
                                if (uri == null ||
                                    !uri.hasScheme ||
                                    !['http', 'https'].contains(uri.scheme)) {
                                  _showSnackBar(
                                    'Please enter a valid URL',
                                    key: 'post_validation_error',
                                  );
                                  return;
                                }
                              }

                              setState(() => isUpdating = true);

                              try {
                                await _updatePost(
                                  postId,
                                  newTitle,
                                  newDescription,
                                  newLink,
                                );
                                if (mounted) {
                                  Navigator.pop(dialogContext);
                                  _showSnackBar(
                                    'Post updated successfully',
                                    key: 'post_update_success',
                                  );
                                }
                              } catch (e) {
                                if (mounted) {
                                  setState(() => isUpdating = false);
                                  _showSnackBar(
                                    'Failed to update post: $e',
                                    key: 'post_update_error',
                                  );
                                }
                              }
                            },
                    child:
                        isUpdating
                            ? const CircularProgressIndicator()
                            : const Text('Update'),
                  ),
                ],
              );
            },
          ),
    );
  }

  // Update post in Firebase
  Future<void> _updatePost(
    String postId,
    String newTitle,
    String newDescription,
    String newLink,
  ) async {
    if (user == null) {
      throw Exception('User not logged in');
    }

    try {
      final postRef = _postsRef.child(postId);
      final snapshot = await postRef.get();
      if (!snapshot.exists) {
        throw Exception('Post no longer exists');
      }

      final postData =
          jsonDecode(snapshot.value as String) as Map<String, dynamic>;
      if (postData['uid'] != user!.uid) {
        throw Exception('Unauthorized: You can only edit your own posts');
      }

      // Update fields
      postData['title'] = newTitle;
      postData['description'] = newDescription;
      postData['link'] = newLink;
      postData['timestamp'] = ServerValue.timestamp;

      // Save to Firebase
      await postRef.set(jsonEncode(postData));

      // Update local state
      if (mounted) {
        setState(() {
          final postIndex = _userPosts.indexWhere((p) => p['postNo'] == postId);
          if (postIndex != -1) {
            _userPosts[postIndex] = {'postNo': postId, ...postData};
          }
          _postCache[postId] = postData;
        });
      }

      // Update cached posts
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'cached_user_posts_${user!.uid}',
        jsonEncode(_userPosts),
      );
    } catch (e) {
      debugPrint('Post update error: $e');
      throw Exception('Failed to update post: $e');
    }
  }

  // Show comments dialog
  void _showComments(String postId, String username) {
    TextEditingController commentController = TextEditingController();
    bool isSubmitting = false;

    setState(() => _isDialogOpen = true);

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
                        return const Center(child: Text('No comments yet'));
                      }

                      final postData =
                          jsonDecode(snapshot.data!.snapshot.value as String)
                              as Map<String, dynamic>;
                      final comments = Map<String, dynamic>.from(
                        postData['comments'] ?? {},
                      );
                      List<Map<String, dynamic>> commentList =
                          comments.entries.map((e) {
                            return {
                              'commentId': e.key,
                              'username': e.value['username'] ?? 'anonymous',
                              'text': e.value['text'] ?? '',
                              'timestamp':
                                  e.value['timestamp'] is int
                                      ? e.value['timestamp']
                                      : DateTime.now().millisecondsSinceEpoch,
                            };
                          }).toList();

                      commentList.sort(
                        (a, b) =>
                            (a['timestamp'] as int).compareTo(b['timestamp']),
                      );

                      return Column(
                        children: [
                          const Text(
                            'Comments',
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
                                                comment['username'][0]
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
                                                comment['username'],
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
                                          comment['text'],
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
                              labelText: 'Add a comment',
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
                                  this.setState(() => _isDialogOpen = false);
                                },
                                child: const Text('Close'),
                              ),
                              ElevatedButton(
                                onPressed:
                                    isSubmitting
                                        ? null
                                        : () async {
                                          if (commentController.text.isEmpty) {
                                            _showSnackBar(
                                              'Comment cannot be empty',
                                              key: 'comment_error',
                                            );
                                            return;
                                          }

                                          if (user == null) {
                                            _showSnackBar(
                                              'Please log in to comment',
                                              key: 'auth_error',
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
                                                'Post no longer exists',
                                                key: 'comment_error',
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
                                                  postData['comments'] ?? {},
                                                );
                                            final commentId =
                                                DateTime.now()
                                                    .millisecondsSinceEpoch
                                                    .toString();
                                            comments[commentId] = {
                                              'text': commentController.text,
                                              'username':
                                                  _username ?? 'anonymous',
                                              'timestamp':
                                                  ServerValue.timestamp,
                                            };

                                            postData['comments'] = comments;
                                            postData['timestamp'] =
                                                ServerValue.timestamp;

                                            await postRef.set(
                                              jsonEncode(postData),
                                            );
                                            commentController.clear();
                                            setState(() {});
                                          } catch (e) {
                                            _showSnackBar(
                                              'Failed to add comment: $e',
                                              key: 'comment_error',
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
                                        : const Text('Submit'),
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
    ).then((_) => setState(() => _isDialogOpen = false));
  }

  // Share post
  Future<void> _sharePost(
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
        _showSnackBar('Post no longer exists', key: 'share_error');
        return;
      }

      final postData =
          jsonDecode(snapshot.value as String) as Map<String, dynamic>;
      postData['shareCount'] = (postData['shareCount'] as int? ?? 0) + 1;
      postData['timestamp'] = ServerValue.timestamp;

      await postRef.set(jsonEncode(postData));

      if (mounted) {
        setState(() {
          final postIndex = _userPosts.indexWhere((p) => p['postNo'] == postId);
          if (postIndex != -1) {
            _userPosts[postIndex] = {'postNo': postId, ...postData};
          }
          _postCache[postId] = postData;
        });
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'cached_user_posts_${user!.uid}',
        jsonEncode(_userPosts),
      );

      final shareText =
          description.isNotEmpty
              ? link.isNotEmpty
                  ? '$description\nCheck out this post: $link'
                  : description
              : link.isNotEmpty
              ? 'Check out this post: $link'
              : 'Check out this post by $username!';

      if (imageUrls.isNotEmpty) {
        final imageFile = await _downloadImage(imageUrls[0]);
        if (imageFile != null) {
          await Share.shareXFiles([XFile(imageFile.path)], text: shareText);
          await imageFile.delete();
        } else {
          await Share.share(shareText);
          if (mounted) {
            _showSnackBar(
              'Failed to download image, sharing text only',
              key: 'share_error',
            );
          }
        }
      } else {
        await Share.share(shareText);
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Failed to share post: $e', key: 'share_error');
      }
    }
  }

  // Download image for sharing
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

  // Show image gallery
  void _showImageGallery(
    BuildContext context,
    List<String> imageUrls,
    int initialIndex,
  ) {
    setState(() => _isDialogOpen = true);

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
                    setState(() => _isDialogOpen = false);
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
    ).then((_) => setState(() => _isDialogOpen = false));
  }

  // Show snackbar
  void _showSnackBar(String message, {required String key}) {
    if (!mounted) return;
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

  // Build post skeleton
  Widget _buildPostSkeleton() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 120,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              const SizedBox(height: 8),
              Container(height: 14, width: 100, color: Colors.white),
              const SizedBox(height: 4),
              Container(height: 10, width: 150, color: Colors.white),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
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

  // Build post card
  Widget _buildPostCard(Map<String, dynamic> post) {
    final postId = post['postNo'] as String? ?? '';
    final username = post['username'] as String? ?? 'anonymous';
    final imageUrls = List<String>.from(post['imageUrls'] ?? []);
    final title = post['title'] as String? ?? '';
    final description = post['description'] as String? ?? '';
    final link = post['link'] as String? ?? '';
    final likeCount = post['likeCount'] as int? ?? 0;
    final comments = Map<String, dynamic>.from(post['comments'] ?? {});
    final shareCount = post['shareCount'] as int? ?? 0;
    final postUid = post['uid'] as String? ?? '';

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
                                '+${imageUrls.length - 4}',
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
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: Colors.blue.shade100,
                  backgroundImage:
                      _imageUrl != null ? NetworkImage(_imageUrl!) : null,
                  child:
                      _imageUrl == null
                          ? Text(
                            username.isNotEmpty
                                ? username[0].toUpperCase()
                                : '?',
                            style: TextStyle(
                              color: Colors.blue.shade900,
                              fontWeight: FontWeight.bold,
                            ),
                          )
                          : null,
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
                if (true) ...[
                  IconButton(
                    icon: Icon(
                      Icons.edit,
                      color: Colors.blue.shade600,
                      size: 20,
                    ),
                    onPressed:
                        () => _showEditPostDialog(
                          postId,
                          title,
                          description,
                          link,
                        ),
                    tooltip: 'Edit Post',
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.delete,
                      color: Colors.red.shade600,
                      size: 20,
                    ),
                    onPressed:
                        () => showDialog(
                          context: context,
                          builder:
                              (context) => AlertDialog(
                                title: const Text('Delete Post'),
                                content: const Text(
                                  'Are you sure you want to delete this post?',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text('Cancel'),
                                  ),
                                  TextButton(
                                    onPressed: () async {
                                      Navigator.pop(context);
                                      await _deletePost(postId);
                                    },
                                    child: const Text(
                                      'Delete',
                                      style: TextStyle(color: Colors.red),
                                    ),
                                  ),
                                ],
                              ),
                        ),
                    tooltip: 'Delete Post',
                  ),
                ],
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
                    _showSnackBar('Cannot open link', key: 'link_error');
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
                      postData['likes'] ?? {},
                    );
                    isLiked = likes[user?.uid ?? ''] == true;
                    currentLikeCount = postData['likeCount'] as int? ?? 0;
                    currentCommentCount =
                        (postData['comments'] as Map<dynamic, dynamic>?)
                            ?.length ??
                        0;
                    currentShareCount = postData['shareCount'] as int? ?? 0;
                  } catch (e) {
                    debugPrint('Error parsing post data: $e');
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
                        '$currentLikeCount Likes',
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
                        '$currentCommentCount Comments',
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
                        '$currentShareCount Shares',
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
    return WillPopScope(
      onWillPop:
          () async => !_isUploading, // Prevent back navigation during upload
      child: Scaffold(
        body:
            _isProfileLoading
                ? const Center(child: CircularProgressIndicator())
                : Stack(
                  children: [
                    SafeArea(
                      child: CustomScrollView(
                        slivers: [
                          SliverAppBar(
                            expandedHeight: 200,
                            floating: false,
                            pinned: true,
                            flexibleSpace: FlexibleSpaceBar(
                              background: Stack(
                                fit: StackFit.expand,
                                children: [
                                  _imageUrl != null
                                      ? CachedNetworkImage(
                                        imageUrl: _imageUrl!,
                                        fit: BoxFit.cover,
                                        placeholder:
                                            (context, url) =>
                                                Shimmer.fromColors(
                                                  baseColor: Colors.grey[300]!,
                                                  highlightColor:
                                                      Colors.grey[100]!,
                                                  child: Container(
                                                    color: Colors.grey[200],
                                                  ),
                                                ),
                                        errorWidget:
                                            (context, url, error) => Container(
                                              color: Colors.grey[200],
                                              child: const Icon(
                                                Icons.error,
                                                color: Colors.red,
                                              ),
                                            ),
                                      )
                                      : Container(color: Colors.grey[300]),
                                  Positioned(
                                    bottom: 10,
                                    right: 10,
                                    child: GestureDetector(
                                      onTap: _pickImage,
                                      child: Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: Colors.blue.shade800,
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.camera_alt,
                                          color: Colors.white,
                                          size: 20,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: GestureDetector(
                                          onTap: _updateUsername,
                                          child: Text(
                                            _username ?? 'Set Username',
                                            style: GoogleFonts.roboto(
                                              fontSize: 24,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.blue.shade900,
                                            ),
                                          ),
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(
                                          Icons.logout,
                                          color: Colors.red,
                                        ),
                                        onPressed: _logout,
                                        tooltip: 'Logout',
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    user?.email ?? 'No email',
                                    style: GoogleFonts.roboto(
                                      fontSize: 16,
                                      color: Colors.blue.shade700,
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  Text(
                                    'My Posts',
                                    style: GoogleFonts.roboto(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blue.shade900,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                ],
                              ),
                            ),
                          ),
                          _isPostsLoading
                              ? SliverPadding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                ),
                                sliver: SliverGrid(
                                  gridDelegate:
                                      const SliverGridDelegateWithFixedCrossAxisCount(
                                        crossAxisCount: 2,
                                        crossAxisSpacing: 8,
                                        mainAxisSpacing: 8,
                                        childAspectRatio: 0.75,
                                      ),
                                  delegate: SliverChildBuilderDelegate(
                                    (context, index) => _buildPostSkeleton(),
                                    childCount: 4,
                                  ),
                                ),
                              )
                              : _userPosts.isEmpty
                              ? SliverToBoxAdapter(
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Text(
                                    'No posts yet',
                                    style: TextStyle(
                                      color: Colors.blue.shade900,
                                    ),
                                  ),
                                ),
                              )
                              : SliverPadding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                ),
                                sliver: SliverList(
                                  delegate: SliverChildBuilderDelegate((
                                    context,
                                    index,
                                  ) {
                                    try {
                                      return _buildPostCard(_userPosts[index]);
                                    } catch (e) {
                                      return Padding(
                                        padding: const EdgeInsets.all(16),
                                        child: Text(
                                          'Error loading post: $e',
                                          style: TextStyle(
                                            color: Colors.red.shade700,
                                          ),
                                        ),
                                      );
                                    }
                                  }, childCount: _userPosts.length),
                                ),
                              ),
                          const SliverToBoxAdapter(child: SizedBox(height: 98)),
                        ],
                      ),
                    ),
                    if (_isUploading)
                      Container(
                        color: Colors.black.withOpacity(0.5),
                        child: const Center(child: CircularProgressIndicator()),
                      ),
                  ],
                ),
      ),
    );
  }
}

class CropImageScreen extends StatefulWidget {
  final File imageFile;

  const CropImageScreen({super.key, required this.imageFile});

  @override
  _CropImageScreenState createState() => _CropImageScreenState();
}

class _CropImageScreenState extends State<CropImageScreen> {
  late CustomImageCropController controller;

  @override
  void initState() {
    super.initState();
    controller = CustomImageCropController();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Crop Profile Picture'),
        backgroundColor: Colors.blue.shade800,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Expanded(
            child: CustomImageCrop(
              cropController: controller,
              image: FileImage(widget.imageFile),
              shape: CustomCropShape.Circle,
              ratio: Ratio(
                width: 1,
                height: 1,
              ), // Square crop for profile picture
              canRotate: true,
              canMove: true,
              canScale: true,
              borderRadius: 4,
              customProgressIndicator: const CupertinoActivityIndicator(),
              outlineColor: Colors.blue,
              imageFit: CustomImageFit.fillCropSpace,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                IconButton(
                  icon: const Icon(Icons.refresh, color: Colors.blue),
                  onPressed: controller.reset,
                  tooltip: 'Reset',
                ),
                IconButton(
                  icon: const Icon(Icons.zoom_in, color: Colors.blue),
                  onPressed:
                      () =>
                          controller.addTransition(CropImageData(scale: 1.33)),
                  tooltip: 'Zoom In',
                ),
                IconButton(
                  icon: const Icon(Icons.zoom_out, color: Colors.blue),
                  onPressed:
                      () =>
                          controller.addTransition(CropImageData(scale: 0.75)),
                  tooltip: 'Zoom Out',
                ),
                IconButton(
                  icon: const Icon(Icons.rotate_left, color: Colors.blue),
                  onPressed:
                      () => controller.addTransition(
                        CropImageData(angle: -0.7854),
                      ), // -45 degrees
                  tooltip: 'Rotate Left',
                ),
                IconButton(
                  icon: const Icon(Icons.rotate_right, color: Colors.blue),
                  onPressed:
                      () => controller.addTransition(
                        CropImageData(angle: 0.7854),
                      ), // +45 degrees
                  tooltip: 'Rotate Right',
                ),
                ElevatedButton.icon(
                  onPressed: () async {
                    final image = await controller.onCropImage();
                    if (image != null) {
                      Navigator.pop(context, image);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Failed to crop image')),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade600,
                    foregroundColor: Colors.white,
                  ),
                  icon: const Icon(Icons.crop),
                  label: const Text('Crop'),
                ),
              ],
            ),
          ),
          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }
}
