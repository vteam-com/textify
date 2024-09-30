import 'dart:math';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:textify/matrix_enclosures.dart';
import 'package:textify/matrix_lines.dart';

extension RectArea on Rect {
  double area() => width * height;
}

class Matrix {
  Matrix([num width = 0, num height = 0, bool value = false]) {
    data = List.generate(
      height.toInt(),
      (_) => List.filled(width.toInt(), false),
    );
    cols = width.toInt();
    rows = height.toInt();
  }

  factory Matrix.fromAsciiDefinition(final List<String> template) {
    Matrix matrix = Matrix();
    matrix.rows = template.length;
    matrix.cols = template[0].length;
    matrix.data = List.generate(
      matrix.rows,
      (y) => List.generate(matrix.cols, (x) => template[y][x] == '#'),
    );
    return matrix;
  }

  factory Matrix.fromBoolMatrix(final List<List<bool>> input) {
    Matrix matrix = Matrix();
    matrix.setGrid(input);
    return matrix;
  }

  factory Matrix.fromFlatListOfBool(
    final List<bool> inputList,
    final int width,
  ) {
    Matrix matrix = Matrix();
    matrix.rows = inputList.length ~/ width;
    matrix.cols = width;

    for (int y = 0; y < matrix.rows; y++) {
      matrix.data.add(inputList.sublist(y * matrix.cols, (y + 1) * matrix.cols));
    }
    return matrix;
  }

  factory Matrix.fromJson(Map<String, dynamic> json) {
    Matrix matrix = Matrix();
    matrix.rows = json['rows'];
    matrix.cols = json['cols'];
    matrix.data = (json['data'] as List<dynamic>).map((row) {
      return row.toString().split('').map((cell) => cell == '#').toList();
    }).toList();
    return matrix;
  }

  factory Matrix.fromUint8List(
    final Uint8List pixels,
    int width,
  ) {
    return Matrix.fromFlatListOfBool(
      [
        for (int i = 0; i < pixels.length; i += 4) pixels[i] == 0,
      ],
      width,
    );
  }

  int cols = 0;
  List<List<bool>> data = [];
  int rows = 0;

  int _enclosures = -1;

  bool? _verticalLineLeft;
  bool? _verticalLineRight;

  int get area => cols * rows;

  double aspectRatioOfContent() {
    int minX = cols;
    int maxX = 0;
    int minY = rows;
    int maxY = 0;

    for (int y = 0; y < rows; y++) {
      for (int x = 0; x < cols; x++) {
        if (data[y][x]) {
          minX = min(minX, x);
          maxX = max(maxX, x);
          minY = min(minY, y);
          maxY = max(maxY, y);
        }
      }
    }
    int width = maxX - minX;
    int height = maxY - minY;

    return height / width.toDouble(); // Aspect ratio
  }

  /// Calculates a penalty based on differences in aspect ratios between grids.
  static double calculateAspectRatioPenalty(
    Matrix inputGrid,
    Matrix templateGrid,
  ) {
    // Get bounding boxes for both grids
    Rect inputBoundingBox = Matrix.getBoundingBox(inputGrid);
    Rect templateBoundingBox = Matrix.getBoundingBox(templateGrid);

    // Calculate aspect ratios
    double inputAspectRatio = inputBoundingBox.width / inputBoundingBox.height;
    double templateAspectRatio = templateBoundingBox.width / templateBoundingBox.height;

    // Calculate the difference in aspect ratios
    double aspectRatioDifference = (inputAspectRatio - templateAspectRatio).abs();

    // Normalize the penalty based on the aspect ratios
    return aspectRatioDifference;
  }

  // Function to penalize mismatches along the outer boundary of the shape
  static double calculateBoundaryMismatchPenalty(
    Matrix inputGrid,
    Matrix templateGrid,
  ) {
    int rows = inputGrid.rows;
    int cols = inputGrid.cols;

    int boundaryMismatchCount = 0;

    // Check edges of the grid (outermost rows and columns)
    for (int i = 0; i < rows; i++) {
      if (inputGrid.data[i][0] != templateGrid.data[i][0] ||
          inputGrid.data[i][cols - 1] != templateGrid.data[i][cols - 1]) {
        boundaryMismatchCount++;
      }
    }

    for (int j = 0; j < cols; j++) {
      if (inputGrid.data[0][j] != templateGrid.data[0][j] ||
          inputGrid.data[rows - 1][j] != templateGrid.data[rows - 1][j]) {
        boundaryMismatchCount++;
      }
    }

    // Return a penalty proportional to the number of boundary mismatches
    return boundaryMismatchCount.toDouble() * 0.1; // Tune this factor
  }

  /// Calculates a penalty based on differences in bounding boxes between grids.
  static double calculateBoundingBoxPenalty(
    Matrix inputGrid,
    Matrix templateGrid,
  ) {
    // Get bounding boxes for both grids
    Rect inputBoundingBox = Matrix.getBoundingBox(inputGrid);
    Rect templateBoundingBox = Matrix.getBoundingBox(templateGrid);

    // Calculate the difference in areas of the bounding boxes
    double areaDifference = (inputBoundingBox.area() - templateBoundingBox.area()).abs();

    // Normalize the penalty based on bounding box area
    double maxArea =
        (inputBoundingBox.area() > templateBoundingBox.area()) ? inputBoundingBox.area() : templateBoundingBox.area();

    return areaDifference / maxArea;
  }

  // Calculate the center of mass (centroid) of a grid
  static List<double> calculateCenterOfMass(Matrix grid) {
    int totalPoints = 0;
    double sumX = 0;
    double sumY = 0;

    for (int y = 0; y < grid.rows; y++) {
      for (int x = 0; x < grid.cols; x++) {
        if (grid.data[y][x]) {
          sumX += x;
          sumY += y;
          totalPoints++;
        }
      }
    }

    if (totalPoints == 0) {
      return [0, 0]; // Avoid division by zero if grid is empty
    }

    return [sumX / totalPoints, sumY / totalPoints];
  }

  static double calculateHorizontalLinePenalty(
    Matrix inputGrid,
    Matrix templateGrid,
  ) {
    bool hasHorizontalLineInput = inputGrid.detectHorizontalLine();
    bool hasHorizontalLineTemplate = templateGrid.detectHorizontalLine();

    // Penalize if a horizontal line is present in one grid but not the other
    if (hasHorizontalLineInput != hasHorizontalLineTemplate) {
      return 0.1; // Adjust penalty value based on experimentation
    }

    return 0.0;
  }

  bool cellGet(final int x, final int y) {
    if (isValidXY(x, y)) {
      return data[y][x];
    }
    return false;
  }

  void cellSet(final int x, final int y, bool value) {
    if (isValidXY(x, y)) {
      data[y][x] = value;
    }
  }

  /// Helper function to copy a grid onto another at a specific offset
  static void copyGrid(
    final Matrix source,
    final Matrix target,
    final int offsetX,
    final int offsetY,
  ) {
    for (int y = 0; y < source.rows; y++) {
      for (int x = 0; x < source.cols; x++) {
        if (y + offsetY < target.rows && x + offsetX < target.cols) {
          target.data[y + offsetY][x + offsetX] |= source.data[y][x];
        }
      }
    }
  }

  // Calculate the number of true cells in a grid
  int countTrueCells() {
    int count = 0;
    for (final List<bool> row in data) {
      for (final bool cell in row) {
        if (cell) {
          count++;
        }
      }
    }
    return count;
  }

  Matrix createCropGrid() {
    if (isEmpty || isEmpty) {
      return Matrix();
    }
    // Find the boundaries of the content
    int topRow = 0;
    int bottomRow = rows - 1;
    int leftCol = 0;
    int rightCol = cols - 1;

    // Find top row with content
    while (topRow < rows && !data[topRow].contains(true)) {
      topRow++;
    }

    // Find bottom row with content
    while (bottomRow > topRow && !data[bottomRow].contains(true)) {
      bottomRow--;
    }

    // Find left column with content
    outer:
    while (leftCol < cols) {
      for (int i = topRow; i <= bottomRow; i++) {
        if (data[i][leftCol]) {
          break outer;
        }
      }
      leftCol++;
    }

    // Find right column with content
    outer:
    while (rightCol > leftCol) {
      for (int i = topRow; i <= bottomRow; i++) {
        if (data[i][rightCol]) {
          break outer;
        }
      }
      rightCol--;
    }

    // Crop the grid
    return Matrix.fromBoolMatrix(
      List.generate(
        bottomRow - topRow + 1,
        (i) => data[i + topRow].sublist(leftCol, rightCol + 1),
      ),
    );
  }

  Matrix createNormalizeMatrix(
    int desiredWidth,
    int desiredHeight,
  ) {
    // help resizing by ensuring there's a border
    if (isPonctuation()) {
      // do not crop and center
      return createWrapGridWithFalse().createResizedGrid(
        desiredWidth,
        desiredHeight,
      );
    } else {
      // Resise
      return createCropGrid().createWrapGridWithFalse().createResizedGrid(
            desiredWidth,
            desiredHeight,
          );
    }
  }

  Matrix createResizedGrid(
    int targetWidth,
    int targetHeight,
  ) {
    // Initialize the resized grid
    Matrix resizedGrid = Matrix.fromBoolMatrix(
      List.generate(
        targetHeight,
        (i) => List.filled(targetWidth, false),
        growable: true,
      ),
    );

    // Calculate the scale factors
    double xScale = cols / targetWidth;
    double yScale = rows / targetHeight;

    for (int y = 0; y < targetHeight; y++) {
      for (int x = 0; x < targetWidth; x++) {
        // Coordinates in the original grid
        double srcX = x * xScale;
        double srcY = y * yScale;

        if (targetWidth > cols || targetHeight > rows) {
          // Upscaling: Use nearest-neighbor interpolation
          int srcXInt = srcX.floor();
          int srcYInt = srcY.floor();
          resizedGrid.data[y][x] = data[srcYInt][srcXInt];
        } else {
          // Downscaling: Average the values in the sub-grid
          int startX = srcX.floor();
          int endX = (srcX + xScale).ceil();
          int startY = srcY.floor();
          int endY = (srcY + yScale).ceil();

          int blackCount = 0;
          int totalCount = 0;

          for (int sy = startY; sy < endY && sy < rows; sy++) {
            for (int sx = startX; sx < endX && sx < cols; sx++) {
              if (data[sy][sx]) {
                blackCount++;
              }
              totalCount++;
            }
          }

          // Set the resized grid value based on average
          resizedGrid.data[y][x] = blackCount * 2 > totalCount; // Threshold: more than half black pixels
        }
      }
    }
    return resizedGrid;
  }

  Matrix createWrapGridWithFalse() {
    if (isEmpty) {
      return Matrix.fromBoolMatrix([
        [false, false],
        [false, false],
        [false, false],
      ]);
    }

    // Create a new grid with increased dimensions
    Matrix newGrid = Matrix.fromBoolMatrix(
      List.generate(
        rows + 2,
        (r) => List.generate(cols + 2, (c) => false),
      ),
    );

    // Copy the original grid into the center of the new grid
    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        newGrid.data[r + 1][c + 1] = data[r][c];
      }
    }

    return newGrid;
  }

  /// Helper function to detect the presence of horizontal lines in a grid.
  bool detectHorizontalLine() {
    for (int y = 0; y < rows; y++) {
      bool hasActiveCell = false;
      for (int x = 0; x < cols; x++) {
        if (data[y][x]) {
          hasActiveCell = true;
          break;
        }
      }
      if (hasActiveCell) {
        // Check if the line spans the whole width or a significant part
        int activeCells = data[0].length;
        int threshold = (0.5 * activeCells).toInt(); // Example threshold
        if (activeCells >= threshold) {
          return true;
        }
      }
    }
    return false;
  }

  int get enclosures {
    if (_enclosures == -1) {
      _enclosures = countEnclosedRegion(this);
    }
    return _enclosures;
  }

  static Matrix extractSubGrid({
    required final Matrix binaryImage,
    required final Rect rect,
  }) {
    int startX = rect.left.toInt();
    int startY = rect.top.toInt();
    int subImageWidth = rect.width.toInt();
    int subImageHeight = rect.height.toInt();

    Matrix subImagePixels = Matrix(subImageWidth, subImageHeight, false);

    for (int x = 0; x < subImageWidth; x++) {
      for (int y = 0; y < subImageHeight; y++) {
        final int sourceX = startX + x;
        final int sourceY = startY + y;

        if (sourceX < binaryImage.cols && sourceY < binaryImage.rows) {
          subImagePixels.cellSet(x, y, binaryImage.cellGet(sourceX, sourceY));
        }
      }
    }

    return subImagePixels;
  }

  List<String> getAsListOfString() {
    List<String> result = [];

    for (int row = 0; row < rows; row++) {
      String rowString = '';
      for (int col = 0; col < cols; col++) {
        rowString += cellGet(col, row) ? '#' : '.';
      }

      result.add(rowString);
    }

    return result;
  }

  /// Helper function to get the bounding box of the active area in the grid.
  static Rect getBoundingBox(Matrix grid) {
    int minX = grid.cols;
    int minY = grid.rows;
    int maxX = 0;
    int maxY = 0;

    for (int y = 0; y < grid.rows; y++) {
      for (int x = 0; x < grid.cols; x++) {
        if (grid.data[y][x]) {
          if (x < minX) {
            minX = x;
          }
          if (x > maxX) {
            maxX = x;
          }
          if (y < minY) {
            minY = y;
          }
          if (y > maxY) {
            maxY = y;
          }
        }
      }
    }

    return Rect.fromLTWH(
      minX.toDouble(),
      minY.toDouble(),
      (maxX - minX + 1).toDouble(),
      (maxY - minY + 1).toDouble(),
    );
  }

  Rect getContentRect() {
    if (data.isEmpty || data[0].isEmpty) {
      return Rect.zero;
    }

    int minX = cols;
    int maxX = -1;
    int minY = rows;
    int maxY = -1;

    for (int y = 0; y < rows; y++) {
      for (int x = 0; x < cols; x++) {
        if (data[y][x]) {
          minX = min(minX, x);
          maxX = max(maxX, x);
          minY = min(minY, y);
          maxY = max(maxY, y);
        }
      }
    }

    // If no content found, return Rect.zero
    if (maxX == -1 || maxY == -1) {
      return Rect.zero;
    }

    return Rect.fromLTRB(
      minX.toDouble(),
      minY.toDouble(),
      (maxX + 1).toDouble(),
      (maxY + 1).toDouble(),
    );
  }

  /// Calculates a match score between an input grid and a template grid.
  ///
  /// This function compares two boolean grids and returns a score indicating how
  /// well they match. The score is based on several factors including similarity,
  /// aspect ratio, edge characteristics, and center enclosure.
  ///
  /// Parameters:
  /// - [inputGrid]: The grid being evaluated. It should be a 2D list of booleans
  ///   where true represents an active cell and false an inactive cell.
  /// - [templateGrid]: The reference grid to compare against. It should have the
  ///   same structure as the inputGrid.
  ///
  /// Returns:
  /// A [double] representing the match score. A higher score indicates a better
  /// match. The score is calculated as follows:
  /// - 50% of the score is based on the similarity (Hamming distance)
  /// - 20% is based on the aspect ratio comparison
  /// - 10% is deducted based on edge characteristics
  /// - 20% is added if the center of the input grid is enclosed
  ///
  /// The final score is normalized and typically falls between 0 and 1, but may
  /// exceed 1 in some cases.
  ///
  static double getDistancePercentage(
    Matrix inputGrid,
    Matrix templateGrid,
  ) {
    if (inputGrid.isEmpty ||
        templateGrid.isEmpty ||
        inputGrid.rows != templateGrid.rows ||
        inputGrid.cols != templateGrid.cols) {
      throw ArgumentError('Grids must be non-empty and of the same size.');
    }

    final double hammingDist = Matrix.hammingDistance(inputGrid, templateGrid);
    return hammingDist;
/*
  // Calculate number of active cells (true values) in both grids
  int activeInputCells = countTrueCells(inputGrid);
  int activeTemplateCells = countTrueCells(templateGrid);

  // Calculate size difference
  double sizeDifference = (activeInputCells - activeTemplateCells).abs() /
      activeTemplateCells.toDouble();
  double sizePenalty =
      sizeDifference / 30; // Tune this factor based on experimentation

  // Compute bounding box, aspect ratio, and specific feature penalties
  double boundingBoxPenalty =
      calculateBoundingBoxPenalty(inputGrid, templateGrid);
  double aspectRatioPenalty =
      calculateAspectRatioPenalty(inputGrid, templateGrid);
  double horizontalLinePenalty =
      calculateHorizontalLinePenalty(inputGrid, templateGrid);

  // Adjust final score with peak and loop counts, and additional penalties
  double finalScore = normalizedSimilarity -
      boundingBoxPenalty -
      aspectRatioPenalty -
      horizontalLinePenalty;

  // Penalize size difference
  finalScore -= sizePenalty;

  return finalScore;
  */
  }

  Size getSizeOfContent() {
    Rect contentRect = getContentRect();
    return contentRect.size;
  }

  static List<String> getStringListOfOverlayedGrids(
    final Matrix grid1,
    final Matrix grid2,
  ) {
    final int height = grid1.rows;
    final int width = grid1.cols;

    if (height != grid2.rows || width != grid2.cols) {
      throw Exception('Grids must have the same dimensions');
    }

    List<String> overlayedGrid = [];

    for (int row = 0; row < height; row++) {
      String overlayedRow = '';

      for (int col = 0; col < width; col++) {
        final bool cell1 = grid1.data[row][col];
        final bool cell2 = grid2.data[row][col];

        if (cell1 && cell2) {
          overlayedRow += '=';
        } else if (cell1) {
          overlayedRow += '*';
        } else if (cell2) {
          overlayedRow += '#';
        } else {
          overlayedRow += '.';
        }
      }

      overlayedGrid.add(overlayedRow);
    }

    return overlayedGrid;
  }

  String gridToText({
    bool forCode = false,
    String onChar = '#',
    String offChar = '.',
  }) {
    List<String> rows = [];
    for (int y = 0; y < this.rows; y++) {
      String row = '';
      for (int x = 0; x < cols; x++) {
        row += cellGet(x, y) ? onChar : offChar;
      }
      //row += ' ${row.length}';
      rows.add(row);
    }
    if (forCode) {
      String rowsAsText = rows.join('",\n"');
      return '"$rowsAsText"';
    }
    return rows.join('\n');
  }

  static double hammingDistance(
    Matrix inputGrid,
    Matrix templateGrid,
  ) {
    int distance = 0;
    for (int y = 0; y < inputGrid.rows; y++) {
      for (int x = 0; x < inputGrid.cols; x++) {
        if (inputGrid.data[y][x] != templateGrid.data[y][x]) {
          distance++;
        }
      }
    }

    final int gridSize = inputGrid.area;
    final double normalizedSimilarity = 1.0 - (distance / gridSize.toDouble());
    return normalizedSimilarity;
  }

  bool isConsidreredLine() {
    var ar = aspectRatioOfContent();
    if (ar < 0.25 || ar > 50) {
      return true;
    }
    return false;
  }

  bool get isEmpty => data.isEmpty;

  bool get isNotEmpty => data.isEmpty == false;

// smaller (~30%) in height artifacts will be considred ponctuation
  bool isPonctuation() {
    // Calculate the height of the content
    final Size size = getSizeOfContent();

    // If there's no content, it's not punctuation
    if (size == Size.zero) {
      return false;
    }

    // Check if the content height is less than 20% of the total height
    return size.height < (rows * 0.40);
  }

  bool isValidXY(final int x, final int y) {
    return (x >= 0 && x < cols) && (y >= 0 && y < rows);
  }

  // Custom comparison method for matrices
  static bool matrixEquals(Matrix a, Matrix b) {
    // Check if dimensions are the same
    if (a.rows != b.rows || a.cols != b.cols) {
      return false;
    }

    // Compare each cell
    for (int y = 0; y < a.rows; y++) {
      for (int x = 0; x < a.cols; x++) {
        if (a.data[y][x] != b.data[y][x]) {
          return false;
        }
      }
    }

    // If we've made it this far, the matrices are equal
    return true;
  }

  /// Sets the internal grid data of the matrix from a 2D list of boolean values.
  ///
  /// This method takes a 2D list of boolean values representing the grid data
  /// and sets the internal `data` list of the matrix accordingly. It also updates
  /// the `rows` and `cols` properties to match the dimensions of the input grid.
  ///
  /// Parameters:
  /// - grid: A 2D list of boolean values representing the grid data. Each inner
  ///   list represents a row, and each boolean value represents a cell in that row.
  ///
  /// Throws:
  /// - [ArgumentError] if the input grid is not rectangular (i.e., not all rows
  ///   have the same length).
  ///
  /// Edge cases:
  /// - If the input grid is empty or its first row is empty, the method sets
  ///   `rows` and `cols` to 0 and clears the `data` list.
  ///
  /// Implementation details:
  /// - The method creates a deep copy of the input grid to ensure that changes
  ///   to the original grid won't affect the internal data.
  /// - It uses `List.generate` with `List<bool>.from` to create the deep copy.
  /// - After creating the copy, it verifies that all rows have the same length
  ///   as `cols`. If not, it throws an `ArgumentError`.
  /// - If the input grid is valid, it updates the `rows` and `cols` properties
  ///   based on the dimensions of the input grid.
  void setGrid(List<List<bool>> grid) {
    if (grid.isEmpty || grid[0].isEmpty) {
      rows = 0;
      cols = 0;
      data = [];
      return;
    }

    rows = grid.length;
    cols = grid[0].length;

    // Create a deep copy of the grid
    data = List.generate(
      rows,
      (i) => List<bool>.from(grid[i]),
    );

    // Ensure all rows have the same length
    assert(
      data.every((row) => row.length == cols),
      'All rows in the grid must have the same length',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'rows': rows,
      'cols': cols,
      'data': data.map((row) {
        return row.map((cell) => cell ? '#' : '.').join();
      }).toList(),
    };
  }

  bool get verticalLineLeft {
    _verticalLineLeft ??= hasVerticalLineLeft(this);
    return _verticalLineLeft!;
  }

  bool get verticalLineRight {
    _verticalLineRight ??= hasVerticalLineRight(this);
    return _verticalLineRight!;
  }
}
