import 'dart:async';
import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/widgets.dart';
import 'package:textify/artifact.dart';
import 'package:textify/band.dart';
import 'package:textify/character_definitions.dart';
import 'package:textify/correction.dart';
import 'package:textify/matrix.dart';
import 'package:textify/score_match.dart';

/// Textify is a class designed to extract text from clean digital images.
///
/// This class provides functionality to process binary images, identify text artifacts,
/// organize them into bands, and extract the text content. It is optimized for
/// clean computer-generated documents with standard fonts and good contrast.
class Textify {
  /// Stores definitions of characters for matching.
  final CharacterDefinitions characterDefinitions = CharacterDefinitions();

  /// List of text bands identified in the image.
  final List<Band> bands = [];

  /// List of discovered artifacts on the image
  final List<Artifact> artifactsFound = [];

  /// List of artifacts (potential characters) identified in the image.
  final List<Artifact> _artifactsToProcess = [];

  /// The extracted text from the image.
  String textFound = '';

  /// Represents the start time of a process or operation.
  DateTime processBegin = DateTime.now();

  /// Represents the end time of a process or operation.
  DateTime processEnd = DateTime.now();

  /// Calculates the duration, in milliseconds, between the start and end times
  /// of a process or operation.
  ///
  /// The duration is calculated by subtracting the number of milliseconds since
  /// the Unix epoch for the start time (`processBegin`) from the number of
  /// milliseconds since the Unix epoch for the end time (`processedEnd`).
  ///
  /// Returns:
  ///   An integer representing the duration, in milliseconds, between the start
  ///   and end times of the process or operation.
  int get duration =>
      processEnd.millisecondsSinceEpoch - processBegin.millisecondsSinceEpoch;

  /// Should textify attempt to detect the Space ' ' character
  bool includeSpaceDetections = true;

  /// Ignore horizontal and vertical lines
  bool excludeLongLines = true;

  /// Whether to apply dictionary-based corrections during text recognition.
  ///
  /// When set to true, the recognition process will attempt to correct potential
  /// misidentified characters by comparing them against a dictionary of known words.
  /// This can improve accuracy but may increase processing time.
  bool applyDictionary = false;

  /// Initializes the Textify instance by loading character definitions.
  ///
  /// [pathToAssetsDefinition] is the path to the JSON file containing character definitions.
  /// Returns a [Future<bool>] indicating whether the initialization was successful.
  Future<Textify> init({
    final String pathToAssetsDefinition =
        'packages/textify/assets/matrices.json',
  }) async {
    await characterDefinitions.loadDefinitions(pathToAssetsDefinition);
    return this;
  }

  /// Clears all stored data, resetting the Textify instance.
  void clear() {
    _artifactsToProcess.clear();
    artifactsFound.clear();
    bands.clear();
    textFound = '';
  }

  /// The width of the character template used for recognition.
  ///
  /// This getter returns the standard width of the template used to define
  /// characters in the recognition process. It's derived from the
  /// [CharacterDefinition] class.
  ///
  /// Returns:
  ///   An [int] representing the width of the character template in pixels.
  int get templateWidth => CharacterDefinition.templateWidth;

  /// The height of the character template used for recognition.
  ///
  /// This getter returns the standard height of the template used to define
  /// characters in the recognition process. It's derived from the
  /// [CharacterDefinition] class.
  ///
  /// Returns:
  ///   An [int] representing the height of the character template in pixels.
  int get templateHeight => CharacterDefinition.templateHeight;

  /// The number of items in the list.
  ///
  /// This getter returns the current count of items in the list. It's a
  /// convenient way to access the length property of the underlying list.
  ///
  /// Returns:
  ///   An [int] representing the number of items in the list.
  int get count => artifactsFound.length;

  /// Finds matching character scores for a given artifact.
  ///
  /// [artifact] is the artifact to find matches for.
  /// [supportedCharacters] is an optional string of characters to limit the search to.
  ///
  /// Returns:
  ///   A list of [ScoreMatch] objects sorted by descending score.
  List<ScoreMatch> getMatchingScoresOfNormalizedMatrix(
    final Artifact artifact, [
    final String supportedCharacters = '',
  ]) {
    final Matrix matrix = artifact.matrix;
    final int numberOfEnclosure = matrix.enclosures;
    final bool hasVerticalLineOnTheLeftSide = matrix.verticalLineLeft;
    final bool hasVerticalLineOnTheRightSide = matrix.verticalLineRight;
    final bool punctuation = matrix.isPunctuation();

    const double percentageNeeded = 0.5;
    const int totalChecks = 4;

    List<CharacterDefinition> qualifiedTemplates = characterDefinitions
        .definitions
        .where((final CharacterDefinition template) {
      if (supportedCharacters.isNotEmpty &&
          !supportedCharacters.contains(template.character)) {
        return false;
      }

      int matchingChecks = 0;
      // Enclosures
      if (numberOfEnclosure == template.enclosures) {
        matchingChecks++;
      }

      // Punctuation
      if (punctuation == template.isPunctuation) {
        matchingChecks++;
      }

      // Left Line
      if (hasVerticalLineOnTheLeftSide == template.lineLeft) {
        matchingChecks++;
      }

      // Right Line
      if (hasVerticalLineOnTheRightSide == template.lineRight) {
        matchingChecks++;
      }

      // Calculate match percentage
      final double matchPercentage = matchingChecks / totalChecks;

      // Include templates that meet or exceed the percentage needed
      return matchPercentage >= percentageNeeded;
    }).toList();

    if (qualifiedTemplates.isEmpty) {
      qualifiedTemplates = characterDefinitions.definitions;
    }

    final Matrix resizedMatrix =
        matrix.createNormalizeMatrix(templateWidth, templateHeight);

    // Calculate the final scores
    final List<ScoreMatch> scores =
        _getDistanceScores(qualifiedTemplates, resizedMatrix);

    // Sort scores in descending order (higher score is better)
    scores.sort((a, b) => b.score.compareTo(a.score));
    return scores;
  }

  /// Extracts text from an image.
  ///
  /// This method converts the input image to black and white, transforms it into a matrix,
  /// and then uses the [getTextFromMatrix] method to perform the actual text recognition.
  ///
  /// Parameters:
  /// - [image]: A [ui.Image] object representing the image from which to extract text.
  ///   This parameter is required.
  /// - [supportedCharacters]: An optional string containing the set of characters
  ///   to be recognized. If provided, the text extraction will be limited to these
  ///   characters. Default is an empty string, which means all supported characters
  ///   will be considered.
  ///
  /// Returns:
  /// A [Future<String>] that resolves to the extracted text from the image.
  ///
  /// Throws:
  /// May throw exceptions related to image processing or text extraction failures.
  ///
  /// Usage:
  /// ```dart
  /// final ui.Image myImage = // ... obtain image
  /// final String extractedText = await getTextFromImage(image: myImage);
  /// print(extractedText);
  /// ```
  Future<String> getTextFromImage({
    required final ui.Image image,
    final String supportedCharacters = '',
  }) async {
    final ui.Image imageBlackAndWhite = await imageToBlackOnWhite(image);

    final Matrix imageAsMatrix = await Matrix.fromImage(imageBlackAndWhite);

    return await getTextFromMatrix(
      imageAsMatrix: imageAsMatrix,
      supportedCharacters: supportedCharacters,
    );
  }

  /// Extracts text from a binary image.
  ///
  /// [imageAsMatrix] is the binary representation of the image.
  /// [supportedCharacters] is an optional string of characters to limit the recognition to.
  /// Returns the extracted text as a string.
  Future<String> getTextFromMatrix({
    required final Matrix imageAsMatrix,
    final String supportedCharacters = '',
  }) async {
    assert(
      characterDefinitions.count > 0,
      'No character definitions loaded, did you forget to call Init()',
    );

    /// Start
    processBegin = DateTime.now();

    identifyArtifactsAndBandsInBinaryImage(imageAsMatrix);

    String result = await _getTextFromArtifacts(
      supportedCharacters: supportedCharacters,
    );

    processEnd = DateTime.now();
    // End

    return result;
  }

  /// Processes a binary image to find, merge, and categorize artifacts.
  ///
  /// This method takes a binary image represented as a [Matrix] and performs
  /// a series of operations to identify and process artifacts within the image.
  ///
  /// The process involves three main steps:
  /// 1. Finding individual artifacts in the image.
  /// 2. Merging disconnected parts of artifacts that likely belong together.
  /// 3. Creating bands based on the positions of the merged artifacts.
  ///
  /// Parameters:
  ///   [imageAsBinary] - A [Matrix] representing the binary image to be processed.
  ///
  /// The method does not return a value, but updates internal state to reflect
  /// the found artifacts and bands.
  ///
  /// Note: This method assumes that the input [Matrix] is a valid binary image.
  /// Behavior may be undefined for non-binary input.
  void identifyArtifactsAndBandsInBinaryImage(final Matrix imageAsBinary) {
    // (1) Find artifact using flood fill
    _findArtifacts(imageAsBinary);

    // (2) merge overlapping artifact
    _mergeOverlappingArtifacts();

    // (3) merge proximity artifact for cases like  [i j ; :]
    _mergeConnectedArtifacts(verticalThreshold: 20, horizontalThreshold: 4);

    // (4) create band based on proximity of artifacts
    _assignAllArtifactsToBands();

    // (5) post-process each band for addition clean up of the artifacts in each band
    for (final Band band in bands) {
      band.sortLeftToRight();
      if (this.includeSpaceDetections) {
        band.identifySpacesInBand();
      }
      band.packArtifactLeftToRight();
    }
  }

  /// Merges connected artifacts based on specified thresholds.
  ///
  /// This method iterates through the list of artifacts and merges those that are
  /// considered connected based on vertical and horizontal thresholds.
  ///
  /// Parameters:
  ///   [verticalThreshold]: The maximum vertical distance between artifacts to be considered connected.
  ///   [horizontalThreshold]: The maximum horizontal distance between artifacts to be considered connected.
  ///
  /// Returns:
  ///   A list of [Artifact] objects after merging connected artifacts.
  List<Artifact> _mergeConnectedArtifacts({
    required final double verticalThreshold,
    required final double horizontalThreshold,
  }) {
    final List<Artifact> mergedArtifacts = [];

    for (int i = 0; i < _artifactsToProcess.length; i++) {
      final Artifact current = _artifactsToProcess[i];

      for (int j = i + 1; j < _artifactsToProcess.length; j++) {
        final Artifact next = _artifactsToProcess[j];

        if (_areArtifactsConnected(
          current.matrix.rectangle,
          next.matrix.rectangle,
          verticalThreshold,
          horizontalThreshold,
        )) {
          current.mergeArtifact(next);
          _artifactsToProcess.removeAt(j);
          j--; // Adjust index since we removed an artifact
        }
      }

      mergedArtifacts.add(current);
    }

    return mergedArtifacts;
  }

  /// Determines if two artifacts are connected based on their rectangles and thresholds.
  ///
  /// This method checks both horizontal and vertical proximity of the rectangles.
  ///
  /// Parameters:
  ///   [rect1]: The rectangle of the first artifact.
  ///   [rect2]: The rectangle of the second artifact.
  ///   [verticalThreshold]: The maximum vertical distance to be considered connected.
  ///   [horizontalThreshold]: The maximum horizontal distance to be considered connected.
  ///
  /// Returns:
  ///   true if the artifacts are considered connected, false otherwise.
  bool _areArtifactsConnected(
    final Rect rect1,
    final Rect rect2,
    final double verticalThreshold,
    final double horizontalThreshold,
  ) {
    // Calculate the center X of each rectangle
    final double centerX1 = (rect1.left + rect1.right) / 2;
    final double centerX2 = (rect2.left + rect2.right) / 2;

    // Check horizontal connection using the center X values
    final bool horizontallyConnected =
        (centerX1 - centerX2).abs() <= horizontalThreshold;

    // Check vertical connection as before
    final bool verticallyConnected =
        (rect1.bottom + verticalThreshold >= rect2.top &&
            rect1.top - verticalThreshold <= rect2.bottom);

    return horizontallyConnected && verticallyConnected;
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

    // Create and return the Artifact object
    final Artifact artifact = Artifact();
    artifact.matrix.rectangle = rectangle;

    // Extract the sub-grid from the binary image
    artifact.matrix.setGrid(
      Matrix.extractSubGrid(
        binaryImage: binaryImage,
        rect: rectangle,
      ).data,
    );

    return artifact;
  }

  /// Groups artifacts into horizontal bands based on their vertical positions.
  ///
  /// This method organizes artifacts into bands, which are horizontal groupings
  /// of artifacts that are vertically close to each other. The process involves:
  /// 1. Sorting artifacts by their top y-position.
  /// 2. Iterating through sorted artifacts and assigning them to existing bands
  ///    or creating new bands as necessary.
  ///
  /// The method uses a vertical tolerance to determine if an artifact belongs
  /// to an existing band.
  void _assignAllArtifactsToBands() {
    // Sort artifacts by the top y-position of their rectangles
    this._artifactsToProcess.sort(
          (a, b) => a.matrix.rectangle.top.compareTo(b.matrix.rectangle.top),
        );

    this.bands.clear();
    final List<Artifact> toRemove = [];

    for (final Artifact artifact in this._artifactsToProcess) {
      bool foundBand = false;

      for (final Band band in bands) {
        // final double tolerance = band.rectangle.height * (10 / 100);

        final double overlap = _calculateVerticalOverlapPercentage(
          band.rectangle,
          artifact.matrix.rectangle,
        );
        if (overlap > 50) {
          band.addArtifact(artifact);
          toRemove.add(artifact);
          foundBand = true;
          break;
        }
      }

      if (!foundBand) {
        final Band newBand = Band();
        newBand.addArtifact(artifact);
        toRemove.add(artifact);
        bands.add(newBand);
      }
    }
    _artifactsToProcess.removeWhere((artifact) => toRemove.contains(artifact));

    // all artifacts should not be in a band, thus confirm that there's no loose artifacts
    assert(_artifactsToProcess.isEmpty);
  }

  /// Calculates the percentage of vertical overlap between two rectangles.
  ///
  /// This function determines how much two rectangles overlap vertically and
  /// expresses this overlap as a percentage of their combined heights.
  ///
  /// Parameters:
  ///   - rect1: The first rectangle to compare.
  ///   - rect2: The second rectangle to compare.
  ///
  /// Returns:
  ///   A double representing the percentage of vertical overlap.
  ///   The value ranges from 0.0 (no overlap) to 100.0 (complete overlap).
  ///
  /// The calculation is performed as follows:
  /// 1. Ensure rect1 is the higher rectangle (smaller top value).
  /// 2. Check for no overlap condition.
  /// 3. Calculate the height of the overlapping region.
  /// 4. Calculate the total height of both rectangles combined.
  /// 5. Compute the overlap percentage as (overlap height / total height) * 100.
  ///
  /// Note: This function considers the combined height of both rectangles as the base
  /// for percentage calculation. If you need the percentage relative to one of the
  /// rectangles, you'll need to modify the calculation.
  ///
  /// Example:
  /// ```
  ///   Rect rect1 = Rect.fromLTRB(0, 0, 10, 30);
  ///   Rect rect2 = Rect.fromLTRB(0, 20, 10, 50);
  ///   double overlap = calculateVerticalOverlapPercentage(rect1, rect2);
  ///   print('Overlap: ${overlap.toStringAsFixed(2)}%');
  /// ```
  double _calculateVerticalOverlapPercentage(
    final Rect rect1,
    final Rect rect2,
  ) {
    // Ensure rect1 is the higher rectangle (smaller top value)
    if (rect2.top < rect1.top) {
      return _calculateVerticalOverlapPercentage(rect2, rect1);
    }

    // Check if there's no overlap
    if (rect1.bottom <= rect2.top) {
      return 0.0;
    }

    // Calculate the overlap
    double overlapStart = rect2.top;
    double overlapEnd = min(rect1.bottom, rect2.bottom);
    double overlapHeight = overlapEnd - overlapStart;

    // Calculate the height of the shorter rectangle
    double shorterHeight = min(rect1.height, rect2.height);

    // Calculate and return the percentage
    return (overlapHeight / shorterHeight) * 100;
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

          artifactsFound.add(artifactFound);

          // drop anything that looks like a 1 or 2 pixel
          if (connectedPoints.length > 2) {
            if (excludeLongLines && artifactFound.matrix.isConsideredLine()) {
              // discard lines
            } else {
              final Artifact artifactForWork = _extractArtifact(
                binaryImages,
                connectedPoints,
              );

              // Add the found artifact to the list
              _artifactsToProcess.add(artifactForWork);
            }
          }
        }
      }
    }
  }

  /// Performs a flood fill algorithm on a binary image matrix.
  ///
  /// This method implements a depth-first search flood fill algorithm to find
  /// all connected points starting from a given point in a binary image.
  ///
  /// Parameters:
  ///   [binaryPixels]: A Matrix representing the binary image where true values
  ///                   indicate filled pixels.
  ///   [visited]: A Matrix of the same size as [binaryPixels] to keep track of
  ///              visited pixels.
  ///   [startX]: The starting X coordinate for the flood fill.
  ///   [startY]: The starting Y coordinate for the flood fill.
  ///
  /// Returns:
  ///   A List of Point objects representing all connected points found during
  ///   the flood fill process.
  ///
  /// Throws:
  ///   An assertion error if the areas of [binaryPixels] and [visited] are not equal.
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

  /// Determines the most likely character represented by an artifact.
  ///
  /// This method analyzes the given artifact and attempts to match it against
  /// a set of supported characters, returning the best match.
  ///
  /// Parameters:
  ///   [artifact]: The Artifact object to be analyzed. This typically represents
  ///               a segment of an image that potentially contains a character.
  ///   [supportedCharacters]: An optional string containing all the characters
  ///                          that should be considered in the matching process.
  ///                          If empty, all possible characters are considered.
  ///
  /// Returns:
  ///   A String containing the best matching character. If no match is found
  ///   or if the scores list is empty, an empty string is returned.
  ///
  /// Note:
  ///   This method relies on the `getMatchingScores` function to perform the
  ///   actual character matching and scoring. The implementation of
  ///   `getMatchingScores` is crucial for the accuracy of this method.
  String _getCharacterFromArtifactNormalizedMatrix(
    final Artifact artifact, [
    final String supportedCharacters = '',
  ]) {
    final List<ScoreMatch> scores =
        getMatchingScoresOfNormalizedMatrix(artifact, supportedCharacters);

    return scores.isNotEmpty ? scores.first.character : '';
  }

  /// Calculates the distance scores between an input matrix and a set of character templates.
  ///
  /// This method iterates through each character template, calculates the Hamming distance
  /// percentage between the input matrix and each matrix in the template, and creates a
  /// [ScoreMatch] object for each comparison. The [ScoreMatch] objects are then sorted in
  /// descending order by their score.
  ///
  /// If there is a tie between the top two [ScoreMatch] objects, a tie-breaker is implemented
  /// by calculating the average Hamming distance percentage for all matrices in each template
  /// and swapping the top two [ScoreMatch] objects if the second template has a higher average.
  ///
  /// Parameters:
  ///   [templates]: A list of [CharacterDefinition] objects representing the character templates
  ///                to compare against.
  ///   [inputMatrix]: The input matrix to compare against the character templates.
  ///
  /// Returns:
  ///   A list of [ScoreMatch] objects representing the distance scores between the input matrix
  ///   and the character templates, sorted in descending order by score.
  static List<ScoreMatch> _getDistanceScores(
    List<CharacterDefinition> templates,
    Matrix inputMatrix,
  ) {
    final List<ScoreMatch> scores = [];
    // Iterate through each template in the map
    for (final CharacterDefinition template in templates) {
      // Calculate the similarity score and create a ScoreMatch object
      for (int i = 0; i < template.matrices.length; i++) {
        final Matrix matrix = template.matrices[i];
        final ScoreMatch scoreMatch = ScoreMatch(
          character: template.character,
          matrixIndex: i,
          score: Matrix.hammingDistancePercentage(
            inputMatrix,
            matrix,
          ),
        );

        // Add the ScoreMatch to the scores list
        scores.add(scoreMatch);
      }
    }

    // Sort the scores list in descending order of score 1.0 to 0.0
    scores.sort((a, b) => b.score.compareTo(a.score));

    if (scores.length >= 2) {
      // Implement tie breaker
      if (scores[0].score == scores[1].score) {
        final CharacterDefinition template1 = templates.firstWhere(
          (t) => t.character == scores[0].character,
        );
        final CharacterDefinition template2 = templates.firstWhere(
          (t) => t.character == scores[1].character,
        );

        double totalScore1 = 0;
        double totalScore2 = 0;

        for (final matrix in template1.matrices) {
          totalScore1 += Matrix.hammingDistancePercentage(
            inputMatrix,
            matrix,
          );
        }
        totalScore1 /= template1.matrices.length; // averaging

        for (final matrix in template2.matrices) {
          totalScore2 += Matrix.hammingDistancePercentage(
            inputMatrix,
            matrix,
          );
        }

        totalScore2 /= template2.matrices.length; // averaging

        if (totalScore2 > totalScore1) {
          // Swap the first two elements if the second template has a higher total score
          final temp = scores[0];
          scores[0] = scores[1];
          scores[1] = temp;
        }
      }
    }

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
  Future<String> _getTextFromArtifacts({
    final String supportedCharacters = '',
  }) async {
    this.textFound = '';

    final List<String> linesFound = [];

    for (final Band band in bands) {
      String line = '';

      for (final Artifact artifact in band.artifacts) {
        artifact.characterMatched = _getCharacterFromArtifactNormalizedMatrix(
          artifact,
          supportedCharacters,
        );

        line += artifact.characterMatched;
      }
      linesFound.add(line);
    }

    this.textFound += linesFound.join('\n');

    if (applyDictionary) {
      this.textFound = applyDictionaryCorrection(this.textFound);
    }

    return textFound.trim(); // Trim to remove leading space
  }

  /// Merges overlapping artifacts in the list.
  ///
  /// This method performs a global merge operation on all artifacts in the list.
  /// It identifies overlapping artifacts, merges them, and removes the redundant ones.
  ///
  /// The algorithm works as follows:
  /// 1. Iterate through all pairs of artifacts.
  /// 2. If two artifacts overlap and haven't been marked for removal:
  ///    - Merge them using the [_mergeArtifact] method.
  ///    - Mark the second artifact for removal.
  /// 3. Remove all marked artifacts from the list.
  ///
  /// Time Complexity: O(n^2), where n is the number of artifacts.
  /// Space Complexity: O(n) in the worst case, for the removal set.
  ///
  /// Note: This method modifies the original list of artifacts.
  void _mergeOverlappingArtifacts() {
    final int n = _artifactsToProcess.length;

    final Set<Artifact> toRemove = {};

    for (int i = 0; i < n; i++) {
      final Artifact artifactA = _artifactsToProcess[i];
      if (toRemove.contains(artifactA)) {
        // already merged
        continue;
      }

      for (int j = i + 1; j < n; j++) {
        final Artifact artifactB = _artifactsToProcess[j];
        if (toRemove.contains(artifactB)) {
          // already merged
          continue;
        }

        if (artifactA.matrix.rectangle.overlaps(artifactB.matrix.rectangle)) {
          artifactA.mergeArtifact(artifactB);
          toRemove.add(artifactB);
        }
      }
    }

    _artifactsToProcess.removeWhere((artifact) => toRemove.contains(artifact));
  }
}

/// Loads an image from the specified asset path.
///
/// This function asynchronously loads an image from the specified asset path and
/// returns a [Future] that completes with the loaded [ui.Image] instance.
///
/// The function uses [AssetImage] to resolve the image and listens to the
/// [ImageStream] to get the loaded image.
///
/// Example usage:
///
/// final image = await loadImage('assets/my_image.png');
///
Future<ui.Image> loadImageFromAssets(String assetPath) async {
  final assetImage = AssetImage(assetPath);
  final completer = Completer<ui.Image>();
  assetImage.resolve(ImageConfiguration.empty).addListener(
        ImageStreamListener((info, _) => completer.complete(info.image)),
      );
  return completer.future;
}
