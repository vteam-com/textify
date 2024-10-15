import 'package:flutter/material.dart';
import 'package:textify/textify.dart';
import 'package:textify_dashboard/panel1_source/panel_content.dart';
import 'package:textify_dashboard/panel3_artifacts/display_bands_and_artifacts.dart';
import 'package:textify_dashboard/widgets/gap.dart';
import 'package:textify_dashboard/widgets/image_viewer.dart';

Widget panelArtifactFound(
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
