import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/profile_repository.dart';
import '../data/profile_models.dart';

// ── Repository Provider ─────────────────────────────────────────
final profileRepositoryProvider =
    Provider<ProfileRepository>((_) => ProfileRepository());

// ── Profile State ───────────────────────────────────────────────
sealed class ProfileState {}

class ProfileInitial extends ProfileState {}

class ProfileLoading extends ProfileState {}

class ProfileLoaded extends ProfileState {
  final UserProfile profile;
  ProfileLoaded(this.profile);
}

class ProfileUpdating extends ProfileState {
  final UserProfile profile;
  ProfileUpdating(this.profile);
}

class ProfileUpdateSuccess extends ProfileState {
  final UserProfile profile;
  ProfileUpdateSuccess(this.profile);
}

class ProfileError extends ProfileState {
  final String message;
  // Keep profile around so we can still show the form
  final UserProfile? profile;
  ProfileError(this.message, {this.profile});
}

// ── Change Password State ───────────────────────────────────────
sealed class ChangePasswordState {}

class ChangePasswordInitial extends ChangePasswordState {}

class ChangePasswordLoading extends ChangePasswordState {}

class ChangePasswordSuccess extends ChangePasswordState {}

class ChangePasswordError extends ChangePasswordState {
  final String message;
  ChangePasswordError(this.message);
}

// ── Profile Notifier ────────────────────────────────────────────
class ProfileNotifier extends StateNotifier<ProfileState> {
  final ProfileRepository _repo;
  ProfileNotifier(this._repo) : super(ProfileInitial());

  Future<void> loadProfile() async {
    state = ProfileLoading();
    try {
      final profile = await _repo.getProfile();
      state = ProfileLoaded(profile);
    } catch (e) {
      print('❌ PROFILE NOTIFIER: $e');
      state = ProfileError(e.toString().replaceAll('Exception: ', ''));
    }
  }

  Future<void> updateProfile(UpdateProfileRequest request) async {
    final current = _currentProfile;
    if (current != null) state = ProfileUpdating(current);

    try {
      final updated = await _repo.updateProfile(request);
      state = ProfileUpdateSuccess(updated);
    } catch (e) {
      print('❌ UPDATE PROFILE NOTIFIER: $e');
      state = ProfileError(
        e.toString().replaceAll('Exception: ', ''),
        profile: current,
      );
    }
  }

  void resetToLoaded() {
    final current = _currentProfile;
    if (current != null) state = ProfileLoaded(current);
  }

  UserProfile? get _currentProfile {
    final s = state;
    if (s is ProfileLoaded) return s.profile;
    if (s is ProfileUpdating) return s.profile;
    if (s is ProfileUpdateSuccess) return s.profile;
    if (s is ProfileError) return s.profile;
    return null;
  }
}

// ── Change Password Notifier ───────────────────────────────────
class ChangePasswordNotifier extends StateNotifier<ChangePasswordState> {
  final ProfileRepository _repo;
  ChangePasswordNotifier(this._repo) : super(ChangePasswordInitial());

  Future<void> changePassword(
      String currentPassword, String newPassword) async {
    state = ChangePasswordLoading();
    try {
      await _repo.changePassword(
        ChangePasswordRequest(
          currentPassword: currentPassword,
          newPassword: newPassword,
        ),
      );
      state = ChangePasswordSuccess();
    } catch (e) {
      print('❌ CHANGE PASSWORD NOTIFIER: $e');
      state = ChangePasswordError(e.toString().replaceAll('Exception: ', ''));
    }
  }

  void reset() => state = ChangePasswordInitial();
}

// ── Providers ───────────────────────────────────────────────────
final profileProvider =
    StateNotifierProvider<ProfileNotifier, ProfileState>((ref) {
  return ProfileNotifier(ref.read(profileRepositoryProvider));
});

final changePasswordProvider =
    StateNotifierProvider<ChangePasswordNotifier, ChangePasswordState>((ref) {
  return ChangePasswordNotifier(ref.read(profileRepositoryProvider));
});
