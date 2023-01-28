import 'package:ml_linalg/linalg.dart';

import './qubo.dart';
import './exceptions.dart';

class Hamiltonian {
  final Matrix _matrix;

  Hamiltonian._(this._matrix);

  factory Hamiltonian.fromList(List<List<double>> list) {
    _checkListFormat(list);

    final matrix = Matrix.fromList(list, dtype: DType.float32);
    return Hamiltonian._(matrix);
  }

  factory Hamiltonian.fromQubo(Qubo qubo) {
    final matrix = _quboToMatrix(qubo);
    return Hamiltonian._(matrix);
  }

  List<List<double>> get matrix => _matrix
      .toList()
      .map(
        (iterable) => iterable.toList(),
      )
      .toList();

  int get dimension => _matrix.rowCount;

  static void _checkListFormat(List<List<double>> list) {
    final size = list.length;

    for (var rowIndex = 0; rowIndex < list.length; rowIndex++) {
      final row = list[rowIndex];
      if (row.length != size) {
        throw DataFormattingException(DataFormatError.listNotSquare);
      }
      for (var i = 0; i < rowIndex; i++) {
        if (row[i] != 0) {
          throw DataFormattingException(
            DataFormatError.lowerTriangleEntryNotZero,
          );
        }
      }
    }
  }

  static Matrix _quboToMatrix(Qubo qubo) {
    List<List<double>> rows = [];

    for (var i = 0; i < qubo.size; i++) {
      var row = List.filled(qubo.size, 0.0);
      for (var j = i; j < qubo.size; j++) {
        var entry = qubo.getEntry(i, j);
        if (entry != null) {
          row[j] = entry;
        }
      }
      rows.add(row);
    }

    return Matrix.fromList(rows, dtype: DType.float32);
  }
}

class SolutionVector {
  late Vector _vector;

  SolutionVector._(this._vector);

  factory SolutionVector.fromList(List<int> list) {
    _checkListFormat(list);

    final vector = Vector.fromList(list);
    return SolutionVector._(vector);
  }

  factory SolutionVector.filled(int length, {required int fillValue}) {
    if (fillValue != 0 && fillValue != 1) {
      throw InvalidOperationException(
        InvalidOperation.providedValueNotBinary,
        paramName: "fillValue",
      );
    }

    final vector = Vector.filled(length, fillValue, dtype: DType.float32);
    return SolutionVector._(vector);
  }

  List<int> get vector {
    return _vector.map((entry) => entry.round()).toList();
  }

  bool increment() {
    final current = vector;
    var cursor = current.length - 1;

    do {
      current[cursor] = current[cursor] == 0 ? 1 : 0;
      cursor -= 1;
    } while (current[cursor + 1] == 0 && cursor >= 0);

    _updateVector(current);

    return cursor == -1;
  }

  static void _checkListFormat(List<int> list) {
    for (var entry in list) {
      if (entry != 0 && entry != 1) {
        throw DataFormattingException(DataFormatError.entryNotBinary);
      }
    }
  }

  void _updateVector(List<int> newList) => _vector = Vector.fromList(newList);
}

class Calculator {
  static double energy(
    Hamiltonian hamiltonian,
    SolutionVector solutionVector,
  ) =>
      (solutionVector._vector *
              hamiltonian._matrix *
              Matrix.column(
                solutionVector._vector.toList(),
              ))
          .first;
}