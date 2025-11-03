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

    // run query
    final result = await db.query(
      'customer',
      where: 'id = ?',
      whereArgs: [accountId],
      limit: 1,
    );

    if (result.isNotEmpty) {
      return Customer.fromMap(result.first);
    } else {
      return null; // no customer found
    }
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

    // Decide table & column based on type
    final isCustomer = type.toLowerCase() == 'customer';
    final table = 'customer';
    final column = 'customerNo';

    try {
      // Get last record (highest number)
      final result = await db.query(
        table,
        columns: [column],
        orderBy: '$column DESC',
        limit: 1,
      );

      // Get the last code (like CUST01 or VEN01)
      String lastCode;
      if (result.isNotEmpty) {
        lastCode = result.first[column] as String;
      } else {
        // No record found → default starting code
        return isCustomer ? 'CUST01' : 'VEN01';
      }

      // Extract numeric part of the last code
      final regex = RegExp(r'(\d+)$');
      final match = regex.firstMatch(lastCode);

      int nextNum = 1; // default
      if (match != null) {
        final numPart = int.tryParse(match.group(1)!) ?? 0;
        nextNum = numPart + 1;
      }

      // Create new code
      final prefix = isCustomer ? 'CUST' : 'VEN';
      // Format number with 2 digits (01, 02, …)
      final newCode = '$prefix${nextNum.toString().padLeft(2, '0')}';

      return newCode;
    } catch (e) {
      // fallback if something goes wrong
      return isCustomer ? 'CUST01' : 'VEN01';
    }
  }
}
