import 'dart:math';

import 'package:wordle/src/controller.dart';
import 'package:wordle/src/data/all_words.dart';
import 'package:wordle/src/renderer.dart';
import 'package:wordle/src/types.dart';
import 'package:wordle/src/utils.dart';

class Helper {
  final Controller _controller;
  final Renderer _renderer;

  late List<Guess> _guesses;
  late List<Result> _results;
  String? _answer;

  Helper(this._controller, this._renderer, {bool play = false}) {
    _resetHelperData(play);
  }

  Future<void> init() async {
    _controller.update.listen(_onControllerUpdate);
    _renderer.init();
    print('raise, arise, arose, alone, ratio, atone, irate, alter, alert, aisle, later, teary, leant, learn, early');
    _paint();

    // chug through all words to give us the word with highest expected info
    // printAvgInfo(getExpectedInfo(allWords), limit: 20);
  }

  void _onControllerUpdate(HelperUpdate update) {
    switch (update) {
      case HelperUpdate.reset:
        _onReset();
        break;
      case HelperUpdate.create:
        _onCreate();
        break;
      case HelperUpdate.update:
        _paint();
        break;
    }
  }

  void _resetHelperData(bool play) {
    _guesses = <Guess>[];
    _results = <Result>[];
    _answer = allWords[Random().nextInt(allWords.length)];
    print('raise, arise, arose, alone, ratio, atone, irate, alter, alert, aisle, later, teary, leant, learn, early');
  }

  // update will flow to controller and then back here as a cursor update
  void _onReset() {
    print('--RESET--------------');
    _resetHelperData(_answer != null);
    _controller.reset();
  }

  void _onCreate() {
    final word = _controller.word;
    final result = _answer != null ? Result.from(word, _answer!) : _controller.result;
    final guess = _guesses.isEmpty ? Guess(word, allWords) : _guesses.last.next(word, _results.last);
    _guesses.add(guess);
    _results.add(result);
    _printRemaining();
    _controller.reset();
  }

  void _paint() => _renderer.paint(_guesses, _results, _controller);

  void _printRemaining() {
    if (_guesses.isNotEmpty) {
      final remaining = _guesses.last.matches(_results.last).length;
      print('Round:${_guesses.length} words:$remaining info:${getBits(1 / remaining).toStringAsFixed(2)}');
      printAvgInfo(_guesses.last.expectedInfo(_results.last), limit: 10);
    }
  }
}
