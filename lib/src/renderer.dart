import 'package:wordle/src/types.dart';

abstract class Renderer {
  void init();

  void paint(List<Guess> guess, List<Result> result, RowData row);
}
