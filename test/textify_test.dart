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
    const String charactersWithEnclosures = '04689ABDOPQbdegopq';

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
        instance.characterDefinitions.getDefinition(char)!.enclosers,
        0,
        reason: reason,
      );
    }

    // Enclosures
    expect(instance.characterDefinitions.getDefinition('A')!.enclosers, 1);
    expect(instance.characterDefinitions.getDefinition('B')!.enclosers, 2);
    expect(instance.characterDefinitions.getDefinition('b')!.enclosers, 1);
    expect(instance.characterDefinitions.getDefinition('D')!.enclosers, 1);
    expect(instance.characterDefinitions.getDefinition('d')!.enclosers, 1);
    expect(instance.characterDefinitions.getDefinition('e')!.enclosers, 1);
    expect(instance.characterDefinitions.getDefinition('g')!.enclosers, 1);
    expect(instance.characterDefinitions.getDefinition('O')!.enclosers, 1);
    expect(instance.characterDefinitions.getDefinition('o')!.enclosers, 1);
    expect(instance.characterDefinitions.getDefinition('P')!.enclosers, 1);
    expect(instance.characterDefinitions.getDefinition('p')!.enclosers, 1);
    expect(instance.characterDefinitions.getDefinition('Q')!.enclosers, 1);
    expect(instance.characterDefinitions.getDefinition('q')!.enclosers, 1);
    expect(instance.characterDefinitions.getDefinition('0')!.enclosers, 1);
    expect(instance.characterDefinitions.getDefinition('4')!.enclosers, 1);
    expect(instance.characterDefinitions.getDefinition('6')!.enclosers, 1);
    expect(instance.characterDefinitions.getDefinition('8')!.enclosers, 2);
    expect(instance.characterDefinitions.getDefinition('9')!.enclosers, 1);
  });
}
