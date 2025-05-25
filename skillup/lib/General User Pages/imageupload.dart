import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';

class CloudinaryUploadPage extends StatefulWidget {
  const CloudinaryUploadPage({super.key});

  @override
  _CloudinaryUploadPageState createState() => _CloudinaryUploadPageState();
}

class _CloudinaryUploadPageState extends State<CloudinaryUploadPage> {
  File? _imageFile;
  String? _uploadedImageUrl;
  bool _isUploading = false;

  final ImagePicker picker = ImagePicker();

  Future<void> _pickImage() async {
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
        _uploadedImageUrl = null;
      });
    }
  }

  Future<void> _uploadToCloudinary(File imageFile) async {
    setState(() {
      _isUploading = true;
    });

    const cloudName = "dnedosgc6";
    const uploadPreset = "ml_default"; // unsigned preset

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
                      : null,
            ),
          );

    try {
      final response = await request.send();

      if (response.statusCode == 200) {
        final responseData = await http.Response.fromStream(response);
        final imageUrl = RegExp(
          r'"secure_url":"(.*?)"',
        ).firstMatch(responseData.body)?.group(1)?.replaceAll(r'\/', '/');

        setState(() {
          _uploadedImageUrl = imageUrl;
        });
      } else {
        print('Failed to upload: ${response.statusCode}');
        final errorBody = await response.stream.bytesToString();
        print('Error details: $errorBody');
      }
    } catch (e) {
      print('Upload error: $e');
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Upload to Cloudinary')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _imageFile != null
                  ? Image.file(_imageFile!, height: 200)
                  : Icon(Icons.image, size: 100, color: Colors.grey),
              SizedBox(height: 20),
              ElevatedButton(onPressed: _pickImage, child: Text('Pick Image')),
              SizedBox(height: 20),
              if (_imageFile != null && !_isUploading)
                ElevatedButton(
                  onPressed: () => _uploadToCloudinary(_imageFile!),
                  child: Text('Upload to Cloudinary'),
                ),
              if (_isUploading) CircularProgressIndicator(),
              if (_uploadedImageUrl != null) ...[
                SizedBox(height: 20),
                Text(
                  'Uploaded Image:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Image.network(_uploadedImageUrl!),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
