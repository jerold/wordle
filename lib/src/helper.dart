import 'dart:math';

import 'package:wordle/src/controller.dart';
import 'package:wordle/src/data/all_words.dart';
import 'package:wordle/src/data/allowed_words.dart';
import 'package:wordle/src/renderer.dart';
import 'package:wordle/src/types.dart';

const maxRounds = 6;
const maxCandidates = 5;

class Helper {
  final Controller _controller;
  final Renderer _renderer;

  late List<Guess> _guesses;
  late List<Result> _results;

  String? _answer;
  bool get playing => _answer != null;

  List<String> _candidates = [];

  Helper(this._controller, this._renderer);

  Future<void> init(bool play) async {
    _resetHelperData(play);
    _controller.update.listen(_onControllerUpdate);
    _renderer.init(play);
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
    if (play) {
      _candidates = [];
      _answer = allWords[Random().nextInt(allWords.length)];
    } else {
      _candidates = [
        'slate',
        'crane',
        'trace',
        'audio',
        'weary',
      ];
    }
  }

  // update will flow to controller and then back here as a cursor update
  void _onReset() {
    _resetHelperData(playing);
    _controller.reset();
  }

  void _onCreate() {
    final word = _controller.rowData.word;

    if (_results.length == maxRounds) {
      print('  :( Sorry, 6 tries is all you get!');
      return;
    }

    // don't submit empty guesses
    if (word.trim().length != wordLength) {
      print('  :( Can\'t submit an incomplete word!');
      return;
    }

    if (!allowedWords.contains(word)) {
      print('  :( Your word isn\'t in the allowed list!');
      return;
    }

    if (!playing && _controller.rowData.result.infos.any((element) => element == Info.tbd)) {
      print('   :( Please provide the pattern returns by Wordle for this word!');
      return;
    }

    if (playing && _controller.rowData.result.infos.any((element) => element != Info.tbd)) {
      print('   :) I\'ll handle the results, you can relax.');
    }

    final result = playing ? Result.from(word, _answer!) : _controller.rowData.result;
    final guess = _guesses.isEmpty ? Guess(word, allWords) : _guesses.last.next(word, _results.last);

    _guesses.add(guess);
    _results.add(result);
    _controller.reset();

    _generateCandidates(guess, result);
  }

  List<RowData> _getRowData() {
    final rowData = <RowData>[];
    for (int i = 0; i < _guesses.length; i++) {
      rowData.add(RowData(
        letters: _guesses[i].word.split(''),
        infos: _results[i].infos,
      ));
    }
    return rowData;
  }

  Future<void> _generateCandidates(Guess guess, Result result) async {
    if (!playing) {
      _candidates = guess.expectedInfo(result).keys.toList();
      if (_candidates.length > maxCandidates) {
        _candidates = _candidates.sublist(0, maxCandidates);
      }
      _paint();
    }
  }

  void _paint() {
    final rowData = _getRowData();
    if (_results.length < maxRounds && (_results.isEmpty || _results.last != victoryResult)) {
      rowData.add(_controller.rowData);
    }
    _renderer.paint(rowData, _candidates);
  }
}
