import 'dart:math';

import 'package:flutter/material.dart';
import 'package:textify/band.dart';
import 'package:textify/textify.dart';
import 'package:textify_dashboard/panel_source/panel_content.dart';
import 'package:textify_dashboard/widgets/display_artifact.dart';
import 'package:textify_dashboard/widgets/gap.dart';
import 'package:textify_dashboard/widgets/image_viewer.dart';

const int offsetX = 00;
const int offsetY = 14;

class DisplayBandsAndArtifacts extends StatelessWidget {
  const DisplayBandsAndArtifacts({
    super.key,
    required this.textify,
    required this.applyPacking,
  });

  final bool applyPacking;
  final Textify textify;

  @override
  Widget build(BuildContext context) {
    double maxWidth = 0;
    double maxHeight = 0;
    for (final Band band in textify.bands) {
      if (band.artifacts.isNotEmpty) {
        maxWidth = max(maxWidth, band.rectangle.right + offsetX);
        maxHeight = max(maxHeight, band.rectangle.bottom + offsetY);
      }
    }

    return SizedBox(
      width: maxWidth,
      height: maxHeight + 100,
      child: CustomPaint(
        key: Key(textify.processEnd.toString()),
        painter: DisplayArtifacts(
          textify: textify,
          applyPacking: applyPacking,
        ),
        size: Size(maxWidth, maxHeight),
      ),
    );
  }
}

Widget buildArtifactFound(
  final Textify textify,
  final bool cleanUpArtifacts,
  final TransformationController transformationController,
  final Function onToggleCleanup,
) {
  return PanelContent(
    top: _buildActionButtons(
      onToggleCleanup,
      cleanUpArtifacts,
      transformationController,
    ),
    center: CustomInteractiveViewer(
      transformationController: transformationController,
      child: DisplayBandsAndArtifacts(
        textify: textify,
        applyPacking: cleanUpArtifacts,
      ),
    ),
  );
}

Widget _buildActionButtons(
  final Function onToggleCleanup,
  final bool cleanUpArtifacts,
  final TransformationController transformationController,
) {
  return Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      OutlinedButton(
        onPressed: () {
          transformationController.value =
              transformationController.value.scaled(1 / 1.5);
        },
        child: const Text('Zoom -'),
      ),
      gap(),
      OutlinedButton(
        onPressed: () {
          transformationController.value =
              transformationController.value.scaled(1.5);
        },
        child: const Text('Zoom +'),
      ),
      gap(),
      OutlinedButton(
        onPressed: () {
          transformationController.value = Matrix4.identity();
        },
        child: const Text('Center'),
      ),
      gap(),
      OutlinedButton(
        onPressed: () {
          onToggleCleanup();
        },
        child: Text(cleanUpArtifacts ? 'Original' : 'Normalized'),
      ),
    ],
  );
}
