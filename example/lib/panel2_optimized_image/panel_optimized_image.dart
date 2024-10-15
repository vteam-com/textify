import 'dart:ui' as ui;

import 'package:flutter/cupertino.dart';
import 'package:textify_dashboard/widgets/image_viewer.dart';

Widget buildOptimizedImage(
  final ui.Image? imageHighContrast,
  final TransformationController? transformationController,
) {
  return imageHighContrast == null
      ? const CupertinoActivityIndicator(radius: 30)
      : buildInteractiveImageViewer(
          imageHighContrast,
          transformationController,
        );
}
