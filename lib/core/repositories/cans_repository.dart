import 'package:flutter/material.dart';
import 'package:ledger_master/core/database/db_helper.dart';
import 'package:ledger_master/core/models/cans.dart';

class CansRepository {
  final DBHelper _dbHelper = DBHelper();

  /// Fetch all cans tables
  Future<List<Cans>> getAllCans() async {
    final db = await _dbHelper.database;
    final maps = await db.query('cans');
    return maps.map((map) => Cans.fromMap(map)).toList();
  }

  /// Fetch a single cans table by ID
  Future<Cans?> getCansById(int id) async {
    final db = await _dbHelper.database;
    final maps = await db.query('cans', where: 'id = ?', whereArgs: [id]);
    if (maps.isNotEmpty) {
      return Cans.fromMap(maps.first);
    }
    return null;
  }

  /// Add a new cans table
  Future<int> addCans(Cans cans) async {
    final db = await _dbHelper.database;
    return await db.insert('cans', cans.toMap());
  }

  /// Update an existing cans table
  Future<int> updateCans(Cans cans) async {
    final db = await _dbHelper.database;
    return await db.update(
      'cans',
      cans.toMap(),
      where: 'id = ?',
      whereArgs: [cans.id],
    );
  }

  /// Delete a cans table
  Future<int> deleteCans(int id) async {
    final db = await _dbHelper.database;
    return await db.delete('cans', where: 'id = ?', whereArgs: [id]);
  }

  /// Fetch all entries for a specific cans table
  Future<List<CansEntry>> getCansEntriesByCansId(int cansId) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'cans_entries',
      where: 'cansId = ?',
      whereArgs: [cansId],
      orderBy: 'createdAt ASC',
    );
    return maps.map((map) => CansEntry.fromMap(map)).toList();
  }

  /// Add a new cans entry
  Future<int> addCansEntry(CansEntry entry) async {
    final db = await _dbHelper.database;
    return await db.insert('cans_entries', entry.toMap());
  }

  /// Update an existing cans entry
  Future<int> updateCansEntry(CansEntry entry) async {
    final db = await _dbHelper.database;
    return await db.update(
      'cans_entries',
      entry.toMap(),
      where: 'id = ?',
      whereArgs: [entry.id],
    );
  }

  /// Delete a cans entry
  Future<int> deleteCansEntry(int id) async {
    final db = await _dbHelper.database;
    return await db.delete('cans_entries', where: 'id = ?', whereArgs: [id]);
  }

  /// Fetch the latest cans table for a specific customer by name
  Future<Cans?> getCansByCustomerName(String accountName) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'cans',
      where: 'accountName = ?',
      whereArgs: [accountName],
      orderBy: 'updatedDate DESC',
      limit: 1,
    );
    if (maps.isNotEmpty) {
      return Cans.fromMap(maps.first);
    }
    return null;
  }

  Future<Map<String, dynamic>> getCansBalanceSummary(int accountId) async {
    final db = await _dbHelper.database;

    // First, get the cans record for this account
    final cansMaps = await db.query(
      'cans',
      where: 'accountId = ?',
      whereArgs: [accountId],
    );

    if (cansMaps.isEmpty) {
      return {
        'previous': 0.0,
        'current': 0.0,
        'total': 0.0,
        'received': 0.0,
        'balance': 0.0,
        'has_data': false,
      };
    }

    final cans = Cans.fromMap(cansMaps.first);
    final cansId = cans.id!;

    // Get ALL entries in chronological order
    final entriesMaps = await db.query(
      'cans_entries',
      where: 'cansId = ?',
      whereArgs: [cansId],
      orderBy: 'createdAt ASC', // Get ALL entries in order
    );

    final entries = entriesMaps.map((map) => CansEntry.fromMap(map)).toList();

    if (entries.isEmpty) {
      // No entries yet
      return {
        'previous': 0.0,
        'current': 0.0,
        'total': cans.openingBalanceCans,
        'received': 0.0,
        'balance': cans.openingBalanceCans,
        'has_data': true,
      };
    }

    // Get the latest (last) entry
    final latestEntry = entries.last;
    final currentIndex = entries.length - 1;

    // Calculate previous balance using the same logic as CansDataSource
    double previousCans;
    if (currentIndex == 0) {
      // First entry: previous is opening balance
      previousCans = cans.openingBalanceCans;
    } else {
      // Not first entry: previous is the balance up to previous entry
      previousCans = _calculateBalance(
        cans.openingBalanceCans,
        entries,
        currentIndex - 1,
      );
    }

    final double current = latestEntry.currentCans;
    final double total = previousCans + current;
    final double received = latestEntry.receivedCans;
    final double balance =
        total - received; // This should equal latestEntry.balance

    return {
      'previous': previousCans,
      'current': current,
      'total': total,
      'received': received,
      'balance': balance,
      'has_data': true,
    };
  }

  /// Calculate the running balance up to a given index (same as in CansDataSource)
  double _calculateBalance(
    double openingBalance,
    List<CansEntry> entries,
    int upToIndex,
  ) {
    double balance = openingBalance;
    for (int i = 0; i <= upToIndex && i < entries.length; i++) {
      balance += entries[i].currentCans - entries[i].receivedCans;
    }
    return balance;
  }

  /// Generate a unique voucher number (legacy function - can be used for other voucher types)
  Future<String> generateVoucherNoByCanId(int canId) async {
    final db = await _dbHelper.database;

    try {
      // Query only entries for this specific can to find the highest voucher number
      final result = await db.rawQuery(
        '''
        SELECT voucherNo FROM cans_entries
        WHERE cansId = ?
        AND voucherNo IS NOT NULL
        AND voucherNo LIKE 'CN%'
        ORDER BY voucherNo DESC
        LIMIT 1
      ''',
        [canId],
      );

      int maxNumber = 0;

      if (result.isNotEmpty) {
        final lastVoucherNo = result.first['voucherNo'] as String? ?? '';
        final match = RegExp(r'CN(\d+)').firstMatch(lastVoucherNo);
        if (match != null) {
          maxNumber = int.tryParse(match.group(1)!) ?? 0;
        }
      }

      // Generate next voucher number for this specific can
      final nextNumber = maxNumber + 1;
      return 'CN${nextNumber.toString().padLeft(3, '0')}'; // CN001, CN002, etc.
    } catch (e) {
      debugPrint('Error generating voucher number for canId $canId: $e');
      // Fallback: return a timestamp-based voucher number
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      return 'CN${timestamp.toString().substring(9)}';
    }
  }
}
