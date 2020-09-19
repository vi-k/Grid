import 'dart:collection';
import 'dart:math';
import 'string_ext.dart';
  
typedef TCreator<T> = T Function(int index);
typedef CellCreator<T> = T Function(int row, int col);

class GridRow<TRow, TCell> extends IterableBase<TCell> {
  int _index;
  TRow value;
  final List<TCell> _cells = [];

  GridRow._(this.value, int rowIndex, int colsCount, CellCreator? cellCreator) : _index = rowIndex {
    // Создаём ячейки в новой строке
    for (var i = 0; i < colsCount; i++) {
      _cells.add(cellCreator?.call(rowIndex, i) as TCell);
    }
  }
  
  int get index => _index;
  TCell operator [](int index) => _cells[index];

  @override
  Iterator<TCell> get iterator => _cells.iterator;
}

class GridCol<TCol> {
  int _index;
  TCol value;

  GridCol._(this.value, int colIndex) : _index = colIndex;
  
  int get index => _index;
}

class GridCols<TCol> extends IterableBase<GridCol<TCol>> {
  final Iterator<GridCol<TCol>> iterator;
  GridCols._(this.iterator);
}

class Grid<TRow, TCol, TCell> extends IterableBase<GridRow<TRow, TCell>> {
  final TCreator<TRow>? _rowCreator;
  final TCreator<TCol>? _colCreator;
  final CellCreator<TCell>? _cellCreator;
  
  final List<GridRow<TRow, TCell>> _rows = [];
  final List<GridCol<TCol>> _cols = [];

  Grid({
    TCreator<TRow>? row,
    TCreator<TCol>? col, 
    CellCreator<TCell>? cell,
  }) : _rowCreator = row,
       _colCreator = col,
       _cellCreator = cell;

  Grid.fill(int rowsCount, int colsCount, {
    TCreator<TRow>? row,
    TCreator<TCol>? col, 
    CellCreator<TCell>? cell,
  }) : _rowCreator = row,
       _colCreator = col,
       _cellCreator = cell {

    addRows(rowsCount);
    addCols(colsCount);
  }

  int get rowsCount => _rows.length;
  int get colsCount => _cols.length;

  GridRow<TRow, TCell> operator [](int index) => _rows[index];
 
  GridCol<TCol> col(int index) => _cols[index];

  @override
  Iterator<GridRow<TRow, TCell>> get iterator => _rows.iterator;

  GridCols<TCol> get cols => GridCols<TCol>._(_cols.iterator);


  void insertRow(int index, {TRow? row, CellCreator? cell}) {
    _rows.insert(index, GridRow<TRow, TCell>._(row as TRow, rowsCount, colsCount, cell ?? this._cellCreator));

    // Корректируем индексы строк снизу
    for (var i = index + 1; i < rowsCount; i++) {
      _rows[i]._index = i;
    }
  }

  void insertRows(int count, int index, {TCreator<TRow>? row, CellCreator? cell}) {
    row = row ?? this._rowCreator;
    
    while (count-- > 0) {
      _rows.insert(index, GridRow<TRow, TCell>._(row?.call(rowsCount) as TRow, rowsCount, colsCount, cell ?? this._cellCreator));
      index++;
    }

    // Корректируем индексы строк снизу
    for (var i = index; i < rowsCount; i++) {
      _rows[i]._index = i;
    }
  }

  void addRow({TRow? row, CellCreator? cell}) => insertRow(rowsCount, row: row, cell: cell);  
  void addRows(int count, {TCreator<TRow>? row, CellCreator? cell}) => insertRows(count, rowsCount, row: row, cell: cell);


  void insertCol(int index, {TCol? col, CellCreator? cell}) {
    cell = cell ?? _cellCreator;
         
    _cols.insert(index, GridCol<TCol>._((col ?? _colCreator?.call(index)) as TCol, index));

    // Создаём ячейки в новой колонке
    for (var i = 0; i < rowsCount; i++) {
      _rows[i]._cells.insert(index, cell?.call(i, index) as TCell);
    }

    // Корректируем индексы колонок справа
    for (var i = index + 1; i < colsCount; i++) {
      _cols[i]._index = i;
    }
  }

  void insertCols(int count, int index, {TCreator<TCol>? col, CellCreator? cell}) {
    col = col ?? _colCreator;
    cell = cell ?? _cellCreator;   

    while (count-- > 0) {
      _cols.insert(index, GridCol<TCol>._(col?.call(index) as TCol, index));

      // Создаём ячейки в новой колонке
      for (var i = 0; i < rowsCount; i++) {
        _rows[i]._cells.insert(index, cell?.call(i, index) as TCell);
      }

      index++;
    }

    // Корректируем индексы колонок справа
    for (var i = index; i < colsCount; i++) {
      _cols[i]._index = i;
    }
  }

  void addCol({TCol? col, CellCreator? cell}) => insertCol(colsCount, col: col, cell: cell);  
  void addCols(int count, {TCreator<TCol>? col, CellCreator? cell}) => insertCols(count, colsCount, col: col, cell: cell);


  @override
  String toString([int? maxWidth]) {
    final buf = StringBuffer();
    var firstWidth = 0;
    final widths = List<int>.filled(colsCount, 0);

    // Ширина колонки с названиями строк
    for (var row in _rows) {
      final value = (row.value ?? '[${row.index}]').toString();
      if (firstWidth < value.length) firstWidth = maxWidth == null ? value.length : min(value.length, maxWidth);
    }

    // Ширина колонок по названиям
    for (var col in _cols) {
      final value = (col.value ?? '[${col.index}]').toString();
      if (widths[col.index] < value.length) widths[col.index] = maxWidth == null ? value.length : min(value.length, maxWidth);
    }

    // Ширина колонок по значениям ячеек
    for (var row in _rows) {
      for (var col in _cols) {
        final value = row[col.index].toString();
        if (widths[col.index] < value.length) widths[col.index] = maxWidth == null ? value.length : min(value.length, maxWidth);
      }
    }

    final indent = ' ' * firstWidth;

    // Строка с названиями колонок
    buf.write(indent);
    for (var col in _cols) {
      buf.write('  ');
      buf.write((col.value ?? '[${col.index}]').toString().cutAndPad(widths[col.index]));
    }
    buf.write('\n');

    buf.write(indent);
    for (var col in _cols) {
      buf.write('  ');
      buf.write('-' * widths[col.index]);
    }
    buf.write('\n');

    // Таблица
    for (var row in _rows) {
      buf.write((row.value ?? '[${row.index}]').toString().cutAndPadRight(firstWidth));

      for (var col in _cols) {
        buf.write('  ');
        buf.write(row[col.index].toString().cutAndPadRight(widths[col.index]));
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
    row: (index) => 'Row $index',
    col: (index) => 'Col $index',
    cell: (row, col) => '$row.$col',
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

  var grid5 = Grid<String, String, String>.fill(3, 6,
    row: (index) => 'Row $index',
    col: (index) => 'Col $index',
    cell: (row, col) => 'Cell $row.$col',
  );
  
  print(grid5.toString());

  var grid6 = Grid<Null, Null, String>.fill(3, 6, cell: (row, col) => '$row.$col');
  
  print(grid6.toString());
}
