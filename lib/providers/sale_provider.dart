import 'package:flutter/foundation.dart';
import '../models/sale.dart';
import '../models/sale_item.dart';
import '../services/sale_service.dart';
import '../core/network/network_info.dart';
import '../services/sync_service.dart';
import '../core/utils/date_helper.dart';

class SaleProvider with ChangeNotifier {
  final SaleService _saleService = SaleService();

  List<Sale> _sales = [];
  bool _isLoading = false;
  String? _error;

  List<Sale> get sales => _sales;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchSales({String? startDate, String? endDate}) async {
    _setLoading(true);
    try {
      final todayStr = DateHelper.toIsoDate(DateTime.now());
      final isDefaultToday = (startDate == todayStr && endDate == todayStr) || (startDate == null && endDate == null);

      if (await NetworkInfo.isConnected) {
        // Sync pending actions first
        await SyncService.instance.syncPendingSales();

        _sales = await _saleService.getSales(startDate: startDate, endDate: endDate);

        // Cache default sales history (today's range or no range)
        if (isDefaultToday) {
          final rawList = _sales.map((s) => s.toJson()).toList();
          await SyncService.instance.cacheSales(rawList);
        }
        _error = null;
      } else {
        if (!isDefaultToday) {
          throw Exception("Koneksi internet diperlukan untuk melihat data tanggal lain");
        }

        await _loadOfflineSales();
        _error = null;
      }
    } catch (e) {
      final todayStr = DateHelper.toIsoDate(DateTime.now());
      final isDefaultToday = (startDate == todayStr && endDate == todayStr) || (startDate == null && endDate == null);
      if (!isDefaultToday) {
        _error = e.toString().replaceAll('Exception: ', '');
      } else {
        // Fallback to cache
        await _loadOfflineSales();
        _error = null;
      }
    } finally {
      _setLoading(false);
    }
  }

  Future<void> _loadOfflineSales() async {
    final cached = await SyncService.instance.getCachedSales() ?? [];
    List<Sale> localList = cached.map((json) => Sale.fromJson(json)).toList();
    
    final pending = await SyncService.instance.getPendingSales();
    final cachedProducts = await SyncService.instance.getCachedProducts() ?? [];

    List<Sale> pendingSalesList = [];
    for (var item in pending) {
      final payload = Map<String, dynamic>.from(item['payload']);
      final items = List<Map<String, dynamic>>.from(payload['items'] ?? []);

      double totalRev = 0;
      double totalCost = 0;
      List<SaleItem> saleItems = [];

      for (var itemData in items) {
        final name = itemData['product_name'] ?? '';
        final double sellPrice = double.tryParse(itemData['sell_price'].toString()) ?? 0.0;
        final int qty = int.tryParse(itemData['quantity'].toString()) ?? 0;

        double costPrice = 0.0;
        int? productId;
        final matchingProd = cachedProducts.firstWhere(
          (p) => p['name'].toString().toLowerCase() == name.toString().toLowerCase(),
          orElse: () => {},
        );
        if (matchingProd.isNotEmpty) {
          costPrice = double.tryParse(matchingProd['cost_price'].toString()) ?? 0.0;
          productId = matchingProd['id'];
        }

        final subRev = sellPrice * qty;
        final subCost = costPrice * qty;

        saleItems.add(SaleItem(
          id: -1,
          productId: productId,
          productName: name,
          costPrice: costPrice,
          sellPrice: sellPrice,
          quantity: qty,
          subtotalCost: subCost,
          subtotalRevenue: subRev,
          subtotalProfit: subRev - subCost,
        ));

        totalRev += subRev;
        totalCost += subCost;
      }

      pendingSalesList.add(Sale(
        id: item['id'],
        saleCode: 'OFFLINE-${item['id'].toString().replaceAll('-', '')}',
        totalCost: totalCost,
        totalRevenue: totalRev,
        grossProfit: totalRev - totalCost,
        notes: payload['notes'],
        saleDate: payload['sale_date'],
        items: saleItems,
      ));
    }

    _sales = [...pendingSalesList, ...localList];
  }

  Future<bool> addSale(Map<String, dynamic> data) async {
    try {
      if (await NetworkInfo.isConnected) {
        // Sync pending first
        await SyncService.instance.syncPendingSales();

        final newSale = await _saleService.createSale(data);
        _sales.insert(0, newSale);

        // Update sales cache
        final cached = await SyncService.instance.getCachedSales() ?? [];
        cached.insert(0, newSale.toJson());
        await SyncService.instance.cacheSales(cached);

        notifyListeners();
        return true;
      } else {
        // Store offline
        final localId = -DateTime.now().millisecondsSinceEpoch;
        await SyncService.instance.queueSale(data, localId: localId);
        
        // Re-load offline combined list to update UI state
        await _loadOfflineSales();
        notifyListeners();
        return true;
      }
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  List<Map<String, dynamic>> _suggestions = [];
  List<Map<String, dynamic>> get suggestions => _suggestions;

  Future<void> fetchSuggestions() async {
    try {
      if (await NetworkInfo.isConnected) {
        _suggestions = await _saleService.getSuggestions();
        await SyncService.instance.cacheSuggestions(_suggestions);
      } else {
        _suggestions = await SyncService.instance.getCachedSuggestions() ?? [];
      }
      notifyListeners();
    } catch (e) {
      // Fail silently, load from cache if possible
      _suggestions = await SyncService.instance.getCachedSuggestions() ?? [];
      notifyListeners();
    }
  }

  Future<bool> editSale(int id, Map<String, dynamic> data) async {
    try {
      if (id < 0) {
        // Update local offline pending transaction
        await SyncService.instance.queueSale(data, localId: id);
        await _loadOfflineSales();
        notifyListeners();
        return true;
      }

      if (await NetworkInfo.isConnected) {
        final updatedSale = await _saleService.updateSale(id, data);
        final index = _sales.indexWhere((s) => s.id == id);
        if (index >= 0) {
          _sales[index] = updatedSale;
          
          // Update cache
          final cached = await SyncService.instance.getCachedSales() ?? [];
          final cIndex = cached.indexWhere((c) => c['id'] == id);
          if (cIndex >= 0) {
            cached[cIndex] = updatedSale.toJson();
            await SyncService.instance.cacheSales(cached);
          }
          
          notifyListeners();
        }
        return true;
      } else {
        throw Exception("Koneksi internet diperlukan untuk mengubah transaksi yang sudah tersimpan di server");
      }
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteSale(int id) async {
    try {
      if (id < 0) {
        // Delete local offline pending transaction
        await SyncService.instance.removePendingSale(id);
        await _loadOfflineSales();
        notifyListeners();
        return true;
      }

      if (await NetworkInfo.isConnected) {
        await _saleService.deleteSale(id);
        _sales.removeWhere((sale) => sale.id == id);

        // Update cache
        final cached = await SyncService.instance.getCachedSales() ?? [];
        cached.removeWhere((c) => c['id'] == id);
        await SyncService.instance.cacheSales(cached);

        notifyListeners();
        return true;
      } else {
        throw Exception("Koneksi internet diperlukan untuk menghapus transaksi yang sudah tersimpan di server");
      }
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
