import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:textify/textify.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  test('Main Class', () async {
    final Textify instance = Textify();
    // at first all is empty
    expect(instance.count, 0);
    expect(instance.characterDefinitions.count, 0);

    // init() will load the default definitions
    await instance.init(pathToAssetsDefinition: 'assets/matrices.json');
    expect(instance.characterDefinitions.count, 70);
  });
}
