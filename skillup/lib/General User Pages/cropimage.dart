// Crop Image Screen using custom_image_crop
import 'dart:io';

import 'package:custom_image_crop/custom_image_crop.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

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
