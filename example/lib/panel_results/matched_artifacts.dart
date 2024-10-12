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
double compareStringPercentage(String str1, String str2) {
  if (str1 == str2) {
    return 100.0;
  }
  if (str1.isEmpty || str2.isEmpty) {
    return 0.0;
  }

  int minLength = str1.length < str2.length ? str1.length : str2.length;
  int matchCount = 0;

  for (int i = 0; i < minLength; i++) {
    if (str1[i] == str2[i]) {
      matchCount++;
    }
  }

  return (matchCount / str1.length) * 100;
}
