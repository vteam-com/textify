import 'package:flutter/material.dart';

class PanelContent extends StatelessWidget {
  const PanelContent({
    super.key,
    this.left,
    this.top,
    required this.center,
    this.bottom,
    this.right,
  });

  final Widget? left;
  final Widget? top;
  final Widget center;
  final Widget? bottom;
  final Widget? right;

  @override
  Widget build(final BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        if (left != null) left!,
        Expanded(
          child: Column(
            children: [
              if (top != null) top!,
              Container(
                height: 400,
                margin: const EdgeInsets.only(top: 13, bottom: 3),
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8.0),
                  border: Border.all(
                    color:
                        Theme.of(context).colorScheme.secondary.withAlpha(200),
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
                child: center,
              ),
              if (bottom != null) bottom!,
            ],
          ),
        ),
        if (right != null) right!,
      ],
    );
  }
}
