import 'dart:async';
import 'dart:html';
import 'dart:math';

import 'package:wordle/src/types.dart';
import 'package:wordle/wordle.dart';

const alphabet = 'abcdefghijklmnopqrstuvwxyz';

Element? get _parentElement => querySelector('#helper');

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
  KeyCode.TILDE: HelperUpdate.toggle,
};

const Map<int, CursorInput> cursorBindings = {
  KeyCode.UP: CursorInput.up,
  KeyCode.DOWN: CursorInput.down,
  KeyCode.BACKSPACE: CursorInput.delete,
};

void main() {
  final play = document.baseUri?.split('/#/').last == 'play';

  final controller = WebController();
  final renderer = WebRenderer();
  Helper(controller, renderer, play: play).init();
}

class WebController extends Controller {
  late final StreamController<HelperUpdate> _helperController;

  Element get _keyboardElement => _parentElement!.querySelector('#keyboard')!;
  Element get _toggleElement => _keyboardElement!.querySelector('#toggle-help')!;
  Element get _restartElement => querySelector('#restart')!;

  late RowData _rowData;
  late int _index;

  // gestures for changing info on mobile
  late Point _startTouch;
  late Point _endTouch;

  WebController() {
    _helperController = StreamController<HelperUpdate>.broadcast();
    _initRowData();

    document.body!.onKeyDown.listen(_onKeyDown);

    document.body!.onTouchStart.listen(_onTouchStart);
    document.body!.onTouchMove.listen(_onTouchMove);
    document.body!.onTouchEnd.listen(_onTouchEnd);

    for (final letter in alphabet.split('')) {
      _keyboardElement.querySelector('#$letter')!.onClick.listen(_onClickLetter(letter));
    }
    _keyboardElement.querySelector('#submit')!.onClick.listen((_) => _updateHelper(HelperUpdate.create));
    _keyboardElement.querySelector('#delete')!.onClick.listen((_) => _onCursorInput(CursorInput.delete));
    _toggleElement.onClick.listen((_) => _updateHelper(HelperUpdate.toggle));
    _restartElement.onClick.listen((_) => _updateHelper(HelperUpdate.reset));
  }

  @override
  Stream<HelperUpdate> get update => _helperController.stream;

  @override
  RowData get rowData => _rowData;

  @override
  int get index => _index;

  void _onTouchStart(TouchEvent e) {
    _startTouch = e.touches!.first.client;
    _endTouch = e.touches!.first.client;
  }

  void _onTouchMove(TouchEvent e) {
    _endTouch = e.touches!.first.client;
  }

  void _onTouchEnd(TouchEvent e) {
    if (_startTouch.distanceTo(_endTouch) > 40) {
      final deltaY = _endTouch.y - _startTouch.y;
      final deltaX = _endTouch.x - _startTouch.x;
      if (deltaY.abs() > deltaX.abs()) {
        if (deltaY > 0) {
          _onCursorInput(CursorInput.down);
        } else {
          _onCursorInput(CursorInput.up);
        }
      }
    }
  }

  void _initRowData() {
    _rowData = RowData();
    _index = initialIndex;
  }

  @override
  void reset() {
    _initRowData();
    _updateHelper(HelperUpdate.update);
  }

  void Function(MouseEvent) _onClickLetter(String letter) => (MouseEvent _) => _onCharacterInsert(letter);

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
        _index = max(_index - 1, 0);
        break;
      case CursorInput.right:
        _index = min(wordLength, _index + 1);
        break;
      case CursorInput.up:
        if (_index == 0) return;
        _rowData = _rowData.copyWith(_index - 1, info: _rowData.infos[index - 1].cycleUp);
        break;
      case CursorInput.down:
        if (_index == 0) return;
        _rowData = _rowData.copyWith(_index - 1, info: _rowData.infos[index - 1].cycleDown);
        break;
      case CursorInput.delete:
        if (_index == 0) return;
        _rowData = _rowData.copyWith(_index - 1, letter: emptyLetter, info: Info.tbd);
        _onCursorInput(CursorInput.left);
        break;
    }
    _updateHelper(HelperUpdate.update);
  }

  void _onCharacterInsert(String char) {
    if (_index == wordLength) return;
    _rowData = _rowData.copyWith(_index, letter: char.toLowerCase(), info: Info.tbd);
    _onCursorInput(CursorInput.right);
  }
}

class WebRenderer extends Renderer {
  WebRenderer();

  Element get _boardElement => _parentElement!.querySelector('#board')!;
  Element get _candidatesElement => _parentElement!.querySelector('#candidates')!;
  Element get _keyboardElement => _parentElement!.querySelector('#keyboard')!;
  Element get _toggleElement => _parentElement!.querySelector('#toggle-help')!;

  String? _prevCandidatesHash;

  @override
  void init() {
    assert(_parentElement != null, "Failed to mount Helper, unable to find element");
  }

  @override
  void paint(List<RowData> rows) {
    _paintBoard(rows);
    _paintKeyboard(rows);
  }

  @override
  void paintCandidates(List<String> candidates) {
    final hash = candidates.join();
    if (hash != _prevCandidatesHash) {
      _prevCandidatesHash = hash;
      _candidatesElement.innerHtml = candidates.map(_candidateInnerHtml).join();
    }
  }

  @override
  void paintToggle(bool isChecked) {
    (_toggleElement as InputElement).checked = isChecked;
  }

  void _paintBoard(List<RowData> rows) {
    _boardElement.innerHtml = rows.map(_boardRowInnerHtml).join();
  }

  String _boardRowInnerHtml(RowData row) {
    return Iterable.generate(wordLength, (i) => _tileInnerHtml(row.letters[i], row.infos[i])).join();
  }

  String _tileInnerHtml(String letter, Info info) =>
      '<div class="tile ${_tileState(letter, info)}">${_tileContent(letter)}</div>';

  String _tileContent(String letter) => letter == emptyLetter ? '&nbsp;' : letter;

  String _tileState(String letter, Info info) {
    switch (info) {
      case Info.absent:
        return InfoClass.absent;
      case Info.present:
        return InfoClass.present;
      case Info.correct:
        return InfoClass.correct;
      default:
        return letter == emptyLetter ? InfoClass.empty : InfoClass.tbd;
    }
  }

  void _paintKeyboard(List<RowData> rows) {
    final keyMap = <String, Info>{};
    for (final row in rows) {
      for (int i = 0; i < wordLength; i++) {
        final letter = row.letters[i];
        final info = row.infos[i];
        if (info != Info.tbd && (!keyMap.containsKey(letter) || keyMap[letter]!.index < info.index)) {
          keyMap[letter] = info;
        }
      }
    }
    for (final letter in alphabet.split('')) {
      final element = _keyboardElement.querySelector('#$letter')!;
      element.classes.removeAll([InfoClass.absent, InfoClass.present, InfoClass.correct]);
      if (keyMap.containsKey(letter)) {
        element.classes.add(InfoClass.from(keyMap[letter]!));
      }
    }
  }

  String _candidateInnerHtml(String candidate) {
    return Iterable.generate(wordLength, (i) => _smallTileInnerHtml(candidate[i])).join();
  }

  String _smallTileInnerHtml(String letter) => '<div class="small-tile">$letter</div>';
}
