import 'package:flutter/material.dart';
import 'package:textify/artifact.dart';
import 'package:textify/band.dart';
import 'package:textify/textify.dart';
import 'package:textify_dashoard/widgets/paint_grid.dart';

class DisplayArtifacts extends CustomPainter {
  DisplayArtifacts({
    required this.textify,
    required this.applyPacking,
  });

  final Textify textify;
  final bool applyPacking;

  int p = 9;

  @override
  void paint(Canvas canvas, Size size) {
    if (applyPacking) {
      _paintAsRows(canvas, size);
    } else {
      // Paints the bands and artifacts on the canvas in their original positions.
      _paintArtifactsExactlyWhereTheyAreFound(canvas, textify.artifacts);
    }
  }

  @override
  bool shouldRepaint(DisplayArtifacts oldDelegate) => false;

  void _drawRectangle(
    Canvas canvas,
    Rect bandRect,
    Color background,
  ) {
    final paintRect = Paint();
    paintRect.color = background;
    canvas.drawRect(bandRect, paintRect);
  }

  void _drawText(Canvas canvas, double x, double y, String text,
      [double fontSize = 10]) {
    // Draw information about the band
    final textSpan = TextSpan(
      text: text,
      style: TextStyle(
        color: Colors.white,
        fontSize: fontSize,
      ),
    );
    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(x, y),
    );
  }

  String _getBandTitle(final Band band) {
    int id = textify.bands.indexOf(band) + 1;

    return '$id: found ${band.artifacts.length}   AW:${band.averageWidth.toStringAsFixed(1)}   AG:${band.averageKerning.toStringAsFixed(1)} S:${band.spacesCount}';
  }

  void _paintArtifactsInRow({
    required final Canvas canvas,
    required final List<Artifact> artifactsInTheBand,
  }) {
    List<Color> colors = [
      Colors.blue.shade300,
      Colors.green.shade300,
    ];

    // artifact in that band
    int id = 1;
    for (final Artifact artifact in artifactsInTheBand) {
      paintMatrix(
        canvas,
        colors[textify.artifacts.indexOf(artifact) % colors.length],
        artifact.rectangleAdjusted.left.toInt(),
        artifact.rectangleAdjusted.top.toInt(),
        artifact.matrixOriginal,
      );
      _drawText(canvas, artifact.rectangleAdjusted.left,
          artifact.rectangleAdjusted.top, id.toString(), 8);
      id++;
    }
  }

  void _paintArtifactsExactlyWhereTheyAreFound(
    Canvas canvas,
    List<Artifact> artifactsInTheBand,
  ) {
    // Rainbow colors
    List<Color> colors = [
      Colors.red.shade200,
      Colors.orange.shade200,
      Colors.yellow.shade200,
      Colors.green.shade200,
      Colors.blue.shade200,
      Colors.indigo.shade200,
      Colors.deepPurple.shade200, // Using deepPurple as it's closer to violet
    ];

    // artifact in that band
    for (Artifact artifact in artifactsInTheBand) {
      paintMatrix(
        canvas,
        colors[textify.artifacts.indexOf(artifact) % colors.length],
        artifact.rectangleOrinal.left.toInt(),
        artifact.rectangleOrinal.top.toInt(),
        artifact.matrixOriginal,
      );
    }
  }

  /// Organizes artifacts into bands and adjusts their positions.
  ///
  /// This method sorts the artifacts by band and left position, then arranges
  /// them into bands with specified spacing. It updates the positions of the
  /// artifacts and populates the `bands` list with the calculated band rectangles.
  ///
  /// The method performs the following steps:
  /// 1. Sorts artifacts by band and left position.
  /// 2. Iterates through sorted artifacts, grouping them into bands.
  /// 3. Positions artifacts within each band, maintaining horizontal spacing.
  /// 4. Creates new bands as needed, with vertical spacing between bands.
  /// 5. Updates the `bands` list with the final calculated band rectangles.
  ///
  /// If either the artifact list or the bands list is empty, the method returns
  /// without making any changes.
  ///
  /// Note: This method assumes that the `list` property contains the artifacts to be
  /// packed, and it will update the `bands` property with the new band data.
  void _paintAsRows(Canvas canvas, Size size) {
    for (final Band band in textify.bands) {
      _paintBand(canvas: canvas, band: band);
      _paintArtifactsInRow(canvas: canvas, artifactsInTheBand: band.artifacts);
    }
  }

  void _paintBand({
    required final Canvas canvas,
    required final Band band,
  }) {
    final caption = _getBandTitle(band);
    final bandRect = Band.getBoundingBox(band.artifacts);

    // main regsion in blue
    _drawRectangle(
      canvas,
      bandRect,
      Colors.black.withAlpha(200),
    );

    // information about the band
    if (caption.isNotEmpty) {
      _drawText(
        canvas,
        bandRect.left,
        bandRect.top - 12,
        caption,
      );
    }
  }
}
