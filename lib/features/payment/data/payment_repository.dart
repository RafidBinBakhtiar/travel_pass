import 'package:dio/dio.dart';
import '../../../core/network/dio_client.dart';

enum PaymentGateway { bkash, shurjopay }

class PaymentRepository {
  final Dio _dio = DioClient.createDio();

  static const _baseUrl = DioClient.baseUrl;

  /// Returns the full URL to open for bKash payment.
  /// GET /payments/bkash/pay?paymentId={id}&successUrl=...&failUrl=...
  String getBkashPayUrl({
    required int paymentId,
    required String successUrl,
    required String failUrl,
  }) {
    return '$_baseUrl/payments/bkash/pay'
        '?paymentId=$paymentId'
        '&successUrl=${Uri.encodeComponent(successUrl)}'
        '&failUrl=${Uri.encodeComponent(failUrl)}';
  }

  /// Returns the full URL to open for ShurjoPay payment.
  /// GET /payments/shurjopay/pay?paymentId={id}&successUrl=...&failUrl=...
  String getShurjopayUrl({
    required int paymentId,
    required String successUrl,
    required String failUrl,
  }) {
    return '$_baseUrl/payments/shurjopay/pay'
        '?paymentId=$paymentId'
        '&successUrl=${Uri.encodeComponent(successUrl)}'
        '&failUrl=${Uri.encodeComponent(failUrl)}';
  }

  /// Verify a bKash callback manually (optional, used if WebView intercepts).
  Future<Map<String, dynamic>> verifyBkashCallback({
    required String status,
    required String paymentID,
  }) async {
    try {
      final response = await _dio.get(
        '/payments/bkash/callback',
        queryParameters: {'status': status, 'paymentID': paymentID},
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      final msg = e.response?.data?['message'] as String?;
      throw Exception(msg ?? 'Payment verification failed');
    }
  }

  /// Verify a ShurjoPay callback manually (optional, used if WebView intercepts).
  Future<Map<String, dynamic>> verifyShurjopayCallback({
    required String orderId,
  }) async {
    try {
      final response = await _dio.get(
        '/payments/shurjopay/callback',
        queryParameters: {'order_id': orderId},
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      final msg = e.response?.data?['message'] as String?;
      throw Exception(msg ?? 'Payment verification failed');
    }
  }
}
