import 'package:flutter/material.dart';

class PanelContent extends StatelessWidget {
  const PanelContent({
    super.key,
    required this.middle,
    required this.end,
    required this.start,
  });

  final Widget end;
  final Widget middle;
  final Widget start;

  @override
  Widget build(final BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        start,
        Expanded(
          child: Container(
            height: 400,
            margin: const EdgeInsets.only(top: 13, bottom: 3),
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8.0),
              border: Border.all(
                color: Theme.of(context).colorScheme.secondary.withAlpha(200),
              ),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.orange.shade900.withAlpha(50),
                  Colors.purple.shade900.withAlpha(50),
                  Colors.blue.shade900.withAlpha(50),
                ],
              ),
            ),
            child: middle,
          ),
        ),
        end,
      ],
    );
  }
}
