import 'package:dio/dio.dart';
import '../../../core/network/dio_client.dart';

enum PaymentGateway { shurjopay }

class PaymentRepository {
  final Dio _dio = DioClient.createDio();

  static const _baseUrl = DioClient.baseUrl;

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

  /// Verifies ShurjoPay callback with `order_id`.
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
