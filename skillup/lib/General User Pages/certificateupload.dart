import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SearchAndUploadPage extends StatefulWidget {
  const SearchAndUploadPage({super.key});

  @override
  _SearchAndUploadPageState createState() => _SearchAndUploadPageState();
}

class _SearchAndUploadPageState extends State<SearchAndUploadPage> {
  final DatabaseReference _usersRef =
      FirebaseDatabase.instance.ref().child('users');
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _certKeyController = TextEditingController();
  List<Map<String, dynamic>> _allUsers = [];
  List<Map<String, dynamic>> _filteredUsers = [];
  bool _isLoading = false;
  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();
  final SupabaseClient supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    _fetchAllUsers();
    _searchController.addListener(_filterUsers);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _certKeyController.dispose();
    super.dispose();
  }

  Future<void> _fetchAllUsers() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final snapshot = await _usersRef.get();
      if (snapshot.exists && snapshot.value != null) {
        final data = Map<String, dynamic>.from(snapshot.value as Map);
        _allUsers = [];
        data.forEach((userId, userData) {
          final userMap = Map<String, dynamic>.from(userData as Map);
          userMap['userId'] = userId;
          _allUsers.add(userMap);
        });
        _filteredUsers = List.from(_allUsers);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching users: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _filterUsers() {
    final query = _searchController.text.toLowerCase();
    if (query.isEmpty) {
      setState(() {
        _filteredUsers = List.from(_allUsers);
      });
    } else {
      setState(() {
        _filteredUsers = _allUsers
            .where((user) => (user['email'] != null &&
                (user['email'] as String).toLowerCase().contains(query)))
            .toList();
      });
    }
  }

  Future<void> _pickImage() async {
    final XFile? pickedFile =
        await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  Future<String?> _uploadImage(String userId) async {
    if (_selectedImage == null) return null;

    try {
      final fileName = '$userId-${DateTime.now().millisecondsSinceEpoch}.png';
      await supabase.storage
          .from('image') // Ensure this matches your bucket name
          .upload(fileName, _selectedImage!, fileOptions: const FileOptions());

      final publicUrl = supabase.storage.from('image').getPublicUrl(fileName);
      return publicUrl;
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error uploading image: $e')),
      );
      return null;
    }
  }

  Future<void> _updateUserCertificate(String userId, String imageUrl) async {
    try {
      final userCertificatesRef = _usersRef.child(userId).child('certificates');

      // Show dialog to get custom key name
      final String? customKey = await _showCertificateKeyDialog();
      if (customKey == null || customKey.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Certificate key cannot be empty')),
        );
        return;
      }

      // Check if the key already exists
      final snapshot = await userCertificatesRef.child(customKey).get();
      if (snapshot.exists) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Certificate "$customKey" already exists')),
        );
        return;
      }

      // Save with custom key
      await userCertificatesRef.child(customKey).set(imageUrl);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Certificate updated successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating certificate: $e')),
      );
    }
  }

  Future<String?> _showCertificateKeyDialog() async {
    _certKeyController.clear();
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Enter Certificate Name'),
        content: TextField(
          controller: _certKeyController,
          decoration: const InputDecoration(
            hintText: 'e.g., Web Development Certificate',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () =>
                Navigator.pop(context, _certKeyController.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleUserSelection(Map<String, dynamic> user) async {
    await _pickImage();
    if (_selectedImage == null) return;

    setState(() {
      _isLoading = true;
    });

    final userId = user['userId'];
    final imageUrl = await _uploadImage(userId);
    if (imageUrl != null) {
      await _updateUserCertificate(userId, imageUrl);
    }

    setState(() {
      _selectedImage = null;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Search Users & Upload Certificate'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchAllUsers,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search user emails...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: _filteredUsers.isEmpty
                      ? const Center(child: Text('No users found.'))
                      : ListView.builder(
                          itemCount: _filteredUsers.length,
                          itemBuilder: (context, index) {
                            final user = _filteredUsers[index];
                            return ListTile(
                              title: Text(user['email'] ?? ''),
                              subtitle: Text('UserID: ${user['userId']}'),
                              onTap: () => _handleUserSelection(user),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}
