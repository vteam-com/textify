/// Keep track of evaluation score of Artifacts against CharacterDefinition templates
class ScoreMatch {
  /// Factory method for creating an empty ScoreMatch
  factory ScoreMatch.empty() {
    return ScoreMatch(
      character: '',
      matrixIndex: -1,
      score: 0.0,
    );
  }

  /// Constructor
  ScoreMatch({
    required this.character,
    required this.matrixIndex,
    required this.score,
  });

  /// Charcter matched
  String character;

  /// Index of the matching template matrices
  int matrixIndex;

  /// final score in pecentation 0..1
  double score;

  /// Checks if the current object represents an empty or uninitialized state.
  ///
  /// This getter returns true if all of the following conditions are met:
  /// - The [character] string is empty
  /// - The [matrixIndex] is -1 (likely indicating an unset or invalid index)
  /// - The [score] is exactly 0
  ///
  /// This can be useful for determining if the object has been populated with
  /// meaningful data or if it's in its default/empty state.
  ///
  /// Returns:
  ///   [bool]: true if the object is considered empty, false otherwise.
  bool get isEmpty => character.isEmpty && matrixIndex == -1 && score == 0;
}
