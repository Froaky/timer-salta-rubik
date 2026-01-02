import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

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

    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Create sessions table
    await db.execute('''
      CREATE TABLE sessions (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        cube_type TEXT NOT NULL,
        created_at INTEGER NOT NULL
      )
    ''');

    // Create default session
    await db.insert('sessions', {
      'id': 'default',
      'name': 'Default Session',
      'cube_type': '3x3',
      'created_at': DateTime.now().millisecondsSinceEpoch,
    });

    // Create solves table
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
        FOREIGN KEY (session_id) REFERENCES sessions (id) ON DELETE CASCADE
      )
    ''');
  }

  // Solve operations
  Future<void> insertSolve(Map<String, dynamic> solve) async {
    print('DEBUG: LocalDatabase.insertSolve called');
    print('DEBUG: Inserting solve data: $solve');
    final db = await database;
    try {
      final result = await db.insert('solves', solve);
      print('DEBUG: Insert successful, row ID: $result');
    } catch (e) {
      print('DEBUG: Insert failed with error: $e');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getSolves({
    String? sessionId,
    int? limit,
    int? offset,
  }) async {
    final db = await database;
    String whereClause = '';
    List<dynamic> whereArgs = [];

    if (sessionId != null) {
      whereClause = 'WHERE session_id = ?';
      whereArgs.add(sessionId);
    }

    String limitClause = '';
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

    return await db.rawQuery(query, whereArgs);
  }

  Future<List<Map<String, dynamic>>> getSolvesBySession(
      String sessionId) async {
    final db = await database;
    return await db.query(
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

  // Session operations
  Future<void> insertSession(Map<String, dynamic> session) async {
    final db = await database;
    await db.insert('sessions', session);
  }

  Future<List<Map<String, dynamic>>> getSessions() async {
    final db = await database;
    return await db.query(
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
    // Delete all solves in this session first
    await db.delete(
      'solves',
      where: 'session_id = ?',
      whereArgs: [id],
    );

    // Then delete the session
    await db.delete(
      'sessions',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
