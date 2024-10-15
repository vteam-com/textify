import 'dart:async';
import 'dart:collection';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui';
import 'dart:ui' as ui;

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
  Matrix([
    final num width = 0,
    final num height = 0,
    final bool value = false,
  ]) {
    _data = List.generate(
      height.toInt(),
      (_) => List.filled(width.toInt(), false),
    );
    cols = width.toInt();
    rows = height.toInt();
  }

  /// Creates a new [Matrix] instance from an existing [Matrix].
  ///
  /// This factory method creates a new [Matrix] instance based on the provided [value] matrix.
  /// It copies the grid data and the rectangle properties from the input matrix.
  ///
  /// Parameters:
  /// - [value]: The source [Matrix] instance to copy from.
  ///
  /// Returns:
  /// A new [Matrix] instance with the same grid data and rectangle as the input matrix.
  ///
  /// Note: This method creates a shallow copy of the grid data. If deep copying of the data
  /// is required, consider implementing a separate deep copy method.
  ///
  /// Example:
  /// ```dart
  /// Matrix original = Matrix(/* ... */);
  /// Matrix copy = Matrix.fromMatrix(original);
  /// ```
  factory Matrix.fromMatrix(Matrix value) {
    final matrix = Matrix();
    matrix.setGrid(value.data);
    matrix.rectangle = value.rectangle;
    return matrix;
  }

  /// Creates a Matrix from an ASCII representation.
  ///
  /// [template] A list of strings where '#' represents true and any other character represents false.
  factory Matrix.fromAsciiDefinition(final List<String> template) {
    final Matrix matrix = Matrix();
    matrix.rows = template.length;
    matrix.cols = template[0].length;
    matrix._data = List.generate(
      matrix.rows,
      (y) => List.generate(matrix.cols, (x) => template[y][x] == '#'),
    );
    return matrix;
  }

  /// Creates a Matrix from an existing 2D boolean list.
  ///
  /// [input] A 2D list of boolean values.
  factory Matrix.fromBoolMatrix(final List<List<bool>> input) {
    final Matrix matrix = Matrix();
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
    final Matrix matrix = Matrix();
    matrix.rows = inputList.length ~/ width;
    matrix.cols = width;

    for (int y = 0; y < matrix.rows; y++) {
      matrix._data
          .add(inputList.sublist(y * matrix.cols, (y + 1) * matrix.cols));
    }
    return matrix;
  }

  /// Creates a Matrix from JSON data.
  ///
  /// [json] A map containing 'rows', 'cols', and 'data' keys.
  factory Matrix.fromJson(final Map<String, dynamic> json) {
    final Matrix matrix = Matrix();
    matrix.font = json['font'];
    matrix.rows = json['rows'];
    matrix.cols = json['cols'];
    matrix._data = (json['data'] as List<dynamic>).map((row) {
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
    final int width,
  ) {
    return Matrix.fromFlatListOfBool(
      [
        for (int i = 0; i < pixels.length; i += 4) pixels[i] == 0,
      ],
      width,
    );
  }

  /// Creates a [Matrix] from a [ui.Image].
  ///
  /// This factory constructor takes a [ui.Image] object and transforms it into a [Matrix]
  /// representation. The process involves two main steps:
  /// 1. Converting the image to a Uint8List using [imageToUint8List].
  /// 2. Creating a Matrix from the Uint8List using [Matrix.fromUint8List].
  ///
  /// [image] The ui.Image object to be converted. This should be a valid,
  /// non-null image object.
  ///
  /// Returns a [Future<Matrix>] representing the image data. The returned Matrix
  /// will have the same width as the input image, and its height will be
  /// determined by the length of the Uint8List and the width.
  ///
  /// Throws an exception if [imageToUint8List] fails to convert the image or if
  /// [Matrix.fromUint8List] encounters an error during matrix creation.
  ///
  /// Note: This constructor is asynchronous due to the [imageToUint8List] operation.
  /// Ensure to await its result when calling.
  static Future<Matrix> fromImage(final ui.Image image) async {
    final Uint8List uint8List = await imageToUint8List(image);
    return Matrix.fromUint8List(uint8List, image.width);
  }

  /// Font this matrix template is based on
  String font = '';

  /// The number of columns in the matrix.
  int cols = 0;

  /// The 2D list representing the boolean grid.
  List<List<bool>> _data = [];

  /// Getter for data
  List<List<bool>> get data => _data;

  /// The number of rows in the matrix.
  int rows = 0;

  /// the rectangle location of this matrix.
  Rect rectangle = Rect.zero;

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
    final Size size = _getContentSize();
    return size.height / size.width; // Aspect ratio
  }

  /// Retrieves the value of a cell at the specified coordinates.
  ///
  /// Returns false if the coordinates are out of bounds.
  bool cellGet(final int x, final int y) {
    if (_isValidXY(x, y)) {
      return _data[y][x];
    }
    return false;
  }

  /// Sets the value of a cell at the specified coordinates.
  ///
  /// Does nothing if the coordinates are out of bounds.
  void cellSet(final int x, final int y, bool value) {
    if (_isValidXY(x, y)) {
      _data[y][x] = value;
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
          target._data[y + offsetY][x + offsetX] |= source._data[y][x];
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
    while (topRow < rows && !_data[topRow].contains(true)) {
      topRow++;
    }

    // Find bottom row with content
    while (bottomRow > topRow && !_data[bottomRow].contains(true)) {
      bottomRow--;
    }

    // Find left column with content
    outer:
    while (leftCol < cols) {
      for (int i = topRow; i <= bottomRow; i++) {
        if (_data[i][leftCol]) {
          break outer;
        }
      }
      leftCol++;
    }

    // Find right column with content
    outer:
    while (rightCol > leftCol) {
      for (int i = topRow; i <= bottomRow; i++) {
        if (_data[i][rightCol]) {
          break outer;
        }
      }
      rightCol--;
    }

    // Crop the grid
    return Matrix.fromBoolMatrix(
      List.generate(
        bottomRow - topRow + 1,
        (i) => _data[i + topRow].sublist(leftCol, rightCol + 1),
      ),
    );
  }

  /// Creates a normalized Matrix with the specified dimensions.
  ///
  /// This method handles resizing and special cases like punctuation.
  Matrix createNormalizeMatrix(
    final int desiredWidth,
    final int desiredHeight,
  ) {
    // help resizing by ensuring there's a border
    if (isPunctuation()) {
      // do not crop and center
      return _createWrapGridWithFalse()._createResizedGrid(
        desiredWidth,
        desiredHeight,
      );
    } else {
      // Resize
      return trim()._createWrapGridWithFalse()._createResizedGrid(
            desiredWidth,
            desiredHeight,
          );
    }
  }

  /// Returns:
  /// A string representation ths Matrix.
  @override
  String toString() {
    final Size size = _getContentSize();
    return 'W:$cols H:$rows CW:${size.width} CH:${size.height} isEmpty:$isEmpty E:$enclosures LL:$verticalLineLeft LR:$verticalLineRight';
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
  Matrix _createResizedGrid(final int targetWidth, final int targetHeight) {
    // Initialize the resized grid
    final Matrix resizedGrid = Matrix(targetWidth, targetHeight);

    // Calculate the scale factors
    final double xScale = cols / targetWidth;
    final double yScale = rows / targetHeight;

    for (int y = 0; y < targetHeight; y++) {
      for (int x = 0; x < targetWidth; x++) {
        // Coordinates in the original grid
        final double srcX = x * xScale;
        final double srcY = y * yScale;

        if (targetWidth > cols || targetHeight > rows) {
          // UpScaling: Use nearest-neighbor interpolation
          final int srcXInt = srcX.floor();
          final int srcYInt = srcY.floor();
          resizedGrid._data[y][x] = _data[srcYInt][srcXInt];
        } else {
          // DownScaling: Check for any black pixel in the sub-grid
          final int startX = srcX.floor();
          final int endX = (srcX + xScale).ceil();
          final int startY = srcY.floor();
          final int endY = (srcY + yScale).ceil();

          bool hasBlackPixel = false;

          for (int sy = startY; sy < endY && sy < rows; sy++) {
            for (int sx = startX; sx < endX && sx < cols; sx++) {
              if (_data[sy][sx]) {
                hasBlackPixel = true;
                break;
              }
            }
            if (hasBlackPixel) {
              break;
            }
          }

          // Set the resized grid value based on the presence of any black pixel
          resizedGrid._data[y][x] = hasBlackPixel;
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
  void padTopBottom({
    required final int paddingTop,
    required final int paddingBottom,
  }) {
    final blankLine = List.filled(cols, false);

    for (int add = 0; add < paddingTop; add++) {
      this._data.insert(0, blankLine);
    }

    for (int add = 0; add < paddingBottom; add++) {
      this._data.add(blankLine);
    }
    this.rows = _data.length;
  }

  /// Creates a new Matrix with a false border wrapping around the original matrix.
  ///
  /// This function generates a new Matrix that is larger than the original by adding
  /// a border of 'false' values around all sides. If the original matrix is empty,
  /// it returns a predefined 3x2 matrix of 'false' values.
  ///
  /// The process:
  /// 1. If the original matrix is empty, return a predefined 3x2 matrix of 'false' values.
  /// 2. Create a new matrix with dimensions increased by 2 in both rows and columns,
  ///    initialized with 'false' values.
  /// 3. Copy the original matrix data into the center of the new matrix, leaving
  ///    the outer border as 'false'.
  ///
  /// Returns:
  /// - If the original matrix is empty: A new 3x2 Matrix filled with 'false' values.
  /// - Otherwise: A new Matrix with dimensions (rows + 2) x (cols + 2), where the
  ///   original matrix data is centered and surrounded by a border of 'false' values.
  ///
  /// This function is useful for operations that require considering the edges of a matrix,
  /// such as cellular automata or image processing algorithms.
  Matrix _createWrapGridWithFalse() {
    if (isEmpty) {
      return Matrix.fromBoolMatrix([
        [false, false],
        [false, false],
        [false, false],
      ]);
    }

    // Create a new grid with increased dimensions
    final Matrix newGrid = Matrix.fromBoolMatrix(
      List.generate(
        rows + 2,
        (r) => List.generate(cols + 2, (c) => false),
      ),
    );

    // Copy the original grid into the center of the new grid
    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        newGrid._data[r + 1][c + 1] = _data[r][c];
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
      _enclosures = _countEnclosedRegion(this);
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
  /// - [rect]: A Rect object specifying the region to extract. The rectangle's
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
    final int startX = rect.left.toInt();
    final int startY = rect.top.toInt();
    final int subImageWidth = rect.width.toInt();
    final int subImageHeight = rect.height.toInt();

    final Matrix subImagePixels = Matrix(subImageWidth, subImageHeight, false);

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
  Size _getContentSize() {
    return getContentRect().size;
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
    int minX = cols;
    int maxX = -1;
    int minY = rows;
    int maxY = -1;

    for (int y = 0; y < rows; y++) {
      for (int x = 0; x < cols; x++) {
        if (_data[y][x]) {
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
    } else {
      return Rect.fromLTRB(
        minX.toDouble(),
        minY.toDouble(),
        (maxX + 1).toDouble(),
        (maxY + 1).toDouble(),
      );
    }
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
  static List<String> getStringListOfOverlappedGrids(
    final Matrix grid1,
    final Matrix grid2,
  ) {
    final int height = grid1.rows;
    final int width = grid1.cols;

    if (height != grid2.rows || width != grid2.cols) {
      throw Exception('Grids must have the same dimensions');
    }

    final List<String> overlappedGrid = [];

    for (int row = 0; row < height; row++) {
      String overlappedRow = '';

      for (int col = 0; col < width; col++) {
        final bool cell1 = grid1._data[row][col];
        final bool cell2 = grid2._data[row][col];

        if (cell1 && cell2) {
          overlappedRow += '=';
        } else if (cell1) {
          overlappedRow += '*';
        } else if (cell2) {
          overlappedRow += '#';
        } else {
          overlappedRow += '.';
        }
      }

      overlappedGrid.add(overlappedRow);
    }

    return overlappedGrid;
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
  /// is formatted as a multi-line Dart string literal. Otherwise, it's a
  /// simple string with newline characters separating rows.
  ///
  /// Example:
  /// ```dart
  /// final matrix = Matrix(/* ... */);
  ///
  /// // For display (forCode = false):
  /// print(matrix.gridToString());
  /// // Output:
  /// // #.#
  /// // .#.
  /// // #.#
  ///
  /// // For code (forCode = true):
  /// print(matrix.gridToString(forCode: true));
  /// // Output:
  /// // "#.#",
  /// // ".#.",
  /// // "#.#"
  /// ```
  ///
  /// Note: This method uses [gridToStrings] internally to generate the list
  /// of strings representing each row of the matrix.
  String gridToString({
    final bool forCode = false,
    final String onChar = '#',
    final String offChar = '.',
  }) {
    final List<String> list = gridToStrings(onChar: onChar, offChar: offChar);
    return forCode ? '"${list.join('",\n"')}"' : list.join('\n');
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
  /// ```dart
  /// // ["#.#", ".#.", "#.#"]
  /// ```
  List<String> gridToStrings({
    final String onChar = '#',
    final String offChar = '.',
  }) {
    final List<String> result = [];

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
    final Matrix inputGrid,
    final Matrix templateGrid,
  ) {
    int matchingPixels = 0;
    int totalPixels = 0;

    for (int y = 0; y < inputGrid.rows; y++) {
      for (int x = 0; x < inputGrid.cols; x++) {
        if (inputGrid._data[y][x] || templateGrid._data[y][x]) {
          totalPixels++;
          if (inputGrid._data[y][x] == templateGrid._data[y][x]) {
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
    final double ar = aspectRatioOfContent();
    if (ar < 0.09 || ar > 50) {
      return true;
    }
    return false;
  }

  /// The grid contains one or more True values
  bool get isEmpty => _getContentSize().isEmpty;

  /// All entries in the grid are false
  bool get isNotEmpty => !isEmpty;

  /// smaller (~30%) in height artifacts will be considered punctuation
  bool isPunctuation() {
    // Calculate the height of the content
    final Size size = _getContentSize();

    // If there's no content, it's not punctuation
    if (size == Size.zero) {
      return false;
    }

    // Check if the content height is less than 40% of the total height
    return size.height < (rows * 0.40);
  }

  /// Ensure that x & y are in the boundary of the grid
  bool _isValidXY(final int x, final int y) {
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
        if (a._data[y][x] != b._data[y][x]) {
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
  void setGrid(final List<List<bool>> grid) {
    if (grid.isEmpty || grid[0].isEmpty) {
      rows = 0;
      cols = 0;
      _data = [];
      return;
    }
    // Ensure all rows have the same length
    assert(
      _data.every((row) => row.length == cols),
      'All rows in the grid must have the same length',
    );

    rows = grid.length;
    cols = grid[0].length;

    // Create a deep copy of the grid
    // _data = grid;
    _data = List.generate(
      rows,
      (i) => List<bool>.from(grid[i]),
    );
  }

  /// Converts the Matrix object to a JSON-serializable Map.
  ///
  /// This method creates a Map representation of the Matrix object that can be
  /// easily serialized to JSON. The resulting Map contains the following keys:
  ///
  /// - 'font': The font used in the Matrix (type depends on how 'font' is defined in the class).
  /// - 'rows': The number of rows in the Matrix.
  /// - 'cols': The number of columns in the Matrix.
  /// - 'data': A List of Strings, where each String represents a row in the Matrix.
  ///           In these Strings, '#' represents true (or filled) cells, and '.'
  ///           represents false (or empty) cells.
  ///
  /// The 'data' field is created by transforming the 2D boolean array into a more
  /// compact string representation, where each row is converted to a string of
  /// '#' and '.' characters.
  ///
  /// Returns:
  ///   A Map<String, dynamic> that can be serialized to JSON, representing the
  ///   current state of the Matrix object.
  ///
  /// Example usage:
  ///   Matrix matrix = Matrix(...);
  ///   Map<String, dynamic> jsonMap = matrix.toJson();
  ///   String jsonString = jsonEncode(jsonMap);
  Map<String, dynamic> toJson() {
    return {
      'font': font,
      'rows': rows,
      'cols': cols,
      'data': _data.map((row) {
        return row.map((cell) => cell ? '#' : '.').join();
      }).toList(),
    };
  }

  /// Determines if there's a vertical line on the left side of the matrix.
  ///
  /// This getter lazily evaluates and caches the result of checking for a vertical
  /// line on the left side of the matrix. It uses the [_hasVerticalLineLeft] method
  /// to perform the actual check.
  ///
  /// Returns:
  ///   A boolean value:
  ///   - true if a vertical line is present on the left side
  ///   - false otherwise
  ///
  /// The result is cached after the first call for efficiency in subsequent accesses.
  bool get verticalLineLeft {
    _verticalLineLeft ??= _hasVerticalLineLeft(this);
    return _verticalLineLeft!;
  }

  /// Determines if there's a vertical line on the right side of the matrix.
  ///
  /// This getter lazily evaluates and caches the result of checking for a vertical
  /// line on the right side of the matrix. It uses the [_hasVerticalLineRight] method
  /// to perform the actual check.
  ///
  /// Returns:
  ///   A boolean value:
  ///   - true if a vertical line is present on the right side
  ///   - false otherwise
  ///
  /// The result is cached after the first call for efficiency in subsequent accesses.
  bool get verticalLineRight {
    _verticalLineRight ??= _hasVerticalLineRight(this);
    return _verticalLineRight!;
  }

  /// Counts the number of enclosed regions in a given grid.
  ///
  /// This function analyzes a binary grid represented by [Matrix] to identify and count
  /// enclosed regions that meet specific criteria.
  ///
  /// Parameters:
  /// - [grid]: A [Matrix] object representing the binary grid to analyze.
  ///
  /// Returns:
  /// An integer representing the count of enclosed regions that meet the criteria.
  ///
  /// Algorithm:
  /// 1. Initializes a 'visited' matrix to keep track of explored cells.
  /// 2. Iterates through each cell in the grid.
  /// 3. For each unvisited 'false' cell (representing a potential region):
  ///    a. Explores the connected region using [_exploreRegion].
  ///    b. If the region size is at least [minRegionSize] (3 in this case) and
  ///       it's confirmed as enclosed by [_isEnclosedRegion], increments the loop count.
  ///
  /// Note:
  /// - The function assumes the existence of helper methods [_exploreRegion] and [_isEnclosedRegion].
  /// - A region must have at least 3 cells to be considered a potential loop.
  /// - The function uses a depth-first search approach to explore regions.
  ///
  /// Time Complexity: O(rows * cols), where each cell is visited at most once.
  /// Space Complexity: O(rows * cols) for the 'visited' matrix.
  int _countEnclosedRegion(final Matrix grid) {
    final int rows = grid.rows;
    final int cols = grid.cols;

    final Matrix visited = Matrix(cols, rows);

    int loopCount = 0;
    int minRegionSize = 3; // Minimum size for a region to be considered a loop

    for (int y = 0; y < rows; y++) {
      for (int x = 0; x < cols; x++) {
        if (!grid._data[y][x] && !visited._data[y][x]) {
          int regionSize = _exploreRegion(grid, visited, x, y);
          if (regionSize >= minRegionSize &&
              _isEnclosedRegion(grid, x, y, regionSize)) {
            loopCount++;
          }
        }
      }
    }

    return loopCount;
  }

  /// Explores a connected region in a grid starting from a given point.
  ///
  /// This function uses a breadth-first search algorithm to explore a region
  /// of connected cells in a grid, starting from the specified coordinates.
  ///
  /// Parameters:
  /// - [grid]: A Matrix representing the grid to explore.
  ///   Assumed to contain boolean values where false represents an explorable cell.
  /// - [visited]: A Matrix of the same size as [grid] to keep track of visited cells.
  /// - [startX]: The starting X-coordinate for exploration.
  /// - [startY]: The starting Y-coordinate for exploration.
  ///
  /// Returns:
  /// The size of the explored region (number of connected cells).
  ///
  /// Note: This function modifies the [visited] matrix in-place to mark explored cells.
  int _exploreRegion(
    final Matrix grid,
    final Matrix visited,
    final int startX,
    final int startY,
  ) {
    int rows = grid.rows;
    int cols = grid.cols;
    Queue<List<int>> queue = Queue();
    queue.add([startX, startY]);
    visited._data[startY][startX] = true;
    int regionSize = 0;

    // Directions for exploring adjacent cells (up, down, left, right)
    final directions = [
      [-1, 0],
      [1, 0],
      [0, -1],
      [0, 1],
    ];

    while (queue.isNotEmpty) {
      final List<int> current = queue.removeFirst();
      final int x = current[0], y = current[1];
      regionSize++;

      // Explore all adjacent cells
      for (final List<int> dir in directions) {
        final int newX = x + dir[0], newY = y + dir[1];

        // Check if the new coordinates are within bounds and the cell is explorable
        if (newX >= 0 &&
            newX < cols &&
            newY >= 0 &&
            newY < rows &&
            !grid._data[newY][newX] &&
            !visited._data[newY][newX]) {
          queue.add([newX, newY]);
          visited._data[newY][newX] = true;
        }
      }
    }

    return regionSize;
  }

  /// Determines if a region in a grid is enclosed.
  ///
  /// This function uses a breadth-first search algorithm to explore a region
  /// starting from the given coordinates and checks if it's enclosed within the grid.
  ///
  /// Parameters:
  /// - [grid]: A Matrix representing the grid.
  ///   Assumed to contain boolean values where false represents an explorable cell.
  /// - [startX]: The starting X-coordinate for exploration.
  /// - [startY]: The starting Y-coordinate for exploration.
  /// - [regionSize]: The size of the region being checked.
  ///
  /// Returns:
  /// A boolean value indicating whether the region is enclosed (true) or not (false).
  ///
  /// A region is considered not enclosed if:
  /// 1. It reaches the edge of the grid during exploration.
  /// 2. Its size is less than 1% of the total grid area (adjustable threshold).
  bool _isEnclosedRegion(
    final Matrix grid,
    final int startX,
    final int startY,
    final int regionSize,
  ) {
    final int rows = grid.rows;
    final int cols = grid.cols;
    final Queue<List<int>> queue = Queue();
    final Set<String> visited = {};
    queue.add([startX, startY]);
    visited.add('$startX,$startY');
    bool isEnclosed = true;

    // Directions for exploring adjacent cells (up, down, left, right)
    final List<List<int>> directions = [
      [-1, 0],
      [1, 0],
      [0, -1],
      [0, 1],
    ];

    while (queue.isNotEmpty) {
      final List<int> current = queue.removeFirst();
      final int x = current[0], y = current[1];

      for (final List<int> dir in directions) {
        int newX = x + dir[0], newY = y + dir[1];

        // Check if the new coordinates are outside the grid
        if (newX < 0 || newX >= cols || newY < 0 || newY >= rows) {
          isEnclosed = false;
          continue;
        }

        final String key = '$newX,$newY';
        // If the cell is explorable and not visited, add it to the queue
        if (!grid._data[newY][newX] && !visited.contains(key)) {
          queue.add([newX, newY]);
          visited.add(key);
        }
      }
    }

    // Check if the region is too small compared to the grid size
    final int gridArea = rows * cols;
    final double regionPercentage = regionSize / gridArea;
    if (regionPercentage < 0.01) {
      // Adjust this threshold as needed
      isEnclosed = false;
    }

    return isEnclosed;
  }

  /// The minimum percentage of the character's height required for a vertical line to be considered valid.
  final double _thresholdLinePercentage = 0.7;

  /// Checks if the given matrix contains a vertical line on the left side.
  ///
  /// This function scans the matrix from left to right, looking for vertical lines
  /// that meet a minimum height requirement. It uses a helper function
  /// `_isValidVerticalLineLeft` to validate potential vertical lines.
  ///
  /// Parameters:
  /// - [matrix]: A Matrix representing the data to be analyzed.
  ///   Assumed to contain boolean values where true represents a filled cell.
  ///
  /// Returns:
  /// A boolean value indicating whether a valid vertical line was found on the left side.
  ///
  /// Note:
  /// - The minimum height for a vertical line is determined by `_thresholdLinePercentage`,
  ///   which is a constant value representing the percentage of the character's height.
  /// - The function modifies the [visited] matrix in-place to keep track of visited cells.
  bool _hasVerticalLineLeft(final Matrix matrix) {
    final Matrix visited = Matrix(matrix.cols, matrix.rows);

    // We only consider lines that are more than 40% of the character's height
    final int minVerticalLine =
        (matrix.rows * _thresholdLinePercentage).toInt();

    // Iterate over the matrix from left to right
    for (int x = 0; x < matrix.cols; x++) {
      for (int y = 0; y < matrix.rows; y++) {
        // If the current cell is filled and not visited
        if (matrix._data[y][x] && !visited._data[y][x]) {
          // Check if a valid vertical line exists starting from this cell
          if (_isValidVerticalLineLeft(
            minVerticalLine,
            matrix,
            x,
            y,
            visited,
          )) {
            // If a valid line is found, return true
            return true;
          }
        }
      }
    }

    // If no valid vertical line is found, return false
    return false;
  }

  /// Checks if the given matrix contains a vertical line on the right side.
  ///
  /// This function scans the matrix from right to left, looking for vertical lines
  /// that meet a minimum height requirement. It uses a helper function
  /// `_isValidVerticalLineRight` to validate potential vertical lines.
  ///
  /// Parameters:
  /// - [matrix]: A Matrix representing the data to be analyzed.
  ///   Assumed to contain boolean values where true represents a filled cell.
  ///
  /// Returns:
  /// A boolean value indicating whether a valid vertical line was found on the right side.
  ///
  /// Note:
  /// - The minimum height for a vertical line is determined by `_thresholdLinePercentage`,
  ///   which is assumed to be a class-level constant or variable.
  /// - The function modifies the [visited] matrix in-place to keep track of visited cells.
  bool _hasVerticalLineRight(final Matrix matrix) {
    final Matrix visited = Matrix(matrix.cols, matrix.rows);

    // We only consider lines that are more than 40% of the character's height
    final int minVerticalLine =
        (matrix.rows * _thresholdLinePercentage).toInt();

    // Iterate over the matrix from right to left
    for (int x = matrix.cols - 1; x >= 0; x--) {
      for (int y = 0; y < matrix.rows; y++) {
        // If the current cell is filled and not visited
        if (matrix._data[y][x] && !visited._data[y][x]) {
          // Check if a valid vertical line exists starting from this cell
          if (_isValidVerticalLineRight(
            minVerticalLine,
            matrix,
            x,
            y,
            visited,
          )) {
            // If a valid line is found, return true
            return true;
          }
        }
      }
    }

    // If no valid vertical line is found, return false
    return false;
  }

  /// Checks if the segment starting at (x, y) is a valid vertical line.
  /// Only considers it a vertical line if there are no filled pixels to the left
  /// at any point in the line.
  bool _isValidVerticalLineLeft(
    final int minVerticalLine,
    final Matrix matrix,
    final int x,
    int y,
    final Matrix visited,
  ) {
    final int rows = matrix.rows;
    int lineLength = 0;

    // Ensure no filled pixels on the immediate left side at any point
    while (y < rows && matrix._data[y][x]) {
      visited._data[y][x] = true;
      lineLength++;

      // If there's a filled pixel to the left of any point in the line, it's invalid
      if (!_validLeftSideLeft(matrix, x, y)) {
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

  /// Validates a potential vertical line on the right side of a character.
  ///
  /// This function checks if there's a valid vertical line starting from the given
  /// coordinates (x, y) in the matrix. A valid line must meet the following criteria:
  /// 1. It must be at least [minVerticalLine] pixels long.
  /// 2. It must not have any filled pixels immediately to its left.
  ///
  /// Parameters:
  /// - [minVerticalLine]: The minimum length required for a vertical line to be considered valid.
  /// - [matrix]: The Matrix representing the character or image being analyzed.
  /// - [x]: The x-coordinate of the starting point of the potential line.
  /// - [y]: The y-coordinate of the starting point of the potential line.
  /// - [visited]: A Matrix to keep track of visited pixels.
  ///
  /// Returns:
  /// A boolean value indicating whether a valid vertical line was found (true) or not (false).
  bool _isValidVerticalLineRight(
    final int minVerticalLine,
    final Matrix matrix,
    final int x,
    int y,
    final Matrix visited,
  ) {
    final int rows = matrix.rows;
    int lineLength = 0;

    // Traverse downwards from the starting point
    while (y < rows && matrix._data[y][x]) {
      visited._data[y][x] = true;
      lineLength++;

      // Check if there's a filled pixel to the left of the current point
      if (!_validLeftSideRight(matrix, x, y)) {
        lineLength = 0; // Reset line length if an invalid pixel is found
      }

      // If we've found a line of sufficient length, return true
      if (lineLength >= minVerticalLine) {
        return true;
      }

      y++; // Move to the next row
    }

    // If we've exited the loop, no valid line was found
    return false;
  }

  /// inspection left side with some tolerance
  bool _validLeftSideLeft(
    final Matrix m,
    final int x,
    final int y,
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

  /// inspection right side with some tolerance
  bool _validLeftSideRight(
    final Matrix m,
    final int x,
    final int y,
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

/// Binarize an input image by converting it to black and white based on a brightness threshold.
///
/// This function takes an input [ui.Image] and converts it to a black and white image
/// where pixels brighter than the specified [threshold] become white, and those below become black.
///
/// Parameters:
/// - [inputImage]: The source image to be binarized.
/// - [threshold]: Optional. The brightness threshold used to determine black or white pixels.
///   Defaults to 190. Range is 0-255.
///
/// Returns:
/// A [Future] that resolves to a new [ui.Image] containing the binarized version of the input image.
///
/// Throws:
/// An [Exception] if it fails to get image data from the input image.
Future<ui.Image> imageToBlackOnWhite(
  final ui.Image inputImage, {
  final double threshold = 190,
}) async {
  // Get the bytes from the input image
  final ByteData? byteData =
      await inputImage.toByteData(format: ui.ImageByteFormat.rawRgba);
  if (byteData == null) {
    throw Exception('Failed to get image data');
  }

  final int width = inputImage.width;
  final int height = inputImage.height;
  final Uint8List pixels = byteData.buffer.asUint8List();

  // Create a new Uint8List for the output image
  final Uint8List outputPixels = Uint8List(width * height * 4);

  for (int i = 0; i < pixels.length; i += 4) {
    final int r = pixels[i];
    final int g = pixels[i + 1];
    final int b = pixels[i + 2];
    final int a = pixels[i + 3];

    // Calculate brightness as the average of R, G, and B
    final double brightness = (r + g + b) / 3;

    // If brightness is above the threshold, set pixel to white, otherwise black
    if (brightness > threshold) {
      outputPixels[i] = 255; // R
      outputPixels[i + 1] = 255; // G
      outputPixels[i + 2] = 255; // B
    } else {
      outputPixels[i] = 0; // R
      outputPixels[i + 1] = 0; // G
      outputPixels[i + 2] = 0; // B
    }

    // Keep the alpha channel unchanged
    outputPixels[i + 3] = a;
  }

  // Create a new ui.Image from the modified pixels
  final ui.ImmutableBuffer buffer =
      await ui.ImmutableBuffer.fromUint8List(outputPixels);
  final ui.ImageDescriptor descriptor = ui.ImageDescriptor.raw(
    buffer,
    width: width,
    height: height,
    pixelFormat: ui.PixelFormat.rgba8888,
  );
  final ui.Codec codec = await descriptor.instantiateCodec();
  final ui.FrameInfo frameInfo = await codec.getNextFrame();

  return frameInfo.image;
}

/// Converts a [ui.Image] to a [Uint8List] representation.
///
/// This function takes a [ui.Image] and converts it to a [Uint8List] containing
/// the raw RGBA data of the image.
///
/// Parameters:
/// - [image]: The source image to be converted. Can be null.
///
/// Returns:
/// A [Future] that resolves to a [Uint8List] containing the raw RGBA data of the image.
/// If the input [image] is null or conversion fails, returns an empty [Uint8List].
Future<Uint8List> imageToUint8List(final ui.Image? image) async {
  if (image == null) {
    return Uint8List(0);
  }
  final ByteData? data =
      await image.toByteData(format: ui.ImageByteFormat.rawRgba);
  return data?.buffer.asUint8List() ?? Uint8List(0);
}

/// Performs an erosion operation on the input image.
///
/// This function takes a [ui.Image] and performs an erosion operation on it.
/// The erosion operation removes pixels from the boundaries of objects in the image.
///
/// Parameters:
/// - [inputImage]: The source image to be eroded.
///
/// Returns:
/// A [Future] that resolves to a [ui.Image] containing the eroded image.
/// Performs an erosion operation on the input image.
///
/// This function takes a [ui.Image] and performs a less aggressive erosion operation on it.
/// The erosion operation removes pixels from the boundaries of objects in the image,
/// but only if they have a certain number of white neighbors.
///
/// Parameters:
/// - [inputImage]: The source image to be eroded.
///
/// Returns:
/// A [Future] that resolves to a [ui.Image] containing the eroded image.
/// Performs an erosion operation on the input image.
///
/// This function takes a [ui.Image] and performs a configurable erosion operation on it.
/// The erosion operation removes pixels from the boundaries of objects in the image,
/// based on the number of white neighbors each black pixel has.
///
/// Parameters:
/// - [inputImage]: The source image to be eroded.
/// - [threshold]: The number of white neighbors a black pixel must have to be eroded.
///   Default is 6. Lower values result in more aggressive erosion.
///
/// Returns:
/// A [Future] that resolves to a [ui.Image] containing the eroded image.
Future<ui.Image> erode(
  ui.Image inputImage, {
  int threshold = 6,
}) async {
  final width = inputImage.width;
  final height = inputImage.height;

  // Get the pixel data of the image
  final ByteData? byteData =
      await inputImage.toByteData(format: ui.ImageByteFormat.rawRgba);
  final pixels = byteData!.buffer.asUint8List();

  // Create an empty list for the eroded pixels
  final erodedPixels = Uint8List(width * height * 4);

  // Copy the original image to erodedPixels
  erodedPixels.setAll(0, pixels);

  for (int y = 1; y < height - 1; y++) {
    for (int x = 1; x < width - 1; x++) {
      int index = (y * width + x) * 4;

      // Only process black pixels
      if (_isBlack(pixels, index)) {
        // Count white neighbors
        int whiteNeighbors = 0;
        for (int dy = -1; dy <= 1; dy++) {
          for (int dx = -1; dx <= 1; dx++) {
            if (dx == 0 && dy == 0) {
              continue;
            } // Skip the center pixel
            int neighborIndex = ((y + dy) * width + (x + dx)) * 4;
            if (!_isBlack(pixels, neighborIndex)) {
              whiteNeighbors++;
            }
          }
        }

        // Erode only if the pixel has more white neighbors than the threshold
        if (whiteNeighbors >= threshold) {
          // Set to white
          erodedPixels[index] = 255; // R
          erodedPixels[index + 1] = 255; // G
          erodedPixels[index + 2] = 255; // B
          erodedPixels[index + 3] = 255; // A
        }
      }
    }
  }

  return createImageFromPixels(erodedPixels, width, height);
}

/// Performs a dilation operation on the input image.
///
/// This function takes a [ui.Image] and performs a dilation operation on it.
/// The dilation operation adds pixels to the boundaries of objects in the image.
///
/// Parameters:
/// - [inputImage]: The source image to be dilated.
///
/// Returns:
/// A [Future] that resolves to a [ui.Image] containing the dilated image.
Future<ui.Image> dilate(ui.Image inputImage) async {
  final width = inputImage.width;
  final height = inputImage.height;

  // Get the pixel data of the image
  final byteData =
      await inputImage.toByteData(format: ui.ImageByteFormat.rawRgba);
  final pixels = byteData!.buffer.asUint8List();

  // Create an empty list for the dilated pixels
  final Uint8List dilatedPixels = Uint8List(width * height * 4);

  for (int y = 1; y < height - 1; y++) {
    for (int x = 1; x < width - 1; x++) {
      int index = (y * width + x) * 4;
      // Check if the current pixel or any of its neighbors are black
      if (_isBlack(pixels, index) ||
          _isBlack(pixels, ((y - 1) * width + (x - 1)) * 4) ||
          _isBlack(pixels, ((y - 1) * width + x) * 4) ||
          _isBlack(pixels, ((y - 1) * width + (x + 1)) * 4) ||
          _isBlack(pixels, (y * width + (x - 1)) * 4) ||
          _isBlack(pixels, (y * width + (x + 1)) * 4) ||
          _isBlack(pixels, ((y + 1) * width + (x - 1)) * 4) ||
          _isBlack(pixels, ((y + 1) * width + x) * 4) ||
          _isBlack(pixels, ((y + 1) * width + (x + 1)) * 4)) {
        // Set to black
        dilatedPixels[index] = 0; // R
        dilatedPixels[index + 1] = 0; // G
        dilatedPixels[index + 2] = 0; // B
        dilatedPixels[index + 3] = 255; // A
      } else {
        // Set to white
        dilatedPixels[index] = 255; // R
        dilatedPixels[index + 1] = 255; // G
        dilatedPixels[index + 2] = 255; // B
        dilatedPixels[index + 3] = 255; // A
      }
    }
  }

  return createImageFromPixels(dilatedPixels, width, height);
}

/// Checks if a pixel is black based on its RGBA values.
///
/// This function takes a [Uint8List] representing the pixel data and an [index]
/// pointing to the start of a pixel's RGBA values. It checks if the pixel is
/// black by comparing the R, G, and B values to 0.
///
/// Parameters:
/// - [pixels]: The [Uint8List] containing the pixel data.
/// - [index]: The index pointing to the start of a pixel's RGBA values.
///
/// Returns:
/// A [bool] indicating whether the pixel is black or not.
bool _isBlack(Uint8List pixels, int index) {
  return pixels[index] == 0 && pixels[index + 1] == 0 && pixels[index + 2] == 0;
}

/// Creates a new [ui.Image] from a [Uint8List] of pixel data.
///
/// This function takes a [Uint8List] containing the pixel data, the [width],
/// and the [height] of the image, and creates a new [ui.Image] from it.
///
/// Parameters:
/// - [pixels]: The [Uint8List] containing the pixel data.
/// - [width]: The width of the image.
/// - [height]: The height of the image.
///
/// Returns:
/// A [Future] that resolves to a [ui.Image] created from the pixel data.
Future<ui.Image> createImageFromPixels(
  Uint8List pixels,
  int width,
  int height,
) async {
  // Create a new ui.Image from the modified pixels
  final ui.ImmutableBuffer buffer =
      await ui.ImmutableBuffer.fromUint8List(pixels);

  // Create a new ui.Image from the modified pixels
  final ui.ImageDescriptor descriptor = ui.ImageDescriptor.raw(
    buffer,
    width: width,
    height: height,
    pixelFormat: ui.PixelFormat.rgba8888,
  );
  final ui.Codec codec = await descriptor.instantiateCodec();
  final ui.FrameInfo frameInfo = await codec.getNextFrame();

  return frameInfo.image;
}
