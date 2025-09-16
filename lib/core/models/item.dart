// Item Model
class Item {
  final int? id;
  final String name;
  final String type;
  final double pricePerKg;
  final double costPrice;
  final double sellingPrice;
  double availableStock;
  final double canWeight;

  Item({
    this.id,
    required this.name,
    required this.type,
    required this.pricePerKg,
    required this.costPrice,
    required this.sellingPrice,
    required this.availableStock,
    required this.canWeight,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'pricePerKg': pricePerKg,
      'costPrice': costPrice,
      'sellingPrice': sellingPrice,
      'availableStock': availableStock,
      'canWeight': canWeight,
    };
  }

  factory Item.fromMap(Map<String, dynamic> map) {
    return Item(
      id: map['id'],
      name: map['name'],
      type: map['type'],
      pricePerKg: (map['pricePerKg'] as num).toDouble(),
      costPrice: (map['costPrice'] as num).toDouble(),
      sellingPrice: (map['sellingPrice'] as num).toDouble(),
      availableStock: (map['availableStock'] as num).toDouble(),
      canWeight: (map['canWeight'] as num).toDouble(),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Item && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
