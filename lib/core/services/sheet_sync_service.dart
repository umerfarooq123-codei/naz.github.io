import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:ledger_master/core/database/db_helper.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class SheetSyncService {
  static const String webAppUrl =
      'https://script.google.com/macros/s/AKfycbzkQ2HaAGUYiD9Vm4Ox5aX9bQfimJ7S_3bDGGMYRXk2BaZaurpfSNvlCXPZHXd2pnAe/exec';

  final DBHelper dbHelper = DBHelper();
  late SharedPreferences _prefs;

  // ==================== SINGLE UNIFIED SYNC FUNCTION ====================

  // **THIS IS THE ONLY FUNCTION YOU NEED TO CALL**
  Future<Map<String, dynamic>> syncData() async {
    final stopwatch = Stopwatch()..start(); // Start timer at the beginning

    try {
      await _initPrefs();

      // Get all table names
      List<String> tables = await getAllTableNames();
      debugPrint('🚀 Starting sync - Found ${tables.length} tables');

      Map<String, dynamic> results = {};
      int syncedCount = 0;
      int skippedCount = 0;
      int failedCount = 0;

      for (String table in tables) {
        try {
          // Get current table data
          List<Map<String, dynamic>> localData = await getLocalTableData(table);

          // Calculate current hash
          String currentHash = await _calculateDataHash(localData);

          // Get stored hash from last sync
          String storedHash = await _getStoredHash(table);

          // Check if we need to sync
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
              results[table] = {
                'success': true,
                'action': 'synced',
                'rows': localData.length,
              };
              debugPrint('✅ Synced: $table (${localData.length} rows)');
            } else {
              failedCount++;
              results[table] = {'success': false, 'action': 'failed'};
              debugPrint('❌ Failed: $table');
            }
          } else {
            skippedCount++;
            results[table] = {
              'success': true,
              'action': 'skipped',
              'rows': localData.length,
            };
            debugPrint('⚡ Skipped: $table (no changes)');
          }
        } catch (e) {
          failedCount++;
          results[table] = {'success': false, 'error': e.toString()};
          debugPrint('❌ Error: $table - $e');
        }
      }

      stopwatch.stop(); // Stop timer at the end

      final executionTime = stopwatch.elapsed;
      final minutes = executionTime.inMinutes;
      final seconds = executionTime.inSeconds % 60;
      final milliseconds = executionTime.inMilliseconds % 1000;

      debugPrint(
        '⏱️ Total execution time: ${minutes}m ${seconds}s ${milliseconds}ms',
      );

      return {
        'success': failedCount == 0,
        'message':
            'Sync completed: $syncedCount synced, $skippedCount skipped, $failedCount failed',
        'totalTables': tables.length,
        'synced': syncedCount,
        'skipped': skippedCount,
        'failed': failedCount,
        'results': results,
        'executionTime': executionTime.toString(),
        'executionTimeMs': executionTime.inMilliseconds,
        'executionTimeFormatted': '${minutes}m ${seconds}s ${milliseconds}ms',
        'timestamp': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      stopwatch.stop();
      debugPrint('❌ Fatal sync error: $e');
      debugPrint('⏱️ Failed after: ${stopwatch.elapsed}');

      return {
        'success': false,
        'error': e.toString(),
        'executionTime': stopwatch.elapsed.toString(),
        'timestamp': DateTime.now().toIso8601String(),
      };
    }
  }

  // ==================== CORE SYNC LOGIC ====================

  // Sync a single table to Google Sheets
  Future<bool> _syncTableToSheets(
    String tableName,
    List<Map<String, dynamic>> data,
    String currentHash,
  ) async {
    try {
      if (data.isEmpty) {
        debugPrint('📭 Table $tableName is empty, skipping');
        await _storeHash(tableName, 'empty');
        return true;
      }

      http.Response response = await http.post(
        Uri.parse(webAppUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'operation': 'sync',
          'tableName': tableName,
          'data': data,
        }),
      );

      // Success conditions: 200 OK or 302 Redirect
      bool success = response.statusCode == 200 || response.statusCode == 302;

      if (success) {
        // Store the hash after successful sync
        await _storeHash(tableName, currentHash);
        return true;
      } else {
        debugPrint('❌ HTTP ${response.statusCode} for table: $tableName');
        return false;
      }
    } catch (e) {
      debugPrint('❌ Sync error for $tableName: $e');
      return false;
    }
  }

  // ==================== HASH MANAGEMENT ====================

  // Calculate hash of data
  Future<String> _calculateDataHash(List<Map<String, dynamic>> data) async {
    if (data.isEmpty) return 'empty';

    var dataString = jsonEncode(data);
    var bytes = utf8.encode(dataString);
    var digest = md5.convert(bytes);
    return digest.toString();
  }

  // Get stored hash from SharedPreferences
  Future<String> _getStoredHash(String tableName) async {
    await _initPrefs();
    return _prefs.getString('hash_$tableName') ?? 'first_time';
  }

  // Store hash in SharedPreferences
  Future<void> _storeHash(String tableName, String hash) async {
    await _initPrefs();
    await _prefs.setString('hash_$tableName', hash);
  }

  // Initialize SharedPreferences
  Future<void> _initPrefs() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // Clear all stored hashes (for testing/reset)
  Future<void> resetSyncStatus() async {
    await _initPrefs();
    final keys = _prefs.getKeys().where((key) => key.startsWith('hash_'));
    for (String key in keys) {
      await _prefs.remove(key);
    }
    debugPrint('🔄 All sync statuses reset');
  }

  // ==================== HELPER METHODS ====================

  // Get all table names from database
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

  // Get all data from local table
  Future<List<Map<String, dynamic>>> getLocalTableData(String tableName) async {
    try {
      Database db = await dbHelper.database;
      return await db.query(tableName);
    } catch (e) {
      debugPrint('Error getting data for $tableName: $e');
      return [];
    }
  }

  // Get row count from local table
  Future<int> getLocalRowCount(String tableName) async {
    try {
      Database db = await dbHelper.database;
      List<Map<String, dynamic>> result = await db.rawQuery(
        'SELECT COUNT(*) as count FROM $tableName',
      );
      return result.first['count'] as int;
    } catch (e) {
      debugPrint('Error getting local count for $tableName: $e');
      return 0;
    }
  }

  // ==================== UTILITY METHODS ====================

  // Check if any table needs sync
  Future<bool> hasChanges() async {
    List<String> tables = await getAllTableNames();

    for (String table in tables) {
      List<Map<String, dynamic>> data = await getLocalTableData(table);
      String currentHash = await _calculateDataHash(data);
      String storedHash = await _getStoredHash(table);

      if (currentHash != storedHash) {
        return true;
      }
    }

    return false;
  }

  // Get sync summary
  Future<Map<String, dynamic>> getSyncSummary() async {
    List<String> tables = await getAllTableNames();
    Map<String, dynamic> summary = {};
    int changedCount = 0;

    for (String table in tables) {
      List<Map<String, dynamic>> data = await getLocalTableData(table);
      String currentHash = await _calculateDataHash(data);
      String storedHash = await _getStoredHash(table);

      bool hasChanges = currentHash != storedHash;
      if (hasChanges) changedCount++;

      summary[table] = {
        'rowCount': data.length,
        'hasChanges': hasChanges,
        'currentHash': currentHash.substring(0, 8),
        'storedHash': storedHash.substring(0, 8),
      };
    }

    return {
      'totalTables': tables.length,
      'changedTables': changedCount,
      'allSynced': changedCount == 0,
      'summary': summary,
    };
  }

  // Force sync a specific table (bypass hash check)
  Future<bool> forceSyncTable(String tableName) async {
    try {
      List<Map<String, dynamic>> data = await getLocalTableData(tableName);
      String hash = await _calculateDataHash(data);
      return await _syncTableToSheets(tableName, data, hash);
    } catch (e) {
      debugPrint('Error force syncing $tableName: $e');
      return false;
    }
  }

  // Test API connection
  Future<bool> testConnection() async {
    try {
      http.Response response = await http.post(
        Uri.parse(webAppUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'operation': 'get_all_statuses'}),
      );

      return response.statusCode == 200 || response.statusCode == 302;
    } catch (e) {
      debugPrint('Connection test failed: $e');
      return false;
    }
  }
}
