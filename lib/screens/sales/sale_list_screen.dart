import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/sale_provider.dart';
import '../../core/utils/currency_formatter.dart';
import '../../widgets/common/empty_state.dart';
import '../../widgets/common/app_drawer.dart';
import '../../core/utils/date_helper.dart';
import '../../services/sync_service.dart';

class SaleListScreen extends StatefulWidget {
  final String? initialSearchQuery;
  final DateTime? initialStartDate;
  final DateTime? initialEndDate;
  final bool hasInitialFilters;

  const SaleListScreen({
    super.key,
    this.initialSearchQuery,
    this.initialStartDate,
    this.initialEndDate,
    this.hasInitialFilters = false,
  });

  @override
  State<SaleListScreen> createState() => _SaleListScreenState();
}

class _SaleListScreenState extends State<SaleListScreen> {
  DateTimeRange? _selectedDateRange;
  String _searchQuery = '';
  late TextEditingController _searchController;
  bool _isPopping = false;

  @override
  void initState() {
    super.initState();
    if (widget.hasInitialFilters) {
      _searchQuery = widget.initialSearchQuery ?? '';
      if (widget.initialStartDate != null && widget.initialEndDate != null) {
        _selectedDateRange = DateTimeRange(
          start: widget.initialStartDate!,
          end: widget.initialEndDate!,
        );
      } else {
        _selectedDateRange = null;
      }
    } else {
      _searchQuery = '';
      _selectedDateRange = DateTimeRange(
        start: DateTime.now(),
        end: DateTime.now(),
      );
    }
    _searchController = TextEditingController(text: _searchQuery);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchSales();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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

  void _confirmDelete(int id, String saleCode) {
    showDialog(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
          title: const Text('Hapus Transaksi'),
          content: Text('Apakah Anda yakin ingin menghapus transaksi $saleCode? Tindakan ini tidak dapat dibatalkan.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () async {
                final messenger = ScaffoldMessenger.of(context);
                final provider = context.read<SaleProvider>();
                Navigator.pop(dialogCtx);
                final success = await provider.deleteSale(id);
                if (mounted) {
                  if (success) {
                    messenger.showSnackBar(
                      SnackBar(content: Text('Transaksi $saleCode berhasil dihapus')),
                    );
                  } else {
                    messenger.showSnackBar(
                      SnackBar(content: Text(provider.error ?? 'Gagal menghapus transaksi')),
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
                    _fetchSales();
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
          title: const Text('Riwayat Penjualan'),
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
          _buildOfflineBanner(context),
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
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Cari berdasarkan nama barang...',
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
                  child: Consumer<SaleProvider>(
                    builder: (context, provider, child) {
                      if (provider.isLoading) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (provider.error != null) {
                        return Center(child: Text('Error: ${provider.error}'));
                      }

                      final filteredSales = provider.sales.where((sale) {
                        if (_searchQuery.isEmpty) return true;
                        return sale.items.any((item) =>
                            item.productName.toLowerCase().contains(_searchQuery.toLowerCase()));
                      }).toList();

                      if (filteredSales.isEmpty) {
                        return const EmptyState(
                          message: 'Belum ada penjualan.',
                          icon: Icons.receipt_long,
                        );
                      }

                      return RefreshIndicator(
                        onRefresh: () async => _fetchSales(),
                        child: ListView.builder(
                          padding: const EdgeInsets.only(bottom: 88.0),
                          itemCount: filteredSales.length,
                          itemBuilder: (context, index) {
                            final sale = filteredSales[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Text(
                                              sale.saleCode,
                                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                            ),
                                            if (sale.id < 0) ...[
                                              const SizedBox(width: 8),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: Colors.amber.shade50,
                                                  borderRadius: BorderRadius.circular(4),
                                                  border: Border.all(color: Colors.amber.shade200),
                                                ),
                                                child: Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    Icon(Icons.cloud_off_rounded, size: 10, color: Colors.amber.shade700),
                                                    const SizedBox(width: 4),
                                                    Text(
                                                      'Offline',
                                                      style: TextStyle(color: Colors.amber.shade800, fontSize: 9, fontWeight: FontWeight.bold),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          DateHelper.formatDate(sale.saleDate),
                                          style: const TextStyle(color: Colors.grey, fontSize: 12),
                                        ),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.edit_outlined, color: Colors.blue),
                                    onPressed: () async {
                                      await context.push('/sales/form', extra: sale);
                                      if (mounted) {
                                        _fetchSales();
                                      }
                                    },
                                    constraints: const BoxConstraints(),
                                    padding: EdgeInsets.zero,
                                    iconSize: 20,
                                    tooltip: 'Edit Penjualan',
                                  ),
                                  const SizedBox(width: 12),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                                    onPressed: () {
                                      _confirmDelete(sale.id, sale.saleCode);
                                    },
                                    constraints: const BoxConstraints(),
                                    padding: EdgeInsets.zero,
                                    iconSize: 20,
                                    tooltip: 'Hapus Penjualan',
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
    ),);
  }
}
