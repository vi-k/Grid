import "dart:math";
  
typedef RowCreator<TRow> = TRow Function(int rowIndex);
typedef ColGroupCreator<TColGroup> = TColGroup Function(int colGroupIndex);
typedef ColCreator<TCol> = TCol Function(int colIndex);
typedef CellCreator<TCell> = TCell Function(int rowIndex, int colIndex);

class GridRow<TRow, TCell> {
  TRow value;
  final List<TCell> _cells = [];

  GridRow._(this.value, int rowIndex, int colsCount, CellCreator/*?*/ cellCreate) {
    for (int i = 0; i < colsCount; i++) {
      TCell cell = cellCreate?.call(rowIndex, i) as TCell;
      _cells.add(cell);
    }
  }
  
  TCell operator [](int index) => _cells[index]; 
}

class GridColGroup<TRow, TColGroup, TCol, TCell> {
  final Grid<TRow, TColGroup, TCol, TCell> grid;
  TColGroup value;

  final List<TCol> _cols = [];
  TCol operator [](int index) => _cols[index];

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

  void add([ColCreator<TCol>/*?*/ colCreate, CellCreator/*?*/ cellCreate]) {
    final int colIndex = _getLeftColumnsCount() + colsCount;
         
    TCol col = (colCreate ?? grid.colCreate)?.call(colIndex) as TCol;
    _cols.add(col);
    
    for (var i = 0; i < grid.rowsCount; i++) {
      TCell cell = cellCreate?.call(i, colIndex) as TCell;    
      grid._rows[i]._cells.insert(colIndex, cell);
    }
  }
}

// class GridException implements Exception {
//   final String message;
  
//   const GridException(this.message);
// }

class Grid<TRow, TColGroup, TCol, TCell> {
  final RowCreator<TRow>/*?*/ rowCreate;
  final ColGroupCreator<TCol>/*?*/ colGroupCreate;
  final ColCreator<TCol>/*?*/ colCreate;
  final CellCreator<TCell>/*?*/ cellCreate;
  
  final List<GridRow<TRow, TCell>> _rows = [];
  final List<GridColGroup<TRow, TColGroup, TCol, TCell>> _colGroups = [];

  int get rowsCount => _rows.length;
  int get colGroupsCount => _colGroups.length;
  int get colsCount => _colGroups.fold(0, (prev, group) => prev + group.colsCount);

  Grid({
    this.rowCreate,
    this.colGroupCreate, 
    this.colCreate, 
    this.cellCreate,
  });

  GridRow<TRow, TCell> operator [](int index) => _rows[index];
  GridColGroup<TRow, TColGroup, TCol, TCell> group(int index) => _colGroups[index];

  void addRow([RowCreator<TRow>/*?*/ rowCreate, CellCreator/*?*/ cellCreate]) {
    final row = (rowCreate ?? this.rowCreate)?.call(rowsCount) as TRow;
    final gridRow = GridRow<TRow, TCell>._(row, rowsCount, colsCount, cellCreate ?? this.cellCreate);
    _rows.add(gridRow);
  }
  
  void addColGroup([ColGroupCreator<TColGroup>/*?*/ colGroupCreate]) {
    final colGroup = (colGroupCreate ?? this.colGroupCreate)?.call(colGroupsCount) as TColGroup;
    final gridColGroup = GridColGroup<TRow, TColGroup, TCol, TCell>._(this, colGroup);
    _colGroups.add(gridColGroup);
  }
}

// class A<T> {
//   T value;
  
//   A(this.value);
  
//   void setValue() {
//   }
// }

void main() {
//   var a = A<void>(null);
//   print(a.value);
  
  var grid1 = Grid<String, String, String, String>()
    ..addRow((index) => 'Row $index')
    ..addRow((index) => 'Row $index')
    ..addRow((index) => 'Row $index')
    ..addColGroup((index) => 'ColGroup $index')
    ..addColGroup((index) => 'ColGroup $index')
    ..addColGroup((index) => 'ColGroup $index')
    ..group(0).add((index) => 'Col $index', (row, col) => 'Cell $row.$col')
    ..group(0).add((index) => 'Col $index', (row, col) => 'Cell $row.$col')
    ..group(0).add((index) => 'Col $index', (row, col) => 'Cell $row.$col')
    ..group(1).add((index) => 'Col $index', (row, col) => 'Cell $row.$col')
    ..group(1).add((index) => 'Col $index', (row, col) => 'Cell $row.$col')
    ..group(2).add((index) => 'Col $index', (row, col) => 'Cell $row.$col')
//     ..addCol('Col 1', (rowIndex) => '$rowIndex')
//     ..addCol('Col 2')
//     ..addCol('Col 3')
    ;
  
  const int colWidth = 12;
  
  var buf = StringBuffer();
  buf.write(' ' * colWidth);
  for (var i = 0; i < grid1.colGroupsCount; i++) {
    var colGroup = grid1.group(i);
    buf.write(colGroup.value.padRight(max(colGroup.colsCount * colWidth, colWidth)));
  }
  print(buf.toString());
  
  for (var i = 0; i < grid1.rowsCount; i++) {
    var buf = StringBuffer();
    buf.write(grid1[i].value.padRight(colWidth));
    for (var j = 0; j < grid1.colsCount; j++) {
      buf.write(grid1[i][j].padRight(colWidth));
    }
    print(buf.toString());
  }
  
//   print(a.z);
}
