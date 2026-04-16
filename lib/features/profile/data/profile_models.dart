class UserProfile {
  final int id;
  final String fullName;
  final String email;
  final String phone;
  final bool isEmailVerified;
  final List<String> roles;
  final List<String> permissions;

  UserProfile({
    required this.id,
    required this.fullName,
    required this.email,
    required this.phone,
    required this.isEmailVerified,
    required this.roles,
    required this.permissions,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as int? ?? 0,
      fullName: json['fullName'] as String? ?? '',
      email: json['email'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      isEmailVerified: json['isEmailVerified'] as bool? ?? false,
      roles: (json['roles'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      permissions: (json['permissions'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
    );
  }

  UserProfile copyWith({
    String? fullName,
    String? email,
    String? phone,
  }) {
    return UserProfile(
      id: id,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      isEmailVerified: isEmailVerified,
      roles: roles,
      permissions: permissions,
    );
  }
}

class UpdateProfileRequest {
  final String fullName;
  final String email;
  final String phone;
  final String touristType;

  UpdateProfileRequest({
    required this.fullName,
    required this.email,
    required this.phone,
    required this.touristType,
  });

  Map<String, dynamic> toJson() => {
        'fullName': fullName,
        if (email.isNotEmpty) 'email': email,
        'phone': phone,
        'touristType': touristType,
      };
}

class ChangePasswordRequest {
  final String currentPassword;
  final String newPassword;

  ChangePasswordRequest({
    required this.currentPassword,
    required this.newPassword,
  });

  Map<String, dynamic> toJson() => {
        'currentPassword': currentPassword,
        'newPassword': newPassword,
      };
}
