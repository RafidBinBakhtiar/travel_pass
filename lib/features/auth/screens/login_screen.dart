import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:travel_pass/l10n/app_localizations.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_fonts.dart';
import '../provider/auth_provider.dart';
import '../../../screens/home_screen.dart';
import '../../../main.dart';
import 'dart:async';
import 'dart:convert';
import 'package:flutter_svg/flutter_svg.dart';
import '../screens/registration_screen.dart';
import '../screens/forgot_password_screen.dart';
import 'package:phone_form_field/phone_form_field.dart';
import 'package:otp_pin_field/otp_pin_field.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _phoneController = PhoneController(
    PhoneNumber(isoCode: IsoCode.BD, nsn: ''),
  );
  final _passwordController = TextEditingController();
  bool _passwordVisible = false;
  bool _isMobileLogin = true;

  void _handleLogin() {
    if (_formKey.currentState!.validate()) {
      final emailOrPhone = _isMobileLogin
          ? _phoneController.value?.international ?? ''
          : _emailController.text.trim();
          
      ref
          .read(authProvider.notifier)
          .login(emailOrPhone, _passwordController.text);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).languageCode;
    final font = AppFonts.forLocale(locale);
    final authState = ref.watch(authProvider);

    // Navigate to OTP screen when Step 1 succeeds
    ref.listen(authProvider, (_, next) {
      if (next is AuthAwaitingOtp) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => OtpScreen(email: next.emailOrPhone),
          ),
        );
      }
      if (next is AuthSuccess) {
        // Set verification status to true and navigate to HomeScreen
        ref.read(verificationStatusProvider.notifier).setVerified(true);
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => HomeScreen(userData: next.usersData),
          ),
        );
      }
      if (next is AuthDirectSuccess) {
        // Set verification status to true and navigate to HomeScreen (no user data needed)
        ref.read(verificationStatusProvider.notifier).setVerified(true);
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      }
    });

    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                const SizedBox(height: 60),
                SvgPicture.asset("assets/images/Logo.svg", height: 100),
                const SizedBox(height: 24),

                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
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
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.loginTitle,
                        style: TextStyle(
                          fontFamily: font,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textDark,
                        ),
                      ),
                      Text(
                        l10n.loginSubtitle,
                        style: TextStyle(
                          fontFamily: font,
                          fontSize: 14,
                          color: AppColors.textGrey,
                        ),
                      ),
                      const SizedBox(height: 30),

                      // Email / phone toggle
                      Row(
                        children: [
                          Radio<bool>(
                            value: true,
                            groupValue: _isMobileLogin,
                            onChanged: (v) => setState(() {
                              _isMobileLogin = v!;
                              _emailController.clear();
                            }),
                            activeColor: AppColors.primaryGreen,
                          ),
                          Text('মোবাইল', style: TextStyle(fontFamily: font)),
                          const SizedBox(width: 16),
                          Radio<bool>(
                            value: false,
                            groupValue: _isMobileLogin,
                            onChanged: (v) => setState(() {
                              _isMobileLogin = v!;
                              _phoneController.value =
                                  PhoneNumber(isoCode: IsoCode.BD, nsn: '');
                            }),
                            activeColor: AppColors.primaryGreen,
                          ),
                          Text('ইমেইল', style: TextStyle(fontFamily: font)),
                        ],
                      ),
                      const SizedBox(height: 8),

                      Text(
                        _isMobileLogin ? 'মোবাইল নম্বর' : l10n.email,
                        style: TextStyle(
                          fontFamily: font,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (_isMobileLogin)
                        PhoneFormField(
                          controller: _phoneController,
                          defaultCountry: IsoCode.BD,
                          decoration: _inputDeco('17XXXXXXXXX'),
                          validator: PhoneValidator.compose([
                            PhoneValidator.required(
                              errorText: 'মোবাইল নম্বর প্রয়োজন',
                            ),
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
                          decoration: _inputDeco(l10n.email),
                          validator: (v) => (v == null || v.isEmpty)
                              ? l10n.emailNotRegistered
                              : null,
                        ),

                      const SizedBox(height: 20),

                      // Password
                      Text(
                        l10n.passwordLabel,
                        style: TextStyle(
                          fontFamily: font,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: !_passwordVisible,
                        style: const TextStyle(fontFamily: AppFonts.english),
                        decoration: _inputDeco(l10n.passwordHint).copyWith(
                          suffixIcon: IconButton(
                            icon: Icon(
                              _passwordVisible
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                            ),
                            onPressed: () => setState(
                              () => _passwordVisible = !_passwordVisible,
                            ),
                          ),
                        ),
                        validator: (v) => (v == null || v.isEmpty)
                            ? l10n.wrongPassword
                            : null,
                      ),

                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const ForgotPasswordScreen(),
                            ),
                          ),
                          child: Text(
                            l10n.forgotPassword,
                            style: TextStyle(
                              fontFamily: font,
                              color: AppColors.textDark,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),

                      // API error banner
                      if (authState is AuthError)
                        _errorBanner(authState.message, font),

                      // Login button
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: ElevatedButton(
                          onPressed: authState is AuthLoading
                              ? null
                              : _handleLogin,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryGreen,
                            foregroundColor: AppColors.white,
                            elevation: 0,
                            disabledBackgroundColor: AppColors.primaryGreen
                                .withValues(alpha: 0.6),
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
                                  l10n.loginButton,
                                  style: TextStyle(
                                    fontFamily: font,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            l10n.noAccount,
                            style: TextStyle(fontFamily: font),
                          ),
                          // Find the GestureDetector for register link and update onTap:
                          GestureDetector(
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const RegistrationScreen(),
                              ),
                            ),
                            child: Text(
                              l10n.registerLink,
                              style: TextStyle(
                                color: AppColors.primaryGreen,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _errorBanner(String message, String font) => Container(
    padding: const EdgeInsets.all(10),
    margin: const EdgeInsets.only(bottom: 12),
    decoration: BoxDecoration(
      color: AppColors.errorRed.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: AppColors.errorRed.withValues(alpha: 0.3)),
    ),
    child: Row(
      children: [
        const Icon(Icons.error_outline, color: AppColors.errorRed, size: 16),
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

  InputDecoration _inputDeco(String hint) => InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(
      fontFamily: AppFonts.english,
      color: AppColors.textGrey,
    ),
    filled: true,
    fillColor: AppColors.white,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: AppColors.borderGrey),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: AppColors.borderGrey),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: AppColors.primaryGreen, width: 1.5),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: AppColors.errorRed),
    ),
  );

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}

// ── OTP Screen ────────────────────────────────────────────────────────────────
class OtpScreen extends ConsumerStatefulWidget {
  final String email;
  const OtpScreen({super.key, required this.email});

  @override
  ConsumerState<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends ConsumerState<OtpScreen> {
  final _otpPinFieldKey = GlobalKey<OtpPinFieldState>();
  String _otp = '';
  int _secondsLeft = 59;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    setState(() => _secondsLeft = 59);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsLeft == 0) {
        timer.cancel();
      } else {
        setState(() => _secondsLeft--);
      }
    });
  }

  void _handleVerify() {
    final otp = _otp;
    if (otp.length < 4) return;
    ref.read(authProvider.notifier).verifyOtp(widget.email, otp);
  }

  void _handleResend() {
    if (_secondsLeft > 0) return;
    ref.read(authProvider.notifier).resendOtp(widget.email);
    _startTimer();
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

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).languageCode;
    final font = AppFonts.forLocale(locale);

    ref.listen(authProvider, (_, next) {
      if (next is AuthAwaitingOtp) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                OtpScreen(email: next.emailOrPhone), // ← emailOrPhone
          ),
        );
      }
      if (next is AuthSuccess) {
        // Set verification status to true and navigate to HomeScreen
        ref.read(verificationStatusProvider.notifier).setVerified(true);
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => HomeScreen(userData: next.usersData),
          ),
        );
      }
      if (next is AuthDirectSuccess) {
        // Set verification status to true and navigate to HomeScreen (no user data needed)
        ref.read(verificationStatusProvider.notifier).setVerified(true);
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      }
    });

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        leading: BackButton(color: AppColors.textDark),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const SizedBox(height: 40),
              SvgPicture.asset('assets/images/Logo.svg', height: 80),
              const SizedBox(height: 24),

              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
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
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.verifyOtpTitle,
                      style: TextStyle(
                        fontFamily: font,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      l10n.otpSentTo(widget.email),
                      style: TextStyle(
                        fontFamily: font,
                        color: AppColors.textGrey,
                        fontSize: 13,
                        height: 1.6,
                      ),
                    ),
                    const SizedBox(height: 24),

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
                        fieldBorderWidth: 1.5,
                      ),
                      mainAxisAlignment: MainAxisAlignment.center,
                      otpPinFieldDecoration:
                          OtpPinFieldDecoration.roundedPinBoxDecoration,
                    ),
                    const SizedBox(height: 24),

                    Center(
                      child: GestureDetector(
                        onTap: _handleResend,
                        child: RichText(
                          text: TextSpan(
                            style: TextStyle(fontFamily: font, fontSize: 13),
                            children: [
                              const TextSpan(
                                text: 'কোড টি পাননি? ',
                                style: TextStyle(color: AppColors.textGrey),
                              ),
                              if (_secondsLeft > 0)
                                TextSpan(
                                  text:
                                      '(০:${_secondsLeft.toString().padLeft(2, '০')} সেকেন্ড পর চেষ্টা করুন)',
                                  style: const TextStyle(
                                    color: AppColors.textGrey,
                                  ),
                                )
                              else
                                const TextSpan(
                                  text: 'আবার পাঠান',
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

                    const SizedBox(height: 20),

                    if (authState is AuthError)
                      Container(
                        padding: const EdgeInsets.all(10),
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: AppColors.errorRed.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: AppColors.errorRed.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.error_outline,
                              color: AppColors.errorRed,
                              size: 16,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                authState.message,
                                style: const TextStyle(
                                  color: AppColors.errorRed,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed:
                            authState is AuthLoading ||
                                _otp.length < 4
                            ? null
                            : _handleVerify,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryGreen,
                          foregroundColor: AppColors.white,
                          elevation: 0,
                          disabledBackgroundColor: AppColors.primaryGreen
                              .withValues(alpha: 0.6),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: authState is AuthLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2.5,
                                ),
                              )
                            : Text(
                                l10n.verifyOtpButton,
                                style: TextStyle(
                                  fontFamily: font,
                                  fontSize: 16,
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
                            style: const TextStyle(
                              fontFamily: AppFonts.bengali,
                              fontSize: 13,
                            ),
                            children: [
                              TextSpan(
                                text: widget.email.contains('@') 
                                    ? 'ভুল ইমেইল দিয়েছেন? '
                                    : 'ভুল নম্বর দিয়েছেন? ',
                                style: const TextStyle(color: AppColors.textGrey),
                              ),
                              const TextSpan(
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
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Users data display ────────────────────────────────────────────────────────
class UsersDataScreen extends StatelessWidget {
  final Map<String, dynamic> data;
  const UsersDataScreen({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        title: const Text(
          'Users Data',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.primaryGreen,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E2E),
            borderRadius: BorderRadius.circular(12),
          ),
          child: SelectableText(
            const JsonEncoder.withIndent('  ').convert(data),
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 13,
              color: Color(0xFF89DDFF),
              height: 1.6,
            ),
          ),
        ),
      ),
    );
  }
}
