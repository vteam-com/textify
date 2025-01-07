import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:textify_dashboard/panel1_source/panel_content.dart';
import 'package:textify_dashboard/widgets/gap.dart';
import 'package:textify_dashboard/widgets/image_viewer.dart';

class ThresholdControlWidget extends StatelessWidget {
  const ThresholdControlWidget({
    super.key,
    required this.kernelSizeErode,
    required this.kernelSizeDilate,
    required this.grayscaleLevel,
    required this.onChanged,
    required this.onReset,
  });
  final int kernelSizeErode;
  final int kernelSizeDilate;
  final int grayscaleLevel;
  final Function(int, int, int) onChanged;
  final Function onReset;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      spacing: 40,
      children: [
        _buildGrayscaleButtons(),
        _buildErodeButtons(),
        _buildDilateButtons(),
        OutlinedButton(
          onPressed: () {
            onReset();
          },
          child: Text('Reset'),
        ),
      ],
    );
  }

  Widget _buildGrayscaleButtons() {
    return Row(
      children: [
        _buildButton('-', () {
          if (grayscaleLevel > 0) {
            onChanged(
              kernelSizeErode,
              kernelSizeDilate,
              grayscaleLevel - 1,
            );
          }
        }),
        gap(),
        Text('GrayScale: $grayscaleLevel'), // Display current grayscale level
        gap(),
        _buildButton('+', () {
          if (grayscaleLevel < 255) {
            onChanged(
              kernelSizeErode,
              kernelSizeDilate,
              grayscaleLevel + 1,
            );
          }
        }),
      ],
    );
  }

  Widget _buildErodeButtons() {
    return Row(
      children: [
        _buildButton('-', () {
          if (kernelSizeErode > 0) {
            onChanged(
              kernelSizeErode - 1,
              kernelSizeDilate,
              grayscaleLevel,
            );
          }
        }),
        gap(),
        Text('Erode: $kernelSizeErode'),
        gap(),
        _buildButton('+', () {
          onChanged(
            kernelSizeErode + 1,
            kernelSizeDilate,
            grayscaleLevel,
          );
        }),
      ],
    );
  }

  Widget _buildDilateButtons() {
    return Row(
      children: [
        _buildButton('-', () {
          if (kernelSizeDilate > 0) {
            onChanged(
              kernelSizeErode,
              kernelSizeDilate - 1,
              grayscaleLevel,
            );
          }
        }),
        gap(),
        Text('Dilate: $kernelSizeDilate'),
        gap(),
        _buildButton('+', () {
          onChanged(
            kernelSizeErode,
            kernelSizeDilate + 1,
            grayscaleLevel,
          );
        }),
      ],
    );
  }

  // New helper method to create buttons
  Widget _buildButton(String label, VoidCallback onPressed) {
    return OutlinedButton(
      onPressed: onPressed,
      child: Text(label),
    );
  }
}

Widget panelOptimizedImage({
  required final ui.Image? imageBlackOnWhite,
  required final int kernelSizeErode,
  required final int kernelSizeDilate,
  required final int grayscaleLevel,
  required final Function(int, int, int) thresoldsChanged,
  required final Function onReset,
  required final TransformationController transformationController,
}) {
  return PanelContent(
    top: ThresholdControlWidget(
      kernelSizeErode: kernelSizeErode,
      kernelSizeDilate: kernelSizeDilate,
      grayscaleLevel: grayscaleLevel,
      onChanged: thresoldsChanged,
      onReset: onReset,
    ),
    center: imageBlackOnWhite == null
        ? null
        : buildInteractiveImageViewer(
            imageBlackOnWhite,
            transformationController,
          ),
  );
}
