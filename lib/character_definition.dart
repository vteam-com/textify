import 'dart:convert';

import 'package:textify/matrix.dart';

/// Represents the definition and properties of a single character.
class CharacterDefinition {
  /// Creates a new [CharacterDefinition] instance.
  ///
  /// [character] is required. All other parameters are optional and have default values.
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

  /// Creates a [CharacterDefinition] from a JSON map.
  factory CharacterDefinition.fromJson(Map<String, dynamic> json) {
    return CharacterDefinition(
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
  }

  /// Creates a [CharacterDefinition] from a JSON string.
  factory CharacterDefinition.fromJsonString(String jsonString) {
    return CharacterDefinition.fromJson(
      jsonDecode(jsonString) as Map<String, dynamic>,
    );
  }

  /// The height of the character template.
  static int templateHeight = 60;

  /// The width of the character template.
  static int templateWidth = 40;

  /// The character being defined.
  final String character;

  /// The number of enclosers for this character.
  final int enclosers;

  /// Indicates if this character is used in amounts.
  bool isAmount;

  /// Indicates if this character is used in dates.
  bool isDate;

  /// Indicates if this character is a digit.
  bool isDigit;

  /// Indicates if this character is a letter.
  bool isLetter;

  /// Indicates if this character is a punctuation mark.
  bool isPunctuation;

  /// Indicates if the character has a left vertical line as part of its shape.
  bool lineLeft;

  /// Indicates if the character has a right vertical line as part of its shape.
  bool lineRight;

  /// List of matrices representing this character.
  List<Matrix> matrices;

  /// Converts this [CharacterDefinition] to a JSON map.
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

  /// Converts this [CharacterDefinition] to a JSON string.
  String toJsonString() => jsonEncode(toJson());
}

/// List of all digit characters.
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

/// List of characters typically used in representing amounts.
const List<String> charactersForAmount = [
  ...allDigits,
  '-',
  '(',
  ')',
  '.',
  ',',
];

/// List of characters typically used in date formats.
const List<String> charactersForDate = [
  ...allDigits,
  '-',
  '.',
  '/',
];
