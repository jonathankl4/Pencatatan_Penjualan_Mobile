import 'sale_item.dart';

class Sale {
  final int id;
  final String saleCode;
  final double totalCost;
  final double totalRevenue;
  final double grossProfit;
  final String? notes;
  final String saleDate;
  final List<SaleItem> items;

  Sale({
    required this.id,
    required this.saleCode,
    required this.totalCost,
    required this.totalRevenue,
    required this.grossProfit,
    this.notes,
    required this.saleDate,
    required this.items,
  });

  factory Sale.fromJson(Map<String, dynamic> json) {
    var list = json['items'] as List?;
    List<SaleItem> itemsList = list != null ? list.map((i) => SaleItem.fromJson(i)).toList() : [];

    return Sale(
      id: json['id'],
      saleCode: json['sale_code'],
      totalCost: double.parse(json['total_cost'].toString()),
      totalRevenue: double.parse(json['total_revenue'].toString()),
      grossProfit: double.parse(json['gross_profit'].toString()),
      notes: json['notes'],
      saleDate: json['sale_date'],
      items: itemsList,
    );
  }
}
