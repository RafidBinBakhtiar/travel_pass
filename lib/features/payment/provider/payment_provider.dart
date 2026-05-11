import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/payment_repository.dart';

// ── Repository provider ──────────────────────────────────────────
final paymentRepositoryProvider =
    Provider<PaymentRepository>((_) => PaymentRepository());

// ── Selected gateway state ───────────────────────────────────────
final selectedGatewayProvider =
    StateProvider<PaymentGateway>((ref) => PaymentGateway.shurjopay);

// ── Payment initiation state ─────────────────────────────────────
sealed class PaymentInitState {}

class PaymentInitIdle extends PaymentInitState {}

class PaymentInitLoading extends PaymentInitState {}

class PaymentInitReady extends PaymentInitState {
  final String url;
  PaymentInitReady({required this.url});
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
    PaymentGateway gateway = PaymentGateway.shurjopay,
  }) {
    const successUrl = 'travelpass://payment/success';
    const failUrl = 'travelpass://payment/fail';
    final url = _repo.getShurjopayUrl(
      paymentId: applicationId,
      successUrl: successUrl,
      failUrl: failUrl,
    );
    state = PaymentInitReady(url: url);
  }

  void reset() => state = PaymentInitIdle();
}

final paymentInitProvider =
    StateNotifierProvider<PaymentInitNotifier, PaymentInitState>((ref) {
  return PaymentInitNotifier(ref.read(paymentRepositoryProvider));
});
