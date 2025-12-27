import 'package:dio/dio.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';

class DioClient {
  DioClient({required String baseUrl, String? token})
      : _dio = Dio(
          BaseOptions(
            baseUrl: baseUrl,
            connectTimeout: const Duration(seconds: 10),
            receiveTimeout: const Duration(seconds: 10),
            sendTimeout: const Duration(seconds: 10),
            headers: {
              'Accept': 'application/json',
              if (token != null) 'Authorization': 'Bearer $token',
            },
          ), // BaseOptions
        ) { // Dio
    _dio.interceptors.addAll([
      PrettyDioLogger(
        requestHeader: true,
        requestBody: true,
        responseBody: true,
        responseHeader: false,
        compact: true,
      ),
      InterceptorsWrapper(
        onError: (e, handler) {
          // Forward standardized error message
          return handler.next(_mapError(e));
        },
      ),
    ]);
  }

  final Dio _dio;

  // Expose Dio instance for accessing headers (e.g., for Image.network fallback)
  Dio get dio => _dio;

  DioException _mapError(DioException error) {
    // Central place to normalize Dio errors
    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.sendTimeout) {
      return DioException(
        requestOptions: error.requestOptions,
        type: error.type,
        error: 'Cek koneksi internet anda',
      );
    }

    if (error.type == DioExceptionType.connectionError ||
        error.type == DioExceptionType.unknown) {
      // Network/connection errors
      return DioException(
        requestOptions: error.requestOptions,
        type: error.type,
        error: 'Cek koneksi internet anda',
      );
    }

    if (error.type == DioExceptionType.badResponse) {
      final status = error.response?.statusCode;
      final message = error.response?.data is Map
          ? (error.response?.data['message'] ?? 'Terjadi kesalahan')
          : 'Terjadi kesalahan';
      return DioException(
        requestOptions: error.requestOptions,
        response: error.response,
        type: error.type,
        error: '[$status] $message',
      );
    }

    return error;
  }

  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    return _dio.get<T>(
      path,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
    );
  }

  Future<Response<T>> post<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    return _dio.post<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
    );
  }

  Future<Response<T>> put<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    return _dio.put<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
    );
  }

  Future<Response<T>> delete<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    return _dio.delete<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
    );
  }

  void updateToken(String token) {
    _dio.options.headers['Authorization'] = 'Bearer $token';
  }

  void clearToken() {
    _dio.options.headers.remove('Authorization');
  }

  // Download image as bytes (for Image.memory) - with aggressive retry
  Future<List<int>> downloadImage(String imageUrl) async {
    const maxRetries = 5; // Increased from 3 to 5

    for (int attempt = 0; attempt < maxRetries; attempt++) {
      try {
        // Exponential backoff: 0s, 2s, 4s, 6s, 8s
        if (attempt > 0) {
          final delaySeconds = attempt * 2;
          await Future.delayed(Duration(seconds: delaySeconds));
          print(
            'Image retry attempt ${attempt + 1} (waiting ${delaySeconds}s)...',
          );
        }

        // Create a separate Dio instance without baseUrl for image download
        final imageDio = Dio(
          BaseOptions(
            connectTimeout: const Duration(seconds: 60),
            receiveTimeout: const Duration(seconds: 300), // 5 minutes
            sendTimeout: const Duration(seconds: 30),
            headers: {
              'Accept': 'image/*,*/*',
              'User-Agent': 'Flutter App',
              'Connection': 'keep-alive',
            },
          ), // BaseOptions
        ); // Dio

        // No logger, no interceptors - just raw download
        final response = await imageDio.get<List<int>>(
          imageUrl,
          options: Options(responseType: ResponseType.bytes),
        );

        if (response.statusCode == 200) {
          print(
            '✔️ Image OK on attempt ${attempt + 1}: $imageUrl (${response.data?.length ?? 0} bytes)',
          );
          return response.data ?? [];
        } else {
          throw Exception('HTTP ${response.statusCode}');
        }
      } catch (e) {
        print('❌ Attempt ${attempt + 1} failed: $e');
        if (attempt == maxRetries - 1) {
          print(
            '⚠️ All $maxRetries attempts failed, falling back to Image.network()',
          );
          throw Exception('Gagal memuat gambar: $e');
        }
      }
    }

    throw Exception('Gagal memuat gambar');
  }
}