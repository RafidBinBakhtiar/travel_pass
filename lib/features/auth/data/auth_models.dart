class LoginRequest {
  final String emailOrPhone;
  final String password;
  final bool rememberMe;

  LoginRequest({
    required this.emailOrPhone,
    required this.password,
    this.rememberMe = false,
  });

  Map<String, dynamic> toJson() => {
    'emailOrPhone': emailOrPhone,
    'password': password,
    'rememberMe': rememberMe,
  };
}

// Result of parsing the login response
sealed class LoginResult {}

// Phone not verified — need OTP
class LoginNeedsOtp extends LoginResult {
  final String emailOrPhone;
  LoginNeedsOtp(this.emailOrPhone);
}

// Phone verified — has tokens already
class LoginHasTokens extends LoginResult {
  final String accessToken;
  final String refreshToken;
  LoginHasTokens({required this.accessToken, required this.refreshToken});
}

class VerifyLoginRequest {
  final String emailOrPhone;
  final String otp;

  VerifyLoginRequest({required this.emailOrPhone, required this.otp});

  Map<String, dynamic> toJson() => {
    'emailOrPhone': emailOrPhone,
    'otp': otp,
  };
}

// ── Registration ───────────────────────────────────────────────
class RegisterRequest {
  final String fullName;
  final String email;
  final String phone;
  final String password;
  final String touristType; // 'DOMESTIC' or 'FOREIGN'

  RegisterRequest({
    required this.fullName,
    required this.email,
    required this.phone,
    required this.password,
    required this.touristType,
  });

  Map<String, dynamic> toJson() => {
    'fullName': fullName,
    if (email.isNotEmpty) 'email': email,
    'phone': phone,
    'password': password,
    'touristType': touristType,
  };
}

// What the register API returns
sealed class RegisterResult {}

class RegisterNeedsPhoneOtp extends RegisterResult {
  final String phone;
  RegisterNeedsPhoneOtp(this.phone);
}

class RegisterNeedsEmailOtp extends RegisterResult {
  final String email;
  RegisterNeedsEmailOtp(this.email);
}

// ── Forgot Password ───────────────────────────────────────────────
class ForgotPasswordRequest {
  final String emailOrPhone;

  ForgotPasswordRequest({required this.emailOrPhone});

  Map<String, dynamic> toJson() => {
    'emailOrPhone': emailOrPhone,
  };
}

class VerifyForgotPasswordOtpRequest {
  final String emailOrPhone;
  final String otp;

  VerifyForgotPasswordOtpRequest({required this.emailOrPhone, required this.otp});

  Map<String, dynamic> toJson() => {
    'emailOrPhone': emailOrPhone,
    'otp': otp,
  };
}

class ResetPasswordRequest {
  final String resetToken;
  final String newPassword;
  final String confirmPassword;

  ResetPasswordRequest({
    required this.resetToken,
    required this.newPassword,
    required this.confirmPassword,
  });

  Map<String, dynamic> toJson() => {
    'resetToken': resetToken,
    'newPassword': newPassword,
    'confirmPassword': confirmPassword,
  };
}