import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:textify/character_definition.dart';
import 'package:textify/matrix.dart';
export 'package:textify/character_definition.dart';

/// Manages a collection of character definitions used for text processing.
///
/// This class provides methods to load, manipulate, and retrieve character
/// definitions, which are used to represent the visual appearance of characters
/// in different fonts or styles.
class CharacterDefinitions {
  /// The list of character definitions.
  List<CharacterDefinition> _definitions = [];

  /// Returns the number of character definitions.
  int get count => _definitions.length;

  /// Adds a new character definition to the collection.
  ///
  /// [definition] The character definition to add.
  void addDefinition(CharacterDefinition definition) {
    _definitions.add(definition);
  }

  /// Returns an unmodifiable list of all character definitions.
  List<CharacterDefinition> get definitions {
    return List.unmodifiable(_definitions);
  }

  /// Parses character definitions from a JSON string.
  ///
  /// [jsonString] A JSON string containing character definitions.
  void fromJsonString(String jsonString) {
    final dynamic jsonObject = jsonDecode(jsonString);
    final List<dynamic> jsonList = jsonObject['templates'];
    _definitions =
        jsonList.map((json) => CharacterDefinition.fromJson(json)).toList();
  }

  /// Retrieves a specific character definition.
  ///
  /// [character] The character to find the definition for.
  ///
  /// Returns the [CharacterDefinition] for the specified character,
  /// or null if not found.
  CharacterDefinition? getDefinition(final String character) {
    try {
      return _definitions.firstWhere((t) => t.character == character);
    } catch (e) {
      return null;
    }
  }

  /// Returns a sorted list of all supported characters.
  List<String> getSupportedCharacters() {
    final List<String> list =
        _definitions.map((entry) => entry.character).toList();
    list.sort();
    return list;
  }

  /// Retrieves the template as a list of strings for a given character.
  ///
  /// [character] The character to get the template for.
  ///
  /// Returns a list of strings representing the character's template.
  /// For space character, returns a predefined template.
  ///
  /// Throws an [ArgumentError] if no template is found for the character.
  List<String> getTemplateAsString(final String character) {
    if (character == ' ') {
      return List.generate(
        60,
        (_) => '........................................',
      );
    }

    final definition = getDefinition(character);
    if (definition == null || definition.matrices.isEmpty) {
      throw ArgumentError('No template found for character: $character');
    }

    return definition.matrices.first.gridToStrings();
  }

  /// Loads character definitions from a JSON file.
  ///
  /// [pathToAssetsDefinition] The path to the JSON file containing definitions.
  ///
  /// Returns a Future<CharacterDefinitions> once loading is complete.
  ///
  /// Throws an exception if loading fails.
  Future<CharacterDefinitions> loadDefinitions([
    final String pathToAssetsDefinition =
        'packages/textify/assets/matrices.json',
  ]) async {
    try {
      String jsonString = await rootBundle.loadString(pathToAssetsDefinition);
      fromJsonString(jsonString);
      return this;
    } catch (e) {
      throw Exception('Failed to load character definitions: $e');
    }
  }

  /// Sorts character definitions alphabetically by character.
  void _sortDefinitions() {
    _definitions.sort((a, b) => a.character.compareTo(b.character));
  }

  /// Converts character definitions to a JSON string.
  ///
  /// Returns a JSON string representation of all character definitions.
  String toJsonString() {
    _sortDefinitions();

    Map<String, dynamic> matricesMap = {
      'templates': definitions.map((template) => template.toJson()).toList(),
    };

    return jsonEncode(matricesMap);
  }

  /// Updates or inserts a template matrix for a given character and font.
  ///
  /// If a definition for the character doesn't exist, a new one is created.
  /// If a matrix for the given font already exists, it is updated; otherwise, it's added.
  ///
  /// [font] The font name for the matrix.
  /// [character] The character this matrix represents.
  /// [matrix] The Matrix object containing the character's pixel data.
  bool upsertTemplate(
    final String font,
    final String character,
    Matrix matrix,
  ) {
    matrix.font = font;
    final CharacterDefinition? found = getDefinition(character);
    if (found == null) {
      final CharacterDefinition newDefinition = CharacterDefinition(
        character: character,
        matrices: [matrix],
      );
      _definitions.add(newDefinition);
      return true;
    } else {
      final existingMatrixIndex =
          found.matrices.indexWhere((m) => m.font == font);

      if (existingMatrixIndex == -1) {
        found.matrices.add(matrix);
      } else {
        found.matrices[existingMatrixIndex] = matrix;
      }
      return false;
    }
  }
}
