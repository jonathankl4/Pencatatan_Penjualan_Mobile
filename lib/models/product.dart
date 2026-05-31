class Product {
  final int id;
  final String name;
  final double costPrice;
  final double sellPrice;
  final bool isActive;

  Product({
    required this.id,
    required this.name,
    required this.costPrice,
    required this.sellPrice,
    required this.isActive,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'],
      name: json['name'],
      costPrice: double.parse(json['cost_price'].toString()),
      sellPrice: double.parse(json['sell_price'].toString()),
      isActive: json['is_active'] == 1 || json['is_active'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'cost_price': costPrice,
      'sell_price': sellPrice,
      'is_active': isActive ? 1 : 0,
    };
  }
}
