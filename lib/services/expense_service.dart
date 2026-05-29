import 'package:dio/dio.dart';
import '../core/constants/api_endpoints.dart';
import '../core/network/api_client.dart';
import '../models/expense.dart';

class ExpenseService {
  final ApiClient _apiClient = ApiClient();

  Future<List<Expense>> getExpenses() async {
    try {
      final response = await _apiClient.dio.get(ApiEndpoints.expenses);
      final List data = response.data['data'];
      return data.map((json) => Expense.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to load expenses');
    }
  }

  Future<Expense> createExpense(Map<String, dynamic> data) async {
    try {
      final response = await _apiClient.dio.post(ApiEndpoints.expenses, data: data);
      return Expense.fromJson(response.data['data']);
    } catch (e) {
      throw Exception('Failed to create expense');
    }
  }

  Future<Expense> updateExpense(int id, Map<String, dynamic> data) async {
    try {
      final response = await _apiClient.dio.put('${ApiEndpoints.expenses}/$id', data: data);
      return Expense.fromJson(response.data['data']);
    } catch (e) {
      throw Exception('Failed to update expense');
    }
  }

  Future<void> deleteExpense(int id) async {
    try {
      await _apiClient.dio.delete('${ApiEndpoints.expenses}/$id');
    } catch (e) {
      throw Exception('Failed to delete expense');
    }
  }
}
