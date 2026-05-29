import 'package:flutter/foundation.dart';
import '../models/dashboard_summary.dart';
import '../services/dashboard_service.dart';

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
      _summary = await _dashboardService.getDashboardSummary(
        startDate: startDate,
        endDate: endDate,
      );
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
