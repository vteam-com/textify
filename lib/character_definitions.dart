import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:textify/character_definition.dart';
import 'package:textify/matrix.dart';
export 'package:textify/character_definition.dart';

class CharacterDefinitions {
  List<CharacterDefinition> _definitions = [];

  int get count => _definitions.length;

  // Add a new template
  void addDefinition(CharacterDefinition definition) {
    _definitions.add(definition);
  }

  // Get all templates
  List<CharacterDefinition> get definitions {
    return List.unmodifiable(_definitions);
  }

  void fromJSonString(String jsonString) {
    final dynamic jsonObject = jsonDecode(jsonString);
    final List<dynamic> jsonList = jsonObject['templates'];
    _definitions =
        jsonList.map((json) => CharacterDefinition.fromJson(json)).toList();
  }

  // Get a specific template
  CharacterDefinition? getDefinition(final String character) {
    try {
      return _definitions.firstWhere((t) => t.character == character);
    } catch (e) {
      return null;
    }
  }

  List<String> getSupportedCharacters() {
    final List<String> list =
        _definitions.map((entry) => entry.character).toList();
    list.sort();
    return list;
  }

  List<String> getTemplateAsString(final String character) {
    if (character == ' ') {
      return List.generate(
        60,
        (_) => '........................................',
      );
    }

    return getDefinition(character)!.matrices.first.gridToStrings();
  }

  Future<CharacterDefinitions> loadDefinitions([
    final String pathToAssetsDefinition =
        'packages/textify/assets/matrices.json',
  ]) async {
    // Load the JSON file from the assets
    String jsonString = await rootBundle.loadString(pathToAssetsDefinition);
    fromJSonString(jsonString);
    return this;
  }

  void sortDefinitions() {
    _definitions.sort((a, b) => a.character.compareTo(b.character));
  }

  String toJsonString() {
    sortDefinitions();

    // Convert the matrices data to a Map
    Map<String, dynamic> matricesMap = {
      'templates': definitions.map((template) => template.toJson()).toList(),
      // Add other properties of Matrices class if any
    };

    // Convert the Map to a JSON string
    return jsonEncode(matricesMap);
  }

  // Update an existing template
  void updateDefinition(CharacterDefinition template) {
    final index =
        _definitions.indexWhere((t) => t.character == template.character);
    if (index != -1) {
      _definitions[index] = template;
    } else {
      throw ArgumentError(
        'Template not found for character: ${template.character}',
      );
    }
  }

  /// Updates or inserts a template matrix for a given character and font.
  ///
  /// This method either adds a new [CharacterDefinition] or updates an existing one.
  /// If a matrix for the given character and font already exists, it is replaced.
  /// Otherwise, a new matrix is added to the existing character definition or
  /// a new character definition is created.
  ///
  /// Parameters:
  /// - [font]: The font name for the matrix.
  /// - [character]: The character this matrix represents.
  /// - [matrix]: The [Matrix] object containing the character's pixel data.
  ///
  /// The method performs the following steps:
  /// 1. Checks if a [CharacterDefinition] exists for the given character.
  /// 2. If no definition exists, creates a new one with the given matrix.
  /// 3. If a definition exists, checks for an existing matrix with the same font.
  /// 4. Replaces the existing matrix if found, or adds a new one if not found.
  void upsertTemplate(
    final String font,
    final String character,
    Matrix matrix,
  ) {
    matrix.font = font;
    final CharacterDefinition? found = getDefinition(character);
    if (found == null) {
      // Create a new CharacterDefinition and add it to the collection
      final CharacterDefinition newDefinition = CharacterDefinition(
        character: character,
        matrices: [matrix],
      );
      _definitions.add(newDefinition);
    } else {
      // Check if a matrix with the same font already exists
      final existingMatrixIndex =
          found.matrices.indexWhere((m) => m.font == font);

      if (existingMatrixIndex == -1) {
        // Add the new matrix if no matrix with the same font exists
        found.matrices.add(matrix);
      } else {
        // Replace the existing matrix if it has the same font
        found.matrices[existingMatrixIndex] = matrix;
      }
    }
  }
}
