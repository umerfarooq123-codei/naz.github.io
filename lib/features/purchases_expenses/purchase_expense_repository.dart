import '../../core/database/db_helper.dart';
import '../../core/models/purchase.dart';

class ExpensePurchaseRepository {
  final DBHelper _dbHelper = DBHelper();

  ExpensePurchaseRepository() {
    _ensureTableExists();
  }

  Future<void> _ensureTableExists() async {
    final db = await _dbHelper.database;
    // FIXED: Use CREATE TABLE IF NOT EXISTS to make it idempotent (no need for explicit check)
    await db.execute('''
      CREATE TABLE IF NOT EXISTS expense_purchases (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date INTEGER NOT NULL,
        description TEXT NOT NULL,
        amount REAL NOT NULL,
        madeBy TEXT NOT NULL,
        category TEXT NOT NULL,
        paymentMethod TEXT NOT NULL,
        referenceNumber TEXT,
        notes TEXT,
        createdAt INTEGER NOT NULL,
        updatedAt INTEGER NOT NULL
      )
    ''');
  }

  Future<List<ExpensePurchase>> getAllExpensePurchases() async {
    await _ensureTableExists(); // Keep for safety, though idempotent now
    final db = await _dbHelper.database;
    final maps = await db.query('expense_purchases', orderBy: 'date DESC');
    return maps.map((map) => ExpensePurchase.fromMap(map)).toList();
  }

  Future<int> insertExpensePurchase(ExpensePurchase expense) async {
    await _ensureTableExists();
    final db = await _dbHelper.database;
    return await db.insert('expense_purchases', expense.toMap());
  }

  Future<int> updateExpensePurchase(ExpensePurchase expense) async {
    await _ensureTableExists();
    final db = await _dbHelper.database;
    return await db.update(
      'expense_purchases',
      expense.toMap(),
      where: 'id = ?',
      whereArgs: [expense.id],
    );
  }

  Future<int> deleteExpensePurchase(int id) async {
    await _ensureTableExists();
    final db = await _dbHelper.database;
    return await db.delete(
      'expense_purchases',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
