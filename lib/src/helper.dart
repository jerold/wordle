import 'dart:math';

import 'package:wordle/src/controller.dart';
import 'package:wordle/src/data/all_words.dart';
import 'package:wordle/src/data/allowed_words.dart';
import 'package:wordle/src/renderer.dart';
import 'package:wordle/src/types.dart';
import 'package:wordle/src/utils.dart';

const maxRounds = 6;
const maxCandidates = 5;

class Helper {
  final Controller _controller;
  final Renderer _renderer;

  late List<Guess> _guesses;
  late List<Result> _results;

  String? _answer;
  bool get playing => _answer != null;

  late bool _showSuggestions;
  List<String> _suggestions = [];

  Helper(this._controller, this._renderer, {bool play = false}) {
    _resetHelperData(play);
  }

  Future<void> init() async {
    _showSuggestions = !playing;
    _renderer.paintToggle(_showSuggestions);
    _controller.update.listen(_onControllerUpdate);
    _renderer.init();
    _paint();

    // chug through all words to give us the word with highest expected info
    // printAvgInfo(getExpectedInfo(allWords), limit: 20);
  }

  void _onControllerUpdate(HelperUpdate update) {
    switch (update) {
      case HelperUpdate.reset:
        _onReset(playing);
        break;
      case HelperUpdate.create:
        _onCreate();
        break;
      case HelperUpdate.update:
        _paint();
        break;
      case HelperUpdate.toggle:
        _onToggle();
        break;
    }
  }

  void _resetHelperData(bool play) {
    _guesses = <Guess>[];
    _results = <Result>[];
    _suggestions = [];
    print(play ? 'New Puzzle Generated, good luck!' : 'Ready to help!');
    if (play) {
      _answer = allWords[Random().nextInt(allWords.length)];
    } else {
      _answer = null;
      print('Good starters: raise, arise, arose, alone, ratio, irate, alter, alert, aisle, later, leant, learn, early');
    }
  }

  // update will flow to controller and then back here as a cursor update
  void _onReset(bool play) {
    _resetHelperData(play);
    _renderer.paintCandidates([]);
    _controller.reset();
  }

  void _onToggle() {
    _showSuggestions = !_showSuggestions;
    _renderer.paintToggle(_showSuggestions);
    print('Show($_showSuggestions)');
    if (_showSuggestions) {
      _renderer.paintCandidates(_suggestions);
    } else {
      _renderer.paintCandidates([]);
    }
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
    _suggestions = guess.expectedInfo(result).keys.toList();
    if (_suggestions.length > maxCandidates) {
      _suggestions = _suggestions.sublist(0, maxCandidates);
    }
    if (_showSuggestions) {
      _renderer.paintCandidates(_suggestions);
    }
  }

  void _paint() {
    final rowData = _getRowData();
    if (_results.length < maxRounds && (_results.isEmpty || _results.last != victoryPatter)) {
      rowData.add(_controller.rowData);
    }
    _renderer.paint(rowData);
  }
}
