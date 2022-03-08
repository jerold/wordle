import 'package:wordle/src/types.dart';

enum HelperUpdate {
  reset,
  create,
  update,
}

abstract class Controller {
  Stream<HelperUpdate> get update;
  RowData get rowData;
  int get index;

  void reset();
}
