import 'dart:math';

import 'package:textify/english_words.dart';

/// Applies dictionary-based correction to the input text. It first tries to match words
/// directly in the dictionary, then attempts to substitute commonly confused characters,
/// and finally finds the closest match in the dictionary if no direct match is found.
/// The original casing of the input words is preserved in the corrected output.
Future<String> applyDictionaryCorrection(
  final String input,
) async {
  const Map<String, List<String>> correctionLetters = {
    '0': ['O', 'o', 'B', '8'],
    '5': ['S', 's'],
    'l': ['L', '1', 'i', '!'],
    'S': ['5'],
    'o': ['D', '0'],
    'O': ['D', '0'],
    '!': ['T', 'i', 'l', '1'],
    '@': ['A', 'a'],
  };

  String cleanedUpText = input;
  List<String> words = input.split(' ');

  for (int i = 0; i < words.length; i++) {
    String word = words[i];
    if (word.isEmpty) {
      continue;
    }

    final String allDigits = digitCorrection(word);
    if (allDigits.isNotEmpty) {
      words[i] = allDigits;
      continue;
    }

    // Try direct dictionary match first
    if (englishWords.contains(word.toLowerCase())) {
      words[i] = applyCasingToDifferingChars(word, word.toLowerCase());
      continue;
    }

    // Try substituting commonly confused characters
    String modifiedWord = word;
    bool foundMatch = false;

    for (final MapEntry<String, List<String>> entry
        in correctionLetters.entries) {
      for (final String substitute in entry.value) {
        if (word.contains(entry.key)) {
          String testWord = word.replaceAll(entry.key, substitute);
          if (englishWords.contains(testWord.toLowerCase())) {
            modifiedWord = testWord;
            foundMatch = true;
            break;
          }
        }
      }
      if (foundMatch) {
        break;
      }
    }

    // If no direct match after substitutions, find closest match
    if (!foundMatch) {
      String? suggestion =
          await findClosestWord(englishWords, modifiedWord.toLowerCase());
      if (suggestion == null) {
        // If the last letter is an 's' or 'S', remove it and try again to see if there's a hit on the singular version of the word
        String lastChar = modifiedWord[modifiedWord.length - 1];
        if (lastChar == 's' || lastChar == 'S') {
          String withoutLastLetter =
              modifiedWord.substring(0, modifiedWord.length - 1);
          suggestion = await findClosestWord(
            englishWords,
            withoutLastLetter.toLowerCase(),
          );
          if (suggestion != null) {
            suggestion += lastChar;
          }
        }
      } else {
        String lastChar = modifiedWord[modifiedWord.length - 1];
        if (lastChar == 's' ||
            lastChar == 'S' && (modifiedWord.length - 1 == suggestion.length)) {
          suggestion += lastChar;
        }
        if (modifiedWord.length == suggestion.length) {
          modifiedWord = suggestion;
        }
      }
    }

    words[i] = applyCasingToDifferingChars(word, modifiedWord);
  }

  cleanedUpText = words.join(' ');
  return cleanedUpText;
}

/// This function replaces problematic characters in the input string with their digit representations,
/// but only if the word is mostly composed of digits.
String digitCorrection(final String input) {
  const Map<String, String> map = {
    'o': '0',
    'O': '0',
    'i': '1',
    'l': '1',
    's': '5',
    'S': '5',
    'B': '8',
  };

  // List of digits for quick check
  const List<String> digits = [
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

  // Calculate the proportion of digits in the input string
  final int digitCount =
      input.split('').where((char) => digits.contains(char)).length;
  double digitProportion = digitCount / input.length;

  // Apply the correction only if the string is mostly composed of digits (e.g., > 50%)
  if (digitProportion <= 0.5) {
    return ''; // If not mostly digits, return the input as is
  }

  // Otherwise, perform the digit replacement
  String correction = '';
  for (int i = 0; i < input.length; i++) {
    String char = input[i];
    if (digits.contains(char)) {
      correction += char;
    } else {
      // Replace problematic characters with their digit representations
      correction += map[char] ?? char;
    }
  }
  return correction == input ? '' : correction;
}

/// Finds the closest matching word in a dictionary for a given input word.
Future<String?> findClosestWord(
  final Set<String> dictionary,
  final String word,
) async {
  String? closestMatch;
  int minDistance = 3; // Max edit distance to consider

  for (String dictWord in dictionary) {
    // Only consider words of similar length (±1 character)
    if ((dictWord.length - word.length).abs() <= 1) {
      int distance = levenshteinDistance(word, dictWord.toLowerCase());
      if (distance < minDistance ||
          (distance == minDistance &&
              dictWord.length > (closestMatch?.length ?? 0))) {
        minDistance = distance;
        closestMatch = dictWord;
      }
    }
  }

  return closestMatch;
}

/// Calculates the Levenshtein distance between two strings.
int levenshteinDistance(String s1, String s2) {
  if (s1 == s2) {
    return 0;
  }
  if (s1.isEmpty) {
    return s2.length;
  }
  if (s2.isEmpty) {
    return s1.length;
  }

  List<int> v0 = List<int>.generate(s2.length + 1, (i) => i);
  List<int> v1 = List<int>.filled(s2.length + 1, 0);

  for (int i = 0; i < s1.length; i++) {
    v1[0] = i + 1;

    for (int j = 0; j < s2.length; j++) {
      int cost = (s1[i] == s2[j]) ? 0 : 1;
      v1[j + 1] = min(v1[j] + 1, min(v0[j + 1] + 1, v0[j] + cost));
    }

    for (int j = 0; j < v0.length; j++) {
      v0[j] = v1[j];
    }
  }

  return v1[s2.length];
}

/// Applies the casing of the original string to the corrected string.
///
/// This function takes the original string and the corrected string, and
/// returns a new string where the casing of the corrected string characters is adjusted
/// to match the casing of the following character in the original string.

String applyCasingToDifferingChars(String original, String corrected) {
  if (original.length != corrected.length) {
    return corrected;
  }

  if (original == corrected) {
    return corrected;
  }

  StringBuffer result = StringBuffer();

  for (int i = 0; i < corrected.length; i++) {
    if (original[i].toLowerCase() != corrected[i].toLowerCase()) {
      if (i == 0) {
        // First modified character is always uppercase
        result.write(corrected[i].toUpperCase());
      } else if (i + 1 < original.length && isUpperCase(original[i + 1])) {
        // If the following character in the original string is uppercase
        result.write(corrected[i].toUpperCase());
      } else if (i == corrected.length - 1) {
        // Last modified character: Match the casing of the previous character
        result.write(
          isUpperCase(original[i - 1])
              ? corrected[i].toUpperCase()
              : corrected[i].toLowerCase(),
        );
      } else {
        // Otherwise, match the casing of the following character
        result.write(
          isUpperCase(original[i + 1])
              ? corrected[i].toUpperCase()
              : corrected[i].toLowerCase(),
        );
      }
    } else {
      // If the character matches, preserve it as is
      result.write(original[i]);
    }
  }

  return result.toString();
}

/// Checks whether the given string is all uppercase.
///
/// This function takes a [String] and returns `true` if the string contains only
/// uppercase characters, and `false` otherwise.
bool isUpperCase(String str) {
  return str == str.toUpperCase();
}