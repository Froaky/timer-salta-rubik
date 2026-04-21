import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class LocalDatabase {
  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, 'salta_rubik.db');

    return openDatabase(
      path,
      version: 2,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db
          .execute('ALTER TABLE solves ADD COLUMN is_synced INTEGER DEFAULT 0');
    }
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE sessions (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        cube_type TEXT NOT NULL,
        created_at INTEGER NOT NULL
      )
    ''');

    await db.insert('sessions', {
      'id': 'default',
      'name': 'Default Session',
      'cube_type': '3x3',
      'created_at': DateTime.now().millisecondsSinceEpoch,
    });

    await db.execute('''
      CREATE TABLE solves (
        id TEXT PRIMARY KEY,
        session_id TEXT NOT NULL,
        time_ms INTEGER NOT NULL,
        penalty TEXT NOT NULL,
        scramble TEXT NOT NULL,
        cube_type TEXT NOT NULL,
        lane INTEGER,
        created_at INTEGER NOT NULL,
        is_synced INTEGER DEFAULT 0,
        FOREIGN KEY (session_id) REFERENCES sessions (id) ON DELETE CASCADE
      )
    ''');
  }

  Future<void> insertSolve(Map<String, dynamic> solve) async {
    final db = await database;
    await db.insert('solves', solve);
  }

  Future<List<Map<String, dynamic>>> getSolves({
    String? sessionId,
    int? limit,
    int? offset,
  }) async {
    final db = await database;
    var whereClause = '';
    final whereArgs = <dynamic>[];

    if (sessionId != null) {
      whereClause = 'WHERE session_id = ?';
      whereArgs.add(sessionId);
    }

    var limitClause = '';
    if (limit != null) {
      limitClause = 'LIMIT $limit';
      if (offset != null) {
        limitClause += ' OFFSET $offset';
      }
    }

    final query = '''
      SELECT * FROM solves
      $whereClause
      ORDER BY created_at DESC
      $limitClause
    ''';

    return db.rawQuery(query, whereArgs);
  }

  Future<List<Map<String, dynamic>>> getSolvesBySession(
      String sessionId) async {
    final db = await database;
    return db.query(
      'solves',
      where: 'session_id = ?',
      whereArgs: [sessionId],
      orderBy: 'created_at DESC',
    );
  }

  Future<void> updateSolve(Map<String, dynamic> solve) async {
    final db = await database;
    await db.update(
      'solves',
      solve,
      where: 'id = ?',
      whereArgs: [solve['id']],
    );
  }

  Future<void> deleteSolve(String id) async {
    final db = await database;
    await db.delete(
      'solves',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> deleteSolvesBySession(String sessionId) async {
    final db = await database;
    await db.delete(
      'solves',
      where: 'session_id = ?',
      whereArgs: [sessionId],
    );
  }

  Future<List<Map<String, dynamic>>> getUnsyncedSolves() async {
    final db = await database;
    return db.query(
      'solves',
      where: 'is_synced = ?',
      whereArgs: [0],
    );
  }

  Future<void> markSolvesAsSynced(List<String> ids) async {
    final db = await database;
    await db.update(
      'solves',
      {'is_synced': 1},
      where: 'id IN (${ids.map((id) => "'$id'").join(',')})',
    );
  }

  Future<void> insertSession(Map<String, dynamic> session) async {
    final db = await database;
    await db.insert('sessions', session);
  }

  Future<List<Map<String, dynamic>>> getSessions() async {
    final db = await database;
    return db.query(
      'sessions',
      orderBy: 'created_at DESC',
    );
  }

  Future<Map<String, dynamic>?> getSession(String id) async {
    final db = await database;
    final results = await db.query(
      'sessions',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    return results.isNotEmpty ? results.first : null;
  }

  Future<void> updateSession(Map<String, dynamic> session) async {
    final db = await database;
    await db.update(
      'sessions',
      session,
      where: 'id = ?',
      whereArgs: [session['id']],
    );
  }

  Future<void> deleteSession(String id) async {
    final db = await database;
    await db.delete(
      'solves',
      where: 'session_id = ?',
      whereArgs: [id],
    );

    await db.delete(
      'sessions',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
