import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_fonts.dart';
import '../provider/auth_provider.dart';
import 'package:travel_pass/core/utils/password_validator.dart';
import 'dart:async';
import 'package:phone_form_field/phone_form_field.dart';
import 'package:otp_pin_field/otp_pin_field.dart';
import 'package:lucide_icons/lucide_icons.dart';

// ── Shared Auth Shell ──────────────────────────────────────────────────────────
class _AuthShell extends StatelessWidget {
  final Widget child;
  const _AuthShell({required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 24),
            Center(
              child: Image.asset(
                'assets/images/logo.png',
                height: 80,
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: child,
              ),
            ),
            SizedBox(
              width: double.infinity,
              child: Image.asset(
                'assets/images/BgImage.png',
                fit: BoxFit.fitWidth,
                alignment: Alignment.bottomCenter,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

BoxDecoration get _cardDecoration => BoxDecoration(
  color: AppColors.white,
  borderRadius: BorderRadius.circular(16),
  border: Border.all(color: AppColors.borderGrey),
  boxShadow: [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.05),
      blurRadius: 15,
      offset: const Offset(0, 5),
    ),
  ],
);

Widget _errorBanner(String message, String font) => Container(
  padding: const EdgeInsets.all(10),
  margin: const EdgeInsets.only(top: 12, bottom: 4),
  decoration: BoxDecoration(
    color: AppColors.errorRed.withValues(alpha: 0.08),
    borderRadius: BorderRadius.circular(8),
    border: Border.all(color: AppColors.errorRed.withValues(alpha: 0.3)),
  ),
  child: Row(
    children: [
      const Icon(LucideIcons.alertCircle, color: AppColors.errorRed, size: 16),
      const SizedBox(width: 8),
      Expanded(
        child: Text(
          message,
          style: TextStyle(
            fontFamily: font,
            color: AppColors.errorRed,
            fontSize: 13,
          ),
        ),
      ),
    ],
  ),
);

InputDecoration _fieldDeco(String hint) => InputDecoration(
  hintText: hint,
  hintStyle: const TextStyle(
    fontFamily: AppFonts.english,
    color: AppColors.textGrey,
  ),
  filled: true,
  fillColor: AppColors.white,
  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
  border: OutlineInputBorder(
    borderRadius: BorderRadius.circular(8),
    borderSide: const BorderSide(color: AppColors.borderGrey),
  ),
  enabledBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(8),
    borderSide: const BorderSide(color: AppColors.borderGrey),
  ),
  focusedBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(8),
    borderSide: const BorderSide(color: AppColors.primaryGreen, width: 1.5),
  ),
  errorBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(8),
    borderSide: const BorderSide(color: AppColors.errorRed),
  ),
  focusedErrorBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(8),
    borderSide: const BorderSide(color: AppColors.errorRed),
  ),
);

// ── ForgotPasswordScreen ──────────────────────────────────────────────────────
class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _phoneController = PhoneController(
    PhoneNumber(isoCode: IsoCode.BD, nsn: ''),
  );
  bool _isMobile = true;

  void _handleForgotPassword() {
    if (_formKey.currentState!.validate()) {
      final emailOrPhone = _isMobile
          ? _phoneController.value?.international ?? ''
          : _emailController.text.trim();
      ref.read(authProvider.notifier).forgotPassword(emailOrPhone);
    }
  }

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).languageCode;
    final font = AppFonts.forLocale(locale);
    final authState = ref.watch(authProvider);

    ref.listen(authProvider, (_, next) {
      if (next is ForgotPasswordAwaitingOtp) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                ForgotPasswordOtpScreen(emailOrPhone: next.emailOrPhone),
          ),
        );
      }
    });

    return _AuthShell(
      child: Form(
        key: _formKey,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: _cardDecoration,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'পাসওয়ার্ড ভুলে গেছেন?',
                style: TextStyle(
                  fontFamily: font,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'নতুন পাসওয়ার্ড সেট করার জন্য আপনার রেজিস্টার্ড ফোন/\nইমেইলে একটি কোড পাঠানো হবে',
                style: TextStyle(
                  fontFamily: font,
                  fontSize: 13,
                  color: AppColors.textGrey,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                _isMobile ? 'মোবাইল নম্বর' : 'ইমেইল',
                style: TextStyle(fontFamily: font, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              if (_isMobile)
                PhoneFormField(
                  controller: _phoneController,
                  defaultCountry: IsoCode.BD,
                  decoration: _fieldDeco('17XXXXXXXXX'),
                  validator: PhoneValidator.compose([
                    PhoneValidator.required(errorText: 'মোবাইল নম্বর প্রয়োজন'),
                    PhoneValidator.validMobile(
                      errorText: 'সঠিক মোবাইল নম্বর দিন',
                    ),
                  ]),
                )
              else
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  style: const TextStyle(fontFamily: AppFonts.english),
                  decoration: _fieldDeco('email@example.com'),
                  validator: (v) =>
                      (v == null || v.isEmpty) ? 'ইমেইল প্রয়োজন' : null,
                ),
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerRight,
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _isMobile = !_isMobile;
                      _emailController.clear();
                      _phoneController.value = PhoneNumber(
                        isoCode: IsoCode.BD,
                        nsn: '',
                      );
                    });
                  },
                  child: Text(
                    _isMobile
                        ? 'ইমেইলে কোড গ্রহন করতে চান?'
                        : 'মোবাইলে কোড গ্রহন করতে চান?',
                    style: TextStyle(
                      fontFamily: font,
                      fontSize: 13,
                      color: AppColors.textDark,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              if (authState is AuthError) _errorBanner(authState.message, font),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: authState is AuthLoading
                      ? null
                      : _handleForgotPassword,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryGreen,
                    foregroundColor: AppColors.white,
                    elevation: 0,
                    disabledBackgroundColor: AppColors.primaryGreen.withValues(
                      alpha: 0.6,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: authState is AuthLoading
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : Text(
                          'এগিয়ে যান',
                          style: TextStyle(
                            fontFamily: font,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 12),
              Center(
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: RichText(
                    text: TextSpan(
                      style: TextStyle(fontFamily: font, fontSize: 13),
                      children: const [
                        TextSpan(
                          text: '← ',
                          style: TextStyle(color: AppColors.primaryGreen),
                        ),
                        TextSpan(
                          text: 'লগইন পেইজে ফিরে যান',
                          style: TextStyle(
                            color: AppColors.primaryGreen,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }
}

// ── ForgotPasswordOtpScreen ───────────────────────────────────────────────────
class ForgotPasswordOtpScreen extends ConsumerStatefulWidget {
  final String emailOrPhone;
  const ForgotPasswordOtpScreen({super.key, required this.emailOrPhone});

  @override
  ConsumerState<ForgotPasswordOtpScreen> createState() =>
      _ForgotPasswordOtpScreenState();
}

class _ForgotPasswordOtpScreenState
    extends ConsumerState<ForgotPasswordOtpScreen> {
  final _otpPinFieldKey = GlobalKey<OtpPinFieldState>();
  String _otp = '';
  Timer? _countdownTimer;
  int _timeRemaining = 59;
  bool _canResendOtp = false;

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  void _startCountdown() {
    _timeRemaining = 59;
    _canResendOtp = false;
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _timeRemaining--;
          if (_timeRemaining <= 0) {
            _canResendOtp = true;
            timer.cancel();
          }
        });
      }
    });
  }

  void _handleResendOtp() {
    if (!_canResendOtp) return;
    ref
        .read(authProvider.notifier)
        .resendForgotPasswordOtp(widget.emailOrPhone);
    _startCountdown();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text(
          'ওটিপি আবার পাঠানো হয়েছে',
          style: TextStyle(fontFamily: AppFonts.bengali),
        ),
        backgroundColor: AppColors.primaryGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _handleVerifyOtp() {
    if (_otp.length < 4) return;
    ref
        .read(authProvider.notifier)
        .verifyForgotPasswordOtp(widget.emailOrPhone, _otp);
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).languageCode;
    final font = AppFonts.forLocale(locale);
    final authState = ref.watch(authProvider);

    ref.listen(authProvider, (_, next) {
      if (next is ForgotPasswordOtpVerified) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ResetPasswordScreen(resetToken: next.resetToken),
          ),
        );
      }
    });

    return _AuthShell(
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: _cardDecoration,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'ওটিপি যাচাইকরণ',
              style: TextStyle(
                fontFamily: font,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'আপনার পরিচয় নিশ্চিত করতে আমরা ${widget.emailOrPhone} নম্বরে একটি ৪-সংখ্যার ওটিপি (OTP) কোড পাঠিয়েছি।',
              style: TextStyle(
                fontFamily: font,
                color: AppColors.textGrey,
                fontSize: 13,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'ওটিপি কোডটি এখানে লিখুন',
              style: TextStyle(fontFamily: font, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            OtpPinField(
              key: _otpPinFieldKey,
              autoFillEnable: false,
              textInputAction: TextInputAction.done,
              onSubmit: (text) => setState(() => _otp = text),
              onChange: (text) => setState(() => _otp = text),
              maxLength: 4,
              showCursor: true,
              cursorColor: AppColors.primaryGreen,
              otpPinFieldStyle: OtpPinFieldStyle(
                defaultFieldBorderColor: AppColors.borderGrey,
                activeFieldBorderColor: AppColors.primaryGreen,
                defaultFieldBackgroundColor: AppColors.white,
                activeFieldBackgroundColor: AppColors.white,
                filledFieldBackgroundColor: AppColors.white,
                filledFieldBorderColor: AppColors.borderGrey,
                fieldBorderRadius: 10,
                fieldBorderWidth: 1.2,
              ),
              mainAxisAlignment: MainAxisAlignment.center,
              otpPinFieldDecoration:
                  OtpPinFieldDecoration.defaultPinBoxDecoration,
            ),
            const SizedBox(height: 16),
            Center(
              child: GestureDetector(
                onTap: _handleResendOtp,
                child: RichText(
                  text: TextSpan(
                    style: TextStyle(fontFamily: font, fontSize: 13),
                    children: [
                      const TextSpan(
                        text: 'কোডটি পাননি? ',
                        style: TextStyle(color: AppColors.textGrey),
                      ),
                      if (!_canResendOtp)
                        TextSpan(
                          text:
                              '(০:${_timeRemaining.toString().padLeft(2, '0')} সেকেন্ড পর চেষ্টা করুন)',
                          style: const TextStyle(color: AppColors.textGrey),
                        )
                      else
                        const TextSpan(
                          text: 'আবার ওটিপি পাঠান',
                          style: TextStyle(
                            color: AppColors.primaryGreen,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            if (authState is AuthError) _errorBanner(authState.message, font),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: authState is AuthLoading || _otp.length < 4
                    ? null
                    : _handleVerifyOtp,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryGreen,
                  foregroundColor: AppColors.white,
                  elevation: 0,
                  disabledBackgroundColor: AppColors.primaryGreen.withValues(
                    alpha: 0.6,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: authState is AuthLoading
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.5,
                        ),
                      )
                    : Text(
                        'এগিয়ে যান',
                        style: TextStyle(
                          fontFamily: font,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 12),
            Center(
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: RichText(
                  text: const TextSpan(
                    style: TextStyle(
                      fontFamily: AppFonts.bengali,
                      fontSize: 13,
                    ),
                    children: [
                      TextSpan(
                        text: 'ভুল নম্বর দিয়েছেন? ',
                        style: TextStyle(color: AppColors.textGrey),
                      ),
                      TextSpan(
                        text: 'পরিবর্তন করুন',
                        style: TextStyle(
                          color: AppColors.primaryGreen,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── ResetPasswordScreen ───────────────────────────────────────────────────────
class ResetPasswordScreen extends ConsumerStatefulWidget {
  final String resetToken;
  const ResetPasswordScreen({super.key, required this.resetToken});

  @override
  ConsumerState<ResetPasswordScreen> createState() =>
      _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _newPasswordVisible = false;
  bool _confirmPasswordVisible = false;

  void _handleResetPassword() {
    if (_formKey.currentState!.validate()) {
      ref
          .read(authProvider.notifier)
          .resetPassword(
            widget.resetToken,
            _newPasswordController.text,
            _confirmPasswordController.text,
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).languageCode;
    final font = AppFonts.forLocale(locale);
    final authState = ref.watch(authProvider);
    final passwordStatus = PasswordValidator.getValidationStatus(
      _newPasswordController.text,
    );

    ref.listen(authProvider, (_, next) {
      if (next is ForgotPasswordSuccess) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const PasswordResetSuccessScreen()),
        );
      }
    });

    return _AuthShell(
      child: Form(
        key: _formKey,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: _cardDecoration,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'নতুন পাসওয়ার্ড সেট করুন',
                style: TextStyle(
                  fontFamily: font,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'আপনার অ্যাকাউন্টের নিরাপত্তার জন্য একটি শক্তিশালী পাসওয়ার্ড তৈরি করুন।',
                style: TextStyle(
                  fontFamily: font,
                  fontSize: 13,
                  color: AppColors.textGrey,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'নতুন পাসওয়ার্ড',
                style: TextStyle(fontFamily: font, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _newPasswordController,
                obscureText: !_newPasswordVisible,
                style: const TextStyle(fontFamily: AppFonts.english),
                decoration: _fieldDeco('••••••••').copyWith(
                  suffixIcon: IconButton(
                    icon: Icon(
                      _newPasswordVisible
                          ? LucideIcons.eye
                          : LucideIcons.eyeOff,
                    ),
                    onPressed: () => setState(
                      () => _newPasswordVisible = !_newPasswordVisible,
                    ),
                  ),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'পাসওয়ার্ড প্রয়োজন';
                  if (!PasswordValidator.isValid(v))
                    return PasswordValidator.getValidationMessages(
                      v,
                    ).join('\n');
                  return null;
                },
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.borderGrey),
                ),
                child: Column(
                  children: [
                    _validationRow(
                      'অন্তত ৮টি অক্ষর হতে হবে',
                      passwordStatus['minLength'] ?? false,
                      font,
                    ),
                    const SizedBox(height: 8),
                    _validationRow(
                      'একটি বড় হাতের অক্ষর (A-Z) ও একটি সংখ্যা (0-9)',
                      (passwordStatus['uppercase'] ?? false) &&
                          (passwordStatus['number'] ?? false),
                      font,
                    ),
                    const SizedBox(height: 8),
                    _validationRow(
                      'একটি বিশেষ চিহ্ন (যেমন: @, #, \$)',
                      passwordStatus['specialChar'] ?? false,
                      font,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'পাসওয়ার্ড নিশ্চিত করুন',
                style: TextStyle(fontFamily: font, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _confirmPasswordController,
                obscureText: !_confirmPasswordVisible,
                style: const TextStyle(fontFamily: AppFonts.english),
                decoration: _fieldDeco('পাসওয়ার্ড নিশ্চিত করুন').copyWith(
                  suffixIcon: IconButton(
                    icon: Icon(
                      _confirmPasswordVisible
                          ? LucideIcons.eye
                          : LucideIcons.eyeOff,
                    ),
                    onPressed: () => setState(
                      () => _confirmPasswordVisible = !_confirmPasswordVisible,
                    ),
                  ),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'পাসওয়ার্ড নিশ্চিত করুন';
                  if (v != _newPasswordController.text)
                    return 'পাসওয়ার্ড দুটি মেলেনি';
                  return null;
                },
              ),
              if (authState is AuthError) _errorBanner(authState.message, font),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: authState is AuthLoading
                      ? null
                      : _handleResetPassword,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryGreen,
                    foregroundColor: AppColors.white,
                    elevation: 0,
                    disabledBackgroundColor: AppColors.primaryGreen.withValues(
                      alpha: 0.6,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: authState is AuthLoading
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : Text(
                          'পাসওয়ার্ড রিসেট করুন',
                          style: TextStyle(
                            fontFamily: font,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _validationRow(String text, bool isValid, String font) => Row(
    children: [
      Icon(
        isValid ? LucideIcons.checkCircle : LucideIcons.xCircle,
        size: 16,
        color: isValid
            ? AppColors.primaryGreen
            : AppColors.errorRed.withValues(alpha: 0.5),
      ),
      const SizedBox(width: 8),
      Expanded(
        child: Text(
          text,
          style: TextStyle(
            fontFamily: font,
            fontSize: 12,
            color: isValid ? AppColors.textDark : AppColors.textGrey,
          ),
        ),
      ),
    ],
  );

  @override
  void dispose() {
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
}

// ── PasswordResetSuccessScreen ─────────────────────────────────────────────────
class PasswordResetSuccessScreen extends StatelessWidget {
  const PasswordResetSuccessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).languageCode;
    final font = AppFonts.forLocale(locale);

    return _AuthShell(
      child: Container(
        padding: const EdgeInsets.all(32),
        decoration: _cardDecoration,
        child: Column(
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.primaryGreen.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                LucideIcons.checkCircle,
                color: AppColors.primaryGreen,
                size: 48,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'অভিনন্দন!',
              style: TextStyle(
                fontFamily: font,
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'আপনার পাসওয়ার্ডটি সফলভাবে সেট করা হয়েছে। এখন আপনি নতুন পাসওয়ার্ড ব্যবহার করে অ্যাকাউন্টে প্রবেশ করতে পারবেন।',
              style: TextStyle(
                fontFamily: font,
                fontSize: 14,
                color: AppColors.textGrey,
                height: 1.6,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: () =>
                    Navigator.of(context).popUntil((route) => route.isFirst),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryGreen,
                  foregroundColor: AppColors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(
                  'লগইন করুন',
                  style: TextStyle(
                    fontFamily: font,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
