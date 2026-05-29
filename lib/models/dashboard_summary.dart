import 'sale.dart';
import 'expense.dart';

class DashboardItemRecap {
  final String productName;
  final int totalQuantity;
  final double totalRevenue;

  DashboardItemRecap({
    required this.productName,
    required this.totalQuantity,
    required this.totalRevenue,
  });

  factory DashboardItemRecap.fromJson(Map<String, dynamic> json) {
    return DashboardItemRecap(
      productName: json['product_name'] ?? '',
      totalQuantity: int.tryParse(json['total_quantity'].toString()) ?? 0,
      totalRevenue: double.tryParse(json['total_revenue'].toString()) ?? 0.0,
    );
  }
}

class DashboardSummary {
  final String periodStart;
  final String periodEnd;
  final double totalRevenue;
  final double totalGrossProfit;
  final double totalExpenses;
  final double netProfit;
  final List<Sale> recentSales;
  final List<Expense> recentExpenses;
  final List<DashboardItemRecap> itemRecap;

  DashboardSummary({
    required this.periodStart,
    required this.periodEnd,
    required this.totalRevenue,
    required this.totalGrossProfit,
    required this.totalExpenses,
    required this.netProfit,
    required this.recentSales,
    required this.recentExpenses,
    required this.itemRecap,
  });

  factory DashboardSummary.fromJson(Map<String, dynamic> json) {
    var salesList = json['recent_sales'] as List? ?? [];
    var expensesList = json['recent_expenses'] as List? ?? [];
    var recapList = json['item_recap'] as List? ?? [];

    return DashboardSummary(
      periodStart: json['period']['start'],
      periodEnd: json['period']['end'],
      totalRevenue: double.parse(json['summary']['total_revenue'].toString()),
      totalGrossProfit: double.parse(json['summary']['total_gross_profit'].toString()),
      totalExpenses: double.parse(json['summary']['total_expenses'].toString()),
      netProfit: double.parse(json['summary']['net_profit'].toString()),
      recentSales: salesList.map((i) => Sale.fromJson(i)).toList(),
      recentExpenses: expensesList.map((i) => Expense.fromJson(i)).toList(),
      itemRecap: recapList.map((i) => DashboardItemRecap.fromJson(i)).toList(),
    );
  }
}
