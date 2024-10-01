import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:textify/matrix.dart';

class ImagePipeline {
  ImagePipeline({
    this.imageSource,
    this.imageHighContrast,
    required this.imageBinary,
  });

  factory ImagePipeline.empty() => ImagePipeline(
        imageBinary: Matrix(),
      );

  final Matrix imageBinary;
  final ui.Image? imageHighContrast;
  final ui.Image? imageSource;

  static Future<ImagePipeline> apply(
    final ui.Image? imageSourceInColor,
  ) async {
    if (imageSourceInColor == null) {
      return ImagePipeline.empty();
    }

    // Increase Contrast
    final ui.Image imageHighContrast = await binarizeImage(imageSourceInColor);

    // Binary
    final Matrix imageBinary = Matrix.fromUint8List(
      await imageToUint8List(imageHighContrast),
      imageSourceInColor.width,
    );

    return ImagePipeline(
      imageSource: imageSourceInColor,
      imageHighContrast: imageHighContrast,
      imageBinary: imageBinary,
    );
  }
}

Future<ui.Image> binarizeImage(
  ui.Image inputImage, {
  double threshold = 190,
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

Future<Uint8List> imageToUint8List(final ui.Image? image) async {
  if (image == null) {
    return Uint8List(0);
  }
  final ByteData? data =
      await image.toByteData(format: ui.ImageByteFormat.rawRgba);
  return data?.buffer.asUint8List() ?? Uint8List(0);
}
