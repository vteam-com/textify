// Imports
import 'dart:ui';

import 'package:textify/matrix.dart';

/// Represents an artifact in the text processing system.
///
/// An artifact contains information about a specific character or group of characters,
/// including its position, size, and matrix representation.
class Artifact {
  /// Unique identifier for the band this artifact belongs to.
  int bandId = 0;

  /// The character that this artifact matches.
  String characterMatched = '';

  /// The rectangular area that this artifact occupies.
  Rect rectangle = const Rect.fromLTRB(0, 0, 0, 0);

  /// The original matrix representation of the artifact.
  final Matrix _matrix = Matrix();

  /// A normalized version of the matrix representation.
  final Matrix _matrixNormalized = Matrix();

  @override
  String toString() {
    return '${rectangle.toString()} length $area}';
  }

  /// The area of the artifact, calculated from its matrix representation.
  int get area => _matrix.area;

  /// Adjusts the artifact's height to fit within a given rectangle while maintaining its relative position.
  ///
  /// This method resizes the artifact vertically to match the height of the provided rectangle.
  /// If the original data is taller than the target rectangle, it will be cropped.
  /// If it's shorter, padding will be added to maintain the relative position.
  ///
  /// Parameters:
  /// - targetRect: The rectangle representing the area the artifact should fit into.
  void fitToRectangleHeight(Rect targetRect) {
    final int newHeight = targetRect.height.toInt();

    if (rectangle.height == newHeight) {
      return; // Early return if no change needed
    }

    final List<List<bool>> originalData = matrixOriginal.data;
    final int currentWidth = matrixOriginal.cols;

    // Calculate the relative position of the artifact within the target rectangle
    final double relativeTop =
        (rectangle.top - targetRect.top) / targetRect.height;

    final List<List<bool>> newGrid =
        _createNewGrid(originalData, newHeight, relativeTop, currentWidth);

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

  /// Returns a string representation of the resized artifact.
  ///
  /// Parameters:
  /// - w: The target width for resizing.
  /// - h: The target height for resizing.
  /// - onChar: The character to use for 'on' pixels (default: '#').
  /// - forCode: Whether the output is intended for code representation (default: false).
  ///
  /// Returns:
  /// A string representation of the resized artifact.
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

  /// Checks if the artifact is empty (contains no 'on' pixels).
  bool get isEmpty {
    return _matrix.isEmpty;
  }

  /// Checks if the artifact is not empty (contains at least one 'on' pixel).
  bool get isNotEmpty {
    return !isEmpty;
  }

  /// Gets the original matrix representation of the artifact.
  Matrix get matrixOriginal => _matrix;

  /// Sets the original matrix representation of the artifact.
  set matrixOriginal(final Matrix value) {
    _matrix.data = value.data;
    _matrix.cols = value.cols;
    _matrix.rows = value.rows;
  }

  /// Gets the normalized matrix representation of the artifact.
  Matrix get matrixNormalized => _matrixNormalized;

  /// Resizes the artifact to the specified width and height.
  ///
  /// Parameters:
  /// - w: The target width.
  /// - h: The target height.
  ///
  /// Returns:
  /// The resized matrix.
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

  /// Converts the artifact to a text representation.
  ///
  /// Parameters:
  /// - onChar: The character to use for 'on' pixels (default: '#').
  /// - forCode: Whether the output is intended for code representation (default: false).
  ///
  /// Returns:
  /// A string representation of the artifact.
  String toText({
    String onChar = '#',
    bool forCode = false,
  }) {
    return _matrix.gridToString(
      forCode: forCode,
      onChar: onChar,
    );
  }

  /// Creates a new grid based on the original data and the new height.
  ///
  /// This method decides whether to crop or pad the grid based on the new height.
  ///
  /// Parameters:
  /// - originalData: The original boolean matrix data.
  /// - newHeight: The target height for the new grid.
  /// - relativeTop: The relative top position of the artifact within the target rectangle.
  /// - currentWidth: The current width of the grid.
  ///
  /// Returns:
  /// A new List<List<bool>> representing the adjusted grid.
  List<List<bool>> _createNewGrid(
    List<List<bool>> originalData,
    int newHeight,
    double relativeTop,
    int currentWidth,
  ) {
    if (originalData.length > newHeight) {
      return _cropGrid(originalData, newHeight, relativeTop);
    } else {
      return _padGrid(originalData, newHeight, relativeTop, currentWidth);
    }
  }

  /// Crops the original grid to fit the new height.
  ///
  /// Parameters:
  /// - originalData: The original boolean matrix data.
  /// - newHeight: The target height for the new grid.
  /// - relativeTop: The relative top position of the artifact within the target rectangle.
  ///
  /// Returns:
  /// A new List<List<bool>> representing the cropped grid.
  List<List<bool>> _cropGrid(
    List<List<bool>> originalData,
    int newHeight,
    double relativeTop,
  ) {
    int startRow = (relativeTop * originalData.length).round();
    startRow = startRow.clamp(0, originalData.length - newHeight);
    return originalData.sublist(startRow, startRow + newHeight);
  }

  /// Pads the original grid to fit the new height.
  ///
  /// Parameters:
  /// - originalData: The original boolean matrix data.
  /// - newHeight: The target height for the new grid.
  /// - relativeTop: The relative top position of the artifact within the target rectangle.
  /// - currentWidth: The current width of the grid.
  ///
  /// Returns:
  /// A new List<List<bool>> representing the padded grid.
  List<List<bool>> _padGrid(
    List<List<bool>> originalData,
    int newHeight,
    double relativeTop,
    int currentWidth,
  ) {
    int topPadding = (relativeTop * newHeight).round().clamp(0, newHeight);
    int bottomPadding =
        (newHeight - originalData.length - topPadding).clamp(0, newHeight);

    return [
      ...List.generate(topPadding, (_) => List.filled(currentWidth, false)),
      ...originalData,
      ...List.generate(bottomPadding, (_) => List.filled(currentWidth, false)),
    ];
  }
}
