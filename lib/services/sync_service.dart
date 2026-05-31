import 'package:hive/hive.dart';
import '../core/network/network_info.dart';
import 'sale_service.dart';

class SyncService {
  static final SyncService instance = SyncService._internal();
  SyncService._internal();

  final SaleService _saleService = SaleService();

  Box? _pendingSalesBox;
  Box? _salesCacheBox;
  Box? _dashboardCacheBox;
  Box? _productsCacheBox;
  Box? _suggestionsCacheBox;
  Box? _expensesCacheBox;

  Future<Box> _getBox(String name) async {
    if (Hive.isBoxOpen(name)) {
      return Hive.box(name);
    }
    return await Hive.openBox(name);
  }

  Future<Box> get pendingSalesBox async => _pendingSalesBox ??= await _getBox('pending_sales');
  Future<Box> get salesCacheBox async => _salesCacheBox ??= await _getBox('sales_cache');
  Future<Box> get dashboardCacheBox async => _dashboardCacheBox ??= await _getBox('dashboard_cache');
  Future<Box> get productsCacheBox async => _productsCacheBox ??= await _getBox('products_cache');
  Future<Box> get suggestionsCacheBox async => _suggestionsCacheBox ??= await _getBox('suggestions_cache');
  Future<Box> get expensesCacheBox async => _expensesCacheBox ??= await _getBox('expenses_cache');

  // --- Pending Sales Queue ---
  Future<void> queueSale(Map<String, dynamic> payload, {required int localId}) async {
    final box = await pendingSalesBox;
    await box.put(localId, {
      'id': localId,
      'payload': payload,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  Future<List<Map<String, dynamic>>> getPendingSales() async {
    final box = await pendingSalesBox;
    final List<Map<String, dynamic>> list = [];
    for (var key in box.keys) {
      final value = box.get(key);
      if (value != null) {
        list.add(Map<String, dynamic>.from(value));
      }
    }
    // Sort chronologically (localId is timestamp, so lower is older)
    list.sort((a, b) => a['id'].compareTo(b['id']));
    return list;
  }

  Future<void> removePendingSale(int localId) async {
    final box = await pendingSalesBox;
    await box.delete(localId);
  }

  Future<int> getPendingSalesCount() async {
    final box = await pendingSalesBox;
    return box.length;
  }

  // --- Caching Utilities ---
  Future<void> cacheSales(List<Map<String, dynamic>> salesJsonList) async {
    final box = await salesCacheBox;
    await box.put('latest_sales', salesJsonList);
  }

  Future<List<Map<String, dynamic>>?> getCachedSales() async {
    final box = await salesCacheBox;
    final data = box.get('latest_sales');
    if (data != null) {
      return List<Map<String, dynamic>>.from(
        (data as List).map((item) => Map<String, dynamic>.from(item)),
      );
    }
    return null;
  }

  Future<void> cacheDashboard(Map<String, dynamic> dashboardJson) async {
    final box = await dashboardCacheBox;
    await box.put('latest_dashboard', dashboardJson);
  }

  Future<Map<String, dynamic>?> getCachedDashboard() async {
    final box = await dashboardCacheBox;
    final data = box.get('latest_dashboard');
    if (data != null) {
      return Map<String, dynamic>.from(data);
    }
    return null;
  }

  Future<void> cacheProducts(List<Map<String, dynamic>> productsJsonList) async {
    final box = await productsCacheBox;
    await box.put('latest_products', productsJsonList);
  }

  Future<List<Map<String, dynamic>>?> getCachedProducts() async {
    final box = await productsCacheBox;
    final data = box.get('latest_products');
    if (data != null) {
      return List<Map<String, dynamic>>.from(
        (data as List).map((item) => Map<String, dynamic>.from(item)),
      );
    }
    return null;
  }

  Future<void> cacheSuggestions(List<Map<String, dynamic>> suggestionsJsonList) async {
    final box = await suggestionsCacheBox;
    await box.put('latest_suggestions', suggestionsJsonList);
  }

  Future<List<Map<String, dynamic>>?> getCachedSuggestions() async {
    final box = await suggestionsCacheBox;
    final data = box.get('latest_suggestions');
    if (data != null) {
      return List<Map<String, dynamic>>.from(
        (data as List).map((item) => Map<String, dynamic>.from(item)),
      );
    }
    return null;
  }

  Future<void> cacheExpenses(List<Map<String, dynamic>> expensesJsonList) async {
    final box = await expensesCacheBox;
    await box.put('latest_expenses', expensesJsonList);
  }

  Future<List<Map<String, dynamic>>?> getCachedExpenses() async {
    final box = await expensesCacheBox;
    final data = box.get('latest_expenses');
    if (data != null) {
      return List<Map<String, dynamic>>.from(
        (data as List).map((item) => Map<String, dynamic>.from(item)),
      );
    }
    return null;
  }

  // --- Synchronization Method ---
  Future<bool> syncPendingSales() async {
    if (!await NetworkInfo.isConnected) return false;

    final pending = await getPendingSales();
    if (pending.isEmpty) return true;

    bool allSuccess = true;
    for (var item in pending) {
      final localId = item['id'];
      final payload = Map<String, dynamic>.from(item['payload']);

      try {
        await _saleService.createSale(payload);
        await removePendingSale(localId);
      } catch (e) {
        allSuccess = false;
        // Halt synchronization on first failure to preserve order
        break;
      }
    }

    return allSuccess;
  }
}
