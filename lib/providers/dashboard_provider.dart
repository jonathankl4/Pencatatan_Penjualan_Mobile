import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../models/dashboard_summary.dart';
import '../services/dashboard_service.dart';
import '../core/network/network_info.dart';
import '../services/sync_service.dart';

class DashboardProvider with ChangeNotifier {
  final DashboardService _dashboardService = DashboardService();

  DashboardSummary? _summary;
  bool _isLoading = false;
  String? _error;

  DashboardSummary? get summary => _summary;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchSummary({String? startDate, String? endDate}) async {
    _setLoading(true);
    try {
      if (await NetworkInfo.isConnected) {
        // Sync pending actions first if any to have clean dashboard
        await SyncService.instance.syncPendingSales();

        _summary = await _dashboardService.getDashboardSummary(
          startDate: startDate,
          endDate: endDate,
        );

        // Cache default dashboard (no date filter)
        if (startDate == null && endDate == null) {
          final dataMap = {
            'period': {
              'start': _summary!.periodStart,
              'end': _summary!.periodEnd,
            },
            'summary': {
              'total_revenue': _summary!.totalRevenue,
              'total_gross_profit': _summary!.totalGrossProfit,
              'total_expenses': _summary!.totalExpenses,
              'net_profit': _summary!.netProfit,
            },
            'recent_sales': _summary!.recentSales.map((s) => s.toJson()).toList(),
            'recent_expenses': _summary!.recentExpenses.map((e) => e.toJson()).toList(),
            'item_recap': _summary!.itemRecap.map((r) => {
              'product_name': r.productName,
              'total_quantity': r.totalQuantity,
              'total_revenue': r.totalRevenue,
            }).toList(),
          };
          await SyncService.instance.cacheDashboard(dataMap);
        }
        _error = null;
      } else {
        if (startDate != null || endDate != null) {
          throw Exception("Koneksi internet diperlukan untuk melihat data tanggal lain");
        }

        final cachedJson = await SyncService.instance.getCachedDashboard();
        if (cachedJson != null) {
          final Map<String, dynamic> modifiedJson = jsonDecode(jsonEncode(cachedJson));
          
          final pendingSales = await SyncService.instance.getPendingSales();
          final cachedProducts = await SyncService.instance.getCachedProducts() ?? [];

          double additionalRevenue = 0;
          double additionalProfit = 0;
          List<Map<String, dynamic>> tempSalesJson = [];

          for (var pending in pendingSales) {
            final payload = Map<String, dynamic>.from(pending['payload']);
            final items = List<Map<String, dynamic>>.from(payload['items'] ?? []);
            
            double saleRevenue = 0;
            double saleCost = 0;
            
            List<Map<String, dynamic>> saleItemsJson = [];
            for (var item in items) {
              final name = item['product_name'] ?? '';
              final double sellPrice = double.tryParse(item['sell_price'].toString()) ?? 0.0;
              final int qty = int.tryParse(item['quantity'].toString()) ?? 0;
              
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

              final subCost = costPrice * qty;
              final subRev = sellPrice * qty;
              final subProfit = subRev - subCost;

              saleRevenue += subRev;
              saleCost += subCost;

              saleItemsJson.add({
                'id': -1,
                'product_id': productId,
                'product_name': name,
                'cost_price': costPrice,
                'sell_price': sellPrice,
                'quantity': qty,
                'subtotal_cost': subCost,
                'subtotal_revenue': subRev,
                'subtotal_profit': subProfit,
              });

              // Update item recap
              final recapList = List<Map<String, dynamic>>.from(modifiedJson['item_recap'] ?? []);
              final recapIndex = recapList.indexWhere((r) => r['product_name'].toString().toLowerCase() == name.toString().toLowerCase());
              if (recapIndex >= 0) {
                recapList[recapIndex]['total_quantity'] = (int.tryParse(recapList[recapIndex]['total_quantity'].toString()) ?? 0) + qty;
                recapList[recapIndex]['total_revenue'] = (double.tryParse(recapList[recapIndex]['total_revenue'].toString()) ?? 0.0) + subRev;
              } else {
                recapList.add({
                  'product_name': name,
                  'total_quantity': qty,
                  'total_revenue': subRev,
                });
              }
              modifiedJson['item_recap'] = recapList;
            }

            final double saleProfit = saleRevenue - saleCost;
            additionalRevenue += saleRevenue;
            additionalProfit += saleProfit;

            tempSalesJson.add({
              'id': pending['id'],
              'sale_code': 'OFFLINE-${pending['id'].toString().replaceAll('-', '')}',
              'total_cost': saleCost,
              'total_revenue': saleRevenue,
              'gross_profit': saleProfit,
              'notes': payload['notes'],
              'sale_date': payload['sale_date'],
              'items': saleItemsJson,
            });
          }

          modifiedJson['summary']['total_revenue'] = (double.tryParse(modifiedJson['summary']['total_revenue'].toString()) ?? 0.0) + additionalRevenue;
          modifiedJson['summary']['total_gross_profit'] = (double.tryParse(modifiedJson['summary']['total_gross_profit'].toString()) ?? 0.0) + additionalProfit;
          modifiedJson['summary']['net_profit'] = (double.tryParse(modifiedJson['summary']['net_profit'].toString()) ?? 0.0) + additionalProfit;

          final recentSalesList = List<Map<String, dynamic>>.from(modifiedJson['recent_sales'] ?? []);
          recentSalesList.insertAll(0, tempSalesJson);
          if (recentSalesList.length > 5) {
            modifiedJson['recent_sales'] = recentSalesList.sublist(0, 5);
          } else {
            modifiedJson['recent_sales'] = recentSalesList;
          }

          _summary = DashboardSummary.fromJson(modifiedJson);
          _error = null;
        } else {
          _summary = null;
          _error = "Offline. Ringkasan dashboard tidak ditemukan di cache.";
        }
      }
    } catch (e) {
      if (startDate != null || endDate != null) {
        _error = e.toString().replaceAll('Exception: ', '');
      } else {
        // Fallback to cache
        final cachedJson = await SyncService.instance.getCachedDashboard();
        if (cachedJson != null) {
          _summary = DashboardSummary.fromJson(cachedJson);
          _error = null;
        } else {
          _error = e.toString();
        }
      }
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
