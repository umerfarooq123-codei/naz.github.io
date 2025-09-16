import '../database/db_helper.dart';

class KPIRepository {
  final DBHelper _dbHelper = DBHelper();

  Future<double> getTotalSales() async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery(
      'SELECT SUM(totalAmount) as total FROM invoice',
    );
    return result.first['total'] != null
        ? (result.first['total'] as num).toDouble()
        : 0.0;
  }

  Future<double> getOutstandingReceivables() async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery(
      'SELECT SUM(balance) as total FROM invoice',
    );
    return result.first['total'] != null
        ? (result.first['total'] as num).toDouble()
        : 0.0;
  }

  Future<double> getTotalExpenses() async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery(
      'SELECT SUM(amount) as total FROM purchases',
    );
    return result.first['total'] != null
        ? (result.first['total'] as num).toDouble()
        : 0.0;
  }

  Future<double> getInventoryValue() async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery(
      'SELECT SUM(cost * stockLevel) as total FROM inventory_item',
    );
    return result.first['total'] != null
        ? (result.first['total'] as num).toDouble()
        : 0.0;
  }
}
