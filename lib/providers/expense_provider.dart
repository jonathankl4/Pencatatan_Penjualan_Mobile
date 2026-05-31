import 'package:flutter/foundation.dart';
import '../models/expense.dart';
import '../services/expense_service.dart';
import '../core/network/network_info.dart';
import '../services/sync_service.dart';

class ExpenseProvider with ChangeNotifier {
  final ExpenseService _expenseService = ExpenseService();

  List<Expense> _expenses = [];
  bool _isLoading = false;
  String? _error;

  List<Expense> get expenses => _expenses;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchExpenses({String? startDate, String? endDate}) async {
    _setLoading(true);
    try {
      if (await NetworkInfo.isConnected) {
        _expenses = await _expenseService.getExpenses(startDate: startDate, endDate: endDate);
        if (startDate == null && endDate == null) {
          final rawList = _expenses.map((e) => e.toJson()).toList();
          await SyncService.instance.cacheExpenses(rawList);
        }
        _error = null;
      } else {
        if (startDate != null || endDate != null) {
          throw Exception("Koneksi internet diperlukan untuk melihat data tanggal lain");
        }
        final cached = await SyncService.instance.getCachedExpenses();
        if (cached != null) {
          _expenses = cached.map((json) => Expense.fromJson(json)).toList();
          _error = null;
        } else {
          _expenses = [];
          _error = "Offline. Data pengeluaran tidak ditemukan di cache.";
        }
      }
    } catch (e) {
      if (startDate != null || endDate != null) {
        _error = e.toString().replaceAll('Exception: ', '');
      } else {
        final cached = await SyncService.instance.getCachedExpenses();
        if (cached != null) {
          _expenses = cached.map((json) => Expense.fromJson(json)).toList();
          _error = null;
        } else {
          _error = e.toString();
        }
      }
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> addExpense(Map<String, dynamic> data) async {
    try {
      final newExpense = await _expenseService.createExpense(data);
      _expenses.insert(0, newExpense);
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateExpense(int id, Map<String, dynamic> data) async {
    try {
      final updated = await _expenseService.updateExpense(id, data);
      final index = _expenses.indexWhere((e) => e.id == id);
      if (index >= 0) {
        _expenses[index] = updated;
      }
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteExpense(int id) async {
    try {
      await _expenseService.deleteExpense(id);
      _expenses.removeWhere((e) => e.id == id);
      notifyListeners();
      return true;
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
