import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/payment_repository.dart';

// ── Repository provider ──────────────────────────────────────────
final paymentRepositoryProvider =
    Provider<PaymentRepository>((_) => PaymentRepository());

// ── Selected gateway state ───────────────────────────────────────
final selectedGatewayProvider =
    StateProvider<PaymentGateway?>((ref) => null);

// ── Payment initiation state ─────────────────────────────────────
sealed class PaymentInitState {}

class PaymentInitIdle extends PaymentInitState {}

class PaymentInitLoading extends PaymentInitState {}

class PaymentInitReady extends PaymentInitState {
  final String url;
  final PaymentGateway gateway;
  PaymentInitReady({required this.url, required this.gateway});
}

class PaymentInitError extends PaymentInitState {
  final String message;
  PaymentInitError(this.message);
}

// ── Notifier ─────────────────────────────────────────────────────
class PaymentInitNotifier extends StateNotifier<PaymentInitState> {
  final PaymentRepository _repo;
  PaymentInitNotifier(this._repo) : super(PaymentInitIdle());

  /// Build the gateway URL and emit PaymentInitReady.
  void initiatePayment({
    required int applicationId,
    required PaymentGateway gateway,
  }) {
    // Deep-link / scheme that the WebView will intercept to detect success/fail
    const successUrl = 'travelpass://payment/success';
    const failUrl = 'travelpass://payment/fail';

    final String url;
    if (gateway == PaymentGateway.bkash) {
      url = _repo.getBkashPayUrl(
        paymentId: applicationId,
        successUrl: successUrl,
        failUrl: failUrl,
      );
    } else {
      url = _repo.getShurjopayUrl(
        paymentId: applicationId,
        successUrl: successUrl,
        failUrl: failUrl,
      );
    }

    state = PaymentInitReady(url: url, gateway: gateway);
  }

  void reset() => state = PaymentInitIdle();
}

final paymentInitProvider =
    StateNotifierProvider<PaymentInitNotifier, PaymentInitState>((ref) {
  return PaymentInitNotifier(ref.read(paymentRepositoryProvider));
});
