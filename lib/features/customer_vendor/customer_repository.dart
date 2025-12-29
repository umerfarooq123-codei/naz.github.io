import 'package:flutter/foundation.dart';
import 'package:ledger_master/features/customer_vendor/customer_list.dart';
import 'package:sqflite/sqflite.dart';

import '../../core/database/db_helper.dart';
import '../../core/models/customer.dart';

class CustomerRepository {
  final DBHelper _dbHelper = DBHelper();

  Future<int> insertCustomer(Customer customer) async {
    final db = await _dbHelper.database;
    return await db.insert(
      'customer',
      customer.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Customer>> getAllCustomers() async {
    final db = await _dbHelper.database;
    final result = await db.query('customer', orderBy: 'name ASC');
    return result.map((e) => Customer.fromMap(e)).toList();
  }

  Future<Customer?> getCustomer(String accountId) async {
    final db = await _dbHelper.database;
    final result = await db.query(
      'customer',
      where: 'id = ?',
      whereArgs: [accountId],
      limit: 1,
    );

    if (result.isNotEmpty) {
      return Customer.fromMap(result.first);
    } else {
      return null;
    }
  }

  Future<Customer?> getCustomerByName(String customerName) async {
    final db = await _dbHelper.database;
    final result = await db.query(
      'customer',
      where: 'name = ? AND type = \'Customer\'',
      whereArgs: [customerName.toLowerCase()],
      limit: 1,
    );

    if (result.isNotEmpty) {
      return Customer.fromMap(result.first);
    } else {
      return null;
    }
  }

  /// ✅ FIXED: Get customer's opening balance with case-insensitive search
  Future<double> getOpeningBalanceForCustomer(String customerName) async {
    final db = await _dbHelper.database;

    // Use UPPER() for case-insensitive comparison
    final result = await db.rawQuery(
      '''
      SELECT openingBalance
      FROM customer
      WHERE UPPER(name) = UPPER(?)
      LIMIT 1
      ''',
      [customerName],
    );

    if (result.isNotEmpty) {
      final rawValue = result.first['openingBalance'];

      if (rawValue == null) {
        return 0.0;
      }

      double parsedValue = 0.0;
      if (rawValue is double) {
        parsedValue = rawValue;
      } else if (rawValue is int) {
        parsedValue = rawValue.toDouble();
      } else if (rawValue is String) {
        parsedValue = double.tryParse(rawValue) ?? 0.0;
      }
      return parsedValue;
    }

    return 0.0;
  }

  Future<int> updateCustomer(Customer customer) async {
    final db = await _dbHelper.database;
    return await db.update(
      'customer',
      customer.toMap(),
      where: 'id = ?',
      whereArgs: [customer.id],
    );
  }

  Future<int> deleteCustomer(int id) async {
    final db = await _dbHelper.database;
    return await db.delete('customer', where: 'id = ?', whereArgs: [id]);
  }

  Future<String> getLastCustNVendNo(String type) async {
    final db = await _dbHelper.database;

    final isCustomer = type.toLowerCase() == 'customer';
    final table = 'customer';
    final column = 'customerNo';

    try {
      final result = await db.query(
        table,
        columns: [column],
        orderBy: '$column DESC',
        limit: 1,
      );

      String lastCode;
      if (result.isNotEmpty) {
        lastCode = result.first[column] as String;
      } else {
        return isCustomer ? 'CUST01' : 'VEN01';
      }

      final regex = RegExp(r'(\d+)$');
      final match = regex.firstMatch(lastCode);
      int nextNum = 1;
      if (match != null) {
        final numPart = int.tryParse(match.group(1)!) ?? 0;
        nextNum = numPart + 1;
      }

      final prefix = isCustomer ? 'CUST' : 'VEN';
      final newCode = '$prefix${nextNum.toString().padLeft(2, '0')}';
      return newCode;
    } catch (e) {
      return isCustomer ? 'CUST01' : 'VEN01';
    }
  }

  /// ✅ NEW: Get vendor by exact name match (case-insensitive)
  Future<Customer?> getVendorByName(String vendorName) async {
    final db = await _dbHelper.database;

    final result = await db.rawQuery(
      '''
      SELECT *
      FROM customer
      WHERE UPPER(name) = UPPER(?) AND type = 'Vendor'
      LIMIT 1
      ''',
      [vendorName],
    );

    if (result.isNotEmpty) {
      return Customer.fromMap(result.first);
    }
    return null;
  }
}

class CustomerLedgerRepository {
  final DBHelper _dbHelper = DBHelper();

  String _sanitizeIdentifier(String input) =>
      input.replaceAll(RegExp(r'[^A-Za-z0-9_]'), '_');

  String _tableNameFromCustomerName(String customerName, int customerId) {
    final safeName = _sanitizeIdentifier(customerName);
    return 'customer_ledger_entries_${safeName}_$customerId';
  }

  Future<void> createCustomerLedgerTable(
    String customerName,
    int customerId,
  ) async {
    final db = await _dbHelper.database;
    final tableName = _tableNameFromCustomerName(customerName, customerId);

    await db.execute('''
      CREATE TABLE IF NOT EXISTS $tableName (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        voucherNo TEXT NOT NULL,
        date TEXT NOT NULL,
        customerName TEXT NOT NULL,
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
        createdAt TEXT NOT NULL
      )
    ''');
  }

  Future<int> insertCustomerLedgerEntry(
    CustomerLedgerEntry entry,
    String customerName,
    int customerId,
  ) async {
    final db = await _dbHelper.database;
    final tableName = _tableNameFromCustomerName(customerName, customerId);

    await createCustomerLedgerTable(customerName, customerId);
    return await db.insert(tableName, entry.toMap());
  }

  Future<List<CustomerLedgerEntry>> getCustomerLedgerEntries(
    String customerName,
    int customerId,
  ) async {
    final db = await _dbHelper.database;
    final tableName = _tableNameFromCustomerName(customerName, customerId);

    try {
      await createCustomerLedgerTable(customerName, customerId);
      final result = await db.query(tableName, orderBy: 'date ASC, id ASC');
      return result.map((e) => CustomerLedgerEntry.fromMap(e)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<int> updateCustomerLedgerEntry(
    CustomerLedgerEntry entry,
    String customerName,
    int customerId,
  ) async {
    final db = await _dbHelper.database;
    final tableName = _tableNameFromCustomerName(customerName, customerId);

    return await db.update(
      tableName,
      entry.toMap(),
      where: 'id = ?',
      whereArgs: [entry.id],
    );
  }

  Future<DebitCreditSummary> fetchTotalDebitAndCredit(
    String customerName,
    int customerId,
  ) async {
    final db = await _dbHelper.database;
    final tableName = _tableNameFromCustomerName(customerName, customerId);

    debugPrint('=== fetchTotalDebitAndCredit ===');
    debugPrint('customerName: $customerName');
    debugPrint('customerId: $customerId');
    debugPrint('tableName: $tableName');

    try {
      await createCustomerLedgerTable(customerName, customerId);

      final result = await db.rawQuery('''
      SELECT
        COALESCE(SUM(debit), 0) AS totalDebit,
        COALESCE(SUM(credit), 0) AS totalCredit
      FROM $tableName
    ''');

      debugPrint('result.isEmpty: ${result.isEmpty}');
      if (result.isNotEmpty) {
        debugPrint('row: ${result.first}');
      }

      final row = result.firstOrNull ?? {};

      final totalDebit = (row['totalDebit'] ?? 0).toString();
      final totalCredit = (row['totalCredit'] ?? 0).toString();

      debugPrint('RETURNING => debit: $totalDebit, credit: $totalCredit');

      return DebitCreditSummary(debit: totalDebit, credit: totalCredit);
    } catch (e) {
      debugPrint('ERROR in fetchTotalDebitAndCredit: $e');
      return DebitCreditSummary(debit: "0", credit: "0");
    }
  }

  Future<int> deleteCustomerLedgerEntry(
    int entryId,
    String customerName,
    int customerId,
  ) async {
    final db = await _dbHelper.database;
    final tableName = _tableNameFromCustomerName(customerName, customerId);

    return await db.delete(tableName, where: 'id = ?', whereArgs: [entryId]);
  }

  Future<String> getLastVoucherNo(String customerName, int customerId) async {
    final db = await _dbHelper.database;
    final tableName = _tableNameFromCustomerName(customerName, customerId);

    try {
      await createCustomerLedgerTable(customerName, customerId);
      final result = await db.query(
        tableName,
        columns: ['voucherNo'],
        orderBy: 'voucherNo DESC',
        limit: 1,
      );

      if (result.isNotEmpty) {
        final lastVoucherNo = result.first['voucherNo'] as String;
        final regex = RegExp(r'(\d+)$');
        final match = regex.firstMatch(lastVoucherNo);

        if (match != null) {
          final num = int.parse(match.group(1)!);
          return 'VN${(num + 1).toString().padLeft(4, '0')}';
        }
      }
      return 'VN0001';
    } catch (e) {
      return 'VN0001';
    }
  }
}
