import 'package:flutter_riverpod/flutter_riverpod.dart';
import './auth_provider.dart';
import '../data/auth_repository.dart';
import '../data/auth_models.dart';

sealed class RegisterState {}
class RegisterInitial extends RegisterState {}
class RegisterLoading extends RegisterState {}

class RegisterNeedsPhoneVerification extends RegisterState {
  final String phone;
  RegisterNeedsPhoneVerification(this.phone);
}

class RegisterNeedsEmailVerification extends RegisterState {
  final String email;
  RegisterNeedsEmailVerification(this.email);
}

class RegisterSuccess extends RegisterState {
  final String fullName;
  RegisterSuccess(this.fullName);
}

class RegisterError extends RegisterState {
  final String message;
  RegisterError(this.message);
}

class RegisterNotifier extends StateNotifier<RegisterState> {
  final AuthRepository _repo;
  RegisterNotifier(this._repo) : super(RegisterInitial());

  Future<void> register(RegisterRequest request) async {
    state = RegisterLoading();
    try {
      final result = await _repo.register(request);
      if (result is RegisterNeedsPhoneOtp) {
        state = RegisterNeedsPhoneVerification(result.phone);
      } else if (result is RegisterNeedsEmailOtp) {
        state = RegisterNeedsEmailVerification(result.email);
      }
    } catch (e) {
      state = RegisterError(e.toString().replaceAll('Exception: ', ''));
    }
  }

  Future<void> verifyOtp(String emailOrPhone, String otp, String fullName) async {
    state = RegisterLoading();
    try {
      await _repo.verifyRegistrationOtp(emailOrPhone, otp);
      state = RegisterSuccess(fullName);
    } catch (e) {
      state = RegisterError(e.toString().replaceAll('Exception: ', ''));
    }
  }

  Future<void> resendOtp(String emailOrPhone) async {
    try {
      await _repo.resendOtp(emailOrPhone);
    } catch (e) {
      // silently fail resend
    }
  }

  void reset() => state = RegisterInitial();
}

final registerProvider =
    StateNotifierProvider.autoDispose<RegisterNotifier, RegisterState>(
  (ref) => RegisterNotifier(ref.read(authRepositoryProvider)),
);