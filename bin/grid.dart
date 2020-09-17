import 'dart:math';
import 'string_ext.dart';
  
typedef RowCreator<R> = R Function(int index);
typedef ColGroupCreator<G> = G Function(int index);
typedef ColCreator<C> = C Function(int index);
typedef CellCreator<L> = L Function(int row, int col);

class GridRow<R, L> {
  R value;
  final List<L> _cells = [];

  GridRow._(this.value, int rowIndex, int colsCount, CellCreator? cellCreate) {
    for (var i = 0; i < colsCount; i++) {
      L cell = cellCreate?.call(rowIndex, i) as L;
      _cells.add(cell);
    }
  }
  
  L operator [](int index) => _cells[index]; 
}

class GridColGroup<R, G, C, L> {
  final Grid<R, G, C, L> grid;
  G value;

  final List<C> _cols = [];
  C operator [](int index) => _cols[index];

  int get colsCount => _cols.length;

  GridColGroup._(this.grid, this.value);
  
  int _getLeftColumnsCount() {
    var count = 0;
    for (var g in grid._colGroups) {
      if (g == this) break;
      count += g.colsCount;
    }
    return count;
  }

  void addCol([C? value, CellCreator? cellCreate]) {
    final colIndex = _getLeftColumnsCount() + colsCount;
    cellCreate = cellCreate ?? grid.cellCreate;   
         
    _cols.add(value as C);
    
    for (var i = 0; i < grid.rowsCount; i++) {
      grid._rows[i]._cells.insert(colIndex, cellCreate?.call(i, colIndex) as L);
    }
  }

  void addCols(int count, [ColCreator<C>? colCreate, CellCreator? cellCreate]) {
    colCreate = colCreate ?? grid.colCreate;
    cellCreate = cellCreate ?? grid.cellCreate;   
    var colIndex = _getLeftColumnsCount() + colsCount;

    while (count-- > 0) {
      _cols.add(colCreate?.call(colIndex) as C);
      
      for (var i = 0; i < grid.rowsCount; i++) {
        grid._rows[i]._cells.insert(colIndex, cellCreate?.call(i, colIndex) as L);
      }

      colIndex++;
    }
  }
}

class Grid<R, G, C, L> {
  final RowCreator<R>? rowCreate;
  final ColGroupCreator<G>? colGroupCreate;
  final ColCreator<C>? colCreate;
  final CellCreator<L>? cellCreate;
  
  final List<GridRow<R, L>> _rows = [];
  final List<GridColGroup<R, G, C, L>> _colGroups = [];

  int get rowsCount => _rows.length;
  int get colGroupsCount => _colGroups.length;
  int get colsCount => _colGroups.fold(0, (prev, group) => prev + group.colsCount);

  Grid({
    this.rowCreate,
    this.colGroupCreate, 
    this.colCreate, 
    this.cellCreate,
  });

  GridRow<R, L> operator [](int index) => _rows[index];
  
  GridColGroup<R, G, C, L> group(int index) => _colGroups[index];
  
  C col(int index) {
    var i = index;
    for (var g in _colGroups) {
      if (i < g.colsCount) return g[i];
      i -= g.colsCount;
    }

    throw RangeError.range(index, 0, colsCount - 1);
  }

  void addRow([R? value, CellCreator? cellCreate]) {
    _rows.add(GridRow<R, L>._(value as R, rowsCount, colsCount, cellCreate ?? this.cellCreate));
  }
  
  void addRows(int count, [RowCreator<R>? rowCreate, CellCreator? cellCreate]) {
    rowCreate = rowCreate ?? this.rowCreate;
    while (count-- > 0) {
      _rows.add(GridRow<R, L>._(rowCreate?.call(rowsCount) as R, rowsCount, colsCount, cellCreate ?? this.cellCreate));
    }
  }

  void addColGroup([G? value]) {
    _colGroups.add(GridColGroup<R, G, C, L>._(this, value as G));
  }

  void addColGroups(int count, [ColGroupCreator<G>? colGroupCreate]) {
    colGroupCreate = colGroupCreate ?? this.colGroupCreate;
    while (count-- > 0) {
      _colGroups.add(GridColGroup<R, G, C, L>._(this, colGroupCreate?.call(colGroupsCount) as G));
    }
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
      for (var i = 0; i < colGroupsCount; i++) {
        final colGroup = group(i);
        
        for (var j = 0; j < colGroup.colsCount; j++) {
          final value = (colGroup[j] ?? '[$j]').toString();
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
    buf.write(indent);
    buf2.write(indent);

    var col = 0;
    for (var i = 0; i < colGroupsCount; i++) {
      final colGroup = group(i);
      
      var maxWidth = 0;
      for (var j = 0; j < colGroup.colsCount; j++) {
        maxWidth += widths[++col] + (j == 0 ? 0 : 2);
      }

      buf.write('    ');
      buf.write((colGroup.value ?? '[$i]').toString().cutAndPad(maxWidth));
      
      buf2.write('    ');
      buf2.write('=' * maxWidth);
    }
    buf.write('\n');
    buf.write(buf2.toString());
    buf.write('\n');
    
    // Строка с названиями колонок
    buf.write(indent);
    buf2.clear();
    buf2.write(indent);

    col = 0;
    for (var i = 0; i < colGroupsCount; i++) {
      final colGroup = group(i);
      
      for (var j = 0; j < colGroup.colsCount; j++) {
        final w = widths[col + 1];
          buf.write(j == 0 ? '    ' : '  ');
          buf.write((colGroup[j] ?? '[$col]').toString().cutAndPad(w));

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
      for (var i = 0; i < colGroupsCount; i++) {
        final colGroup = group(i);
        
        for (var j = 0; j < colGroup.colsCount; j++) {
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

void main() {
  var grid1 = Grid<String, String, String, String>()
    ..addRow('Row 0')
    ..addRow('Row 1')
    ..addRow('Row 2')
    ..addColGroup('ColGroup 0')
    ..addColGroup('ColGroup 1')
    ..addColGroup('ColGroup 2')
    ..group(0).addCol('Col 0', (row, col) => 'Cell $row.$col')
    ..group(0).addCol('Col 1', (row, col) => 'Cell $row.$col')
    ..group(0).addCol('Col 2', (row, col) => 'Cell $row.$col')
    ..group(1).addCol('Col 3', (row, col) => 'Cell $row.$col')
    ..group(1).addCol('Col 4', (row, col) => 'Cell $row.$col')
    ..group(2).addCol('Col 5', (row, col) => 'Cell $row.$col');
  
  print(grid1.toString());
  
  var grid2 = Grid<String, String, String, String>()
    ..addRows(3, (index) => 'Row $index')
    ..addColGroups(3, (index) => 'ColGroup $index')
    ..group(0).addCols(3, (index) => 'Col $index', (row, col) => 'Cell $row.$col')
    ..group(1).addCols(2, (index) => 'Col $index', (row, col) => 'Cell $row.$col')
    ..group(2).addCols(1, (index) => 'Col $index', (row, col) => 'Cell $row.$col');
  
  print(grid2.toString());

  var grid3 = Grid<String, String, String, String>(
    rowCreate: (index) => 'Row $index',
    colGroupCreate: (index) => 'ColGroup $index',
    colCreate: (index) => 'Col $index',
    cellCreate: (row, col) => 'Cell $row.$col',
  )
    ..addRows(3)
    ..addColGroups(3)
    ..group(0).addCols(3)
    ..group(1).addCols(2)
    ..group(2).addCols(1);
  
  print(grid3.toString());

  var z = <void>[];
  var grid4 = Grid<Void, Null, Null, String>(
    cellCreate: (row, col) => 'Cell $row.$col',
  )
    //..addRows(2)
    // ..addRow()
    // ..addRow()
    // ..addRow()
    ..addColGroups(3)
    ..group(0).addCols(3)
    ..group(1).addCols(2)
    ..group(2).addCols(1);
  
  print(grid4.toString());

  //print(grid4[2].value is Null);
  // print(grid4.group(0).value is Null);
  // print(grid1.col(5));
  //print(grid4.col(0) is Null);
}
