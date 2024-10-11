import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:textify/character_definition.dart';

import 'package:textify/textify.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final Textify instance = await Textify().init(
    pathToAssetsDefinition: 'assets/matrices.json',
  );

  final List<String> supportedCharacters =
      instance.characterDefinitions.supportedCharacters;

  test('Character Definitions', () async {
    expect(instance.characterDefinitions.count, 90);

    expect(
      supportedCharacters.join(),
      'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789 .,?!:;\'"(){}[]<>-/\\+=#\$&*@',
    );
  });

  test('Character Definitions Enclosures', () async {
    const String charactersWithEnclosures = '04689ABDOPQRbdegopq#@&';

    List<String> charactersWithNoEnclosures = supportedCharacters
        .where((c) => !charactersWithEnclosures.contains(c))
        .toList();

    // No englosure;
    for (final String char in charactersWithNoEnclosures) {
      final String reason = 'Characer > "$char"';
      final CharacterDefinition? definition =
          instance.characterDefinitions.getDefinition(char);

      expect(
        definition,
        isNotNull,
        reason: reason,
      );

      expect(
        instance.characterDefinitions.getDefinition(char)!.enclosures,
        0,
        reason: reason,
      );
    }

    // Enclosures
    expect(instance.characterDefinitions.getDefinition('A')!.enclosures, 1);
    expect(instance.characterDefinitions.getDefinition('B')!.enclosures, 2);
    expect(instance.characterDefinitions.getDefinition('b')!.enclosures, 1);
    expect(instance.characterDefinitions.getDefinition('D')!.enclosures, 1);
    expect(instance.characterDefinitions.getDefinition('d')!.enclosures, 1);
    expect(instance.characterDefinitions.getDefinition('e')!.enclosures, 1);
    expect(instance.characterDefinitions.getDefinition('g')!.enclosures, 1);
    expect(instance.characterDefinitions.getDefinition('O')!.enclosures, 1);
    expect(instance.characterDefinitions.getDefinition('o')!.enclosures, 1);
    expect(instance.characterDefinitions.getDefinition('P')!.enclosures, 1);
    expect(instance.characterDefinitions.getDefinition('p')!.enclosures, 1);
    expect(instance.characterDefinitions.getDefinition('Q')!.enclosures, 1);
    expect(instance.characterDefinitions.getDefinition('q')!.enclosures, 1);
    expect(instance.characterDefinitions.getDefinition('0')!.enclosures, 1);
    expect(instance.characterDefinitions.getDefinition('4')!.enclosures, 1);
    expect(instance.characterDefinitions.getDefinition('6')!.enclosures, 1);
    expect(instance.characterDefinitions.getDefinition('8')!.enclosures, 2);
    expect(instance.characterDefinitions.getDefinition('9')!.enclosures, 1);
  });
}
