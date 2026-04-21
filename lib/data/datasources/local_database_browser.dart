// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:convert';
import 'dart:html' as html;

class LocalDatabase {
  LocalDatabase({Map<String, String>? storage}) : _storageOverride = storage;

  static const _sessionsKey = 'salta_rubik.sessions';
  static const _solvesKey = 'salta_rubik.solves';
  static const _initializedKey = 'salta_rubik.initialized';

  final Map<String, String>? _storageOverride;

  Future<void> insertSolve(Map<String, dynamic> solve) async {
    final solves = await _readSolves();
    if (solves.any((entry) => entry['id'] == solve['id'])) {
      throw StateError('Solve with id ${solve['id']} already exists.');
    }
    solves.add(_normalizeRecord(solve));
    await _writeSolves(solves);
  }

  Future<List<Map<String, dynamic>>> getSolves({
    String? sessionId,
    int? limit,
    int? offset,
  }) async {
    var solves = await _readSolves();
    if (sessionId != null) {
      solves =
          solves.where((entry) => entry['session_id'] == sessionId).toList();
    }

    solves.sort(
      (a, b) => (b['created_at'] as int).compareTo(a['created_at'] as int),
    );

    final safeOffset = offset ?? 0;
    if (safeOffset >= solves.length) {
      return <Map<String, dynamic>>[];
    }

    final sliced = solves.sublist(safeOffset);
    if (limit == null) {
      return sliced;
    }

    final end = limit < sliced.length ? limit : sliced.length;
    return sliced.sublist(0, end);
  }

  Future<List<Map<String, dynamic>>> getSolvesBySession(String sessionId) {
    return getSolves(sessionId: sessionId);
  }

  Future<void> updateSolve(Map<String, dynamic> solve) async {
    final solves = await _readSolves();
    final index = solves.indexWhere((entry) => entry['id'] == solve['id']);
    if (index == -1) {
      return;
    }
    solves[index] = _normalizeRecord(solve);
    await _writeSolves(solves);
  }

  Future<void> deleteSolve(String id) async {
    final solves = await _readSolves();
    solves.removeWhere((entry) => entry['id'] == id);
    await _writeSolves(solves);
  }

  Future<void> deleteSolvesBySession(String sessionId) async {
    final solves = await _readSolves();
    solves.removeWhere((entry) => entry['session_id'] == sessionId);
    await _writeSolves(solves);
  }

  Future<List<Map<String, dynamic>>> getUnsyncedSolves() async {
    final solves = await _readSolves();
    return solves
        .where((entry) => (entry['is_synced'] as int? ?? 0) == 0)
        .toList();
  }

  Future<void> markSolvesAsSynced(List<String> ids) async {
    final solves = await _readSolves();
    final syncedIds = ids.toSet();
    for (final solve in solves) {
      if (syncedIds.contains(solve['id'])) {
        solve['is_synced'] = 1;
      }
    }
    await _writeSolves(solves);
  }

  Future<void> insertSession(Map<String, dynamic> session) async {
    final sessions = await _readSessions();
    if (sessions.any((entry) => entry['id'] == session['id'])) {
      throw StateError('Session with id ${session['id']} already exists.');
    }
    sessions.add(_normalizeRecord(session));
    await _writeSessions(sessions);
  }

  Future<List<Map<String, dynamic>>> getSessions() async {
    final sessions = await _readSessions();
    sessions.sort(
      (a, b) => (b['created_at'] as int).compareTo(a['created_at'] as int),
    );
    return sessions;
  }

  Future<Map<String, dynamic>?> getSession(String id) async {
    final sessions = await _readSessions();
    for (final session in sessions) {
      if (session['id'] == id) {
        return session;
      }
    }
    return null;
  }

  Future<void> updateSession(Map<String, dynamic> session) async {
    final sessions = await _readSessions();
    final index = sessions.indexWhere((entry) => entry['id'] == session['id']);
    if (index == -1) {
      return;
    }
    sessions[index] = _normalizeRecord(session);
    await _writeSessions(sessions);
  }

  Future<void> deleteSession(String id) async {
    final sessions = await _readSessions();
    final solves = await _readSolves();
    sessions.removeWhere((entry) => entry['id'] == id);
    solves.removeWhere((entry) => entry['session_id'] == id);
    await _writeSessions(sessions);
    await _writeSolves(solves);
  }

  Future<List<Map<String, dynamic>>> _readSessions() async {
    await _ensureInitialized();
    final raw = _storage[_sessionsKey];
    if (raw == null || raw.isEmpty) {
      return _defaultSessions();
    }
    return _decodeList(raw);
  }

  Future<List<Map<String, dynamic>>> _readSolves() async {
    await _ensureInitialized();
    final raw = _storage[_solvesKey];
    if (raw == null || raw.isEmpty) {
      return <Map<String, dynamic>>[];
    }
    return _decodeList(raw);
  }

  Future<void> _writeSessions(List<Map<String, dynamic>> sessions) async {
    await _ensureInitialized();
    _storage[_sessionsKey] = jsonEncode(sessions);
  }

  Future<void> _writeSolves(List<Map<String, dynamic>> solves) async {
    await _ensureInitialized();
    _storage[_solvesKey] = jsonEncode(solves);
  }

  Map<String, String> get _storage =>
      _storageOverride ?? html.window.localStorage;

  Future<void> _ensureInitialized() async {
    if (_storage[_initializedKey] == 'true') {
      return;
    }

    _storage[_sessionsKey] = jsonEncode(_defaultSessions());
    _storage[_solvesKey] = jsonEncode(const []);
    _storage[_initializedKey] = 'true';
  }

  List<Map<String, dynamic>> _decodeList(String raw) {
    final decoded = jsonDecode(raw) as List<dynamic>;
    return decoded
        .map(
          (entry) => _normalizeRecord(
            Map<String, dynamic>.from(entry as Map),
          ),
        )
        .toList();
  }

  List<Map<String, dynamic>> _defaultSessions() {
    return [
      {
        'id': 'default',
        'name': 'Default Session',
        'cube_type': '3x3',
        'created_at': DateTime.now().millisecondsSinceEpoch,
      },
    ];
  }

  Map<String, dynamic> _normalizeRecord(Map<String, dynamic> record) {
    final normalized = <String, dynamic>{};
    for (final entry in record.entries) {
      final value = entry.value;
      if (value is num) {
        normalized[entry.key] = value.toInt();
      } else {
        normalized[entry.key] = value;
      }
    }
    return normalized;
  }
}
