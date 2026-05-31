import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/product_provider.dart';
import '../../core/utils/currency_formatter.dart';
import '../../widgets/common/empty_state.dart';
import '../../widgets/common/app_drawer.dart';

class ProductListScreen extends StatefulWidget {
  const ProductListScreen({super.key});

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProductProvider>().fetchProducts();
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (Navigator.canPop(context)) {
          Navigator.pop(context);
        } else {
          context.go('/dashboard');
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Daftar Produk'),
        ),
        drawer: const AppDrawer(),
      body: Consumer<ProductProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.error != null) {
            return Center(child: Text('Error: ${provider.error}'));
          }

          if (provider.products.isEmpty) {
            return const EmptyState(
              message: 'Belum ada produk.',
              icon: Icons.inventory_2_outlined,
            );
          }

          return RefreshIndicator(
            onRefresh: () => provider.fetchProducts(),
            child: ListView.builder(
              padding: const EdgeInsets.only(bottom: 88.0),
              itemCount: provider.products.length,
              itemBuilder: (context, index) {
                final product = provider.products[index];
                return ListTile(
                  leading: const CircleAvatar(child: Icon(Icons.inventory)),
                  title: Text(product.name),
                  subtitle: Text('Modal: ${CurrencyFormatter.format(product.costPrice)}'),
                  trailing: Text(
                    CurrencyFormatter.format(product.sellPrice),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/products/form'),
        child: const Icon(Icons.add),
      ),
    ),);
  }
}
