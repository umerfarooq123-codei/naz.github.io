import 'package:ledger_master/core/models/ledger.dart';

import '../../core/database/db_helper.dart';
import '../../core/models/item.dart';

class InventoryRepository {
  final DBHelper _dbHelper = DBHelper();

  Future<int> insertItem(Item item) async {
    final db = await _dbHelper.database;
    return await db.insert('item', item.toMap());
  }

  Future<List<Item>> getAllItems() async {
    final db = await _dbHelper.database;
    final result = await db.query('item', orderBy: 'name ASC');
    return result.map((e) => Item.fromMap(e)).toList();
  }

  Future<int> updateItem(Item item) async {
    final db = await _dbHelper.database;
    return await db.update(
      'item',
      item.toMap(),
      where: 'id = ?',
      whereArgs: [item.id],
    );
  }

  Future<int> deleteItem(int id) async {
    final db = await _dbHelper.database;
    return await db.delete('item', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> insertStockTransaction(StockTransaction tx) async {
    final db = await _dbHelper.database;

    // Wrap stock update and transaction insert in a single atomic transaction
    return await db.transaction<int>((txn) async {
      // Get the current item state from database
      final itemMap = await txn.query(
        'item',
        where: 'id = ?',
        whereArgs: [tx.itemId],
      );
      if (itemMap.isEmpty) throw Exception('Item not found');
      final item = Item.fromMap(itemMap.first);

      // Calculate new stock based on weight
      final isIn = tx.type == 'IN';
      final newStock = isIn
          ? (item.availableStock + tx.quantity)
          : (item.availableStock - tx.quantity);

      if (newStock < 0) throw Exception('Insufficient stock');

      // Update the item in database
      await txn.update(
        'item',
        {'availableStock': newStock},
        where: 'id = ?',
        whereArgs: [tx.itemId],
      );

      // Insert the stock transaction
      return await txn.insert('stock_transaction', tx.toMap());
    });
  }

  Future<List<StockTransaction>> getStockTransactions(int itemId) async {
    final db = await _dbHelper.database;
    final result = await db.query(
      'stock_transaction',
      where: 'itemId = ?',
      whereArgs: [itemId],
      orderBy: 'date DESC',
    );
    return result.map((e) => StockTransaction.fromMap(e)).toList();
  }

  Future<List<Item>> getLowStockItems(int threshold) async {
    final db = await _dbHelper.database;
    final result = await db.query(
      'item',
      where: 'availableStock <= ?',
      whereArgs: [threshold],
    );
    return result.map((e) => Item.fromMap(e)).toList();
  }
}
