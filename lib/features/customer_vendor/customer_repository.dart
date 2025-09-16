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
}
