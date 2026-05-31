import 'package:flutter/foundation.dart';
import '../models/product.dart';
import '../services/product_service.dart';
import '../core/network/network_info.dart';
import '../services/sync_service.dart';

class ProductProvider with ChangeNotifier {
  final ProductService _productService = ProductService();

  List<Product> _products = [];
  bool _isLoading = false;
  String? _error;

  List<Product> get products => _products;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchProducts() async {
    _setLoading(true);
    try {
      if (await NetworkInfo.isConnected) {
        _products = await _productService.getProducts();
        final rawList = _products.map((p) => p.toJson()).toList();
        await SyncService.instance.cacheProducts(rawList);
        _error = null;
      } else {
        final cached = await SyncService.instance.getCachedProducts();
        if (cached != null) {
          _products = cached.map((json) => Product.fromJson(json)).toList();
          _error = null;
        } else {
          _products = [];
          _error = "Offline. Data produk tidak ditemukan di cache.";
        }
      }
    } catch (e) {
      final cached = await SyncService.instance.getCachedProducts();
      if (cached != null) {
        _products = cached.map((json) => Product.fromJson(json)).toList();
        _error = null;
      } else {
        _error = e.toString();
      }
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> addProduct(Map<String, dynamic> data) async {
    try {
      final newProduct = await _productService.createProduct(data);
      _products.insert(0, newProduct);
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
