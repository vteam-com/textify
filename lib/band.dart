import 'package:flutter/widgets.dart';
import 'package:textify/artifact.dart';
import 'package:textify/matrix.dart';

/// Represents a horizontal band (aka strip) in an image/document.
///
/// A Band contains multiple [Artifact] objects and provides methods for
/// analyzing their layout and characteristics.
class Band {
  /// Creates a new Band with the specified rectangle.
  ///
  Band();

  /// unique Band id
  int id = 0;

  /// List of artifacts contained within this band.
  final List<Artifact> artifacts = [];

  /// Private fields to store calculated average of space between each artifacts
  double _averageKerning = -1;

  /// Private fields to store calculated average of artifact width
  double _averageWidth = -1;

  /// Gets the average kerning between adjacent artifacts in the band.
  ///
  /// Triggers calculation if not previously computed.
  ///
  /// Returns:
  /// The average kerning as a double, or -1 if there are fewer than 2 artifacts.
  double get averageKerning {
    if ((_averageKerning == -1 || _averageWidth == -1)) {
      _updateStatistics();
    }
    return _averageKerning;
  }

  /// Kerning between each artifact when applying packing
  static int kerningWidth = 4;

  /// Gets the average width of artifacts in the band.
  ///
  /// Triggers calculation if not previously computed.
  ///
  /// Returns:
  /// The average width as a double, or -1 if there are fewer than 2 artifacts.
  double get averageWidth {
    if ((_averageKerning == -1 || _averageWidth == -1)) {
      _updateStatistics();
    }
    return _averageWidth;
  }

  /// Calculates the average Kerning between adjacent artifacts and their average width.
  ///
  /// This method computes the mean horizontal distance between the right edge of
  /// one artifact and the left edge of the next artifact in the list. It also
  /// calculates the average width of all artifacts. The artifacts are assumed
  /// to be sorted from left to right.
  ///
  /// If there are fewer than 2 artifacts, both averages are set to -1.
  void _updateStatistics() {
    if (artifacts.length < 2) {
      _averageKerning = -1;
      _averageWidth = -1;
      return;
    }

    double totalWidth = 0;
    double totalKerning = 0;
    int count = artifacts.length;

    for (int i = 1; i < artifacts.length; i++) {
      final artifact = artifacts[i];
      final double kerning = artifact.rectangleAdjusted.left -
          artifacts[i - 1].rectangleAdjusted.right;
      totalKerning += kerning;
      totalWidth += artifact.rectangleAdjusted.width;
    }
    _averageWidth = totalWidth / count;
    _averageKerning = totalKerning / count;
  }

  /// Adds an artifact to the collection and resets the cached rectangle.
  ///
  /// This method performs two main actions:
  /// 1. Resets the cached rectangle to zero.
  /// 2. Adds the provided artifact to the collection.
  ///
  /// Parameters:
  /// - [artifact]: The Artifact object to be added to the collection.
  ///
  /// The method modifies the internal state by:
  /// - Setting the [_rectangle] to [Rect.zero], invalidating any previously cached rectangle.
  /// - Adding the new [artifact] to the [artifacts] collection.
  ///
  /// Note: This method should be called whenever a new artifact needs to be added to the collection.
  /// It ensures that the cached rectangle is properly invalidated, which may be important for
  /// subsequent calculations or rendering operations.
  void addArtifact(final Artifact artifact) {
    // reset the cached rectangle each time an artifact is added or removed
    _rectangle = Rect.zero;
    this.artifacts.add(artifact);
  }

  /// Sorts the artifacts in this band from left to right.
  ///
  /// This method orders the artifacts based on their left edge position,
  /// ensuring they are in the correct sequence as they appear in the band.
  void sortLeftToRight() {
    artifacts.sort(
      (a, b) => a.rectangleAdjusted.left.compareTo(b.rectangleAdjusted.left),
    );
  }

  /// Identifies and inserts space artifacts between existing artifacts in the band.
  ///
  /// This method analyzes the Kerning between artifacts and inserts space artifacts
  /// where the Kerning exceeds a certain threshold.
  ///
  /// The process involves:
  /// 1. Calculating a threshold Kerning size based on the average width.
  /// 2. Iterating through artifacts to identify Kerning exceeding the threshold.
  /// 3. Creating a list of artifacts that need spaces inserted before them.
  /// 4. Inserting space artifacts at the appropriate positions.
  ///
  /// The threshold is set at 75% of the average width of artifacts in the band.
  void identifySpacesInBand() {
    final double exceeding = this.averageWidth * 0.75; //%

    final List<Artifact> insertInFrontOfTheseArtifacts = [];

    for (int indexOfArtifact = 0;
        indexOfArtifact < this.artifacts.length;
        indexOfArtifact++) {
      if (indexOfArtifact > 0) {
        // Left
        final Artifact artifactLeft = this.artifacts[indexOfArtifact - 1];
        final double x1 = artifactLeft.rectangleOriginal.right;

        // Right
        final Artifact artifactRight = this.artifacts[indexOfArtifact];
        final double x2 = artifactRight.rectangleOriginal.left;

        final double kerning = x2 - x1;

        if (kerning >= exceeding) {
          // insert Artifact for Space
          insertInFrontOfTheseArtifacts.add(artifactRight);
        }
      }
    }

    for (final artifactOnTheRightSide in insertInFrontOfTheseArtifacts) {
      final indexOfArtifact = this.artifacts.indexOf(artifactOnTheRightSide);
      insetArtifactForSpace(
        indexOfArtifact,
        artifactOnTheRightSide.rectangleOriginal.left -
            averageWidth -
            averageKerning,
        artifactOnTheRightSide.rectangleOriginal.left - averageKerning,
      );
    }
  }

  /// Inserts a space artifact at a specified position in the artifacts list.
  ///
  /// This method creates a new Artifact representing a space and inserts it
  /// into the artifacts list at the specified index.
  ///
  /// Parameters:
  /// - [indexOfArtifact]: The index at which to insert the space artifact.
  /// - [x1]: The left x-coordinate of the space artifact.
  /// - [x2]: The right x-coordinate of the space artifact.
  ///
  /// The created space artifact has the following properties:
  /// - Character matched is a space (' ').
  /// - Band ID is set to the current band's ID.
  /// - Rectangle is set based on the provided x-coordinates and the band's top and bottom.
  /// - A matrix is created based on the dimensions of the rectangle.
  void insetArtifactForSpace(
    final int indexOfArtifact,
    final double x1,
    final double x2,
  ) {
    final Artifact artifactSpace = Artifact();
    artifactSpace.characterMatched = ' ';
    artifactSpace.bandId = this.id;

    artifactSpace.rectangleOriginal = Rect.fromLTRB(
      x1,
      rectangle.top,
      x2,
      rectangle.bottom,
    );
    artifactSpace.rectangleAdjusted = artifactSpace.rectangleOriginal;

    artifactSpace.matrixOriginal = Matrix(
      artifactSpace.rectangleOriginal.width.toInt(),
      artifactSpace.rectangleOriginal.height.toInt(),
    );
    this.artifacts.insert(indexOfArtifact, artifactSpace);
  }

  /// Adjusts the positions of artifacts to pack them from left to right.
  ///
  /// This method repositions all artifacts in the band, aligning them
  /// from left to right with proper spacing. It performs the following steps:
  ///
  /// 1. Adds top and bottom padding to each artifact's matrix.
  /// 2. Shifts each artifact horizontally to align with the left edge of the band.
  /// 3. Adjusts the vertical position of each artifact to align with the band's top.
  /// 4. Updates the artifact's rectangle positions.
  /// 5. Increments the left position for the next artifact, including character spacing.
  ///
  /// This method modifies the positions of all artifacts in the band to create
  /// a left-aligned, properly spaced arrangement.
  void packArtifactLeftToRight() {
    double left = this.rectangle.left;

    for (final Artifact artifact in artifacts) {
      artifact.matrixOriginal.padTopBottom(
        paddingTop: (artifact.rectangleOriginal.top - rectangle.top).toInt(),
        paddingBottom:
            (rectangle.bottom - artifact.rectangleOriginal.bottom).toInt(),
      );

      final double dx = left - artifact.rectangleOriginal.left;
      final double dy = rectangle.top - artifact.rectangleOriginal.top;
      artifact.rectangleAdjusted =
          artifact.rectangleOriginal.shift(Offset(dx, dy));
      artifact.rectangleOriginal = artifact.rectangleAdjusted;
      left += artifact.rectangleAdjusted.width;
      left += kerningWidth;
    }
  }

  /// The cached bounding rectangle of this object.
  ///
  /// This is lazily initialized and cached for performance reasons.
  Rect _rectangle = Rect.zero;

  /// Gets the bounding rectangle of this object.
  ///
  /// This getter uses lazy initialization to compute the bounding box
  /// only when first accessed, and then caches the result for subsequent calls.
  ///
  /// Returns:
  ///   A [Rect] representing the bounding box of this object.
  ///
  /// Note: If the object's dimensions or position can change, this cached
  /// value may become outdated. In such cases, consider adding a method
  /// to invalidate the cache when necessary.
  Rect get rectangle {
    if (_rectangle == Rect.zero) {
      _rectangle = getBoundingBox(this.artifacts);
    }
    return _rectangle;
  }

  /// Return the unified bounding box for all artifacts in the band
  static Rect getBoundingBox(final List<Artifact> artifacts) {
    if (artifacts.isEmpty) {
      return Rect.zero;
    }

    double minX = artifacts
        .map((a) => a.rectangleAdjusted.left)
        .reduce((a, b) => a < b ? a : b);
    double minY = artifacts
        .map((a) => a.rectangleAdjusted.top)
        .reduce((a, b) => a < b ? a : b);
    double maxX = artifacts
        .map((a) => a.rectangleAdjusted.right)
        .reduce((a, b) => a > b ? a : b);
    double maxY = artifacts
        .map((a) => a.rectangleAdjusted.bottom)
        .reduce((a, b) => a > b ? a : b);

    return Rect.fromLTRB(minX, minY, maxX, maxY);
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
