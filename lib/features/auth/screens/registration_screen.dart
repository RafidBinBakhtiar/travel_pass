import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:phone_form_field/phone_form_field.dart';
import 'package:travel_pass/core/constants/app_colors.dart';
import 'package:travel_pass/core/constants/app_fonts.dart';
import 'package:travel_pass/l10n/app_localizations.dart';
import 'package:travel_pass/features/auth/data/auth_models.dart';
import 'package:travel_pass/features/auth/provider/register_provider.dart';
import 'package:travel_pass/core/utils/password_validator.dart';
import '../../../main.dart';
import '../../../screens/home_screen.dart';
import 'package:otp_pin_field/otp_pin_field.dart';

// ── Registration Screen (handles both form & OTP phases inline) ───────────────
class RegistrationScreen extends ConsumerStatefulWidget {
  const RegistrationScreen({super.key});

  @override
  ConsumerState<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends ConsumerState<RegistrationScreen> {
  // ── Form controllers (never cleared — preserved across phases) ────────────
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = PhoneController(
    PhoneNumber(isoCode: IsoCode.BD, nsn: ''),
  );
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _passwordVisible = false;
  String? _touristType;

  // ── OTP phase state ───────────────────────────────────────────────────────
  // When non-null we are in the OTP phase; the String is the phone being verified.
  String? _pendingPhone;
  String _otp = '';
  int _secondsLeft = 59;
  Timer? _timer;
  // Fresh key each time we enter OTP phase so the pin-field resets cleanly.
  GlobalKey<OtpPinFieldState> _otpPinFieldKey = GlobalKey<OtpPinFieldState>();

  // ── Timer ─────────────────────────────────────────────────────────────────
  void _startTimer() {
    _timer?.cancel();
    if (mounted) setState(() => _secondsLeft = 59);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      if (_secondsLeft == 0) {
        t.cancel();
      } else {
        setState(() => _secondsLeft--);
      }
    });
  }

  // ── Form phase handlers ───────────────────────────────────────────────────
  void _handleRegister() {
    final l10n = AppLocalizations.of(context);
    if (!_formKey.currentState!.validate()) return;
    if (_touristType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.selectTouristType),
          backgroundColor: AppColors.errorRed,
        ),
      );
      return;
    }

    final email = _emailController.text.trim();
    ref.read(registerProvider.notifier).register(
      RegisterRequest(
        fullName: _nameController.text.trim(),
        email: email.isEmpty ? '' : email,
        phone: _phoneController.value?.international ?? '',
        password: _passwordController.text,
        touristType: _touristType!,
      ),
    );
  }

  // ── OTP phase handlers ────────────────────────────────────────────────────
  void _handleVerifyOtp() {
    if (_otp.length < 4 || _pendingPhone == null) return;
    ref.read(registerProvider.notifier).verifyOtp(
      _pendingPhone!,
      _otp,
      _nameController.text.trim(),
    );
  }

  void _handleResendOtp() {
    if (_secondsLeft > 0 || _pendingPhone == null) return;
    ref.read(registerProvider.notifier).resendOtp(_pendingPhone!);
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

  /// "পরিবর্তন করুন" — go back to form phase.
  /// All form controllers retain their values; nothing is erased.
  void _handleChangeNumber() {
    _timer?.cancel();
    setState(() {
      _pendingPhone = null;
      _otp = '';
      _secondsLeft = 59;
      // Fresh key so the pin-field initialises empty next time
      _otpPinFieldKey = GlobalKey<OtpPinFieldState>();
    });
    ref.read(registerProvider.notifier).reset();
  }

  String _maskedPhone(String phone) {
    if (phone.length >= 4) {
      return '${phone.substring(0, 3)}******${phone.substring(phone.length - 2)}';
    }
    return phone;
  }

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).languageCode;
    final font = AppFonts.forLocale(locale);
    final state = ref.watch(registerProvider);

    ref.listen(registerProvider, (_, next) {
      if (next is RegisterNeedsPhoneVerification && _pendingPhone == null) {
        // Transition to OTP phase — form data untouched
        setState(() {
          _pendingPhone = next.phone;
          _otp = '';
          _otpPinFieldKey = GlobalKey<OtpPinFieldState>();
        });
        _startTimer();
      } else if (next is RegisterSuccess) {
        ref.read(verificationStatusProvider.notifier).setVerified(true);
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  RegistrationSuccessScreen(fullName: next.fullName),
            ),
          );
        }
      }
    });

    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: _pendingPhone != null
              ? _buildOtpPhase(state, l10n, font)
              : _buildFormPhase(state, l10n, font),
        ),
      ),
    );
  }

  // ── Form Phase ────────────────────────────────────────────────────────────
  Widget _buildFormPhase(
    RegisterState state,
    AppLocalizations l10n,
    String font,
  ) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          const SizedBox(height: 40),
          SvgPicture.asset('assets/images/Logo.svg', height: 80),
          const SizedBox(height: 20),

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
                  l10n.registerTitle,
                  style: TextStyle(
                    fontFamily: font,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  l10n.registerSubtitle,
                  style: TextStyle(
                    fontFamily: font,
                    color: AppColors.textGrey,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 20),

                // Full Name
                _label(l10n.fullNameLabel, font),
                _field(
                  controller: _nameController,
                  hint: l10n.fullNameHint,
                  font: font,
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? l10n.fullNameHint : null,
                ),
                const SizedBox(height: 15),

                // Mobile
                _label(l10n.mobileLabel, font),
                PhoneFormField(
                  controller: _phoneController,
                  defaultCountry: IsoCode.BD,
                  decoration: InputDecoration(
                    hintText: l10n.mobileHint,
                    hintStyle: TextStyle(
                      fontFamily: AppFonts.english,
                      color: AppColors.textGrey,
                    ),
                    filled: true,
                    fillColor: AppColors.white,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 14,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide:
                          const BorderSide(color: AppColors.borderGrey),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide:
                          const BorderSide(color: AppColors.borderGrey),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(
                        color: AppColors.primaryGreen,
                        width: 1.5,
                      ),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide:
                          const BorderSide(color: AppColors.errorRed),
                    ),
                    focusedErrorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide:
                          const BorderSide(color: AppColors.errorRed),
                    ),
                  ),
                  validator: PhoneValidator.compose([
                    PhoneValidator.required(
                      errorText: 'Please enter a mobile number',
                    ),
                    PhoneValidator.validMobile(
                      errorText: 'Please enter a valid mobile number',
                    ),
                  ]),
                ),
                const SizedBox(height: 15),

                // Email (optional)
                _label(l10n.emailLabel, font),
                _field(
                  controller: _emailController,
                  hint: l10n.emailHint,
                  keyboardType: TextInputType.emailAddress,
                  fontFamily: AppFonts.english,
                  font: font,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return null;
                    if (!RegExp(
                      r'^[\w.-]+@[\w.-]+\.\w+$',
                    ).hasMatch(v.trim())) {
                      return 'Please provide a valid email address';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 15),

                // Password
                _label(l10n.passwordLabel, font),
                TextFormField(
                  controller: _passwordController,
                  obscureText: !_passwordVisible,
                  style: const TextStyle(fontFamily: AppFonts.english),
                  decoration: _inputDeco(l10n.passwordHintReg, font).copyWith(
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
                  validator: (v) {
                    if (v == null || v.isEmpty) return l10n.passwordHintReg;
                    if (!PasswordValidator.isValid(v)) {
                      return PasswordValidator.getValidationMessages(v)
                          .join('\n');
                    }
                    return null;
                  },
                ),

                // Password requirements
                const SizedBox(height: 8),
                Builder(
                  builder: (context) {
                    final p = _passwordController.text;
                    return Column(
                      children: [
                        _requirement(
                          l10n.req8Chars,
                          font,
                          isValid: PasswordValidator.hasMinLength(p),
                        ),
                        _requirement(
                          l10n.reqUppercase,
                          font,
                          isValid: PasswordValidator.hasUppercase(p) &&
                              PasswordValidator.hasNumber(p),
                        ),
                        _requirement(
                          l10n.reqSpecial,
                          font,
                          isValid: PasswordValidator.hasSpecialChar(p),
                        ),
                      ],
                    );
                  },
                ),

                const SizedBox(height: 20),

                // Tourist Type
                _label(l10n.touristTypeLabel, font),
                _radioTile(l10n.domesticTourist, 'DOMESTIC', font),
                _radioTile(l10n.foreignTourist, 'FOREIGN', font),

                const SizedBox(height: 20),

                // Error banner
                if (state is RegisterError) _errorBanner(state.message, font),

                // Submit button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed:
                        state is RegisterLoading ? null : _handleRegister,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryGreen,
                      foregroundColor: AppColors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: state is RegisterLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.5,
                            ),
                          )
                        : Text(
                            l10n.createAccountButton,
                            style: TextStyle(
                              fontFamily: font,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Back to login
          TextButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(
              Icons.arrow_back,
              size: 16,
              color: AppColors.primaryGreen,
            ),
            label: Text(
              l10n.backToLogin,
              style: TextStyle(
                fontFamily: font,
                color: AppColors.primaryGreen,
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // ── OTP Phase ─────────────────────────────────────────────────────────────
  Widget _buildOtpPhase(
    RegisterState state,
    AppLocalizations l10n,
    String font,
  ) {
    return Column(
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
                l10n.registrationOtpTitle,
                style: TextStyle(
                  fontFamily: font,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              RichText(
                text: TextSpan(
                  style: TextStyle(
                    fontFamily: font,
                    color: AppColors.textGrey,
                    fontSize: 13,
                    height: 1.6,
                  ),
                  children: [
                    TextSpan(text: l10n.registrationOtpSubtitle),
                    TextSpan(
                      text: ' ${_maskedPhone(_pendingPhone ?? '')}',
                      style: const TextStyle(
                        color: AppColors.textDark,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // OTP label
              Text(
                'ওটিপি কোড টি এখানে লিখুন',
                style: TextStyle(
                  fontFamily: font,
                  fontWeight: FontWeight.w600,
                ),
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
                  fieldBorderWidth: 1.5,
                ),
                mainAxisAlignment: MainAxisAlignment.center,
                otpPinFieldDecoration:
                    OtpPinFieldDecoration.roundedPinBoxDecoration,
              ),

              const SizedBox(height: 24),

              // Resend OTP
              Center(
                child: GestureDetector(
                  onTap: _handleResendOtp,
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
                            style: const TextStyle(color: AppColors.textGrey),
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

              // Error banner
              if (state is RegisterError)
                _errorBanner(state.message, AppFonts.bengali),

              // Continue / verify button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed:
                      state is RegisterLoading || _otp.length < 4
                          ? null
                          : _handleVerifyOtp,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryGreen,
                    foregroundColor: AppColors.white,
                    elevation: 0,
                    disabledBackgroundColor:
                        AppColors.primaryGreen.withValues(alpha: 0.6),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: state is RegisterLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : const Text(
                          'এগিয়ে যান',
                          style: TextStyle(
                            fontFamily: AppFonts.bengali,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 12),

              // Change number — returns to form phase, no data erased
              Center(
                child: GestureDetector(
                  onTap: _handleChangeNumber,
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
        const SizedBox(height: 24),
      ],
    );
  }

  // ── Shared helpers ────────────────────────────────────────────────────────
  Widget _errorBanner(String message, String fontFamily) => Container(
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
              fontFamily: fontFamily,
              color: AppColors.errorRed,
              fontSize: 13,
            ),
          ),
        ),
      ],
    ),
  );

  Widget _label(String text, String fontFamily) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Text(
      text,
      style: TextStyle(fontFamily: fontFamily, fontWeight: FontWeight.w600),
    ),
  );

  Widget _field({
    required TextEditingController controller,
    required String hint,
    String? Function(String?)? validator,
    TextInputType keyboardType = TextInputType.text,
    String fontFamily = AppFonts.bengali,
    required String font,
  }) => TextFormField(
    controller: controller,
    keyboardType: keyboardType,
    style: TextStyle(fontFamily: fontFamily),
    decoration: _inputDeco(hint, font),
    validator: validator,
  );

  Widget _radioTile(String label, String value, String fontFamily) =>
      RadioListTile<String>(
        title: Text(
          label,
          style: TextStyle(fontFamily: fontFamily, fontSize: 13),
        ),
        value: value,
        groupValue: _touristType,
        activeColor: AppColors.primaryGreen,
        contentPadding: EdgeInsets.zero,
        onChanged: (v) => setState(() => _touristType = v),
      );

  Widget _requirement(
    String text,
    String fontFamily, {
    bool isValid = false,
  }) => Padding(
    padding: const EdgeInsets.only(top: 4, left: 2),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 5),
          child: Icon(
            Icons.circle,
            size: 5,
            color: isValid ? AppColors.primaryGreen : AppColors.textGrey,
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontFamily: fontFamily,
              fontSize: 11,
              color: isValid ? AppColors.primaryGreen : AppColors.textGrey,
            ),
          ),
        ),
      ],
    ),
  );

  InputDecoration _inputDeco(String hint, String fontFamily) =>
      InputDecoration(
        hintText: hint,
        hintStyle:
            TextStyle(fontFamily: fontFamily, color: AppColors.textGrey),
        filled: true,
        fillColor: AppColors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
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
          borderSide: const BorderSide(
            color: AppColors.primaryGreen,
            width: 1.5,
          ),
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

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _timer?.cancel();
    super.dispose();
  }
}

// ── Success Screen ────────────────────────────────────────────────────────────
class RegistrationSuccessScreen extends StatelessWidget {
  final String fullName;
  const RegistrationSuccessScreen({super.key, required this.fullName});

  @override
  Widget build(BuildContext context) {
    final firstName = fullName.split(' ').first;

    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SvgPicture.asset('assets/images/Logo.svg', height: 80),
              const SizedBox(height: 40),

              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppColors.primaryGreen.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle,
                  color: AppColors.primaryGreen,
                  size: 48,
                ),
              ),
              const SizedBox(height: 24),

              Text(
                'অভিনন্দন $firstName! আপনার নিবন্ধন সফল হয়েছে',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: AppFonts.bengali,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'ডিজিটাল ট্যুরিজম পারমিশন সিস্টেমে আপনাকে স্বাগতম। এখন আপনি আপনার ভ্রমণের জন্য পারমিট আবেদন শুরু করতে পারেন।',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: AppFonts.bengali,
                  fontSize: 14,
                  color: AppColors.textGrey,
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 32),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (_) => const HomeScreen()),
                      (route) => false,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryGreen,
                    foregroundColor: AppColors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    'ড্যাশবোর্ডে যান',
                    style: TextStyle(
                      fontFamily: AppFonts.bengali,
                      fontSize: 16,
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
}
