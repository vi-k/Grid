import "dart:math";
  
typedef TCreator<T> = T Function(int index);
typedef CellCreator<T> = T Function(int row, int col);

class GridRow<TCell, TRow> {
  TRow value;
  final List<TCell> _cells = [];

  GridRow._(this.value, int rowIndex, int colsCount, CellCreator? cellCreator) {
    for (var i = 0; i < colsCount; i++) {
      _cells.add(cellCreator?.call(rowIndex, i) as TCell);
    }
  }
  
  TCell operator [](int index) => _cells[index]; 
}

class GridGroup<TCell, TRow, TGroup, TCol> {
  final Grid<TCell, TRow, TGroup, TCol> grid;
  TGroup value;

  final List<TCol> _cols = [];

  GridGroup._(this.grid, this.value);
  
  TCol operator [](int index) => _cols[index];

  int get colsCount => _cols.length;

  int _getLeftColumnsCount() {
    var count = 0;
  
    for (var g in grid._groups) {
      if (g == this) break;
      count += g.colsCount;
    }
  
    return count;
  }

  void insertCol(int index, {TCol? col, CellCreator? cell}) {
    final absoluteIndex = _getLeftColumnsCount() + index;
    cell = cell ?? grid._cellCreator;
         
    _cols.insert(index, (col ?? grid._colCreator?.call(index)) as TCol);
    
    for (var i = 0; i < grid.rowsCount; i++) {
      grid._rows[i]._cells.insert(absoluteIndex, cell?.call(i, absoluteIndex) as TCell);
    }
  }

  void insertCols(int count, int index, {TCreator<TCol>? col, CellCreator? cell}) {
    col = col ?? grid._colCreator;
    cell = cell ?? grid._cellCreator;   
    final leftColumnsCount = _getLeftColumnsCount();

    while (count-- > 0) {
      final absoluteIndex = leftColumnsCount + index;
    
      _cols.insert(index, col?.call(absoluteIndex) as TCol);
      
      for (var i = 0; i < grid.rowsCount; i++) {
        grid._rows[i]._cells.insert(absoluteIndex, cell?.call(i, absoluteIndex) as TCell);
      }

      index++;
    }
  }

  void addCol({TCol? col, CellCreator? cell}) {
    insertCol(colsCount, col: col, cell: cell);
  }

  void addCols(int count, {TCreator<TCol>? col, CellCreator? cell}) {
    insertCols(count, colsCount, col: col, cell: cell);
  }
}

class Grid<TCell, TRow, TGroup, TCol> {
  final CellCreator<TCell>? _cellCreator;
  final TCreator<TRow>? _rowCreator;
  final TCreator<TGroup>? _groupCreator;
  final TCreator<TCol>? _colCreator;
  
  final List<GridRow<TCell, TRow>> _rows = [];
  final List<GridGroup<TCell, TRow, TGroup, TCol>> _groups = [];

  Grid({
    CellCreator<TCell>? cell,
    TCreator<TRow>? row,
    TCreator<TCol>? col, 
    TCreator<TGroup>? group, 
  }) : _cellCreator = cell,
       _rowCreator = row,
       _colCreator = col,
       _groupCreator = group;

  int get rowsCount => _rows.length;
  int get groupsCount => _groups.length;
  int get colsCount => _groups.fold(0, (prev, group) => prev + group.colsCount);

  GridRow<TCell, TRow> operator [](int index) => _rows[index];
  
  GridGroup<TCell, TRow, TGroup, TCol> group(int index) => _groups[index];
  
  TCol col(int index) {
    var i = index;
    for (var g in _groups) {
      if (i < g.colsCount) return g[i];
      i -= g.colsCount;
    }

    throw RangeError.range(index, 0, colsCount - 1);
  }

  Pair<GridGroup<TCell, TRow, TGroup, TCol>, int> findCol(int index) {
    var i = index;

    for (var g in _groups) {
      if (i < g.colsCount) return Pair<GridGroup<TCell, TRow, TGroup, TCol>, int>(g, i);
      i -= g.colsCount;
    }

    throw RangeError.range(index, 0, colsCount - 1);
  }

  void insertRow(int index, {TRow? row, CellCreator? cell}) {
    _rows.insert(index, GridRow<TCell, TRow>._(row as TRow, rowsCount, colsCount, cell ?? this._cellCreator));
  }

  void insertRows(int count, int index, {TCreator<TRow>? row, CellCreator? cell}) {
    row = row ?? this._rowCreator;
    while (count-- > 0) {
      _rows.insert(index, GridRow<TCell, TRow>._(row?.call(rowsCount) as TRow, rowsCount, colsCount, cell ?? this._cellCreator));
      index++;
    }
  }

  void addRow({TRow? row, CellCreator? cell}) => insertRow(rowsCount, row: row, cell: cell);  
  void addRows(int count, {TCreator<TRow>? row, CellCreator? cell}) => insertRows(count, rowsCount, row: row, cell: cell);


  void insertGroup(int index, {TGroup? group}) {
    _groups.insert(index, GridGroup<TCell, TRow, TGroup, TCol>._(this, group as TGroup));
  }

  void insertGroups(int count, int index, {TCreator<TGroup>? group}) {
    group = group ?? this._groupCreator;
    while (count-- > 0) {
      _groups.insert(index, GridGroup<TCell, TRow, TGroup, TCol>._(this, group?.call(groupsCount) as TGroup));
      index++;
    }
  }

  void addGroup({TGroup? group}) => insertGroup(groupsCount, group: group);
  void addGroups(int count, {TCreator<TGroup>? group}) => insertGroups(count, groupsCount, group: group);


  void insertCol(int index, {TCol? col, CellCreator? cell}) {
    if (index == colsCount) addCol(col: col, cell: cell);
    else {
      final f = findCol(index);
      f.first.insertCol(f.second, col: col, cell: cell);
    }
  }

  void insertCols(int count, int index, {TCreator<TCol>? col, CellCreator? cell}) {
    if (index == colsCount) addCols(count, col: col, cell: cell);
    else {
      final f = findCol(index);
      f.first.insertCols(count, f.second, col: col, cell: cell);
    }
  }

  void insertColAfter(int index, {TCol? col, CellCreator? cell}) {
    final f = findCol(index);
    f.first.insertCol(f.second + 1, col: col, cell: cell);
  }

  void insertColsAfter(int count, int index, {TCreator<TCol>? col, CellCreator? cell}) {
    final f = findCol(index);
    f.first.insertCols(count, f.second + 1, col: col, cell: cell);
  }

  void addCol({TCol? col, CellCreator? cell}) {
    if (_groups.isEmpty) addGroup();
    _groups.last.addCol(col: col, cell: cell);
  }

  void addCols(int count, {TCreator<TCol>? col, CellCreator? cell}) {
    if (_groups.isEmpty) addGroup();
    _groups.last.addCols(count, col: col, cell: cell);
  }

  @override
  String toString([int? maxWidth]) {
    final buf = StringBuffer();
    final buf2 = StringBuffer();
    final widths = List<int>.filled(colsCount + 1, 0);

    // Ширина столбца с названиями строк
    for (var i = 0; i < rowsCount; i++) {
      final value = (_rows[i].value ?? '[$i]').toString();
      if (widths[0] < value.length) widths[0] = maxWidth == null ? value.length : min(value.length, maxWidth);
    }

    // Ширина остальных столбцов
    for (var i = 0; i < rowsCount; i++) {
      // По названиям колонок
      for (var i = 0; i < groupsCount; i++) {
        final g = group(i);
        
        for (var j = 0; j < g.colsCount; j++) {
          final value = (g[j] ?? '[$j]').toString();
          if (widths[j + 1] < value.length) widths[j + 1] = maxWidth == null ? value.length : min(value.length, maxWidth);
        }
      }

      // По значениям ячеек
      for (var j = 0; j < colsCount; j++) {
        final value = _rows[i][j].toString();
        if (widths[j + 1] < value.length) widths[j + 1] = maxWidth == null ? value.length : min(value.length, maxWidth);
      }
    }

    // Строка с названиями групп
    final indent = ' ' * widths[0];

    if (groupsCount > 1 || groupsCount == 1 && _groups.first.value != null) {
      buf.write(indent);
      buf2.write(indent);

      var col = 0;
      for (var i = 0; i < groupsCount; i++) {
        final g = _groups[i];
        
        var maxWidth = 0;
        for (var j = 0; j < g.colsCount; j++) {
          maxWidth += widths[++col] + (j == 0 ? 0 : 2);
        }

        buf.write('    ');
        buf.write((g.value ?? '[$i]').toString().cutAndPad(maxWidth));
        
        buf2.write('    ');
        buf2.write('=' * maxWidth);
      }
      buf.write('\n');
      buf.write(buf2.toString());
      buf.write('\n');
    }
    
    // Строка с названиями колонок
    buf.write(indent);
    buf2.clear();
    buf2.write(indent);

    var col = 0;
    for (var i = 0; i < groupsCount; i++) {
      final g = _groups[i];
      
      for (var j = 0; j < g.colsCount; j++) {
        final w = widths[col + 1];
          buf.write(j == 0 ? '    ' : '  ');
          buf.write((g[j] ?? '[$col]').toString().cutAndPad(w));

          buf2.write(j == 0 ? '    ' : '  ');
          buf2.write('-' * w);
          col++;
      }
    }
    buf.write('\n');
    buf.write(buf2.toString());
    buf.write('\n');

    // Таблица
    for (var i = 0; i < rowsCount; i++) {
      final row = _rows[i];
      buf.write((row.value ?? '[$i]').toString().cutAndPadRight(widths[0]));

      var col = 0;
      for (var i = 0; i < groupsCount; i++) {
        final g = group(i);
        
        for (var j = 0; j < g.colsCount; j++) {
          buf.write(j == 0 ? '    ' : '  ');
          buf.write(row[col].toString().cutAndPadRight(widths[col + 1]));
          col++;
        }
      }
      buf.write('\n');
    }

    return buf.toString();
  }
}

class Pair<F, S> {
  final F first;
  final S second;

  const Pair(this.first, this.second);

  @override
  String toString() => '($first, $second)';
}

extension Ellipsis on String {
  /// Обрезает строку и добавляет к ней троеточие (ellipsis), если она больше заданного размера
  /// @param {int} width Максимальная длина строки
  /// @param {String} ellipsis='…' Своё троеточие, если символ '…' не устраивает
  /// @param {string} trim=true Удалять пробелы перед ellipsis
  String cut(int width, {String ellipsis = '…', bool trim = true}) {
    if (length <= width) return this;

    // В заданный размер должен войти хотя бы один символ строки и троеточие
    if (width < ellipsis.length) return '';

    var result = substring(0, width - ellipsis.length);
    if (trim) result = result.trimRight();
    
    return result + ellipsis;
  }

  String pad(int width, [String padding]) {
    return padLeft((width + length) ~/ 2, padding).padRight(width, padding);
  }

  String cutAndPadLeft( int width, {String ellipsis = '…', bool trim = true, String padding = ' '}) {
    return cut(width, ellipsis: ellipsis, trim: trim).padLeft(width, padding);
  }

  String cutAndPadRight( int width, {String ellipsis = '…', bool trim = true, String padding = ' '}) {
    return cut(width, ellipsis: ellipsis, trim: trim).padRight(width, padding);
  }

  String cutAndPad( int width, {String ellipsis = '…', bool trim = true, String padding = ' '}) {
    return cut(width, ellipsis: ellipsis, trim: trim).pad(width, padding);
  }
}


void main() {
  var grid1 = Grid<String, String, String, String>()
    ..addRow(row: 'Row 0')
    ..addRow(row: 'Row 1')
    ..addRow(row: 'Row 2')
    ..addGroup(group: 'Group 0')
    ..addGroup(group: 'Group 1')
    ..addGroup(group: 'Group 2')
    ..group(0).addCol(col: 'Col 0', cell: (row, col) => 'Cell $row.$col')
    ..group(0).addCol(col: 'Col 1', cell: (row, col) => 'Cell $row.$col')
    ..group(0).addCol(col: 'Col 2', cell: (row, col) => 'Cell $row.$col')
    ..group(1).addCol(col: 'Col 3', cell: (row, col) => 'Cell $row.$col')
    ..group(1).addCol(col: 'Col 4', cell: (row, col) => 'Cell $row.$col')
    ..group(2).addCol(col: 'Col 5', cell: (row, col) => 'Cell $row.$col');
  
  print(grid1.toString());
  
  var grid2 = Grid<String, String, String, String>()
    ..addRows(3, row: (index) => 'Row $index')
    ..addGroups(3, group: (index) => 'Group $index')
    ..group(0).addCols(3, col: (index) => 'Col $index', cell: (row, col) => 'Cell $row.$col')
    ..group(1).addCols(2, col: (index) => 'Col $index', cell: (row, col) => 'Cell $row.$col')
    ..group(2).addCol(col: 'Col 5', cell: (row, col) => 'Cell $row.$col');
  
  print(grid2.toString());

  var grid3 = Grid<String, String, String, String>(
    cell: (row, col) => 'Cell $row.$col',
    row: (index) => 'Row $index',
    group: (index) => 'Group $index',
    col: (index) => 'Col $index',
  )
    ..addRows(3)
    ..addGroups(3)
    ..group(0).addCols(3)
    ..group(1).addCols(2)
    ..group(2).addCol();
  
  print(grid3.toString());

  var grid4 = Grid<String, Null, Null, Null>(
    cell: (row, col) => 'Cell $row.$col',
  )
    ..addRows(3)
    ..addGroups(3)
    ..group(0).addCols(3)
    ..group(1).addCols(2)
    ..group(2).addCol();
  
  print(grid4.toString());

  var grid5 = Grid<String, String, String, String>()
    ..addRows(3, row: (index) => 'Row $index')
    ..addGroup(group: 'Group 0')
    ..addCols(3, col: (index) => 'Col $index', cell: (row, col) => 'Cell $row.$col')
    ..addGroup(group: 'Group 1')
    ..addCols(2, col: (index) => 'Col $index', cell: (row, col) => 'Cell $row.$col')
    ..addGroup(group: 'Group 2')
    ..addCol(col: 'Col 5', cell: (row, col) => 'Cell $row.$col');
  
  print(grid5.toString());

  var grid6 = Grid<String, String, Null, String>()
    ..addRows(3, row: (index) => 'Row $index')
    ..addCols(3, col: (index) => 'Col $index', cell: (row, col) => 'Cell $row.$col')
    ..addCols(2, col: (index) => 'Col $index', cell: (row, col) => 'Cell $row.$col')
    ..addCol(col: 'Col 5', cell: (row, col) => 'Cell $row.$col');
  
  print(grid6.toString());

  var grid7 = Grid<String, Null, Null, Null>(
    cell: (row, col) => 'Cell $row.$col',
  )
    ..addRows(10)
    ..addCols(10);
  
  print(grid7.toString());
}
