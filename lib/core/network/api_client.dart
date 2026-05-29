import 'package:dio/dio.dart';
import 'package:hive/hive.dart';
import '../constants/api_endpoints.dart';

class ApiClient {
  late Dio _dio;

  ApiClient() {
    _dio = Dio(BaseOptions(
      baseUrl: ApiEndpoints.baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {
        'Accept': 'application/json',
      },
    ));

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final box = await Hive.openBox('authBox');
        final token = box.get('token');
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
      onError: (DioException e, handler) {
        // Here you could handle global errors like 401 Unauthorized
        return handler.next(e);
      },
    ));
  }

  Dio get dio => _dio;
}
