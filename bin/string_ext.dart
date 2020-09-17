extension Ellipsis on String {
  
  /// Обрезает строку и добавляет к ней троеточие (`ellipsis`), если она больше заданного размера
  /// @param {int}    width        Максимальная длина строки
  /// @param {String} ellipsis='…' Своё троеточие, если символ '…' не устраивает
  /// @param {string} trim=true    Удалять пробелы перед `ellipsis`
  String cut(int width, {String ellipsis = '…', bool trim = true}) {
    if (length <= width) return this;

    // В заданный размер должен войти хотя бы один символ строки и троеточие
    if (width < ellipsis.length) return '';

    var result = width < ellipsis.length ? '' : substring(0, width - ellipsis.length);
    if (trim) result = result.trimRight();
    
    return result + ellipsis;
  }

  /// Центрирует текст, добавляя слева и справа `padding`
  String pad(int width, [String padding]) => padLeft((width + length) ~/ 2, padding).padRight(width, padding);

  /// Обрезает строку и добавляет `padding` слева (смещает строку вправо)
  String cutAndPadLeft( int width, {String ellipsis = '…', bool trim = true, String padding = ' '}) =>
    cut(width, ellipsis: ellipsis, trim: trim).padLeft(width, padding);

  /// Обрезает строку и добавляет `padding` справа (смещает строку влево)
  String cutAndPadRight( int width, {String ellipsis = '…', bool trim = true, String padding = ' '}) =>
    cut(width, ellipsis: ellipsis, trim: trim).padRight(width, padding);

  /// Обрезает строку и центрирует строку
  String cutAndPad( int width, {String ellipsis = '…', bool trim = true, String padding = ' '}) =>
    cut(width, ellipsis: ellipsis, trim: trim).pad(width, padding);
}
