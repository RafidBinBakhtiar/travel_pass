import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/auth_repository.dart';
import '../data/auth_models.dart';

sealed class AuthState {}
class AuthInitial extends AuthState {}
class AuthLoading extends AuthState {}

class AuthAwaitingOtp extends AuthState {
  final String emailOrPhone;
  AuthAwaitingOtp(this.emailOrPhone);
}

class AuthSuccess extends AuthState {
  final Map<String, dynamic> usersData;
  AuthSuccess(this.usersData);
}

// Direct success — phone was already verified, tokens received at login
class AuthDirectSuccess extends AuthState {}

class AuthError extends AuthState {
  final String message;
  AuthError(this.message);
}

// Forgot Password states
class ForgotPasswordAwaitingOtp extends AuthState {
  final String emailOrPhone;
  ForgotPasswordAwaitingOtp(this.emailOrPhone);
}

class ForgotPasswordOtpVerified extends AuthState {
  final String resetToken;
  ForgotPasswordOtpVerified(this.resetToken);
}

class ForgotPasswordSuccess extends AuthState {}

final authRepositoryProvider =
    Provider<AuthRepository>((_) => AuthRepository());

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _repo;
  AuthNotifier(this._repo) : super(AuthInitial());

  // Step 1
  Future<void> login(String emailOrPhone, String password) async {
    state = AuthLoading();
    try {
      final result = await _repo.login(
        LoginRequest(emailOrPhone: emailOrPhone, password: password),
      );

      if (result is LoginNeedsOtp) {
        // Phone not verified → go to OTP screen
        state = AuthAwaitingOtp(result.emailOrPhone);
      } else if (result is LoginHasTokens) {
        // Phone verified → fetch users and go home
        
        state = AuthDirectSuccess();
      }
    } catch (e) {
      print('❌ LOGIN PROVIDER: $e');
      state = AuthError(e.toString().replaceAll('Exception: ', ''));
    }
  }

  // Step 2
  Future<void> verifyOtp(String emailOrPhone, String otp) async {
    state = AuthLoading();
    try {
      final data = await _repo.verifyLogin(
        VerifyLoginRequest(emailOrPhone: emailOrPhone, otp: otp),
      );
      state = AuthSuccess(data);
    } catch (e) {
      print('❌ VERIFY PROVIDER: $e');
      state = AuthError(e.toString().replaceAll('Exception: ', ''));
    }
  }

  Future<void> resendOtp(String emailOrPhone) async {
    try {
      await _repo.resendOtp(emailOrPhone);
    } catch (e) {
      print('❌ RESEND OTP PROVIDER: $e');
      state = AuthError(e.toString().replaceAll('Exception: ', ''));
    }
  }

  void resetToOtp(String emailOrPhone) {
    state = AuthAwaitingOtp(emailOrPhone);
  }

  // Forgot Password methods
  Future<void> forgotPassword(String emailOrPhone) async {
    state = AuthLoading();
    try {
      await _repo.forgotPassword(
        ForgotPasswordRequest(emailOrPhone: emailOrPhone),
      );
      state = ForgotPasswordAwaitingOtp(emailOrPhone);
    } catch (e) {
      print('❌ FORGOT PASSWORD PROVIDER: $e');
      state = AuthError(e.toString().replaceAll('Exception: ', ''));
    }
  }

  Future<void> verifyForgotPasswordOtp(String emailOrPhone, String otp) async {
    state = AuthLoading();
    try {
      final data = await _repo.verifyForgotPasswordOtp(
        VerifyForgotPasswordOtpRequest(emailOrPhone: emailOrPhone, otp: otp),
      );
      final resetToken = data['resetToken'] as String;
      state = ForgotPasswordOtpVerified(resetToken);
    } catch (e) {
      print('❌ VERIFY FORGOT PASSWORD OTP PROVIDER: $e');
      state = AuthError(e.toString().replaceAll('Exception: ', ''));
    }
  }

  Future<void> resendForgotPasswordOtp(String emailOrPhone) async {
    try {
      await _repo.resendOtp(emailOrPhone);
    } catch (e) {
      print('❌ RESEND OTP PROVIDER: $e');
      state = AuthError(e.toString().replaceAll('Exception: ', ''));
    }
  }

  Future<void> resetPassword(String resetToken, String newPassword, String confirmPassword) async {
    state = AuthLoading();
    try {
      await _repo.resetPassword(
        ResetPasswordRequest(
          resetToken: resetToken,
          newPassword: newPassword,
          confirmPassword: confirmPassword,
        ),
      );
      state = ForgotPasswordSuccess();
    } catch (e) {
      print('❌ RESET PASSWORD PROVIDER: $e');
      state = AuthError(e.toString().replaceAll('Exception: ', ''));
    }
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>(
  (ref) => AuthNotifier(ref.read(authRepositoryProvider)),
);