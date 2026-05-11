import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';
import 'app_logger.dart';
import 'token_storage.dart';

class DioClient {
  static const baseUrl = 'https://travel-pass-backend.onrender.com/api';

  static Dio createDio() {
    final dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: {'Content-Type': 'application/json'},
    ));

    dio.interceptors.add(_AuthInterceptor(dio));

    if (kDebugMode) {
      dio.interceptors.add(
        PrettyDioLogger(
          requestHeader: true,
          requestBody: true,
          responseHeader: false,
          responseBody: true,
          error: true,
          compact: true,
          maxWidth: 120,
          filter: (options, args) => options.data is! FormData,
        ),
      );
    }

    return dio;
  }
}

class _AuthInterceptor extends Interceptor {
  final Dio _dio;
  _AuthInterceptor(this._dio);

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await TokenStorage.getAccessToken();
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (err.response?.statusCode == 401) {
      AppLogger.w('401 received on ${err.requestOptions.uri} — refreshing token');
      try {
        final refreshToken = await TokenStorage.getRefreshToken();
        if (refreshToken == null) {
          AppLogger.w('No refresh token available — passing error through');
          return handler.next(err);
        }

        final refreshDio = Dio(BaseOptions(baseUrl: DioClient.baseUrl));
        final response = await refreshDio.post(
          '/auth/refresh',
          data: {'refreshToken': refreshToken},
        );

        final newAccess = response.data['accessToken'];
        final newRefresh = response.data['refreshToken'];

        await TokenStorage.saveTokens(
          accessToken: newAccess,
          refreshToken: newRefresh,
        );
        AppLogger.i('Token refreshed — retrying original request');

        err.requestOptions.headers['Authorization'] = 'Bearer $newAccess';
        final retried = await _dio.fetch(err.requestOptions);
        return handler.resolve(retried);
      } catch (e, st) {
        AppLogger.e('Token refresh failed — clearing tokens', e, st);
        await TokenStorage.clearTokens();
        handler.next(err);
      }
    } else {
      handler.next(err);
    }
  }
}
