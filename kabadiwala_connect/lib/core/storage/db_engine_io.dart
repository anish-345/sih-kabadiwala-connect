import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqlite3/sqlite3.dart';
import 'db_engine.dart';

class SqliteDbEngine implements DbEngine {
  final Database _db;
  SqliteDbEngine(this._db);

  @override
  void execute(String sql, [List<Object?> parameters = const []]) {
    _db.execute(sql, parameters);
  }

  @override
  List<Map<String, dynamic>> select(String sql, [List<Object?> parameters = const []]) {
    final rs = _db.select(sql, parameters);
    return rs.map((row) => Map<String, dynamic>.from(row)).toList();
  }

  @override
  void close() {
    _db.dispose();
  }
}

Future<DbEngine> openPlatformDb({bool inMemory = false}) async {
  if (inMemory) {
    return SqliteDbEngine(sqlite3.openInMemory());
  } else {
    final docDir = await getApplicationDocumentsDirectory();
    final dbPath = p.join(docDir.path, 'kabadiwala_connect.db');
    return SqliteDbEngine(sqlite3.open(dbPath));
  }
}
