import 'dart:ui' as ui;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:textify/image_pipeline.dart';
import 'package:textify/textify.dart';

import 'image_sources/image_source_selector.dart';
import 'image_sources/panel_content.dart';
import 'show_steps/matched_artifacts.dart';
import 'show_steps/show_findings.dart';
import 'widgets/gap.dart';
import 'widgets/image_viewer.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final Textify _textify = Textify();

  // The image that will be use for detecting the text
  ImagePipeline? _imagePipeline;
  ui.Image? _imageSource;
  String _fontName = '';
  List<String> _charactersExpectedToBeFoundInTheImage = [];
  bool _cleanUpArtifactFound = false;
  String _textFound = '';

  bool _isExpandedArtifactFound = true;
  bool _isExpandedHightContrast = false;
  bool _isExpandedResults = true;
  bool _isExpandedSource = true;

  final TransformationController _transformationController =
      TransformationController();

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _textify.init();
      _triggetTextifyConvertion();
    });
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
                      _isExpandedHightContrast = isExpanded;
                    case 2:
                      _isExpandedArtifactFound = isExpanded;
                    case 3:
                      _isExpandedResults = isExpanded;
                  }
                });
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
                // Input image in high conttrast
                //
                _buildExpansionPanel(
                  titleLeft: 'High Contrast',
                  titleCenter: _getDimensionOfImageSource(_imageSource),
                  titleRight: '',
                  isExpanded: _isExpandedHightContrast,
                  content: _buildShowPiplineStateHightContrast(
                    _imagePipeline,
                    _transformationController,
                  ),
                ),

                //
                // Artifact found
                //
                _buildExpansionPanel(
                  titleLeft: 'Artifacts found',
                  titleCenter: _textify.count.toString(),
                  titleRight: '',
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
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
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
      ),
    );
  }

  Widget _buildArtifactFound(
    final Textify textify,
    final bool cleanUpArtifacts,
    final Function onToggleCleanup,
  ) {
    return PanelContent(
      start: const SizedBox(),
      middle: InteractiveViewer(
        transformationController: _transformationController,
        constrained: false,
        minScale: 0.1,
        maxScale: 50,
        child: ShowFindings(
          textify: textify,
          applyPacking: cleanUpArtifacts,
        ),
      ),
      end: _buildActionButtons(
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
      onSourceChanged: (final ui.Image? newImage,
          final List<String> expectedText, final String fontName) {
        _imageSource = newImage;
        _charactersExpectedToBeFoundInTheImage = expectedText;
        _fontName = fontName;
        _triggetTextifyConvertion();
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

  Widget _buildShowPiplineStateHightContrast(
    pipelineImages,
    transformationController,
  ) {
    return pipelineImages?.imageHighContrast == null
        ? const CupertinoActivityIndicator(radius: 30)
        : buildInteractiveImageViewer(
            pipelineImages.imageHighContrast,
            transformationController,
          );
  }

  void _clearState() {
    if (mounted) {
      setState(() {
        _imagePipeline = null;
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
    final ImagePipeline interimImages = await ImagePipeline.apply(_imageSource);

    _textify.getTextFromMatrix(
      imageAsBinary: interimImages.imageBinary,
    );

    if (mounted) {
      setState(() {
        _imagePipeline = interimImages;
        _textFound = _textify.textFound;
      });
    }
  }

  void _triggetTextifyConvertion() {
    _convertImageToText().then((__) {
      if (mounted) {
        setState(() {});
      }
    });
  }
}
