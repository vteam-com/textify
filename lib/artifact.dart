// Imports
import 'dart:math';
import 'dart:ui';

import 'package:textify/matrix.dart';

/// Represents an artifact in the text processing system.
///
/// An artifact contains information about a specific character or group of characters,
/// including its position, size, and matrix representation.
class Artifact {
  /// The character that this artifact matches.
  String characterMatched = '';

  /// The original matrix representation of the artifact.
  final Matrix _matrixOriginal = Matrix();

  /// A normalized version of the matrix representation.
  final Matrix _matrixNormalized = Matrix();

  /// Returns:
  /// A string representation ths artifact.
  @override
  String toString() {
    return '"$characterMatched" Rect:${_matrixOriginal.rectangle.toString()} Area: $area}';
  }

  /// The area of the artifact, calculated from its matrix representation.
  int get area => _matrixOriginal.area;

  /// Checks if the artifact is empty (contains no 'on' pixels).
  bool get isEmpty {
    return _matrixOriginal.isEmpty;
  }

  /// Checks if the artifact is not empty (contains at least one 'on' pixel).
  bool get isNotEmpty {
    return !isEmpty;
  }

  /// Gets the original matrix representation of the artifact.
  Matrix get matrixOriginal => _matrixOriginal;

  /// Sets the original matrix representation of the artifact.
  set matrixOriginal(final Matrix value) {
    _matrixOriginal.setGrid(value.data);
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
  Matrix updateMatrixNormalizedFromOriginal(final int width, final int height) {
    final Matrix newSizedMatrix = matrixOriginal.createNormalizeMatrix(
      width,
      height,
    );
    _matrixNormalized.setGrid(newSizedMatrix.data);
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
    return _matrixOriginal.gridToString(
      forCode: forCode,
      onChar: onChar,
    );
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
      min(
        this._matrixNormalized.rectangle.left,
        toMerge._matrixNormalized.rectangle.left,
      ),
      min(
        this._matrixNormalized.rectangle.top,
        toMerge._matrixNormalized.rectangle.top,
      ),
      max(
        this._matrixNormalized.rectangle.right,
        toMerge._matrixNormalized.rectangle.right,
      ),
      max(
        this._matrixNormalized.rectangle.bottom,
        toMerge._matrixNormalized.rectangle.bottom,
      ),
    );

    // Merge the grids
    final Matrix newGrid = Matrix(newRect.width, newRect.height);

    // Copy both grids onto the new grid
    Matrix.copyGrid(
      this.matrixOriginal,
      newGrid,
      (this._matrixNormalized.rectangle.left - newRect.left).toInt(),
      (this._matrixNormalized.rectangle.top - newRect.top).toInt(),
    );

    Matrix.copyGrid(
      toMerge.matrixOriginal,
      newGrid,
      (toMerge._matrixNormalized.rectangle.left - newRect.left).toInt(),
      (toMerge._matrixNormalized.rectangle.top - newRect.top).toInt(),
    );
    this.matrixOriginal = newGrid;
    this.matrixOriginal.rectangle = this
        .matrixOriginal
        .rectangle
        .expandToInclude(toMerge.matrixOriginal.rectangle);
  }
}
