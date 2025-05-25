import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';

class ImageUrlInput extends StatefulWidget {
  final TextEditingController controller;
  final Function(String) onChanged;

  const ImageUrlInput({
    required this.controller,
    required this.onChanged,
    super.key,
  });

  @override
  _ImageUrlInputState createState() => _ImageUrlInputState();
}

class _ImageUrlInputState extends State<ImageUrlInput> {
  void _openPopup(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          child: SizedBox(
            width: MediaQuery.of(context).size.width * 0.9,
            height: MediaQuery.of(context).size.height * 0.8,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Upload Image', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    child: Html(data: '<iframe src="https://cetmock.42web.io/upload-image/" width="100%" height="600px" style="border:none;"></iframe>'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: widget.controller,
          decoration: const InputDecoration(labelText: 'Image URL'),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter an image URL';
            }
            return null;
          },
          onChanged: widget.onChanged,
        ),
        const SizedBox(height: 10),
        ElevatedButton(
          onPressed: () => _openPopup(context),
          child: const Text('Upload Image'),
        ),
        const SizedBox(height: 15),
      ],
    );
  }
}
