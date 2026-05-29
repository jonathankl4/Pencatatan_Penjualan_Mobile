class SaleItem {
  final int id;
  final int? productId;
  final String productName;
  final double costPrice;
  final double sellPrice;
  final int quantity;
  final double subtotalCost;
  final double subtotalRevenue;
  final double subtotalProfit;

  SaleItem({
    required this.id,
    this.productId,
    required this.productName,
    required this.costPrice,
    required this.sellPrice,
    required this.quantity,
    required this.subtotalCost,
    required this.subtotalRevenue,
    required this.subtotalProfit,
  });

  factory SaleItem.fromJson(Map<String, dynamic> json) {
    return SaleItem(
      id: json['id'],
      productId: json['product_id'],
      productName: json['product_name'],
      costPrice: double.parse(json['cost_price'].toString()),
      sellPrice: double.parse(json['sell_price'].toString()),
      quantity: json['quantity'],
      subtotalCost: double.parse(json['subtotal_cost'].toString()),
      subtotalRevenue: double.parse(json['subtotal_revenue'].toString()),
      subtotalProfit: double.parse(json['subtotal_profit'].toString()),
    );
  }
}
