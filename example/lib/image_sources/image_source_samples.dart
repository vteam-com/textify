import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'debouce.dart';
import 'panel_content.dart';

class ImageSourceSamples extends StatefulWidget {
  const ImageSourceSamples({
    super.key,
    required this.transformationController,
    required this.onImageChanged,
  });

  final Function(
    ui.Image?,
    List<String> expectedStrings,
    bool includeSpaceDetection,
  ) onImageChanged;
  final TransformationController transformationController;

  @override
  State<ImageSourceSamples> createState() => _ImageSourceSamplesState();
}

class _ImageSourceSamplesState extends State<ImageSourceSamples> {
  final List<ImageData> imageFileData = [
    ImageData(
      'generated_odd_colors.png',
      'ABCDEFGHI\nJKLMNOPQR\nSTUVWXYZ 0123456789',
    ),
    ImageData(
      'black-on-white-rounded.png',
      'ABCDE\nFGHIJ\nKLMN\nOPQRS\nTUVW\nXYZ',
    ),
    ImageData(
      'black-on-white-typewriter.png',
      'A B C D E F G H\nI J K L M N O P\nQ R S T U V W X\nY Z',
    ),
    ImageData(
      'back-on-white-the_example_text.png',
      'THEEXAMPLETEXT',
    ),
    ImageData(
      'classy.png',
      'ABCDE\nFGHIJK\nLMNOP\nQRSTUV\nWXYZ',
    ),
    ImageData(
      'upper-case-alphabet-times-700x490.jpg',
      'ABCDEFG\nHIJKLMN\nOPQRSTU\nVWXYZ',
    ),
    ImageData(
      'lines-circles.png',
      '',
    ),
    ImageData(
      'color-on-white-gummy.png',
      'ABCDEF\nGHIJKL\nMNOPQ\nRSTUV\nWXYZ',
    ),
    ImageData(
      'bank-statement.png',
      '',
    ),
    ImageData(
      'bank-statement-template-27.webp',
      '',
    ),
  ];

  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadLastIndex();
  }

  @override
  Widget build(BuildContext context) {
    return PanelContent(
      left: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: _currentIndex > 0
            ? () {
                _changeIndex(_currentIndex - 1);
              }
            : null,
      ),
      center: InteractiveViewer(
        transformationController: widget.transformationController,
        constrained: false,
        minScale: 0.1,
        maxScale: 50,
        child: Image.asset(
          getSampleAssetName(_currentIndex),
          fit: BoxFit.contain,
        ),
      ),
      right: IconButton(
        icon: const Icon(Icons.arrow_forward),
        onPressed: _currentIndex < imageFileData.length - 1
            ? () {
                _changeIndex(_currentIndex + 1);
              }
            : null,
      ),
    );
  }

  List<String> getSampeExpectedText(int index) {
    if (index < 0 && index >= imageFileData.length) {
      index = 0;
    }
    if (imageFileData[index].expected.isEmpty) {
      return [];
    } else {
      return imageFileData[index].expected.split('\n');
    }
  }

  String getSampleAssetName(int index) {
    if (index < 0 && index >= imageFileData.length) {
      index = 0;
    }
    return 'assets/samples/${imageFileData[index].file}';
  }

  Future<ui.Image> getUiImageFromAsset(String assetPath) async {
    // Load the asset as a byte array
    final ByteData data = await rootBundle.load(assetPath);
    return fromBytesToImage(data.buffer.asUint8List());
  }

  void _changeIndex(int newIndex) {
    _saveLastIndex();
    if (mounted) {
      setState(() {
        _currentIndex = newIndex;
        _loadCurrentImage();
      });
    }
  }

  void _loadCurrentImage() async {
    final ui.Image image =
        await getUiImageFromAsset(getSampleAssetName(_currentIndex));

    widget.onImageChanged(image, getSampeExpectedText(_currentIndex), true);
  }

  Future<void> _loadLastIndex() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _currentIndex = prefs.getInt('last_sample_index') ?? 0;
      });
    }
    _loadCurrentImage();
  }

  Future<void> _saveLastIndex() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('last_sample_index', _currentIndex);
  }
}

class ImageData {
  ImageData(this.file, this.expected);

  final String expected;
  final String file;
}
