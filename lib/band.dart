import 'package:flutter/widgets.dart';
import 'package:textify/artifact.dart';

/// Represents a horizontal band or strip in an image or document.
///
/// A Band contains multiple [Artifact] objects and provides methods for
/// analyzing their layout and characteristics.
class Band {
  /// Creates a new Band with the specified rectangle.
  ///
  /// The [rectangle] parameter defines the boundaries of the band.
  Band(this.rectangle);

  /// List of artifacts contained within this band.
  List<Artifact> artifacts = [];

  /// The rectangular area that defines the boundaries of this band.
  Rect rectangle;

  // Private fields to store calculated average of space between earh artifacts
  double _averageGap = -1;

  // Private fields to store calculated average of artifact width
  double _averageWidth = -1;

  /// Gets the average gap between adjacent artifacts in the band.
  ///
  /// Triggers calculation if not previously computed.
  ///
  /// Returns:
  /// The average gap as a double, or -1 if there are fewer than 2 artifacts.
  double get averageGap {
    if ((_averageGap == -1 || _averageWidth == -1)) {
      calculateAverages();
    }
    return _averageGap;
  }

  /// Gets the average width of artifacts in the band.
  ///
  /// Triggers calculation if not previously computed.
  ///
  /// Returns:
  /// The average width as a double, or -1 if there are fewer than 2 artifacts.
  double get averageWidth {
    if ((_averageGap == -1 || _averageWidth == -1)) {
      calculateAverages();
    }
    return _averageWidth;
  }

  /// Calculates the average gap between adjacent artifacts and their average width.
  ///
  /// This method computes the mean horizontal distance between the right edge of
  /// one artifact and the left edge of the next artifact in the list. It also
  /// calculates the average width of all artifacts. The artifacts are assumed
  /// to be sorted from left to right.
  ///
  /// If there are fewer than 2 artifacts, both averages are set to -1.
  void calculateAverages() {
    if (artifacts.length < 2) {
      _averageGap = -1;
      _averageWidth = -1;
      return;
    }

    double totalWidth = 0;
    double totalGap = 0;
    int count = artifacts.length;

    for (int i = 1; i < artifacts.length; i++) {
      final artifact = artifacts[i];
      double gap = artifact.rectangle.left - artifacts[i - 1].rectangle.right;
      totalGap += gap;
      totalWidth += artifact.rectangle.width;
    }
    _averageWidth = totalWidth / count;
    _averageGap = totalGap / count;
  }

  /// Sorts the artifacts in this band from left to right.
  ///
  /// This method orders the artifacts based on their left edge position,
  /// ensuring they are in the correct sequence as they appear in the band.
  void sortLeftToRight() {
    artifacts.sort((a, b) => a.rectangle.left.compareTo(b.rectangle.left));
  }

  /// Counts the number of space characters among the artifacts in this band.
  ///
  /// Returns:
  /// The number of artifacts that match a space character.
  int get spacesCount => artifacts.fold(
        0,
        (count, a) => a.characterMatched == ' ' ? count + 1 : count,
      );
}
