import 'dart:math';

import 'package:flutter/material.dart';
import 'package:textify/textify.dart';

import '../image_sources/panel_content.dart';
import '../../widgets/gap.dart';
import 'edit.dart';
import 'matched_artifact.dart';

class MatchedArtifacts extends StatelessWidget {
  const MatchedArtifacts({
    super.key,
    required this.textify,
    required this.expectedStrings,
    required this.font,
  });

  final String font;
  final Textify textify;
  final List<String> expectedStrings;

  @override
  Widget build(BuildContext context) {
    if (expectedStrings.isEmpty) {
      return _buildFreeStyleResults(context);
    } else {
      return _buildMatchingCharacter(context);
    }
  }

  int countSpaces(final String text) {
    int count = 0;

    for (int i = 0; i < text.length; i++) {
      if (text[i] == ' ') {
        count++;
      }
    }

    return count;
  }

  Widget _buildFreeStyleResults(final BuildContext context) {
    return SizedBox(
      height: 300,
      child: SingleChildScrollView(
        child: SelectableText(
          textify.textFound,
          style: const TextStyle(
            fontFamily: 'Courier',
            fontSize: 16.0,
          ),
          showCursor: true,
          cursorColor: Colors.blue,
          cursorWidth: 2.0,
          cursorRadius: const Radius.circular(2.0),
        ),
      ),
    );
  }

  Widget _buildListOfMatches(final BuildContext context) {
    List<Widget> widgets = [];
    int line = 0;

    for (final band in textify.bands) {
      int charIndex = 0;
      for (final artifact in band.artifacts) {
        final String text =
            line < expectedStrings.length ? expectedStrings[line] : '';

        final expectedCharacter =
            charIndex < text.length ? text[charIndex] : '!';

        charIndex++;
        final button = InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => EditScreen(
                  textify: textify,
                  artifact: artifact,
                  characterExpected: expectedCharacter,
                  characterFound: artifact.characterMatched,
                ),
              ),
            );
          },
          child: MatchedArtifact(
            characterExpected: expectedCharacter,
            characterFound: artifact.characterMatched,
          ),
        );
        widgets.add(button);
      }
      line++;
      widgets.add(gap());
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: widgets,
      ),
    );
  }

  Widget _buildMatchingCharacter(final BuildContext context) {
    return PanelContent(
      start: const SizedBox(),
      middle: Center(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: SizedBox(
            height: 80,
            child: Row(
              children: [
                _buildPrefixTextForMatches(),
                Expanded(child: _buildListOfMatches(context)),
              ],
            ),
          ),
        ),
      ),
      end: const SizedBox(),
    );
  }

  Widget _buildPrefixTextForMatches() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        const Text('Expected: '),
        gap(10),
        const Text('Found: '),
      ],
    );
  }
}

double getPercentageOfMatches(List<String> expectedStrings, String textFound) {
  if (expectedStrings.isEmpty) {
    return 0;
  }

  int matchCount = 0;
  List<String> stringsFound = textFound.split('\n');

  // Implement distance matching
  for (int i = 0; i < expectedStrings.length && i < stringsFound.length; i++) {
    String expected = expectedStrings[i];
    String found = stringsFound[i];

    // Calculate Levenshtein distance
    int distance = damerauLevenshteinDistance(expected, found);

    // Consider it a match if the distance is less than 30% of the expected string length
    if (distance <= (expected.length * 0.3).round()) {
      matchCount++;
    }
  }

  double percentage = (matchCount / expectedStrings.length) * 100;
  return percentage;
}

int damerauLevenshteinDistance(String source, String target) {
  if (source == target) return 0;
  if (source.isEmpty) return target.length;
  if (target.isEmpty) return source.length;

  List<List<int>> matrix = List.generate(
    source.length + 1,
    (i) => List.generate(target.length + 1, (j) => 0),
  );

  for (int i = 0; i <= source.length; i++) {
    matrix[i][0] = i;
  }
  for (int j = 0; j <= target.length; j++) {
    matrix[0][j] = j;
  }

  for (int i = 1; i <= source.length; i++) {
    for (int j = 1; j <= target.length; j++) {
      int cost = source[i - 1] == target[j - 1] ? 0 : 1;

      matrix[i][j] = [
        matrix[i - 1][j] + 1, // Deletion
        matrix[i][j - 1] + 1, // Insertion
        matrix[i - 1][j - 1] + cost, // Substitution
      ].reduce((curr, next) => curr < next ? curr : next);

      if (i > 1 &&
          j > 1 &&
          source[i - 1] == target[j - 2] &&
          source[i - 2] == target[j - 1]) {
        matrix[i][j] =
            min(matrix[i][j], matrix[i - 2][j - 2] + cost); // Transposition
      }
    }
  }

  return matrix[source.length][target.length];
}
