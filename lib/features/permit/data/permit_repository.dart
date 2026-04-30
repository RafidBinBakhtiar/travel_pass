import 'package:dio/dio.dart';
import '../../../core/network/dio_client.dart';
import 'permit_models.dart';

class PermitRepository {
  final Dio _dio = DioClient.createDio();

  /// GET /applications — fetch all applications
  Future<List<PermitApplication>> getApplications() async {
    try {
      final response = await _dio.get('/applications');
      if (response.data['success'] != true) {
        throw Exception(
          response.data['message'] ?? 'Failed to fetch applications',
        );
      }
      final raw = response.data['data'];
      final list = raw is List
          ? raw
          : ((raw['items'] ?? raw['data'] ?? []) as List<dynamic>);
      return list
          .map((e) => PermitApplication.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      final msg = e.response?.data?['message'] as String?;
      throw Exception(msg ?? 'Failed to fetch applications');
    }
  }

  /// POST /applications — create a new application
  Future<PermitApplication> createApplication(
    CreateApplicationRequest req,
  ) async {
    try {
      final response = await _dio.post('/applications', data: req.toJson());
      if (response.data['success'] != true) {
        throw Exception(
          response.data['message'] ?? 'Failed to create application',
        );
      }
      return PermitApplication.fromJson(
        response.data['data'] as Map<String, dynamic>,
      );
    } on DioException catch (e) {
      final msg = e.response?.data?['message'] as String?;
      throw Exception(msg ?? 'Failed to create application');
    }
  }

  /// GET /applications/:id — fetch a single application
  Future<PermitApplication> getApplication(int id) async {
    try {
      final response = await _dio.get('/applications/$id');
      if (response.data['success'] != true) {
        throw Exception(
          response.data['message'] ?? 'Failed to fetch application',
        );
      }
      return PermitApplication.fromJson(
        response.data['data'] as Map<String, dynamic>,
      );
    } on DioException catch (e) {
      final msg = e.response?.data?['message'] as String?;
      throw Exception(msg ?? 'Failed to fetch application');
    }
  }

  /// PATCH /applications/:id — update an application
  Future<PermitApplication> updateApplication(
    int id,
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await _dio.patch('/applications/$id', data: data);
      if (response.data['success'] != true) {
        throw Exception(
          response.data['message'] ?? 'Failed to update application',
        );
      }
      return PermitApplication.fromJson(
        response.data['data'] as Map<String, dynamic>,
      );
    } on DioException catch (e) {
      final msg = e.response?.data?['message'] as String?;
      throw Exception(msg ?? 'Failed to update application');
    }
  }

  /// GET /applications/:id/permit_certificate — fetch permit certificate
  Future<Map<String, dynamic>> getPermitCertificate(int id) async {
    try {
      final response = await _dio.get('/applications/$id/permit_certificate');
      if (response.data['success'] != true) {
        throw Exception(
          response.data['message'] ?? 'Failed to fetch certificate',
        );
      }
      return response.data['data'] as Map<String, dynamic>;
    } on DioException catch (e) {
      final msg = e.response?.data?['message'] as String?;
      throw Exception(msg ?? 'Failed to fetch certificate');
    }
  }
}
