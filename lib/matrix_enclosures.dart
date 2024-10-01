import 'dart:collection';

import 'package:textify/matrix.dart';

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
