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

  /// Upsert a template for a given character by adding or updating its matrix.
  ///
  /// This method either adds a new CharacterDefinition if one doesn't exist
  /// for the given character, or updates an existing one by adding a new matrix.
  ///
  /// Parameters:
  /// - [character]: The character for which to upsert the template.
  /// - [matrix]: The Matrix to be added to the character's definition.
  void upsertTemplate(final String character, Matrix matrix) {
    final CharacterDefinition? found = getDefinition(character);
    if (found == null) {
      // Create a new CharacterDefinition and add it to the collection
      final newDefinition = CharacterDefinition(
        character: character,
        matrices: [matrix],
      );
      _definitions.add(newDefinition);
    } else {
      // Add the new matrix to the existing definition if it's not already present
      if (!found.matrices.any(
        (Matrix existingMatrix) => Matrix.matrixEquals(existingMatrix, matrix),
      )) {
        found.matrices.add(matrix);
      }
    }
  }
}
