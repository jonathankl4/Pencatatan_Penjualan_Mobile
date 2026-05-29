import 'package:flutter/material.dart';
import '../../models/product.dart';
import '../../core/utils/currency_formatter.dart';

class ProductPicker extends StatelessWidget {
  final List<Product> products;
  final Function(Product) onSelected;

  const ProductPicker({
    super.key,
    required this.products,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: products.length,
      itemBuilder: (context, index) {
        final product = products[index];
        return ListTile(
          title: Text(product.name),
          subtitle: Text(CurrencyFormatter.format(product.sellPrice)),
          onTap: () {
            onSelected(product);
            Navigator.of(context).pop();
          },
        );
      },
    );
  }
}
