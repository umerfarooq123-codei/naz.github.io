import '../../core/database/db_helper.dart';
import '../../core/models/bank_transaction.dart';

class BankRepository {
  final DBHelper _dbHelper = DBHelper();

  Future<int> insertTransaction(BankTransaction tx) async {
    final db = await _dbHelper.database;
    return await db.insert('bank_transaction', tx.toMap());
  }

  Future<List<BankTransaction>> getAllTransactions() async {
    final db = await _dbHelper.database;
    final result = await db.query('bank_transaction', orderBy: 'date DESC');
    return result.map((e) => BankTransaction.fromMap(e)).toList();
  }

  Future<int> updateTransaction(BankTransaction tx) async {
    final db = await _dbHelper.database;
    return await db.update(
      'bank_transaction',
      tx.toMap(),
      where: 'id = ?',
      whereArgs: [tx.id],
    );
  }

  Future<int> deleteTransaction(int id) async {
    final db = await _dbHelper.database;
    return await db.delete(
      'bank_transaction',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Mark transaction as cleared
  Future<int> markCleared(int id, bool cleared) async {
    final db = await _dbHelper.database;
    return await db.update(
      'bank_transaction',
      {'cleared': cleared ? 1 : 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
