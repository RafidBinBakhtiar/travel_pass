import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:travel_pass/core/constants/app_colors.dart';
import 'package:travel_pass/core/constants/app_fonts.dart';
import 'package:travel_pass/features/permit/data/permit_models.dart';
import 'package:travel_pass/features/permit/provider/permit_provider.dart';
import 'package:webview_flutter/webview_flutter.dart';

class PaymentWebViewScreen extends ConsumerStatefulWidget {
  final String paymentUrl;
  final PermitApplication application;

  const PaymentWebViewScreen({
    super.key,
    required this.paymentUrl,
    required this.application,
  });

  @override
  ConsumerState<PaymentWebViewScreen> createState() =>
      _PaymentWebViewScreenState();
}

class _PaymentWebViewScreenState extends ConsumerState<PaymentWebViewScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;

  static const _successScheme = 'travelpass://payment/success';
  static const _failScheme = 'travelpass://payment/fail';

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (p) => setState(() => _isLoading = p < 100),
          onPageStarted: (_) => setState(() => _isLoading = true),
          onPageFinished: (_) => setState(() => _isLoading = false),
          onNavigationRequest: (NavigationRequest req) {
            final url = req.url;
            if (url.startsWith(_successScheme) ||
                url.contains('payment/success')) {
              _onPaymentSuccess();
              return NavigationDecision.prevent;
            }
            if (url.startsWith(_failScheme) ||
                url.contains('payment/fail') ||
                url.contains('payment/cancel')) {
              _onPaymentFailed();
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.paymentUrl));
  }

  void _onPaymentSuccess() {
    // Refresh the applications list
    ref.read(applicationsProvider.notifier).loadApplications();
    // Navigate to success page, replacing the WebView
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => PaymentSuccessScreen(application: widget.application),
      ),
    );
  }

  void _onPaymentFailed() {
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'পেমেন্ট ব্যর্থ হয়েছে। পুনরায় চেষ্টা করুন।',
          style: const TextStyle(fontFamily: AppFonts.bengali),
        ),
        backgroundColor: AppColors.errorRed,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.close, color: AppColors.textDark),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'পেমেন্ট',
          style: TextStyle(
            fontFamily: AppFonts.bengali,
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.textDark,
          ),
        ),
        centerTitle: true,
        bottom: _isLoading
            ? PreferredSize(
                preferredSize: const Size.fromHeight(3),
                child: LinearProgressIndicator(
                  valueColor:
                      const AlwaysStoppedAnimation(AppColors.primaryGreen),
                  backgroundColor:
                      AppColors.primaryGreen.withValues(alpha: 0.2),
                ),
              )
            : null,
      ),
      body: WebViewWidget(controller: _controller),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Payment Success Screen
// ─────────────────────────────────────────────────────────────────────────────

class PaymentSuccessScreen extends StatelessWidget {
  final PermitApplication application;

  const PaymentSuccessScreen({super.key, required this.application});

  @override
  Widget build(BuildContext context) {
    const font = AppFonts.bengali;
    final appId = application.displayId;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: _buildAppBar(context),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 540),
            child: Column(
              children: [
                // Step Indicator (all 3 done)
                _buildStepIndicator(font),
                const SizedBox(height: 28),

                // Success Card
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Section header
                      Text(
                        'ফি প্রদান',
                        style: TextStyle(
                          fontFamily: font,
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textDark,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Success banner
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFE5E7EB)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Title row
                            Row(
                              children: [
                                Container(
                                  width: 28,
                                  height: 28,
                                  decoration: const BoxDecoration(
                                    color: AppColors.primaryGreen,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.check,
                                      color: Colors.white, size: 16),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    'অভিনন্দন রহিম! আপনার ফি প্রদান সফল হয়েছে!',
                                    style: TextStyle(
                                      fontFamily: font,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textDark,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),

                            // Description
                            Text(
                              'আপনার আবেদনের ফি সঠিকভাবে জমা দেওয়া হয়েছে। '
                              'এখন কর্তৃপক্ষ আপনার তথ্যগুলো যাচাই করবেন। '
                              'অনুমোদন সম্পন্ন হলে আপনার মোবাইলে একটি '
                              'এসএমএস (SMS) পাঠানো হবে।',
                              style: TextStyle(
                                fontFamily: font,
                                fontSize: 13,
                                color: AppColors.textGrey,
                                height: 1.6,
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Application ID
                            RichText(
                              text: TextSpan(
                                children: [
                                  TextSpan(
                                    text: 'আবেদনের আইডি: ',
                                    style: TextStyle(
                                      fontFamily: font,
                                      fontSize: 13,
                                      color: AppColors.textDark,
                                    ),
                                  ),
                                  TextSpan(
                                    text: appId,
                                    style: const TextStyle(
                                      fontFamily: AppFonts.english,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textDark,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 4),

                            // Fee amount
                            RichText(
                              text: TextSpan(
                                children: [
                                  TextSpan(
                                    text: 'ফি-র পরিমাণ: ',
                                    style: TextStyle(
                                      fontFamily: font,
                                      fontSize: 13,
                                      color: AppColors.textDark,
                                    ),
                                  ),
                                  TextSpan(
                                    text: '৫০০ টাকা',
                                    style: TextStyle(
                                      fontFamily: font,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textDark,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Dashboard button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            // Pop all the way back to HomeScreen
                            Navigator.of(context)
                                .popUntil((route) => route.isFirst);
                            Navigator.of(context)
                                .pushReplacementNamed('/home');
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryGreen,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8)),
                          ),
                          child: Text(
                            'ড্যাশবোর্ডে যান',
                            style: TextStyle(
                              fontFamily: font,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
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
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new,
            color: AppColors.textDark, size: 20),
        onPressed: () => Navigator.of(context).pop(),
      ),
      centerTitle: true,
      title: Column(
        children: [
          Text(
            'ট্রাভেল পারমিট আবেদনফর্ম',
            style: TextStyle(
              fontFamily: AppFonts.bengali,
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepIndicator(String font) {
    final steps = ['আবেদনফর্ম', 'নথিপত্র আপলোড', 'ফি প্রদান'];
    return Row(
      children: List.generate(steps.length * 2 - 1, (i) {
        if (i.isOdd) {
          return Expanded(
            child: Container(
              height: 2,
              color: AppColors.primaryGreen,
            ),
          );
        }
        final stepIndex = i ~/ 2;
        return Column(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primaryGreen,
              ),
              child:
                  const Center(child: Icon(Icons.check, color: Colors.white, size: 16)),
            ),
            const SizedBox(height: 6),
            Text(
              steps[stepIndex],
              style: TextStyle(
                fontFamily: font,
                fontSize: 11,
                color: AppColors.primaryGreen,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        );
      }),
    );
  }
}
