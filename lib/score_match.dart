/// Keep track of evaluation score of Artifacts against CharacterDefinition templates
class ScoreMatch {
  /// Factory method that creates a new [ScoreMatch] instance with default values:
  /// - [character] is an empty string
  /// - [matrixIndex] is -1
  /// - [score] is 0.0
  ///
  /// This can be used to create an "empty" or uninitialized [ScoreMatch] object.
  factory ScoreMatch.empty() {
    return ScoreMatch(
      character: '',
      matrixIndex: -1,
      score: 0.0,
    );
  }

  /// Constructs a [ScoreMatch] object with the provided [character], [matrixIndex], and [score].
  ///
  /// The [character] represents the matched character, the [matrixIndex] is the index of the
  /// matching template matrices, and the [score] is the final score in percentage (0..1).
  ScoreMatch({
    required this.character,
    required this.matrixIndex,
    required this.score,
  });

  /// Character matched
  final String character;

  /// Index of the matching template matrices
  final int matrixIndex;

  /// final score in percentage 0..1
  final double score;

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
