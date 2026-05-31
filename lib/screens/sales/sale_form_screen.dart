import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/sale_provider.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/date_helper.dart';
import '../../widgets/common/app_button.dart';
import '../../models/sale.dart';

class SaleFormScreen extends StatefulWidget {
  final Sale? sale;
  const SaleFormScreen({super.key, this.sale});

  @override
  State<SaleFormScreen> createState() => _SaleFormScreenState();
}

class _SaleFormScreenState extends State<SaleFormScreen> {
  final List<Map<String, dynamic>> _cart = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.sale != null) {
      for (var item in widget.sale!.items) {
        _cart.add({
          'product_id': item.productId,
          'product_name': item.productName,
          'sell_price': item.sellPrice,
          'quantity': item.quantity,
        });
      }
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SaleProvider>().fetchSuggestions();
    });
  }

  void _showAddItemDialog() {
    TextEditingController? nameController;
    final priceController = TextEditingController();
    final qtyController = TextEditingController(text: '1');
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) {
        final suggestions = context.read<SaleProvider>().suggestions;
        return AlertDialog(
          title: const Text('Tambah Catatan Barang'),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Autocomplete<Map<String, dynamic>>(
                    optionsBuilder: (TextEditingValue textEditingValue) {
                      if (textEditingValue.text.isEmpty) {
                        return const Iterable<Map<String, dynamic>>.empty();
                      }
                      return suggestions.where((option) {
                        return option['product_name']
                            .toString()
                            .toLowerCase()
                            .contains(textEditingValue.text.toLowerCase());
                      });
                    },
                    displayStringForOption: (option) => option['product_name'] ?? '',
                    onSelected: (option) {
                      nameController?.text = option['product_name'] ?? '';
                      priceController.text = option['sell_price']?.toString() ?? '';
                    },
                    fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                      nameController = controller;
                      return TextFormField(
                        controller: controller,
                        focusNode: focusNode,
                        decoration: const InputDecoration(
                          labelText: 'Nama Barang/Deskripsi',
                          hintText: 'Cari atau ketik baru (misal: Kresek Tikus)',
                        ),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return 'Nama barang harus diisi';
                          }
                          return null;
                        },
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: priceController,
                    decoration: const InputDecoration(
                      labelText: 'Harga Satuan (Rp)',
                      hintText: 'Misal: 5000',
                    ),
                    keyboardType: TextInputType.number,
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return 'Harga harus diisi';
                      }
                      final price = double.tryParse(val);
                      if (price == null || price < 0) {
                        return 'Harga tidak valid';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: qtyController,
                    decoration: const InputDecoration(
                      labelText: 'Jumlah',
                      hintText: 'Misal: 1',
                    ),
                    keyboardType: TextInputType.number,
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return 'Jumlah harus diisi';
                      }
                      final qty = int.tryParse(val);
                      if (qty == null || qty < 1) {
                        return 'Jumlah minimal 1';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  final name = nameController?.text.trim() ?? '';
                  final price = double.parse(priceController.text);
                  final qty = int.parse(qtyController.text);
                  
                  _addItem(name, price, qty);
                  Navigator.pop(context);
                }
              },
              child: const Text('Tambah'),
            ),
          ],
        );
      },
    );
  }

  void _addItem(String name, double price, int qty) {
    setState(() {
      final existingIndex = _cart.indexWhere((item) => item['product_name'] == name);
      if (existingIndex >= 0) {
        _cart[existingIndex]['quantity'] += qty;
      } else {
        _cart.add({
          'product_id': null,
          'product_name': name,
          'sell_price': price,
          'quantity': qty,
        });
      }
    });
  }

  double _calculateTotal() {
    double total = 0;
    for (var item in _cart) {
      total += (item['sell_price'] * item['quantity']);
    }
    return total;
  }

  void _saveSale() async {
    if (_cart.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Keranjang kosong!')),
      );
      return;
    }

    setState(() => _isLoading = true);

    final provider = context.read<SaleProvider>();
    final isEdit = widget.sale != null;
    
    final payload = {
      'sale_date': isEdit ? widget.sale!.saleDate : DateHelper.toIsoDate(DateTime.now()),
      'items': _cart,
    };

    final success = isEdit
        ? await provider.editSale(widget.sale!.id, payload)
        : await provider.addSale(payload);

    setState(() => _isLoading = false);

    if (success) {
      if (mounted) context.pop();
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(provider.error ?? 'Gagal menyimpan penjualan')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.sale != null ? 'Edit Penjualan' : 'Buat Penjualan'),
      ),
      body: Column(
        children: [
          Expanded(
            child: _cart.isEmpty
                ? const Center(child: Text('Belum ada catatan barang. Silakan tambah.'))
                : ListView.builder(
                    itemCount: _cart.length,
                    itemBuilder: (context, index) {
                      final item = _cart[index];
                      return ListTile(
                        title: Text(item['product_name']),
                        subtitle: Text(CurrencyFormatter.format(item['sell_price'])),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove_circle_outline),
                              onPressed: () {
                                setState(() {
                                  if (item['quantity'] > 1) {
                                    item['quantity']--;
                                  } else {
                                    _cart.removeAt(index);
                                  }
                                });
                              },
                            ),
                            Text('${item['quantity']}'),
                            IconButton(
                              icon: const Icon(Icons.add_circle_outline),
                              onPressed: () {
                                setState(() {
                                  item['quantity']++;
                                });
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                )
              ],
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Total:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    Text(
                      CurrencyFormatter.format(_calculateTotal()),
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.blue),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.add_shopping_cart),
                        label: const Text('Tambah Barang'),
                        onPressed: _showAddItemDialog,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: AppButton(
                        text: 'Simpan',
                        isLoading: _isLoading,
                        onPressed: _saveSale,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
