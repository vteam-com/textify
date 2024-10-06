import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'image_source_clipboard.dart';
import 'image_source_generated.dart';
import 'image_source_samples.dart';

class ImageSourceSelector extends StatefulWidget {
  const ImageSourceSelector({
    super.key,
    required this.transformationController,
    required this.onSourceChanged,
  });

  final Function(ui.Image? imageSelected, List<String> expectedText,
      String fontName, bool includeSpaceDetection) onSourceChanged;
  final TransformationController transformationController;

  @override
  ImageSourceSelectorState createState() => ImageSourceSelectorState();
}

class ImageSourceSelectorState extends State<ImageSourceSelector>
    with SingleTickerProviderStateMixin {
  // Choice of Images sources
  final List<String> tabViews = [
    'Generate',
    'Samples',
    'Clipboard',
  ];

  List<String> _expectedText = [];
  String _fontName = 'Font???';
  bool _includeSpaceDetection = true;

  // Keep track of user choices
  ui.Image? _imageSelected;

  late TabController _tabController;

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: tabViews.length, vsync: this);
    _loadLastTab();
  }

  @override
  Widget build(BuildContext context) {
    return Builder(
      builder: (BuildContext context) {
        return Column(
          children: [
            TabBar(
              controller: _tabController,
              tabs: tabViews.map((e) => Tab(text: e)).toList(),
              onTap: (index) {
                _tabController.animateTo(index);
                _saveLastTab(index);
                widget.onSourceChanged(
                  _imageSelected,
                  _expectedText,
                  _fontName,
                  _includeSpaceDetection,
                );
              },
            ),
            IntrinsicHeight(
              child: _buildContent(_tabController.index),
            ),
          ],
        );
      },
    );
  }

  Widget _buildContent(final int selectedView) {
    switch (selectedView) {
      // Image source is from Samples
      case 1:
        return ImageSourceSamples(
          transformationController: widget.transformationController,
          onImageChanged: (
            final ui.Image? image,
            final List<String> expectedText,
            bool includeSpaceDetection,
          ) async {
            _imageSelected = image;
            _expectedText = expectedText;
            _includeSpaceDetection = true;
            if (mounted) {
              setState(() {
                widget.onSourceChanged(
                  _imageSelected,
                  _expectedText,
                  _fontName,
                  _includeSpaceDetection,
                );
              });
            }
          },
        );

      // Image source is from the Clipboard
      case 2:
        return ImageSourceClipboard(
          transformationController: widget.transformationController,
          onImageChanged: (final ui.Image? newImage) {
            _imageSelected = newImage;
            _expectedText = [];
            _includeSpaceDetection = true;
            if (mounted) {
              setState(() {
                widget.onSourceChanged(
                  _imageSelected,
                  _expectedText,
                  _fontName,
                  _includeSpaceDetection,
                );
              });
            }
          },
        );

      // Image source is Generated
      case 0:
      default:
        return ImageSourceGenerated(
          transformationController: widget.transformationController,
          onImageChanged: (
            final ui.Image? newImage,
            final List<String> expectedText,
            final String fontName,
            final bool includeSpaceDetections,
          ) {
            _imageSelected = newImage;
            _expectedText = expectedText;
            _fontName = fontName;
            _includeSpaceDetection = includeSpaceDetections;
            if (mounted) {
              setState(() {
                widget.onSourceChanged(
                  _imageSelected,
                  _expectedText,
                  _fontName,
                  _includeSpaceDetection,
                );
              });
            }
          },
        );
    }
  }

  Future<void> _loadLastTab() async {
    final prefs = await SharedPreferences.getInstance();
    final lastIndex = prefs.getInt('last_tab_index') ?? 0;
    _tabController.animateTo(lastIndex);
  }

  Future<void> _saveLastTab(int index) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('last_tab_index', index);
  }
}
