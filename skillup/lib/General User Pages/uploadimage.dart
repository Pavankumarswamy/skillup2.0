import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:path/path.dart';
import 'package:flutter/services.dart';

class UploadImagePage extends StatefulWidget {
  const UploadImagePage({super.key});

  @override
  _UploadImagePageState createState() => _UploadImagePageState();
}

class _UploadImagePageState extends State<UploadImagePage> {
  File? _image;
  bool _isUploading = false;
  String? _imageUrl;

  final ImagePicker _picker = ImagePicker();
  final SupabaseClient supabase = Supabase.instance.client;

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    }
  }

  Future<void> _uploadImage() async {
    if (_image == null) return;

    setState(() {
      _isUploading = true;
    });

    try {
      final String fileName = basename(_image!.path);
      final String filePath = 'uploads/$fileName';

      await supabase.storage.from('image').upload(filePath, _image!);
      final String imageUrl =
          supabase.storage.from('image').getPublicUrl(filePath);

      setState(() {
        _imageUrl = imageUrl;
      });

      ScaffoldMessenger.of(context as BuildContext).showSnackBar(
        SnackBar(content: Text('Upload Successful!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context as BuildContext).showSnackBar(
        SnackBar(content: Text('Upload Failed: $e')),
      );
    }

    setState(() {
      _isUploading = false;
    });
  }

  void _copyToClipboard() {
    if (_imageUrl != null) {
      Clipboard.setData(ClipboardData(text: _imageUrl!));
      ScaffoldMessenger.of(context as BuildContext).showSnackBar(
        SnackBar(content: Text('Link copied to clipboard!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Upload Image to Supabase')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _image != null
                ? Image.file(_image!, height: 200)
                : Text('No image selected'),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _pickImage,
              child: Text('Pick Image'),
            ),
            SizedBox(height: 20),
            _isUploading
                ? CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: _uploadImage,
                    child: Text('Upload Image'),
                  ),
            SizedBox(height: 20),
            _imageUrl != null
                ? Column(
                    children: [
                      Text('Uploaded Image:'),
                      SizedBox(height: 10),
                      Image.network(_imageUrl!, height: 200),
                      SizedBox(height: 10),
                      SelectableText(_imageUrl!, textAlign: TextAlign.center),
                      SizedBox(height: 10),
                      ElevatedButton(
                        onPressed: _copyToClipboard,
                        child: Text('Copy Link'),
                      ),
                    ],
                  )
                : Container(),
          ],
        ),
      ),
    );
  }
}
