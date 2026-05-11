import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
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

  final _profileFormKey = GlobalKey<FormState>();
  late TextEditingController _fullNameCtrl;
  late TextEditingController _phoneCtrl;
  late TextEditingController _emailCtrl;
  String _touristType = 'DOMESTIC';
  bool _isEditingProfile = false;

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
    _phoneCtrl.text = profile.phone;
    _emailCtrl.text = profile.email;
    _touristType = profile.touristType;
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

    ref.listen<ProfileState>(profileProvider, (prev, next) {
      if (next is ProfileUpdateSuccess) {
        setState(() => _isEditingProfile = false);
        _showSnackbar(context, font, 'প্রোফাইল সফলভাবে আপডেট হয়েছে', isError: false);
        Future.microtask(() => ref.read(profileProvider.notifier).resetToLoaded());
      } else if (next is ProfileError && prev is! ProfileInitial) {
        _showSnackbar(context, font, next.message, isError: true);
      }
    });

    ref.listen<ChangePasswordState>(changePasswordProvider, (prev, next) {
      if (next is ChangePasswordSuccess) {
        _currentPasswordCtrl.clear();
        _newPasswordCtrl.clear();
        _confirmPasswordCtrl.clear();
        _showSnackbar(context, font, 'পাসওয়ার্ড সফলভাবে পরিবর্তন হয়েছে', isError: false);
        ref.read(changePasswordProvider.notifier).reset();
      } else if (next is ChangePasswordError) {
        _showSnackbar(context, font, next.message, isError: true);
        ref.read(changePasswordProvider.notifier).reset();
      }
    });

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: true,
        title: Text(
          'প্রোফাইল',
          style: TextStyle(
            fontFamily: font,
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textDark,
          ),
        ),
        actions: [
          if (!_isEditingProfile && profileState is ProfileLoaded)
            IconButton(
              icon: const Icon(Icons.edit_outlined, color: AppColors.primaryGreen),
              onPressed: () => _enterEditMode(profileState.profile),
            ),
        ],
      ),
      body: Column(
        children: [
          Container(
            color: AppColors.white,
            child: TabBar(
              controller: _tabController,
              labelColor: AppColors.primaryGreen,
              unselectedLabelColor: AppColors.textGrey,
              indicatorColor: AppColors.primaryGreen,
              indicatorWeight: 3,
              labelStyle: TextStyle(
                fontFamily: font,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
              tabs: const [
                Tab(text: 'প্রোফাইল তথ্য'),
                Tab(text: 'নিরাপত্তা'),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.borderGrey),
          Expanded(
            child: TabBarView(
              controller: _tabController,
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

  Widget _buildProfileTab(String font, ProfileState state) {
    if (state is ProfileLoading || state is ProfileInitial) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primaryGreen));
    }

    final profile = switch (state) {
      ProfileLoaded s => s.profile,
      ProfileUpdating s => s.profile,
      ProfileUpdateSuccess s => s.profile,
      ProfileError s => s.profile,
      _ => null,
    };

    if (profile == null) return const Center(child: Text('তথ্য পাওয়া যায়নি'));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Center(
            child: Column(
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.white, width: 4),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Icon(LucideIcons.user, size: 50, color: Color(0xFF3B82F6)),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  profile.fullName,
                  style: TextStyle(
                    fontFamily: font,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
                Text(
                  _formatRole(profile.roles.isNotEmpty ? profile.roles.first : 'Tourist'),
                  style: TextStyle(
                    fontFamily: font,
                    fontSize: 14,
                    color: AppColors.textGrey,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          if (_isEditingProfile)
            _buildEditForm(font, profile, state is ProfileUpdating)
          else
            _buildViewProfile(font, profile),
        ],
      ),
    );
  }

  Widget _buildViewProfile(String font, UserProfile profile) {
    return Column(
      children: [
        _infoCard(font, LucideIcons.phone, 'মোবাইল নম্বর', profile.phone),
        const SizedBox(height: 12),
        _infoCard(font, LucideIcons.mail, 'イমেইল', profile.email.isEmpty ? 'প্রদান করা হয়নি' : profile.email),
        const SizedBox(height: 12),
        _infoCard(font, LucideIcons.layers, 'পর্যটকের ধরন', profile.touristType == 'DOMESTIC' ? 'অভ্যন্তরীণ' : 'বিদেশী'),
      ],
    );
  }

  Widget _infoCard(String font, IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderGrey),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 20, color: AppColors.textDark),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontFamily: font, fontSize: 12, color: AppColors.textGrey)),
                const SizedBox(height: 2),
                Text(value, style: TextStyle(fontFamily: font, fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textDark)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditForm(String font, UserProfile profile, bool isSubmitting) {
    return Form(
      key: _profileFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildLabel(font, 'আপনার নাম'),
          const SizedBox(height: 8),
          TextFormField(
            controller: _fullNameCtrl,
            enabled: !isSubmitting,
            decoration: _inputDecoration(font, 'নাম লিখুন'),
          ),
          const SizedBox(height: 20),
          _buildLabel(font, 'ইমেইল'),
          const SizedBox(height: 8),
          TextFormField(
            controller: _emailCtrl,
            enabled: !isSubmitting,
            decoration: _inputDecoration(font, 'ইমেইল লিখুন'),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: isSubmitting ? null : _saveProfile,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryGreen,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: isSubmitting
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('সংরক্ষণ করুন', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: TextButton(
              onPressed: _cancelEditMode,
              child: const Text('বাতিল', style: TextStyle(color: AppColors.textGrey)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPasswordTab(String font, ChangePasswordState state) {
    final isLoading = state is ChangePasswordLoading;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _passwordFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildLabel(font, 'বর্তমান পাসওয়ার্ড'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _currentPasswordCtrl,
              obscureText: !_showCurrentPassword,
              enabled: !isLoading,
              decoration: _inputDecoration(font, 'বর্তমান পাসওয়ার্ড লিখুন').copyWith(
                suffixIcon: IconButton(
                  icon: Icon(_showCurrentPassword ? LucideIcons.eye : LucideIcons.eyeOff, size: 20),
                  onPressed: () => setState(() => _showCurrentPassword = !_showCurrentPassword),
                ),
              ),
            ),
            const SizedBox(height: 20),
            _buildLabel(font, 'নতুন পাসওয়ার্ড'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _newPasswordCtrl,
              obscureText: !_showNewPassword,
              enabled: !isLoading,
              decoration: _inputDecoration(font, 'নতুন পাসওয়ার্ড লিখুন').copyWith(
                suffixIcon: IconButton(
                  icon: Icon(_showNewPassword ? LucideIcons.eye : LucideIcons.eyeOff, size: 20),
                  onPressed: () => setState(() => _showNewPassword = !_showNewPassword),
                ),
              ),
              validator: _validateNewPassword,
            ),
            const SizedBox(height: 20),
            _buildLabel(font, 'পাসওয়ার্ড নিশ্চিত করুন'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _confirmPasswordCtrl,
              obscureText: !_showConfirmPassword,
              enabled: !isLoading,
              decoration: _inputDecoration(font, 'আবার লিখুন').copyWith(
                suffixIcon: IconButton(
                  icon: Icon(_showConfirmPassword ? LucideIcons.eye : LucideIcons.eyeOff, size: 20),
                  onPressed: () => setState(() => _showConfirmPassword = !_showConfirmPassword),
                ),
              ),
              validator: (v) => v != _newPasswordCtrl.text ? 'পাসওয়ার্ড মিলেনি' : null,
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: isLoading ? null : _submitChangePassword,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryGreen,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('পাসওয়ার্ড পরিবর্তন করুন', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String font, String label) {
    return Text(label, style: TextStyle(fontFamily: font, fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textDark));
  }

  InputDecoration _inputDecoration(String font, String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(fontFamily: font, fontSize: 14, color: AppColors.textGrey),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      filled: true,
      fillColor: const Color(0xFFF9FAFB),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.borderGrey)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.borderGrey)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.primaryGreen, width: 1.5)),
    );
  }

  String _formatRole(String role) {
    return role.toLowerCase() == 'tourist' ? 'পর্যটক' : role;
  }

  String? _validateNewPassword(String? value) {
    if (value == null || value.isEmpty) return 'নতুন পাসওয়ার্ড দিন';
    if (value.length < 8) return 'অন্তত ৮টি অক্ষর হতে হবে';
    return null;
  }

  void _showSnackbar(BuildContext context, String font, String message, {required bool isError}) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message, style: TextStyle(fontFamily: font)),
      backgroundColor: isError ? AppColors.errorRed : AppColors.primaryGreen,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      margin: const EdgeInsets.all(16),
    ));
  }
}
