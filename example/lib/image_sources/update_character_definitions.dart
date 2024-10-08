import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:textify/artifact.dart';
import 'package:textify/image_pipeline.dart';
import 'package:textify/matrix.dart';
import 'package:textify/textify.dart';
import 'package:textify_dashoard/image_sources/image_source_generated.dart';
import 'package:textify_dashoard/widgets/gap.dart';

class CharacterGenerationScreen extends StatelessWidget {
  final Function onComplete;
  final List<String> availableFonts;

  const CharacterGenerationScreen({
    super.key,
    required this.onComplete,
    required this.availableFonts,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Character Generation')),
      body: CharacterGenerationBody(
          availableFonts: availableFonts, onComplete: onComplete),
    );
  }
}

class CharacterGenerationBody extends StatefulWidget {
  final Function onComplete;
  final List<String> availableFonts;

  const CharacterGenerationBody({
    super.key,
    required this.onComplete,
    required this.availableFonts,
  });

  @override
  CharacterGenerationBodyState createState() => CharacterGenerationBodyState();
}

class ProcessedCharacter {
  ProcessedCharacter(this.character);
  String character = '';
  List<Artifact> artifacts = [];
  List<String> description = [];
  List<String> problems = [];
}

class CharacterGenerationBodyState extends State<CharacterGenerationBody> {
  String _currentChar = '';
  bool _completed = false;
  bool _cancel = false;
  late final Textify textify;
  List _supportedCharacters = [];
  Map<String, ProcessedCharacter> processedCharacters = {};
  String displayDetailsForCharacter = '';
  String displayDetailsForCharacterProblems = '';

  @override
  void initState() {
    super.initState();

    _generateCharacters();
  }

  Future<void> _generateCharacters() async {
    this.textify = await Textify().init();
    // we only want to detect a single character, skip Space detections
    this.textify.includeSpaceDetections = false;
    _supportedCharacters =
        this.textify.characterDefinitions.getSupportedCharacters();

    for (String char in _supportedCharacters) {
      if (char == ' ') {
        processedCharacters[char] = (ProcessedCharacter(char));
        continue;
      }
      if (_cancel) {
        break;
      }
      setState(() {
        _currentChar = char;
      });
      await updateEachCharactersForEveryFonts(char);
    }
    setState(() {
      _completed = true;
    });
    widget.onComplete(); // Call the completion function when done
  }

  Color _getColorForCharacerBorder(final String char) {
    ProcessedCharacter? pc = processedCharacters[char];
    if (pc == null) {
      return Colors.grey;
    }
    return pc.problems.isEmpty ? Colors.green : Colors.orange;
  }

  Widget _buildProgress() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(_completed ? 'Completed' : 'Processing'),
        ),
        Wrap(
          spacing: 4,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: _supportedCharacters.map((char) {
            // Check if the character is the current character
            final bool isCurrentChar =
                char == _currentChar && _completed == false;
            return OutlinedButton(
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: _getColorForCharacerBorder(char)),
              ),
              onPressed: () {
                setState(() {
                  displayDetailsForCharacter = char;
                  ProcessedCharacter? pc = processedCharacters[char];
                  displayDetailsForCharacterProblems =
                      pc!.description.join('\n');
                });
              },
              child: Text(
                char,
                style: TextStyle(
                  fontFamily: 'Courier',
                  fontWeight: ui.FontWeight.bold,
                  fontSize: 20, // Larger font for current char
                  color: isCurrentChar && _completed == false
                      ? Colors.blue
                      : Colors.white, // Blue for current char
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildDetailsOfCharacter(final String char) {
    final ProcessedCharacter? pc = processedCharacters[char];

    return Column(
      children: [
        Text(
          displayDetailsForCharacter,
          style: const TextStyle(fontSize: 100),
        ),
        Text(displayDetailsForCharacterProblems),
        if (pc != null)
          Expanded(
            child: Center(
              child: Wrap(
                alignment: WrapAlignment.center,
                spacing: 10,
                runSpacing: 10,
                children: pc.artifacts.map((artifact) {
                  return Text(
                    style: TextStyle(fontFamily: 'Courier', fontSize: 5),
                    artifact.matrixOriginal.gridToString(),
                  );
                }).toList(),
              ),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(40.0),
      child: Column(
        children: [
          Center(child: _buildProgress()),
          Expanded(
            child: _buildDetailsOfCharacter(displayDetailsForCharacter),
          ),
          gap(),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              OutlinedButton(
                child: Text(_completed ? 'Close' : 'Cancel'),
                onPressed: () {
                  if (_completed) {
                    Navigator.pop(context);
                  } else {
                    setState(() {
                      _cancel = true;
                    });
                  }
                },
              ),
              gap(),
              if (_completed)
                OutlinedButton(
                  child: Text('Copy as "matrices.json"'),
                  onPressed: () {
                    Clipboard.setData(
                      ClipboardData(
                          text: textify.characterDefinitions.toJsonString()),
                    );
                  },
                )
            ],
          ),
        ],
      ),
    );
  }

  Future<void> updateEachCharactersForEveryFonts(String char) async {
    final processedCharacter = ProcessedCharacter(char);
    List<dynamic> problems = [];

    for (final fontName in widget.availableFonts) {
      final problemsFound =
          await upadeteSingleCharSingleFont(char, fontName, processedCharacter);
      problems.addAll(problemsFound);
    }
    processedCharacters[char] = processedCharacter;
  }

  Future<List<dynamic>> upadeteSingleCharSingleFont(
    String char,
    String fontName,
    ProcessedCharacter processedCharacter,
  ) async {
    List<dynamic> problems = [];

    final ui.Image newImageSource = await createColorImageSingleCharacter(
      imageWidth: 40 * 6,
      imageHeight: 60,
      character: 'A $char W',
      fontFamily: fontName,
      fontSize: imageSettings.fontSize.toInt(),
    );

    final ImagePipeline interimImages =
        await ImagePipeline.apply(newImageSource);

    textify.findArtifactsFromBinaryImage(interimImages.imageBinary);
    if (textify.bands.length == 1) {
      List<Artifact> artifactsInTheFirstBand = textify.bands.first.artifacts;

      final artifactsInTheFirstBandNoSpaces = artifactsInTheFirstBand
          .where((Artifact artifact) => artifact.matrixOriginal.isNotEmpty)
          .toList();
      if (artifactsInTheFirstBandNoSpaces.length == 3) {
        final targetArtifact = artifactsInTheFirstBandNoSpaces[
            1]; // second character from "A?W" skip spaces

        final Matrix matrix =
            targetArtifact.matrixOriginal.createNormalizeMatrix(40, 60);
        final wasNewDefinition =
            textify.characterDefinitions.upsertTemplate(fontName, char, matrix);
        if (matrix.isEmpty) {
          processedCharacter.problems.add('***** NO Content found');
        } else {
          processedCharacter.description
              .add('$fontName  IsNew:$wasNewDefinition    $matrix');
        }
        processedCharacter.artifacts.add(targetArtifact);
      } else {
        processedCharacter.problems.add('Not found');
        processedCharacter.artifacts.addAll(artifactsInTheFirstBand);
      }
    }
    return problems;
  }
}
