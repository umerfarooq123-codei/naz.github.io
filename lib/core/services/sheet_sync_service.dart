import 'dart:async';
import 'dart:convert';
import 'dart:math';

// Remove unused import: import 'dart:math';

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

  // Enhanced Table-to-model mapping with all required models
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

  // Enhanced regex patterns for dynamic tables
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

  // ==================== COMPREHENSIVE IMPORT FUNCTIONALITY ====================

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

      debugPrint('🔄 Starting comprehensive import from Google Sheets...');

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

      // Step 3: Import each table with proper model conversion
      for (int i = 0; i < tables.length; i++) {
        final tableName = tables[i];
        final progress = (i + 1) / tables.length;
        importProgress.value = {tableName: progress};

        try {
          debugPrint('📥 Importing table: $tableName');
          final success = await _importTableWithModel(tableName);

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

  /// Import single table with proper model conversion and database schema
  Future<bool> _importTableWithModel(String tableName) async {
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

            debugPrint('📊 Table $tableName has ${tableData.length} rows');

            // Step 1: Convert raw data to proper model data
            final convertedData = await _convertToModelData(
              tableName,
              tableData,
            );

            // Step 2: Validate data integrity
            final validationResult = await _validateTableData(
              tableName,
              convertedData,
            );
            if (!validationResult['valid']) {
              debugPrint(
                '❌ Validation failed for $tableName: ${validationResult['error']}',
              );
              return false;
            }

            // Step 3: Create/ensure database table exists with proper schema
            await _ensureDatabaseTable(tableName, convertedData);

            // Step 4: Insert data with proper foreign key relationships
            final insertSuccess = await _insertModelData(
              tableName,
              convertedData,
            );

            if (insertSuccess) {
              // Calculate and store hash
              final hash = await _calculateDataHash(convertedData);
              await _storeHash(tableName, hash);
              debugPrint('✅ Imported ${tableData.length} rows to $tableName');
              return true;
            } else {
              debugPrint('❌ Failed to insert data for $tableName');
              return false;
            }
          } else {
            debugPrint('❌ Server returned success: false for table $tableName');
            debugPrint('❌ Server message: ${data['message']}');
            return false;
          }
        } catch (e) {
          debugPrint('❌ JSON decode error for table $tableName: $e');
          return false;
        }
      } else {
        debugPrint('❌ HTTP ${response.statusCode} for table: $tableName');
        return false;
      }
    } catch (e) {
      debugPrint('❌ Error importing table $tableName: $e');
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> _convertToModelData(
    String tableName,
    List<Map<String, dynamic>> rawData,
  ) async {
    debugPrint('🎯 Converting data for table: $tableName');

    try {
      // First clean the data
      final cleanedData = rawData.map(_cleanRowWithEnhancedConversion).toList();

      // Then fix type issues
      final fixedData = cleanedData
          .map((row) => _fixTypeIssues(row, tableName))
          .toList();

      // Continue with existing logic...
      if (_modelConstructors.containsKey(tableName)) {
        return _convertUsingStandardModel(tableName, fixedData);
      } else if (_customerLedgerPattern.hasMatch(tableName)) {
        return _convertToCustomerLedgerEntries(tableName, fixedData);
      } else if (_vendorLedgerPattern.hasMatch(tableName)) {
        return _convertToVendorLedgerEntries(fixedData);
      } else if (_itemLedgerPattern.hasMatch(tableName)) {
        return _convertToItemLedgerEntries(tableName, fixedData);
      } else if (_ledgerEntryPattern.hasMatch(tableName)) {
        return _convertToLedgerEntries(tableName, fixedData);
      } else {
        return _cleanAndConvertGenericData(fixedData);
      }
    } catch (e) {
      debugPrint('❌ Error converting data for $tableName: $e');
      return _cleanAndConvertGenericData(rawData);
    }
  }

  /// Convert using standard model constructor with enhanced type conversion
  /// Convert using standard model constructor with enhanced type conversion
  List<Map<String, dynamic>> _convertUsingStandardModel(
    String tableName,
    List<Map<String, dynamic>> rawData,
  ) {
    final constructor = _modelConstructors[tableName]!;
    final convertedData = <Map<String, dynamic>>[];

    for (var row in rawData) {
      try {
        // Enhanced cleaning with proper type conversion
        final cleanedRow = _cleanRowWithEnhancedConversion(row);

        // Special handling for specific models
        if (tableName == 'customer') {
          _handleCustomerSpecialFields(cleanedRow);
        } else if (tableName == 'item') {
          _handleItemSpecialFields(cleanedRow);
        } else if (tableName == 'cans') {
          _handleCansSpecialFields(cleanedRow);
        } else if (tableName == 'expense_purchases') {
          _handleExpensePurchaseSpecialFields(cleanedRow);
        } else if (tableName == 'stock_transaction') {
          // Ensure date is properly formatted for StockTransaction
          if (cleanedRow['date'] is DateTime) {
            cleanedRow['date'] = cleanedRow['date'].toIso8601String();
          }
        } else if (tableName == 'ledger') {
          // Ensure dates are properly formatted for Ledger
          if (cleanedRow['date'] is DateTime) {
            cleanedRow['date'] = cleanedRow['date'].toIso8601String();
          }
          if (cleanedRow['createdAt'] is DateTime) {
            cleanedRow['createdAt'] = cleanedRow['createdAt'].toIso8601String();
          }
          if (cleanedRow['updatedAt'] is DateTime) {
            cleanedRow['updatedAt'] = cleanedRow['updatedAt'].toIso8601String();
          }
        }

        // Convert using model constructor
        final model = constructor(cleanedRow);
        final modelMap = _modelToMap(model);

        // Add to converted data
        convertedData.add(modelMap);
      } catch (e) {
        debugPrint('❌ Error converting row for $tableName: $e');
        debugPrint('❌ Problematic row: $row');
        // Skip problematic row but continue with others
      }
    }

    return convertedData;
  }

  /// Enhanced row cleaning with proper type conversion
  Map<String, dynamic> _cleanRowWithEnhancedConversion(
    Map<String, dynamic> row,
  ) {
    final cleanedRow = <String, dynamic>{};

    for (final entry in row.entries) {
      final key = entry.key;
      final value = entry.value;

      // Handle null/empty values
      if (value == null || value.toString().isEmpty) {
        cleanedRow[key] = null;
        continue;
      }

      // Convert value based on key patterns and data type
      cleanedRow[key] = _convertValueWithEnhancedLogic(key, value);
    }

    return cleanedRow;
  }

  /// Enhanced value conversion logic
  dynamic _convertValueWithEnhancedLogic(String key, dynamic value) {
    final String stringValue = value.toString();

    // Handle empty strings
    if (stringValue.isEmpty) return null;

    // ============ ID FIELDS ============
    if (key.endsWith('Id') ||
        key == 'id' ||
        key == 'transactionId' ||
        key == 'accountId' ||
        key == 'itemId' ||
        key == 'vendorId' ||
        key == 'employeeId' ||
        key == 'customerId' ||
        key == 'cansId') {
      return _tryParseInt(stringValue);
    }

    // ============ DOUBLE/NUMERIC FIELDS ============
    final numericPatterns = [
      'balance',
      'Balance',
      'debit',
      'Debit',
      'credit',
      'Credit',
      'amount',
      'Amount',
      'price',
      'Price',
      'cost',
      'Cost',
      'quantity',
      'Quantity',
      'weight',
      'Weight',
      'stock',
      'Stock',
      'salary',
      'Salary',
      'dues',
      'opening',
      'Opening',
      'PerKg',
      'PerUnit',
      'PerCan',
      'PricePerKg',
      'SellingPrice',
      'CostPrice',
      'AvailableStock',
      'CanWeight',
      'BasicSalary',
      'Allowances',
      'Deductions',
      'NetSalary',
      'TotalAmount',
      'PaidAmount',
      'ChequeAmount',
    ];

    for (var pattern in numericPatterns) {
      if (key.contains(pattern)) {
        return _tryParseDouble(stringValue);
      }
    }

    // ============ BOOLEAN FIELDS ============
    final booleanPatterns = [
      'status',
      'is',
      'Is',
      'active',
      'Active',
      'cleared',
      'can',
      'has',
      'enabled',
      'verified',
      'approved',
    ];

    for (var pattern in booleanPatterns) {
      if (key.contains(pattern)) {
        return _parseBooleanEnhanced(stringValue);
      }
    }

    // ============ DATE/TIME FIELDS ============
    final datePatterns = [
      'date',
      'Date',
      'time',
      'Time',
      'created',
      'Created',
      'updated',
      'Updated',
      'inserted',
      'Inserted',
    ];

    for (var pattern in datePatterns) {
      if (key.contains(pattern) || key.endsWith('At')) {
        return _parseDateTimeEnhanced(stringValue);
      }
    }

    // ============ JSON FIELDS ============
    if (key == 'tags' || key == 'balanceCans' || key == 'receivedCans') {
      return _parseJsonField(stringValue);
    }

    // ============ DEFAULT: STRING ============
    return stringValue.trim();
  }

  /// Try parsing integer with error handling
  int? _tryParseInt(String value) {
    try {
      return int.tryParse(value.replaceAll(',', ''));
    } catch (e) {
      debugPrint('⚠️ Failed to parse int: $value');
      return null;
    }
  }

  /// Try parsing double with error handling
  double? _tryParseDouble(String value) {
    try {
      return double.tryParse(value.replaceAll(',', ''));
    } catch (e) {
      debugPrint('⚠️ Failed to parse double: $value');
      return 0.0;
    }
  }

  /// FIXED: Enhanced boolean parsing - returns bool, not String
  dynamic _parseBooleanEnhanced(String value) {
    final lowerValue = value.toLowerCase().trim();

    if (lowerValue == 'true' ||
        lowerValue == '1' ||
        lowerValue == 'yes' ||
        lowerValue == 'y' ||
        lowerValue == 'on') {
      return true;
    }

    if (lowerValue == 'false' ||
        lowerValue == '0' ||
        lowerValue == 'no' ||
        lowerValue == 'n' ||
        lowerValue == 'off') {
      return false;
    }

    // Return as string if not clearly boolean
    return value;
  }

  /// Enhanced date/time parsing
  dynamic _parseDateTimeEnhanced(String value) {
    try {
      // NEW: Try parsing as millisecond timestamp first
      final timestamp = int.tryParse(value);
      if (timestamp != null) {
        // If it's a large number, treat as milliseconds
        if (timestamp > 1000000000000) {
          return DateTime.fromMillisecondsSinceEpoch(timestamp);
        }
        // If it's a smaller number, treat as seconds
        else if (timestamp > 1000000000) {
          return DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
        }
      }

      // Try ISO8601 format first
      if (value.contains('T') && value.contains(':')) {
        final date = DateTime.tryParse(value);
        if (date != null) return date;
      }

      // Try timestamp (milliseconds since epoch)
      if (timestamp != null && timestamp > 1000000000000) {
        return DateTime.fromMillisecondsSinceEpoch(timestamp);
      }

      // Try common date formats
      final formats = [
        'yyyy-MM-dd HH:mm:ss',
        'yyyy-MM-dd',
        'dd-MM-yyyy HH:mm:ss',
        'dd-MM-yyyy',
        'MM/dd/yyyy HH:mm:ss',
        'MM/dd/yyyy',
        'dd/MM/yyyy HH:mm:ss',
        'dd/MM/yyyy',
      ];

      for (final format in formats) {
        try {
          // Parse based on format
          if (format.contains('HH:mm:ss')) {
            // Handle with time
            final parts = value.split(' ');
            if (parts.length == 2) {
              final datePart = parts[0];
              final timePart = parts[1];

              // Parse date part
              DateTime? date;
              if (datePart.contains('-')) {
                final dateParts = datePart.split('-');
                if (dateParts.length == 3) {
                  if (format.startsWith('yyyy')) {
                    // yyyy-MM-dd
                    final year = int.tryParse(dateParts[0]);
                    final month = int.tryParse(dateParts[1]);
                    final day = int.tryParse(dateParts[2]);
                    if (year != null && month != null && day != null) {
                      date = DateTime(year, month, day);
                    }
                  } else {
                    // dd-MM-yyyy
                    final day = int.tryParse(dateParts[0]);
                    final month = int.tryParse(dateParts[1]);
                    final year = int.tryParse(dateParts[2]);
                    if (year != null && month != null && day != null) {
                      date = DateTime(year, month, day);
                    }
                  }
                }
              } else if (datePart.contains('/')) {
                final dateParts = datePart.split('/');
                if (dateParts.length == 3) {
                  if (format.startsWith('MM')) {
                    // MM/dd/yyyy
                    final month = int.tryParse(dateParts[0]);
                    final day = int.tryParse(dateParts[1]);
                    final year = int.tryParse(dateParts[2]);
                    if (year != null && month != null && day != null) {
                      date = DateTime(year, month, day);
                    }
                  } else {
                    // dd/MM/yyyy
                    final day = int.tryParse(dateParts[0]);
                    final month = int.tryParse(dateParts[1]);
                    final year = int.tryParse(dateParts[2]);
                    if (year != null && month != null && day != null) {
                      date = DateTime(year, month, day);
                    }
                  }
                }
              }

              // Parse time part if date was successfully parsed
              if (date != null && timePart.contains(':')) {
                final timeParts = timePart.split(':');
                if (timeParts.length >= 2) {
                  final hour = int.tryParse(timeParts[0]);
                  final minute = int.tryParse(timeParts[1]);
                  final second = timeParts.length > 2
                      ? int.tryParse(timeParts[2])
                      : 0;

                  if (hour != null && minute != null) {
                    return DateTime(
                      date.year,
                      date.month,
                      date.day,
                      hour,
                      minute,
                      second ?? 0,
                    );
                  }
                }
              }
            }
          } else {
            // Date only formats
            if (value.contains('-')) {
              final parts = value.split('-');
              if (parts.length == 3) {
                if (format.startsWith('yyyy')) {
                  // yyyy-MM-dd
                  final year = int.tryParse(parts[0]);
                  final month = int.tryParse(parts[1]);
                  final day = int.tryParse(parts[2]);
                  if (year != null && month != null && day != null) {
                    return DateTime(year, month, day);
                  }
                } else {
                  // dd-MM-yyyy
                  final day = int.tryParse(parts[0]);
                  final month = int.tryParse(parts[1]);
                  final year = int.tryParse(parts[2]);
                  if (year != null && month != null && day != null) {
                    return DateTime(year, month, day);
                  }
                }
              }
            } else if (value.contains('/')) {
              final parts = value.split('/');
              if (parts.length == 3) {
                if (format.startsWith('MM')) {
                  // MM/dd/yyyy
                  final month = int.tryParse(parts[0]);
                  final day = int.tryParse(parts[1]);
                  final year = int.tryParse(parts[2]);
                  if (year != null && month != null && day != null) {
                    return DateTime(year, month, day);
                  }
                } else {
                  // dd/MM/yyyy
                  final day = int.tryParse(parts[0]);
                  final month = int.tryParse(parts[1]);
                  final year = int.tryParse(parts[2]);
                  if (year != null && month != null && day != null) {
                    return DateTime(year, month, day);
                  }
                }
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

    // Return as string if parsing fails
    return value;
  }

  /// Parse JSON fields
  dynamic _parseJsonField(String value) {
    try {
      if (value.startsWith('[') || value.startsWith('{')) {
        return jsonDecode(value);
      }
      // Handle comma-separated lists
      if (value.contains(',')) {
        return value.split(',').map((item) => item.trim()).toList();
      }
      return [value];
    } catch (e) {
      debugPrint('Error parsing JSON field $value: $e');
      return null;
    }
  }

  /// Handle customer special fields
  void _handleCustomerSpecialFields(Map<String, dynamic> row) {
    // Ensure openingBalance is properly set
    if (row['openingBalance'] == null) {
      row['openingBalance'] = 0.0;
    }

    // Ensure type has a default
    if (row['type'] == null || row['type'].toString().isEmpty) {
      row['type'] = 'Customer';
    }
  }

  /// Handle item special fields
  void _handleItemSpecialFields(Map<String, dynamic> row) {
    // Set default values for numeric fields
    final numericFields = [
      'pricePerKg',
      'costPrice',
      'sellingPrice',
      'availableStock',
      'canWeight',
    ];
    for (var field in numericFields) {
      if (row[field] == null) {
        row[field] = 0.0;
      }
    }
  }

  /// Handle cans special fields
  /// Handle cans special fields
  /// Handle cans special fields
  /// Handle cans special fields
  void _handleCansSpecialFields(Map<String, dynamic> row) {
    debugPrint('Handling Cans special fields, row keys: ${row.keys.toList()}');

    // Handle accountId - might be string like "cust" or number
    if (row['accountId'] is String) {
      final accountIdStr = row['accountId'] as String;
      if (accountIdStr.toLowerCase() == 'cust') {
        row['accountId'] = 1; // Default customer ID
      } else {
        row['accountId'] = int.tryParse(accountIdStr) ?? 0;
      }
    } else if (row['accountId'] is double) {
      row['accountId'] = (row['accountId'] as double).toInt();
    }

    // Handle receivedCans if it's a JSON array like "[0]"
    if (row['receivedCans'] is String) {
      final receivedCansStr = row['receivedCans'] as String;
      if (receivedCansStr.startsWith('[') && receivedCansStr.endsWith(']')) {
        try {
          final jsonArray = jsonDecode(receivedCansStr) as List;
          if (jsonArray.isNotEmpty) {
            row['receivedCans'] = (jsonArray.first as num).toDouble();
          } else {
            row['receivedCans'] = 0.0;
          }
        } catch (e) {
          debugPrint('Error parsing receivedCans JSON: $e');
          row['receivedCans'] = 0.0;
        }
      } else {
        // Try to parse as double
        row['receivedCans'] = double.tryParse(receivedCansStr) ?? 0.0;
      }
    } else if (row['receivedCans'] is List) {
      final listValue = row['receivedCans'] as List;
      if (listValue.isNotEmpty) {
        final firstValue = listValue.first;
        if (firstValue is num) {
          row['receivedCans'] = firstValue.toDouble();
        } else {
          row['receivedCans'] = 0.0;
        }
      } else {
        row['receivedCans'] = 0.0;
      }
    }

    // Set default values for numeric fields
    final numericFields = ['openingBalanceCans', 'currentCans', 'totalCans'];
    for (var field in numericFields) {
      if (row[field] == null) {
        row[field] = 0.0;
      } else if (row[field] is String) {
        row[field] = double.tryParse(row[field] as String) ?? 0.0;
      }
    }

    // Set dates if not provided
    final now = DateTime.now();
    if (row['insertedDate'] == null) row['insertedDate'] = now;
    if (row['updatedDate'] == null) row['updatedDate'] = now;
  }

  /// Handle expense purchase special fields
  /// Handle expense purchase special fields
  /// Handle expense purchase special fields
  void _handleExpensePurchaseSpecialFields(Map<String, dynamic> row) {
    // Set default values
    if (row['category'] == null || row['category'].toString().isEmpty) {
      row['category'] = 'General';
    }

    if (row['paymentMethod'] == null ||
        row['paymentMethod'].toString().isEmpty) {
      row['paymentMethod'] = 'Cash';
    }

    // CRITICAL FIX: Convert dates to milliseconds for ExpensePurchase
    final now = DateTime.now();

    // Handle 'date' field
    if (row['date'] == null) {
      row['date'] = now.millisecondsSinceEpoch;
    } else if (row['date'] is DateTime) {
      row['date'] = (row['date'] as DateTime).millisecondsSinceEpoch;
    } else if (row['date'] is String) {
      try {
        final parsed = DateTime.parse(row['date']);
        row['date'] = parsed.millisecondsSinceEpoch;
      } catch (e) {
        row['date'] = now.millisecondsSinceEpoch;
      }
    } else if (row['date'] is! int) {
      row['date'] = now.millisecondsSinceEpoch;
    }

    // Handle 'createdAt' field
    if (row['createdAt'] == null) {
      row['createdAt'] = now.millisecondsSinceEpoch;
    } else if (row['createdAt'] is DateTime) {
      row['createdAt'] = (row['createdAt'] as DateTime).millisecondsSinceEpoch;
    } else if (row['createdAt'] is String) {
      try {
        final parsed = DateTime.parse(row['createdAt']);
        row['createdAt'] = parsed.millisecondsSinceEpoch;
      } catch (e) {
        row['createdAt'] = now.millisecondsSinceEpoch;
      }
    } else if (row['createdAt'] is! int) {
      row['createdAt'] = now.millisecondsSinceEpoch;
    }

    // Handle 'updatedAt' field
    if (row['updatedAt'] == null) {
      row['updatedAt'] = now.millisecondsSinceEpoch;
    } else if (row['updatedAt'] is DateTime) {
      row['updatedAt'] = (row['updatedAt'] as DateTime).millisecondsSinceEpoch;
    } else if (row['updatedAt'] is String) {
      try {
        final parsed = DateTime.parse(row['updatedAt']);
        row['updatedAt'] = parsed.millisecondsSinceEpoch;
      } catch (e) {
        row['updatedAt'] = now.millisecondsSinceEpoch;
      }
    } else if (row['updatedAt'] is! int) {
      row['updatedAt'] = now.millisecondsSinceEpoch;
    }
  }

  // Fix the model conversion methods to handle DateTime properly:
  List<Map<String, dynamic>> _convertToCustomerLedgerEntries(
    String tableName,
    List<Map<String, dynamic>> rawData,
  ) {
    // Extract customer number from table name
    final parts = tableName.split('_');
    final customerNo = parts.length > 3
        ? parts.sublist(3).join('_')
        : 'unknown';

    return rawData.map((row) {
      try {
        final cleanedRow = _cleanRowWithEnhancedConversion(row);

        // Add customerNo if not present
        if (!cleanedRow.containsKey('customerNo')) {
          cleanedRow['customerNo'] = customerNo;
        }

        // Ensure date is properly formatted
        if (cleanedRow['date'] is DateTime) {
          cleanedRow['date'] = cleanedRow['date'].toIso8601String();
        }
        if (cleanedRow['createdAt'] is DateTime) {
          cleanedRow['createdAt'] = cleanedRow['createdAt'].toIso8601String();
        }
        if (cleanedRow['chequeDate'] is DateTime) {
          cleanedRow['chequeDate'] = cleanedRow['chequeDate'].toIso8601String();
        }

        // Convert to CustomerLedgerEntry
        final entry = CustomerLedgerEntry.fromMap(cleanedRow);
        return entry.toMap();
      } catch (e) {
        debugPrint('❌ Error converting to CustomerLedgerEntry: $e');
        debugPrint('❌ Row data: $row');
        // Return cleaned row as fallback with proper date formatting
        final fallbackRow = _cleanRowWithEnhancedConversion(row);
        if (fallbackRow['date'] is DateTime) {
          fallbackRow['date'] = fallbackRow['date'].toIso8601String();
        }
        return fallbackRow;
      }
    }).toList();
  }

  /// Convert to LedgerEntry with ledgerNo extraction
  List<Map<String, dynamic>> _convertToLedgerEntries(
    String tableName,
    List<Map<String, dynamic>> rawData,
  ) {
    // Extract ledger number from table name
    final parts = tableName.split('_');
    final ledgerNo = parts.length > 2 ? parts.sublist(2).join('_') : 'unknown';

    return rawData.map((row) {
      try {
        debugPrint('Processing ledger entry row: ${row.keys.toList()}');

        final cleanedRow = _cleanRowWithEnhancedConversion(row);
        debugPrint('Cleaned row keys: ${cleanedRow.keys.toList()}');

        // Apply type fixes
        final fixedRow = _fixTypeIssues(cleanedRow, tableName);

        // Add ledgerNo if not present
        if (!fixedRow.containsKey('ledgerNo')) {
          fixedRow['ledgerNo'] = ledgerNo;
        }

        // Debug balanceCans and receivedCans
        if (fixedRow.containsKey('balanceCans')) {
          debugPrint(
            'balanceCans type: ${fixedRow['balanceCans'].runtimeType}, value: ${fixedRow['balanceCans']}',
          );
        }
        if (fixedRow.containsKey('receivedCans')) {
          debugPrint(
            'receivedCans type: ${fixedRow['receivedCans'].runtimeType}, value: ${fixedRow['receivedCans']}',
          );
        }

        // Handle payment method and cheque fields
        _handlePaymentMethodFields(fixedRow);

        // Handle JSON fields
        if (fixedRow.containsKey('tags') && fixedRow['tags'] is String) {
          fixedRow['tags'] = _parseJsonField(fixedRow['tags']);
        }

        debugPrint('Attempting to create LedgerEntry from fixed row');
        // Convert to LedgerEntry
        final entry = LedgerEntry.fromMap(fixedRow);
        debugPrint('Successfully created LedgerEntry');
        return entry.toMap();
      } catch (e, stackTrace) {
        debugPrint('❌ Error converting to LedgerEntry: $e');
        debugPrint('Stack trace: $stackTrace');
        debugPrint('❌ Problematic row data: $row');

        // Return cleaned row as fallback with proper field handling
        final fallbackRow = _cleanRowWithEnhancedConversion(row);
        final fixedFallbackRow = _fixTypeIssues(fallbackRow, tableName);

        // Ensure string fields for LedgerEntry
        if (fixedFallbackRow['balanceCans'] != null) {
          fixedFallbackRow['balanceCans'] = fixedFallbackRow['balanceCans']
              .toString();
        }
        if (fixedFallbackRow['receivedCans'] != null) {
          fixedFallbackRow['receivedCans'] = fixedFallbackRow['receivedCans']
              .toString();
        }

        // Ensure itemId is int?
        if (fixedFallbackRow['itemId'] != null &&
            fixedFallbackRow['itemId'] is double) {
          fixedFallbackRow['itemId'] = (fixedFallbackRow['itemId'] as double)
              .toInt();
        }

        // Ensure cansQuantity is int?
        if (fixedFallbackRow['cansQuantity'] != null &&
            fixedFallbackRow['cansQuantity'] is double) {
          fixedFallbackRow['cansQuantity'] =
              (fixedFallbackRow['cansQuantity'] as double).toInt();
        }

        debugPrint('Returning fallback row');
        return fixedFallbackRow;
      }
    }).toList();
  }

  /// Handle payment method and cheque fields
  void _handlePaymentMethodFields(Map<String, dynamic> row) {
    final paymentMethod = (row['paymentMethod'] ?? 'cash')
        .toString()
        .toLowerCase();

    if (paymentMethod != 'cheque') {
      // Clear cheque fields if not cheque payment
      row['chequeNo'] = null;
      row['chequeAmount'] = null;
      row['chequeDate'] = null;
      row['bankName'] = null;
    }
  }

  /// Fix type conversion issues for problematic fields
  Map<String, dynamic> _fixTypeIssues(
    Map<String, dynamic> row,
    String tableName,
  ) {
    final fixedRow = Map<String, dynamic>.from(row);

    // Fix for cans table - handle accountId
    if (tableName == 'cans') {
      // Fix accountId - might be string like "cust"
      if (fixedRow['accountId'] is String) {
        final accountIdStr = fixedRow['accountId'] as String;
        if (accountIdStr.toLowerCase() == 'cust') {
          fixedRow['accountId'] = 1;
        } else {
          fixedRow['accountId'] = int.tryParse(accountIdStr) ?? 0;
        }
      }

      // Fix receivedCans if it's a JSON array like "[0]"
      if (fixedRow['receivedCans'] is String) {
        final receivedCansStr = fixedRow['receivedCans'] as String;
        if (receivedCansStr.startsWith('[') && receivedCansStr.endsWith(']')) {
          try {
            final jsonArray = jsonDecode(receivedCansStr) as List;
            if (jsonArray.isNotEmpty) {
              fixedRow['receivedCans'] = (jsonArray.first as num).toDouble();
            } else {
              fixedRow['receivedCans'] = 0.0;
            }
          } catch (e) {
            debugPrint('Error parsing receivedCans JSON: $e');
            fixedRow['receivedCans'] = 0.0;
          }
        } else {
          // Try to parse as double
          fixedRow['receivedCans'] = double.tryParse(receivedCansStr) ?? 0.0;
        }
      }
    }

    // Fix for ledger entry tables
    if (_ledgerEntryPattern.hasMatch(tableName)) {
      // Handle balanceCans and receivedCans fields that might be JSON arrays
      final specialFields = ['balanceCans', 'receivedCans'];
      for (var field in specialFields) {
        if (fixedRow[field] is String) {
          final fieldValue = fixedRow[field] as String;
          if (fieldValue.startsWith('[') && fieldValue.endsWith(']')) {
            try {
              final jsonArray = jsonDecode(fieldValue) as List;
              if (jsonArray.isNotEmpty) {
                fixedRow[field] = jsonArray.first.toString();
              } else {
                fixedRow[field] = '0';
              }
            } catch (e) {
              debugPrint('Error parsing $field JSON: $e');
              fixedRow[field] = '0';
            }
          }
          // Already a string, keep it as is
        } else if (fixedRow[field] is num) {
          // Convert number to string
          fixedRow[field] = fixedRow[field].toString();
        } else if (fixedRow[field] is List) {
          // Handle direct List type
          final listValue = fixedRow[field] as List;
          if (listValue.isNotEmpty) {
            fixedRow[field] = listValue.first.toString();
          } else {
            fixedRow[field] = '0';
          }
        }
      }

      // Fix itemId, cansQuantity which should be int?
      if (fixedRow['itemId'] != null) {
        if (fixedRow['itemId'] is double) {
          fixedRow['itemId'] = (fixedRow['itemId'] as double).toInt();
        } else if (fixedRow['itemId'] is String) {
          fixedRow['itemId'] = int.tryParse(fixedRow['itemId'] as String);
        }
      }

      if (fixedRow['cansQuantity'] != null) {
        if (fixedRow['cansQuantity'] is double) {
          fixedRow['cansQuantity'] = (fixedRow['cansQuantity'] as double)
              .toInt();
        } else if (fixedRow['cansQuantity'] is String) {
          fixedRow['cansQuantity'] =
              int.tryParse(fixedRow['cansQuantity'] as String) ?? 0;
        }
      }
    }

    if (tableName == 'expense_purchases') {
      // Fix date fields - ensure they're int (milliseconds)
      final dateFields = ['date', 'createdAt', 'updatedAt'];
      for (var field in dateFields) {
        if (fixedRow[field] is DateTime) {
          fixedRow[field] =
              (fixedRow[field] as DateTime).millisecondsSinceEpoch;
        }
      }
    }

    return fixedRow;
  }

  // Fix the validation method to not require accountName for customer_ledger_entries:
  Future<Map<String, dynamic>> _validateTableData(
    String tableName,
    List<Map<String, dynamic>> data,
  ) async {
    try {
      if (_customerLedgerPattern.hasMatch(tableName) ||
          _itemLedgerPattern.hasMatch(tableName)) {
        debugPrint('⚠️ Skipping validation for ledger table: $tableName');
        return {
          'valid': true,
          'message': 'Validation skipped for ledger table',
        };
      }
      if (data.isEmpty) {
        return {'valid': true, 'message': 'Empty data - valid'};
      }

      final firstRow = data.first;
      final errors = <String>[];

      // Check required fields based on table type
      if (tableName == 'customer') {
        final requiredFields = ['name', 'customerNo', 'mobileNo', 'type'];
        for (var field in requiredFields) {
          if (!firstRow.containsKey(field) || firstRow[field] == null) {
            errors.add('Missing required field: $field');
          }
        }
      } else if (tableName == 'item') {
        final requiredFields = ['name', 'type', 'vendor'];
        for (var field in requiredFields) {
          if (!firstRow.containsKey(field) || firstRow[field] == null) {
            errors.add('Missing required field: $field');
          }
        }
      } else if (_ledgerEntryPattern.hasMatch(tableName)) {
        final requiredFields = [
          'voucherNo',
          'accountName',
          'date',
          'transactionType',
        ];
        for (var field in requiredFields) {
          if (!firstRow.containsKey(field) || firstRow[field] == null) {
            errors.add('Missing required field: $field');
          }
        }
      } else if (_customerLedgerPattern.hasMatch(tableName)) {
        // FIXED: Customer ledger entries use 'customerName' not 'accountName'
        final requiredFields = [
          'voucherNo',
          'customerName', // This is the key change
          'date',
          'transactionType',
        ];
        for (var field in requiredFields) {
          if (!firstRow.containsKey(field) || firstRow[field] == null) {
            errors.add('Missing required field: $field');
          }
        }
      } else if (_itemLedgerPattern.hasMatch(tableName)) {
        // Item ledger entries have different required fields
        final requiredFields = [
          'voucherNo',
          'itemName',
          'vendorName',
          'transactionType',
        ];
        for (var field in requiredFields) {
          if (!firstRow.containsKey(field) || firstRow[field] == null) {
            errors.add('Missing required field: $field');
          }
        }
      } else if (tableName == 'vendor_ledger_entries') {
        final requiredFields = [
          'voucherNo',
          'vendorName',
          'vendorId',
          'date',
          'transactionType',
        ];
        for (var field in requiredFields) {
          if (!firstRow.containsKey(field) || firstRow[field] == null) {
            errors.add('Missing required field: $field');
          }
        }
      }

      // Validate data types - be more lenient
      for (var row in data.take(3)) {
        // Check first 3 rows
        for (var entry in row.entries) {
          final key = entry.key;
          final value = entry.value;

          // Check numeric fields
          if (key.contains('balance') ||
              key.contains('debit') ||
              key.contains('credit') ||
              key.contains('amount') ||
              key.contains('price') ||
              key.contains('cost') ||
              key.contains('quantity') ||
              key.contains('weight') ||
              key.contains('stock')) {
            if (value != null && value is! num && value is! String) {
              errors.add(
                'Field $key should be numeric but got ${value.runtimeType}',
              );
            }
          }

          // Check date fields - accept both DateTime and String
          if (key.contains('date') ||
              key.contains('Date') ||
              key.endsWith('At')) {
            if (value != null &&
                value is! DateTime &&
                value is! String &&
                value is! int) {
              errors.add(
                'Field $key should be DateTime, String, or int but got ${value.runtimeType}',
              );
            }
          }
        }
      }

      if (errors.isNotEmpty) {
        debugPrint('❌ Validation errors for $tableName: $errors');
        return {
          'valid': false,
          'error': 'Validation failed: ${errors.join(', ')}',
          'errors': errors,
        };
      }

      return {'valid': true, 'message': 'Validation passed'};
    } catch (e) {
      debugPrint('❌ Error validating table $tableName: $e');
      return {'valid': false, 'error': 'Validation error: $e'};
    }
  }

  /// Create dynamic ledger entry table
  Future<void> _createDynamicLedgerEntryTable(String tableName) async {
    // final Database db = await dbHelper.database; // FIXED: Use the db variable

    // Extract ledgerNo from table name
    final parts = tableName.split('_');
    final ledgerNo = parts.length > 2 ? parts.sublist(2).join('_') : 'default';

    // Use DBHelper's createLedgerEntryTable method
    await dbHelper.createLedgerEntryTable(ledgerNo);

    debugPrint(
      '📄 Created dynamic ledger entry table: $tableName (ledgerNo: $ledgerNo)',
    );
  }

  /// Create dynamic customer ledger entry table
  Future<void> _createDynamicCustomerLedgerTable(String tableName) async {
    final Database db = await dbHelper.database; // FIXED: Use the db variable

    await db.execute('''
      CREATE TABLE IF NOT EXISTS `$tableName` (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        voucherNo TEXT NOT NULL,
        date TEXT NOT NULL,
        customerName TEXT NOT NULL,
        description TEXT NOT NULL,
        debit REAL NOT NULL,
        credit REAL NOT NULL,
        balance REAL NOT NULL,
        transactionType TEXT NOT NULL,
        paymentMethod TEXT,
        chequeNo TEXT,
        chequeAmount REAL,
        chequeDate TEXT,
        bankName TEXT,
        createdAt TEXT NOT NULL,
        customerNo TEXT
      )
    ''');

    debugPrint('📄 Created dynamic customer ledger table: $tableName');
  }

  /// Create dynamic item ledger entry table
  Future<void> _createDynamicItemLedgerTable(String tableName) async {
    // final Database db = await dbHelper.database; // FIXED: Use the db variable

    // Extract ledgerNo from table name
    final parts = tableName.split('_');
    final ledgerNo = parts.length > 3 ? parts.sublist(3).join('_') : 'default';

    // Use DBHelper's createItemLedgerEntryTable method
    await dbHelper.createItemLedgerEntryTable(ledgerNo);

    debugPrint(
      '📄 Created dynamic item ledger table: $tableName (ledgerNo: $ledgerNo)',
    );
  }

  /// Create generic table with columns from data
  Future<void> _createGenericTable(
    String tableName,
    List<Map<String, dynamic>> data,
  ) async {
    if (data.isEmpty) return;

    final Database db = await dbHelper.database; // FIXED: Use the db variable
    final firstRow = data.first;

    // Get column names and determine types
    final columns = <String, String>{};

    for (var key in firstRow.keys) {
      final value = firstRow[key];

      if (value == null) {
        columns[key] = 'TEXT';
      } else if (value is int) {
        columns[key] = 'INTEGER';
      } else if (value is double) {
        columns[key] = 'REAL';
      } else if (value is DateTime) {
        columns[key] = 'TEXT';
      } else if (value is bool) {
        columns[key] = 'INTEGER';
      } else {
        columns[key] = 'TEXT';
      }
    }

    // Build CREATE TABLE SQL
    final columnDefs = columns.entries
        .map((entry) => '`${entry.key}` ${entry.value}')
        .join(', ');

    final sql = 'CREATE TABLE IF NOT EXISTS `$tableName` ($columnDefs)';

    await db.execute(sql);
    debugPrint(
      '📄 Created generic table: $tableName with ${columns.length} columns',
    );
  }

  /// Insert model data into database with proper handling
  Future<bool> _insertModelData(
    String tableName,
    List<Map<String, dynamic>> data,
  ) async {
    if (data.isEmpty) {
      debugPrint('📭 No data to insert for $tableName');
      return true;
    }

    final Database db = await dbHelper.database;

    try {
      // Use transaction for atomic operations
      await db.transaction((txn) async {
        // Prepare batch for performance
        final batch = txn.batch();

        for (var row in data) {
          // Convert DateTime to proper format for database
          final dbRow = _convertForDatabaseInsert(row);

          // Insert row
          batch.insert(
            tableName,
            dbRow,
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }

        await batch.commit(noResult: true);
      });

      debugPrint('💾 Inserted ${data.length} rows into $tableName');
      return true;
    } catch (e) {
      debugPrint('❌ Error inserting data into $tableName: $e');
      return false;
    }
  }

  /// Convert row for database insertion (handle DateTime, JSON, etc.)
  /// Convert row for database insertion (handle DateTime, JSON, etc.)
  Map<String, dynamic> _convertForDatabaseInsert(Map<String, dynamic> row) {
    final dbRow = <String, dynamic>{};

    for (var entry in row.entries) {
      final key = entry.key;
      var value = entry.value;

      // Convert DateTime to proper format for database
      if (value is DateTime) {
        // For cans table, always use ISO8601
        if (row.containsKey('accountName') &&
            (row.containsKey('openingBalanceCans') ||
                row.containsKey('currentCans'))) {
          // Likely cans table - use ISO8601
          value = value.toIso8601String();
        } else if (key == 'createdAt' || key == 'updatedAt') {
          // Check if it's ExpensePurchase or ItemLedgerEntry (milliseconds)
          if (row.containsKey('amount') && row.containsKey('madeBy')) {
            // Likely ExpensePurchase - use milliseconds
            value = value.millisecondsSinceEpoch;
          } else if (row.containsKey('pricePerKg') &&
              row.containsKey('canWeight')) {
            // Likely ItemLedgerEntry - use milliseconds
            value = value.millisecondsSinceEpoch;
          } else {
            // Default: ISO8601
            value = value.toIso8601String();
          }
        } else if (key == 'chequeDate') {
          // Cheque date should be ISO8601
          value = value.toIso8601String();
        } else if (key == 'insertedDate' || key == 'updatedDate') {
          // Cans table dates - ISO8601
          value = value.toIso8601String();
        } else if (key == 'date') {
          // Check context for date field
          if (row.containsKey('voucherNo') &&
              row.containsKey('transactionType')) {
            // Likely ledger entry - ISO8601
            value = value.toIso8601String();
          } else if (row.containsKey('madeBy') && row.containsKey('category')) {
            // ExpensePurchase - milliseconds
            value = value.millisecondsSinceEpoch;
          } else {
            // Default: ISO8601
            value = value.toIso8601String();
          }
        } else {
          // Default: ISO8601
          value = value.toIso8601String();
        }
      }
      // Convert List to JSON string
      else if (value is List) {
        try {
          value = jsonEncode(value);
        } catch (e) {
          debugPrint('Warning: Could not encode list for $key: $e');
          value = null;
        }
      }
      // Convert Map to JSON string
      else if (value is Map) {
        try {
          value = jsonEncode(value);
        } catch (e) {
          debugPrint('Warning: Could not encode map for $key: $e');
          value = null;
        }
      }
      // Convert bool to int
      else if (value is bool) {
        value = value ? 1 : 0;
      }

      dbRow[key] = value;
    }

    return dbRow;
  }

  /// Convert to JSON serializable format
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

    // Fallback
    try {
      if (model is Map<String, dynamic>) return model;
      return model.toMap() as Map<String, dynamic>;
    } catch (e) {
      debugPrint('❌ Error converting model to map: $e');
      return {};
    }
  }

  /// Clean and convert generic data
  List<Map<String, dynamic>> _cleanAndConvertGenericData(
    List<Map<String, dynamic>> rawData,
  ) {
    return rawData.map(_cleanRowWithEnhancedConversion).toList();
  }

  // ==================== EXISTING METHODS FROM YOUR ORIGINAL CODE ====================
  // These methods already exist in your original code and need to be kept

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
  // Replace the _clearLocalDatabase method with this version:
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

      // IMPORTANT: Recreate all standard tables by reinitializing the database
      await _recreateDatabase();

      debugPrint('✅ Database cleared and recreated successfully');
    } catch (e) {
      debugPrint('Error clearing database: $e');
      rethrow;
    }
  }

  /// Recreate the database by closing and reopening it
  Future<void> _recreateDatabase() async {
    try {
      // Close the existing database connection
      if (_database != null) {
        await _database!.close();
        _database = null;
      }

      // Reinitialize the database (this will trigger onCreate)
      await dbHelper.database;

      debugPrint('✅ Database recreated successfully');
    } catch (e) {
      debugPrint('❌ Error recreating database: $e');
      rethrow;
    }
  }

  // Update the _ensureDatabaseTable method to simplify table creation:
  Future<void> _ensureDatabaseTable(
    String tableName,
    List<Map<String, dynamic>> data,
  ) async {
    final Database db = await dbHelper.database;

    try {
      // Check if table exists
      final tableExists = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name=?",
        [tableName],
      );

      if (tableExists.isNotEmpty) {
        debugPrint('✅ Table $tableName already exists');
        return;
      }

      // Create table based on table type
      if (_modelConstructors.containsKey(tableName)) {
        // For standard tables, we'll create them directly
        debugPrint('📋 Creating standard table: $tableName');

        if (tableName == 'customer') {
          await db.execute('''
          CREATE TABLE customer(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            address TEXT NOT NULL,
            customerNo TEXT NOT NULL,
            mobileNo TEXT NOT NULL,
            type TEXT NOT NULL,
            ntnNo TEXT,
            openingBalance REAL DEFAULT 0.0
          )
        ''');
        } else if (tableName == 'item') {
          await db.execute('''
          CREATE TABLE item(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            type TEXT NOT NULL,
            vendor TEXT NOT NULL,
            pricePerKg REAL DEFAULT 0.0,
            costPrice REAL DEFAULT 0.0,
            sellingPrice REAL DEFAULT 0.0,
            availableStock REAL DEFAULT 0.0,
            canWeight REAL DEFAULT 0.0
          )
        ''');
        } else if (tableName == 'ledger') {
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
        } else if (tableName == 'stock_transaction') {
          await db.execute('''
          CREATE TABLE stock_transaction(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            itemId INTEGER NOT NULL,
            quantity REAL NOT NULL,
            date TEXT NOT NULL,
            type TEXT NOT NULL
          )
        ''');
        } else if (tableName == 'expense_purchases') {
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
        } else if (tableName == 'cans') {
          await db.execute('''
          CREATE TABLE cans (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            accountName TEXT NOT NULL,
            accountId INTEGER,
            openingBalanceCans REAL DEFAULT 0,
            currentCans REAL DEFAULT 0,
            totalCans REAL DEFAULT 0,
            receivedCans REAL DEFAULT 0,
            insertedDate TEXT NOT NULL,
            updatedDate TEXT NOT NULL
          )
        ''');
          // Add unique constraint separately
          await db.execute('''
          CREATE UNIQUE INDEX IF NOT EXISTS idx_cans_account
          ON cans(accountId, accountName)
        ''');
        } else if (tableName == 'cans_entries') {
          await db.execute('''
          CREATE TABLE cans_entries (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            cansId INTEGER NOT NULL,
            voucherNo TEXT NOT NULL,
            accountId INTEGER,
            accountName TEXT NOT NULL,
            date TEXT NOT NULL,
            transactionType TEXT NOT NULL,
            currentCans REAL DEFAULT 0,
            receivedCans REAL DEFAULT 0,
            balance REAL DEFAULT 0,
            description TEXT,
            createdAt TEXT NOT NULL,
            updatedAt TEXT NOT NULL
          )
        ''');
        } else if (tableName == 'vendor_ledger_entries') {
          await db.execute('''
          CREATE TABLE vendor_ledger_entries (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            voucherNo TEXT NOT NULL,
            vendorName TEXT NOT NULL,
            vendorId INTEGER NOT NULL,
            date TEXT NOT NULL,
            description TEXT,
            debit REAL DEFAULT 0.0,
            credit REAL DEFAULT 0.0,
            balance REAL DEFAULT 0.0,
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
        debugPrint('✅ Created standard table: $tableName');
      } else if (_customerLedgerPattern.hasMatch(tableName)) {
        // Create dynamic customer ledger entry table
        await _createDynamicCustomerLedgerTable(tableName);
      } else if (_itemLedgerPattern.hasMatch(tableName)) {
        // Create dynamic item ledger entry table
        await _createDynamicItemLedgerTable(tableName);
      } else if (_ledgerEntryPattern.hasMatch(tableName)) {
        // Create dynamic ledger entry table
        await _createDynamicLedgerEntryTable(tableName);
      } else {
        // Create generic table with columns from data
        await _createGenericTable(tableName, data);
      }

      debugPrint('✅ Created/ensured table: $tableName');
    } catch (e) {
      debugPrint('❌ Error ensuring table $tableName: $e');
      rethrow;
    }
  }

  // Also, we need to add the Database variable to the SheetSyncService class:
  Database? _database;

  // Update the existing getAllTableNames method to use the correct approach:
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

  /// Store hash for table
  Future<void> _storeHash(String tableName, String hash) async {
    await initPrefs();
    await prefs.setString('hash_$tableName', hash);
    debugPrint('💾 Stored hash for $tableName: $hash');
  }

  /// Check internet connection
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

  /// Calculate data hash
  Future<String> _calculateDataHash(List<Map<String, dynamic>> data) async {
    if (data.isEmpty) return 'empty';

    final serializableData = data.map(_convertToJsonSerializable).toList();
    var dataString = jsonEncode(serializableData);
    var bytes = utf8.encode(dataString);
    var digest = md5.convert(bytes);
    return digest.toString();
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

  void stopAutoSync() {
    syncTimer?.cancel();
    syncTimer = null;
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

  Future<String> _getStoredHash(String tableName) async {
    await initPrefs();
    return prefs.getString('hash_$tableName') ?? 'first_time';
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
      // final columns = info.first.keys.join(', ');
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

  List<Map<String, dynamic>> _convertToVendorLedgerEntries(
    List<Map<String, dynamic>> rawData,
  ) {
    return rawData.map((row) {
      try {
        final cleanedRow = _cleanRowWithEnhancedConversion(row);

        // Ensure dates are properly formatted
        if (cleanedRow['date'] is DateTime) {
          cleanedRow['date'] = cleanedRow['date'].toIso8601String();
        }
        if (cleanedRow['createdAt'] is DateTime) {
          cleanedRow['createdAt'] = cleanedRow['createdAt'].toIso8601String();
        }
        if (cleanedRow['updatedAt'] is DateTime) {
          cleanedRow['updatedAt'] = cleanedRow['updatedAt'].toIso8601String();
        }
        if (cleanedRow['chequeDate'] is DateTime) {
          cleanedRow['chequeDate'] = cleanedRow['chequeDate'].toIso8601String();
        }

        final entry = VendorLedgerEntry.fromMap(cleanedRow);
        return entry.toMap();
      } catch (e) {
        debugPrint('❌ Error converting to VendorLedgerEntry: $e');
        debugPrint('❌ Row data: $row');
        // Return cleaned row as fallback with proper date formatting
        final fallbackRow = _cleanRowWithEnhancedConversion(row);
        if (fallbackRow['date'] is DateTime) {
          fallbackRow['date'] = fallbackRow['date'].toIso8601String();
        }
        return fallbackRow;
      }
    }).toList();
  }

  List<Map<String, dynamic>> _convertToItemLedgerEntries(
    String tableName,
    List<Map<String, dynamic>> rawData,
  ) {
    // Extract ledgerNo from table name
    final parts = tableName.split('_');
    final ledgerNo = parts.length > 3 ? parts.sublist(3).join('_') : 'unknown';

    return rawData.map((row) {
      try {
        final cleanedRow = _cleanRowWithEnhancedConversion(row);

        // Add ledgerNo if not present
        if (!cleanedRow.containsKey('ledgerNo')) {
          cleanedRow['ledgerNo'] = ledgerNo;
        }

        // Handle numeric conversions
        _ensureItemLedgerNumericFields(cleanedRow);

        // Ensure dates are in milliseconds for ItemLedgerEntry
        if (cleanedRow['createdAt'] is DateTime) {
          cleanedRow['createdAt'] =
              cleanedRow['createdAt'].millisecondsSinceEpoch;
        }
        if (cleanedRow['updatedAt'] is DateTime) {
          cleanedRow['updatedAt'] =
              cleanedRow['updatedAt'].millisecondsSinceEpoch;
        }

        final entry = ItemLedgerEntry.fromMap(cleanedRow);
        return entry.toMap();
      } catch (e) {
        debugPrint('❌ Error converting to ItemLedgerEntry: $e');
        debugPrint('❌ Row data: $row');
        return _cleanRowWithEnhancedConversion(row);
      }
    }).toList();
  }

  /// Ensure numeric fields in ItemLedgerEntry
  void _ensureItemLedgerNumericFields(Map<String, dynamic> row) {
    final numericFields = [
      'debit',
      'pricePerKg',
      'costPrice',
      'sellingPrice',
      'canWeight',
      'credit',
      'newStock',
      'balance',
    ];

    for (var field in numericFields) {
      if (row[field] == null) {
        row[field] = 0.0;
      }
    }

    // Set dates if not provided
    final now = DateTime.now();
    if (row['createdAt'] == null) row['createdAt'] = now;
    if (row['updatedAt'] == null) row['updatedAt'] = now;
  }
}
