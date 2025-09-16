import '../../core/database/db_helper.dart';
import '../../core/models/expense.dart';
import '../../core/models/purchase.dart';

class PurchaseExpenseRepository {
  final DBHelper _dbHelper = DBHelper();

  // PURCHASE CRUD
  Future<int> insertPurchase(Purchase purchase) async {
    final db = await _dbHelper.database;
    return await db.insert('purchase', purchase.toMap());
  }

  Future<List<Purchase>> getAllPurchases() async {
    final db = await _dbHelper.database;
    final result = await db.query('purchase', orderBy: 'date DESC');
    return result.map((e) => Purchase.fromMap(e)).toList();
  }

  Future<int> updatePurchase(Purchase purchase) async {
    final db = await _dbHelper.database;
    return await db.update(
      'purchase',
      purchase.toMap(),
      where: 'id = ?',
      whereArgs: [purchase.id],
    );
  }

  Future<int> deletePurchase(int id) async {
    final db = await _dbHelper.database;
    return await db.delete('purchase', where: 'id = ?', whereArgs: [id]);
  }

  // EXPENSE CRUD
  Future<int> insertExpense(Expense expense) async {
    final db = await _dbHelper.database;
    return await db.insert('expense', expense.toMap());
  }

  Future<List<Expense>> getAllExpenses() async {
    final db = await _dbHelper.database;
    final result = await db.query('expense', orderBy: 'date DESC');
    return result.map((e) => Expense.fromMap(e)).toList();
  }

  Future<int> updateExpense(Expense expense) async {
    final db = await _dbHelper.database;
    return await db.update(
      'expense',
      expense.toMap(),
      where: 'id = ?',
      whereArgs: [expense.id],
    );
  }

  Future<int> deleteExpense(int id) async {
    final db = await _dbHelper.database;
    return await db.delete('expense', where: 'id = ?', whereArgs: [id]);
  }
}
