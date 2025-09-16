import '../../core/database/db_helper.dart';
import '../../core/models/ledger.dart';

class LedgerRepository {
  final DBHelper _dbHelper = DBHelper();

  Future<int> insertLedger(Ledger ledger) async {
    final db = await _dbHelper.database;
    return await db.insert('ledger', ledger.toMap());
  }

  Future<List<Ledger>> getAllLedgers() async {
    final db = await _dbHelper.database;
    final result = await db.query('ledger', orderBy: 'createdAt DESC');
    return result.map((e) => Ledger.fromMap(e)).toList();
  }

  Future<int> updateLedger(Ledger ledger) async {
    final db = await _dbHelper.database;
    return await db.update(
      'ledger',
      ledger.toMap(),
      where: 'id = ?',
      whereArgs: [ledger.id],
    );
  }

  Future<int> deleteLedger(int id) async {
    final db = await _dbHelper.database;
    return await db.delete('ledger', where: 'id = ?', whereArgs: [id]);
  }

  String getLedgerNo() {
    return 'LN_${DateTime.now().millisecondsSinceEpoch}';
  }

  String _sanitizeIdentifier(String input) =>
      input.replaceAll(RegExp(r'[^A-Za-z0-9_]'), '_');

  String _tableNameFromLedgerNo(String ledgerNo) {
    final safeLedgerNo = _sanitizeIdentifier(ledgerNo);
    return 'ledger_entries_$safeLedgerNo';
  }

  Future<void> createLedgerEntryTable(String ledgerNo) async {
    await _dbHelper.createLedgerEntryTable(ledgerNo);
  }

  Future<int> insertLedgerEntry(LedgerEntry entry, String ledgerNo) async {
    final db = await _dbHelper.database;
    final tableName = _tableNameFromLedgerNo(ledgerNo);

    // Ensure table exists before inserting
    await createLedgerEntryTable(ledgerNo);

    return await db.insert(tableName, entry.toMap());
  }

  Future<List<LedgerEntry>> getLedgerEntries(String ledgerNo) async {
    final db = await _dbHelper.database;
    final tableName = 'ledger_entries_$ledgerNo';

    try {
      final result = await db.query(tableName, orderBy: 'date ASC, id ASC');
      return result.map((e) => LedgerEntry.fromMap(e)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<int> updateLedgerEntry(LedgerEntry entry, String ledgerNo) async {
    final db = await _dbHelper.database;
    final tableName = _tableNameFromLedgerNo(ledgerNo);

    return await db.update(
      tableName,
      entry.toMap(),
      where: 'id = ?',
      whereArgs: [entry.id],
    );
  }

  Future<int> deleteLedgerEntry(int id, String ledgerNo) async {
    final db = await _dbHelper.database;
    final tableName = _tableNameFromLedgerNo(ledgerNo);

    return await db.delete(tableName, where: 'id = ?', whereArgs: [id]);
  }

  Future<List<LedgerEntry>> getLedgerEntriesByCustomer(
    String customerName,
  ) async {
    final db = await _dbHelper.database;
    final List<LedgerEntry> allEntries = [];

    try {
      // Get all ledger tables
      final tables = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name LIKE 'ledger_entries_%'",
      );

      for (final table in tables) {
        final tableName = table['name'] as String;

        // Use UPPER() for case-insensitive search
        final result = await db.rawQuery(
          '''
        SELECT * FROM $tableName
        WHERE UPPER(accountName) = UPPER(?)
        ORDER BY date DESC
      ''',
          [customerName],
        );

        final entries = result.map((e) => LedgerEntry.fromMap(e)).toList();
        allEntries.addAll(entries);
      }

      return allEntries;
    } catch (e) {
      return [];
    }
  }
}
