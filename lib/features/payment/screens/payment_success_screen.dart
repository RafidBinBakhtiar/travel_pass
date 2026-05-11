import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:travel_pass/core/constants/app_colors.dart';
import 'package:travel_pass/core/constants/app_fonts.dart';

class PaymentSuccessScreen extends StatelessWidget {
  final String applicationId;
  final String feeAmount;
  final String touristName;

  const PaymentSuccessScreen({
    super.key,
    required this.applicationId,
    required this.feeAmount,
    required this.touristName,
  });

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
        automaticallyImplyLeading: false,
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
                _buildProgressStep(font, 3, 'ফি প্রদান', true),
              ],
            ),
          ),
          
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.02),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                  border: Border.all(color: AppColors.borderGrey),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          LucideIcons.checkCircle2,
                          color: AppColors.primaryGreen,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'অভিনন্দন $touristName! আপনার ফি প্রদান সফল হয়েছে!',
                            style: TextStyle(
                              fontFamily: font,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textDark,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'আপনার আবেদনের ফি সঠিকভাবে জমা নেওয়া হয়েছে। এখন কর্তৃপক্ষ আপনার তথ্যগুলো যাচাই করবেন। অনুমোদন সম্পন্ন হলে আপনার মোবাইলে একটি এসএমএস (SMS) পাঠানো হবে।',
                      style: TextStyle(
                        fontFamily: font,
                        fontSize: 14,
                        color: AppColors.textGrey,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'আবেদনের আইডি: $applicationId',
                      style: TextStyle(
                        fontFamily: font,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'ফি-র পরিমাণ: $feeAmount টাকা',
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
                        onPressed: () {
                          Navigator.of(context).pushNamedAndRemoveUntil('/home', (route) => false);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryGreen,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: Text(
                          'ড্যাশবোর্ডে যান',
                          style: TextStyle(
                            fontFamily: font,
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
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

