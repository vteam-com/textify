import 'package:flutter/material.dart';

class MatchedArtifact extends StatelessWidget {
  const MatchedArtifact({
    super.key,
    required this.characterExpected,
    required this.characterFound,
    required this.characterCorrected,
    required this.showCorrectionRow,
  });

  final String characterExpected;
  final String characterFound;
  final String characterCorrected;
  final bool showCorrectionRow;

  @override
  Widget build(BuildContext context) {
    const TextStyle style = TextStyle(
      fontSize: 20,
      fontFamily: 'Courier',
    );

    final TextStyle greenStyle =
        style.copyWith(color: Colors.lightGreen.shade400);
    final TextStyle blackStyle =
        style.copyWith(color: Theme.of(context).colorScheme.onPrimaryContainer);
    final TextStyle redStyle = style.copyWith(color: Colors.orange);

    return Container(
      margin: const EdgeInsets.all(1),
      width: 18,
      decoration: BoxDecoration(
        border: Border.all(
          color: characterExpected == characterCorrected
              ? Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.2)
              : Colors.orange.withValues(alpha: 0.5),
          width: 1.0,
        ),
        borderRadius: BorderRadius.circular(4.0),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        spacing: 6,
        children: [
          Text(
            characterFound,
            style: characterExpected == characterFound ? greenStyle : redStyle,
          ),
          if (showCorrectionRow)
            Text(
              characterCorrected,
              style: characterExpected == characterCorrected
                  ? greenStyle
                  : redStyle,
            ),
          Text(
            characterExpected,
            style:
                characterExpected == characterFound ? greenStyle : blackStyle,
          ),
        ],
      ),
    );
  }
}
