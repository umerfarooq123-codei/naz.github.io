import 'dart:async';
import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:ledger_master/core/database/db_helper.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class SheetSyncService extends GetxService {
  static const String webAppUrl =
      'https://script.google.com/macros/s/AKfycbzkQ2HaAGUYiD9Vm4Ox5aX9bQfimJ7S_3bDGGMYRXk2BaZaurpfSNvlCXPZHXd2pnAe/exec';

  final DBHelper dbHelper = DBHelper();
  late SharedPreferences _prefs;

  // Automatic sync timer
  Timer? _syncTimer;

  // Reactive sync status
  final isSyncing = false.obs;
  final lastSyncTime = Rx<DateTime?>(null);
  final nextSyncTime = Rx<DateTime?>(null);
  final syncSettings = Rx<Map<String, dynamic>>({
    'hours': 0,
    'minutes': 0,
    'enabled': false,
  });

  @override
  void onInit() {
    super.onInit();
    _initService();
  }

  @override
  void onClose() {
    _stopAutoSync();
    super.onClose();
  }

  // ==================== SERVICE INITIALIZATION ====================

  Future<void> _initService() async {
    await _initPrefs();
    await _loadSyncSettings();
    await _loadLastSyncTime();
    await _startAutoSync();
  }

  Future<void> _initPrefs() async {
    _prefs = await SharedPreferences.getInstance();
  }

  Future<void> _loadSyncSettings() async {
    final settingsData = _prefs.getString('backup_sync_settings');
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

  Future<void> _loadLastSyncTime() async {
    final lastSyncString = _prefs.getString('last_sync_time');
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
    await _prefs.setString('last_sync_time', now.toIso8601String());
  }

  // ==================== INTERNET CHECK ====================

  Future<bool> _checkInternetConnection() async {
    try {
      // Simple internet check - try to reach Google
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

  Future<void> _startAutoSync() async {
    _stopAutoSync();

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
      _syncTimer = Timer(delay, () async {
        await _performAutoSync();
      });
    }

    _schedulePeriodicCheck();
  }

  Future<void> _performAutoSync() async {
    if (isSyncing.value) return;

    // Check internet before syncing
    final hasInternet = await _checkInternetConnection();
    if (!hasInternet) {
      debugPrint('🌐 Skipping auto sync: No internet');
      return;
    }

    debugPrint('🔄 Starting automatic sync...');
    await syncData();
    await _startAutoSync(); // Schedule next
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

  void _stopAutoSync() {
    _syncTimer?.cancel();
    _syncTimer = null;
  }

  // Update sync settings from AutomationController
  Future<void> updateSyncSettings(Map<String, dynamic> newSettings) async {
    syncSettings.value = newSettings;
    await _prefs.setString('backup_sync_settings', jsonEncode(newSettings));
    await _startAutoSync();
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

    // Check internet before showing dialog
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
      final result = await syncData();
      Get.back();

      // Show simple result dialog
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

  Future<Map<String, dynamic>> syncData() async {
    final stopwatch = Stopwatch()..start();

    try {
      await _initPrefs();

      // Check internet before starting sync
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

      for (String table in tables) {
        try {
          List<Map<String, dynamic>> localData = await getLocalTableData(table);
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
              debugPrint('❌ Failed: $table');
            }
          } else {
            skippedCount++;
            debugPrint('⚡ Skipped: $table');
          }
        } catch (e) {
          failedCount++;
          debugPrint('❌ Error: $table - $e');
        }
      }

      stopwatch.stop();
      debugPrint('⏱️ Total time: ${stopwatch.elapsed}');

      if (failedCount == 0) {
        await _saveLastSyncTime();
      }

      return {
        'success': failedCount == 0,
        'message':
            'Sync completed: $syncedCount synced, $skippedCount skipped, $failedCount failed',
        'synced': syncedCount,
        'skipped': skippedCount,
        'failed': failedCount,
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

      bool success = response.statusCode == 200 || response.statusCode == 302;

      if (success) {
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

  // ==================== HELPER METHODS ====================

  Future<String> _calculateDataHash(List<Map<String, dynamic>> data) async {
    if (data.isEmpty) return 'empty';
    var dataString = jsonEncode(data);
    var bytes = utf8.encode(dataString);
    var digest = md5.convert(bytes);
    return digest.toString();
  }

  Future<String> _getStoredHash(String tableName) async {
    await _initPrefs();
    return _prefs.getString('hash_$tableName') ?? 'first_time';
  }

  Future<void> _storeHash(String tableName, String hash) async {
    await _initPrefs();
    await _prefs.setString('hash_$tableName', hash);
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
