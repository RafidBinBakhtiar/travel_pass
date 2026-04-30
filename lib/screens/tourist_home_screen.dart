import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:travel_pass/core/constants/app_colors.dart';
import 'package:travel_pass/core/constants/app_fonts.dart';
import 'package:travel_pass/features/permit/data/permit_models.dart';
import 'package:travel_pass/features/permit/provider/permit_provider.dart';
import 'package:travel_pass/features/permit/screens/travel_permit_application_screen.dart';
import 'package:travel_pass/features/profile/screens/profile_screen.dart';
import 'package:travel_pass/features/auth/provider/auth_provider.dart';
import 'package:travel_pass/features/auth/screens/login_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic>? userData;
  const HomeScreen({super.key, this.userData});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref.read(applicationsProvider.notifier).loadApplications(),
    );
  }

  void _showLogoutDialog(String font) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20),
        elevation: 0,
        child: Container(
          width: 400,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'আপনি কি নিশ্চিত?',
                style: TextStyle(
                  fontFamily: font,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'আপনি কি আপনার অ্যাকাউন্ট থেকে লগআউট করতে চান?',
                style: TextStyle(
                  fontFamily: font,
                  fontSize: 14,
                  color: AppColors.textGrey,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFF3F4F6),
                        foregroundColor: AppColors.textDark,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(
                          fontFamily: AppFonts.english,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        await ref.read(authProvider.notifier).logout();
                        if (context.mounted) {
                          Navigator.of(context).pushAndRemoveUntil(
                            MaterialPageRoute(
                              builder: (_) => const LoginScreen(),
                            ),
                            (route) => false,
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.errorRed,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Text(
                        'লগআউট',
                        style: TextStyle(
                          fontFamily: font,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openApplicationForm() {
    Navigator.of(context)
        .push(
          MaterialPageRoute(
            builder: (_) => const TravelPermitApplicationScreen(),
          ),
        )
        .then(
          (_) => ref.read(applicationsProvider.notifier).loadApplications(),
        );
  }

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).languageCode;
    final font = AppFonts.forLocale(locale);
    final appsState = ref.watch(applicationsProvider);

    final List<PermitApplication> allApps = appsState is ApplicationsLoaded
        ? appsState.applications
        : [];
    final totalApps = allApps.length;
    final approvedApps = allApps
        .where((a) => a.status.toUpperCase() == 'APPROVED')
        .length;
    final cancelledApps = allApps
        .where(
          (a) =>
              a.status.toUpperCase() == 'CANCELLED' ||
              a.status.toUpperCase() == 'REJECTED',
        )
        .length;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      appBar: _buildAppBar(font, context),
      body: RefreshIndicator(
        color: AppColors.primaryGreen,
        onRefresh: () =>
            ref.read(applicationsProvider.notifier).loadApplications(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header Row ────────────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ElevatedButton.icon(
                    onPressed: _openApplicationForm,
                    icon: const Icon(Icons.add, size: 18),
                    label: Text(
                      'ট্রাভেল পারমিট আবেদন করুন',
                      style: TextStyle(
                        fontFamily: font,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryGreen,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // ── Stats Row ──────────────────────────────────────────
              _buildStatsRow(font, totalApps, approvedApps, cancelledApps),
              const SizedBox(height: 24),

              // ── Body: Empty or filled ─────────────────────────────
              if (appsState is ApplicationsLoading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(48),
                    child: CircularProgressIndicator(
                      color: AppColors.primaryGreen,
                    ),
                  ),
                )
              else if (appsState is ApplicationsError)
                _buildErrorState(font, appsState.message)
              else if (allApps.isEmpty)
                _buildEmptyState(font)
              else
                _buildApplicationsList(font, allApps),
            ],
          ),
        ),
      ),
    );
  }

  // ── AppBar ─────────────────────────────────────────────────────
  PreferredSizeWidget _buildAppBar(String font, BuildContext context) {
    return AppBar(
      backgroundColor: AppColors.white,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      titleSpacing: 0,
      automaticallyImplyLeading: false,
      toolbarHeight: 56,
      title: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            // Logo area
            const Spacer(),
            // Nav links
            TextButton(
              onPressed: () {},
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                'ড্যাশবোর্ড',
                style: TextStyle(
                  fontFamily: font,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryGreen,
                ),
              ),
            ),
            const SizedBox(width: 4),
            TextButton(
              onPressed: () {},
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                'সকল পারমিট',
                style: TextStyle(
                  fontFamily: font,
                  fontSize: 13,
                  color: AppColors.textGrey,
                ),
              ),
            ),
            const SizedBox(width: 4),
            // Bell
            IconButton(
              icon: const Icon(
                Icons.notifications_outlined,
                color: AppColors.textGrey,
                size: 20,
              ),
              onPressed: () {},
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            ),
            const SizedBox(width: 4),
            // Profile avatar & name
            PopupMenuButton<String>(
              offset: const Offset(0, 45),
              elevation: 4,
              shadowColor: Colors.black.withValues(alpha: 0.1),
              surfaceTintColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              color: Colors.white,
              onSelected: (value) {
                if (value == 'profile') {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const ProfileScreen()),
                  );
                } else if (value == 'logout') {
                  _showLogoutDialog(font);
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem<String>(
                  value: 'profile',
                  child: Row(
                    children: [
                      const Icon(
                        Icons.person_outline,
                        size: 20,
                        color: AppColors.textDark,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'প্রোফাইল',
                        style: TextStyle(
                          fontFamily: font,
                          fontSize: 14,
                          color: AppColors.textDark,
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuItem<String>(
                  value: 'logout',
                  child: Row(
                    children: [
                      const Icon(
                        Icons.logout,
                        size: 20,
                        color: AppColors.errorRed,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'লগআউট',
                        style: TextStyle(
                          fontFamily: font,
                          fontSize: 14,
                          color: AppColors.errorRed,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: AppColors.primaryGreen.withValues(
                      alpha: 0.15,
                    ),
                    child: const Icon(
                      Icons.person,
                      color: AppColors.primaryGreen,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 6),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 90),
                    child: Text(
                      'জনাব রহিম',
                      style: TextStyle(
                        fontFamily: font,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textDark,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const Icon(
                    Icons.keyboard_arrow_down,
                    color: AppColors.textGrey,
                    size: 18,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Stats Cards ─────────────────────────────────────────────────
  Widget _buildStatsRow(String font, int total, int approved, int cancelled) {
    return Row(
      children: [
        Expanded(
          child: _statCard(
            font: font,
            title: 'মোট পারমিট আবেদন',
            count: total,
            icon: Icons.description_outlined,
            iconColor: AppColors.primaryGreen,
            subtitle: 'আবেদনের মোট সংখ্যা',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _statCard(
            font: font,
            title: 'অনুমোদিত পারমিট',
            count: approved,
            icon: Icons.person_outline,
            iconColor: const Color(0xFF0EA5E9),
            subtitle: 'অনুমোদিত পারমিটের মোট সংখ্যা',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _statCard(
            font: font,
            title: 'বাতিলকৃত পারমিট',
            count: cancelled,
            icon: Icons.person_off_outlined,
            iconColor: const Color(0xFFF97316),
            subtitle: 'বাতিলকৃত পারমিটের মোট সংখ্যা',
          ),
        ),
      ],
    );
  }

  Widget _statCard({
    required String font,
    required String title,
    required int count,
    required IconData icon,
    required Color iconColor,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderGrey),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontFamily: font,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textDark,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(icon, color: iconColor, size: 18),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            count.toString().padLeft(2, '0'),
            style: TextStyle(
              fontFamily: AppFonts.english,
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              fontFamily: font,
              fontSize: 11,
              color: AppColors.textGrey,
            ),
          ),
        ],
      ),
    );
  }

  // ── Empty State ────────────────────────────────────────────────
  Widget _buildEmptyState(String font) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Column(
          children: [
            // Illustration placeholder
            Container(
              width: 240,
              height: 200,
              decoration: BoxDecoration(
                color: AppColors.primaryGreen.withValues(alpha: 0.06),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.travel_explore,
                size: 100,
                color: AppColors.primaryGreen.withValues(alpha: 0.4),
              ),
            ),
            const SizedBox(height: 28),
            Text(
              'এখনও কোনো আবেদন করা হাঁনি',
              style: TextStyle(
                fontFamily: font,
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'আপনার প্রথম পারমিট আবেদনের জন্য কোনো পারমিট\nআবেদন করুনি। আপনার সফর পরিকল্পনা শুরু করতে নিচে ক্লিক করুন।',
              style: TextStyle(
                fontFamily: font,
                fontSize: 13,
                color: AppColors.textGrey,
                height: 1.6,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _openApplicationForm,
              icon: const Icon(Icons.add, size: 18),
              label: Text(
                'ট্রাভেল পারমিট আবেদন করুন',
                style: TextStyle(
                  fontFamily: font,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryGreen,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Error State ────────────────────────────────────────────────
  Widget _buildErrorState(String font, String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            const Icon(
              Icons.error_outline,
              color: AppColors.errorRed,
              size: 48,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              style: TextStyle(fontFamily: font, color: AppColors.errorRed),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () =>
                  ref.read(applicationsProvider.notifier).loadApplications(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryGreen,
                foregroundColor: Colors.white,
              ),
              child: Text(
                'আবার চেষ্টা করুন',
                style: TextStyle(fontFamily: font),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Applications List ──────────────────────────────────────────
  Widget _buildApplicationsList(String font, List<PermitApplication> apps) {
    final activeApps = apps
        .where(
          (a) =>
              a.status.toUpperCase() != 'APPROVED' &&
              a.status.toUpperCase() != 'CANCELLED' &&
              a.status.toUpperCase() != 'REJECTED',
        )
        .toList();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Active Applications (Left Column) ─────────────────────
        Expanded(
          flex: 5,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.borderGrey),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'বর্তমান সক্রিয় আবেদনসমূহ',
                            style: TextStyle(
                              fontFamily: font,
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textDark,
                            ),
                          ),
                          Text(
                            'আপনার বর্তমানে সক্রিয় আবেদনসমূহ এখানে দেখুন',
                            style: TextStyle(
                              fontFamily: font,
                              fontSize: 11,
                              color: AppColors.textGrey,
                            ),
                          ),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: () {},
                      child: Text(
                        'সকল পারমিট দেখুন →',
                        style: TextStyle(
                          fontFamily: font,
                          fontSize: 12,
                          color: AppColors.primaryGreen,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (activeApps.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      'কোনো সক্রিয় আবেদন নেই',
                      style: TextStyle(
                        fontFamily: font,
                        color: AppColors.textGrey,
                      ),
                    ),
                  )
                else
                  ...activeApps
                      .take(3)
                      .map((app) => _buildApplicationCard(font, app)),
              ],
            ),
          ),
        ),
        const SizedBox(width: 16),

        // ── Drafts Table (Right Column) ───────────────────────────
        Expanded(
          flex: 6,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.borderGrey),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'ড্রাফটসমূহ',
                          style: TextStyle(
                            fontFamily: font,
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textDark,
                          ),
                        ),
                        Text(
                          'আপনার সকল ড্রাফটসমূহের লিস্ট',
                          style: TextStyle(
                            fontFamily: font,
                            fontSize: 11,
                            color: AppColors.textGrey,
                          ),
                        ),
                      ],
                    ),
                    TextButton(
                      onPressed: () {},
                      child: Text(
                        'সকল পারমিট দেখুন →',
                        style: TextStyle(
                          fontFamily: font,
                          fontSize: 12,
                          color: AppColors.primaryGreen,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildApplicationsTable(font, apps),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ── Application Card with Stepper ──────────────────────────────
  Widget _buildApplicationCard(String font, PermitApplication app) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.borderGrey),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Status icon
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.borderGrey,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.lock_outline,
                  color: AppColors.textGrey,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'আবেদনের আইডি',
                              style: TextStyle(
                                fontFamily: font,
                                fontSize: 10,
                                color: AppColors.textGrey,
                              ),
                            ),
                            Text(
                              app.displayId,
                              style: TextStyle(
                                fontFamily: AppFonts.english,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textDark,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 24),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'ভ্রমণের সময়সীমা',
                              style: TextStyle(
                                fontFamily: font,
                                fontSize: 10,
                                color: AppColors.textGrey,
                              ),
                            ),
                            Text(
                              app.travelPeriod,
                              style: TextStyle(
                                fontFamily: AppFonts.english,
                                fontSize: 12,
                                color: AppColors.textDark,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'গন্তব্য',
                              style: TextStyle(
                                fontFamily: font,
                                fontSize: 10,
                                color: AppColors.textGrey,
                              ),
                            ),
                            Text(
                              app.destination,
                              style: TextStyle(
                                fontFamily: font,
                                fontSize: 12,
                                color: AppColors.textDark,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 24),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'আবেদনের তারিখ',
                              style: TextStyle(
                                fontFamily: font,
                                fontSize: 10,
                                color: AppColors.textGrey,
                              ),
                            ),
                            Text(
                              app.formattedCreatedAt,
                              style: TextStyle(
                                fontFamily: AppFonts.english,
                                fontSize: 12,
                                color: AppColors.textDark,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Status stepper
          _buildStatusStepper(font, app.status),
        ],
      ),
    );
  }

  Widget _buildStatusStepper(String font, String status) {
    final steps = ['আবেদন জমা', 'ফি প্রদান', 'যাচাইকরণ', 'অনুমোদন'];
    int activeIndex = _statusToStep(status);

    return Row(
      children: List.generate(steps.length * 2 - 1, (i) {
        if (i.isOdd) {
          final done = activeIndex > i ~/ 2;
          return Expanded(
            child: Container(
              height: 2,
              color: done ? AppColors.primaryGreen : AppColors.borderGrey,
            ),
          );
        }
        final idx = i ~/ 2;
        final done = idx < activeIndex;
        final active = idx == activeIndex;
        return Column(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: done
                    ? AppColors.primaryGreen
                    : active
                    ? AppColors.primaryGreen.withValues(alpha: 0.2)
                    : const Color(0xFFE5E7EB),
                border: Border.all(
                  color: done || active
                      ? AppColors.primaryGreen
                      : const Color(0xFFD1D5DB),
                  width: 1.5,
                ),
              ),
              child: done
                  ? const Icon(Icons.check, color: Colors.white, size: 13)
                  : null,
            ),
            const SizedBox(height: 4),
            Text(
              steps[idx],
              style: TextStyle(
                fontFamily: font,
                fontSize: 9,
                color: done || active
                    ? AppColors.primaryGreen
                    : AppColors.textGrey,
                fontWeight: active ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        );
      }),
    );
  }

  int _statusToStep(String status) {
    switch (status.toUpperCase()) {
      case 'SUBMITTED':
      case 'DRAFT':
        return 0;
      case 'PAYMENT_PENDING':
        return 1;
      case 'PAYMENT_DONE':
      case 'UNDER_REVIEW':
        return 2;
      case 'APPROVED':
        return 3;
      default:
        return 0;
    }
  }

  // ── Applications Table ──────────────────────────────────────────
  Widget _buildApplicationsTable(String font, List<PermitApplication> apps) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        headingRowHeight: 40,
        dataRowMinHeight: 44,
        dataRowMaxHeight: 52,
        columnSpacing: 20,
        headingTextStyle: TextStyle(
          fontFamily: font,
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppColors.textDark,
        ),
        dataTextStyle: TextStyle(
          fontFamily: font,
          fontSize: 12,
          color: AppColors.textDark,
        ),
        columns: const [
          DataColumn(label: Text('আবেদনের আইডি')),
          DataColumn(label: Text('গন্তব্য')),
          DataColumn(label: Text('ভ্রমণের সময়সীমা')),
          DataColumn(label: Text('আবেদনের তারিখ')),
          DataColumn(label: Text('স্ট্যাটাস')),
        ],
        rows: apps
            .map(
              (app) => DataRow(
                cells: [
                  DataCell(
                    Text(
                      app.displayId,
                      style: const TextStyle(fontFamily: AppFonts.english),
                    ),
                  ),
                  DataCell(Text(app.destination)),
                  DataCell(
                    Text(
                      app.travelPeriod,
                      style: const TextStyle(fontFamily: AppFonts.english),
                    ),
                  ),
                  DataCell(
                    Text(
                      app.formattedCreatedAt,
                      style: const TextStyle(fontFamily: AppFonts.english),
                    ),
                  ),
                  DataCell(_buildStatusBadge(font, app.status)),
                ],
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _buildStatusBadge(String font, String status) {
    Color color;
    String label;
    switch (status.toUpperCase()) {
      case 'APPROVED':
        color = AppColors.primaryGreen;
        label = 'অনুমোদন';
        break;
      case 'CANCELLED':
      case 'REJECTED':
        color = AppColors.errorRed;
        label = 'বাতিল';
        break;
      case 'PAYMENT_PENDING':
        color = const Color(0xFFF97316);
        label = 'ফি প্রদান';
        break;
      case 'UNDER_REVIEW':
        color = const Color(0xFF0EA5E9);
        label = 'যাচাইকরণ';
        break;
      default:
        color = AppColors.textGrey;
        label = 'ড্রাফট';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.sync, size: 11, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontFamily: font,
              fontSize: 11,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
