import 'dart:collection';
import 'dart:math';
import 'dart:ui';

import 'package:flutter/foundation.dart';

extension RectArea on Rect {
  double area() => width * height;
}

/// Represents a 2D grid of boolean values, primarily used for image processing
/// and pattern recognition tasks.
///
/// This class provides various ways to create, manipulate, and analyze boolean matrices,
/// including methods for resizing, comparing, and extracting information from the grid.
class Matrix {
  /// Creates a new Matrix with the specified dimensions, filled with the given value.
  ///
  /// [width] The number of columns in the matrix.
  /// [height] The number of rows in the matrix.
  /// [value] The initial value for all cells (default is false).
  Matrix([num width = 0, num height = 0, bool value = false]) {
    data = List.generate(
      height.toInt(),
      (_) => List.filled(width.toInt(), false),
    );
    cols = width.toInt();
    rows = height.toInt();
  }

  /// Creates a Matrix from an ASCII representation.
  ///
  /// [template] A list of strings where '#' represents true and any other character represents false.
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

  /// Creates a Matrix from an existing 2D boolean list.
  ///
  /// [input] A 2D list of boolean values.
  factory Matrix.fromBoolMatrix(final List<List<bool>> input) {
    Matrix matrix = Matrix();
    matrix.setGrid(input);
    return matrix;
  }

  /// Creates a Matrix from a flat list of boolean values.
  ///
  /// [inputList] A flat list of boolean values.
  /// [width] The width of the resulting matrix.
  factory Matrix.fromFlatListOfBool(
    final List<bool> inputList,
    final int width,
  ) {
    Matrix matrix = Matrix();
    matrix.rows = inputList.length ~/ width;
    matrix.cols = width;

    for (int y = 0; y < matrix.rows; y++) {
      matrix.data
          .add(inputList.sublist(y * matrix.cols, (y + 1) * matrix.cols));
    }
    return matrix;
  }

  /// Creates a Matrix from JSON data.
  ///
  /// [json] A map containing 'rows', 'cols', and 'data' keys.
  factory Matrix.fromJson(Map<String, dynamic> json) {
    Matrix matrix = Matrix();
    matrix.font = json['font'];
    matrix.rows = json['rows'];
    matrix.cols = json['cols'];
    matrix.data = (json['data'] as List<dynamic>).map((row) {
      return row.toString().split('').map((cell) => cell == '#').toList();
    }).toList();
    return matrix;
  }

  /// Creates a Matrix from a Uint8List, typically used for image data.
  ///
  /// [pixels] A Uint8List representing pixel data.
  /// [width] The width of the image.
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

  /// Font this matrix template is based on
  String font = '';

  /// The number of columns in the matrix.
  int cols = 0;

  /// The 2D list representing the boolean grid.
  List<List<bool>> data = [];

  /// The number of rows in the matrix.
  int rows = 0;

  /// The number of enclosure found
  int _enclosures = -1;

  /// The number of vertical left lines found
  bool? _verticalLineLeft;

  /// The number of vertical right lines found
  bool? _verticalLineRight;

  /// Area size of the matrix
  int get area => cols * rows;

  /// Calculates the aspect ratio of the content within the matrix.
  ///
  /// Returns the height-to-width ratio of the bounding box containing all true cells.
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

  /// Retrieves the value of a cell at the specified coordinates.
  ///
  /// Returns false if the coordinates are out of bounds.
  bool cellGet(final int x, final int y) {
    if (isValidXY(x, y)) {
      return data[y][x];
    }
    return false;
  }

  /// Sets the value of a cell at the specified coordinates.
  ///
  /// Does nothing if the coordinates are out of bounds.
  void cellSet(final int x, final int y, bool value) {
    if (isValidXY(x, y)) {
      data[y][x] = value;
    }
  }

  /// Copies the content of one matrix onto another at a specific offset.
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

  /// Trims the matrix by removing empty rows and columns from all sides.
  ///
  /// This method removes rows and columns that contain only false values from
  /// the edges of the matrix, effectively trimming it to the smallest possible
  /// size that contains all true values.
  ///
  /// Returns:
  /// A new Matrix object that is a trimmed version of the original. If the
  /// original matrix is empty or contains only false values, it returns an
  /// empty Matrix.
  ///
  /// Note: This method does not modify the original matrix but returns a new one.
  Matrix trim() {
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

  /// Creates a normalized Matrix with the specified dimensions.
  ///
  /// This method handles resizing and special cases like punctuation.
  Matrix createNormalizeMatrix(
    int desiredWidth,
    int desiredHeight,
  ) {
    // help resizing by ensuring there's a border
    if (isPunctuation()) {
      // do not crop and center
      return createWrapGridWithFalse().createResizedGrid(
        desiredWidth,
        desiredHeight,
      );
    } else {
      // Resize
      return trim().createWrapGridWithFalse().createResizedGrid(
            desiredWidth,
            desiredHeight,
          );
    }
  }

  /// Creates a resized version of the current matrix.
  ///
  /// This method resizes the matrix to the specified target dimensions using
  /// different strategies for upscaling and downscaling.
  ///
  /// Parameters:
  /// - [targetWidth]: The desired width of the resized matrix.
  /// - [targetHeight]: The desired height of the resized matrix.
  ///
  /// Returns:
  /// A new Matrix object with the specified dimensions, containing a resized
  /// version of the original matrix's content.
  ///
  /// Resizing strategy:
  /// - For upscaling (target size larger than original), it uses nearest-neighbor interpolation.
  /// - For downscaling (target size smaller than original), it averages the values in each sub-grid.
  Matrix createResizedGrid(final int targetWidth, final int targetHeight) {
    // Initialize the resized grid
    Matrix resizedGrid = Matrix(targetWidth, targetHeight);

    // Calculate the scale factors
    double xScale = cols / targetWidth;
    double yScale = rows / targetHeight;

    for (int y = 0; y < targetHeight; y++) {
      for (int x = 0; x < targetWidth; x++) {
        // Coordinates in the original grid
        double srcX = x * xScale;
        double srcY = y * yScale;

        if (targetWidth > cols || targetHeight > rows) {
          // UpScaling: Use nearest-neighbor interpolation
          int srcXInt = srcX.floor();
          int srcYInt = srcY.floor();
          resizedGrid.data[y][x] = data[srcYInt][srcXInt];
        } else {
          // DownScaling: Average the values in the sub-grid
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
          resizedGrid.data[y][x] = blackCount * 2 >
              totalCount; // Threshold: more than half black pixels
        }
      }
    }
    return resizedGrid;
  }

  /// Adds padding to the top and bottom of the matrix.
  ///
  /// This method inserts blank lines at the top and bottom of the matrix data,
  /// effectively adding padding to the matrix.
  ///
  /// Parameters:
  /// - [paddingTop]: The number of blank lines to add at the top of the matrix.
  /// - [paddingBottom]: The number of blank lines to add at the bottom of the matrix.
  ///
  /// The method modifies the matrix in place by:
  /// 1. Creating blank lines (rows filled with `false` values).
  /// 2. Inserting the specified number of blank lines at the top of the matrix.
  /// 3. Appending the specified number of blank lines at the bottom of the matrix.
  /// 4. Updating the total number of rows in the matrix.
  void paddTopBottom({
    required int paddingTop,
    required int paddingBottom,
  }) {
    final blankLine = List.filled(cols, false);

    for (var add = 0; add < paddingTop; add++) {
      data.insert(0, blankLine);
    }

    for (var add = 0; add < paddingBottom; add++) {
      data.add(blankLine);
    }
    rows = data.length;
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

  /// Gets the number of enclosed regions in the matrix.
  ///
  /// An enclosed region is a contiguous area of false cells completely
  /// surrounded by true cells. This getter calculates the number of such
  /// regions in the matrix.
  ///
  /// The calculation is performed only once and the result is cached for
  /// subsequent calls to improve performance.
  ///
  /// Returns:
  /// An integer representing the number of enclosed regions in the matrix.
  ///
  /// Note: The actual counting is performed by the `countEnclosedRegion`
  /// function, which is assumed to be defined elsewhere in the class or
  /// imported from another file.
  int get enclosures {
    if (_enclosures == -1) {
      _enclosures = countEnclosedRegion(this);
    }
    return _enclosures;
  }

  /// Extracts a sub-grid from a larger binary image matrix.
  ///
  /// This static method creates a new Matrix object representing a portion of
  /// the input binary image, as specified by the given rectangle.
  ///
  /// Parameters:
  /// - [binaryImage]: The source Matrix from which to extract the sub-grid.
  /// - [rect]: A Rect object specifying the region to extract. The rect's
  ///   coordinates are relative to the top-left corner of the binaryImage.
  ///
  /// Returns:
  /// A new Matrix object containing the extracted sub-grid.
  ///
  /// Note:
  /// - If the specified rectangle extends beyond the boundaries of the source
  ///   image, the out-of-bounds areas in the resulting sub-grid will be false.
  /// - The method uses integer coordinates, so any fractional values in the
  ///   rect will be truncated.
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

  /// Calculates the size of the content area in the matrix.
  ///
  /// This method determines the dimensions of the smallest rectangle that
  /// encompasses all true cells in the matrix. It uses the `getContentRect`
  /// method to find the bounding rectangle and then returns its size.
  ///
  /// Returns:
  /// A Size object representing the width and height of the content area.
  ///
  /// If the matrix is empty or contains no true cells, it returns a Size
  /// with zero width and height.
  ///
  /// Note:
  /// - The returned Size uses double values for width and height to be
  ///   compatible with Flutter's Size class.
  /// - This method is a convenient way to get the dimensions of the content
  ///   without needing the full Rect information.
  Size getContentSize() {
    Rect contentRect = getContentRect();
    return contentRect.size;
  }

  /// Calculates the bounding rectangle of the content in the matrix.
  ///
  /// This method finds the smallest rectangle that encompasses all true cells
  /// in the matrix. It's useful for determining the area of the matrix that
  /// contains actual content.
  ///
  /// Returns:
  /// A Rect object representing the bounding rectangle of the content.
  /// The rectangle is defined by its left, top, right, and bottom coordinates.
  ///
  /// If the matrix is empty or contains no true cells, it returns Rect.zero.
  ///
  /// Note:
  /// - The returned Rect uses double values for coordinates to be compatible
  ///   with Flutter's Rect class.
  /// - The right and bottom coordinates are exclusive (i.e., they point to
  ///   the cell just after the last true cell in each direction).
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

  /// Creates a string representation of two overlaid matrices.
  ///
  /// This static method compares two matrices cell by cell and generates a new
  /// representation where each cell is represented by a character based on the
  /// values in both input matrices.
  ///
  /// Parameters:
  /// - [grid1]: The first Matrix to be overlaid.
  /// - [grid2]: The second Matrix to be overlaid.
  ///
  /// Returns:
  /// A List<String> where each string represents a row in the overlaid result.
  /// The characters in the resulting strings represent:
  ///   '=' : Both matrices have true in this cell
  ///   '*' : Only grid1 has true in this cell
  ///   '#' : Only grid2 has true in this cell
  ///   '.' : Both matrices have false in this cell
  ///
  /// Throws:
  /// An Exception if the input matrices have different dimensions.
  ///
  /// Note:
  /// This method is useful for visualizing the differences and similarities
  /// between two matrices, which can be helpful in debugging or analysis tasks.
  static List<String> getStringListOfOverladedGrids(
    final Matrix grid1,
    final Matrix grid2,
  ) {
    final int height = grid1.rows;
    final int width = grid1.cols;

    if (height != grid2.rows || width != grid2.cols) {
      throw Exception('Grids must have the same dimensions');
    }

    List<String> overladedGrid = [];

    for (int row = 0; row < height; row++) {
      String overladedRow = '';

      for (int col = 0; col < width; col++) {
        final bool cell1 = grid1.data[row][col];
        final bool cell2 = grid2.data[row][col];

        if (cell1 && cell2) {
          overladedRow += '=';
        } else if (cell1) {
          overladedRow += '*';
        } else if (cell2) {
          overladedRow += '#';
        } else {
          overladedRow += '.';
        }
      }

      overladedGrid.add(overladedRow);
    }

    return overladedGrid;
  }

  /// Converts the matrix to a string representation.
  ///
  /// This method creates a string representation of the matrix, with options
  /// to format it for code or for display.
  ///
  /// Parameters:
  /// - [forCode]: If true, formats the output as a Dart string literal.
  ///              Default is false.
  /// - [onChar]: The character to represent true cells. Default is '#'.
  /// - [offChar]: The character to represent false cells. Default is '.'.
  ///
  /// Returns:
  /// A string representation of the matrix. If [forCode] is true, the string
  /// is formatted as a multi-line Dart string literal.
  ///
  /// Example:
  /// If [forCode] is false:
  /// "#.#\n.#.\n#.#"
  ///
  /// If [forCode] is true:
  /// "\"#.#\",\n\".#.\",\n\"#.#\""
  String gridToString({
    bool forCode = false,
    String onChar = '#',
    String offChar = '.',
  }) {
    final List<String> list = gridToStrings(onChar: onChar, offChar: offChar);

    if (forCode) {
      String listAsText = list.join('",\n"');
      return '"$listAsText"';
    }
    return list.join('\n');
  }

  /// Converts the matrix to a list of strings.
  ///
  /// This method creates a list where each string represents a row in the matrix.
  ///
  /// Parameters:
  /// - [onChar]: The character to represent true cells. Default is '#'.
  /// - [offChar]: The character to represent false cells. Default is '.'.
  ///
  /// Returns:
  /// A List<String> where each string represents a row in the matrix.
  ///
  /// Example:
  /// ["#.#", ".#.", "#.#"]
  List<String> gridToStrings({
    String onChar = '#',
    String offChar = '.',
  }) {
    List<String> result = [];

    for (int row = 0; row < rows; row++) {
      String rowString = '';
      for (int col = 0; col < cols; col++) {
        rowString += cellGet(col, row) ? onChar : offChar;
      }

      result.add(rowString);
    }

    return result;
  }

  /// Calculates the normalized Hamming distance between two matrices.
  ///
  /// The Hamming distance is the number of positions at which the corresponding
  /// elements in two matrices are different. This method computes a normalized
  /// similarity score based on the Hamming distance.
  ///
  /// Parameters:
  /// - [inputGrid]: The first Matrix to compare.
  /// - [templateGrid]: The second Matrix to compare against.
  ///
  /// Returns:
  /// A double value between 0 and 1, where:
  /// - 1.0 indicates perfect similarity (no differences)
  /// - 0.0 indicates maximum dissimilarity (all elements are different)
  ///
  /// Note: This method assumes that both matrices have the same dimensions.
  /// If the matrices have different sizes, the behavior is undefined and may
  /// result in errors or incorrect results.
  static double hammingDistancePercentage(
    Matrix inputGrid,
    Matrix templateGrid,
  ) {
    int matchingPixels = 0;
    int totalPixels = 0;

    for (int y = 0; y < inputGrid.rows; y++) {
      for (int x = 0; x < inputGrid.cols; x++) {
        if (inputGrid.data[y][x] || templateGrid.data[y][x]) {
          totalPixels++;
          if (inputGrid.data[y][x] == templateGrid.data[y][x]) {
            matchingPixels++;
          }
        }
      }
    }

    if (totalPixels == 0) {
      return 0.0;
    } // If no true pixels, consider it a perfect match

    return matchingPixels / totalPixels;
  }

  /// Determines if the current Matrix is considered a line based on its aspect ratio.
  ///
  /// This method calculates the aspect ratio of the Matrix's content and checks if it falls
  /// within a specific range to determine if it should be considered a line.
  ///
  /// Returns:
  ///   * true if the aspect ratio is less than 0.25 or greater than 50,
  ///     indicating that the Matrix is likely representing a line.
  ///   * false otherwise, suggesting the Matrix is not representing a line.
  ///
  /// The aspect ratio is calculated by the aspectRatioOfContent() method, which is
  /// assumed to return width divided by height of the Matrix's content. Therefore:
  ///   * A very small aspect ratio (< 0.25) indicates a tall, narrow Matrix.
  ///   * A very large aspect ratio (> 50) indicates a wide, short Matrix.
  /// Both of these cases are considered to be line-like in this context.
  ///
  /// This method is useful in image processing or OCR tasks where distinguishing
  /// between line-like structures and other shapes is important.
  bool isConsideredLine() {
    var ar = aspectRatioOfContent();
    if (ar < 0.25 || ar > 50) {
      return true;
    }
    return false;
  }

  bool get isEmpty => data.isEmpty;

  bool get isNotEmpty => data.isEmpty == false;

  /// smaller (~30%) in height artifacts will be considered punctuation
  bool isPunctuation() {
    // Calculate the height of the content
    final Size size = getContentSize();

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

  /// Custom comparison method for matrices
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
      'font': font,
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

  int countEnclosedRegion(Matrix grid) {
    int rows = grid.rows;
    int cols = grid.cols;

    Matrix visited = Matrix(cols, rows);

    int loopCount = 0;
    int minRegionSize = 3; // Minimum size for a region to be considered a loop

    for (int y = 0; y < rows; y++) {
      for (int x = 0; x < cols; x++) {
        if (!grid.data[y][x] && !visited.data[y][x]) {
          int regionSize = exploreRegion(grid, visited, x, y);
          if (regionSize >= minRegionSize &&
              isEnclosedRegion(grid, x, y, regionSize)) {
            loopCount++;
          }
        }
      }
    }

    return loopCount;
  }

  int exploreRegion(
    Matrix grid,
    Matrix visited,
    int startX,
    int startY,
  ) {
    int rows = grid.rows;
    int cols = grid.cols;
    Queue<List<int>> queue = Queue();
    queue.add([startX, startY]);
    visited.data[startY][startX] = true;
    int regionSize = 0;

    while (queue.isNotEmpty) {
      List<int> current = queue.removeFirst();
      int x = current[0], y = current[1];
      regionSize++;

      for (var dir in [
        [-1, 0],
        [1, 0],
        [0, -1],
        [0, 1],
      ]) {
        int newX = x + dir[0], newY = y + dir[1];

        if (newX >= 0 &&
            newX < cols &&
            newY >= 0 &&
            newY < rows &&
            !grid.data[newY][newX] &&
            !visited.data[newY][newX]) {
          queue.add([newX, newY]);
          visited.data[newY][newX] = true;
        }
      }
    }

    return regionSize;
  }

  bool isEnclosedRegion(
    Matrix grid,
    int startX,
    int startY,
    int regionSize,
  ) {
    int rows = grid.rows;
    int cols = grid.cols;
    Queue<List<int>> queue = Queue();
    Set<String> visited = {};
    queue.add([startX, startY]);
    visited.add('$startX,$startY');
    bool isEnclosed = true;

    while (queue.isNotEmpty) {
      List<int> current = queue.removeFirst();
      int x = current[0], y = current[1];

      for (var dir in [
        [-1, 0],
        [1, 0],
        [0, -1],
        [0, 1],
      ]) {
        int newX = x + dir[0], newY = y + dir[1];

        if (newX < 0 || newX >= cols || newY < 0 || newY >= rows) {
          isEnclosed = false;
          continue;
        }

        String key = '$newX,$newY';
        if (!grid.data[newY][newX] && !visited.contains(key)) {
          queue.add([newX, newY]);
          visited.add(key);
        }
      }
    }

    // Check if the region is too small compared to the grid size
    int gridArea = rows * cols;
    double regionPercentage = regionSize / gridArea;
    if (regionPercentage < 0.01) {
      // Adjust this threshold as needed
      isEnclosed = false;
    }

    return isEnclosed;
  }

  double thresholdLinePercentage = 0.7;

  bool hasVerticalLineLeft(Matrix matrix) {
    Matrix visited = Matrix(matrix.cols, matrix.rows);

    // We only consider lines that are more than 40% of the character's height
    int minVerticalLine = (matrix.rows * thresholdLinePercentage).toInt();

    for (int x = 0; x < matrix.cols; x++) {
      for (int y = 0; y < matrix.rows; y++) {
        if (matrix.data[y][x] && !visited.data[y][x]) {
          if (isValidVerticalLineLeft(
            minVerticalLine,
            matrix,
            x,
            y,
            visited,
          )) {
            return true;
          }
        }
      }
    }

    return false;
  }

  bool hasVerticalLineRight(Matrix matrix) {
    Matrix visited = Matrix(matrix.cols, matrix.rows);

    // We only consider lines that are more than 40% of the character's height
    int minVerticalLine = (matrix.rows * thresholdLinePercentage).toInt();

    for (int x = matrix.cols - 1; x >= 0; x--) {
      for (int y = 0; y < matrix.rows; y++) {
        if (matrix.data[y][x] && !visited.data[y][x]) {
          if (isValidVerticalLineRight(
            minVerticalLine,
            matrix,
            x,
            y,
            visited,
          )) {
            return true;
          }
        }
      }
    }

    return false;
  }

  /// Checks if the segment starting at (x, y) is a valid vertical line.
  /// Only considers it a vertical line if there are no filled pixels to the left
  /// at any point in the line.
  bool isValidVerticalLineLeft(
    int minVerticalLine,
    Matrix matrix,
    int x,
    int y,
    Matrix visited,
  ) {
    int rows = matrix.rows;
    int lineLength = 0;

    // Ensure no filled pixels on the immediate left side at any point
    while (y < rows && matrix.data[y][x]) {
      visited.data[y][x] = true;
      lineLength++;

      // If there's a filled pixel to the left of any point in the line, it's invalid
      if (!validLeftSideLeft(matrix, x, y)) {
        lineLength = 0; // reset
      }
      if (lineLength >= minVerticalLine) {
        return true;
      }
      y++;
    }

    // Only count if the line length is sufficient
    return false;
  }

  bool isValidVerticalLineRight(
    int minVerticalLine,
    Matrix matrix,
    int x,
    int y,
    Matrix visited,
  ) {
    int rows = matrix.rows;
    int lineLength = 0;

    // Ensure no filled pixels on the immediate left side at any point
    while (y < rows && matrix.data[y][x]) {
      visited.data[y][x] = true;
      lineLength++;

      // If there's a filled pixel to the left of any point in the line, it's invalid
      if (!validLeftSideRight(matrix, x, y)) {
        lineLength = 0; // reset
      }
      if (lineLength >= minVerticalLine) {
        return true;
      }
      y++;
    }

    // Only count if the line length is sufficient
    return false;
  }

// accept some tolerance
  bool validLeftSideLeft(
    Matrix m,
    int x,
    int y,
  ) {
    if (x - 1 < 0) {
      return true;
    }

    if (m.cellGet(x - 1, y) == false) {
      return true;
    }
    // if (m.cellGet(x - 2, y) == false) {
    //   return true;
    // }
    // if (m.cellGet(x - 3, y) == false) {
    //   return true;
    // }
    return false;
  }

// accept some tolerance
  bool validLeftSideRight(
    Matrix m,
    int x,
    int y,
  ) {
    if (x + 1 >= m.cols) {
      return true;
    }

    if (m.cellGet(x + 1, y) == false) {
      return true;
    }
    // if (m.cellGet(x - 2, y) == false) {
    //   return true;
    // }
    // if (m.cellGet(x - 3, y) == false) {
    //   return true;
    // }
    return false;
  }
}
