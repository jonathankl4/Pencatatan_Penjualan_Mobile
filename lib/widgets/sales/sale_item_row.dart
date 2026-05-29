import 'package:flutter/material.dart';
import '../../core/utils/currency_formatter.dart';
import '../../models/sale_item.dart';

class SaleItemRow extends StatelessWidget {
  final SaleItem item;

  const SaleItemRow({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(item.productName),
      subtitle: Text('${item.quantity} x ${CurrencyFormatter.format(item.sellPrice)}'),
      trailing: Text(
        CurrencyFormatter.format(item.subtotalRevenue),
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
    );
  }
}
