import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/sale_provider.dart';
import '../../core/utils/currency_formatter.dart';
import '../../widgets/common/empty_state.dart';
import '../../widgets/common/app_drawer.dart';
import '../../core/utils/date_helper.dart';

class SaleListScreen extends StatefulWidget {
  const SaleListScreen({super.key});

  @override
  State<SaleListScreen> createState() => _SaleListScreenState();
}

class _SaleListScreenState extends State<SaleListScreen> {
  DateTimeRange? _selectedDateRange;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchSales();
    });
  }

  void _fetchSales() {
    final start = _selectedDateRange != null ? DateHelper.toIsoDate(_selectedDateRange!.start) : null;
    final end = _selectedDateRange != null ? DateHelper.toIsoDate(_selectedDateRange!.end) : null;
    context.read<SaleProvider>().fetchSales(startDate: start, endDate: end);
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
      _fetchSales();
    }
  }

  void _clearFilter() {
    setState(() {
      _selectedDateRange = null;
    });
    _fetchSales();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Riwayat Penjualan'),
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
              color: Colors.blue.shade50,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Filter: ${DateHelper.formatDate(DateHelper.toIsoDate(_selectedDateRange!.start))} - ${DateHelper.formatDate(DateHelper.toIsoDate(_selectedDateRange!.end))}',
                      style: TextStyle(color: Colors.blue.shade800, fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ),
                  TextButton(
                    onPressed: _clearFilter,
                    child: const Text('Reset'),
                  ),
                ],
              ),
            ),
          Expanded(
            child: Consumer<SaleProvider>(
              builder: (context, provider, child) {
                if (provider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (provider.error != null) {
                  return Center(child: Text('Error: ${provider.error}'));
                }

                if (provider.sales.isEmpty) {
                  return const EmptyState(
                    message: 'Belum ada penjualan.',
                    icon: Icons.receipt_long,
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async => _fetchSales(),
                  child: ListView.builder(
                    itemCount: provider.sales.length,
                    itemBuilder: (context, index) {
                      final sale = provider.sales[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    sale.saleCode,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                  ),
                                  Text(
                                    DateHelper.formatDate(sale.saleDate),
                                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                                  ),
                                ],
                              ),
                              const Divider(height: 24),
                              Column(
                                children: sale.items.map((item) {
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            '${item.productName} (x${item.quantity})',
                                            style: const TextStyle(fontSize: 14),
                                          ),
                                        ),
                                        Text(
                                          CurrencyFormatter.format(item.subtotalRevenue),
                                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                              ),
                              const Divider(height: 24),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Total:',
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                  ),
                                  Text(
                                    CurrencyFormatter.format(sale.totalRevenue),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                      color: Colors.blue,
                                    ),
                                  ),
                                ],
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
          await context.push('/sales/form');
          _fetchSales();
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
