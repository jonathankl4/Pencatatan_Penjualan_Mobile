import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import '../models/user.dart';
import '../services/auth_service.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  
  User? _user;
  String? _token;
  bool _isLoading = false;
  String? _error;

  User? get user => _user;
  bool get isAuthenticated => _token != null;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> initAuth() async {
    final box = await Hive.openBox('authBox');
    _token = box.get('token');
    
    // In a real app, you might want to fetch user profile using the token here to verify it's still valid
    
    notifyListeners();
  }

  Future<bool> login(String email, String password) async {
    _setLoading(true);
    try {
      final result = await _authService.login(email, password);
      _token = result['token'];
      _user = result['user'];
      
      final box = await Hive.openBox('authBox');
      await box.put('token', _token);
      
      _error = null;
      _setLoading(false);
      return true;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      _setLoading(false);
      return false;
    }
  }

  Future<void> logout() async {
    _setLoading(true);
    await _authService.logout();
    
    _token = null;
    _user = null;
    
    final box = await Hive.openBox('authBox');
    await box.delete('token');
    
    _setLoading(false);
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
