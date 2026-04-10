// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get loginTitle => 'Login';

  @override
  String get loginSubtitle => 'Login to your Travel Pass account';

  @override
  String get mobileEmailLabel => 'Mobile/Email';

  @override
  String get mobileEmailHint => 'Mobile/Email (in English)';

  @override
  String get email => 'Email (in English)';

  @override
  String get passwordLabel => 'Password';

  @override
  String get passwordHint => 'Password';

  @override
  String get forgotPassword => 'Forgot password?';

  @override
  String get loginButton => 'Login';

  @override
  String get noAccount => 'Don\'t have a Travel Pass account? ';

  @override
  String get registerLink => 'Register';

  @override
  String get emailNotRegistered =>
      'Your mobile number or email is not registered';

  @override
  String get wrongPassword => 'Your password is incorrect, please try again';

  @override
  String get registerTitle => 'Create New Account';

  @override
  String get registerSubtitle =>
      'Fill out the form below with correct information';

  @override
  String get fullNameLabel => 'Full Name';

  @override
  String get fullNameHint => 'Enter your name';

  @override
  String get mobileLabel => 'Mobile Number';

  @override
  String get mobileHint => '01234567890';

  @override
  String get emailLabel => 'Email Address';

  @override
  String get emailHint => 'example@mail.com';

  @override
  String get passwordHintReg => 'Enter password';

  @override
  String get req8Chars => 'Must be at least 8 characters';

  @override
  String get reqUppercase =>
      'Must contain one uppercase letter (A-Z) and a number (0-9)';

  @override
  String get reqSpecial => 'Must contain a special character (e.g. @, #, \$)';

  @override
  String get touristTypeLabel => 'Tourist Type';

  @override
  String get domesticTourist => 'Domestic Tourist';

  @override
  String get foreignTourist => 'Foreign Tourist';

  @override
  String get createAccountButton => 'Create Account';

  @override
  String get backToLogin => 'Back to Login';

  @override
  String get verifyOtpTitle => 'Verify OTP';

  @override
  String otpSentTo(Object email) {
    return 'An OTP has been sent to $email';
  }

  @override
  String get verifyOtpButton => 'Verify OTP';

  @override
  String get resendOtpButton => 'Resend OTP';

  @override
  String get registrationOtpTitle => 'Verify Your Account';

  @override
  String get registrationOtpSubtitle =>
      'Enter the OTP sent to your registered email or phone';

  @override
  String get selectTouristType => 'Please select your tourist type';
}
