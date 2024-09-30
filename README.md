# Textify

Textify is a Flutter package designed to test the Flutter Package "Textify". It is 100% cross-platform, 100% native Dart and Flutter code that works offline. With no package dependency.

## Features

Extract text out of clean digital images with normal font types, like Arial, Helvetica, TimesRoman and Courier.

## Getting started

```bash
flutter pub install textify
```

## Usage

```dart
import 'pagkage/textity';

var textify = Textify();
textify.init();

textify.getTextFromBinaryImage(image);

print(textity.textFound);
```
