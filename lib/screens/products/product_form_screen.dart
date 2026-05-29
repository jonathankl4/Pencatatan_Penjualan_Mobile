import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/product_provider.dart';
import '../../core/utils/validators.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/common/app_text_field.dart';

class ProductFormScreen extends StatefulWidget {
  const ProductFormScreen({super.key});

  @override
  State<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends State<ProductFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _costController = TextEditingController();
  final _sellController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _costController.dispose();
    _sellController.dispose();
    super.dispose();
  }

  void _save() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      
      final provider = context.read<ProductProvider>();
      final success = await provider.addProduct({
        'name': _nameController.text,
        'cost_price': double.parse(_costController.text),
        'sell_price': double.parse(_sellController.text),
        'is_active': true,
      });

      setState(() => _isLoading = false);

      if (success) {
        if (mounted) context.pop();
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(provider.error ?? 'Gagal menyimpan')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tambah Produk'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              AppTextField(
                label: 'Nama Produk',
                controller: _nameController,
                validator: (val) => Validators.required(val, 'Nama'),
              ),
              const SizedBox(height: 16),
              AppTextField(
                label: 'Harga Modal (Rp)',
                controller: _costController,
                keyboardType: TextInputType.number,
                validator: (val) => Validators.number(val, 'Harga Modal'),
              ),
              const SizedBox(height: 16),
              AppTextField(
                label: 'Harga Jual (Rp)',
                controller: _sellController,
                keyboardType: TextInputType.number,
                validator: (val) => Validators.number(val, 'Harga Jual'),
              ),
              const SizedBox(height: 32),
              AppButton(
                text: 'Simpan',
                isLoading: _isLoading,
                onPressed: _save,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
