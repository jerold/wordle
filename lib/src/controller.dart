import 'package:wordle/src/types.dart';

enum HelperUpdate {
  reset,
  create,
  update,
}

abstract class Controller extends RowData {
  Stream<HelperUpdate> get update;

  void reset();
}
