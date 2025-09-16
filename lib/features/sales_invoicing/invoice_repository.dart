import '../../core/database/db_helper.dart';
import '../../core/models/invoice.dart';

class InvoiceRepository {
  final DBHelper _dbHelper = DBHelper();

  Future<int> insertInvoice(Invoice invoice) async {
    final db = await _dbHelper.database;
    return await db.insert('invoice', invoice.toMap());
  }

  Future<List<Invoice>> getAllInvoices() async {
    final db = await _dbHelper.database;
    final result = await db.query('invoice', orderBy: 'date DESC');
    return result.map((e) => Invoice.fromMap(e)).toList();
  }

  Future<int> updateInvoice(Invoice invoice) async {
    final db = await _dbHelper.database;
    return await db.update(
      'invoice',
      invoice.toMap(),
      where: 'id = ?',
      whereArgs: [invoice.id],
    );
  }

  Future<int> deleteInvoice(int id) async {
    final db = await _dbHelper.database;
    return await db.delete('invoice', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Invoice>> getInvoicesByCustomer(int customerId) async {
    final db = await _dbHelper.database;
    final result = await db.query(
      'invoice',
      where: 'customerId = ?',
      whereArgs: [customerId],
      orderBy: 'date DESC',
    );
    return result.map((e) => Invoice.fromMap(e)).toList();
  }
}
