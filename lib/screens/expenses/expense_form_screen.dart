import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/expense_provider.dart';
import '../../models/expense.dart';
import '../../core/utils/validators.dart';
import '../../core/utils/date_helper.dart';
import '../../widgets/common/app_text_field.dart';

class ExpenseFormScreen extends StatefulWidget {
  final Expense? expense;

  const ExpenseFormScreen({super.key, this.expense});

  @override
  State<ExpenseFormScreen> createState() => _ExpenseFormScreenState();
}

class _ExpenseFormScreenState extends State<ExpenseFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _amountController = TextEditingController();
  final _categoryController = TextEditingController(text: 'Lainnya');
  final _notesController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.expense != null) {
      _nameController.text = widget.expense!.name;
      _amountController.text = widget.expense!.amount.toStringAsFixed(0);
      _categoryController.text = widget.expense!.category;
      _notesController.text = widget.expense!.notes ?? '';
      _selectedDate = DateTime.tryParse(widget.expense!.expenseDate) ?? DateTime.now();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    _categoryController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _save() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      
      final provider = context.read<ExpenseProvider>();
      final expenseData = {
        'name': _nameController.text,
        'amount': double.parse(_amountController.text),
        'category': _categoryController.text,
        'notes': _notesController.text,
        'expense_date': DateHelper.toIsoDate(_selectedDate),
      };

      final bool success;
      if (widget.expense != null) {
        success = await provider.updateExpense(widget.expense!.id, expenseData);
      } else {
        success = await provider.addExpense(expenseData);
      }

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

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.expense != null ? 'Edit Pengeluaran' : 'Tambah Pengeluaran'),
        backgroundColor: Colors.red,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppTextField(
                label: 'Nama Pengeluaran',
                controller: _nameController,
                validator: (val) => Validators.required(val, 'Nama'),
              ),
              const SizedBox(height: 16),
              AppTextField(
                label: 'Jumlah (Rp)',
                controller: _amountController,
                keyboardType: TextInputType.number,
                validator: (val) => Validators.number(val, 'Jumlah'),
              ),
              const SizedBox(height: 16),
              AppTextField(
                label: 'Kategori',
                controller: _categoryController,
                validator: (val) => Validators.required(val, 'Kategori'),
              ),
              const SizedBox(height: 16),
              ListTile(
                title: const Text('Tanggal Pengeluaran'),
                subtitle: Text(DateHelper.formatDate(DateHelper.toIsoDate(_selectedDate))),
                trailing: const Icon(Icons.calendar_today),
                onTap: _pickDate,
                contentPadding: EdgeInsets.zero,
              ),
              const SizedBox(height: 16),
              AppTextField(
                label: 'Catatan (Opsional)',
                controller: _notesController,
                maxLines: 3,
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _isLoading ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: _isLoading 
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(widget.expense != null ? 'Simpan Perubahan' : 'Simpan Pengeluaran', style: const TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
