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

  final Function(ui.Image?, String) onImageChanged;
  final TransformationController transformationController;

  @override
  State<ImageSourceSamples> createState() => _ImageSourceSamplesState();
}

class _ImageSourceSamplesState extends State<ImageSourceSamples> {
  final List<ImageData> imageFileData = [
    ImageData(
      'generated_odd_colors.png',
      'ABCDEFGHI JKLMNOPQR STUVWXYZ 0123456789',
    ),
    ImageData(
      'black-on-white-rounded.png',
      'ABCDE FGHIJ KLMN OPQRS TUVW XYZ',
    ),
    ImageData(
      'black-on-white-typewriter.png',
      'ABCDEFGH IJKLMNOP QRSTUVWX YZ',
    ),
    ImageData(
      'back-on-white-the_example_text.png',
      'THE EXAMPLE TEXT',
    ),
    ImageData(
      'classy.png',
      'ABCDE FGHIJK LMNOP QRSTUV WXYZ',
    ),
    ImageData(
      'upper-case-alphabet-times-700x490.jpg',
      'ABCDEFG HIJKLMN OPQRSTU VWXYZ',
    ),
    ImageData(
      'lines-circles.png',
      '',
    ),
    ImageData(
      'color-on-white-gummy.png',
      'ABCDEF GHIJKL MNOPQ RSTUV WXYZ',
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
      start: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: _currentIndex > 0
            ? () {
                _changeIndex(_currentIndex - 1);
              }
            : null,
      ),
      middle: InteractiveViewer(
        transformationController: widget.transformationController,
        constrained: false,
        minScale: 0.1,
        maxScale: 50,
        child: Image.asset(
          getSampleAssetName(_currentIndex),
          fit: BoxFit.contain,
        ),
      ),
      end: IconButton(
        icon: const Icon(Icons.arrow_forward),
        onPressed: _currentIndex < imageFileData.length - 1
            ? () {
                _changeIndex(_currentIndex + 1);
              }
            : null,
      ),
    );
  }

  String getSampeExpectedText(int index) {
    if (index < 0 && index >= imageFileData.length) {
      index = 0;
    }
    return imageFileData[index].expected;
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
    final ui.Image image = await getUiImageFromAsset(getSampleAssetName(_currentIndex));

    widget.onImageChanged(image, getSampeExpectedText(_currentIndex));
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
