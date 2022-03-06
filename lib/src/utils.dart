import 'dart:math';

import 'package:wordle/src/types.dart';

double logBase(num x, num base) => log(x) / log(base);
double log10(num x) => log(x) / ln10;

// bits of information given a probability
double getBits(double p) => p < 1.0 ? -logBase(p, 2) : 0.0;

Map<Result, List<String>> getResults(String word, List<String> words) {
  final patterns = <Result, List<String>>{};
  for (final otherWord in words) {
    final pattern = Result.from(word, otherWord);
    patterns.putIfAbsent(pattern, () => []);
    patterns[pattern]!.add(otherWord);
  }
  return patterns;
}

// expected info given for each word, given the probability of it's most likely pattern
Map<String, double> getExpectedInfo(List<String> words) {
  final avgInfo = <String, double>{};
  for (final word in words) {
    final patterns = getResults(word, words);
    var maxPatternProbability = 0.0;
    for (final patternKey in patterns.keys) {
      final patternProbability = patterns[patternKey]!.length / words.length;
      // patternWords.length/words.length percent of the time this will be the pattern
      maxPatternProbability = max(maxPatternProbability, patternProbability);
    }
    avgInfo[word] = getBits(maxPatternProbability);
  }
  return avgInfo;
}

void printAvgInfo(Map<String, double> avgInfo, {int? limit}) {
  final sortedKeys = avgInfo.keys.toList()..sort((a, b) => avgInfo[b]!.compareTo(avgInfo[a]!));
  var i = 0;
  for (final key in sortedKeys) {
    print(' - $key ${avgInfo[key]!.toStringAsFixed(2)}');
    i++;
    if (limit != null && i > limit) break;
  }
}
