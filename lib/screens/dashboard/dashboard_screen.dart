import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../providers/dashboard_provider.dart';
import '../../core/constants/app_strings.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/currency_formatter.dart';
import '../../widgets/dashboard/summary_card.dart';
import '../../widgets/common/app_drawer.dart';
import '../../core/utils/date_helper.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  DateTimeRange? _selectedDateRange;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchSummary();
    });
  }

  void _fetchSummary() {
    final start = _selectedDateRange != null ? DateHelper.toIsoDate(_selectedDateRange!.start) : null;
    final end = _selectedDateRange != null ? DateHelper.toIsoDate(_selectedDateRange!.end) : null;
    context.read<DashboardProvider>().fetchSummary(startDate: start, endDate: end);
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
      _fetchSummary();
    }
  }

  void _clearFilter() {
    setState(() {
      _selectedDateRange = null;
    });
    _fetchSummary();
  }

  String get _selectedRangeText {
    if (_selectedDateRange == null) {
      return 'Ringkasan Bulan Ini';
    }
    final startStr = DateHelper.formatDate(DateHelper.toIsoDate(_selectedDateRange!.start));
    final endStr = DateHelper.formatDate(DateHelper.toIsoDate(_selectedDateRange!.end));
    return '$startStr - $endStr';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.dashboard),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await context.read<AuthProvider>().logout();
              if (mounted) context.go('/login');
            },
          )
        ],
      ),
      drawer: const AppDrawer(),
      body: Consumer<DashboardProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Error: ${provider.error}'),
                  ElevatedButton(
                    onPressed: () => provider.fetchSummary(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final summary = provider.summary;
          if (summary == null) {
            return const Center(child: Text('Tidak ada data bulan ini.'));
          }

          return RefreshIndicator(
            onRefresh: () async => _fetchSummary(),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          _selectedRangeText,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Row(
                        children: [
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
                    ],
                  ),
                  const SizedBox(height: 16),
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 1.5,
                    children: [
                      SummaryCard(
                        title: 'Pendapatan',
                        amount: CurrencyFormatter.format(summary.totalRevenue),
                        color: AppColors.primary,
                        icon: Icons.trending_up,
                      ),
                      SummaryCard(
                        title: 'Pengeluaran',
                        amount: CurrencyFormatter.format(summary.totalExpenses),
                        color: AppColors.error,
                        icon: Icons.trending_down,
                      ),
                      SummaryCard(
                        title: 'Laba Kotor',
                        amount: CurrencyFormatter.format(summary.totalGrossProfit),
                        color: AppColors.warning,
                        icon: Icons.account_balance_wallet,
                      ),
                      SummaryCard(
                        title: 'Laba Bersih',
                        amount: CurrencyFormatter.format(summary.netProfit),
                        color: AppColors.success,
                        icon: Icons.monetization_on,
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  const Text(
                    'Rekap Barang Terjual',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  if (summary.itemRecap.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16.0),
                      child: Text('Belum ada barang terjual pada periode ini.'),
                    ),
                  ...summary.itemRecap.map((recap) => ListTile(
                        leading: const CircleAvatar(child: Icon(Icons.analytics_outlined)),
                        title: Text(
                          recap.productName,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text('${recap.totalQuantity} pcs'),
                        trailing: Text(
                          CurrencyFormatter.format(recap.totalRevenue),
                          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
                        ),
                      )),
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await context.push('/sales/form');
          _fetchSummary();
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
