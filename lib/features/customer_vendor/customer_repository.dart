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
