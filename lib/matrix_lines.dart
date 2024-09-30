import 'package:textify/matrix.dart';

const double percentageNeeded = 0.7;

bool hasVerticalLineLeft(Matrix matrix) {
  Matrix visited = Matrix(matrix.cols, matrix.rows);

  // We only consider lines that are more than 40% of the character's height
  int minVerticalLine = (matrix.rows * percentageNeeded).toInt();

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
  int minVerticalLine = (matrix.rows * percentageNeeded).toInt();

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
