import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class DBHelper {
  static final DBHelper _instance = DBHelper._internal();
  factory DBHelper() => _instance;
  DBHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  Future<Database> _initDB() async {
    // Optional: initialize FFI on desktops if not set in main()
    // This is safe to call multiple times.
    try {
      sqfliteFfiInit();
    } catch (_) {}

    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'ledger_app.db');

    return await openDatabase(
      path,
      version: 10,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
      onDowngrade: _onDowngrade,
    );
  }

  Future _onDowngrade(Database db, int oldVersion, int newVersion) async {
    await _onUpgrade(db, oldVersion, newVersion);
  }

  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 8) {
      // Clean up unwanted tables and validate schemas
      await _cleanupDatabase(db);

      // Add new columns to ledger_entries tables
      await _upgradeLedgerEntriesTables(db);
    }
  }

  Future<void> _upgradeLedgerEntriesTables(Database db) async {
    try {
      // Get all ledger entry tables
      final tables = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name LIKE 'ledger_entries_%'",
      );

      for (final table in tables) {
        final tableName = table['name'] as String;

        // Check if columns already exist
        final tableInfo = await db.rawQuery("PRAGMA table_info($tableName)");
        final columnNames = tableInfo
            .map((col) => col['name'] as String)
            .toList();

        if (!columnNames.contains('itemId')) {
          await db.execute('ALTER TABLE $tableName ADD COLUMN itemId INTEGER');
        }
        if (!columnNames.contains('itemName')) {
          await db.execute('ALTER TABLE $tableName ADD COLUMN itemName TEXT');
        }
        if (!columnNames.contains('itemPricePerUnit')) {
          await db.execute(
            'ALTER TABLE $tableName ADD COLUMN itemPricePerUnit REAL',
          );
        }
        if (!columnNames.contains('canWeight')) {
          await db.execute('ALTER TABLE $tableName ADD COLUMN canWeight REAL');
        }
        if (!columnNames.contains('cansQuantity')) {
          await db.execute(
            'ALTER TABLE $tableName ADD COLUMN cansQuantity INTEGER',
          );
        }
        if (!columnNames.contains('sellingPricePerCan')) {
          await db.execute(
            'ALTER TABLE $tableName ADD COLUMN sellingPricePerCan REAL',
          );
        }
      }
    } catch (e) {
      // In production consider logging to a crash reporting service
    }
  }

  Future _onCreate(Database db, int version) async {
    // Ledger table
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

    // Customer table
    await db.execute('''
      CREATE TABLE customer(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        address TEXT NOT NULL,
        customerNo TEXT NOT NULL,
        mobileNo TEXT NOT NULL,
        ntnNo TEXT
      )
    ''');

    // Item table
    await db.execute('''
      CREATE TABLE item(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        type TEXT NOT NULL,
        pricePerKg REAL NOT NULL,
        costPrice REAL NOT NULL,
        sellingPrice REAL NOT NULL,
        availableStock REAL NOT NULL,
        canWeight REAL NOT NULL
      )
    ''');

    // Stock transaction table
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

  Future<void> _cleanupDatabase(Database db) async {
    // List of all tables that should exist in the database
    final List<String> expectedTables = [
      'ledger',
      'customer',
      'item',
      'stock_transaction',
    ];

    // Get all tables in the database
    final tables = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table'",
    );

    for (final table in tables) {
      final tableName = table['name'] as String;

      // Skip system tables
      if (tableName == 'sqlite_sequence') continue;

      // Check if it's a ledger_entries table (these are dynamic and should be kept)
      if (tableName.startsWith('ledger_entries_')) {
        // Validate the schema of ledger_entries tables
        await _validateLedgerEntriesSchema(db, tableName);
        continue;
      }

      // Check if table is in our expected list
      if (!expectedTables.contains(tableName)) {
        // Drop unwanted table
        await db.execute('DROP TABLE IF EXISTS $tableName');
      } else {
        // Validate schema of expected tables
        await _validateTableSchema(db, tableName);
      }
    }
  }

  Future<void> _validateTableSchema(Database db, String tableName) async {
    final tableInfo = await db.rawQuery("PRAGMA table_info($tableName)");
    final columnNames = tableInfo.map((col) => col['name'] as String).toList();

    // Define expected schemas for each table
    final Map<String, List<String>> expectedSchemas = {
      'ledger': [
        'id',
        'ledgerNo',
        'accountId',
        'accountName',
        'transactionType',
        'debit',
        'credit',
        'date',
        'description',
        'referenceNumber',
        'transactionId',
        'createdAt',
        'updatedAt',
        'createdBy',
        'category',
        'tags',
        'voucherNo',
        'balance',
        'status',
      ],
      'customer': ['id', 'name', 'address', 'customerNo', 'mobileNo', 'ntnNo'],
      'item': [
        'id',
        'name',
        'type',
        'pricePerKg',
        'costPrice',
        'sellingPrice',
        'availableStock',
        'canWeight',
      ],
      'stock_transaction': ['id', 'itemId', 'quantity', 'date', 'type'],
    };

    final expectedColumns = expectedSchemas[tableName];
    if (expectedColumns == null) return;

    // Check for missing columns
    for (final column in expectedColumns) {
      if (!columnNames.contains(column)) {
        await _migrateTableData(db, tableName);
        return;
      }
    }

    // Check for extra columns
    for (final column in columnNames) {
      if (!expectedColumns.contains(column)) {
        await _migrateTableData(db, tableName);
        return;
      }
    }
  }

  Future<void> _migrateTableData(Database db, String tableName) async {
    try {
      // Backup existing data
      final oldData = await db.query(tableName);

      // Create temporary table with old data
      final tempTableName = 'temp_${DateTime.now().millisecondsSinceEpoch}';

      // Create temp table with same structure
      final tableInfo = await db.rawQuery("PRAGMA table_info($tableName)");
      final columns = tableInfo
          .map(
            (col) =>
                '${col['name']} ${col['type']}${col['pk'] == 1 ? ' PRIMARY KEY' : ''}',
          )
          .join(', ');

      await db.execute('CREATE TABLE $tempTableName ($columns)');

      // Copy data to temp table
      for (final row in oldData) {
        final cols = row.keys.join(', ');
        final values = row.values
            .map(
              (v) => v is String
                  ? "'${v.replaceAll("'", "''")}'"
                  : v?.toString() ?? 'NULL',
            )
            .join(', ');

        await db.execute('INSERT INTO $tempTableName ($cols) VALUES ($values)');
      }

      // Drop original table
      await db.execute('DROP TABLE IF EXISTS $tableName');

      // Recreate table with correct schema
      if (tableName == 'ledger') {
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
      } else if (tableName == 'customer') {
        await db.execute('''
          CREATE TABLE customer(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            address TEXT NOT NULL,
            customerNo TEXT NOT NULL,
            mobileNo TEXT NOT NULL,
            ntnNo TEXT
          )
        ''');
      } else if (tableName == 'item') {
        await db.execute('''
          CREATE TABLE item(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            type TEXT NOT NULL,
            pricePerKg REAL NOT NULL,
            costPrice REAL NOT NULL,
            sellingPrice REAL NOT NULL,
            availableStock REAL NOT NULL,
            canWeight REAL NOT NULL
          )
        ''');
      } else if (tableName == 'stock_transaction') {
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

      // Migrate data back from temp table
      final newTableInfo = await db.rawQuery("PRAGMA table_info($tableName)");
      final newColumns = newTableInfo
          .map((col) => col['name'] as String)
          .toList();

      for (final row in oldData) {
        final validData = Map<String, dynamic>.fromEntries(
          row.entries.where((entry) => newColumns.contains(entry.key)),
        );

        if (validData.isNotEmpty) {
          await db.insert(tableName, validData);
        }
      }

      // Drop temporary table
      await db.execute('DROP TABLE IF EXISTS $tempTableName');
    } catch (e) {
      // If migration fails, recreate table without data
      await _recreateTableWithoutData(db, tableName);
    }
  }

  Future<void> _recreateTableWithoutData(Database db, String tableName) async {
    await db.execute('DROP TABLE IF EXISTS $tableName');

    if (tableName == 'ledger') {
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
    } else if (tableName == 'customer') {
      await db.execute('''
        CREATE TABLE customer(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          address TEXT NOT NULL,
          customerNo TEXT NOT NULL,
          mobileNo TEXT NOT NULL,
          ntnNo TEXT
        )
      ''');
    } else if (tableName == 'item') {
      await db.execute('''
        CREATE TABLE item(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          type TEXT NOT NULL,
          pricePerKg REAL NOT NULL,
          costPrice REAL NOT NULL,
          sellingPrice REAL NOT NULL,
          availableStock REAL NOT NULL,
          canWeight REAL NOT NULL
        )
      ''');
    } else if (tableName == 'stock_transaction') {
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
  }

  Future<void> _validateLedgerEntriesSchema(
    Database db,
    String tableName,
  ) async {
    final tableInfo = await db.rawQuery("PRAGMA table_info($tableName)");
    final columnNames = tableInfo.map((col) => col['name'] as String).toList();

    // Expected schema for ledger_entries tables
    final List<String> expectedColumns = [
      'id',
      'ledgerNo',
      'voucherNo',
      'accountId',
      'accountName',
      'date',
      'transactionType',
      'debit',
      'credit',
      'balance',
      'status',
      'description',
      'referenceNo',
      'category',
      'tags',
      'createdBy',
      'createdAt',
      'updatedAt',
      'itemId',
      'itemName',
      'itemPricePerUnit',
      'canWeight',
      'cansQuantity',
      'sellingPricePerCan',
    ];

    // Check for missing columns
    for (final column in expectedColumns) {
      if (!columnNames.contains(column)) {
        await _migrateLedgerEntriesTable(db, tableName);
        return;
      }
    }

    // Check for extra columns
    for (final column in columnNames) {
      if (!expectedColumns.contains(column)) {
        await _migrateLedgerEntriesTable(db, tableName);
        return;
      }
    }
  }

  Future<void> _migrateLedgerEntriesTable(Database db, String tableName) async {
    try {
      // Backup existing data
      final oldData = await db.query(tableName);

      // Create temporary table
      final tempTableName = 'temp_${DateTime.now().millisecondsSinceEpoch}';
      await db.execute('''
        CREATE TABLE $tempTableName (
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
          sellingPricePerCan REAL
        )
      ''');

      // Copy data to temp table
      for (final row in oldData) {
        await db.insert(tempTableName, row);
      }

      // Drop original table
      await db.execute('DROP TABLE IF EXISTS $tableName');

      // Recreate table with correct schema
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
          FOREIGN KEY (ledgerNo) REFERENCES ledger(ledgerNo)
        )
      ''');

      // Migrate data back
      for (final row in oldData) {
        await db.insert(tableName, row);
      }

      // Drop temporary table
      await db.execute('DROP TABLE IF EXISTS $tempTableName');
    } catch (e) {
      // If migration fails, recreate table without data
      await db.execute('DROP TABLE IF EXISTS $tableName');
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
          FOREIGN KEY (ledgerNo) REFERENCES ledger(ledgerNo)
        )
      ''');
    }
  }

  // Sanitize any string intended to be used in a SQL identifier (e.g., table name)
  String _sanitizeIdentifier(String input) {
    // Allow only letters, numbers and underscore; replace others with underscore
    return input.replaceAll(RegExp(r'[^A-Za-z0-9_]'), '_');
  }

  Future<void> createLedgerEntryTable(String ledgerNo) async {
    final db = await database;
    final safeLedgerNo = _sanitizeIdentifier(ledgerNo);
    final tableName = 'ledger_entries_$safeLedgerNo';

    try {
      // Check if table already exists
      final tables = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name=?",
        [tableName],
      );

      if (tables.isEmpty) {
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
          sellingPricePerCan REAL
        )
      ''');
      }
    } catch (e) {
      rethrow;
    }
  }
}
