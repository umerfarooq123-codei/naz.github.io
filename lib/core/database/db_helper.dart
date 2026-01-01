import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:ledger_master/core/models/customer.dart';
import 'package:ledger_master/core/models/item.dart';
import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class DBHelper {
  static final DBHelper _instance = DBHelper._internal();
  factory DBHelper() => _instance;
  DBHelper._internal();
  final int version = 4; // Incremented version to update cans table schema
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

    // Create cans table
    await db.execute('''
      CREATE TABLE cans (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        accountName TEXT NOT NULL,
        accountId INTEGER,
        openingBalanceCans REAL NOT NULL DEFAULT 0,
        currentCans REAL NOT NULL DEFAULT 0,
        totalCans REAL NOT NULL DEFAULT 0,
        receivedCans REAL NOT NULL DEFAULT 0,
        insertedDate TEXT NOT NULL,
        updatedDate TEXT NOT NULL,
        UNIQUE(accountId, accountName)
      )
    ''');

    // Create cans_entries table
    await db.execute('''
      CREATE TABLE cans_entries (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        cansId INTEGER NOT NULL,
        voucherNo TEXT NOT NULL,
        accountId INTEGER,
        accountName TEXT NOT NULL,
        date TEXT NOT NULL,
        transactionType TEXT NOT NULL,
        currentCans REAL NOT NULL DEFAULT 0,
        receivedCans REAL NOT NULL DEFAULT 0,
        balance REAL NOT NULL DEFAULT 0,
        description TEXT,
        createdAt TEXT NOT NULL,
        updatedAt TEXT NOT NULL,
        FOREIGN KEY(cansId) REFERENCES cans(id) ON DELETE CASCADE
      )
    ''');

    // Create vendor_ledger_entries table (for tracking vendor transactions)
    await db.execute('''
      CREATE TABLE vendor_ledger_entries (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        voucherNo TEXT NOT NULL,
        vendorName TEXT NOT NULL,
        vendorId INTEGER NOT NULL,
        date TEXT NOT NULL,
        description TEXT,
        debit REAL NOT NULL DEFAULT 0.0,
        credit REAL NOT NULL DEFAULT 0.0,
        balance REAL NOT NULL DEFAULT 0.0,
        transactionType TEXT NOT NULL,
        paymentMethod TEXT,
        chequeNo TEXT,
        chequeAmount REAL,
        chequeDate TEXT,
        bankName TEXT,
        createdAt TEXT NOT NULL,
        updatedAt TEXT NOT NULL
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
      // Auto-detect current month in 'YYYY-MM' format
      final now = DateTime.now(); // e.g., 2025-12-29
      final currentMonth =
          '${now.year}-${now.month.toString().padLeft(2, '0')}'; // '2025-12'

      // Get all ledger entry tables
      final tablesResult = await db.rawQuery('''
      SELECT name FROM sqlite_master
      WHERE type = 'table' AND name LIKE 'ledger_entries_%'
    ''');

      if (tablesResult.isEmpty) return 0.0;

      double totalSales = 0.0;

      // Loop through each ledger table
      for (final table in tablesResult) {
        final tableName = table['name'] as String;

        final result = await db.rawQuery(
          '''
        SELECT SUM(COALESCE(debit, 0) + COALESCE(credit, 0)) AS monthly_total
        FROM `$tableName`
        WHERE (
          CASE
            WHEN typeof(date) = 'integer' THEN strftime('%Y-%m', datetime(date / 1000, 'unixepoch'))
            WHEN date GLOB '[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]*' THEN substr(date, 1, 7)
            WHEN date GLOB '[0-9][0-9]/[0-9][0-9]/[0-9][0-9][0-9][0-9]' THEN substr(date, 7, 4) || '-' || substr(date, 4, 2)
            ELSE NULL
          END
        ) = ?
          AND (debit > 0 OR credit > 0)
      ''',
          [currentMonth],
        );

        if (result.isNotEmpty && result.first['monthly_total'] != null) {
          totalSales += (result.first['monthly_total'] as num).toDouble();
        }
      }

      return totalSales;
    } catch (e) {
      debugPrint('Error calculating total sales for current month: $e');
      return 0.0;
    }
  }

  // 2. Function to count all Receivables (sum of all customer balances)
  // Formula: Same as Net Balance = ((General Ledger Credit + Customer Ledger Credit + Opening) - Customer Ledger Debit)
  Future<double> getTotalReceivables() async {
    final db = await database;

    try {
      double totalReceivables = 0.0;

      // Get all customers to calculate their individual balances
      final customerResult = await db.query('customer');
      final customers = customerResult.map((e) => Customer.fromMap(e)).toList();

      for (final customer in customers) {
        // Fetch opening balance (already non-nullable in Customer model)
        final openingBalance = customer.openingBalance;

        // 1. Fetch from GENERAL LEDGER (all ledger_entries_* tables)
        double generalLedgerCredit = 0.0;

        // Get all ledger entry tables
        final tablesResult = await db.rawQuery('''
          SELECT name FROM sqlite_master
          WHERE type='table' AND name LIKE 'ledger_entries_%'
        ''');

        for (final tableRow in tablesResult) {
          final tableName = tableRow['name'] as String;

          // For each ledger_entries_* table, check if it has entries for this customer
          final result = await db.rawQuery(
            '''
            SELECT COALESCE(SUM(CASE WHEN credit > 0 THEN credit ELSE 0 END), 0) as totalCredit
            FROM $tableName
            WHERE UPPER(accountName) = UPPER(?)
          ''',
            [customer.name],
          );

          if (result.isNotEmpty) {
            final credit =
                (result.first['totalCredit'] as num?)?.toDouble() ?? 0.0;
            print('📊 $tableName credit for ${customer.name}: $credit');
            generalLedgerCredit += credit;
          }
        }

        // If no ledger_entries tables found, try querying main ledger table instead
        if (tablesResult.isEmpty) {
          print(
            '📊 No ledger_entries_* tables found, querying main ledger table',
          );
          final mainResult = await db.rawQuery(
            '''
            SELECT COALESCE(SUM(CASE WHEN credit > 0 THEN credit ELSE 0 END), 0) as totalCredit
            FROM ledger
            WHERE UPPER(accountName) = UPPER(?)
          ''',
            [customer.name],
          );

          if (mainResult.isNotEmpty) {
            generalLedgerCredit =
                (mainResult.first['totalCredit'] as num?)?.toDouble() ?? 0.0;
            print(
              '📊 Main ledger credit for ${customer.name}: $generalLedgerCredit',
            );
          }
        }

        // 2. Fetch from CUSTOMER LEDGER (customer_ledger_entries_* tables)
        final custTableName = _sanitizeTableName(customer.name, customer.id!);

        // Check if customer ledger table exists before querying
        final tableExists = await db.rawQuery(
          '''SELECT name FROM sqlite_master WHERE type='table' AND name=?''',
          [custTableName],
        );

        double custDebit = 0.0;
        double custCredit = 0.0;

        if (tableExists.isNotEmpty) {
          final custResult = await db.rawQuery('''
            SELECT
              COALESCE(SUM(CASE WHEN debit > 0 THEN debit ELSE 0 END), 0) as totalDebit,
              COALESCE(SUM(CASE WHEN credit > 0 THEN credit ELSE 0 END), 0) as totalCredit
            FROM $custTableName
          ''');

          if (custResult.isNotEmpty) {
            custDebit =
                (custResult.first['totalDebit'] as num?)?.toDouble() ?? 0.0;
            custCredit =
                (custResult.first['totalCredit'] as num?)?.toDouble() ?? 0.0;
          }
        }

        // Calculate balance using SAME formula as Net Balance:
        // (General Ledger Credit + Customer Ledger Credit + Opening Balance) - Customer Ledger Debit
        final totalCredit = generalLedgerCredit + custCredit;
        final balance = (totalCredit + openingBalance - custDebit).clamp(
          0,
          double.infinity,
        );

        totalReceivables += balance;
      }

      return totalReceivables;
    } catch (e) {
      print('Error getting total receivables: $e');
      return 0.0;
    }
  }

  String _sanitizeTableName(String customerName, int customerId) {
    final safeName = customerName.replaceAll(RegExp(r'[^A-Za-z0-9_]'), '_');
    return 'customer_ledger_entries_${safeName}_$customerId';
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
    String type = 'both', // 'debit', 'credit', or 'both'
  }) async {
    final db = await database;
    try {
      if (!['debit', 'credit', 'both'].contains(type)) {
        type = 'both';
      }

      // Get all ledger entry tables
      final tablesResult = await db.rawQuery('''
      SELECT name FROM sqlite_master
      WHERE type = 'table' AND name LIKE 'ledger_entries_%'
    ''');

      if (tablesResult.isEmpty) return [];

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

      // Build list of individual SELECT queries
      final List<String> selectQueries = [];
      for (final t in tablesResult) {
        final tableName = t['name'] as String;
        selectQueries.add('''
        SELECT
          CASE
            WHEN date IS NULL THEN NULL
            WHEN typeof(date) = 'integer' THEN strftime('%Y-%m', datetime(date / 1000, 'unixepoch'))
            WHEN date GLOB '[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]*' THEN substr(date, 1, 7)
            WHEN date GLOB '[0-9][0-9]/[0-9]/[0-9][0-9][0-9][0-9][0-9]' THEN substr(date, 7, 4) || '-' || substr(date, 4, 2)
            ELSE NULL
          END AS month,
          $amountColumn AS amount
        FROM `$tableName`
        WHERE month IS NOT NULL
          AND month BETWEEN ? AND ?
          AND $whereCondition
      ''');
      }

      if (selectQueries.isEmpty) return [];

      final String unionQueries = selectQueries.join(' UNION ALL ');

      // Build final query
      final String query =
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

      // Build arguments list: first two for CTE, then two for EACH table
      final List<Object?> args = [startMonth, endMonth];
      for (int i = 0; i < tablesResult.length; i++) {
        args.add(startMonth);
        args.add(endMonth);
      }

      final result = await db.rawQuery(query, args);

      return result
          .map(
            (row) => {
              'month': row['month'] as String?,
              'total_sales': (row['total_sales'] as num?)?.toDouble() ?? 0.0,
            },
          )
          .toList();
    } catch (e, s) {
      debugPrint('Error in fetchSalesTrendBetweenMonths: $e\n$s');
      return [];
    }
  }
}
