import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:ledger_master/core/models/item.dart';
import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class DBHelper {
  static final DBHelper _instance = DBHelper._internal();
  factory DBHelper() => _instance;
  DBHelper._internal();
  final int version = 12; // Incremented version to force schema update
  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  Future<Database> _initDB() async {
    try {
      sqfliteFfiInit();
    } catch (_) {}

    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'ledger_app.db');

    return await openDatabase(
      path,
      version: version,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
      onDowngrade: _onDowngrade,
      onConfigure: (db) async {
        // Enable WAL mode for better concurrency and reduced locking
        await db.execute('PRAGMA journal_mode=WAL');
        // Increase timeout for busy locks (e.g., during concurrent access)
        await db.execute('PRAGMA busy_timeout=5000');
        // Optional: Other PRAGMAs for performance
        await db.execute(
          'PRAGMA synchronous=NORMAL',
        ); // Balanced safety/performance
        await db.execute('PRAGMA cache_size=10000'); // Larger cache for writes
      },
    );
  }

  Future _onDowngrade(Database db, int oldVersion, int newVersion) async {
    await _dropAndRecreateAllTables(db);
  }

  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    await _dropAndRecreateAllTables(db);
  }

  Future<void> _dropAndRecreateAllTables(Database db) async {
    // Drop all existing tables
    final tables = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%'",
    );

    for (final table in tables) {
      final tableName = table['name'] as String;
      await db.execute('DROP TABLE IF EXISTS $tableName');
    }

    // Recreate all tables with current schema
    await _createAllTables(db);
  }

  Future _onCreate(Database db, int version) async {
    await _createAllTables(db);
  }

  Future<void> _createAllTables(Database db) async {
    // Create ledger table
    await db.execute('''
      CREATE TABLE ledger(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        ledgerNo TEXT NOT NULL,
        accountId INTEGER,
        accountName TEXT NOT NULL,
        transactionType TEXT NOT NULL,
        debit REAL NOT NULL,
        credit REAL NOT NULL,
        date TEXT NOT NULL,
        description TEXT,
        referenceNumber TEXT,
        transactionId INTEGER,
        createdAt TEXT NOT NULL,
        updatedAt TEXT NOT NULL,
        createdBy TEXT,
        category TEXT,
        tags TEXT,
        voucherNo TEXT NOT NULL,
        balance REAL NOT NULL,
        status TEXT NOT NULL
      )
    ''');

    // Create customer table
    await db.execute('''
      CREATE TABLE customer(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        address TEXT NOT NULL,
        customerNo TEXT NOT NULL,
        mobileNo TEXT NOT NULL,
        type TEXT NOT NULL,
        ntnNo TEXT,
        openingBalance TEXT
      )
    ''');

    // Create item table
    await db.execute('''
      CREATE TABLE item(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        type TEXT NOT NULL,
        vendor TEXT NOT NULL,
        pricePerKg REAL NOT NULL,
        costPrice REAL NOT NULL,
        sellingPrice REAL NOT NULL,
        availableStock REAL NOT NULL,
        canWeight REAL NOT NULL
      )
    ''');

    // Create stock transaction table
    await db.execute('''
      CREATE TABLE stock_transaction(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        itemId INTEGER NOT NULL,
        quantity REAL NOT NULL,
        date TEXT NOT NULL,
        type TEXT NOT NULL,
        FOREIGN KEY(itemId) REFERENCES item(id)
      )
    ''');

    // Create expense_purchases table
    await db.execute('''
      CREATE TABLE expense_purchases (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date INTEGER NOT NULL,
        description TEXT NOT NULL,
        amount REAL NOT NULL,
        madeBy TEXT NOT NULL,
        category TEXT NOT NULL,
        paymentMethod TEXT NOT NULL,
        referenceNumber TEXT,
        notes TEXT,
        createdAt INTEGER NOT NULL,
        updatedAt INTEGER NOT NULL
      )
    ''');
  }

  Future<void> createLedgerEntryTable(String ledgerNo) async {
    final db = await database;
    final safeLedgerNo = _sanitizeIdentifier(ledgerNo);
    final tableName = 'ledger_entries_$safeLedgerNo';

    try {
      // Check if the table exists
      final tableExists = await db.rawQuery(
        '''
      SELECT name FROM sqlite_master
      WHERE type='table' AND name=?
      ''',
        [tableName],
      );

      // If table does not exist → create it
      if (tableExists.isEmpty) {
        await db.execute('''
        CREATE TABLE $tableName (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          ledgerNo TEXT NOT NULL,
          voucherNo TEXT NOT NULL,
          accountId INTEGER,
          accountName TEXT NOT NULL,
          date TEXT NOT NULL,
          transactionType TEXT NOT NULL,
          debit REAL NOT NULL,
          credit REAL NOT NULL,
          balance REAL NOT NULL,
          status TEXT NOT NULL,
          description TEXT,
          referenceNo TEXT,
          category TEXT,
          tags TEXT,
          createdBy TEXT,
          createdAt TEXT NOT NULL,
          updatedAt TEXT NOT NULL,
          itemId INTEGER,
          itemName TEXT,
          itemPricePerUnit REAL,
          canWeight REAL,
          cansQuantity INTEGER,
          sellingPricePerCan REAL,
          balanceCans TEXT,
          receivedCans TEXT,
          paymentMethod TEXT DEFAULT 'cash',
          chequeNo TEXT,
          chequeAmount REAL,
          chequeDate TEXT,
          bankName TEXT,
          FOREIGN KEY (ledgerNo) REFERENCES ledger(ledgerNo)
        )
      ''');
      } else {
        // Table already exists → ensure all required columns exist
        final columns = await db.rawQuery('PRAGMA table_info($tableName)');
        final existing = columns.map((e) => e['name'] as String).toSet();

        // Define new columns that might be missing
        final newColumns = <String, String>{
          'paymentMethod': "TEXT DEFAULT 'cash'",
          'chequeNo': 'TEXT',
          'chequeAmount': 'REAL',
          'chequeDate': 'TEXT',
          'bankName': 'TEXT',
        };

        // Add only missing columns (avoids "duplicate column" error)
        for (final entry in newColumns.entries) {
          if (!existing.contains(entry.key)) {
            await db.execute(
              'ALTER TABLE $tableName ADD COLUMN ${entry.key} ${entry.value}',
            );
          }
        }

        // Set default payment method for existing rows
        await db.rawUpdate('''
        UPDATE $tableName
        SET paymentMethod = COALESCE(paymentMethod, 'cash'),
            chequeNo = COALESCE(chequeNo, NULL),
            chequeAmount = COALESCE(chequeAmount, NULL),
            chequeDate = COALESCE(chequeDate, NULL),
            bankName = COALESCE(bankName, NULL)
      ''');
      }
    } catch (e) {
      debugPrint('Error creating or updating $tableName: $e');
      rethrow;
    }
  }

  Future<void> createItemLedgerEntryTable(String ledgerNo) async {
    final db = await database;
    final safeLedgerNo = _sanitizeIdentifier(ledgerNo);
    final tableName = 'item_ledger_entries_$safeLedgerNo';

    try {
      // Check if table exists first
      final tableExists = await db.rawQuery(
        '''
      SELECT name FROM sqlite_master
      WHERE type='table' AND name=?
    ''',
        [tableName],
      );

      // Only create table if it doesn't exist
      if (tableExists.isEmpty) {
        await db.execute('''
      CREATE TABLE $tableName (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        ledgerNo TEXT NOT NULL,
        voucherNo TEXT NOT NULL,
        itemId INTEGER,
        itemName TEXT NOT NULL,
        vendorName TEXT NOT NULL,
        transactionType TEXT NOT NULL,
        debit REAL NOT NULL,
        pricePerKg REAL NOT NULL,
        costPrice REAL NOT NULL,
        sellingPrice REAL NOT NULL,
        canWeight REAL NOT NULL,
        credit REAL NOT NULL,
        newStock REAL NOT NULL,
        balance REAL NOT NULL,
        createdAt INTEGER NOT NULL,
        updatedAt INTEGER NOT NULL
      )
    ''');
      }
      // If table exists, do nothing - preserve existing data
    } catch (e) {
      rethrow;
    }
  }

  // New: Transaction wrapper for atomic operations (use this in saveAllLedgerEntries)
  Future<T> runInTransaction<T>(
    Future<T> Function(Transaction txn) action,
  ) async {
    final db = await database;
    return await db.transaction(action);
  }

  // Updated: Support for transaction in updateLedgerDebtOrCred
  Future<void> updateLedgerDebtOrCred(
    String flag,
    String ledgerNo,
    double value, [
    Transaction? txn,
  ]) async {
    if (flag != 'debit' && flag != 'credit') {
      throw Exception('Invalid column name');
    }

    final executor = txn ?? await database;

    final result = await executor.rawQuery(
      'SELECT $flag FROM ledger WHERE ledgerNo = ?',
      [ledgerNo],
    );

    final previousValue = (result.isNotEmpty && result.first[flag] != null)
        ? (result.first[flag] as num).toDouble()
        : 0.0;

    final newValue = previousValue + value;

    await executor.rawUpdate('UPDATE ledger SET $flag = ? WHERE ledgerNo = ?', [
      newValue,
      ledgerNo,
    ]);
  }

  // Example: Add txn support to other methods as needed (e.g., insertLedgerEntry would go here if defined)
  // Future<void> insertLedgerEntry(Map<String, dynamic> entry, String ledgerNo, [Transaction? txn]) async { ... }

  // Sanitize any string intended to be used in a SQL identifier
  String _sanitizeIdentifier(String input) {
    return input.replaceAll(RegExp(r'[^A-Za-z0-9_]'), '_');
  }

  // 1. Function to count Total Sales
  Future<double> getTotalSales() async {
    final db = await database;
    try {
      final result = await db.rawQuery('''
      SELECT
        SUM(debit) AS total_debit,
        SUM(credit) AS total_credit
      FROM ledger
    ''');

      if (result.isNotEmpty) {
        final row = result.first;
        final totalDebit = (row['total_debit'] as num?)?.toDouble() ?? 0.0;
        final totalCredit = (row['total_credit'] as num?)?.toDouble() ?? 0.0;

        return totalDebit + totalCredit;
      }

      return 0.0;
    } catch (e) {
      print('Error getting total debit and credit: $e');
      return 0.0;
    }
  }

  // 2. Function to count all Receivables
  Future<double> getTotalReceivables() async {
    final db = await database;

    try {
      // Fetch all ledger tables
      final tables = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name LIKE 'ledger_entries_%'",
      );

      double totalCredit = 0.0;
      double totalDebit = 0.0;

      for (final table in tables) {
        final tableName = table['name'] as String;

        // --- FETCH TOTAL CREDIT ---
        final creditResult = await db.rawQuery('''
        SELECT SUM(credit) AS total_credit
        FROM $tableName
        WHERE credit > 0
      ''');

        if (creditResult.isNotEmpty) {
          final credit = creditResult.first['total_credit'] as num?;
          totalCredit += (credit ?? 0).toDouble();
        }

        // --- FETCH TOTAL DEBIT ---
        final debitResult = await db.rawQuery('''
        SELECT SUM(debit) AS total_debit
        FROM $tableName
        WHERE debit > 0
      ''');

        if (debitResult.isNotEmpty) {
          final debit = debitResult.first['total_debit'] as num?;
          totalDebit += (debit ?? 0).toDouble();
        }
      }

      // Return Credit − Debit (Receivables)
      return totalCredit - totalDebit;
    } catch (e) {
      print('Error getting total receivables: $e');
      return 0.0;
    }
  }

  // 3. Function to get top three inventory items ordered by available stock ASC (lowest stock first)
  Future<List<Item>> getTopThreeLowestStockItems() async {
    final db = await database;
    try {
      final result = await db.rawQuery('''
      SELECT * FROM item
      WHERE availableStock > 0
      ORDER BY availableStock ASC
      LIMIT 3
    ''');

      // Returns empty list if no matching items found (already handled by map.toList())
      return result.map((map) => Item.fromMap(map)).toList();
    } catch (e) {
      print('Error getting top three lowest stock items: $e');
      return [];
    }
  }

  // 4. Function to get total expenses filtered by period (daily, weekly, monthly)
  Future<Map<String, double>> getExpenseTotals() async {
    final db = await database;
    try {
      final now = DateTime.now();

      // Daily: Today
      final todayStart = DateTime(now.year, now.month, now.day);
      final todayEnd = todayStart.add(const Duration(days: 1));
      final dailyResult = await db.rawQuery(
        '''
        SELECT SUM(amount) as total
        FROM expense_purchases
        WHERE date >= ? AND date < ?
      ''',
        [todayStart.millisecondsSinceEpoch, todayEnd.millisecondsSinceEpoch],
      );

      // Weekly: Last 7 days
      final weekStart = now.subtract(const Duration(days: 7));
      final weekEnd = now;
      final weeklyResult = await db.rawQuery(
        '''
        SELECT SUM(amount) as total
        FROM expense_purchases
        WHERE date >= ? AND date <= ?
      ''',
        [weekStart.millisecondsSinceEpoch, weekEnd.millisecondsSinceEpoch],
      );

      // Monthly: Current month
      final monthStart = DateTime(now.year, now.month, 1);
      final monthEnd = DateTime(
        now.year,
        now.month + 1,
        0,
      ).add(const Duration(days: 1));
      final monthlyResult = await db.rawQuery(
        '''
        SELECT SUM(amount) as total
        FROM expense_purchases
        WHERE date >= ? AND date < ?
      ''',
        [monthStart.millisecondsSinceEpoch, monthEnd.millisecondsSinceEpoch],
      );

      final dailyTotal = (dailyResult.isNotEmpty
          ? (dailyResult.first['total'] as num?)?.toDouble() ?? 0.0
          : 0.0);
      final weeklyTotal = (weeklyResult.isNotEmpty
          ? (weeklyResult.first['total'] as num?)?.toDouble() ?? 0.0
          : 0.0);
      final monthlyTotal = (monthlyResult.isNotEmpty
          ? (monthlyResult.first['total'] as num?)?.toDouble() ?? 0.0
          : 0.0);
      return {
        'Daily': dailyTotal,
        'Weekly': weeklyTotal,
        'Monthly': monthlyTotal,
      };
    } catch (e) {
      print('Error getting expense totals: $e');
      return {'daily': 0.0, 'weekly': 0.0, 'monthly': 0.0};
    }
  }

  Future<List<Map<String, dynamic>>> fetchExpenseBreakdown() async {
    final db = await database;
    final result = await db.rawQuery('''
            SELECT
              CASE
                WHEN category IS NULL OR TRIM(category) = '' THEN 'General'
                ELSE category
              END AS category,
              SUM(amount) AS total
            FROM expense_purchases
            GROUP BY
              CASE
                WHEN category IS NULL OR TRIM(category) = '' THEN 'General'
                ELSE category
              END;
                ''');
    return result;
  }

  Future<List<Map<String, dynamic>>> fetchSalesTrendBetweenMonths(
    String startMonth,
    String endMonth, {
    String type = 'debit', // 'debit', 'credit', or 'both'
  }) async {
    final db = await database;
    try {
      // Validate type
      if (!['debit', 'credit', 'both'].contains(type)) {
        type = 'debit';
      }

      // Get all ledger tables
      final tablesResult = await db.rawQuery('''
      SELECT name FROM sqlite_master
      WHERE type = 'table' AND name LIKE 'ledger_entries_%'
    ''');

      if (tablesResult.isEmpty) return [];

      // Build column selection based on type
      final String amountColumn = type == 'both'
          ? 'COALESCE(credit, 0) + COALESCE(debit, 0)'
          : type == 'credit'
          ? 'COALESCE(credit, 0)'
          : 'COALESCE(debit, 0)';

      final String whereCondition = type == 'both'
          ? '(debit IS NOT NULL AND debit > 0 OR credit IS NOT NULL AND credit > 0)'
          : type == 'credit'
          ? 'credit IS NOT NULL AND credit > 0'
          : 'debit IS NOT NULL AND debit > 0';

      // Union all relevant data from every partition
      final unionQueries = tablesResult
          .map((t) {
            final tableName = t['name'] as String;
            return '''
        SELECT
          CASE
            WHEN date IS NULL THEN NULL
            WHEN typeof(date) = 'integer' THEN strftime('%Y-%m', datetime(date / 1000, 'unixepoch'))
            WHEN date GLOB '[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]*' THEN substr(date, 1, 7)
            WHEN date GLOB '[0-9][0-9]/[0-9][0-9]/[0-9][0-9][0-9][0-9]' THEN substr(date, 7, 4) || '-' || substr(date, 4, 2)
            ELSE NULL
          END AS month,
          $amountColumn AS amount
        FROM `$tableName`
        WHERE month IS NOT NULL
          AND month BETWEEN ? AND ?
          AND $whereCondition
      ''';
          })
          .join(' UNION ALL ');

      if (unionQueries.trim().isEmpty) return [];

      // Final query with recursive month generation + totals
      final query =
          '''
      WITH RECURSIVE months(m) AS (
        SELECT ?
        UNION ALL
        SELECT strftime('%Y-%m', date(m || '-01', '+1 month'))
        FROM months
        WHERE m < ?
      ),
      raw_data AS ($unionQueries)
      SELECT
        m AS month,
        COALESCE(SUM(amount), 0) AS total_sales
      FROM months
      LEFT JOIN raw_data ON raw_data.month = months.m
      GROUP BY m
      ORDER BY m ASC
    ''';

      final result = await db.rawQuery(query, [
        startMonth,
        endMonth,
        startMonth,
        endMonth,
      ]);

      return result
          .map(
            (row) => {
              'month': row['month'] as String,
              'total_sales': (row['total_sales'] as num).toDouble(),
            },
          )
          .toList();
    } catch (e, s) {
      debugPrint('Error in fetchSalesTrendBetweenMonths: $e\n$s');
      return [];
    }
  }
}
