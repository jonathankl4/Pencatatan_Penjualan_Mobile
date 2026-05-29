import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/expense_provider.dart';
import '../../core/utils/currency_formatter.dart';
import '../../widgets/common/empty_state.dart';
import '../../widgets/common/app_drawer.dart';

class ExpenseListScreen extends StatefulWidget {
  const ExpenseListScreen({super.key});

  @override
  State<ExpenseListScreen> createState() => _ExpenseListScreenState();
}

class _ExpenseListScreenState extends State<ExpenseListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ExpenseProvider>().fetchExpenses();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Daftar Pengeluaran'),
      ),
      drawer: const AppDrawer(),
      body: Consumer<ExpenseProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.error != null) {
            return Center(child: Text('Error: ${provider.error}'));
          }

          if (provider.expenses.isEmpty) {
            return const EmptyState(
              message: 'Belum ada pengeluaran.',
              icon: Icons.money_off,
            );
          }

          return RefreshIndicator(
            onRefresh: () => provider.fetchExpenses(),
            child: ListView.builder(
              itemCount: provider.expenses.length,
              itemBuilder: (context, index) {
                final expense = provider.expenses[index];
                return ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Colors.redAccent,
                    child: Icon(Icons.arrow_downward, color: Colors.white),
                  ),
                  title: Text(expense.name),
                  subtitle: Text('${expense.expenseDate} • ${expense.category}'),
                  trailing: Text(
                    CurrencyFormatter.format(expense.amount),
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
                  ),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await context.push('/expenses/form');
          if (mounted) {
            context.read<ExpenseProvider>().fetchExpenses();
          }
        },
        backgroundColor: Colors.red,
        child: const Icon(Icons.add),
      ),
    );
  }
}
