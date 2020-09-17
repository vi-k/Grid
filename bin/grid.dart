import 'dart:collection';
import 'dart:math';
import 'string_ext.dart';
  
typedef TCreator<T> = T Function(int index);
typedef CellCreator<T> = T Function(int row, int col);

class GridRow<TRow, TCell> extends IterableBase<TCell> {
  TRow value;
  final List<TCell> _cells = [];

  GridRow._(this.value, int rowIndex, int colsCount, CellCreator? cellCreator) {
    for (var i = 0; i < colsCount; i++) {
      _cells.add(cellCreator?.call(rowIndex, i) as TCell);
    }
  }
  
  TCell operator [](int index) => _cells[index];

  @override
  Iterator<TCell> get iterator => _cells.iterator;
}


class Grid<TRow, TCol, TCell> extends IterableBase<GridRow<TRow, TCell>> {
  final TCreator<TRow>? _rowCreator;
  final TCreator<TCol>? _colCreator;
  final CellCreator<TCell>? _cellCreator;
  
  final List<GridRow<TRow, TCell>> _rows = [];
  final List<TCol> _cols = [];

  Grid({
    CellCreator<TCell>? cell,
    TCreator<TRow>? row,
    TCreator<TCol>? col, 
  }) : _rowCreator = row,
       _colCreator = col,
       _cellCreator = cell;

  int get rowsCount => _rows.length;
  int get colsCount => _cols.length;

  GridRow<TRow, TCell> operator [](int index) => _rows[index];
  
  TCol col(int index) => _cols[index];


  void insertRow(int index, {TRow? row, CellCreator? cell}) {
    _rows.insert(index, GridRow<TRow, TCell>._(row as TRow, rowsCount, colsCount, cell ?? this._cellCreator));
  }

  void insertRows(int count, int index, {TCreator<TRow>? row, CellCreator? cell}) {
    row = row ?? this._rowCreator;
    while (count-- > 0) {
      insertRow(index, row: row?.call(rowsCount) as TRow, cell: cell);
      index++;
    }
  }

  void addRow({TRow? row, CellCreator? cell}) => insertRow(rowsCount, row: row, cell: cell);  
  void addRows(int count, {TCreator<TRow>? row, CellCreator? cell}) => insertRows(count, rowsCount, row: row, cell: cell);


  void insertCol(int index, {TCol? col, CellCreator? cell}) {
    cell = cell ?? _cellCreator;
         
    _cols.insert(index, (col ?? _colCreator?.call(index)) as TCol);

    for (var i = 0; i < rowsCount; i++) {
      _rows[i]._cells.insert(index, cell?.call(i, index) as TCell);
    }
  }

  void insertCols(int count, int index, {TCreator<TCol>? col, CellCreator? cell}) {
    col = col ?? _colCreator;
    cell = cell ?? _cellCreator;   

    while (count-- > 0) {
      insertCol(index, col: col?.call(index), cell: cell);
      index++;
    }
  }

  void addCol({TCol? col, CellCreator? cell}) => insertCol(colsCount, col: col, cell: cell);  
  void addCols(int count, {TCreator<TCol>? col, CellCreator? cell}) => insertCols(count, colsCount, col: col, cell: cell);


  @override
  Iterator<GridRow<TRow, TCell>> get iterator => _rows.iterator;


  @override
  String toString([int? maxWidth]) {
    final buf = StringBuffer();
    var firstWidth = 0;
    final widths = List<int>.filled(colsCount, 0);

    // Ширина столбца с названиями строк
    for (var i = 0; i < rowsCount; i++) {
      final value = (_rows[i].value ?? '[$i]').toString();
      if (firstWidth < value.length) firstWidth = maxWidth == null ? value.length : min(value.length, maxWidth);
    }

    // Ширина столбцов по названиям
    for (var i = 0; i < colsCount; i++) {
      final value = (_cols[i] ?? '[$i]').toString();
      if (widths[i] < value.length) widths[i] = maxWidth == null ? value.length : min(value.length, maxWidth);
    }

    // Ширина столбцов по значениям ячеек
    for (var row in this) {
      for (var i = 0; i < colsCount; i++) {
        final value = row[i].toString();
        if (widths[i] < value.length) widths[i] = maxWidth == null ? value.length : min(value.length, maxWidth);
      }
    }

    final indent = ' ' * firstWidth;

    // Строка с названиями колонок
    buf.write(indent);
    for (var i = 0; i < colsCount; i++) {
      buf.write('  ');
      buf.write((_cols[i] ?? '[$i]').toString().cutAndPad(widths[i]));
    }
    buf.write('\n');

    buf.write(indent);
    for (var i = 0; i < colsCount; i++) {
      buf.write('  ');
      buf.write('-' * widths[i]);
    }
    buf.write('\n');

    // Таблица
    for (var i = 0; i < rowsCount; i++) {
      final row = _rows[i];
      buf.write((row.value ?? '[$i]').toString().cutAndPadRight(firstWidth));

      for (var j = 0; j < colsCount; j++) {
        buf.write('  ');
        buf.write(row[j].toString().cutAndPadRight(widths[j]));
      }
      buf.write('\n');
    }

    return buf.toString();
  }
}

void main() {
  var grid1 = Grid<String, String, String>()
    ..addRow(row: 'Row 0')
    ..addRow(row: 'Row 1')
    ..addRow(row: 'Row 2')
    ..addCol(col: 'Col 0', cell: (row, col) => 'Cell $row.$col')
    ..addCol(col: 'Col 1', cell: (row, col) => 'Cell $row.$col')
    ..addCol(col: 'Col 2', cell: (row, col) => 'Cell $row.$col')
    ..addCol(col: 'Col 3', cell: (row, col) => 'Cell $row.$col')
    ..addCol(col: 'Col 4', cell: (row, col) => 'Cell $row.$col')
    ..addCol(col: 'Col 5', cell: (row, col) => 'Cell $row.$col');
  
  print(grid1.toString());
  
  var grid2 = Grid<String, String, String>()
    ..addRows(3, row: (index) => 'Row $index')
    ..addCols(5, col: (index) => 'Col $index', cell: (row, col) => 'Cell $row.$col')
    ..addCol(col: 'Total col', cell: (row, col) => 'Total cell $row.$col');
  
  print(grid2.toString());

  var grid3 = Grid<String, String, String>(
    cell: (row, col) => '$row.$col',
    row: (index) => 'Row $index',
    col: (index) => 'Col $index',
  )
    ..addRows(3)
    ..addCols(6);
  
  print(grid3.toString());

  var grid4 = Grid<Null, Null, String>(
    cell: (row, col) => '$row.$col',
  )
    ..addRows(3)
    ..addCols(6);
  
  print(grid4.toString());
}
