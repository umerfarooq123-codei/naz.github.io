import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:ledger_master/core/database/db_helper.dart';
import 'package:ledger_master/core/models/cans.dart';
import 'package:ledger_master/core/models/customer.dart';
import 'package:ledger_master/core/models/item.dart';
import 'package:ledger_master/core/models/ledger.dart';
import 'package:ledger_master/core/models/purchase.dart';
import 'package:ledger_master/core/models/vendor.dart';
import 'package:ledger_master/features/vendor_ledger/vendor_ledger_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class SheetSyncService extends GetxService {
  static const String webAppUrl =
      'https://script.google.com/macros/s/AKfycbwrmkv1ldSrrF_tsJe5RSp_p2DfhRtwTkIPiK_QOghUr-oXHsLzl5Gor377HpgF_GIdTw/exec';

  final DBHelper dbHelper = DBHelper();
  late SharedPreferences prefs;

  // Automatic sync timer
  Timer? syncTimer;

  // Reactive sync status
  final isSyncing = false.obs;
  final lastSyncTime = Rx<DateTime?>(null);
  final nextSyncTime = Rx<DateTime?>(null);
  final syncSettings = Rx<Map<String, dynamic>>({
    'hours': 0,
    'minutes': 0,
    'enabled': false,
  });

  // Import status
  final isImporting = false.obs;
  final lastImportTime = Rx<DateTime?>(null);
  final importProgress = Rx<Map<String, double>>({});

  // Table-to-model mapping
  final Map<String, dynamic Function(Map<String, dynamic>)> _modelConstructors =
      {
        'customer': (map) => Customer.fromMap(map),
        'vendor': (map) => Vendor.fromMap(map),
        'item': (map) => Item.fromMap(map),
        'ledger': (map) => Ledger.fromMap(map),
        'stock_transaction': (map) => StockTransaction.fromMap(map),
        'expense_purchases': (map) => ExpensePurchase.fromMap(map),
        'cans': (map) => Cans.fromMap(map),
        'cans_entries': (map) => CansEntry.fromMap(map),
      };

  // Ledger entry patterns (for dynamically named tables)
  final RegExp _customerLedgerPattern = RegExp(r'customer_ledger_entries_');
  final RegExp _vendorLedgerPattern = RegExp(r'vendor_ledger_entries');
  final RegExp _itemLedgerPattern = RegExp(r'item_ledger_entries_');
  final RegExp _ledgerEntryPattern = RegExp(r'ledger_entries_');

  @override
  void onInit() {
    super.onInit();
    initService();
  }

  @override
  void onClose() {
    stopAutoSync();
    super.onClose();
  }

  // ==================== SERVICE INITIALIZATION ====================

  Future<void> initService() async {
    await initPrefs();
    await loadSyncSettings();
    await loadLastSyncTime();
    await startAutoSync();
  }

  Future<void> initPrefs() async {
    prefs = await SharedPreferences.getInstance();
  }

  Future<void> loadSyncSettings() async {
    final settingsData = prefs.getString('backup_sync_settings');
    if (settingsData != null) {
      try {
        final map = jsonDecode(settingsData) as Map<String, dynamic>;
        syncSettings.value = {
          'hours': map['hours'] ?? 0,
          'minutes': map['minutes'] ?? 0,
          'enabled': map['enabled'] ?? false,
        };
      } catch (e) {
        debugPrint('Error loading sync settings: $e');
      }
    }
  }

  Future<void> loadLastSyncTime() async {
    final lastSyncString = prefs.getString('last_sync_time');
    if (lastSyncString != null) {
      try {
        lastSyncTime.value = DateTime.parse(lastSyncString);
      } catch (e) {
        debugPrint('Error parsing last sync time: $e');
      }
    }
  }

  Future<void> _saveLastSyncTime() async {
    final now = DateTime.now();
    lastSyncTime.value = now;
    await prefs.setString('last_sync_time', now.toIso8601String());
  }

  Future<void> _saveLastImportTime() async {
    final now = DateTime.now();
    lastImportTime.value = now;
    await prefs.setString('last_import_time', now.toIso8601String());
  }

  Future<void> loadLastImportTime() async {
    final lastImportString = prefs.getString('last_import_time');
    if (lastImportString != null) {
      try {
        lastImportTime.value = DateTime.parse(lastImportString);
      } catch (e) {
        debugPrint('Error parsing last import time: $e');
      }
    }
  }

  // ==================== IMPORT FUNCTIONALITY ====================

  /// Import all data from Google Sheets into local database
  /// This will clear the local database completely before importing
  Future<Map<String, dynamic>> importFromSheets() async {
    if (isImporting.value) {
      return {'success': false, 'message': 'Import already in progress'};
    }

    final stopwatch = Stopwatch()..start();

    try {
      isImporting.value = true;
      importProgress.value = {};

      // Check internet connection
      final hasInternet = await _checkInternetConnection();
      if (!hasInternet) {
        return {'success': false, 'error': 'No internet connection'};
      }

      debugPrint('🔄 Starting import from Google Sheets...');

      // Step 1: Get all tables from Google Sheets
      final tables = await _getSheetsTables();
      debugPrint('📋 Found ${tables.length} tables in Google Sheets');

      if (tables.isEmpty) {
        return {'success': false, 'error': 'No tables found in Google Sheets'};
      }

      // Step 2: Clear local database completely
      debugPrint('🧹 Clearing local database...');
      await _clearLocalDatabase();
      debugPrint('✅ Local database cleared');

      int importedCount = 0;
      int failedCount = 0;
      List<String> failedTables = [];

      // Step 3: Import each table
      for (int i = 0; i < tables.length; i++) {
        final tableName = tables[i];
        final progress = (i + 1) / tables.length;
        importProgress.value = {tableName: progress};

        try {
          debugPrint('📥 Importing table: $tableName');
          final success = await _importTable(tableName);

          if (success) {
            importedCount++;
            debugPrint('✅ Imported: $tableName');
          } else {
            failedCount++;
            failedTables.add(tableName);
            debugPrint('❌ Failed to import: $tableName');
          }
        } catch (e) {
          failedCount++;
          failedTables.add(tableName);
          debugPrint('❌ Error importing $tableName: $e');
        }
      }

      stopwatch.stop();

      // Update import time
      if (importedCount > 0) {
        await _saveLastImportTime();
      }

      // Clear progress
      importProgress.value = {};

      return {
        'success': failedCount == 0,
        'message':
            'Import completed: $importedCount imported, $failedCount failed',
        'imported': importedCount,
        'failed': failedCount,
        'failedTables': failedTables,
        'timeTaken': '${stopwatch.elapsed.inSeconds} seconds',
        'timestamp': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      stopwatch.stop();
      debugPrint('❌ Fatal import error: $e');
      importProgress.value = {};
      return {
        'success': false,
        'error': e.toString(),
        'timestamp': DateTime.now().toIso8601String(),
      };
    } finally {
      isImporting.value = false;
    }
  }

  /// Get list of all table names from Google Sheets
  Future<List<String>> _getSheetsTables() async {
    try {
      debugPrint('🌐 Requesting tables from Google Sheets...');

      final response = await _makeAppsScriptRequest(
        operation: 'get_all_tables',
      );

      debugPrint('📡 Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        try {
          final data = jsonDecode(response.body);
          if (data['success'] == true) {
            final tables = List<String>.from(data['tables'] ?? []);
            debugPrint(
              '✅ Retrieved ${tables.length} tables from Google Sheets',
            );
            return tables;
          } else {
            debugPrint('❌ Server returned success: false - ${data['message']}');
            return [];
          }
        } catch (e) {
          debugPrint('❌ JSON decode error: $e');
          debugPrint('❌ Response that failed to parse: ${response.body}');
          return [];
        }
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        debugPrint('❌ Authentication error (${response.statusCode})');
        Get.snackbar(
          'Authentication Error',
          'Please check your Google Sheets permissions',
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return [];
      } else {
        debugPrint('❌ HTTP error ${response.statusCode}');
        debugPrint('❌ Response: ${response.body}');
        return [];
      }
    } catch (e) {
      debugPrint('❌ Network error getting tables: $e');
      return [];
    }
  }

  /// Special method for Google Apps Script requests that handles redirects properly
  Future<http.Response> _makeAppsScriptRequest({
    required String operation,
    String? tableName,
    List<Map<String, dynamic>>? data,
    bool force = false,
  }) async {
    try {
      // Build the request body
      final requestBody = <String, dynamic>{'operation': operation};

      if (tableName != null) {
        requestBody['tableName'] = tableName;
      }

      if (data != null) {
        requestBody['data'] = data;
        debugPrint('📦 Data being sent: ${data.length} rows');

        // Debug: Show first row structure
        if (data.isNotEmpty) {
          debugPrint('📋 First row keys: ${data.first.keys.toList()}');
          debugPrint('📋 First row values: ${data.first.values.toList()}');
        }
      }

      if (force) {
        requestBody['force'] = true;
      }

      debugPrint('🌐 Making Apps Script request to: $webAppUrl');
      debugPrint(
        '📤 Operation: $operation, Table: $tableName, Data rows: ${data?.length ?? 0}',
      );

      // Use POST with proper JSON body
      final client = http.Client();

      final response = await client
          .post(
            Uri.parse(webAppUrl),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode(requestBody),
          )
          .timeout(const Duration(seconds: 60));

      // Handle redirects
      final maxRedirects = 5;
      int redirectCount = 0;
      var currentResponse = response;

      while ((currentResponse.statusCode == 302 ||
              currentResponse.statusCode == 301) &&
          redirectCount < maxRedirects) {
        redirectCount++;

        String? redirectUrl;

        // Get redirect URL from headers
        if (currentResponse.headers.containsKey('location')) {
          redirectUrl = currentResponse.headers['location'];
        }

        // If not in headers, try to parse from HTML
        if (redirectUrl == null && currentResponse.body.contains('href="')) {
          final regex = RegExp(r'href="([^"]+)"');
          final match = regex.firstMatch(currentResponse.body);
          if (match != null) {
            redirectUrl = match.group(1);
            // Decode HTML entities
            redirectUrl = redirectUrl?.replaceAll('&amp;', '&');
          }
        }

        if (redirectUrl != null) {
          debugPrint('🔄 Following redirect $redirectCount to: $redirectUrl');

          // For redirects, use GET
          currentResponse = await client
              .get(
                Uri.parse(redirectUrl),
                headers: {'Accept': 'application/json'},
              )
              .timeout(const Duration(seconds: 60));
        } else {
          break;
        }
      }

      client.close();

      debugPrint('📡 Response status: ${currentResponse.statusCode}');

      // Log response for debugging
      if (currentResponse.statusCode != 200) {
        debugPrint('❌ Response body: ${currentResponse.body}');
      } else {
        try {
          final responseData = jsonDecode(currentResponse.body);
          debugPrint('✅ Server response: ${responseData['message']}');
          if (responseData['actions'] != null) {
            debugPrint('📊 Actions: ${responseData['actions']}');
          }
        } catch (e) {
          debugPrint('⚠️ Could not parse successful response');
        }
      }

      return currentResponse;
    } catch (e) {
      debugPrint('❌ Apps Script request error: $e');
      rethrow;
    }
  }

  /// Clear local database completely
  Future<void> _clearLocalDatabase() async {
    try {
      final Database db = await dbHelper.database;

      // Get all user tables
      final tables = await getAllTableNames();

      // Drop all tables
      for (final table in tables) {
        try {
          await db.execute('DROP TABLE IF EXISTS "$table"');
          debugPrint('🗑️ Dropped table: $table');
        } catch (e) {
          debugPrint('Warning: Could not drop table $table: $e');
        }
      }

      // Also clear all stored hashes
      await _clearAllHashes();

      debugPrint('✅ Database cleared successfully');
    } catch (e) {
      debugPrint('Error clearing database: $e');
      rethrow;
    }
  }

  /// Clear all stored hashes
  Future<void> _clearAllHashes() async {
    await initPrefs();
    final keys = prefs.getKeys();
    for (final key in keys) {
      if (key.startsWith('hash_')) {
        await prefs.remove(key);
      }
    }
    await prefs.remove('failed_sync_attempts');
    debugPrint('🧹 Cleared all stored hashes');
  }

  /// Create table with dynamic columns
  Future<void> _createTable(String tableName, List<String> columns) async {
    try {
      final Database db = await dbHelper.database;

      // Build CREATE TABLE SQL
      final columnDefs = columns
          .map((column) {
            // Handle SQLite reserved words and special characters
            final safeColumn = '"$column"';
            return '$safeColumn TEXT';
          })
          .join(', ');

      final sql = 'CREATE TABLE "$tableName" ($columnDefs)';

      await db.execute(sql);
      debugPrint(
        '📄 Created table: $tableName with columns: ${columns.join(', ')}',
      );
    } catch (e) {
      debugPrint('Error creating table $tableName: $e');
      rethrow;
    }
  }

  /// Import a single table from Google Sheets using data models
  Future<bool> _importTable(String tableName) async {
    try {
      debugPrint('📥 Requesting data for table: $tableName');

      final response = await _makeAppsScriptRequest(
        operation: 'get_table_data',
        tableName: tableName,
      );

      debugPrint('📡 Table $tableName response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        try {
          final data = jsonDecode(response.body);

          if (data['success'] == true && data['data'] != null) {
            final tableData = List<Map<String, dynamic>>.from(data['data']);

            if (tableData.isEmpty) {
              debugPrint('📭 Table $tableName is empty');
              await _storeHash(tableName, 'empty');
              return true;
            }

            // Get column names from first row
            final firstRow = tableData.first;
            final columns = firstRow.keys.toList();

            debugPrint(
              '📊 Table $tableName has ${columns.length} columns: ${columns.join(', ')}',
            );
            debugPrint('📊 Table $tableName has ${tableData.length} rows');

            // Clean and prepare data with proper types using data models
            final cleanedData = await _convertToModelData(tableName, tableData);

            // Create table with dynamic schema
            await _createTable(tableName, columns);

            // Insert data
            await _insertTableData(tableName, cleanedData, columns);

            // Calculate and store hash
            final hash = await _calculateDataHash(cleanedData);
            await _storeHash(tableName, hash);

            debugPrint('✅ Imported ${tableData.length} rows to $tableName');
            return true;
          } else {
            debugPrint('❌ Server returned success: false for table $tableName');
            debugPrint('❌ Server message: ${data['message']}');
            return false;
          }
        } catch (e) {
          debugPrint('❌ JSON decode error for table $tableName: $e');
          // Log the problematic response
          if (response.body.length > 200) {
            debugPrint(
              '❌ Response snippet: ${response.body.substring(0, 200)}...',
            );
          } else {
            debugPrint('❌ Response: ${response.body}');
          }
          return false;
        }
      } else {
        debugPrint('❌ HTTP ${response.statusCode} for table: $tableName');
        debugPrint('❌ Response: ${response.body}');
        return false;
      }
    } catch (e) {
      debugPrint('❌ Error importing table $tableName: $e');
      return false;
    }
  }

  /// Convert raw data to proper model data
  Future<List<Map<String, dynamic>>> _convertToModelData(
    String tableName,
    List<Map<String, dynamic>> rawData,
  ) async {
    try {
      // Check if we have a model constructor for this table
      if (_modelConstructors.containsKey(tableName)) {
        debugPrint('🎯 Using model constructor for $tableName');
        return _convertUsingModel(tableName, rawData);
      }

      // Check for pattern matches (ledger entries)
      if (_customerLedgerPattern.hasMatch(tableName)) {
        debugPrint('🎯 Using CustomerLedgerEntry model for $tableName');
        return _convertToCustomerLedgerEntries(rawData);
      } else if (_vendorLedgerPattern.hasMatch(tableName)) {
        debugPrint('🎯 Using VendorLedgerEntry model for $tableName');
        return _convertToVendorLedgerEntries(rawData);
      } else if (_itemLedgerPattern.hasMatch(tableName)) {
        debugPrint('🎯 Using ItemLedgerEntry model for $tableName');
        return _convertToItemLedgerEntries(rawData);
      } else if (_ledgerEntryPattern.hasMatch(tableName)) {
        debugPrint('🎯 Using LedgerEntry model for $tableName');
        return _convertToLedgerEntries(rawData);
      }

      // Default: clean data without model conversion
      debugPrint(
        '⚠️ No specific model found for $tableName, using generic conversion',
      );
      return _cleanGenericData(rawData);
    } catch (e) {
      debugPrint('❌ Error converting data for $tableName: $e');
      // Fall back to generic conversion
      return _cleanGenericData(rawData);
    }
  }

  /// Convert using specific model constructor
  List<Map<String, dynamic>> _convertUsingModel(
    String tableName,
    List<Map<String, dynamic>> rawData,
  ) {
    final constructor = _modelConstructors[tableName]!;
    return rawData.map((row) {
      try {
        // Clean row first
        final cleanedRow = _cleanRow(row);
        // Convert using model
        final model = constructor(cleanedRow);
        // Convert model back to map
        return _modelToMap(model);
      } catch (e) {
        debugPrint('❌ Error converting row for $tableName: $e');
        debugPrint('❌ Problematic row: $row');
        // Return cleaned row as fallback
        return _cleanRow(row);
      }
    }).toList();
  }

  /// Convert to CustomerLedgerEntry objects
  List<Map<String, dynamic>> _convertToCustomerLedgerEntries(
    List<Map<String, dynamic>> rawData,
  ) {
    return rawData.map((row) {
      try {
        final cleanedRow = _cleanRow(row);
        final entry = CustomerLedgerEntry.fromMap(cleanedRow);
        return entry.toMap();
      } catch (e) {
        debugPrint('❌ Error converting to CustomerLedgerEntry: $e');
        return _cleanRow(row);
      }
    }).toList();
  }

  /// Convert to VendorLedgerEntry objects
  List<Map<String, dynamic>> _convertToVendorLedgerEntries(
    List<Map<String, dynamic>> rawData,
  ) {
    return rawData.map((row) {
      try {
        final cleanedRow = _cleanRow(row);
        final entry = VendorLedgerEntry.fromMap(cleanedRow);
        return entry.toMap();
      } catch (e) {
        debugPrint('❌ Error converting to VendorLedgerEntry: $e');
        return _cleanRow(row);
      }
    }).toList();
  }

  /// Convert to ItemLedgerEntry objects
  List<Map<String, dynamic>> _convertToItemLedgerEntries(
    List<Map<String, dynamic>> rawData,
  ) {
    return rawData.map((row) {
      try {
        final cleanedRow = _cleanRow(row);
        final entry = ItemLedgerEntry.fromMap(cleanedRow);
        return entry.toMap();
      } catch (e) {
        debugPrint('❌ Error converting to ItemLedgerEntry: $e');
        return _cleanRow(row);
      }
    }).toList();
  }

  /// Convert to LedgerEntry objects
  List<Map<String, dynamic>> _convertToLedgerEntries(
    List<Map<String, dynamic>> rawData,
  ) {
    return rawData.map((row) {
      try {
        final cleanedRow = _cleanRow(row);
        final entry = LedgerEntry.fromMap(cleanedRow);
        return entry.toMap();
      } catch (e) {
        debugPrint('❌ Error converting to LedgerEntry: $e');
        return _cleanRow(row);
      }
    }).toList();
  }

  /// Clean generic data without model conversion
  List<Map<String, dynamic>> _cleanGenericData(
    List<Map<String, dynamic>> rawData,
  ) {
    return rawData.map(_cleanRow).toList();
  }

  /// Clean a single row with type conversion
  Map<String, dynamic> _cleanRow(Map<String, dynamic> row) {
    final cleanedRow = <String, dynamic>{};

    for (final entry in row.entries) {
      final key = entry.key;
      final value = entry.value;

      // Handle null values
      if (value == null) {
        cleanedRow[key] = null;
        continue;
      }

      // Convert value based on key patterns
      cleanedRow[key] = _convertValue(key, value);
    }

    return cleanedRow;
  }

  /// Convert value based on key name patterns
  dynamic _convertValue(String key, dynamic value) {
    final String stringValue = value.toString();

    if (stringValue.isEmpty) return null;

    // ID fields
    if (key.endsWith('Id') || key == 'id') {
      return int.tryParse(stringValue);
    }

    // Numeric fields
    if (key.contains('balance') ||
        key.contains('Balance') ||
        key.contains('debit') ||
        key.contains('Debit') ||
        key.contains('credit') ||
        key.contains('Credit') ||
        key.contains('amount') ||
        key.contains('Amount') ||
        key.contains('price') ||
        key.contains('Price') ||
        key.contains('cost') ||
        key.contains('Cost') ||
        key.contains('quantity') ||
        key.contains('Quantity') ||
        key.contains('weight') ||
        key.contains('Weight') ||
        key.contains('stock') ||
        key.contains('Stock') ||
        key.contains('salary') ||
        key.contains('Salary') ||
        key.contains('dues') ||
        key.contains('opening') ||
        key.endsWith('PerKg') ||
        key.endsWith('PerUnit') ||
        key.endsWith('PerCan')) {
      return double.tryParse(stringValue);
    }

    // Boolean fields
    if (key == 'status' ||
        key.contains('is') ||
        key.contains('Is') ||
        key.contains('active') ||
        key.contains('Active') ||
        key.contains('cleared')) {
      final lowerValue = stringValue.toLowerCase();
      if (lowerValue == 'true' || lowerValue == '1') return true;
      if (lowerValue == 'false' || lowerValue == '0') return false;
      return stringValue;
    }

    // Date/Time fields
    if (key.contains('date') ||
        key.contains('Date') ||
        key.contains('time') ||
        key.contains('Time') ||
        key.contains('created') ||
        key.contains('Created') ||
        key.contains('updated') ||
        key.contains('Updated') ||
        key.contains('inserted') ||
        key.contains('Inserted') ||
        (key.endsWith('At') || key.contains('At'))) {
      return _parseDateTime(stringValue);
    }

    // Default: return as string
    return stringValue;
  }

  /// Parse date time string
  DateTime? _parseDateTime(String value) {
    try {
      // Try ISO format
      if (value.contains('T') && value.contains(':')) {
        return DateTime.tryParse(value);
      }

      // Try timestamp
      final timestamp = int.tryParse(value);
      if (timestamp != null && timestamp > 1000000000000) {
        return DateTime.fromMillisecondsSinceEpoch(timestamp);
      }

      // Try common date formats
      final formats = [
        'yyyy-MM-dd',
        'dd-MM-yyyy',
        'MM/dd/yyyy',
        'yyyy/MM/dd',
        'dd/MM/yyyy',
      ];

      for (final format in formats) {
        try {
          // Simple parsing for known formats
          if (format == 'yyyy-MM-dd' && value.contains('-')) {
            final parts = value.split('-');
            if (parts.length == 3) {
              final year = int.tryParse(parts[0]);
              final month = int.tryParse(parts[1]);
              final day = int.tryParse(parts[2]);
              if (year != null && month != null && day != null) {
                return DateTime(year, month, day);
              }
            }
          }
        } catch (_) {
          continue;
        }
      }
    } catch (e) {
      debugPrint('Error parsing date $value: $e');
    }

    return null;
  }

  /// Convert model to map
  Map<String, dynamic> _modelToMap(dynamic model) {
    if (model is Customer) return model.toMap();
    if (model is Vendor) return model.toMap();
    if (model is Item) return model.toMap();
    if (model is Ledger) return model.toMap();
    if (model is StockTransaction) return model.toMap();
    if (model is ExpensePurchase) return model.toMap();
    if (model is Cans) return model.toMap();
    if (model is CansEntry) return model.toMap();
    if (model is CustomerLedgerEntry) return model.toMap();
    if (model is VendorLedgerEntry) return model.toMap();
    if (model is ItemLedgerEntry) return model.toMap();
    if (model is LedgerEntry) return model.toMap();

    // Fallback: try to call toMap() if it exists
    try {
      if (model is Map<String, dynamic>) return model;
      return model.toMap() as Map<String, dynamic>;
    } catch (e) {
      debugPrint('❌ Error converting model to map: $e');
      return {};
    }
  }

  // In SheetSyncService class, add this method:
  Map<String, dynamic> _convertToJsonSerializable(Map<String, dynamic> data) {
    final result = <String, dynamic>{};

    for (final entry in data.entries) {
      final key = entry.key;
      final value = entry.value;

      if (value == null) {
        result[key] = null;
      } else if (value is DateTime) {
        result[key] = value.toIso8601String();
      } else if (value is List) {
        result[key] = value.map((item) {
          if (item is DateTime) {
            return item.toIso8601String();
          }
          return item;
        }).toList();
      } else if (value is Map) {
        result[key] = _convertToJsonSerializable(
          Map<String, dynamic>.from(value),
        );
      } else {
        result[key] = value;
      }
    }

    return result;
  }

  /// Insert data into table
  Future<void> _insertTableData(
    String tableName,
    List<Map<String, dynamic>> data,
    List<String> columns,
  ) async {
    try {
      final Database db = await dbHelper.database;

      // Prepare batch for better performance
      final batch = db.batch();

      for (final row in data) {
        final values = <String, dynamic>{};

        // Map row values to column names
        for (final column in columns) {
          final value = row[column];
          values[column] = value?.toString() ?? '';
        }

        batch.insert(tableName, values);
      }

      await batch.commit(noResult: true);
      debugPrint('💾 Inserted ${data.length} rows into $tableName');
    } catch (e) {
      debugPrint('Error inserting data into $tableName: $e');
      rethrow;
    }
  }

  /// Import with dialog for user interaction
  Future<Map<String, dynamic>> importWithDialog() async {
    if (isImporting.value) {
      Get.snackbar(
        'Import In Progress',
        'Please wait for the current import to complete',
        backgroundColor: Colors.orange,
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
      );
      return {'success': false, 'message': 'Import already in progress'};
    }

    // Check internet connection
    final hasInternet = await _checkInternetConnection();
    if (!hasInternet) {
      Get.snackbar(
        'No Internet',
        'Please check your internet connection',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );
      return {'success': false, 'message': 'No internet connection'};
    }

    // Warning dialog - this will DELETE all local data
    final confirm = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('⚠️ Import Data from Cloud'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'This will DELETE ALL LOCAL DATA and replace it with data from Google Sheets.',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            const Text('Are you sure you want to continue?'),
            const SizedBox(height: 8),
            Text(
              'Note: This action cannot be undone.',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            if (lastImportTime.value != null)
              Text(
                'Last import: ${_formatLastSyncTime(lastImportTime.value!)}',
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Get.back(result: true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
            child: const Text('Continue'),
          ),
        ],
      ),
    );

    if (confirm != true) {
      return {'success': false, 'message': 'Import cancelled'};
    }

    // Show progress dialog
    Get.dialog(
      WillPopScope(
        onWillPop: () async => false,
        child: Obx(() {
          final progress = importProgress.value;
          final currentTable = progress.keys.isNotEmpty
              ? progress.keys.first
              : '';
          final progressValue = progress.values.isNotEmpty
              ? progress.values.first
              : 0.0;

          return AlertDialog(
            title: const Text('Importing Data'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                LinearProgressIndicator(value: progressValue),
                const SizedBox(height: 16),
                if (currentTable.isNotEmpty) Text('Importing: $currentTable'),
                const SizedBox(height: 8),
                Text('${(progressValue * 100).toStringAsFixed(1)}% complete'),
              ],
            ),
          );
        }),
      ),
      barrierDismissible: false,
    );

    try {
      final result = await importFromSheets();
      Get.back();

      // Show result dialog
      await Get.dialog(
        AlertDialog(
          title: Text(
            result['success'] == true ? 'Import Complete' : 'Import Failed',
          ),
          content: Text(result['message'] ?? ''),
          actions: [
            TextButton(onPressed: () => Get.back(), child: const Text('OK')),
          ],
        ),
      );

      return result;
    } catch (e) {
      Get.back();

      await Get.dialog(
        AlertDialog(
          title: const Text('Import Error'),
          content: Text('Error: $e'),
          actions: [
            TextButton(onPressed: () => Get.back(), child: const Text('OK')),
          ],
        ),
      );

      return {'success': false, 'error': e.toString()};
    }
  }

  // ==================== INTERNET CHECK ====================

  Future<bool> _checkInternetConnection() async {
    try {
      final response = await http
          .get(Uri.parse('https://www.google.com'))
          .timeout(const Duration(seconds: 5));
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('🌐 No internet connection: $e');
      return false;
    }
  }

  // ==================== AUTOMATIC SYNC SCHEDULING ====================

  Future<void> startAutoSync() async {
    stopAutoSync();

    if (!syncSettings.value['enabled'] ||
        (syncSettings.value['hours'] == 0 &&
            syncSettings.value['minutes'] == 0)) {
      return;
    }

    final totalMinutes =
        (syncSettings.value['hours'] * 60) + syncSettings.value['minutes'];
    if (totalMinutes <= 0) return;

    final now = DateTime.now();
    DateTime nextSync;

    if (lastSyncTime.value != null) {
      nextSync = lastSyncTime.value!.add(Duration(minutes: totalMinutes));
      if (nextSync.isBefore(now)) {
        nextSync = now;
      }
    } else {
      nextSync = now;
    }

    nextSyncTime.value = nextSync;

    final delay = nextSync.difference(now);

    if (delay.inSeconds <= 0) {
      await _performAutoSync();
    } else {
      syncTimer = Timer(delay, () async {
        await _performAutoSync();
      });
    }

    _schedulePeriodicCheck();
  }

  Future<void> _performAutoSync() async {
    if (isSyncing.value) return;

    final hasInternet = await _checkInternetConnection();
    if (!hasInternet) {
      debugPrint('🌐 Skipping auto sync: No internet');
      _scheduleRetry(const Duration(minutes: 5));
      return;
    }

    debugPrint('🔄 Starting automatic sync (with hash checking)...');

    try {
      isSyncing.value = true;
      // Auto sync uses hash checking
      final result = await syncData(useHashCheck: true);

      if (result['success'] == true) {
        debugPrint('✅ Auto sync completed successfully');
        await _saveLastSyncTime();
        await startAutoSync();
      } else {
        debugPrint(
          '❌ Auto sync failed: ${result['error'] ?? result['message']}',
        );

        if (result['error']?.toString().contains('403') ?? false) {
          debugPrint('🔒 Permission error (403) detected. Pausing auto sync.');
          Get.snackbar(
            'Sync Permission Error',
            'Please check your Google Sheets permissions. Auto sync paused.',
            backgroundColor: Colors.red,
            colorText: Colors.white,
            duration: const Duration(seconds: 5),
          );
          await _pauseAutoSync();
          return;
        }

        final failedAttempts = prefs.getInt('failed_sync_attempts') ?? 0;
        final newAttempts = failedAttempts + 1;
        await prefs.setInt('failed_sync_attempts', newAttempts);

        final backoffMinutes = pow(2, newAttempts.clamp(0, 6)) * 5;
        final backoffDuration = Duration(minutes: backoffMinutes.toInt());

        debugPrint('⏰ Scheduling retry in $backoffMinutes minutes');
        _scheduleRetry(backoffDuration);
      }
    } catch (e) {
      debugPrint('❌ Auto sync error: $e');
      _scheduleRetry(const Duration(minutes: 10));
    } finally {
      isSyncing.value = false;
    }
  }

  void _scheduleRetry(Duration delay) {
    syncTimer?.cancel();
    syncTimer = Timer(delay, () async {
      await _performAutoSync();
    });

    final nextRetryTime = DateTime.now().add(delay);
    nextSyncTime.value = nextRetryTime;
    debugPrint('⏰ Next retry scheduled at: $nextRetryTime');
  }

  Future<void> _pauseAutoSync() async {
    final currentSettings = syncSettings.value;
    final newSettings = {
      'hours': currentSettings['hours'],
      'minutes': currentSettings['minutes'],
      'enabled': false,
    };

    await updateSyncSettings(newSettings);

    Get.snackbar(
      'Auto Sync Paused',
      'Auto sync was paused due to permission errors. Please check your settings.',
      backgroundColor: Colors.orange,
      colorText: Colors.white,
      duration: const Duration(seconds: 5),
    );
  }

  void _schedulePeriodicCheck() {
    Timer.periodic(const Duration(minutes: 1), (timer) {
      if (!syncSettings.value['enabled']) {
        timer.cancel();
        return;
      }

      final now = DateTime.now();
      if (nextSyncTime.value != null && now.isAfter(nextSyncTime.value!)) {
        _performAutoSync();
      }
    });
  }

  void stopAutoSync() {
    syncTimer?.cancel();
    syncTimer = null;
  }

  Future<void> updateSyncSettings(Map<String, dynamic> newSettings) async {
    syncSettings.value = newSettings;
    await prefs.setString('backup_sync_settings', jsonEncode(newSettings));
    await startAutoSync();
  }

  // ==================== MANUAL SYNC WITH DIALOGS ====================

  Future<Map<String, dynamic>> manualSyncWithDialog() async {
    if (isSyncing.value) {
      Get.snackbar(
        'Sync In Progress',
        'Please wait for the current sync to complete',
        backgroundColor: Colors.orange,
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
      );
      return {'success': false, 'message': 'Sync already in progress'};
    }

    final hasInternet = await _checkInternetConnection();
    if (!hasInternet) {
      Get.snackbar(
        'No Internet',
        'Please check your internet connection',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );
      return {'success': false, 'message': 'No internet connection'};
    }

    final confirm = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Sync Data to Cloud'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('This will sync all your data to Google Sheets.'),
            const SizedBox(height: 8),
            if (lastSyncTime.value != null)
              Text(
                'Last sync: ${_formatLastSyncTime(lastSyncTime.value!)}',
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Get.back(result: true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
            child: const Text('Start Sync'),
          ),
        ],
      ),
    );

    if (confirm != true) {
      return {'success': false, 'message': 'Sync cancelled'};
    }

    Get.dialog(
      WillPopScope(
        onWillPop: () async => false,
        child: const AlertDialog(
          title: Text('Syncing Data'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Syncing in progress...'),
            ],
          ),
        ),
      ),
      barrierDismissible: false,
    );

    try {
      isSyncing.value = true;
      // Manual sync: ALWAYS sync everything, skip hash checking
      final result = await syncData(useHashCheck: false);
      Get.back();

      await Get.dialog(
        AlertDialog(
          title: Text(
            result['success'] == true ? 'Sync Complete' : 'Sync Failed',
          ),
          content: Text(result['message'] ?? ''),
          actions: [
            TextButton(onPressed: () => Get.back(), child: const Text('OK')),
          ],
        ),
      );

      return result;
    } catch (e) {
      Get.back();

      await Get.dialog(
        AlertDialog(
          title: const Text('Sync Error'),
          content: Text('Error: $e'),
          actions: [
            TextButton(onPressed: () => Get.back(), child: const Text('OK')),
          ],
        ),
      );

      return {'success': false, 'error': e.toString()};
    } finally {
      isSyncing.value = false;
    }
  }

  // ==================== CORE SYNC FUNCTION ====================

  Future<Map<String, dynamic>> syncData({bool useHashCheck = false}) async {
    final stopwatch = Stopwatch()..start();

    try {
      await initPrefs();

      final hasInternet = await _checkInternetConnection();
      if (!hasInternet) {
        return {
          'success': false,
          'error': 'No internet connection',
          'timestamp': DateTime.now().toIso8601String(),
        };
      }

      List<String> tables = await getAllTableNames();
      debugPrint('🚀 Starting sync - Found ${tables.length} tables');

      int syncedCount = 0;
      int skippedCount = 0;
      int failedCount = 0;
      List<String> failedTables = [];

      for (String table in tables) {
        try {
          List<Map<String, dynamic>> localData = await getLocalTableData(table);

          if (useHashCheck) {
            // Check hash for auto sync
            String currentHash = await _calculateDataHash(localData);
            String storedHash = await _getStoredHash(table);
            bool shouldSync = currentHash != storedHash;

            if (shouldSync) {
              debugPrint('🔄 Syncing table: $table');
              bool success = await _syncTableToSheets(
                table,
                localData,
                currentHash,
              );

              if (success) {
                syncedCount++;
                debugPrint('✅ Synced: $table');
              } else {
                failedCount++;
                failedTables.add(table);
                debugPrint('❌ Failed: $table');
              }
            } else {
              skippedCount++;
              debugPrint('⚡ Skipped: $table');
            }
          } else {
            // Manual sync: ALWAYS sync, no hash checking
            debugPrint('🔄 Manual sync for table: $table');
            String currentHash = await _calculateDataHash(localData);
            bool success = await _syncTableToSheets(
              table,
              localData,
              currentHash,
            );

            if (success) {
              syncedCount++;
              debugPrint('✅ Manual synced: $table');
            } else {
              failedCount++;
              failedTables.add(table);
              debugPrint('❌ Manual sync failed: $table');
            }
          }
        } catch (e) {
          failedCount++;
          failedTables.add(table);
          debugPrint('❌ Error: $table - $e');
        }
      }

      stopwatch.stop();
      debugPrint('⏱️ Total time: ${stopwatch.elapsed}');

      if (failedCount == 0) {
        await prefs.remove('failed_sync_attempts');
        await _saveLastSyncTime();
      }

      String message = useHashCheck
          ? 'Sync completed: $syncedCount synced, $skippedCount skipped, $failedCount failed'
          : 'Manual sync completed: $syncedCount synced, $failedCount failed';

      return {
        'success': failedCount == 0,
        'message': message,
        'synced': syncedCount,
        'skipped': skippedCount,
        'failed': failedCount,
        'failedTables': failedTables,
        'useHashCheck': useHashCheck,
        'timestamp': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      stopwatch.stop();
      debugPrint('❌ Fatal sync error: $e');
      return {
        'success': false,
        'error': e.toString(),
        'timestamp': DateTime.now().toIso8601String(),
      };
    }
  }

  Future<bool> _syncTableToSheets(
    String tableName,
    List<Map<String, dynamic>> data,
    String currentHash,
  ) async {
    try {
      if (data.isEmpty) {
        debugPrint('📭 Table $tableName is empty');

        final response = await _makeAppsScriptRequest(
          operation: 'sync',
          tableName: tableName,
          data: [],
        );

        bool success = response.statusCode == 200;

        if (success) {
          await _storeHash(tableName, 'empty');
          return true;
        } else {
          debugPrint(
            '❌ HTTP ${response.statusCode} for empty table: $tableName',
          );
          debugPrint('❌ Response: ${response.body}');
          return false;
        }
      }

      debugPrint('📤 Syncing $tableName with ${data.length} rows');

      final response = await _makeAppsScriptRequest(
        operation: 'sync',
        tableName: tableName,
        data: data,
      );

      bool success = response.statusCode == 200;

      if (success) {
        // Parse response to see what happened
        try {
          final responseData = jsonDecode(response.body);
          if (responseData['success'] == true) {
            // Store hash only if sync was successful
            await _storeHash(tableName, currentHash);

            // Log detailed results
            final actions = responseData['actions'] ?? {};
            final added = actions['added'] ?? 0;
            final updated = actions['updated'] ?? 0;
            final deleted = actions['deleted'] ?? 0;
            final rows = responseData['rows'] ?? 0;

            debugPrint(
              '📊 Server wrote $rows rows: +$added, ~$updated, -$deleted',
            );

            return true;
          } else {
            debugPrint(
              '❌ Server returned success: false - ${responseData['message']}',
            );
            return false;
          }
        } catch (e) {
          debugPrint('⚠️ Could not parse sync response: $e');
          debugPrint('⚠️ Raw response: ${response.body}');
          // Still store hash if HTTP was successful
          await _storeHash(tableName, currentHash);
          return true;
        }
      } else {
        debugPrint('❌ HTTP ${response.statusCode} for table: $tableName');
        debugPrint('❌ Response: ${response.body}');
        return false;
      }
    } catch (e) {
      debugPrint('❌ Sync error for $tableName: $e');
      return false;
    }
  }

  // ==================== HELPER METHODS ====================

  Future<String> _calculateDataHash(List<Map<String, dynamic>> data) async {
    if (data.isEmpty) return 'empty';

    // Convert all DateTime objects to strings before encoding
    final serializableData = data.map(_convertToJsonSerializable).toList();

    var dataString = jsonEncode(serializableData);
    var bytes = utf8.encode(dataString);
    var digest = md5.convert(bytes);
    return digest.toString();
  }

  // In SheetSyncService class
  Future<void> fixExistingDatabaseTypes() async {
    debugPrint('🛠️ Fixing existing database type issues...');

    try {
      final db = await dbHelper.database;

      // Fix customer table
      await _fixTableTypes(db, 'customer', [
        'id INTEGER',
        'openingBalance REAL',
      ]);

      // Fix ledger table
      await _fixTableTypes(db, 'ledger', [
        'id INTEGER',
        'accountId INTEGER',
        'debit REAL',
        'credit REAL',
        'balance REAL',
      ]);

      // Fix item table
      await _fixTableTypes(db, 'item', [
        'id INTEGER',
        'pricePerKg REAL',
        'costPrice REAL',
        'sellingPrice REAL',
        'availableStock REAL',
        'canWeight REAL',
      ]);

      debugPrint('✅ Database types fixed successfully');
    } catch (e) {
      debugPrint('❌ Error fixing database types: $e');
    }
  }

  Future<void> _fixTableTypes(
    Database db,
    String tableName,
    List<String> columnTypes,
  ) async {
    try {
      // Check if table exists
      final tables = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name=?",
        [tableName],
      );

      if (tables.isEmpty) {
        debugPrint('📭 Table $tableName does not exist, skipping');
        return;
      }

      // Get current table info
      final info = await db.query(tableName, limit: 1);
      if (info.isEmpty) {
        debugPrint('📭 Table $tableName is empty, skipping');
        return;
      }

      debugPrint('🛠️ Fixing types for table: $tableName');

      // Create temporary table with correct types
      final tempTable = '${tableName}_temp';
      final columns = info.first.keys.join(', ');
      final columnDefs = columnTypes.join(', ');

      await db.execute('CREATE TABLE $tempTable ($columnDefs)');

      // Copy data with type conversion
      await db.execute('INSERT INTO $tempTable SELECT * FROM $tableName');

      // Drop original table
      await db.execute('DROP TABLE $tableName');

      // Rename temporary table
      await db.execute('ALTER TABLE $tempTable RENAME TO $tableName');

      debugPrint('✅ Fixed types for table: $tableName');
    } catch (e) {
      debugPrint('❌ Error fixing table $tableName: $e');
    }
  }

  Future<String> _getStoredHash(String tableName) async {
    await initPrefs();
    return prefs.getString('hash_$tableName') ?? 'first_time';
  }

  Future<void> _storeHash(String tableName, String hash) async {
    await initPrefs();
    await prefs.setString('hash_$tableName', hash);
  }

  Future<List<String>> getAllTableNames() async {
    try {
      Database db = await dbHelper.database;
      List<Map<String, dynamic>> result = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%'",
      );
      return result.map((row) => row['name'] as String).toList();
    } catch (e) {
      debugPrint('Error getting table names: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getLocalTableData(String tableName) async {
    try {
      Database db = await dbHelper.database;
      return await db.query(tableName);
    } catch (e) {
      debugPrint('Error getting data for $tableName: $e');
      return [];
    }
  }

  String _formatLastSyncTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inMinutes < 1) return 'Just now';
    if (difference.inMinutes < 60) return '${difference.inMinutes} minutes ago';
    if (difference.inHours < 24) return '${difference.inHours} hours ago';
    return '${difference.inDays} days ago';
  }

  Future<bool> testConnection() async {
    try {
      final hasInternet = await _checkInternetConnection();
      if (!hasInternet) return false;

      final response = await _makeAppsScriptRequest(
        operation: 'test_connection',
      );

      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Connection test failed: $e');
      return false;
    }
  }

  Future<void> resetFailedAttempts() async {
    await prefs.remove('failed_sync_attempts');
    debugPrint('🔄 Reset failed sync attempts counter');
  }

  // ==================== FORCE SYNC ALL DATA ====================

  /// Force sync all data to Google Sheets, ignoring saved hashes
  Future<Map<String, dynamic>> forceSyncAllData() async {
    if (isSyncing.value) {
      return {'success': false, 'message': 'Sync already in progress'};
    }

    final stopwatch = Stopwatch()..start();

    try {
      isSyncing.value = true;

      // Check internet connection
      final hasInternet = await _checkInternetConnection();
      if (!hasInternet) {
        return {'success': false, 'error': 'No internet connection'};
      }

      debugPrint('🚀 Starting FORCE sync - Ignoring saved hashes');

      List<String> tables = await getAllTableNames();
      debugPrint('📋 Found ${tables.length} tables to force sync');

      int syncedCount = 0;
      int failedCount = 0;
      List<String> failedTables = [];

      // Process each table with force sync
      for (String table in tables) {
        try {
          List<Map<String, dynamic>> localData = await getLocalTableData(table);

          if (localData.isEmpty) {
            debugPrint('📭 Table $table is empty - force syncing empty data');

            // Sync empty table
            bool success = await _forceSyncTable(table, localData);

            if (success) {
              syncedCount++;
              debugPrint('✅ Force synced empty table: $table');
            } else {
              failedCount++;
              failedTables.add(table);
              debugPrint('❌ Failed to force sync empty table: $table');
            }
            continue;
          }

          debugPrint(
            '🔄 Force syncing table: $table (${localData.length} rows)',
          );

          // Calculate current hash but don't check against stored hash
          String currentHash = await _calculateDataHash(localData);

          // Force sync regardless of previous state
          bool success = await _forceSyncTable(table, localData);

          if (success) {
            // Update the hash after successful force sync
            await _storeHash(table, currentHash);
            syncedCount++;
            debugPrint('✅ Force synced: $table');
          } else {
            failedCount++;
            failedTables.add(table);
            debugPrint('❌ Force sync failed: $table');
          }
        } catch (e) {
          failedCount++;
          failedTables.add(table);
          debugPrint('❌ Error force syncing $table: $e');
        }
      }

      stopwatch.stop();
      debugPrint('⏱️ Force sync total time: ${stopwatch.elapsed}');

      if (failedCount == 0) {
        await prefs.remove('failed_sync_attempts');
        await _saveLastSyncTime();
      }

      return {
        'success': failedCount == 0,
        'message':
            'Force sync completed: $syncedCount synced, $failedCount failed',
        'synced': syncedCount,
        'failed': failedCount,
        'failedTables': failedTables,
        'forced': true,
        'timestamp': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      stopwatch.stop();
      debugPrint('❌ Fatal force sync error: $e');
      return {
        'success': false,
        'error': e.toString(),
        'timestamp': DateTime.now().toIso8601String(),
      };
    } finally {
      isSyncing.value = false;
    }
  }

  /// Force sync a single table to Google Sheets
  Future<bool> _forceSyncTable(
    String tableName,
    List<Map<String, dynamic>> data,
  ) async {
    try {
      if (data.isEmpty) {
        debugPrint('📭 Force syncing empty table: $tableName');

        final response = await _makeAppsScriptRequest(
          operation: 'sync',
          tableName: tableName,
          data: [],
          force: true,
        );

        bool success = response.statusCode == 200;

        if (success) {
          await _storeHash(tableName, 'empty');
          return true;
        } else {
          debugPrint(
            '❌ HTTP ${response.statusCode} for force sync of empty table: $tableName',
          );
          return false;
        }
      }

      debugPrint('📤 Force syncing $tableName with ${data.length} rows');

      final response = await _makeAppsScriptRequest(
        operation: 'sync',
        tableName: tableName,
        data: data,
        force: true,
      );

      bool success = response.statusCode == 200;

      if (success) {
        return true;
      } else {
        debugPrint(
          '❌ HTTP ${response.statusCode} for force sync of table: $tableName',
        );

        // Try to parse error from response
        try {
          final responseData = jsonDecode(response.body);
          debugPrint('📄 Response error: ${responseData['message']}');
        } catch (_) {
          debugPrint('📄 Raw response: ${response.body}');
        }

        return false;
      }
    } catch (e) {
      debugPrint('❌ Force sync error for $tableName: $e');
      return false;
    }
  }

  /// Force sync with dialog for user interaction
  Future<Map<String, dynamic>> forceSyncWithDialog() async {
    if (isSyncing.value) {
      Get.snackbar(
        'Sync In Progress',
        'Please wait for the current sync to complete',
        backgroundColor: Colors.orange,
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
      );
      return {'success': false, 'message': 'Sync already in progress'};
    }

    // Check internet connection
    final hasInternet = await _checkInternetConnection();
    if (!hasInternet) {
      Get.snackbar(
        'No Internet',
        'Please check your internet connection',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );
      return {'success': false, 'message': 'No internet connection'};
    }

    // Warning dialog - this will force sync ALL data
    final confirm = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('🔄 Force Sync to Cloud'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'This will force sync ALL data to Google Sheets, even if no changes were detected.',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            const Text('This is useful when:'),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.only(left: 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('• Sync status got corrupted'),
                  Text('• You suspect sync issues'),
                  Text('• You want to ensure data is backed up'),
                  Text('• Previous syncs were incomplete'),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Text('Are you sure you want to continue?'),
            const SizedBox(height: 8),
            Text(
              'Note: This may take longer than normal sync.',
              style: TextStyle(
                color: Colors.orange,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            if (lastSyncTime.value != null)
              Text(
                'Last normal sync: ${_formatLastSyncTime(lastSyncTime.value!)}',
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Get.back(result: true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepPurple,
              foregroundColor: Colors.white,
            ),
            child: const Text('Force Sync'),
          ),
        ],
      ),
    );

    if (confirm != true) {
      return {'success': false, 'message': 'Force sync cancelled'};
    }

    // Show progress dialog
    Get.dialog(
      WillPopScope(
        onWillPop: () async => false,
        child: const AlertDialog(
          title: Text('Force Syncing Data'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Force syncing all data to cloud...'),
              SizedBox(height: 8),
              Text(
                'This may take a few moments',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
      barrierDismissible: false,
    );

    try {
      final result = await forceSyncAllData();
      Get.back();

      // Show result dialog
      await Get.dialog(
        AlertDialog(
          title: Text(
            result['success'] == true
                ? 'Force Sync Complete'
                : 'Force Sync Failed',
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(result['message'] ?? ''),
              const SizedBox(height: 12),
              if (result['synced'] != null && result['failed'] != null)
                Text(
                  'Synced: ${result['synced']} tables, Failed: ${result['failed']} tables',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: result['failed']! > 0 ? Colors.orange : Colors.green,
                  ),
                ),
              if (result['failedTables'] != null &&
                  result['failedTables'].isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Failed tables:',
                        style: TextStyle(fontSize: 12, color: Colors.red),
                      ),
                      Text(
                        result['failedTables'].join(', '),
                        style: const TextStyle(fontSize: 11, color: Colors.red),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Get.back(), child: const Text('OK')),
          ],
        ),
      );

      return result;
    } catch (e) {
      Get.back();

      await Get.dialog(
        AlertDialog(
          title: const Text('Force Sync Error'),
          content: Text('Error: $e'),
          actions: [
            TextButton(onPressed: () => Get.back(), child: const Text('OK')),
          ],
        ),
      );

      return {'success': false, 'error': e.toString()};
    }
  }

  /// Clear all sync hashes to force next sync to be a full sync
  Future<void> clearAllSyncHashes() async {
    await initPrefs();
    final keys = prefs.getKeys();
    int clearedCount = 0;

    for (final key in keys) {
      if (key.startsWith('hash_')) {
        await prefs.remove(key);
        clearedCount++;
      }
    }

    await prefs.remove('failed_sync_attempts');
    debugPrint('🧹 Cleared $clearedCount sync hashes');

    Get.snackbar(
      'Sync Hashes Cleared',
      'Next sync will be a full sync of all data',
      backgroundColor: Colors.blue,
      colorText: Colors.white,
      duration: const Duration(seconds: 3),
    );
  }
}
