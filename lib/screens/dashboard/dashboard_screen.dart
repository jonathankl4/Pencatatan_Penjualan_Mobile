import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../providers/dashboard_provider.dart';
import '../../providers/sale_provider.dart';
import '../../core/constants/app_strings.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/currency_formatter.dart';
import '../../widgets/dashboard/summary_card.dart';
import '../../widgets/common/app_drawer.dart';
import '../../core/utils/date_helper.dart';
import '../../services/sync_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  DateTimeRange? _selectedDateRange;
  String _recapSearchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchSummary();
      context.read<SaleProvider>().fetchSales(); // also fetch sales to trigger sync or cache load
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
      return 'Ringkasan Hari Ini';
    }
    final startStr = DateHelper.formatDate(DateHelper.toIsoDate(_selectedDateRange!.start));
    final endStr = DateHelper.formatDate(DateHelper.toIsoDate(_selectedDateRange!.end));
    return '$startStr - $endStr';
  }

  Widget _buildOfflineBanner(BuildContext context) {
    context.watch<SaleProvider>(); // Listen to changes
    return FutureBuilder<int>(
      future: SyncService.instance.getPendingSalesCount(),
      builder: (context, snapshot) {
        final pendingCount = snapshot.data ?? 0;
        if (pendingCount == 0) return const SizedBox.shrink();

        return Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.amber.shade50,
            border: Border(bottom: BorderSide(color: Colors.amber.shade200)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              Icon(Icons.cloud_off_rounded, color: Colors.amber.shade800, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '$pendingCount transaksi offline belum disinkronkan.',
                  style: TextStyle(color: Colors.amber.shade900, fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                icon: const Icon(Icons.sync_rounded, size: 14),
                label: const Text('Sinkron', style: TextStyle(fontSize: 12)),
                onPressed: () async {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Menyinkronkan data ke server...')),
                  );
                  final success = await SyncService.instance.syncPendingSales();
                  if (context.mounted) {
                    if (success) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Data berhasil disinkronkan!')),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Gagal menyinkronkan data. Silakan cek koneksi internet.')),
                      );
                    }
                    context.read<DashboardProvider>().fetchSummary();
                    context.read<SaleProvider>().fetchSales();
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber.shade700,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ],
          ),
        );
      },
    );
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
              final authProvider = context.read<AuthProvider>();
              await authProvider.logout();
              if (context.mounted) {
                context.go('/login');
              }
            },
          ),
        ],
      ),
      drawer: const AppDrawer(),
      body: Column(
        children: [
          _buildOfflineBanner(context),
          Expanded(
            child: Consumer<DashboardProvider>(
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
                  return const Center(child: Text('Tidak ada data hari ini.'));
                }

          return RefreshIndicator(
            onRefresh: () async => _fetchSummary(),
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 16.0, bottom: 88.0),
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
                    childAspectRatio: 1.4,
                    children: [
                      SummaryCard(
                        title: 'Pendapatan',
                        amount: CurrencyFormatter.format(summary.totalRevenue),
                        color: AppColors.primary,
                        icon: Icons.trending_up,
                        onTap: () async {
                          final start = _selectedDateRange?.start;
                          final end = _selectedDateRange?.end;
                          final startStr = start != null ? DateHelper.toIsoDate(start) : DateHelper.toIsoDate(DateTime.now());
                          final endStr = end != null ? DateHelper.toIsoDate(end) : DateHelper.toIsoDate(DateTime.now());

                          final result = await context.push<DateTimeRange?>(
                            Uri(
                              path: '/sales',
                              queryParameters: {
                                'startDate': startStr,
                                'endDate': endStr,
                              },
                            ).toString(),
                          );
                          if (mounted) {
                            if (result != null) {
                              setState(() {
                                _selectedDateRange = result;
                              });
                            }
                            _fetchSummary();
                          }
                        },
                      ),
                      SummaryCard(
                        title: 'Pengeluaran',
                        amount: CurrencyFormatter.format(summary.totalExpenses),
                        color: AppColors.error,
                        icon: Icons.trending_down,
                        onTap: () async {
                          final start = _selectedDateRange?.start;
                          final end = _selectedDateRange?.end;
                          final startStr = start != null ? DateHelper.toIsoDate(start) : DateHelper.toIsoDate(DateTime.now());
                          final endStr = end != null ? DateHelper.toIsoDate(end) : DateHelper.toIsoDate(DateTime.now());

                          final result = await context.push<DateTimeRange?>(
                            Uri(
                              path: '/expenses',
                              queryParameters: {
                                'startDate': startStr,
                                'endDate': endStr,
                              },
                            ).toString(),
                          );
                          if (mounted) {
                            if (result != null) {
                              setState(() {
                                _selectedDateRange = result;
                              });
                            }
                            _fetchSummary();
                          }
                        },
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
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'Cari barang terjual...',
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      onChanged: (value) {
                        setState(() {
                          _recapSearchQuery = value;
                        });
                      },
                    ),
                  ),
                  const SizedBox(height: 8),
                  Builder(
                    builder: (context) {
                      final filteredRecap = summary.itemRecap.where((recap) {
                        if (_recapSearchQuery.isEmpty) return true;
                        return recap.productName.toLowerCase().contains(_recapSearchQuery.toLowerCase());
                      }).toList()..sort((a, b) => a.productName.toLowerCase().compareTo(b.productName.toLowerCase()));

                      if (filteredRecap.isEmpty) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16.0),
                          child: Text('Belum ada barang terjual pada periode ini.'),
                        );
                      }

                      return Column(
                        children: filteredRecap.map((recap) => ListTile(
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
                          onTap: () async {
                            final start = _selectedDateRange?.start;
                            final end = _selectedDateRange?.end;
                            final startStr = start != null ? DateHelper.toIsoDate(start) : DateHelper.toIsoDate(DateTime.now());
                            final endStr = end != null ? DateHelper.toIsoDate(end) : DateHelper.toIsoDate(DateTime.now());

                            final result = await context.push<DateTimeRange?>(
                              Uri(
                                path: '/sales',
                                queryParameters: {
                                  'searchQuery': recap.productName,
                                  'startDate': startStr,
                                  'endDate': endStr,
                                },
                              ).toString(),
                            );
                            if (mounted) {
                              if (result != null) {
                                setState(() {
                                  _selectedDateRange = result;
                                });
                              }
                              _fetchSummary();
                            }
                          },
                        )).toList(),
                      );
                    },
                  ),
                ],
              ),
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
          _fetchSummary();
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
