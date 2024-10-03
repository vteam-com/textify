/// Keep track of evaluation score of Artifacts against CharacterDefinition templates
class ScoreMatch {
  // Factory method for creating an empty ScoreMatch
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

  // if the ScoreMatch is empty
  bool get isEmpty => character.isEmpty && matrixIndex == -1 && score == 0.0;
}
