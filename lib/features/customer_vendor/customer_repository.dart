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

  /// ✅ New helper function to get customer's opening balance safely
  Future<double> getOpeningBalanceForCustomer(String customerName) async {
    final db = await _dbHelper.database;
    final result = await db.query(
      'customer',
      columns: ['openingBalance'],
      where: 'name = ?',
      whereArgs: [customerName.toLowerCase()],
      limit: 1,
    );

    if (result.isNotEmpty) {
      final rawValue = result.first['openingBalance'];
      if (rawValue == null) return 0.0;
      if (rawValue is double) return rawValue;
      if (rawValue is int) return rawValue.toDouble();
      if (rawValue is String) {
        return double.tryParse(rawValue) ?? 0.0;
      }
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
}
