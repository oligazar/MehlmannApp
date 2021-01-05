import 'dart:io';

import 'package:mahlmann_app/common/constants.dart';
import 'package:mahlmann_app/common/interfaces/db_change_listener.dart';
import 'package:mahlmann_app/common/interfaces/db_saveable.dart';
import 'package:mahlmann_app/models/built_value/field.dart';
import 'package:mahlmann_app/models/built_value/fountain.dart';
import 'package:mahlmann_app/models/built_value/group.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DbClient {
  
  // static final _databaseVersion = 2; - should be!!
  static final _databaseVersion = 2;
  
  Future<Database> get database async {
    if (_db != null) return _db;
    _db = await _initDb();
    return _db;
  }

  // Users

  insertGroups(List<Group> groups, {bool shouldClearTable = true}) async {
    await _insertDBSaveable(groups, TABLE_GROUPS,
        shouldClearTable: shouldClearTable);
  }

  Future<List<Group>> queryGroups() async {
    return queryListIn(
      TABLE_GROUPS,
      Group.queryColumns,
      (m) => Group.fromMap(m),
    );
  }

  // Fountains

  insertFountains(List<Fountain> fountains,
      {bool shouldClearTable = true}) async {
    await _insertDBSaveable(fountains, TABLE_FOUNTAINS,
        shouldClearTable: shouldClearTable);
  }

  Future<List<Fountain>> queryFountains() async {
    return queryListIn(
      TABLE_FOUNTAINS,
      Fountain.queryColumns,
      (m) => Fountain.fromMap(m),
    );
  }

  // Fields

  insertFields(List<Field> fields, {bool shouldClearTable = true}) async {
    await _insertMap(fields?.map((c) => c.toDb())?.toList() ?? [], TABLE_FIELDS,
        shouldClearTable: shouldClearTable);
  }

  Future<List<Field>> queryFieldsIn(
      {String query = "", List<int> ids}) async {
    return queryListIn(TABLE_FIELDS, Field.queryColumns,
            (m) => Field.fromDb(m),
        queryCol: COL_NAME, query: query, argsCol: COL_ID, args: ids);
  }

  Future<List<Field>> queryFields({
    String query = "",
    int id,
  }) async {
    final argsCol = id != null && id > 0 ? COL_ID : null;
    final args = argsCol != null ? [id] : null;
    return queryListIn(
      TABLE_FIELDS,
      Field.queryColumns,
      (m) => Field.fromDb(m),
      queryCol: COL_NAME,
      query: query,
      argsCol: argsCol,
      args: args
    );
  }

  // helpers

  Future<List<T>> queryListIn<T>(
    String table,
    List<String> columns,
    T Function(Map) converter, {
    String argsCol,
    List args,
    String queryCol,
    String query,
    String orderBy,
  }) async {
    Database db = await database;

    final whereIn = _makeWhereIn(argsCol, args);
    final whereLike = _makeWhereLike(queryCol, query);
    final where = _makeWhere([whereIn, whereLike]);
    final totalArgs = <String>[];
    args?.forEach((arg) {
      if (arg != null) {
        totalArgs.add(arg.toString());
      }
    });
    if (query != null) totalArgs.add(query);

    List<Map> maps = await db.query(
      table,
      columns: columns,
      where: where,
      whereArgs: totalArgs,
      orderBy: orderBy,
    );
    // print("maps: $maps");
    return maps.map((m) => converter(m)).toList();
  }
  
  
  Future clearAllTables() async {
    Database db = await database;
    _tablesToDelete.forEach((table) {
      db
          .delete(table, where: "1")
          .then((rows) => print("$rows deleted from $table"));
    });
  }

  // database initialization

  static final _databaseName = "SqliteClient.common.sqlite.db";

  final List<String> _tableCreators = [
    Group.tableCreator,
    Fountain.tableCreator,
    Field.tableCreator,
  ];

  final List<String> _tablesToDelete = [
    TABLE_GROUPS,
    TABLE_FOUNTAINS,
    TABLE_FIELDS
  ];

  DbClient._internal();

  static final DbClient _instance = DbClient._internal();

  factory DbClient() => _instance;

  static Database _db;

  Future<Database> _initDb() async {
    // The path_provider plugin gets the right directory for Android or iOS.
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, _databaseName);

    // A quick way to view SQL commands printed out is to call before opening any database
//    await Sqflite.devSetDebugModeOn(true);
    // Open the database. Can also add an onUpdate callback parameter.
    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
      onDowngrade: _onUpgrade,
    );
  }

  Future _onCreate(Database db, int version) async {
    _tableCreators.forEach((tc) => db.execute(tc));
  }

  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    _tablesToDelete.forEach((ttd) => db.execute('DROP TABLE IF EXISTS $ttd'));
    _onCreate(db, newVersion);
  }

  // helpers

  Future<void> _insertMap(
    List<Map<String, dynamic>> items,
    String tableName, {
    bool shouldClearTable = true,
  }) async {
    Database db = await database;
    final batch = db.batch();
    if (shouldClearTable) {
      print('delete from: $tableName, new items: ${items.length}');
      batch.rawDelete("DELETE FROM $tableName");
    }
    items.forEach((map) {
      map[COL_SAVE_TIME] = DateTime.now().millisecondsSinceEpoch;
      batch.insert(tableName, map,
          conflictAlgorithm: ConflictAlgorithm.replace);
    });
    await batch.commit();
    _notify(tableName);
  }

  Future<void> _insertDBSaveable<T extends DBSaveable>(
    List<T> items,
    String tableName, {
    bool shouldClearTable = true,
  }) async {
    await _insertMap(
      items?.map((c) => c.toMap())?.toList() ?? [],
      tableName,
      shouldClearTable: shouldClearTable,
    );
  }

  final List<DbChangeListener> _listeners = [];

  void addChangeListener(DbChangeListener listener) {
    _listeners.add(listener);
  }

  void removeChangeListener(DbChangeListener listener) {
    _listeners.remove(listener);
  }

  void _notify(String table) {
    _listeners.forEach((l) => l.onTableChanged(table));
  }

  String _makeWhereIn(String col, List args, {bool notIn = false}) {
    final not = notIn ? " NOT" : "";
    final questions =
        args?.takeWhile((i) => i != null)?.map((i) => "?")?.join(", ");
    return questions != null && questions.isNotEmpty && col != null
        ? '$col$not IN ($questions)'
        : null;
  }

  String _makeWhereLike(String col, String query) =>
      query != null && col != null ? "$col LIKE '%' || ? || '%'" : null;

  String _makeWhere(List<String> statements) {
    final results = <String>[];
    statements.forEach((s) {
      if (s != null) results.add(s);
    });
    return results.isNotEmpty ? results.join(" AND ") : null;
  }
}
