import 'dart:async';
import 'dart:ui';
import 'dart:ui' as ui;

import 'package:flutter/services.dart';

/// A utility class for debouncing function calls.
///
/// This class helps in limiting the rate at which a function is called,
/// particularly useful for operations that don't need to happen too frequently,
/// such as API calls or expensive computations triggered by user input.
class Debouncer {
  /// Creates a new [Debouncer] instance.
  ///
  /// [duration] specifies the time to wait before executing the debounced function.
  /// If not provided, it defaults to 1 second.
  Debouncer([this.duration = const Duration(seconds: 1)]);

  /// The duration to wait before executing the debounced function.
  final Duration duration;

  /// Internal timer used to manage the debounce delay.
  Timer? _timer;

  /// Runs the provided callback after the specified duration.
  ///
  /// If [run] is called again before the duration has elapsed, the previous
  /// call is cancelled and the timer is reset.
  ///
  /// [callback] is the function to be executed after the debounce duration.
  void run(VoidCallback callback) {
    _timer?.cancel();
    _timer = Timer(duration, callback);
  }
}

/// Converts a [Uint8List] of image bytes to a [ui.Image] object.
///
/// This function is useful when you have image data as bytes (e.g., from a network request
/// or file read) and need to convert it to a Flutter Image object for rendering or processing.
///
/// [list] is the [Uint8List] containing the image data in a supported format (e.g., PNG, JPEG).
///
/// Returns a [Future<ui.Image>] that completes with the decoded image.
///
/// Throws an exception if the image data cannot be decoded.
Future<ui.Image> fromBytesToImage(Uint8List list) async {
  // Decode the image
  final Codec codec = await ui.instantiateImageCodec(list);
  final FrameInfo frameInfo = await codec.getNextFrame();

  return frameInfo.image;
}
