import 'package:dio/dio.dart';
import '../core/constants/api_endpoints.dart';
import '../core/network/api_client.dart';
import '../models/product.dart';

class ProductService {
  final ApiClient _apiClient = ApiClient();

  Future<List<Product>> getProducts() async {
    try {
      final response = await _apiClient.dio.get(ApiEndpoints.products);
      final List data = response.data['data'];
      return data.map((json) => Product.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to load products');
    }
  }

  Future<Product> createProduct(Map<String, dynamic> data) async {
    try {
      final response = await _apiClient.dio.post(ApiEndpoints.products, data: data);
      return Product.fromJson(response.data['data']);
    } on DioException catch (e) {
      final msg = e.response?.data['message'];
      throw Exception(msg ?? 'Failed to create product');
    }
  }

  Future<Product> updateProduct(int id, Map<String, dynamic> data) async {
    try {
      final response = await _apiClient.dio.put('${ApiEndpoints.products}/$id', data: data);
      return Product.fromJson(response.data['data']);
    } catch (e) {
      throw Exception('Failed to update product');
    }
  }

  Future<void> deleteProduct(int id) async {
    try {
      await _apiClient.dio.delete('${ApiEndpoints.products}/$id');
    } catch (e) {
      throw Exception('Failed to delete product');
    }
  }
}
