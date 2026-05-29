import 'package:dio/dio.dart';
import '../core/constants/api_endpoints.dart';
import '../core/network/api_client.dart';
import '../models/dashboard_summary.dart';

class DashboardService {
  final ApiClient _apiClient = ApiClient();

  Future<DashboardSummary> getDashboardSummary({String? startDate, String? endDate}) async {
    try {
      Map<String, dynamic> query = {};
      if (startDate != null) query['start_date'] = startDate;
      if (endDate != null) query['end_date'] = endDate;

      final response = await _apiClient.dio.get(
        ApiEndpoints.dashboard,
        queryParameters: query,
      );
      return DashboardSummary.fromJson(response.data['data']);
    } catch (e) {
      throw Exception('Failed to load dashboard data');
    }
  }
}
