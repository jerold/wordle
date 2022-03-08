import 'package:wordle/src/types.dart';

abstract class Renderer {
  void init(bool playing);

  void paint(List<RowData> rows, List<String> candidates);
}
