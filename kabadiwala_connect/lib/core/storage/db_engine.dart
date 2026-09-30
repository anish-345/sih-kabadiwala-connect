abstract class DbEngine {
  void execute(String sql, [List<Object?> parameters = const []]);
  List<Map<String, dynamic>> select(String sql, [List<Object?> parameters = const []]);
  void close();
}
