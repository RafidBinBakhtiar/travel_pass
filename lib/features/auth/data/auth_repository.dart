import 'package:dio/dio.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/network/token_storage.dart';
import 'auth_models.dart';

class AuthRepository {
  final Dio _dio = DioClient.createDio();

  // Step 1 — login, returns LoginResult (needs OTP or has tokens)
  Future<LoginResult> login(LoginRequest request) async {
    try {
      final response = await _dio.post('/auth/login', data: request.toJson());
      print('✅ LOGIN: ${response.data}');

      if (response.data['success'] != true) {
        throw Exception(response.data['message'] ?? 'Login failed');
      }

      final data = response.data['data'] as Map<String, dynamic>;

      if (data.containsKey('accessToken')) {
        // Fully Verified Account (No OTP Needed)
        await TokenStorage.saveTokens(
          accessToken: data['accessToken'],
          refreshToken: data['refreshToken'],
        );
        return LoginHasTokens(
          accessToken: data['accessToken'],
          refreshToken: data['refreshToken'],
        );
      }

      // Otherwise → phone not verified, needs OTP
      return LoginNeedsOtp(request.emailOrPhone);
    } on DioException catch (e) {
      print('❌ LOGIN ERROR: ${e.response?.statusCode} ${e.response?.data}');
      final msg = e.response?.data?['message'] as String?;
      throw Exception(msg ?? 'Login failed');
    }
  }

  // Step 2 — verify OTP, get tokens, fetch users
  Future<Map<String, dynamic>> verifyLogin(VerifyLoginRequest request) async {
    try {
      final response = await _dio.post(
        '/auth/verify-login',
        data: request.toJson(),
      );
      print('✅ VERIFY: ${response.data}');

      if (response.data['success'] != true) {
        throw Exception(response.data['message'] ?? 'OTP verification failed');
      }

      final data = response.data['data'] as Map<String, dynamic>;
      await _saveAuthTokens(data);

      return data;
    } on DioException catch (e) {
      print('❌ VERIFY ERROR: ${e.response?.statusCode} ${e.response?.data}');
      final msg = e.response?.data?['message'] as String?;
      throw Exception(msg ?? 'OTP verification failed');
    }
  }

  Future<void> verifyRegistrationOtp(String emailOrPhone, String otp) async {
    try {
      final response = await _dio.post(
        '/auth/verify-login',
        data: {'emailOrPhone': emailOrPhone, 'otp': otp},
      );
      print('✅ REGISTRATION OTP: ${response.data}');

      if (response.data['success'] != true) {
        throw Exception(response.data['message'] ?? 'OTP verification failed');
      }

      final data = response.data['data'] as Map<String, dynamic>;
      await _saveAuthTokens(data);
    } on DioException catch (e) {
      print('❌ REGISTRATION OTP ERROR: ${e.response?.data}');
      final msg = e.response?.data?['message'] as String?;
      throw Exception(msg ?? 'OTP verification failed');
    }
  }

  Future<void> _saveAuthTokens(Map<String, dynamic> data) async {
    final accessToken = data['accessToken'] as String?;
    final refreshToken = data['refreshToken'] as String?;

    if (accessToken == null ||
        accessToken.isEmpty ||
        refreshToken == null ||
        refreshToken.isEmpty) {
      throw Exception('Authentication tokens missing from server response');
    }

    await TokenStorage.saveTokens(
      accessToken: accessToken,
      refreshToken: refreshToken,
    );
  }

  // Add this method to AuthRepository
  Future<Map<String, dynamic>> fetchUsers() async {
    try {
      final response = await _dio.get(
        '/users',
        queryParameters: {'page': 1, 'limit': 10},
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      final msg = e.response?.data?['message'] as String?;
      throw Exception(msg ?? 'Failed to fetch users');
    }
  }

  Future<RegisterResult> register(RegisterRequest request) async {
    try {
      final response = await _dio.post(
        '/auth/register',
        data: request.toJson(),
      );
      print('✅ REGISTER: ${response.data}');

      if (response.data['success'] != true) {
        throw Exception(response.data['message'] ?? 'Registration failed');
      }

      if (request.phone.isNotEmpty) {
        return RegisterNeedsPhoneOtp(request.phone);
      }
      if (request.email.isNotEmpty) {
        return RegisterNeedsEmailOtp(request.email);
      }

      throw Exception('Phone or email is required for registration');
    } on DioException catch (e) {
      print('❌ REGISTER ERROR: ${e.response?.statusCode} ${e.response?.data}');
      final msg = e.response?.data?['message'] as String?;
      throw Exception(msg ?? 'Registration failed');
    }
  }

  Future<void> verifyPhoneOtp(String emailOrPhone, String otp) async {
    try {
      final response = await _dio.post(
        '/auth/verify-login',
        data: {'emailOrPhone': emailOrPhone, 'otp': otp},
      );
      print('✅ PHONE OTP: ${response.data}');

      if (response.data['success'] != true) {
        throw Exception(response.data['message'] ?? 'OTP verification failed');
      }
    } on DioException catch (e) {
      print('❌ PHONE OTP ERROR: ${e.response?.data}');
      final msg = e.response?.data?['message'] as String?;
      throw Exception(msg ?? 'OTP verification failed');
    }
  }

  Future<void> resendOtp(String emailOrPhone) async {
    try {
      await _dio.post('/auth/resend-otp', data: {'emailOrPhone': emailOrPhone});
    } on DioException catch (e) {
      final msg = e.response?.data?['message'] as String?;
      throw Exception(msg ?? 'Failed to resend OTP');
    }
  }

  // Forgot Password methods
  Future<void> forgotPassword(ForgotPasswordRequest request) async {
    try {
      final response = await _dio.post(
        '/auth/forgot-password',
        data: request.toJson(),
      );
      print('✅ FORGOT PASSWORD: ${response.data}');

      if (response.data['success'] != true) {
        throw Exception(response.data['message'] ?? 'Forgot password failed');
      }
    } on DioException catch (e) {
      print(
        '❌ FORGOT PASSWORD ERROR: ${e.response?.statusCode} ${e.response?.data}',
      );
      final msg = e.response?.data?['message'] as String?;
      throw Exception(msg ?? 'Forgot password failed');
    }
  }

  Future<Map<String, dynamic>> verifyForgotPasswordOtp(
    VerifyForgotPasswordOtpRequest request,
  ) async {
    try {
      final response = await _dio.post(
        '/auth/verify-forgot-password-otp',
        data: request.toJson(),
      );
      print('✅ VERIFY FORGOT PASSWORD OTP: ${response.data}');

      if (response.data['success'] != true) {
        throw Exception(response.data['message'] ?? 'OTP verification failed');
      }

      return response.data['data'] as Map<String, dynamic>;
    } on DioException catch (e) {
      print(
        '❌ VERIFY FORGOT PASSWORD OTP ERROR: ${e.response?.statusCode} ${e.response?.data}',
      );
      final msg = e.response?.data?['message'] as String?;
      throw Exception(msg ?? 'OTP verification failed');
    }
  }

  Future<void> resetPassword(ResetPasswordRequest request) async {
    try {
      final response = await _dio.post(
        '/auth/reset-password',
        data: request.toJson(),
      );
      print('✅ RESET PASSWORD: ${response.data}');

      if (response.data['success'] != true) {
        throw Exception(response.data['message'] ?? 'Password reset failed');
      }
    } on DioException catch (e) {
      print(
        '❌ RESET PASSWORD ERROR: ${e.response?.statusCode} ${e.response?.data}',
      );
      final msg = e.response?.data?['message'] as String?;
      throw Exception(msg ?? 'Password reset failed');
    }
  }
}
