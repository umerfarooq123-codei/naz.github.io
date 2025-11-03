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
        ntnNo TEXT
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
  }

  Future<void> createLedgerEntryTable(String ledgerNo) async {
    final db = await database;
    final safeLedgerNo = _sanitizeIdentifier(ledgerNo);
    final tableName = 'ledger_entries_$safeLedgerNo';

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
          FOREIGN KEY (ledgerNo) REFERENCES ledger(ledgerNo)
        )
      ''');
      }
      // If table exists, do nothing - preserve existing data
    } catch (e) {
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
        transactionType TEXT NOT NULL,
        debit REAL NOT NULL,
        credit REAL NOT NULL,
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

  Future<void> updateLedgerDebtOrCred(
    String flag,
    String ledgerNo,
    double value,
  ) async {
    if (flag != 'debit' && flag != 'credit') {
      throw Exception('Invalid column name');
    }

    final db = await database;

    final result = await db.rawQuery(
      'SELECT $flag FROM ledger WHERE ledgerNo = ?',
      [ledgerNo],
    );

    final previousValue = (result.isNotEmpty && result.first[flag] != null)
        ? (result.first[flag] as num).toDouble()
        : 0.0;

    final newValue = previousValue + value;

    await db.rawUpdate('UPDATE ledger SET $flag = ? WHERE ledgerNo = ?', [
      newValue,
      ledgerNo,
    ]);
  }

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
      // Get all ledger tables
      final tables = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name LIKE 'ledger_entries_%'",
      );

      double totalReceivables = 0.0;

      // Sum balances from all ledger entry tables
      for (final table in tables) {
        final tableName = table['name'] as String;
        final result = await db.rawQuery('''
          SELECT SUM(credit) as total_balance
          FROM $tableName
          WHERE credit > 0
        ''');

        if (result.isNotEmpty) {
          final balance = result.first['total_balance'] as double?;
          totalReceivables += balance ?? 0.0;
        }
      }
      return totalReceivables;
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

      return result.map((map) => Item.fromMap(map)).toList();
    } catch (e) {
      print('Error getting top three lowest stock items: $e');
      return [];
    }
  }
}
