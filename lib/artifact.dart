// Imports
import 'dart:math';
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
  Rect rectangleOrinal = Rect.zero;

  /// The rectangular area that this artifact occupies.
  Rect rectangleAdjusted = Rect.zero;

  /// The original matrix representation of the artifact.
  final Matrix _matrix = Matrix();

  /// A normalized version of the matrix representation.
  final Matrix _matrixNormalized = Matrix();

  /// Returns:
  /// A string representation ths artifact.
  @override
  String toString() {
    return '"$characterMatched" Band:$bandId Rect:${rectangleAdjusted.toString()} Area: $area}';
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
  void fitToRectangleHeight(final Rect targetRect) {
    final int newHeight = targetRect.height.toInt();

    if (rectangleAdjusted.height == newHeight) {
      return; // Early return if no change needed
    }

    final List<List<bool>> originalData = matrixOriginal.data;
    final int currentWidth = matrixOriginal.cols;

    // Calculate the relative position of the artifact within the target rectangle
    final double relativeTop =
        (rectangleAdjusted.top - targetRect.top) / targetRect.height;

    final List<List<bool>> newGrid =
        _createNewGrid(originalData, newHeight, relativeTop, currentWidth);

    // Update the matrix with the new grid
    _matrix.setGrid(newGrid);

    // Adjust the rectangle to maintain relative position within the target rectangle
    rectangleAdjusted = Rect.fromLTWH(
      rectangleAdjusted.left,
      targetRect.top,
      rectangleAdjusted.width,
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
    final String onChar = '#',
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
  /// - width: The target width.
  /// - height: The target height.
  ///
  /// Returns:
  /// The resized matrix.
  Matrix resize(final int width, final int height) {
    _matrixNormalized.setGrid(
      matrixOriginal
          .createNormalizeMatrix(
            width,
            height,
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
    final String onChar = '#',
    final bool forCode = false,
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
    final List<List<bool>> originalData,
    final int newHeight,
    final double relativeTop,
    final int currentWidth,
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
    final List<List<bool>> originalData,
    final int newHeight,
    final double relativeTop,
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
    final List<List<bool>> originalData,
    final int newHeight,
    final double relativeTop,
    final int currentWidth,
  ) {
    final int topPadding =
        (relativeTop * newHeight).round().clamp(0, newHeight);
    final int bottomPadding =
        (newHeight - originalData.length - topPadding).clamp(0, newHeight);

    return [
      ...List.generate(topPadding, (_) => List.filled(currentWidth, false)),
      ...originalData,
      ...List.generate(bottomPadding, (_) => List.filled(currentWidth, false)),
    ];
  }

  /// Merges the current artifact with another artifact.
  ///
  /// This method combines the current artifact with the provided artifact,
  /// creating a new, larger artifact that encompasses both.
  ///
  /// Parameters:
  /// - [toMerge]: The Artifact to be merged with the current artifact.
  ///
  /// The merging process involves:
  /// 1. Creating a new rectangle that encompasses both artifacts.
  /// 2. Creating a new matrix (grid) large enough to contain both artifacts' data.
  /// 3. Copying the data from both artifacts into the new matrix.
  /// 4. Updating the current artifact's matrix and rectangle to reflect the merged state.
  ///
  /// Note: This method modifies the current artifact in-place.
  void mergeArtifact(final Artifact toMerge) {
    // Create a new rectangle that encompasses both artifacts
    final Rect newRect = Rect.fromLTRB(
      min(this.rectangleAdjusted.left, toMerge.rectangleAdjusted.left),
      min(this.rectangleAdjusted.top, toMerge.rectangleAdjusted.top),
      max(this.rectangleAdjusted.right, toMerge.rectangleAdjusted.right),
      max(this.rectangleAdjusted.bottom, toMerge.rectangleAdjusted.bottom),
    );

    // Merge the grids
    final Matrix newGrid = Matrix(newRect.width, newRect.height);

    // Copy both grids onto the new grid
    Matrix.copyGrid(
      this.matrixOriginal,
      newGrid,
      (this.rectangleAdjusted.left - newRect.left).toInt(),
      (this.rectangleAdjusted.top - newRect.top).toInt(),
    );

    Matrix.copyGrid(
      toMerge.matrixOriginal,
      newGrid,
      (toMerge.rectangleAdjusted.left - newRect.left).toInt(),
      (toMerge.rectangleAdjusted.top - newRect.top).toInt(),
    );
    this.matrixOriginal = newGrid;
    this.rectangleOrinal =
        this.rectangleOrinal.expandToInclude(toMerge.rectangleOrinal);
  }
}
