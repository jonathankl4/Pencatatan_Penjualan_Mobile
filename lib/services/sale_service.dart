import 'package:dio/dio.dart';
import '../core/constants/api_endpoints.dart';
import '../core/network/api_client.dart';
import '../models/sale.dart';

class SaleService {
  final ApiClient _apiClient = ApiClient();

  Future<List<Sale>> getSales({String? startDate, String? endDate}) async {
    try {
      Map<String, dynamic> query = {};
      if (startDate != null) query['start_date'] = startDate;
      if (endDate != null) query['end_date'] = endDate;

      final response = await _apiClient.dio.get(
        ApiEndpoints.sales,
        queryParameters: query,
      );
      final List data = response.data['data'];
      return data.map((json) => Sale.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to load sales');
    }
  }

  Future<Sale> createSale(Map<String, dynamic> data) async {
    try {
      final response = await _apiClient.dio.post(ApiEndpoints.sales, data: data);
      return Sale.fromJson(response.data['data']);
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Failed to create sale');
    }
  }

  Future<void> deleteSale(int id) async {
    try {
      await _apiClient.dio.delete('${ApiEndpoints.sales}/$id');
    } catch (e) {
      throw Exception('Failed to delete sale');
    }
  }

  Future<List<Map<String, dynamic>>> getSuggestions() async {
    try {
      final response = await _apiClient.dio.get(ApiEndpoints.saleSuggestions);
      final List data = response.data['data'];
      return List<Map<String, dynamic>>.from(data);
    } catch (e) {
      throw Exception('Failed to load suggestions');
    }
  }

  Future<Sale> updateSale(int id, Map<String, dynamic> data) async {
    try {
      final response = await _apiClient.dio.put('${ApiEndpoints.sales}/$id', data: data);
      return Sale.fromJson(response.data['data']);
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Failed to update sale');
    }
  }
}
