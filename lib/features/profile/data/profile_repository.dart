import 'package:dio/dio.dart';
import '../../../core/network/dio_client.dart';
import 'profile_models.dart';

class ProfileRepository {
  final Dio _dio = DioClient.createDio();

  /// GET /auth/me — fetch the current user's profile
  Future<UserProfile> getProfile() async {
    try {
      final response = await _dio.get('/auth/me');
      print('✅ GET PROFILE: ${response.data}');

      if (response.data['success'] != true) {
        throw Exception(response.data['message'] ?? 'Failed to fetch profile');
      }

      final data = response.data['data'] as Map<String, dynamic>;
      return UserProfile.fromJson(data);
    } on DioException catch (e) {
      print(
        '❌ GET PROFILE ERROR: ${e.response?.statusCode} ${e.response?.data}',
      );
      final msg = e.response?.data?['message'] as String?;
      throw Exception(msg ?? 'Failed to fetch profile');
    }
  }

  /// PUT /auth/me — update the current user's profile
  Future<UserProfile> updateProfile(UpdateProfileRequest request) async {
    try {
      final response = await _dio.put('/auth/me', data: request.toJson());
      print('✅ UPDATE PROFILE: ${response.data}');

      if (response.data['success'] != true) {
        throw Exception(response.data['message'] ?? 'Failed to update profile');
      }

      final data = response.data['data'] as Map<String, dynamic>;
      return UserProfile.fromJson(data);
    } on DioException catch (e) {
      print(
        '❌ UPDATE PROFILE ERROR: ${e.response?.statusCode} ${e.response?.data}',
      );
      final msg = e.response?.data?['message'] as String?;
      throw Exception(msg ?? 'Failed to update profile');
    }
  }

  /// POST /auth/change-password — change current user's password
  Future<void> changePassword(ChangePasswordRequest request) async {
    try {
      final response = await _dio.post(
        '/auth/change-password',
        data: request.toJson(),
      );
      print('✅ CHANGE PASSWORD: ${response.data}');

      if (response.data['success'] != true) {
        throw Exception(
          response.data['message'] ?? 'Failed to change password',
        );
      }
    } on DioException catch (e) {
      print(
        '❌ CHANGE PASSWORD ERROR: ${e.response?.statusCode} ${e.response?.data}',
      );
      final msg = e.response?.data?['message'] as String?;
      throw Exception(msg ?? 'Failed to change password');
    }
  }
}
