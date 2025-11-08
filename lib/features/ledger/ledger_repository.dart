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

  Future<bool> ledgerExistsForCustomer(String customerName) async {
    final db = await _dbHelper.database;
    final result = await db.query(
      'ledger',
      columns: ['id'],
      where: 'UPPER(accountName) = UPPER(?)',
      whereArgs: [customerName],
      limit: 1,
    );
    return result.isNotEmpty;
  }

  Future<int> deleteLedger(int id) async {
    final db = await _dbHelper.database;
    return await db.delete('ledger', where: 'id = ?', whereArgs: [id]);
  }

  Future<String> getLedgerNo() async {
    final db = await _dbHelper.database;

    // get the largest ledgerNo from the table
    // assuming ledgerNo is stored like 'LN_0001', 'LN_0002', etc.
    final result = await db.rawQuery('''
    SELECT ledgerNo
    FROM ledger
    WHERE ledgerNo LIKE 'LN_%'
    ORDER BY CAST(SUBSTR(ledgerNo, 4) AS INTEGER) DESC
    LIMIT 1
  ''');

    if (result.isNotEmpty) {
      final lastLedgerNo = result.first['ledgerNo'] as String;
      final lastNumber = int.tryParse(lastLedgerNo.replaceAll('LN_', '')) ?? 0;
      final nextNumber = lastNumber + 1;

      // format with leading zeros if you want (e.g. LN_0001)
      return 'LN_${nextNumber.toString().padLeft(4, '0')}';
    } else {
      // no ledgers yet
      return 'LN_0001';
    }
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

  Future<void> updateLedgerDebtOrCred(
    String flag,
    String ledgerNo,
    double value,
  ) async {
    await _dbHelper.updateLedgerDebtOrCred(flag, ledgerNo, value);
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
    final tableName = _tableNameFromLedgerNo(ledgerNo);

    try {
      final result = await db.query(tableName, orderBy: 'date ASC');
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

    // First, get the entry details before deletion
    final entryResult = await db.query(
      tableName,
      where: 'id = ?',
      whereArgs: [id],
    );

    if (entryResult.isEmpty) {
      return 0; // Entry not found
    }

    final entry = LedgerEntry.fromMap(entryResult.first);

    // Delete the entry
    final deleteCount = await db.delete(
      tableName,
      where: 'id = ?',
      whereArgs: [id],
    );

    if (deleteCount > 0) {
      // If entry has credit, update both credit and balance
      if (entry.credit > 0) {
        await updateLedgerDebtOrCred('credit', ledgerNo, -entry.credit);

        // Also update balance by subtracting the credit amount
        await db.rawUpdate(
          'UPDATE ledger SET balance = balance - ? WHERE ledgerNo = ?',
          [entry.credit, ledgerNo],
        );
      }

      // If entry has debit, only update debit (balance unchanged)
      if (entry.debit > 0) {
        await updateLedgerDebtOrCred('debit', ledgerNo, -entry.debit);
      }
    }

    return deleteCount;
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

  Future<String> getLastVoucherNo(String ledgerNo) async {
    final db = await _dbHelper.database;
    final tableName = _tableNameFromLedgerNo(ledgerNo);

    try {
      final result = await db.query(
        tableName,
        columns: ['voucherNo'],
        orderBy: 'voucherNo DESC',
        limit: 1,
      );
      return result.isNotEmpty ? result.first['voucherNo'] as String : 'VN00';
    } catch (e) {
      return 'VN00'; // fallback
    }
  }
}
