import 'dart:io';
import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import 'package:gal/gal.dart';
import 'package:permission_handler/permission_handler.dart';

class ImageViewerScreen extends StatelessWidget {
  final String imagePath;
  const ImageViewerScreen({super.key, required this.imagePath});

  Future<void> _saveImage(BuildContext context) async {
    try {
      if (imagePath.startsWith('http')) {
        final bytes = await HttpClient()
            .getUrl(Uri.parse(imagePath))
            .then((request) => request.close())
            .then((response) => response.fold<List<int>>([], (a, b) => a..addAll(b)));
        final tempDir = await Directory.systemTemp.createTemp();
        final tempFile = File('${tempDir.path}/image.jpg');
        await tempFile.writeAsBytes(bytes);
        await Gal.putImage(tempFile.path);
      } else {
        await Gal.putImage(imagePath);
      }
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('图片已保存到相册')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('保存失败，请检查权限')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: () => _saveImage(context),
          ),
        ],
      ),
      body: Center(
        child: PhotoView(
          imageProvider: imagePath.startsWith('http')
              ? NetworkImage(imagePath)
              : FileImage(File(imagePath)) as ImageProvider,
          minScale: PhotoViewComputedScale.contained,
          maxScale: PhotoViewComputedScale.covered * 3,
        ),
      ),
    );
  }
}
