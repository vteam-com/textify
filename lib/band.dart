import 'package:flutter/widgets.dart';
import 'package:textify/artifact.dart';

class Band {
  Band(this.rectangle);

  List<Artifact> artifacts = [];
  Rect rectangle;

  double _averageGap = -1;
  double _averageWidth = -1;

  double get averageGap {
    if ((_averageGap == -1 || _averageWidth == -1)) {
      calculateAverages();
    }
    return _averageGap;
  }

  double get averageWidth {
    if ((_averageGap == -1 || _averageWidth == -1)) {
      calculateAverages();
    }
    return _averageWidth;
  }

  /// Calculates the average gap between adjacent artifacts in a list.
  ///
  /// This method computes the mean horizontal distance between the right edge of
  /// one artifact and the left edge of the next artifact in the list. The artifacts
  /// are assumed to be sorted from left to right.
  ///
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

  void sortLeftToRight() {
    artifacts.sort((a, b) => a.rectangle.left.compareTo(b.rectangle.left));
  }

  int get spaces => artifacts.fold(
        0,
        (count, a) => a.characterMatched == ' ' ? count + 1 : count,
      );
}
