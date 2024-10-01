import 'package:flutter/material.dart';

import '../../widgets/gap.dart';

class MatchedArtifact extends StatelessWidget {
  const MatchedArtifact({
    super.key,
    required this.firstChar,
    required this.secondChar,
  });

  final String firstChar;
  final String secondChar;

  @override
  Widget build(BuildContext context) {
    const TextStyle style = TextStyle(
      fontSize: 20,
      fontFamily: 'CourierPrime',
    );

    final TextStyle greenStyle =
        style.copyWith(color: Colors.lightGreen.shade400);
    final TextStyle blackStyle =
        style.copyWith(color: Theme.of(context).colorScheme.onPrimaryContainer);
    final TextStyle redStyle = style.copyWith(color: Colors.orange);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 1),
      width: 18,
      decoration: BoxDecoration(
        border: Border.all(
          color: firstChar == secondChar
              ? Theme.of(context).colorScheme.onSurface.withOpacity(0.5)
              : Colors.orange,
          width: 1.0,
        ),
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            firstChar,
            style: firstChar == secondChar ? greenStyle : blackStyle,
          ),
          gap(6),
          Text(
            secondChar,
            style: firstChar == secondChar ? greenStyle : redStyle,
          ),
        ],
      ),
    );
  }
}
