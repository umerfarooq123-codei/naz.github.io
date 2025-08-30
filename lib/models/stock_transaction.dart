// stock_transaction.dart
enum StockType { inwards, outwards }

class StockTransaction {
  final String id;
  final String itemId;
  final StockType type;
  final int quantity;
  final DateTime date;

  StockTransaction({
    required this.id,
    required this.itemId,
    required this.type,
    required this.quantity,
    required this.date,
  });
}
