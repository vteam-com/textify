import 'dart:convert';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pasteboard/pasteboard.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../widgets/image_viewer.dart';
import 'debouce.dart';
import 'panel_content.dart';

class ImageSourceClipboard extends StatefulWidget {
  const ImageSourceClipboard({
    super.key,
    required this.transformationController,
    required this.onImageChanged,
  });

  final Function(ui.Image?) onImageChanged;
  final TransformationController transformationController;

  @override
  State<ImageSourceClipboard> createState() => _ImageSourceClipboardState();
}

class _ImageSourceClipboardState extends State<ImageSourceClipboard> {
  ui.Image? _image;

  @override
  void initState() {
    super.initState();
    _loadSavedImage();
  }

  @override
  Widget build(BuildContext context) {
    return PanelContent(
      // Paste button
      start: IconButton(
        icon: const Icon(Icons.paste),
        onPressed: () async {
          final Uint8List? bytes = await Pasteboard.image;
          if (bytes != null) {
            if (context.mounted) {
              _clipboardToImage(context, bytes);
            }
          } else {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('No image found in clipboard.'),
                ),
              );
            }
          }
        },
      ),
      // Display image
      middle: _buildDisplayImage(),
      // Clear button
      end: IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () async {
          if (mounted) {
            await _updateImageFromBytes(Uint8List(0));
            setState(() {});
          }
          widget.onImageChanged(null); // Notify image cleared
        },
      ),
    );
  }

  Widget _buildDisplayImage() {
    return _image == null
        ? const Center(child: Text('No image pasted'))
        : InteractiveViewer(
            transformationController: widget.transformationController,
            constrained: false,
            minScale: 0.1,
            maxScale: 50,
            child: ImageViewer(
              image: _image!,
            ),
          );
  }

  void _clipboardToImage(
    final BuildContext context,
    final Uint8List bytes,
  ) async {
    try {
      // Update state with image bytes from clipboard
      await _updateImageFromBytes(bytes);
      setState(() {});

      // Notify the widget's parent about the image change
      widget.onImageChanged(_image);

      // Save the image bytes to SharedPreferences
      await _saveImageToPrefs(bytes);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to decode image from clipboard.'),
          ),
        );
      }
    }
  }

  Future<void> _loadSavedImage() async {
    final prefs = await SharedPreferences.getInstance();
    final String? savedImage = prefs.getString('clipboard_image');
    if (savedImage != null) {
      final Uint8List savedImageBytes = base64Decode(savedImage);
      await _updateImageFromBytes(savedImageBytes);
      setState(() {});
      widget.onImageChanged(_image);
    }
  }

  Future<void> _saveImageToPrefs(Uint8List bytes) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('clipboard_image', base64Encode(bytes));
  }

  Future<void> _updateImageFromBytes(Uint8List bytes) async {
    if (bytes.isEmpty) {
      _image = null;
    } else {
      _image = await fromBytesToImage(bytes);
    }
  }
}
