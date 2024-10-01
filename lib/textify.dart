import 'dart:math';

import 'package:flutter/widgets.dart';
import 'package:textify/artifact.dart';
import 'package:textify/band.dart';
import 'package:textify/character_definitions.dart';
import 'package:textify/matrix.dart';

export 'package:textify/artifact.dart';
export 'package:textify/character_definitions.dart';
export 'package:textify/matrix.dart';

class Textify {
  CharacterDefinitions characterDefinitions = CharacterDefinitions();
  List<Band> bands = [];
  List<Artifact> list = [];
  String textFound = '';

  Future<bool> init({
    final String pathToAssetsDefinition = 'packages/textify/assets/matrices.json',
  }) async {
    await characterDefinitions.loadDefinitions(pathToAssetsDefinition);
    return true;
  }

  List<Artifact> artifactsInBand(final int bandIndex) {
    return list
        .where(
          (final Artifact artifact) => artifact.bandId == bandIndex,
        )
        .toList();
  }

  void clear() {
    list.clear();
    bands.clear();
    textFound = '';
  }

  int get count => list.length;

  Artifact get(final int index) {
    return list[index];
  }

  List<ScoreMatch> getMatchingScores(
    final Artifact artifact, [
    final String supportedCharacters = '',
  ]) {
    final matrix = artifact.matrixNormalized;
    final int numberOfEnclosure = matrix.enclosures;
    final bool hasVerticalLineOnTheLeftSide = matrix.verticalLineLeft;
    final bool hasVerticalLineOnTheRightSide = matrix.verticalLineRight;
    final bool punctuation = matrix.isPunctuation();

    const double percentageNeeded = 0.3; // Adjust this value as needed
    const int totalChecks = 4; // Total number of checks we perform

    final List<CharacterDefinition> qualifiedTemplates =
        characterDefinitions.definitions.where((CharacterDefinition template) {
      //
      // The caller has a restricted set of possible characters to match
      //
      if (supportedCharacters.isNotEmpty && !supportedCharacters.contains(template.character)) {
        return false;
      }

      int matchingChecks = 0;

      // Count matching characteristics
      if (numberOfEnclosure == template.enclosers) {
        matchingChecks++;
      }
      if (punctuation == template.isPunctuation) {
        matchingChecks++;
      }
      if (hasVerticalLineOnTheLeftSide == template.lineLeft) {
        matchingChecks++;
      }
      if (hasVerticalLineOnTheRightSide == template.lineRight) {
        matchingChecks++;
      }

      // Calculate match percentage
      double matchPercentage = matchingChecks / totalChecks;

      // Include templates that meet or exceed the percentage needed
      return matchPercentage >= percentageNeeded;
    }).toList();

    // Use _getDistanceScores to calculate the final scores
    final List<ScoreMatch> scores = _getDistanceScores(qualifiedTemplates, matrix);

    // Sort scores in descending order (higher score is better)
    scores.sort((a, b) => b.score.compareTo(a.score));
    return scores;
  }

  String getTextFromBinaryImage({
    required final Matrix imageAsBinary,
    final String supportedCharacters = '',
  }) {
    _findArtifacts(imageAsBinary);

    // merge disconnected parts of artifacts found
    _globalMergeOfArtifacts();

    return _getTextFromArtifacts(supportedCharacters: supportedCharacters);
  }

  static String getTextFromBinaryImageStatic({
    required final Matrix imageAsBinary,
  }) {
    return Textify().getTextFromBinaryImage(imageAsBinary: imageAsBinary);
  }

  void _adjustArtifactsToBandHeight() {
    for (final Artifact artifact in list) {
      if (artifact.bandId >= 0 && artifact.bandId < bands.length) {
        final Rect bandRect = bands[artifact.bandId].rectangle;
        artifact.fitToRectangleHeight(bandRect);
      }
    }
  }

  /// Creates and organizes text bands from artifact positions in the image.
  ///
  /// This method processes the artifacts (typically individual characters or words)
  /// detected in an image and organizes them into coherent text bands. It operates
  /// in four distinct phases:
  ///
  /// 1. Identify Text Bands:
  ///    Analyzes the spatial distribution of artifacts to determine potential
  ///    text bands (rows of text) in the image.
  ///
  /// 2. Merge Artifacts:
  ///    Combines overlapping or closely positioned artifacts within each band.
  ///    This step helps to consolidate fragmented characters or words.
  ///
  /// 3. Adjust Artifact Heights:
  ///    Normalizes the height of artifacts within each band to ensure consistency.
  ///    This step is crucial for maintaining a uniform appearance of text lines.
  ///
  /// 4. Sort Artifacts:
  ///    Arranges the artifacts within each band in reading order (typically
  ///    left-to-right for most languages).
  ///
  /// After execution, the artifacts will be organized into bands, with each band
  /// containing properly merged, height-adjusted, and sorted artifacts. This
  /// structured representation of the text layout is essential for further
  /// processing steps such as OCR or document layout analysis.
  ///
  /// Note: This method modifies the internal state of the object, updating the
  /// artifact list and band information. It does not return a value.
  ///
  /// Throws:
  ///   May throw exceptions if there are issues with artifact processing or
  ///   if the input data is invalid or corrupted.
  ///
  /// Example usage:
  /// ```dart
  /// TextProcessor processor = TextProcessor();
  /// processor.loadArtifacts(imageData);
  /// processor.createBandsFromArtifactsPositions();
  /// List<TextBand> bands = processor.getTextBands();
  /// ```
  ///
  /// See also:
  ///   * [Artifact], for the definition of individual text elements.
  ///   * [TextBand], for the structure representing a line of text.
  void _createBandsFromArtifactsPositions() {
    // Phase 1: Determine bands
    _identifyTextBands();

    // Phase 2: Merge overlapping artifacts
    _mergeArtifactsWithinBands();

    // Phase 4: Sort artifacts in reading order
    _sortArtifactsInReadingOrder();

    // Phase 3: Adjust artifacts to match band height
    _adjustArtifactsToBandHeight();
    for (int bandId = 0; bandId < bands.length; bandId++) {
      bands[bandId].artifacts = artifactsInBand(bandId);
      // this.bands[bandId].sortLeftToRight();
    }

    _identifySpacesInBands();
  }

  /// Creates a rectangle that encompasses all artifacts in a given row.
  ///
  /// This method takes a list of [Artifact] objects representing a single row of text
  /// and calculates a [Rect] that fully contains all the artifacts in that row.
  ///
  /// The algorithm works as follows:
  /// 1. If the input list is empty, it returns [Rect.zero].
  /// 2. Starting with the rectangle of the first artifact, it iteratively expands
  ///    the rectangle to include each subsequent artifact's rectangle.
  ///
  /// This approach ensures that the resulting rectangle:
  /// - Has a left edge aligned with the leftmost artifact in the row.
  /// - Has a top edge aligned with the highest artifact in the row.
  /// - Has a right edge aligned with the rightmost artifact in the row.
  /// - Has a bottom edge aligned with the lowest artifact in the row.
  ///
  /// Parameters:
  ///   [rowArtifacts] - A list of [Artifact] objects representing a single row of text.
  ///
  /// Returns:
  ///   A [Rect] that encompasses all artifacts in the given row.
  ///   Returns [Rect.zero] if the input list is empty.
  ///
  /// Example:
  ///   final rowRect = _createRowRect(rowArtifacts);
  ///   // rowRect now contains the bounding rectangle for all artifacts in the row
  Rect _createRectToFitArtifacts(final List<Artifact> rowArtifacts) {
    if (rowArtifacts.isEmpty) {
      return Rect.zero;
    }

    return rowArtifacts.fold(
      rowArtifacts.first.rectangle,
      (Rect acc, Artifact artifact) => acc.expandToInclude(artifact.rectangle),
    );
  }

  /// Checks if two rectangles overlap horizontally.
  ///
  /// This function determines whether two rectangles have any horizontal overlap,
  /// regardless of their vertical positions.
  ///
  /// Parameters:
  /// - rectangleA: The first rectangle to check.
  /// - rectangleB: The second rectangle to check.
  ///
  /// Returns:
  /// true if the rectangles overlap horizontally, false otherwise.
  bool _doRectanglesOverlapHorizontally(Rect rectangleA, Rect rectangleB) {
    return rectangleA.left < rectangleB.right && rectangleB.left < rectangleA.right;
  }

  /// Extracts an artifact from a binary image based on a list of connected points.
  ///
  /// This method creates an [Artifact] object from a set of connected points in a binary image.
  /// It determines the bounding rectangle of the points and extracts the corresponding
  /// sub-grid from the binary image.
  ///
  /// Parameters:
  /// - [binaryImage]: The full binary image from which to extract the artifact.
  /// - [points]: A list of [Point] objects representing the connected pixels of the artifact.
  ///
  /// Returns:
  /// An [Artifact] object containing:
  /// - A [Rect] representing the bounding box of the artifact.
  /// - A [Matrix] representing the extracted sub-grid of the artifact.
  ///
  /// The method performs the following steps:
  /// 1. Determines the bounding box of the artifact from the given points.
  /// 2. Creates a rectangle based on the bounding box.
  /// 3. Extracts a sub-grid from the binary image corresponding to the rectangle.
  /// 4. Creates and returns an [Artifact] object with the rectangle and sub-grid.
  Artifact _extractArtifact(
    final Matrix binaryImage,
    final List<Point> points,
  ) {
    assert(points.isNotEmpty);

    // Initialize min and max values with the first point
    num minX = points[0].x;
    num minY = points[0].y;
    num maxX = minX;
    num maxY = minY;

    // Find the bounding box of the artifact
    for (final Point point in points.skip(1)) {
      if (point.x < minX) {
        minX = point.x;
      }
      if (point.y < minY) {
        minY = point.y;
      }
      if (point.x > maxX) {
        maxX = point.x;
      }
      if (point.y > maxY) {
        maxY = point.y;
      }
    }

    // Create a rectangle from the bounding box
    final Rect rectangle = Rect.fromLTWH(
      minX.toDouble(),
      minY.toDouble(),
      (maxX - minX) + 1,
      (maxY - minY) + 1,
    );

    // Extract the sub-grid from the binary image
    final Matrix subGrid = Matrix.extractSubGrid(
      binaryImage: binaryImage,
      rect: rectangle,
    );

    // Create and return the Artifact object
    final Artifact artifact = Artifact();
    artifact.rectangle = rectangle;
    artifact.setMatrix(subGrid);

    return artifact;
  }

  /// Identifies and extracts artifacts from a binary image.
  ///
  /// This method scans through a binary image represented by [binaryImages] and
  /// identifies connected bands of "on" pixels, treating each as an artifact.
  /// It uses a flood fill algorithm to find connected pixels and extracts
  /// meaningful information about each artifact.
  ///
  /// Parameters:
  /// - [binaryImages]: A Matrix representing the binary image. "On" pixels are
  ///   considered part of potential artifacts.
  ///
  /// The method updates the following properties:
  /// - [list]: A list of [Artifact] objects, each representing a found artifact.
  ///
  /// Note: This method clears any existing artifacts before processing.
  void _findArtifacts(final Matrix binaryImages) {
    // Clear existing artifacts
    clear();

    // Create a matrix to keep track of visited pixels
    final Matrix visited = Matrix(binaryImages.cols, binaryImages.rows, false);

    // Iterate through each pixel in the binary image
    for (int y = 0; y < binaryImages.rows; y++) {
      for (int x = 0; x < binaryImages.cols; x++) {
        // Check if the current pixel is unvisited and "on"
        if (!visited.cellGet(x, y) && binaryImages.cellGet(x, y)) {
          // Find all connected "on" pixels starting from the current pixel
          final List<Point> connectedPoints = _floodFill(
            binaryImages,
            visited,
            x,
            y,
          );

          // Extract artifact information from the connected points
          final Artifact artifactFound = _extractArtifact(
            binaryImages,
            connectedPoints,
          );

          if (artifactFound.matrixOriginal.isConsideredLine()) {
            // discard lines
          } else {
            // Add the found artifact to the list
            list.add(artifactFound);
          }
        }
      }
    }
  }

  List<Point> _floodFill(
    final Matrix binaryPixels,
    final Matrix visited,
    final int startX,
    final int startY,
  ) {
    assert(binaryPixels.area == visited.area);

    final List<Point> stack = [Point(startX, startY)];
    final List<Point> connectedPoints = [];

    while (stack.isNotEmpty) {
      final Point point = stack.removeLast();
      final int x = point.x.toInt();
      final int y = point.y.toInt();

      if (x < 0 || x >= binaryPixels.cols || y < 0 || y >= binaryPixels.rows) {
        continue;
      }

      if (!binaryPixels.cellGet(x, y) || visited.cellGet(x, y)) {
        // no pixel at this location
        continue;
      }

      visited.cellSet(x, y, true);
      connectedPoints.add(point);

      // Push neighboring pixels onto the stack
      stack.add(Point(x - 1, y)); // Left
      stack.add(Point(x + 1, y)); // Right
      stack.add(Point(x, y - 1)); // Top
      stack.add(Point(x, y + 1)); // Bottom
    }
    return connectedPoints;
  }

  String _getCharacterFromArtifacts(
    final Artifact artifact, [
    final String supportedCharacters = '',
  ]) {
    final List<ScoreMatch> scores = getMatchingScores(artifact, supportedCharacters);

    return scores.isNotEmpty ? scores.first.character : '';
  }

  /// Calculates matching scores for a normalized artifact against a set of character templates.
  ///
  /// This function compares a normalized artifact (likely an image or pattern) against
  /// multiple character templates to find the best matches.
  ///
  /// @param templatesToAttemptToMatch A map of character strings to their corresponding template matrices.
  /// @param normalizedArtifact The normalized artifact to compare against the templates.
  /// @param scores An output list that will be populated with ScoreMatch objects.
  static List<ScoreMatch> _getDistanceScores(
    List<CharacterDefinition> templates,
    Matrix normalizedArtifact,
  ) {
    final List<ScoreMatch> scores = [];
    // Iterate through each template in the map
    for (var entry in templates) {
      if (normalizedArtifact.isNotEmpty) {
        // Calculate the similarity score and create a ScoreMatch object
        for (final matrix in entry.matrices) {
          ScoreMatch scoreMatch = ScoreMatch(
            character: entry.character,
            score: Matrix.getDistancePercentage(
              normalizedArtifact,
              matrix,
            ),
          );

          // Add the ScoreMatch to the scores list
          scores.add(scoreMatch);
        }
      }
    }

    // Sort the scores list in descending order of score
    scores.sort((a, b) => b.score.compareTo(a.score));
    return scores;
  }

  /// Processes the list of artifacts to extract and format the text content.
  ///
  /// This method performs a series of operations to convert visual artifacts
  /// (likely representing characters or words in an image) into a coherent
  /// string of text, while attempting to preserve the original layout.
  ///
  /// The process involves several phases:
  /// 1. Grouping artifacts into text rows
  /// 2. Merging overlapping artifacts
  /// 3. Adjusting artifacts to match the height of their respective rows
  /// 4. Sorting artifacts in reading order (left to right, top to bottom)
  /// 5. Extracting text from each artifact and combining into a single string
  ///
  /// The method also handles formatting by adding spaces between different
  /// rows to maintain the structure of the original text.
  ///
  /// Returns:
  ///   A String containing the extracted text, with attempts made to preserve
  ///   the original layout through the use of spaces between rows.
  String _getTextFromArtifacts({final String supportedCharacters = ''}) {
    // First group connected artifacts(Characters) into their bands to form words
    _createBandsFromArtifactsPositions();
    textFound = '';

    List<String> linesFound = [];

    for (final band in bands) {
      String line = '';

      for (final artifact in band.artifacts) {
        artifact.resize(
          templateBaseDimensionWidth,
          templateBaseDimensionHeight,
        );
        String characterFound = _getCharacterFromArtifacts(artifact, supportedCharacters);
        line += characterFound;
      }
      linesFound.add(line);
    }

    textFound += linesFound.join('\n');
    return textFound; // Trim to remove leading space
  }

  /// Merges overlapping artifacts in the list.
  ///
  /// This method performs a global merge operation on all artifacts in the list.
  /// It identifies overlapping artifacts, merges them, and removes the redundant ones.
  ///
  /// The algorithm works as follows:
  /// 1. Iterate through all pairs of artifacts.
  /// 2. If two artifacts overlap and haven't been marked for removal:
  ///    - Merge them using the [_mergeArtifacts] method.
  ///    - Mark the second artifact for removal.
  /// 3. Remove all marked artifacts from the list.
  ///
  /// Time Complexity: O(n^2), where n is the number of artifacts.
  /// Space Complexity: O(n) in the worst case, for the removal set.
  ///
  /// Note: This method modifies the original list of artifacts.
  void _globalMergeOfArtifacts() {
    final int n = list.length;

    final Set<Artifact> toRemove = {};

    for (int i = 0; i < n; i++) {
      final artifactA = list[i];
      if (toRemove.contains(artifactA)) {
        // already merged
        continue;
      }

      for (int j = i + 1; j < n; j++) {
        final artifactB = list[j];
        if (toRemove.contains(artifactB)) {
          // already merged
          continue;
        }

        if (artifactA.rectangle.overlaps(artifactB.rectangle)) {
          artifactA.setMatrix(_mergeArtifacts(artifactA, artifactB));
          toRemove.add(artifactB);
        }
      }
    }

    list.removeWhere((artifact) => toRemove.contains(artifact));
  }

  void _identifySpacesInBand(final Band band) {
    band.sortLeftToRight();
    band.calculateAverages();

    final double averageWidth = band.averageWidth;
    final double averageGap = band.averageGap;
    final double exceeding = averageGap * 1.8;

    for (int indexOfArtifact = 0; indexOfArtifact < band.artifacts.length; indexOfArtifact++) {
      if (indexOfArtifact > 0) {
        final Artifact artifactLeft = band.artifacts[indexOfArtifact - 1];
        final Artifact artifactRight = band.artifacts[indexOfArtifact];
        final double gap = (artifactRight.rectangle.left - artifactLeft.rectangle.right);

        if (gap > exceeding) {
          // insert Artifact for Space
          final Artifact artifactSpace = Artifact();

          artifactSpace.bandId = artifactRight.bandId;

          artifactSpace.rectangle = Rect.fromLTWH(
            artifactLeft.rectangle.right,
            artifactLeft.rectangle.top,
            averageWidth,
            artifactLeft.rectangle.height,
          );
          artifactSpace.resize(
            artifactSpace.rectangle.width.toInt(),
            artifactSpace.rectangle.height.toInt(),
          );
          artifactSpace.characterMatched = ' ';

          {
            final indexToInsertAt = band.artifacts.indexOf(artifactRight);
            band.artifacts.insert(indexToInsertAt, artifactSpace);
            indexOfArtifact++; // skip to next one on the right
          }
          {
            // final indexToInsertAt = this.list.indexOf(artifactRight);
            list.add(artifactSpace);
          }
        }
      }
    }
  }

  void _identifySpacesInBands() {
    for (final Band band in bands) {
      _identifySpacesInBand(band);
    }
  }

  /// Groups artifacts into text rows based on their spatial relationships.
  ///
  /// This method analyzes the list of artifacts (presumably characters or words)
  /// and groups them into rows of text. It prioritizes left-to-right ordering
  /// first, then top-to-bottom progression.
  ///
  /// The algorithm works as follows:
  /// 1. Sort artifacts primarily by x-coordinate, then by y-coordinate.
  /// 2. Calculate the average character width and find the largest width from all artifacts.
  /// 3. Iterate through the sorted artifacts, grouping them into rows.
  /// 4. For each artifact, check if it's within horizontal and vertical tolerances of the current row.
  /// 5. If within tolerances, add to the current row; otherwise, start a new row.
  /// 6. Assign each artifact a row number corresponding to its position.
  ///
  /// Returns:
  ///   A List<Rect> where each Rect represents a row of text. The rectangles
  ///   encompass all artifacts in their respective rows.
  void _identifyTextBands() {
    if (list.isEmpty) {
      return;
    }

    List<Band> bands = [];
    List<Artifact> currentRow = [];

    // Calculate average width and find the largest width
    double totalWidth = 0.0;

    double totalHeight = 0.0;
    for (var artifact in list) {
      totalWidth += artifact.rectangle.width;
      totalHeight += artifact.rectangle.height;
    }
    double averageCharWidth = totalWidth / list.length;
    double averageCharHeight = totalHeight / list.length;
    double horizontalTolerance = averageCharWidth * 1.5; // 50% variation
    double verticalTolerance = averageCharHeight * 0.5; // 50% of average height

    for (final Artifact artifact in list) {
      if (currentRow.isEmpty) {
        currentRow.add(artifact);
        continue;
      }

      final Rect currentRowRect = _createRectToFitArtifacts(currentRow);
      final double horizontalDistance = artifact.rectangle.left - currentRowRect.right;
      final double verticalDistance =
          (artifact.rectangle.top + artifact.rectangle.bottom) / 2 - (currentRowRect.top + currentRowRect.bottom) / 2;

      bool isHorizontallyClose = horizontalDistance <= horizontalTolerance;
      bool isVerticallyClose = verticalDistance.abs() <= verticalTolerance;

      if (isHorizontallyClose && isVerticallyClose) {
        // This artifact is close enough to be part of the current row
        currentRow.add(artifact);
      } else if (!isVerticallyClose) {
        // Start a new row if the gap is too large horizontally or vertically
        bands.add(Band(currentRowRect));
        currentRow = [artifact];
      } else {
        // This artifact is vertically close but not horizontally close
        // We still consider it part of the current row
        currentRow.add(artifact);
      }

      artifact.bandId = bands.length;
    }

    // Add the last row
    if (currentRow.isNotEmpty) {
      bands.add(Band(_createRectToFitArtifacts(currentRow)));
    }
    this.bands = bands;
  }

  /// Merges two artifacts by combining their matrices into a single, larger matrix.
  ///
  /// This function creates a new matrix that encompasses the area of both input artifacts.
  /// The original matrices of both artifacts are copied onto this new, larger matrix,
  /// preserving their relative positions.
  ///
  /// Parameters:
  ///   a1: The first artifact to be merged.
  ///   a2: The second artifact to be merged.
  ///
  /// Returns:
  ///   A new Matrix object representing the merged result of both artifacts.
  ///
  /// The merging process involves these steps:
  /// 1. Create a new rectangle that encompasses both artifacts' rectangles.
  /// 2. Initialize a new matrix with the dimensions of this encompassing rectangle.
  /// 3. Copy the matrix data from both artifacts onto the new matrix, adjusting
  ///    their positions relative to the new, larger rectangle.
  ///
  /// Note: This function does not modify the original artifacts; it creates and
  /// returns a new matrix containing the merged data.
  Matrix _mergeArtifacts(final Artifact a1, final Artifact a2) {
    // Create a new rectangle that encompasses both artifacts
    final Rect newRect = Rect.fromLTRB(
      min(a1.rectangle.left, a2.rectangle.left),
      min(a1.rectangle.top, a2.rectangle.top),
      max(a1.rectangle.right, a2.rectangle.right),
      max(a1.rectangle.bottom, a2.rectangle.bottom),
    );

    // Merge the grids
    final Matrix newGrid = Matrix(newRect.width, newRect.height);

    // Copy both grids onto the new grid
    Matrix.copyGrid(
      a1.matrixOriginal,
      newGrid,
      (a1.rectangle.left - newRect.left).toInt(),
      (a1.rectangle.top - newRect.top).toInt(),
    );

    Matrix.copyGrid(
      a2.matrixOriginal,
      newGrid,
      (a2.rectangle.left - newRect.left).toInt(),
      (a2.rectangle.top - newRect.top).toInt(),
    );
    return newGrid;
  }

  /// Finds artifacts within a band that overlap horizontally.
  ///
  /// This function takes a list of artifacts and a band (represented as a Rect),
  /// and returns a list of lists, where each inner list contains artifacts that
  /// overlap horizontally within the given band.
  ///
  /// Parameters:
  /// - artifacts: The list of all artifacts to process.
  /// - band: The band (Rect) within which to find overlapping artifacts.
  ///
  /// Returns:
  /// A list of lists, where each inner list contains horizontally overlapping artifacts.
  void _mergeArtifactsWithinBands() {
    List<Artifact> toRemove = [];

    for (int index = 0; index < bands.length; index++) {
      final List<Artifact> artifactsInRect = artifactsInBand(index);

      for (var artifactA in artifactsInRect) {
        for (var artifactB in artifactsInRect) {
          if (artifactA != artifactB) {
            if (!toRemove.contains(artifactA) && !toRemove.contains(artifactB)) {
              if (_doRectanglesOverlapHorizontally(
                artifactA.rectangle,
                artifactB.rectangle,
              )) {
                artifactA.setMatrix(_mergeArtifacts(artifactA, artifactB));
                toRemove.add(artifactB);
              }
            }
          }
        }
      }
    }

    // clean up
    for (final a in toRemove) {
      list.remove(a);
    }
  }

  void _sortArtifactsInReadingOrder() {
    list.sort((a, b) {
      // First, sort by vertical position using the bottom and top comparison
      if (a.rectangle.bottom <= b.rectangle.top) {
        return -1;
      } else if (b.rectangle.bottom <= a.rectangle.top) {
        return 1;
      } else {
        // If rectangles overlap vertically, sort by left (x-coordinate)
        return a.rectangle.left.compareTo(b.rectangle.left);
      }
    });
  }
}

class ScoreMatch {
  ScoreMatch({
    required this.character,
    required this.score,
  });

  String character;
  double score;
}
