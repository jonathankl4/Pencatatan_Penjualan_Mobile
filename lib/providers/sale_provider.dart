import 'package:flutter/foundation.dart';
import '../models/sale.dart';
import '../services/sale_service.dart';

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
      _sales = await _saleService.getSales(startDate: startDate, endDate: endDate);
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> addSale(Map<String, dynamic> data) async {
    try {
      final newSale = await _saleService.createSale(data);
      _sales.insert(0, newSale);
      notifyListeners();
      return true;
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
      _suggestions = await _saleService.getSuggestions();
      notifyListeners();
    } catch (e) {
      // Fail silently
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
