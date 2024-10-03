import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:textify/matrix.dart';

/// Represents a pipeline for processing images through various stages.
///
/// This class handles the transformation of a source image into high-contrast
/// and binary representations. It provides access to all stages of the
/// processed image.
class ImagePipeline {
  /// Constructs an [ImagePipeline] with optional source and high-contrast images,
  /// and a required binary image.
  ///
  /// [imageSource] The original source image, if available.
  /// [imageHighContrast] The high-contrast version of the image, if available.
  /// [imageBinary] The binary (black and white) representation of the image as a [Matrix].
  ImagePipeline({
    this.imageSource,
    this.imageHighContrast,
    required this.imageBinary,
  });

  /// Creates an empty [ImagePipeline] with only an empty binary [Matrix].
  ///
  /// This is useful for initializing an [ImagePipeline] when no image data is available.
  ///
  /// Returns an [ImagePipeline] instance with an empty [Matrix] as [imageBinary].
  factory ImagePipeline.empty() => ImagePipeline(
        imageBinary: Matrix(),
      );

  /// The binary representation of the image as a [Matrix].
  final Matrix imageBinary;

  /// The high-contrast version of the image.
  ///
  /// This may be null if high-contrast processing hasn't been performed.
  final ui.Image? imageHighContrast;

  /// The original source image.
  ///
  /// This may be null if no source image was provided.
  final ui.Image? imageSource;

  /// Processes a color image through the pipeline stages.
  ///
  /// This method takes a color image, increases its contrast, and converts it
  /// to a binary representation. It returns a new [ImagePipeline] instance
  /// containing all stages of the processed image.
  ///
  /// [imageSourceInColor] The source color image to process. Can be null.
  ///
  /// Returns a [Future] that completes with a new [ImagePipeline] instance
  /// containing the processed image data. If [imageSourceInColor] is null,
  /// returns an empty [ImagePipeline].
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

/// Binarizes an input image by converting it to black and white based on a brightness threshold.
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
