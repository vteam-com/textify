import 'dart:async';
import 'dart:ui';
import 'dart:ui' as ui;

import 'package:flutter/services.dart';

class Debouncer {
  Debouncer([this.duration = const Duration(seconds: 1)]);

  final Duration duration;

  Timer? _timer;

  void run(VoidCallback callback) {
    _timer?.cancel();
    _timer = Timer(duration, callback);
  }
}

Future<ui.Image> fromBytesToImage(Uint8List list) async {
  // Decode the image
  final Codec codec = await ui.instantiateImageCodec(list);
  final FrameInfo frameInfo = await codec.getNextFrame();

  return frameInfo.image;
}
