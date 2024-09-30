// ignore_for_file: unnecessary_this

import 'package:flutter/material.dart';

class ImageGeneratorInput {
  ImageGeneratorInput({
    required this.defaultTextLine1,
    required this.defaultTextLine2,
    required this.defaultTextLine3,
    required this.fontSize,
    required this.imageBackgroundColor,
    required this.imageTextColorAlphabet,
    required this.imageTextColorNumbers,
    required this.selectedFont,
    this.lastUpdated,
  });

  factory ImageGeneratorInput.empty() {
    return ImageGeneratorInput(
      defaultTextLine1: 'ABCDEFGHIJKLM NOPQRSTUVWXYZ',
      defaultTextLine2: 'abcdefghijklm nopqrstuvwxyz',
      defaultTextLine3: '0123456789 /-(),:.',
      fontSize: 40,
      imageBackgroundColor: Colors.yellow.shade100,
      imageTextColorAlphabet: Colors.pink,
      imageTextColorNumbers: Colors.purple,
      selectedFont: 'Arial',
      lastUpdated: DateTime.now(),
    );
  }

  String defaultTextLine1;
  String defaultTextLine2;
  String defaultTextLine3;
  double fontSize;
  Color imageBackgroundColor;
  Color imageTextColorAlphabet;
  Color imageTextColorNumbers;
  String selectedFont;

  DateTime? lastUpdated;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }

    if (other.runtimeType != runtimeType) {
      return false;
    }

    return other is ImageGeneratorInput &&
        defaultTextLine1 == other.defaultTextLine1 &&
        defaultTextLine2 == other.defaultTextLine2 &&
        defaultTextLine3 == other.defaultTextLine3 &&
        fontSize == other.fontSize &&
        imageTextColorAlphabet == other.imageTextColorAlphabet &&
        imageTextColorNumbers == other.imageTextColorNumbers &&
        selectedFont == other.selectedFont &&
        lastUpdated == other.lastUpdated;
  }

  @override
  int get hashCode {
    return defaultTextLine1.hashCode ^
        defaultTextLine2.hashCode ^
        defaultTextLine3.hashCode ^
        fontSize.hashCode ^
        imageBackgroundColor.hashCode ^
        imageTextColorAlphabet.hashCode ^
        imageTextColorNumbers.hashCode ^
        selectedFont.hashCode ^
        lastUpdated.hashCode;
  }

  ImageGeneratorInput clone() {
    return ImageGeneratorInput(
      defaultTextLine1: this.defaultTextLine1,
      defaultTextLine2: this.defaultTextLine2,
      defaultTextLine3: this.defaultTextLine3,
      fontSize: this.fontSize,
      imageBackgroundColor: this.imageBackgroundColor,
      imageTextColorAlphabet: this.imageTextColorAlphabet,
      imageTextColorNumbers: this.imageTextColorNumbers,
      selectedFont: this.selectedFont,
      lastUpdated: this.lastUpdated,
    );
  }
}
