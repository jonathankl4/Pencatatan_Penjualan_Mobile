import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/expense_provider.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/date_helper.dart';
import '../../widgets/common/empty_state.dart';
import '../../widgets/common/app_drawer.dart';

class ExpenseListScreen extends StatefulWidget {
  final DateTime? initialStartDate;
  final DateTime? initialEndDate;
  final bool hasInitialFilters;

  const ExpenseListScreen({
    super.key,
    this.initialStartDate,
    this.initialEndDate,
    this.hasInitialFilters = false,
  });

  @override
  State<ExpenseListScreen> createState() => _ExpenseListScreenState();
}

class _ExpenseListScreenState extends State<ExpenseListScreen> {
  DateTimeRange? _selectedDateRange;
  String _searchQuery = '';
  late TextEditingController _searchController;
  bool _isPopping = false;

  @override
  void initState() {
    super.initState();
    if (widget.hasInitialFilters) {
      if (widget.initialStartDate != null && widget.initialEndDate != null) {
        _selectedDateRange = DateTimeRange(
          start: widget.initialStartDate!,
          end: widget.initialEndDate!,
        );
      } else {
        _selectedDateRange = null;
      }
    } else {
      _selectedDateRange = DateTimeRange(
        start: DateTime.now(),
        end: DateTime.now(),
      );
    }
    _searchController = TextEditingController(text: _searchQuery);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchExpenses();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _fetchExpenses() {
    final start = _selectedDateRange != null ? DateHelper.toIsoDate(_selectedDateRange!.start) : null;
    final end = _selectedDateRange != null ? DateHelper.toIsoDate(_selectedDateRange!.end) : null;
    context.read<ExpenseProvider>().fetchExpenses(startDate: start, endDate: end);
  }

  void _selectDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange: _selectedDateRange,
    );

    if (picked != null) {
      setState(() {
        _selectedDateRange = picked;
      });
      _fetchExpenses();
    }
  }

  void _clearFilter() {
    setState(() {
      _selectedDateRange = null;
    });
    _fetchExpenses();
  }

  void _confirmDelete(int id, String expenseName) {
    showDialog(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
          title: const Text('Hapus Pengeluaran'),
          content: Text('Apakah Anda yakin ingin menghapus pengeluaran "$expenseName"? Tindakan ini tidak dapat dibatalkan.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () async {
                final messenger = ScaffoldMessenger.of(context);
                final provider = context.read<ExpenseProvider>();
                Navigator.pop(dialogCtx);
                final success = await provider.deleteExpense(id);
                if (mounted) {
                  if (success) {
                    messenger.showSnackBar(
                      SnackBar(content: Text('Pengeluaran "$expenseName" berhasil dihapus')),
                    );
                  } else {
                    messenger.showSnackBar(
                      SnackBar(content: Text(provider.error ?? 'Gagal menghapus pengeluaran')),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Hapus'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (Navigator.canPop(context)) {
          if (_isPopping) return;
          _isPopping = true;
          Navigator.pop(context, _selectedDateRange);
        } else {
          context.go('/dashboard');
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Daftar Pengeluaran'),
          leading: Navigator.canPop(context)
              ? IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () {
                    _isPopping = true;
                    Navigator.pop(context, _selectedDateRange);
                  },
                )
              : null,
          actions: [
            if (_selectedDateRange != null)
              IconButton(
                icon: const Icon(Icons.filter_alt_off),
                tooltip: 'Hapus Filter',
                onPressed: _clearFilter,
              ),
            IconButton(
              icon: const Icon(Icons.date_range),
              tooltip: 'Filter Tanggal',
              onPressed: _selectDateRange,
            ),
          ],
        ),
        drawer: const AppDrawer(),
        body: Column(
          children: [
            if (_selectedDateRange != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                color: Colors.red.shade50,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        'Filter: ${DateHelper.formatDate(DateHelper.toIsoDate(_selectedDateRange!.start))} - ${DateHelper.formatDate(DateHelper.toIsoDate(_selectedDateRange!.end))}',
                        style: TextStyle(color: Colors.red.shade800, fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ),
                    TextButton(
                      onPressed: _clearFilter,
                      child: const Text('Reset'),
                    ),
                  ],
                ),
              ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Cari pengeluaran...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
              ),
            ),
            Expanded(
              child: Consumer<ExpenseProvider>(
                builder: (context, provider, child) {
                  if (provider.isLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (provider.error != null) {
                    return Center(child: Text('Error: ${provider.error}'));
                  }

                  final filteredExpenses = provider.expenses.where((expense) {
                    if (_searchQuery.isEmpty) return true;
                    return expense.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                        expense.category.toLowerCase().contains(_searchQuery.toLowerCase());
                  }).toList();

                  if (filteredExpenses.isEmpty) {
                    return const EmptyState(
                      message: 'Belum ada pengeluaran.',
                      icon: Icons.money_off,
                    );
                  }

                  return RefreshIndicator(
                    onRefresh: () async => _fetchExpenses(),
                    child: ListView.builder(
                      padding: const EdgeInsets.only(bottom: 88.0),
                      itemCount: filteredExpenses.length,
                      itemBuilder: (context, index) {
                        final expense = filteredExpenses[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: ListTile(
                            leading: const CircleAvatar(
                              backgroundColor: Colors.redAccent,
                              child: Icon(Icons.arrow_downward, color: Colors.white),
                            ),
                            title: Text(
                              expense.name,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text('${DateHelper.formatDate(expense.expenseDate)} • ${expense.category}'),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  CurrencyFormatter.format(expense.amount),
                                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red, fontSize: 15),
                                ),
                                const SizedBox(width: 8),
                                IconButton(
                                  icon: const Icon(Icons.edit_outlined, color: Colors.blue),
                                  onPressed: () async {
                                    await context.push('/expenses/form', extra: expense);
                                    if (mounted) {
                                      _fetchExpenses();
                                    }
                                  },
                                  constraints: const BoxConstraints(),
                                  padding: EdgeInsets.zero,
                                  iconSize: 20,
                                  tooltip: 'Edit Pengeluaran',
                                ),
                                const SizedBox(width: 8),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                                  onPressed: () {
                                    _confirmDelete(expense.id, expense.name);
                                  },
                                  constraints: const BoxConstraints(),
                                  padding: EdgeInsets.zero,
                                  iconSize: 20,
                                  tooltip: 'Hapus Pengeluaran',
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () async {
            await context.push('/expenses/form');
            if (mounted) {
              _fetchExpenses();
            }
          },
          backgroundColor: Colors.red,
          child: const Icon(Icons.add),
        ),
      ),
    );
  }
}
