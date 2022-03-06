import 'package:wordle/src/types.dart';

abstract class Renderer {
  void init();

  void paint(List<RowData> rows);

  void paintCandidates(List<String> candidates);
}
