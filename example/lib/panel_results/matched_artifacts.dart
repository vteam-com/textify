import 'dart:math';

import 'package:flutter/material.dart';
import 'package:textify/textify.dart';
import 'package:textify_dashboard/panel_source/panel_content.dart';
import 'package:textify_dashboard/widgets/gap.dart';
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
      center: Center(
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

  List<String> stringsFound = textFound.split('\n');

  double totalPercentages = 0;

  // Implement distance matching
  for (int i = 0; i < expectedStrings.length && i < stringsFound.length; i++) {
    String expected = expectedStrings[i];
    String found = stringsFound[i];

    double singleResult = compareStringInPercentage(expected, found);
    totalPercentages += singleResult;
  }

  double percentage = totalPercentages / expectedStrings.length;
  return percentage;
}

/// Compares two strings and returns their similarity as a percentage.
///
/// This function uses the Levenshtein distance algorithm to calculate the
/// edit distance between the two strings, and then converts it to a percentage
/// based on the maximum length of the strings.
///
/// If the two strings are identical, it returns 100.0. If either string is
/// empty, it returns 0.0.
///
/// Example usage:
///
/// ```dart
/// String s1 = "hello";
/// String s2 = "hallo";
/// double similarity = compareStringInPercentage(s1, s2);
/// print("Similarity: ${similarity.toStringAsFixed(2)}%"); // Output: Similarity: 80.00%
/// ```
///
/// Parameters:
///   s1: The first string to compare.
///   s2: The second string to compare.
///
/// Returns:
///   A double value representing the similarity percentage between the two
///   strings, clamped between 0.0 and 100.0.
double compareStringInPercentage(final String s1, final String s2) {
  if (s1 == s2) {
    return 100.0;
  }
  if (s1.isEmpty || s2.isEmpty) {
    return 0.0;
  }

  final int len1 = s1.length;
  final int len2 = s2.length;

  List<int> prevRow = List<int>.generate(len2 + 1, (i) => i);
  List<int> currentRow = List<int>.filled(len2 + 1, 0);

  for (int i = 0; i < len1; i++) {
    currentRow[0] = i + 1;

    for (int j = 0; j < len2; j++) {
      int insertCost = currentRow[j] + 1;
      int deleteCost = prevRow[j + 1] + 1;
      int replaceCost = prevRow[j] + (s1[i] != s2[j] ? 1 : 0);

      currentRow[j + 1] = [insertCost, deleteCost, replaceCost].reduce(min);
    }

    // swap
    final List<int> temp = prevRow;
    prevRow = currentRow;
    currentRow = temp;
  }

  int levenshteinDistance = prevRow[len2];
  int maxLength = max(len1, len2);

  return ((1 - levenshteinDistance / maxLength) * 100).clamp(0.0, 100.0);
}

int damerauLevenshteinDistance(String source, String target) {
  if (source == target) {
    return 0;
  }
  if (source.isEmpty) {
    return target.length;
  }
  if (target.isEmpty) {
    return source.length;
  }

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
