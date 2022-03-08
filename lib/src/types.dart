import 'package:wordle/src/utils.dart';

const wordLength = 5;

const initialIndex = 0;
const emptyLetter = ' ';

final initialLetters = List<String>.filled(wordLength, emptyLetter);
final initialInfos = List<Info>.filled(wordLength, Info.tbd);
final victoryResult = Result(List<Info>.filled(wordLength, Info.correct));

final emptyInfos = List<Info>.filled(wordLength, Info.absent);

class RowData {
  final List<String> _letters;
  final List<Info> _infos;

  RowData({List<String>? letters, List<Info>? infos})
      : _letters = letters?.toList() ?? initialLetters.toList(),
        _infos = infos?.toList() ?? initialInfos.toList();

  RowData copyWith(int index, {String? letter, Info? info}) {
    assert(index >= 0 && index < wordLength, "invalid RowData copy (index out of bounds $index)");
    return RowData(
      letters: letter != null ? (letters..[index] = letter) : letters,
      infos: info != null ? (infos..[index] = info) : infos,
    );
  }

  List<String> get letters => _letters.toList();
  List<Info> get infos => _infos.toList();

  String get word => letters.join();
  Result get result => Result(infos);
}

class Guess {
  final String word;
  final List<String> words;
  final Map<Result, List<String>> patterns;

  Guess(this.word, this.words) : patterns = getResults(word, words);

  // takes the pattern resulting from the previous round to limit the remaining words for the next round
  Guess next(String word, Result pattern) => Guess(word, matches(pattern));

  List<String> matches(Result pattern) => patterns[pattern] ?? [];

  Result forWord(String word) => patterns.keys.firstWhere((p) => patterns[p]!.contains(word));

  Map<String, double> expectedInfo(Result pattern) => getExpectedInfo(matches(pattern));
}

enum Info {
  tbd,
  absent,
  present,
  correct,
}

extension InfoX on Info {
  Info get cycleUp => Info.values[(index + 1) % Info.values.length];
  Info get cycleDown => Info.values[(index - 1 + Info.values.length) % Info.values.length];
}

class InfoClass {
  static const String tbd = 'tbd';
  static const String empty = 'empty';
  static const String absent = 'absent';
  static const String present = 'present';
  static const String correct = 'correct';

  static from(Info into) {
    switch (into) {
      case Info.tbd:
        return InfoClass.tbd;
      case Info.absent:
        return InfoClass.absent;
      case Info.present:
        return InfoClass.present;
      case Info.correct:
        return InfoClass.correct;
    }
  }
}

// represents the pattern when comparing a guess to an answer. Letters that
// match the answer are given the appropreate Info value.
class Result {
  final List<Info> infos;

  final int _hashCode;

  Result(this.infos) : _hashCode = infos.fold(0, (p, e) => p * 10 + e.index);

  factory Result.input(List<int> ints) => Result(ints.map((e) => Info.values[e]).toList());

  factory Result.from(String guess, String answer) {
    // number of times the char has been used (correct guesses used first, then left
    // to right, must be <= number of times the char is in the answer to be close)
    final charCountUsed = <String, int>{};
    for (final letter in guess.split('')) {
      charCountUsed.putIfAbsent(letter, () => 0);
    }

    // how many times is the char in the answer
    final charCountInAnswer = <String, int>{};
    for (final letter in answer.split('')) {
      charCountInAnswer.putIfAbsent(letter, () => 0);
      charCountInAnswer[letter] = charCountInAnswer[letter]! + 1;
    }

    final infos = emptyInfos.toList();
    // go through and mark correct placement
    for (var i = 0; i < guess.length; i++) {
      final guessChar = guess[i];
      final answerChar = answer[i];
      if (guessChar == answerChar) {
        charCountUsed[guessChar] = charCountUsed[guessChar]! + 1;
        infos[i] = Info.correct;
      }
    }

    // go through and mark close and miss
    for (var i = 0; i < guess.length; i++) {
      final guessChar = guess[i];
      if (infos[i] != Info.correct) {
        if (charCountInAnswer.containsKey(guessChar) && charCountUsed[guessChar]! < charCountInAnswer[guessChar]!) {
          charCountUsed[guessChar] = charCountUsed[guessChar]! + 1;
          infos[i] = Info.present;
        }
      }
    }
    return Result(infos);
  }

  @override
  String toString() => infos.map((v) {
        if (v == Info.correct) return '🟩';
        if (v == Info.present) return '🟨';
        return '⬛';
      }).join();

  @override
  // ignore: avoid_renaming_method_parameters
  bool operator ==(Object o) {
    if (o is! Result) return false;
    if (o.infos.length != infos.length) return false;
    for (var i = 0; i < infos.length; i++) {
      if (o.infos[i] != infos[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode => _hashCode;
}
