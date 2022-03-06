import 'dart:async';
import 'dart:html';
import 'dart:math';

import 'package:wordle/src/types.dart';
import 'package:wordle/wordle.dart';

const alphabet = 'abcdefghijklmnopqrstuvwxyz';

const defaultIndex = 0;
final defaultLetters = List<String>.filled(wordLength, ' ');
final defaultInfos = List<Info>.filled(wordLength, Info.miss);

enum CursorInput {
  left,
  right,
  up,
  down,
  delete,
}

const Map<int, HelperUpdate> helperBindings = {
  KeyCode.ESC: HelperUpdate.reset,
  KeyCode.ENTER: HelperUpdate.create,
};

const Map<int, CursorInput> cursorBindings = {
  KeyCode.LEFT: CursorInput.left,
  KeyCode.RIGHT: CursorInput.right,
  KeyCode.UP: CursorInput.up,
  KeyCode.DOWN: CursorInput.down,
  KeyCode.BACKSPACE: CursorInput.delete,
};

void main() {
  final controller = WebController();
  final renderer = WebRenderer();
  Helper(controller, renderer, play: true).init();
}

class WebController extends Controller {
  late final StreamController<HelperUpdate> _helperController;

  late List<String> _letters;
  late List<Info> _infos;
  late int _index;

  WebController() {
    _helperController = StreamController<HelperUpdate>.broadcast();
    _initRowData();

    document.body!.onKeyDown.listen(_onKeyDown);
  }

  @override
  Stream<HelperUpdate> get update => _helperController.stream;

  @override
  String get word => _letters.join();

  @override
  Result get result => Result(_infos);

  @override
  int get index => _index;

  void _initRowData() {
    _letters = defaultLetters.toList();
    _infos = defaultInfos.toList();
    _index = defaultIndex;
  }

  @override
  void reset() {
    _initRowData();
    _updateHelper(HelperUpdate.update);
  }

  void _onKeyDown(KeyboardEvent e) {
    if (helperBindings.containsKey(e.keyCode)) {
      _updateHelper(helperBindings[e.keyCode]!);
    } else if (cursorBindings.containsKey(e.keyCode)) {
      _onCursorInput(cursorBindings[e.keyCode]!);
    } else if (e.key != null && e.key!.length == 1 && alphabet.contains(e.key!)) {
      _onCharacterInsert(e.key!);
    }
  }

  void _updateHelper(HelperUpdate input) => _helperController.add(input);

  void _onCursorInput(CursorInput input) {
    switch (input) {
      case CursorInput.left:
        _index = (_index - 1 + wordLength) % wordLength;
        break;
      case CursorInput.right:
        _index = (_index + 1) % wordLength;
        break;
      case CursorInput.up:
        _infos[_index] = Info.values[(_infos[_index].index + 1) % Info.values.length];
        break;
      case CursorInput.down:
        _infos[_index] = Info.values[(_infos[_index].index - 1 + Info.values.length) % Info.values.length];
        break;
      case CursorInput.delete:
        _letters[_index] = ' ';
        _onCursorInput(CursorInput.left);
        break;
    }
    _updateHelper(HelperUpdate.update);
  }

  void _onCharacterInsert(String char) {
    _letters[_index] = char;
    _onCursorInput(CursorInput.right);
  }
}

class WebRenderer extends Renderer {
  @override
  void init() {}

  @override
  void paint(List<Guess> guesses, List<Result> results, RowData rowData) {
    for (int i = 0; i < guesses.length; i++) {
      print('${guesses[i].word} ${results[i]}');
    }
    if (results.isEmpty || results.last != victoryPatter) {
      var letters = rowData.word.split('');
      for (int i = 0; i < rowData.word.length; i++) {
        if (i == rowData.index) {
          letters[i] = '[${letters[i]}]';
        }
      }
      print('${letters.join()} ${rowData.result}');
    }
  }
}
