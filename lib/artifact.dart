// Imports
import 'dart:ui';

import 'package:textify/matrix.dart';

class Artifact {
  int bandId = 0;
  String characterMatched = '';
  Rect rectangle = const Rect.fromLTRB(0, 0, 0, 0);

  final Matrix _matrix = Matrix();
  final Matrix _matrixNormalized = Matrix();

  @override
  String toString() {
    return '${rectangle.toString()} length $area}';
  }

  int get area => _matrix.area;

  /// Adjusts the artifact's height to fit within a given rectangle while maintaining its relative position.
  ///
  /// This method resizes the artifact vertically to match the height of the provided rectangle.
  /// If the original data is taller than the target rectangle, it will be cropped.
  /// If it's shorter, padding will be added to maintain the relative position.
  ///
  /// Parameters:
  /// - targetRect: The rectangle representing the area the artifact should fit into.
  ///
  /// The method performs the following steps:
  /// 1. Checks if resizing is necessary.
  /// 2. Calculates the new dimensions and relative position.
  /// 3. Creates a new grid, either by cropping or adding padding as needed.
  /// 4. Updates the internal matrix representation with the new grid.
  /// 5. Adjusts the artifact's rectangle to reflect its new position and size.
  ///
  /// Note: This method assumes that the width of the artifact remains unchanged.
  void fitToRectangleHeight(Rect targetRect) {
    final int newHeight = targetRect.height.toInt();

    if (rectangle.height == newHeight) {
      return; // No change needed
    }

    int currentWidth = matrixOriginal.cols;
    List<List<bool>> originalData = matrixOriginal.data;

    // Calculate the relative position of the artifact within the target rectangle
    double relativeTop = (rectangle.top - targetRect.top) / targetRect.height;

    late final List<List<bool>> newGrid;

    if (originalData.length > newHeight) {
      // If original data is taller, crop it
      int startRow = (relativeTop * originalData.length).round();
      startRow = startRow.clamp(0, originalData.length - newHeight);
      newGrid = originalData.sublist(startRow, startRow + newHeight);
    } else {
      // If original data is shorter or equal, add padding
      int topPadding = (relativeTop * newHeight).round();
      int bottomPadding = newHeight - originalData.length - topPadding;

      // Ensure non-negative padding
      topPadding = topPadding.clamp(0, newHeight);
      bottomPadding = bottomPadding.clamp(0, newHeight);

      newGrid = [
        ...List.generate(topPadding, (_) => List.filled(currentWidth, false)),
        ...originalData,
        ...List.generate(
          bottomPadding,
          (_) => List.filled(currentWidth, false),
        ),
      ];
    }

    // Update the matrix with the new grid
    _matrix.setGrid(newGrid);

    // Adjust the rectangle to maintain relative position within the target rectangle
    rectangle = Rect.fromLTWH(
      rectangle.left,
      targetRect.top,
      rectangle.width,
      targetRect.height,
    );
  }

  String getResizedString({
    required final int w,
    required final int h,
    String onChar = '#',
    final bool forCode = false,
  }) {
    _matrixNormalized.data = matrixOriginal.createNormalizeMatrix(w, h).data;
    _matrixNormalized.cols = w;
    _matrixNormalized.rows = h;

    return _matrixNormalized.gridToString(
      forCode: forCode,
      onChar: onChar,
    );
  }

  bool get isEmpty {
    return _matrix.isEmpty;
  }

  bool get isNotEmpty {
    return !isEmpty;
  }

  Matrix get matrixOriginal => _matrix;

  set matrixOriginal(final Matrix value) {
    _matrix.data = value.data;
    _matrix.cols = value.cols;
    _matrix.rows = value.rows;
  }

  Matrix get matrixNormalized => _matrixNormalized;

  Matrix resize(int w, int h) {
    _matrixNormalized.setGrid(
      matrixOriginal
          .createNormalizeMatrix(
            w,
            h,
          )
          .data,
    );
    return _matrixNormalized;
  }

  String toText({
    String onChar = '#',
    bool forCode = false,
  }) {
    return _matrix.gridToString(
      forCode: forCode,
      onChar: onChar,
    );
  }
}
