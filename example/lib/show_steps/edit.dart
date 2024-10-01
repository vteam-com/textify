import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:textify/artifact.dart';
import 'package:textify/character_definitions.dart';
import 'package:textify/matrix.dart';

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
          fontFamily: 'CourierPrime',
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
                  fontFamily: 'CourierPrime',
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
    final int w,
    final int h,
    final Matrix matrixNormalized,
    // Expected
    final String characterExpected,
  ) {
    List<Widget> widgets = [];

    int index = 0;
    final List<ScoreMatch> scoreMatches =
        widget.textify.getMatchingScores(widget.artifact);

    for (final ScoreMatch match in scoreMatches.take(20)) {
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
          title +=
              '\nTeamplate "${match.character}"\nScore = ${(match.score * 100).toStringAsFixed(1)}% E:${definition.enclosers}, ${verticalLinesTemplate(definition)}';

          overlayGridText = Matrix.getStringListOfOverladedGrids(
            matrixNormalized,
            definition.matrices.first,
          );
        }

        widgets.add(gap());
        widgets.add(
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
        );
      }
    }
    return widgets;
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
