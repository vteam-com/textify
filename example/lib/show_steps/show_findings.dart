import 'dart:math';

import 'package:flutter/material.dart';
import 'package:textify/artifact.dart';
import 'package:textify/band.dart';
import 'package:textify/matrix.dart';
import 'package:textify/textify.dart';

const int offsetX = 00;
const int offsetY = 14;

class ShowFindings extends StatelessWidget {
  const ShowFindings({
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
      maxWidth = max(maxWidth, band.rectangle.right + offsetX);
      maxHeight = max(maxHeight, band.rectangle.bottom + offsetY);
    }

    return SizedBox(
      width: maxWidth,
      height: maxHeight + 100,
      child: CustomPaint(
        painter: DisplayArtifacts(
          textify: textify,
          applyPacking: applyPacking,
        ),
        size: Size(maxWidth, maxHeight),
      ),
    );
  }
}

class DisplayArtifacts extends CustomPainter {
  DisplayArtifacts({
    required this.textify,
    required this.applyPacking,
  });

  final Textify textify;
  final bool applyPacking;
  final int characterSpacing = 2;

  int p = 9;

  @override
  void paint(Canvas canvas, Size size) {
    if (applyPacking) {
      paintAsRows(canvas, size);
    } else {
      paintAsIs(canvas, size);
    }
  }

  @override
  bool shouldRepaint(DisplayArtifacts oldDelegate) => false;

  void drawRectangle(
    Canvas canvas,
    Rect bandRect,
    Color background,
  ) {
    final paintRect = Paint();
    paintRect.color = background;
    canvas.drawRect(bandRect, paintRect);
  }

  void drawText(Canvas canvas, double x, double y, String text,
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

  String getBandTitle(final bandNumber) {
    final Band band = textify.bands[bandNumber];

    return '${bandNumber + 1}: found ${band.artifacts.length}   AW:${band.averageWidth.toStringAsFixed(1)}   AG:${band.averageGap.toStringAsFixed(1)} S:${band.spacesCount}';
  }

  Size getRectSizeFromArtifacts(
    final List<Artifact> artifactsInTheRect,
  ) {
    double w = 0;
    double maxH = 0;
    for (final artifact in artifactsInTheRect) {
      w += artifact.rectangle.width;
      w += characterSpacing;
      maxH = max(maxH, artifact.rectangle.height);
    }
    // remove the last spacing
    w -= characterSpacing;
    return Size(w, maxH);
  }

  void paintArtifactsInRow({
    required final Canvas canvas,
    required final List<Artifact> artifactsInTheBand,
    required final Rect bandRect,
  }) {
    List<Color> colors = [
      Colors.blue.shade300,
      Colors.green.shade300,
    ];

    double x = bandRect.left;

    // artifact in that band
    int id = 1;
    for (final Artifact artifact in artifactsInTheBand) {
      paintSmallGrid(
        canvas,
        colors[textify.list.indexOf(artifact) % colors.length],
        x.toInt(),
        bandRect.top.toInt(),
        artifact.matrixOriginal,
      );
      drawText(canvas, x, bandRect.top, id.toString(), 8);
      id++;
      // next horizontal position
      x += artifact.rectangle.width;
      x += characterSpacing; // space between each characters
    }
  }

  void paintArtifactsWhereTheyFound(
    List<Artifact> artifactsInTheBand,
    Canvas canvas,
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
      paintSmallGrid(
        canvas,
        colors[textify.list.indexOf(artifact) % colors.length],
        artifact.rectangle.left.toInt(),
        artifact.rectangle.top.toInt(),
        artifact.matrixOriginal,
      );
    }
  }

  /// Paints the bands and artifacts on the canvas in their original positions.
  ///
  /// This method iterates through all bands in the artifacts collection and
  /// paints each band along with its associated artifacts on the canvas.
  ///
  /// @param canvas The Canvas object to paint on.
  /// @param size The Size of the canvas (not used in this method, but may be useful for future modifications).
  void paintAsIs(Canvas canvas, Size size) {
    // Iterate through all bands in the artifacts collection
    for (int bandIndex = 0; bandIndex < textify.bands.length; bandIndex++) {
      // Get the current band's rectangle
      final Rect ar = textify.bands[bandIndex].rectangle;

      // Create a new rectangle with offset applied
      // This adjusts the position of the band on the canvas
      final Rect rect = Rect.fromLTWH(
        ar.left,
        ar.top,
        ar.width,
        ar.height,
      );

      // Paint the band and its artifacts
      paintBandAndArtifacts(
        canvas,
        // The adjusted rectangle for the band
        rect,
        // Get artifacts for this band
        textify.artifactsInBand(bandIndex),
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
  void paintAsRows(Canvas canvas, Size size) {
    // // Sort artifacts by band and then by left position within each band
    // artifacts.list.sort((a, b) {
    //   if (a.bandId != b.bandId) {
    //     return a.bandId.compareTo(b.bandId);
    //   }
    //   return a.rectangle.left.compareTo(b.rectangle.left);
    // });

    double currentY = 10;

    for (int bandIndex = 0; bandIndex < textify.bands.length; bandIndex++) {
      final Band band = textify.bands[bandIndex];

      final Size rectSize = getRectSizeFromArtifacts(band.artifacts);

      final Rect rectangle = Rect.fromLTWH(
        0,
        currentY,
        rectSize.width,
        rectSize.height,
      );

      paintBandAndLabel(
        canvas: canvas,
        caption: getBandTitle(bandIndex),
        bandRect: rectangle,
        background: Colors.black.withAlpha(200),
      );

      paintArtifactsInRow(
        canvas: canvas,
        artifactsInTheBand: band.artifacts,
        bandRect: rectangle,
      );

      currentY += band.rectangle.height + offsetY;
    }
  }

  void paintBandAndArtifacts(
    Canvas canvas,
    Rect bandRect,
    List<Artifact> artifactsInTheBand,
  ) {
    // main regsion in blue
    drawRectangle(canvas, bandRect, Colors.black.withAlpha(100));

    // artifact in that band
    paintArtifactsWhereTheyFound(artifactsInTheBand, canvas);
  }

  void paintBandAndLabel({
    required final Canvas canvas,
    required final String caption,
    required final Rect bandRect,
    required final Color background,
  }) {
    // main regsion in blue
    drawRectangle(canvas, bandRect, background);

    // information about the band
    if (caption.isNotEmpty) {
      drawText(
        canvas,
        bandRect.left,
        bandRect.top - 12,
        caption,
      );
    }
  }

  void paintSmallGrid(
    final Canvas canvas,
    final Color color,
    final int startX,
    final int startY,
    final Matrix matrix,
  ) {
    const double pixelSize = 1;
    const double gapForOn = pixelSize * 0.1;
    const double gapForOff = pixelSize * 0.2;
    final double sizeForOn = 1 - (gapForOn * 2);
    final double sizeForOff = 1 - (gapForOff * 2);

    final paintBackground = Paint();
    paintBackground.style = PaintingStyle.fill;
    paintBackground.color = Colors.white.withAlpha(100);

    final paintForeground = Paint();
    paintForeground.style = PaintingStyle.fill;
    paintForeground.color = color;

    final int rows = matrix.rows;
    final int cols = matrix.cols;
    final data = matrix.data;

    for (int y = 0; y < rows; y++) {
      final double yPos = startY + y.toDouble();
      for (int x = 0; x < cols; x++) {
        final double xPos = startX + x.toDouble();
        if (data[y][x]) {
          canvas.drawRect(
            Rect.fromLTWH(
                xPos + gapForOn, yPos + gapForOn, sizeForOn, sizeForOn),
            paintForeground,
          );
        } else {
          canvas.drawRect(
            Rect.fromLTWH(
                xPos + gapForOff, yPos + gapForOff, sizeForOff, sizeForOff),
            paintBackground,
          );
        }
      }
    }
  }
}
