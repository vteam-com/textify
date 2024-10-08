import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:textify/artifact.dart';
import 'package:textify/character_definitions.dart';
import 'package:textify/matrix.dart';
import 'package:textify/score_match.dart';

import 'package:textify/textify.dart';

import '../../widgets/gap.dart';

class EditScreen extends StatefulWidget {
  const EditScreen({
    super.key,
    required this.textify,
    required this.artifact,
    required this.characterExpected,
    required this.characterFound,
  });
  final Textify textify;
  final Artifact artifact;
  final String characterExpected;
  final String characterFound;

  @override
  State<EditScreen> createState() => _EditScreenState();
}

class _EditScreenState extends State<EditScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          child: _buildContent(context),
        ),
      ),
    );
  }

  static Widget buildColoredText(String multiLineText) {
    return RichText(
      text: TextSpan(
        style: const TextStyle(
          fontFamily: 'Courier',
          fontSize: 8,
        ),
        children: multiLineText.split('\n').expand((line) {
          return line.split('').map((char) {
            switch (char) {
              case '.':
                return TextSpan(
                  text: char,
                  style: const TextStyle(color: Colors.grey),
                );
              case '=':
                return TextSpan(
                  text: char,
                  style: TextStyle(color: Colors.green.shade200),
                );
              case '#':
                return TextSpan(
                  text: char,
                  style: TextStyle(color: Colors.orange.shade200),
                );
              case '*':
                return TextSpan(
                  text: char,
                  style: TextStyle(color: Colors.blue.shade200),
                );
              default:
                return TextSpan(text: char);
            }
          }).toList()
            ..add(const TextSpan(text: '\n'));
        }).toList(),
      ),
      textScaler: const TextScaler.linear(1.0),
    );
  }

  String verticalLines(Matrix matrix) {
    return 'VL:${matrix.verticalLineLeft ? 'Y' : 'N'} VR:${matrix.verticalLineRight ? 'Y' : 'N'}';
  }

  String verticalLinesTemplate(CharacterDefinition template) {
    return 'VL:${template.lineLeft ? 'Y' : 'N'} VR:${template.lineRight ? 'Y' : 'N'}';
  }

  static Widget _buildArtifactGrid(
    final String title,
    final Color headerBackgroundColor,
    final multiLineText,
    final textForClipboard,
  ) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _buildHeader(
          title,
          headerBackgroundColor,
          OutlinedButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: textForClipboard));
            },
            child: const Text('Copy'),
          ),
        ),
        buildColoredText(multiLineText),
      ],
    );
  }

  Widget _buildContent(final BuildContext context) {
    final List<ScoreMatch> scoreMatches =
        widget.textify.getMatchingScores(widget.artifact);

    final ScoreMatch scoreOfExpectedCharacter = scoreMatches.firstWhere(
      (scoreMatch) => scoreMatch.character == widget.characterExpected,
      orElse: () => ScoreMatch.empty(),
    );

    if (scoreOfExpectedCharacter.isEmpty) {
      // not found
    } else {
      if (scoreMatches.first != scoreOfExpectedCharacter) {
        // We do not have a expecte match
        // Move the expected match to the second position of the list
        scoreMatches.remove(scoreOfExpectedCharacter);
        scoreMatches.insert(1, scoreOfExpectedCharacter);
      }
    }
    // Make sure that we don't have redundant trailing entries
    final scoresMatchToDisplay = scoreMatches
        .fold<List<ScoreMatch>>([], (uniqueList, entry) {
          if (uniqueList.length < 2 ||
              !uniqueList.any((e) => e.character == entry.character)) {
            uniqueList.add(entry);
          }
          return uniqueList;
        })
        .take(20)
        .toList();

    final int w = widget.textify.templateWidth;
    final int h = widget.textify.templateHeight;

    List<Widget> widgets = [
      // as found
      _buildArtifactGrid(
        'Artifact\nBand #${widget.artifact.bandId}',
        Colors.black,
        widget.artifact.toText(onChar: '*'),
        widget.artifact.toText(forCode: true),
      ),
      gap(),
      // Found Normalized
      _buildArtifactGrid(
        'Artifact\nNormalized\n${w}x$h E:${widget.artifact.matrixNormalized.enclosures} ${verticalLines(widget.artifact.matrixNormalized)}',
        Colors.grey.withAlpha(100),
        widget.artifact.getResizedString(w: w, h: h, onChar: '*'),
        widget.artifact.getResizedString(w: w, h: h, forCode: true),
      ),

      // Expected templates and matches
      ..._buildTemplates(
        scoresMatchToDisplay,
        w,
        h,
        // Artifact found
        widget.artifact.matrixNormalized,

        // Expected Character
        widget.characterExpected,
      ),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child:
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: widgets),
    );
  }

  static Widget _buildHeader(
    final String title,
    final Color headerBackgroundColor,
    final Widget child,
  ) {
    return SizedBox(
      height: 150,
      child: Column(
        children: [
          Expanded(
            child: Container(
              color: headerBackgroundColor,
              padding: const EdgeInsets.all(8.0),
              margin: const EdgeInsets.all(8.0),
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontFamily: 'Courier',
                ),
              ),
            ),
          ),
          child,
          gap(),
        ],
      ),
    );
  }

  List<Widget> _buildTemplates(
    List<ScoreMatch> scoreMatches,
    final int w,
    final int h,
    final Matrix matrixNormalized,
    // Expected
    final String characterExpected,
  ) {
    List<Widget> widgets = [];

    int index = 0;

    for (final ScoreMatch match in scoreMatches) {
      if (match.score > 0) {
        String title = 'Match ${++index}';
        Color headerColor = index == 1
            ? const Color.fromARGB(255, 169, 61, 2)
            : Colors.red.withAlpha(100);
        if (match.character == characterExpected) {
          title += ' EXPECTED';
          headerColor = Colors.green.withAlpha(100);
        }

        List<String> overlayGridText = [];
        final CharacterDefinition? definition =
            widget.textify.characterDefinitions.getDefinition(match.character);
        if (definition != null) {
          final templateMatrix = definition.matrices[match.matrixIndex];

          title +=
              '\nTeamplate "${match.character}"[${match.matrixIndex}] ${templateMatrix.font}\nScore = ${(match.score * 100).toStringAsFixed(1)}% E:${definition.enclosures}, ${verticalLinesTemplate(definition)}';

          overlayGridText = Matrix.getStringListOfOverladedGrids(
            matrixNormalized,
            templateMatrix,
          );
        }

        widgets.add(gap());
        widgets.add(
          Column(
            children: [
              _buildArtifactGrid(
                title,
                headerColor,
                overlayGridText.join('\n'),
                _getMultiLineTextForTemplate(
                  match.character,
                  false,
                  true,
                ),
              ),
              ..._buildVariations(
                  match.character,
                  matrixNormalized,
                  [0, 1, 2, 3]
                      .where((number) => number != match.matrixIndex)
                      .toList())
            ],
          ),
        );
      }
    }
    return widgets;
  }

  List<Widget> _buildVariations(
    final String character,
    final Matrix matrixFound,
    final List<int> matrixIndexes,
  ) {
    List<Widget> widgets = [];
    for (final matrixIndex in matrixIndexes) {
      final variation = _buildVariation(character, matrixFound, matrixIndex);
      if (variation != null) {
        widgets.add(variation);
      }
    }
    return widgets;
  }

  Widget? _buildVariation(
    final String character,
    final Matrix matrixFound,
    final int matrixIndex,
  ) {
    final CharacterDefinition? definition =
        widget.textify.characterDefinitions.getDefinition(character);
    if (definition != null && matrixIndex < definition.matrices.length) {
      final templatedMatrix = definition.matrices[matrixIndex];

      List<String> overlayGridText = [];
      overlayGridText = Matrix.getStringListOfOverladedGrids(
        matrixFound,
        templatedMatrix,
      );

      final double scoreForThisVariation = Matrix.hammingDistancePercentage(
            matrixFound,
            templatedMatrix,
          ) *
          100;
      return _buildArtifactGrid(
        'Template "$character"[$matrixIndex]${templatedMatrix.font}\n${scoreForThisVariation.toStringAsFixed(2)}%',
        Colors.grey.shade900,
        overlayGridText.join('\n'),
        _getMultiLineTextForTemplate(
          character,
          false,
          true,
        ),
      );
    }
    return null;
  }

  String _getMultiLineTextForTemplate(
    final String character,
    final bool resize,
    final bool forCode,
  ) {
    final List<String> textTemplate =
        widget.textify.characterDefinitions.getTemplateAsString(character);
    return Matrix.fromAsciiDefinition(textTemplate)
        .gridToString(forCode: forCode);
  }
}
