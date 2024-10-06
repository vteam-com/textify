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

class Problem {
  Problem(this.character, this.artifacts, this.description);
  String character = '';
  List<Artifact> artifacts = [];
  String description = '';
}

class CharacterGenerationBodyState extends State<CharacterGenerationBody> {
  String _currentChar = '';
  bool _completed = false;
  bool _cancel = false;
  late final Textify textify;
  List<String> log = [];
  List<Problem> logProblems = [];

  @override
  void initState() {
    super.initState();
    _generateCharacters();
  }

  Future<void> _generateCharacters() async {
    this.textify = await Textify().init();
    // we only want to detect a single character, skip Space detections
    this.textify.includeSpaceDetections = false;

    for (String char in textify.characterDefinitions.getSupportedCharacters()) {
      if (char == ' ') {
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

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(40.0),
      child: Column(
        children: [
          Center(
            child: Text(
              textAlign: ui.TextAlign.center,
              'Processing character\n\n"$_currentChar"',
              style: const TextStyle(fontSize: 24),
            ),
          ),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(
                  child: ListView.builder(
                    itemCount: log.length,
                    itemBuilder: (context, index) {
                      return Text(log[index]);
                    },
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: logProblems.length,
                    itemBuilder: (context, index) {
                      final problem = logProblems[index];
                      return ListTile(
                        title: Text(problem.character),
                        subtitle: Row(
                          children: problem.artifacts.map((artifact) {
                            return Text(
                              style:
                                  TextStyle(fontFamily: 'Courier', fontSize: 5),
                              artifact.matrixOriginal.gridToString(),
                            );
                          }).toList(),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
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
                  child: Text('Copy'),
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
    log.add('\n"$char"');
    for (final fontName in widget.availableFonts) {
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
          final bool wasNewDefinition =
              textify.characterDefinitions.upsertTemplate(
            fontName,
            char,
            matrix,
          );
          String problem = '';
          if (char != ' ' && matrix.isEmpty) {
            problem = '***** NO Content found';
          }
          String logEntry = '$fontName $matrix New:$wasNewDefinition $problem';
          log.add(logEntry);
          if (problem.isNotEmpty) {
            logProblems.add(Problem(char, [targetArtifact], logEntry));
          }
        } else {
          logProblems.add(Problem(char, artifactsInTheFirstBand,
              'Band has ${artifactsInTheFirstBandNoSpaces.length} artifacts'));
        }
      }
    }
  }
}
