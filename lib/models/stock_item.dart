// stock_item.dart
class StockItem {
  final String id;
  final String name;
  final double rate;
  final int quantity;

  StockItem({
    required this.id,
    required this.name,
    required this.rate,
    required this.quantity,
  });

  StockItem copyWith({int? quantity}) {
    return StockItem(
      id: id,
      name: name,
      rate: rate,
      quantity: quantity ?? this.quantity,
    );
  }
}
