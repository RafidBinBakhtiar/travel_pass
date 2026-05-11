import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:travel_pass/core/constants/app_colors.dart';
import 'package:travel_pass/core/constants/app_fonts.dart';
import 'package:travel_pass/features/payment/data/payment_repository.dart';
import 'package:travel_pass/features/permit/data/permit_models.dart';
import 'package:travel_pass/features/permit/provider/permit_provider.dart';
import 'package:travel_pass/features/payment/screens/payment_success_screen.dart';
import 'package:url_launcher/url_launcher.dart';

class FeePaymentScreen extends ConsumerStatefulWidget {
  final PermitApplication application;
  final double feeAmount;
  final int paymentId;

  const FeePaymentScreen({
    super.key,
    required this.application,
    required this.feeAmount,
    required this.paymentId,
  });

  @override
  ConsumerState<FeePaymentScreen> createState() => _FeePaymentScreenState();
}

class _FeePaymentScreenState extends ConsumerState<FeePaymentScreen> {
  final PaymentRepository _paymentRepository = PaymentRepository();
  final AppLinks _appLinks = AppLinks();
  bool _isProcessing = false;
  bool _isVerifyingCallback = false;
  StreamSubscription<Uri>? _deepLinkSubscription;

  @override
  void initState() {
    super.initState();
    _startListeningForPaymentCallback();
  }

  @override
  void dispose() {
    _deepLinkSubscription?.cancel();
    super.dispose();
  }

  Future<void> _startListeningForPaymentCallback() async {
    try {
      _deepLinkSubscription = _appLinks.uriLinkStream.listen((uri) {
        _handleCallbackUri(uri);
      });
    } catch (_) {
      // Silent fail: user can retry payment manually.
    }
  }

  Future<void> _initiatePayment() async {
    setState(() => _isProcessing = true);

    try {
      final successUrl = 'travelpass://payment/success?paymentId=${widget.paymentId}';
      final failUrl = 'travelpass://payment/fail?paymentId=${widget.paymentId}';

      final paymentUrl = _paymentRepository.getShurjopayUrl(
        paymentId: widget.paymentId,
        successUrl: successUrl,
        failUrl: failUrl,
      );

      final launched = await launchUrl(
        Uri.parse(paymentUrl),
        mode: LaunchMode.externalApplication,
      );

      if (!launched && mounted) {
        throw Exception('পেমেন্ট পেইজ খোলা যাচ্ছে না।');
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('ব্রাউজারে পেমেন্ট সম্পন্ন করুন, সফল হলে অ্যাপে ফিরে আসবে।'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  void _onPaymentSuccess() {
    ref.read(applicationsProvider.notifier).loadApplications();
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => PaymentSuccessScreen(
          applicationId: widget.application.displayId,
          feeAmount: widget.feeAmount.toStringAsFixed(0),
          touristName: widget.application.touristName,
        ),
      ),
    );
  }

  void _onPaymentFail() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Payment failed. Please try again.')),
    );
  }

  Future<void> _handleCallbackUri(Uri uri) async {
    final scheme = uri.scheme.toLowerCase();
    if (scheme != 'travelpass' && scheme != 'travel-pass') return;
    if (uri.host.toLowerCase() != 'payment') return;

    final path = uri.path.toLowerCase();
    if (path.contains('fail')) {
      _onPaymentFail();
      return;
    }

    if (!path.contains('success')) return;
    final orderId = uri.queryParameters['order_id'] ?? uri.queryParameters['orderId'];
    if (orderId == null || orderId.isEmpty) {
      _onPaymentFail();
      return;
    }
    await _verifyPaymentCallback(orderId);
  }

  Future<void> _verifyPaymentCallback(String orderId) async {
    if (_isVerifyingCallback) return;
    setState(() => _isVerifyingCallback = true);
    try {
      final response = await _paymentRepository.verifyShurjopayCallback(
        orderId: orderId,
      );
      if (response['success'] == true) {
        _onPaymentSuccess();
      } else {
        _onPaymentFail();
      }
    } catch (_) {
      _onPaymentFail();
    } finally {
      if (mounted) {
        setState(() => _isVerifyingCallback = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).languageCode;
    final font = AppFonts.forLocale(locale);

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        automaticallyImplyLeading: true,
        centerTitle: true,
        title: Text(
          'ট্রাভেল পারমিট আবেদনফর্ম',
          style: TextStyle(
            fontFamily: font,
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: AppColors.textDark,
          ),
        ),
      ),
      body: Column(
        children: [
          // ── Progress Indicator ──
          Container(
            color: AppColors.white,
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
            child: Row(
              children: [
                _buildProgressStep(font, 1, 'আবেদনফর্ম', true),
                _buildProgressConnector(true),
                _buildProgressStep(font, 2, 'নথিপত্র আপলোড', true),
                _buildProgressConnector(true),
                _buildProgressStep(font, 3, 'ফি প্রদান', false),
              ],
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Payment Summary Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.borderGrey),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.02),
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'আবেদন ফি প্রদান করুন',
                          style: TextStyle(
                            fontFamily: font,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textDark,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'আপনার ভ্রমণ পারমিটটি নিশ্চিত করতে নির্ধারিত ফি পরিশোধ করুন।',
                          style: TextStyle(
                            fontFamily: font,
                            fontSize: 14,
                            color: AppColors.textGrey,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'আবেদনের আইডি: ${widget.application.displayId}',
                          style: TextStyle(
                            fontFamily: font,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textDark,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'ফি-র পরিমাণ: ${widget.feeAmount.toStringAsFixed(0)} টাকা',
                          style: TextStyle(
                            fontFamily: font,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textDark,
                          ),
                        ),
                        const SizedBox(height: 32),
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton(
                            onPressed: _isProcessing ? null : _initiatePayment,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryGreen,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: (_isProcessing || _isVerifyingCallback)
                                ? const CircularProgressIndicator(color: Colors.white)
                                : Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        'ফি প্রদান করুন',
                                        style: TextStyle(
                                          fontFamily: font,
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      const Icon(LucideIcons.arrowRight, size: 18),
                                    ],
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String font, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontFamily: font,
              fontSize: 14,
              color: AppColors.textGrey,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontFamily: font,
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textDark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressStep(String font, int step, String label, bool isCompleted) {
    return Expanded(
      child: Column(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isCompleted
                  ? AppColors.primaryGreen
                  : const Color(0xFFF3F4F6),
              border: Border.all(
                color: isCompleted ? AppColors.primaryGreen : AppColors.borderGrey,
                width: 2,
              ),
            ),
            child: Center(
              child: isCompleted
                  ? const Icon(LucideIcons.check, color: Colors.white, size: 14)
                  : Text(
                      step.toString(),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: font,
              fontSize: 11,
              color: isCompleted ? AppColors.primaryGreen : AppColors.textGrey,
              fontWeight: isCompleted ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressConnector(bool isCompleted) {
    return Expanded(
      child: Container(
        height: 2,
        color: isCompleted ? AppColors.primaryGreen : AppColors.borderGrey,
      ),
    );
  }

}
