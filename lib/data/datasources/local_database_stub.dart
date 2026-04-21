class LocalDatabase {
  Future<void> insertSolve(Map<String, dynamic> solve) {
    throw UnsupportedError('LocalDatabase is not supported on this platform.');
  }

  Future<List<Map<String, dynamic>>> getSolves({
    String? sessionId,
    int? limit,
    int? offset,
  }) {
    throw UnsupportedError('LocalDatabase is not supported on this platform.');
  }

  Future<List<Map<String, dynamic>>> getSolvesBySession(String sessionId) {
    throw UnsupportedError('LocalDatabase is not supported on this platform.');
  }

  Future<void> updateSolve(Map<String, dynamic> solve) {
    throw UnsupportedError('LocalDatabase is not supported on this platform.');
  }

  Future<void> deleteSolve(String id) {
    throw UnsupportedError('LocalDatabase is not supported on this platform.');
  }

  Future<void> deleteSolvesBySession(String sessionId) {
    throw UnsupportedError('LocalDatabase is not supported on this platform.');
  }

  Future<List<Map<String, dynamic>>> getUnsyncedSolves() {
    throw UnsupportedError('LocalDatabase is not supported on this platform.');
  }

  Future<void> markSolvesAsSynced(List<String> ids) {
    throw UnsupportedError('LocalDatabase is not supported on this platform.');
  }

  Future<void> insertSession(Map<String, dynamic> session) {
    throw UnsupportedError('LocalDatabase is not supported on this platform.');
  }

  Future<List<Map<String, dynamic>>> getSessions() {
    throw UnsupportedError('LocalDatabase is not supported on this platform.');
  }

  Future<Map<String, dynamic>?> getSession(String id) {
    throw UnsupportedError('LocalDatabase is not supported on this platform.');
  }

  Future<void> updateSession(Map<String, dynamic> session) {
    throw UnsupportedError('LocalDatabase is not supported on this platform.');
  }

  Future<void> deleteSession(String id) {
    throw UnsupportedError('LocalDatabase is not supported on this platform.');
  }
}
