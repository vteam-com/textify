import 'dart:ui' as ui;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:textify/matrix.dart';
import 'package:textify/textify.dart';

import 'image_sources/image_source_selector.dart';
import 'image_sources/panel_content.dart';
import 'show_steps/matched_artifacts.dart';
import 'show_steps/show_findings.dart';
import 'widgets/gap.dart';
import 'widgets/image_viewer.dart';

///
class HomeScreen extends StatefulWidget {
  ///
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final Textify _textify = Textify();

  // The image that will be use for detecting the text
  ui.Image? _imageBlackOnWhite;

  ui.Image? _imageSource;
  String _fontName = '';
  List<String> _charactersExpectedToBeFoundInTheImage = [];
  bool _cleanUpArtifactFound = false;
  String _textFound = '';

  bool _isExpandedArtifactFound = true;
  bool _isExpandedOptimized = true;
  bool _isExpandedResults = true;
  bool _isExpandedSource = true;

  final TransformationController _transformationController =
      TransformationController();

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _textify.init();
      _convertImageToText();
    });
    _loadLastPreferences();
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final String percentage = getPercentageOfMatches(
      _charactersExpectedToBeFoundInTheImage,
      _textFound,
    ).toStringAsFixed(0);

    return Scaffold(
      backgroundColor: colorScheme.primaryContainer,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(13),
            child: ExpansionPanelList(
              expandedHeaderPadding: const EdgeInsets.all(0),
              materialGapSize: 2,
              expansionCallback: (int index, bool isExpanded) {
                setState(() {
                  switch (index) {
                    case 0:
                      _isExpandedSource = isExpanded;
                    case 1:
                      _isExpandedOptimized = isExpanded;
                    case 2:
                      _isExpandedArtifactFound = isExpanded;
                    case 3:
                      _isExpandedResults = isExpanded;
                  }
                });
                _savePreferences();
              },
              children: [
                //
                // Input Source
                //
                _buildExpansionPanel(
                  titleLeft: 'TEXTIFY',
                  titleCenter: 'Source',
                  titleRight: '',
                  isExpanded: _isExpandedSource,
                  content: _buildImageSourceSelector(),
                ),

                //
                // Input image in high contrast
                //
                _buildExpansionPanel(
                  titleLeft: 'High Contrast',
                  titleCenter: _getDimensionOfImageSource(_imageSource),
                  titleRight: '',
                  isExpanded: _isExpandedOptimized,
                  content: _buildOptimizedImage(
                    _imageBlackOnWhite,
                    _transformationController,
                  ),
                ),

                //
                // Bands of Artifact
                //
                _buildExpansionPanel(
                  titleLeft: '${_textify.bands.length} Bands',
                  titleCenter: '${_textify.count} Artifacts',
                  titleRight:
                      '${NumberFormat.decimalPattern().format(_textify.duration)}ms',
                  isExpanded: _isExpandedArtifactFound,
                  content: _buildArtifactFound(
                    _textify,
                    _cleanUpArtifactFound,
                    () {
                      setState(() {
                        _cleanUpArtifactFound = !_cleanUpArtifactFound;
                      });
                    },
                  ),
                ),

                //
                // Results
                //
                _buildExpansionPanel(
                  titleLeft: 'Results',
                  titleCenter: '$percentage%',
                  titleRight: '',
                  isExpanded: _isExpandedResults,
                  content: MatchedArtifacts(
                    font: _fontName,
                    expectedStrings: _charactersExpectedToBeFoundInTheImage,
                    textify: _textify,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtons(
    final Function onToggleCleanup,
    final bool cleanUpArtifacts,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        OutlinedButton(
          onPressed: () {
            _transformationController.value =
                _transformationController.value.scaled(1 / 1.5);
          },
          child: const Text('Zoom -'),
        ),
        gap(),
        OutlinedButton(
          onPressed: () {
            _transformationController.value =
                _transformationController.value.scaled(1.5);
          },
          child: const Text('Zoom +'),
        ),
        gap(),
        OutlinedButton(
          onPressed: () {
            _transformationController.value = Matrix4.identity();
          },
          child: const Text('Center'),
        ),
        gap(),
        OutlinedButton(
          onPressed: () {
            onToggleCleanup();
          },
          child: Text(cleanUpArtifacts ? 'Original' : 'Normalized'),
        ),
      ],
    );
  }

  Widget _buildArtifactFound(
    final Textify textify,
    final bool cleanUpArtifacts,
    final Function onToggleCleanup,
  ) {
    return PanelContent(
      center: CustomInteractiveViewer(
        transformationController: _transformationController,
        child: ShowFindings(
          textify: textify,
          applyPacking: cleanUpArtifacts,
        ),
      ),
      top: _buildActionButtons(
        onToggleCleanup,
        cleanUpArtifacts,
      ),
    );
  }

  ExpansionPanel _buildExpansionPanel({
    required final String titleLeft,
    required final String titleCenter,
    required final String titleRight,
    required final bool isExpanded,
    required final Widget content,
  }) {
    return ExpansionPanel(
      canTapOnHeader: true,
      isExpanded: isExpanded,
      headerBuilder: (final BuildContext context, final bool isExpanded) =>
          _buildPanelHeader(titleLeft, titleCenter, titleRight),
      body: Container(
        color: const ui.Color.fromARGB(255, 0, 24, 36),
        padding: const EdgeInsets.all(8.0),
        child: content,
      ),
    );
  }

  Widget _buildImageSourceSelector() {
    return ImageSourceSelector(
      transformationController: _transformationController,
      onSourceChanged: (
        final ui.Image? newImage,
        final List<String> expectedText,
        final String fontName,
        final bool includeSpaceDetection,
      ) {
        _imageSource = newImage;
        _charactersExpectedToBeFoundInTheImage = expectedText;
        _fontName = fontName;
        _textify.includeSpaceDetections = includeSpaceDetection;
        _convertImageToText();
      },
    );
  }

  Widget _buildPanelHeader(
    final String left,
    final String center,
    final String right,
  ) {
    return Padding(
      padding: const EdgeInsets.only(left: 8.0, right: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Expanded(
            child: Text(
              left,
              textAlign: TextAlign.left,
              style: const TextStyle(fontSize: 20),
            ),
          ),
          Expanded(
            child: Text(
              center,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 20),
            ),
          ),
          Expanded(
            child: Text(
              right,
              textAlign: TextAlign.right,
              style: const TextStyle(fontSize: 20),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOptimizedImage(
    final ui.Image? imageHighContrast,
    final TransformationController? transformationController,
  ) {
    return imageHighContrast == null
        ? const CupertinoActivityIndicator(radius: 30)
        : buildInteractiveImageViewer(
            imageHighContrast,
            transformationController,
          );
  }

  void _clearState() {
    if (mounted) {
      setState(() {
        _imageBlackOnWhite = null;
        _textFound = '';
      });
    }
  }

  String _getDimensionOfImageSource(imageSource) {
    if (imageSource == null) {
      return '';
    }
    return '${imageSource!.width} x ${imageSource!.height}';
  }

  Future<void> _convertImageToText() async {
    if (_imageSource == null) {
      _clearState();
      return;
    }

    // Convert color image source to a grid of on=ink/off=paper
    final ui.Image tmpImageBlackOnWhite = await imageToBlackOnWhite(
      _imageSource!,
    );

    _textify.getTextFromMatrix(
      imageAsMatrix: await Matrix.fromImage(tmpImageBlackOnWhite),
    );

    if (mounted) {
      setState(() {
        _imageBlackOnWhite = tmpImageBlackOnWhite;
        _textFound = _textify.textFound;
      });
    }
  }

  Future<void> _loadLastPreferences() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    _isExpandedSource = prefs.getBool('expanded_source') ?? true;
    _isExpandedArtifactFound = prefs.getBool('expanded_found') ?? true;
    _isExpandedOptimized = prefs.getBool('expanded_contrast') ?? true;
    _isExpandedResults = prefs.getBool('expanded_results') ?? true;
  }

  Future<void> _savePreferences() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();

    await prefs.setBool('expanded_source', _isExpandedSource);
    await prefs.setBool('expanded_found', _isExpandedArtifactFound);
    await prefs.setBool('expanded_contrast', _isExpandedOptimized);
    await prefs.setBool('expanded_results', _isExpandedResults);
  }
}
