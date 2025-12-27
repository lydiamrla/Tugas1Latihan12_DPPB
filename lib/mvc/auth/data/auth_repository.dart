import 'package:dio/dio.dart';
import '../../../core/dio_client.dart';  // ← PERBAIKI INI! (naik 3 level)
import 'user_model.dart';

class AuthRepository {
  final DioClient _client;
  AuthRepository(this._client);

  // Fungsi Register
  Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
    required String passwordConfirmation,
  }) async {
    final response = await _client.post(
      '/register',
      data: {
        'name': name,
        'email': email,
        'password': password,
        'password_confirmation': passwordConfirmation,
      },
    );

    final data = response.data ?? {};
    return {
      'user': UserModel.fromJson(data['user'] as Map<String, dynamic>),
      'token': data['access_token'] as String,
      'message': data['message'] as String? ?? 'Registration successful',
    };
  }

  // Fungsi Login dengan penanganan error spesifik
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _client.post(
        '/login',
        data: {'email': email, 'password': password},
      );

      final data = response.data ?? {};
      return {
        'user': UserModel.fromJson(data['user'] as Map<String, dynamic>),
        'token': data['access_token'] as String,
        'message': data['message'] as String? ?? 'Login berhasil',
      };
    } on DioException catch (e) {
      // Penanganan error koneksi & validasi
      if (e.type != DioExceptionType.badResponse) {
        throw Exception('Cek koneksi internet anda');
      }

      final status = e.response?.statusCode;
      final msg = e.response?.data is Map ? e.response?.data['message'] : null;

      if (status == 401 || (msg is String && msg.toLowerCase().contains('invalid'))) {
        throw Exception('Email atau password salah');
      }
      if (status == 422) {
        throw Exception('Input tidak valid. Periksa email dan password.');
      }
      throw Exception(msg ?? 'Gagal login. Coba lagi.');
    }
  }

  // Fungsi Logout dan Get Profile
  Future<String> logout() async {
    final response = await _client.post('/logout');
    final data = response.data ?? {};
    return data['message'] as String? ?? 'Logout successful';
  }

  Future<UserModel> getProfile() async {
    final response = await _client.get('/me');
    final data = response.data ?? {};
    return UserModel.fromJson(data['user'] as Map<String, dynamic>);
  }
}