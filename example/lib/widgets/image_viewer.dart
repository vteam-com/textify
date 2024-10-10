import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';

import '../image_sources/panel_content.dart';

class ImageViewer extends StatelessWidget {
  const ImageViewer({super.key, required this.image});

  final ui.Image image;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: ImagePainter(image),
      size: Size(image.width.toDouble(), image.height.toDouble()),
    );
  }
}

class ImagePainter extends CustomPainter {
  ImagePainter(this.image);

  final ui.Image image;

  @override
  void paint(Canvas canvas, Size size) {
    paintImage(
      canvas: canvas,
      rect: Offset.zero & size,
      image: image,
      fit: BoxFit.contain,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

Widget buildInteractiveImageViewer(
  final ui.Image iamgeToDiplay,
  final TransformationController? transformationController,
) {
  return PanelContent(
    start: const SizedBox(),
    middle: InteractiveViewer(
      transformationController: transformationController,
      constrained: false,
      minScale: 0.1,
      maxScale: 50,
      child: ImageViewer(
        image: iamgeToDiplay,
      ),
    ),
    end: const SizedBox(),
  );
}
