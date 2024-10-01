import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:textify/image_pipeline.dart';
import 'package:textify/textify.dart';

import '../../widgets/gap.dart';
import 'debouce.dart';
import 'image_generator_input.dart';
import 'panel_content.dart';

ImageGeneratorInput imageSettings = ImageGeneratorInput.empty();

ImageGeneratorInput lastImageSettingsUseForImageSource =
    ImageGeneratorInput.empty();

/// This widget is responsible for displaying and managing the settings of the application.
/// It includes controls for font size and font selection, as well as a preview of the text.
/// The widget adapts its layout based on the screen size, displaying the controls and preview
/// side by side on larger screens and stacked on smaller screens.
///
/// The [onImageChanged] callback is triggered when the font size is changed, and the
/// [onSelectedFontChanged] callback is triggered when a new font is selected.
///
/// This widget is designed to be flexible and easy to use, making it simple to integrate
/// into any Flutter application that requires user-adjustable text settings.
class ImageSourceGenerated extends StatefulWidget {
  const ImageSourceGenerated({
    super.key,
    required this.transformationController,
    required this.onImageChanged,
  });

  final Function(
          ui.Image? image, List<String> expectedCharacters, String fontName)
      onImageChanged;
  final TransformationController transformationController;

  @override
  State<ImageSourceGenerated> createState() => _ImageSourceGeneratedState();
}

class _ImageSourceGeneratedState extends State<ImageSourceGenerated> {
  // The list of available fonts
  List<String> availableFonts = [
    'Arial',
    'Helvetica',
    'Times New Roman',
    'CourierPrime',
  ];

  Debouncer debouncer = Debouncer(const Duration(milliseconds: 700));

  final TextEditingController _textControllerLine1 = TextEditingController();
  final TextEditingController _textControllerLine2 = TextEditingController();
  final TextEditingController _textControllerLine3 = TextEditingController();

  // The image that will be use for detecting the text
  ui.Image? _imageGenerated;

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    loadSavedText().then((_) {
      setState(() {
        _textControllerLine1.text = imageSettings.defaultTextLine1;
        _textControllerLine2.text = imageSettings.defaultTextLine2;
        _textControllerLine3.text = imageSettings.defaultTextLine3;
        _isLoading = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    // adapt to screen size layout
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        buildControllers(),
        Expanded(
          child: PanelContent(
            start: const SizedBox(),
            middle: InteractiveViewer(
              constrained: false,
              minScale: 0.1,
              maxScale: 50,
              transformationController: widget.transformationController,
              child: showImage(),
            ),
            end: _buildActionButtons(),
          ),
        ),
      ],
    );
  }

  /// Builds the controllers for font size and font selection.
  Widget buildControllers() {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Row(
        children: [
          Expanded(
            child: Column(
              children: [
                buildFontSizeSlider(),
                gap(),
                buildPickFont(),
              ],
            ),
          ),
          gap(),
          Expanded(
            child: Column(
              children: [
                buildTextInputLine1(),
                gap(),
                buildTextInputLine2(),
                gap(),
                buildTextInputLine3(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Builds the slider for font size adjustment.
  Widget buildFontSizeSlider() {
    return Row(
      children: [
        SizedBox(
          width: 80, // Set a fixed width for the caption
          child: Text(
            'FontSize ${imageSettings.fontSize}',
            style: const TextStyle(fontSize: 16),
          ),
        ),
        Expanded(
          child: Slider(
            value: imageSettings.fontSize.toDouble(),
            min: 10,
            max: 100,
            divisions: 100,
            label: imageSettings.fontSize.toString(),
            onChanged: (value) {
              setState(() {
                imageSettings.fontSize = value.round().toDouble();
              });
            },
          ),
        ),
      ],
    );
  }

  /// Builds the dropdown for font selection.
  Widget buildPickFont() {
    return Row(
      children: [
        const SizedBox(
          width: 100, // Set a fixed width for the caption
          child: Text('Type', style: TextStyle(fontSize: 16)),
        ),
        DropdownButton<String>(
          value: imageSettings.selectedFont,
          items: availableFonts.map((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(value),
            );
          }).toList(),
          onChanged: (String? newValue) {
            if (newValue != null) {
              setState(() {
                imageSettings.selectedFont = newValue;
              });
            }
          },
        ),
      ],
    );
  }

  /// Builds a TextField for text input.
  Widget buildTextInputLine1() {
    return TextField(
      controller: _textControllerLine1,
      decoration: const InputDecoration(
        border: OutlineInputBorder(),
        hintText: 'Enter text for line 1',
        labelText: 'Line 1',
      ),
      onChanged: (text) {
        setState(() {
          imageSettings.defaultTextLine1 = text;
          saveText('textLine1', text);
        });
      },
    );
  }

  /// Builds a TextField for text input.
  Widget buildTextInputLine2() {
    return TextField(
      controller: _textControllerLine2,
      decoration: const InputDecoration(
        border: OutlineInputBorder(),
        hintText: 'Enter text for line 2',
        labelText: 'Line 2',
      ),
      onChanged: (text) {
        setState(() {
          imageSettings.defaultTextLine2 = text;
          saveText('textLine2', text);
        });
      },
    );
  }

  /// Builds a TextField for text input.
  Widget buildTextInputLine3() {
    return TextField(
      controller: _textControllerLine3,
      decoration: const InputDecoration(
        border: OutlineInputBorder(),
        hintText: 'Enter text for line 3',
        labelText: 'Line 3',
      ),
      onChanged: (text) {
        setState(() {
          imageSettings.defaultTextLine3 = text;
          saveText('textLine3', text);
        });
      },
    );
  }

  Future<void> loadSavedText() async {
    final prefs = await SharedPreferences.getInstance();
    final textLine1 =
        prefs.getString('textLine1') ?? imageSettings.defaultTextLine1;
    final textLine2 =
        prefs.getString('textLine2') ?? imageSettings.defaultTextLine2;
    final textLine3 =
        prefs.getString('textLine3') ?? imageSettings.defaultTextLine2;
    setState(() {
      _textControllerLine1.text = textLine1;
      _textControllerLine2.text = textLine2;
      _textControllerLine3.text = textLine3;
      imageSettings.defaultTextLine1 = textLine1;
      imageSettings.defaultTextLine2 = textLine2;
      imageSettings.defaultTextLine3 = textLine3;
      imageSettings.lastUpdated = DateTime.now();
    });
  }

  void notify() {
    debouncer.run(() {
      widget.onImageChanged(
        _imageGenerated,
        [
          _textControllerLine1.text,
          _textControllerLine2.text,
          _textControllerLine3.text,
        ],
        imageSettings.selectedFont,
      );
    });
  }

  void resetSettings() async {
    setState(() {
      imageSettings = ImageGeneratorInput.empty();
      _textControllerLine1.text = imageSettings.defaultTextLine1;
      _textControllerLine2.text = imageSettings.defaultTextLine2;
      _textControllerLine3.text = imageSettings.defaultTextLine3;
    });

    // Save the reset text
    saveText('textLine1', imageSettings.defaultTextLine1);
    saveText('textLine2', imageSettings.defaultTextLine2);
    saveText('textLine3', imageSettings.defaultTextLine3);

    // Trigger image regeneration
    debouncer.run(() {
      widget.onImageChanged(
        _imageGenerated,
        [
          _textControllerLine1.text,
          _textControllerLine2.text,
          _textControllerLine3.text
        ],
        imageSettings.selectedFont,
      );
    });

    final textify = await Textify().init();

    final List<String> allCharacters = (imageSettings.defaultTextLine1 +
            imageSettings.defaultTextLine2 +
            imageSettings.defaultTextLine3)
        .split('');

    for (final fontName in availableFonts) {
      for (final String char in allCharacters) {
        final ui.Image newImageSource = await createColorImageSingleCharacter(
          imageWidth: 40 * 6,
          imageHeight: 60,
          character: 'A|$char|W',
          fontFamily: fontName,
          fontSize: imageSettings.fontSize.toInt(),
        );

        final ImagePipeline interimImages =
            await ImagePipeline.apply(newImageSource);

        textify.findArtifactsFromBinaryImage(interimImages.imageBinary);
        if (textify.bands.length == 1) {
          final targetArtifact =
              textify.bands.first.artifacts[2]; // second character from "A|?|W"

          textify.characterDefinitions.upsertTemplate(
            fontName,
            char,
            targetArtifact.matrixOriginal
                .createNormalizeMatrix(40, 60), // the second artifact
          );
        }
      }
    }

    Clipboard.setData(
      ClipboardData(text: textify.characterDefinitions.toJsonString()),
    );
  }

  Future<void> saveText(String key, String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, value);
  }

  Widget showImage() {
    return FutureBuilder(
      future: _buildGenerateImageWidget(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        } else if (snapshot.hasData) {
          return snapshot.data!;
        }
        return Container();
      },
    );
  }

  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Wrap(
        children: [
          SizedBox(
            width: 100,
            child: OutlinedButton(
              onPressed: resetSettings,
              child: const Text('Reset'),
            ),
          ),
        ],
      ),
    );
  }

  /// Builds a quick preview of the text with the selected font and size.
  Future<Widget> _buildGenerateImageWidget() async {
    if (lastImageSettingsUseForImageSource != imageSettings) {
      final ui.Image newImageSource = await createColorImageUsingTextPainter(
        fontFamily: imageSettings.selectedFont,
        backgroundColor: imageSettings.imageBackgroundColor,
        text1: _textControllerLine1.text,
        textColor1: imageSettings.imageTextColorAlphabet,
        text2: _textControllerLine2.text,
        textColor2: imageSettings.imageTextColorAlphabet,
        text3: _textControllerLine3.text,
        textColor3: imageSettings.imageTextColorNumbers,
        fontSize: imageSettings.fontSize.toInt(),
      );
      imageSettings.lastUpdated = DateTime.now();
      _imageGenerated = newImageSource;
      lastImageSettingsUseForImageSource = imageSettings.clone();
      notify();
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.transparent,
        border: Border.all(color: Colors.grey),
      ),
      child: RawImage(
        image: _imageGenerated,
        width: _imageGenerated!.width.toDouble(),
        height: _imageGenerated!.height.toDouble(),
        fit: BoxFit.contain,
      ),
    );
  }
}

Future<ui.Image> createColorImageSingleCharacter({
  required final int imageWidth,
  required final int imageHeight,
  required final String character,
  // Font
  required final String fontFamily,
  required final int fontSize,
}) async {
  final ui.PictureRecorder recorder = ui.PictureRecorder();
  final ui.Canvas newCanvas = ui.Canvas(recorder);

  final ui.Paint paint = ui.Paint();
  paint.color = Colors.white;
  paint.style = ui.PaintingStyle.fill;

  newCanvas.drawRect(
    ui.Rect.fromPoints(
      const ui.Offset(0.0, 0.0),
      ui.Offset(
        imageWidth.toDouble(),
        imageHeight.toDouble(),
      ),
    ),
    paint,
  );

  TextPainter textPainter = myDrawText(
    paint: paint,
    width: imageWidth,
    text: character,
    color: Colors.black,
    fontSize: fontSize,
    fontFamily: fontFamily,
  );

  textPainter.paint(
    newCanvas,
    Offset(0, 0),
  );

  final ui.Picture picture = recorder.endRecording();
  final ui.Image image = await picture.toImage(imageWidth, imageHeight);
  return image;
}

Future<ui.Image> createColorImageUsingTextPainter({
  required final Color backgroundColor,
  // text 1
  required final String text1,
  required final Color textColor1,
  // text 2
  required final String text2,
  required final Color textColor2,
  // text 3
  required final String text3,
  required final Color textColor3,
  // Font
  required final String fontFamily,
  required final int fontSize,
}) async {
  final ui.PictureRecorder recorder = ui.PictureRecorder();
  final ui.Canvas newCanvas = ui.Canvas(recorder);

  final ui.Paint paint = ui.Paint();
  paint.color = backgroundColor;
  paint.style = ui.PaintingStyle.fill;

  const letterSpacing = 4;

  final int maxWidthLine1 = text1.length * (fontSize + letterSpacing);
  final int maxWidthLine2 = text2.length * (fontSize + letterSpacing);
  final int maxWidthLine3 = text2.length * (fontSize + letterSpacing);

  const int padding = 20;
  final int imageWidth = padding +
      max(
          1,
          max(
            max(
              maxWidthLine1,
              maxWidthLine2,
            ),
            maxWidthLine3,
          ));
  final int imageHeight = padding + (5 * fontSize);

  newCanvas.drawRect(
    ui.Rect.fromPoints(
      const ui.Offset(0.0, 0.0),
      ui.Offset(
        imageWidth.toDouble(),
        imageHeight.toDouble(),
      ),
    ),
    paint,
  );

  // Line 1
  TextPainter textPainter = myDrawText(
    paint: paint,
    width: imageWidth,
    text: text1,
    color: textColor1,
    fontSize: fontSize,
    fontFamily: fontFamily,
  );
  textPainter.paint(
    newCanvas,
    Offset(padding.toDouble(), padding.toDouble()),
  );

  // Line 2
  TextPainter textPainter2 = myDrawText(
    paint: paint,
    width: imageWidth,
    text: text2,
    color: textColor2,
    fontSize: fontSize,
    fontFamily: fontFamily,
  );
  textPainter2.paint(
    newCanvas,
    Offset(padding.toDouble(), 2 * fontSize.toDouble()),
  );

  // Line 3
  TextPainter textPainter3 = myDrawText(
    paint: paint,
    width: imageWidth,
    text: text3,
    color: textColor3,
    fontSize: fontSize,
    fontFamily: fontFamily,
  );
  textPainter3.paint(
    newCanvas,
    Offset(padding.toDouble(), 4 * fontSize.toDouble()),
  );

  final ui.Picture picture = recorder.endRecording();
  final ui.Image image = await picture.toImage(imageWidth, imageHeight);
  return image;
}

TextPainter myDrawText({
  required final Paint paint,
  required final Color color,
  required final String text,
  required final int fontSize,
  required final String fontFamily,
  required final int width,
  int letterSpacing = 4,
}) {
  paint.color = color;

  final TextPainter textPainter = TextPainter(
    text: TextSpan(
      text: text,
      style: TextStyle(
        color: color,
        letterSpacing: letterSpacing.toDouble(),
        fontSize: fontSize.toDouble(),
        fontFamily: fontFamily,
      ),
    ),
    textDirection: ui.TextDirection.ltr,
  );

  textPainter.layout(
    maxWidth: width.toDouble(),
  );
  return textPainter;
}
