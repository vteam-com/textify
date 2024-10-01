import 'dart:convert';

import 'package:textify/matrix.dart';

class CharacterDefinition {
  CharacterDefinition({
    required this.character,
    this.enclosers = 0,
    this.isAmount = false,
    this.isDate = false,
    this.isDigit = false,
    this.isLetter = false,
    this.isPunctuation = false,
    this.lineLeft = false,
    this.lineRight = false,
    this.matrices = const [],
  });

  // Add this factory method for JSON deserialization
  factory CharacterDefinition.fromJson(Map<String, dynamic> json) {
    final CharacterDefinition definition = CharacterDefinition(
      character: json['character'] as String,
      enclosers: json['enclosers'] as int,
      lineLeft: json['lineLeft'] as bool,
      lineRight: json['lineRight'] as bool,
      isLetter: json['isLetter'] as bool,
      isAmount: json['isAmount'] as bool,
      isDate: json['isDate'] as bool,
      isDigit: json['isDigit'] as bool,
      isPunctuation: json['isPunctuation'] as bool,
      matrices: (json['matrices'] as List)
          .map((m) => Matrix.fromJson(m as Map<String, dynamic>))
          .toList(),
    );

    return definition;
  }

  // Add this factory method to create an object from a JSON string
  factory CharacterDefinition.fromJsonString(String jsonString) {
    return CharacterDefinition.fromJson(
      jsonDecode(jsonString) as Map<String, dynamic>,
    );
  }
  static int templateWidth = 40;
  static int templateHeight = 60;

  final String character;
  final int enclosers;

  bool isAmount;
  bool isDate;
  bool isDigit;
  bool isLetter;
  bool isPunctuation;
  bool lineLeft;
  bool lineRight;
  List<Matrix> matrices;

  // Add this method for JSON serialization
  Map<String, dynamic> toJson() {
    return {
      'character': character,
      'enclosers': enclosers,
      'isAmount': isAmount,
      'isDate': isDate,
      'isDigit': isDigit,
      'isLetter': isLetter,
      'isPunctuation': isPunctuation,
      'lineLeft': lineLeft,
      'lineRight': lineRight,
      'matrices': matrices.map((m) => m.toJson()).toList(),
    };
  }

  // Add this method to convert the object to a JSON string
  String toJsonString() => jsonEncode(toJson());
}

const List<String> allDigits = [
  '0',
  '1',
  '2',
  '3',
  '4',
  '5',
  '6',
  '7',
  '8',
  '9',
];

const List<String> charactersForAmount = [
  ...allDigits,
  '-',
  '(',
  ')',
  '.',
  ',',
];

const List<String> charactersForDate = [
  ...allDigits,
  '-',
  '.',
  '/',
];
