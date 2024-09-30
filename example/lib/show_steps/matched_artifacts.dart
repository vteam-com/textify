import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:textify/textify.dart';

import '../image_sources/panel_content.dart';
import '../../widgets/gap.dart';
import 'edit.dart';
import 'matched_artifact.dart';

class MatchedArtifacts extends StatelessWidget {
  const MatchedArtifacts({
    super.key,
    required this.textify,
    required this.charactersExpected,
  });

  final Textify textify;
  final String charactersExpected;

  @override
  Widget build(BuildContext context) {
    if (charactersExpected.isEmpty) {
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

  void fix() {
    final String characterWithoutSpace = charactersExpected.replaceAll(' ', '');

    for (int index = 0; index < characterWithoutSpace.length; index++) {
      textify.characterDefinitions.upsertTemplate(
        characterWithoutSpace[index],
        textify.list[index].matrixNormalized,
      );
    }
  }

  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 100,
            child: OutlinedButton(onPressed: () => fix(), child: const Text('Fix')),
          ),
          gap(),
          SizedBox(
            width: 100,
            child: OutlinedButton(
              child: const Text('Copy'),
              onPressed: () {
                Clipboard.setData(
                  ClipboardData(text: textify.characterDefinitions.toJsonString()),
                );
              },
            ),
          ),
        ],
      ),
    );
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
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          ...List.generate(charactersExpected.length, (index) {
            final String characterExpected = charactersExpected[index];
            final String characterFound = index < textify.textFound.length ? textify.textFound[index] : '!';
            return InkWell(
              onTap: () {
                final discountSpacesForIndexPositionInArtifactFound =
                    countSpaces(charactersExpected.substring(0, index));
                final Artifact artifactToUse = textify.list[index - discountSpacesForIndexPositionInArtifactFound];

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EditScreen(
                      textify: textify,
                      artifact: artifactToUse,
                      characterExpected: characterExpected,
                      characterFound: characterFound,
                    ),
                  ),
                );
              },
              child: MatchedArtifact(
                firstChar: characterExpected,
                secondChar: characterFound.replaceAll('\n', ' '),
              ),
            );
          }),
        ],
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
      end: _buildActionButtons(),
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

double getPercentageOfMatches(String characters, String textFound) {
  if (characters.isEmpty) {
    return 0;
  }

  int matchCount = 0;
  textFound = textFound.replaceAll('\n', ' ');
  for (int i = 0; i < characters.length; i++) {
    if (i < textFound.length) {
      if (characters[i] == textFound[i]) {
        matchCount++;
      }
    }
  }

  double percentage = (matchCount / characters.length) * 100;
  return percentage;
}
