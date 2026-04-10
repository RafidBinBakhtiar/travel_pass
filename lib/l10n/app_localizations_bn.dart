// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Bengali Bangla (`bn`).
class AppLocalizationsBn extends AppLocalizations {
  AppLocalizationsBn([String locale = 'bn']) : super(locale);

  @override
  String get loginTitle => 'লগইন';

  @override
  String get loginSubtitle => 'ট্রাভেল পাস অ্যাকাউন্টে লগইন করুন';

  @override
  String get mobileEmailLabel => 'মোবাইল/ইমেইল';

  @override
  String get mobileEmailHint => 'মোবাইল/ইমেইল (ইংরেজিতে)';

  @override
  String get email => 'ইমেইল (ইংরেজিতে)';

  @override
  String get passwordLabel => 'পাসওয়ার্ড';

  @override
  String get passwordHint => 'পাসওয়ার্ড';

  @override
  String get forgotPassword => 'পাসওয়ার্ড ভুলে গেছেন?';

  @override
  String get loginButton => 'লগইন করুন';

  @override
  String get noAccount => 'ট্রাভেল পাস অ্যাকাউন্ট নেই? ';

  @override
  String get registerLink => 'রেজিস্ট্রেশন করুন';

  @override
  String get emailNotRegistered =>
      'আপনার মোবাইল নম্বরটি অথবা ইমেইলটি নিবন্ধিত নয়';

  @override
  String get wrongPassword => 'আপনার পাসওয়ার্ডটি সঠিক নয়, আবার চেষ্টা করুন';

  @override
  String get registerTitle => 'নতুন অ্যাকাউন্ট তৈরি করুন';

  @override
  String get registerSubtitle => 'সঠিক তথ্য দিয়ে নিচের ফর্মটি পূরণ করুন';

  @override
  String get fullNameLabel => 'পূর্ণ নাম';

  @override
  String get fullNameHint => 'আপনার নাম লিখুন';

  @override
  String get mobileLabel => 'মোবাইল নম্বর';

  @override
  String get mobileHint => '০১২৩৪৬৭৮৯০';

  @override
  String get emailLabel => 'ইমেইল অ্যাড্রেস';

  @override
  String get emailHint => 'example@mail.com';

  @override
  String get passwordHintReg => 'পাসওয়ার্ড দিন';

  @override
  String get req8Chars => 'অন্তত ৮টি অক্ষর হতে হবে';

  @override
  String get reqUppercase =>
      'একটি বড় হাতের অক্ষর (A-Z) ও একটি সংখ্যা (0-9) থাকতে হবে';

  @override
  String get reqSpecial => 'একটি বিশেষ চিহ্ন (যেমন: @, #, \$) থাকতে হবে';

  @override
  String get touristTypeLabel => 'পর্যটকের ধরণ';

  @override
  String get domesticTourist => 'অভ্যন্তরীণ পর্যটক (Domestic Tourist)';

  @override
  String get foreignTourist => 'বিদেশি পর্যটক (Foreign Tourist)';

  @override
  String get createAccountButton => 'অ্যাকাউন্ট তৈরি করুন';

  @override
  String get backToLogin => 'লগইন পেইজে ফিরে যান';

  @override
  String get verifyOtpTitle => 'OTP যাচাই করুন';

  @override
  String otpSentTo(Object email) {
    return '$email এ একটি OTP পাঠানো হয়েছে';
  }

  @override
  String get verifyOtpButton => 'ওটিপি যাচাই করুন';

  @override
  String get resendOtpButton => 'ওটিপি পুনরায় পাঠান';

  @override
  String get registrationOtpTitle => 'আপনার অ্যাকাউন্ট যাচাই করুন';

  @override
  String get registrationOtpSubtitle =>
      'আপনার নিবন্ধিত ইমেইল বা ফোনে পাঠানো OTP প্রবেश করুন';

  @override
  String get selectTouristType => 'আপনার পর্যটক ধরণ নির্বাচন করুন';
}
