import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:travel_pass/core/constants/app_colors.dart';
import 'package:travel_pass/core/constants/app_fonts.dart';
import 'package:travel_pass/features/profile/data/profile_models.dart';
import 'package:travel_pass/features/profile/provider/profile_provider.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Profile Edit form
  final _profileFormKey = GlobalKey<FormState>();
  late TextEditingController _fullNameCtrl;
  late TextEditingController _phoneCtrl;
  late TextEditingController _emailCtrl;
  String _touristType = 'DOMESTIC';
  bool _isEditingProfile = false;

  // Change Password form
  final _passwordFormKey = GlobalKey<FormState>();
  final _currentPasswordCtrl = TextEditingController();
  final _newPasswordCtrl = TextEditingController();
  final _confirmPasswordCtrl = TextEditingController();
  bool _showCurrentPassword = false;
  bool _showNewPassword = false;
  bool _showConfirmPassword = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fullNameCtrl = TextEditingController();
    _phoneCtrl = TextEditingController();
    _emailCtrl = TextEditingController();

    // Load profile on first render
    Future.microtask(() => ref.read(profileProvider.notifier).loadProfile());
  }

  @override
  void dispose() {
    _tabController.dispose();
    _fullNameCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _currentPasswordCtrl.dispose();
    _newPasswordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    super.dispose();
  }

  void _populateFields(UserProfile profile) {
    _fullNameCtrl.text = profile.fullName;
    // Strip country code for display (keep as-is, API sends full number)
    _phoneCtrl.text = profile.phone;
    _emailCtrl.text = profile.email;
  }

  void _enterEditMode(UserProfile profile) {
    _populateFields(profile);
    setState(() => _isEditingProfile = true);
  }

  void _cancelEditMode() {
    setState(() => _isEditingProfile = false);
  }

  Future<void> _saveProfile() async {
    if (!_profileFormKey.currentState!.validate()) return;
    await ref.read(profileProvider.notifier).updateProfile(
          UpdateProfileRequest(
            fullName: _fullNameCtrl.text.trim(),
            email: _emailCtrl.text.trim(),
            phone: _phoneCtrl.text.trim(),
            touristType: _touristType,
          ),
        );
  }

  Future<void> _submitChangePassword() async {
    if (!_passwordFormKey.currentState!.validate()) return;
    await ref.read(changePasswordProvider.notifier).changePassword(
          _currentPasswordCtrl.text,
          _newPasswordCtrl.text,
        );
  }

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).languageCode;
    final font = AppFonts.forLocale(locale);
    final profileState = ref.watch(profileProvider);
    final changePassState = ref.watch(changePasswordProvider);

    // React to profile update success
    ref.listen<ProfileState>(profileProvider, (prev, next) {
      if (next is ProfileUpdateSuccess) {
        setState(() => _isEditingProfile = false);
        _showSnackbar(context, font, 'প্রোফাইল সফলভাবে আপডেট হয়েছে', isError: false);
        // Move back to loaded state
        Future.microtask(
            () => ref.read(profileProvider.notifier).resetToLoaded());
      } else if (next is ProfileError && prev is! ProfileInitial) {
        _showSnackbar(context, font, next.message, isError: true);
      }
    });

    // React to change password states
    ref.listen<ChangePasswordState>(changePasswordProvider, (prev, next) {
      if (next is ChangePasswordSuccess) {
        _currentPasswordCtrl.clear();
        _newPasswordCtrl.clear();
        _confirmPasswordCtrl.clear();
        _showSnackbar(context, font, 'পাসওয়ার্ড সফলভাবে পরিবর্তন হয়েছে',
            isError: false);
        ref.read(changePasswordProvider.notifier).reset();
      } else if (next is ChangePasswordError) {
        _showSnackbar(context, font, next.message, isError: true);
        ref.read(changePasswordProvider.notifier).reset();
      }
    });

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: _buildAppBar(font, profileState),
      body: Column(
        children: [
          // Tab Bar
          Container(
            color: AppColors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: _buildTabBar(font),
          ),
          // Tab Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildProfileTab(font, profileState),
                _buildPasswordTab(font, changePassState),
              ],
            ),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(String font, ProfileState profileState) {
    return AppBar(
      backgroundColor: AppColors.white,
      elevation: 0,
      shadowColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new,
            color: AppColors.textDark, size: 20),
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: Text(
        'প্রোফাইল',
        style: TextStyle(
          fontFamily: font,
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: AppColors.textDark,
        ),
      ),
      actions: [
        if (!_isEditingProfile && profileState is ProfileLoaded)
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: OutlinedButton.icon(
              onPressed: () => _enterEditMode(profileState.profile),
              icon: const Icon(Icons.edit_outlined, size: 16),
              label: Text(
                'প্রোফাইল এডিট করুন',
                style: TextStyle(fontFamily: font, fontSize: 13),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.textDark,
                side: const BorderSide(color: AppColors.borderGrey),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              ),
            ),
          ),
        if (_isEditingProfile) ...[
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ElevatedButton.icon(
              onPressed: profileState is ProfileUpdating ? null : _saveProfile,
              icon: profileState is ProfileUpdating
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.save_outlined, size: 16),
              label: Text(
                'প্রোফাইল সংরক্ষণ করুন',
                style: TextStyle(fontFamily: font, fontSize: 13),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryGreen,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: OutlinedButton(
              onPressed: _cancelEditMode,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.textDark,
                side: const BorderSide(color: AppColors.borderGrey),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              ),
              child: Text(
                'বাতিল করুন',
                style: TextStyle(fontFamily: font, fontSize: 13),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildTabBar(String font) {
    return TabBar(
      controller: _tabController,
      isScrollable: false,
      labelStyle: TextStyle(
        fontFamily: font,
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
      unselectedLabelStyle: TextStyle(
        fontFamily: font,
        fontSize: 14,
        fontWeight: FontWeight.w400,
      ),
      labelColor: AppColors.textDark,
      unselectedLabelColor: AppColors.textGrey,
      indicatorColor: AppColors.textDark,
      indicatorWeight: 2.5,
      dividerColor: AppColors.borderGrey,
      tabs: const [
        Tab(text: 'প্রোফাইল'),
        Tab(text: 'পাসওয়ার্ড পরিবর্তন করুন'),
      ],
    );
  }

  // ─── Profile Tab ───────────────────────────────────────────────────────────
  Widget _buildProfileTab(String font, ProfileState state) {
    if (state is ProfileLoading || state is ProfileInitial) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primaryGreen),
      );
    }

    if (state is ProfileError && state.profile == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: AppColors.errorRed, size: 48),
            const SizedBox(height: 12),
            Text(state.message,
                style: TextStyle(fontFamily: font, color: AppColors.errorRed)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () =>
                  ref.read(profileProvider.notifier).loadProfile(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryGreen,
                foregroundColor: Colors.white,
              ),
              child: Text('আবার চেষ্টা করুন', style: TextStyle(fontFamily: font)),
            ),
          ],
        ),
      );
    }

    final profile = switch (state) {
      ProfileLoaded s => s.profile,
      ProfileUpdating s => s.profile,
      ProfileUpdateSuccess s => s.profile,
      ProfileError s => s.profile,
      _ => null,
    };

    if (profile == null) return const SizedBox.shrink();

    if (_isEditingProfile) {
      return _buildEditForm(font, profile, state is ProfileUpdating);
    } else {
      return _buildViewProfile(font, profile);
    }
  }

  Widget _buildViewProfile(String font, UserProfile profile) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.borderGrey),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'প্রোফাইল তথ্য',
                  style: TextStyle(
                    fontFamily: font,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 20),
                _buildInfoRow(font, 'আপনার নামঃ', profile.fullName,
                    Icons.person_outline),
                const Divider(height: 24, color: AppColors.borderGrey),
                _buildInfoRow(
                    font, 'মোবাইল নম্বর', profile.phone, Icons.phone_outlined),
                const Divider(height: 24, color: AppColors.borderGrey),
                _buildInfoRow(
                  font,
                  'ইমেইল আড্রেস',
                  profile.email.isEmpty ? '—' : profile.email,
                  Icons.email_outlined,
                  trailing: profile.isEmailVerified
                      ? _buildBadge(font, 'যাচাইকৃত', AppColors.primaryGreen)
                      : _buildBadge(font, 'অযাচাইকৃত', AppColors.errorRed),
                ),
                const Divider(height: 24, color: AppColors.borderGrey),
                _buildInfoRow(
                  font,
                  'ভূমিকা',
                  profile.roles.map(_formatRole).join(', '),
                  Icons.badge_outlined,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(
    String font,
    String label,
    String value,
    IconData icon, {
    Widget? trailing,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: AppColors.textGrey),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontFamily: font,
                  fontSize: 12,
                  color: AppColors.textGrey,
                ),
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      value,
                      style: TextStyle(
                        fontFamily: font,
                        fontSize: 15,
                        color: AppColors.textDark,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  ?trailing,
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBadge(String font, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
            fontFamily: font,
            fontSize: 11,
            color: color,
            fontWeight: FontWeight.w600),
      ),
    );
  }

  // ─── Edit Form ─────────────────────────────────────────────────────────────
  Widget _buildEditForm(String font, UserProfile profile, bool isSubmitting) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Form(
            key: _profileFormKey,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.borderGrey),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'প্রোফাইল এডিট',
                    style: TextStyle(
                      fontFamily: font,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Full Name
                  _buildLabel(font, 'আপনার নামঃ'),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _fullNameCtrl,
                    enabled: !isSubmitting,
                    decoration: _inputDecoration(font, ''),
                    style: TextStyle(fontFamily: font, fontSize: 14),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'নাম দিন'
                        : null,
                  ),
                  const SizedBox(height: 16),

                  // Phone
                  _buildLabel(font, 'মোবাইল নম্বর'),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _phoneCtrl,
                    enabled: !isSubmitting,
                    keyboardType: TextInputType.phone,
                    decoration: _inputDecoration(font, '').copyWith(
                      prefixIcon: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Bangladesh flag emoji
                            const Text('🇧🇩',
                                style: TextStyle(fontSize: 18)),
                            const SizedBox(width: 4),
                            Icon(Icons.arrow_drop_down,
                                color: AppColors.textGrey, size: 18),
                          ],
                        ),
                      ),
                    ),
                    style: TextStyle(fontFamily: font, fontSize: 14),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'মোবাইল নম্বর দিন'
                        : null,
                  ),
                  const SizedBox(height: 16),

                  // Email (optional)
                  _buildLabel(font, 'ইমেইল আড্রেস (ঐচ্ছিক)'),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _emailCtrl,
                    enabled: !isSubmitting,
                    keyboardType: TextInputType.emailAddress,
                    decoration:
                        _inputDecoration(font, 'example@mail.com'),
                    style: TextStyle(fontFamily: font, fontSize: 14),
                  ),
                  const SizedBox(height: 20),

                  // Tourist Type
                  _buildLabel(font, 'পর্যটকের ধরন'),
                  const SizedBox(height: 8),
                  _buildTouristTypeSelector(font, isSubmitting),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTouristTypeSelector(String font, bool isSubmitting) {
    return Column(
      children: [
        _buildRadioOption(
          font: font,
          label: 'অভ্যন্তরীণ পর্যটক (Domestic Tourist)',
          value: 'DOMESTIC',
          isSubmitting: isSubmitting,
        ),
        const SizedBox(height: 8),
        _buildRadioOption(
          font: font,
          label: 'বিদেশি পর্যটক (Foreign Tourist)',
          value: 'FOREIGN',
          isSubmitting: isSubmitting,
        ),
      ],
    );
  }

  Widget _buildRadioOption({
    required String font,
    required String label,
    required String value,
    required bool isSubmitting,
  }) {
    final selected = _touristType == value;
    return GestureDetector(
      onTap: isSubmitting ? null : () => setState(() => _touristType = value),
      child: Row(
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: selected
                    ? AppColors.primaryGreen
                    : AppColors.borderGrey,
                width: 2,
              ),
            ),
            child: selected
                ? Center(
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(
                        color: AppColors.primaryGreen,
                        shape: BoxShape.circle,
                      ),
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 10),
          Text(
            label,
            style: TextStyle(
              fontFamily: font,
              fontSize: 14,
              color: selected ? AppColors.textDark : AppColors.textGrey,
              fontWeight:
                  selected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  // ─── Password Tab ──────────────────────────────────────────────────────────
  Widget _buildPasswordTab(String font, ChangePasswordState state) {
    final isLoading = state is ChangePasswordLoading;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Form(
            key: _passwordFormKey,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.borderGrey),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'পাসওয়ার্ড পরিবর্তন',
                    style: TextStyle(
                      fontFamily: font,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Current Password
                  _buildLabel(font, 'বর্তমান পাসওয়ার্ড'),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _currentPasswordCtrl,
                    obscureText: !_showCurrentPassword,
                    enabled: !isLoading,
                    decoration: _inputDecoration(font, 'পাসওয়ার্ড দিন').copyWith(
                      suffixIcon: IconButton(
                        icon: Icon(
                          _showCurrentPassword
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_off_outlined,
                          color: AppColors.textGrey,
                          size: 20,
                        ),
                        onPressed: () => setState(
                            () => _showCurrentPassword = !_showCurrentPassword),
                      ),
                    ),
                    style: TextStyle(fontFamily: font, fontSize: 14),
                    validator: (v) => (v == null || v.isEmpty)
                        ? 'বর্তমান পাসওয়ার্ড দিন'
                        : null,
                  ),
                  const SizedBox(height: 16),

                  // New Password
                  _buildLabel(font, 'নতুন পাসওয়ার্ড'),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _newPasswordCtrl,
                    obscureText: !_showNewPassword,
                    enabled: !isLoading,
                    decoration: _inputDecoration(font, 'পাসওয়ার্ড দিন').copyWith(
                      suffixIcon: IconButton(
                        icon: Icon(
                          _showNewPassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          color: AppColors.textGrey,
                          size: 20,
                        ),
                        onPressed: () =>
                            setState(() => _showNewPassword = !_showNewPassword),
                      ),
                    ),
                    style: TextStyle(fontFamily: font, fontSize: 14),
                    validator: _validateNewPassword,
                  ),
                  const SizedBox(height: 8),
                  _buildPasswordHints(font),
                  const SizedBox(height: 16),

                  // Confirm Password
                  _buildLabel(font, 'নতুন পাসওয়ার্ড কনফার্ম করুন'),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _confirmPasswordCtrl,
                    obscureText: !_showConfirmPassword,
                    enabled: !isLoading,
                    decoration: _inputDecoration(font, 'পাসওয়ার্ড দিন').copyWith(
                      suffixIcon: IconButton(
                        icon: Icon(
                          _showConfirmPassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          color: AppColors.textGrey,
                          size: 20,
                        ),
                        onPressed: () => setState(
                            () => _showConfirmPassword = !_showConfirmPassword),
                      ),
                    ),
                    style: TextStyle(fontFamily: font, fontSize: 14),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'পাসওয়ার্ড কনফার্ম করুন';
                      if (v != _newPasswordCtrl.text) {
                        return 'পাসওয়ার্ড মিলছে না';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),

                  // Submit Button
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: isLoading ? null : _submitChangePassword,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryGreen,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor:
                            AppColors.primaryGreen.withValues(alpha: 0.6),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              'আপডেট পাসওয়ার্ড',
                              style: TextStyle(
                                fontFamily: font,
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPasswordHints(String font) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHint(font, '• অন্তত ৮টি অক্ষর হতে হবে'),
        _buildHint(font, '• একটি বড় হাতের অক্ষর (A-Z) ও একটি সংখ্যা (0-9) থাকতে হবে'),
        _buildHint(font, '• একটি বিশেষ চিহ্ন (যেমন: @, #, \$) থাকতে হবে'),
      ],
    );
  }

  Widget _buildHint(String font, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Text(
        text,
        style: TextStyle(
          fontFamily: font,
          fontSize: 12,
          color: AppColors.textGrey,
        ),
      ),
    );
  }

  String? _validateNewPassword(String? value) {
    if (value == null || value.isEmpty) return 'নতুন পাসওয়ার্ড দিন';
    if (value.length < 8) return 'অন্তত ৮টি অক্ষর হতে হবে';
    if (!RegExp(r'[A-Z]').hasMatch(value)) return 'একটি বড় হাতের অক্ষর থাকতে হবে';
    if (!RegExp(r'[0-9]').hasMatch(value)) return 'একটি সংখ্যা থাকতে হবে';
    if (!RegExp(r'[!@#\$%^&*(),.?":{}|<>]').hasMatch(value)) {
      return 'একটি বিশেষ চিহ্ন থাকতে হবে';
    }
    return null;
  }

  // ─── Helpers ───────────────────────────────────────────────────────────────
  Widget _buildLabel(String font, String label) {
    return Text(
      label,
      style: TextStyle(
        fontFamily: font,
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: AppColors.textDark,
      ),
    );
  }

  InputDecoration _inputDecoration(String font, String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(
        fontFamily: font,
        fontSize: 14,
        color: AppColors.textGrey,
      ),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
        borderSide:
            const BorderSide(color: AppColors.primaryGreen, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.errorRed),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.errorRed, width: 1.5),
      ),
      filled: true,
      fillColor: AppColors.white,
    );
  }

  String _formatRole(String role) {
    switch (role.toLowerCase()) {
      case 'tourist':
        return 'পর্যটক';
      case 'admin':
        return 'অ্যাডমিন';
      default:
        return role;
    }
  }

  void _showSnackbar(BuildContext context, String font, String message,
      {required bool isError}) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: TextStyle(fontFamily: font, color: Colors.white),
        ),
        backgroundColor: isError ? AppColors.errorRed : AppColors.primaryGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }
}
