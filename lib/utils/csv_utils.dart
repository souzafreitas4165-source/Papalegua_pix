class CsvUtils {
  /// Gera uma string CSV a partir de uma lista de mapas.
  static String toCsv(List<Map<String, dynamic>> data,
      {List<String>? headers}) {
    if (data.isEmpty) return '';
    final keys = headers ?? data.first.keys.toList();
    final buffer = StringBuffer();
    buffer.writeln(keys.join(','));
    for (final row in data) {
      buffer.writeln(keys.map((k) => '"${row[k] ?? ''}"').join(','));
    }
    return buffer.toString();
  }
}
