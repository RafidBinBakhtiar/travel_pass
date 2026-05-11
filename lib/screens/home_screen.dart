import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:travel_pass/core/constants/app_colors.dart';
import 'package:travel_pass/core/constants/app_fonts.dart';
import 'package:travel_pass/features/permit/data/permit_models.dart';
import 'package:travel_pass/features/permit/provider/permit_provider.dart';
import 'package:travel_pass/features/permit/screens/travel_permit_application_screen.dart';
import 'package:travel_pass/features/auth/provider/auth_provider.dart';
import 'package:travel_pass/features/auth/screens/login_screen.dart';
import 'package:travel_pass/features/profile/provider/profile_provider.dart';

class HomeScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic>? userData;
  const HomeScreen({super.key, this.userData});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _selectedTabIndex = 0; // 0 = ড্যাশবোর্ড, 1 = মেনু, 2 = সকল পারমিট
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() => _searchQuery = _searchController.text.toLowerCase());
    });
    Future.microtask(() {
      ref.read(applicationsProvider.notifier).loadApplications();
      ref.read(profileProvider.notifier).loadProfile();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showLogoutDialog(String font) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20),
        elevation: 0,
        child: Container(
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
                        'বাতিল',
                        style: TextStyle(
                          fontFamily: AppFonts.bengali,
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

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: _buildAppBar(font),
      body: Column(
        children: [
          // ── Horizontal Navbar ──────────────────────────────────────────
          Container(
            color: AppColors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildTab(font, 0, 'ড্যাশবোর্ড'),
                  const SizedBox(width: 24),
                  _buildTab(font, 1, 'মেনু'),
                  const SizedBox(width: 24),
                  _buildTab(font, 2, 'সকল পারমিট'),
                ],
              ),
            ),
          ),
          const Divider(height: 1, color: AppColors.borderGrey),

          // ── Content Area ─────────────────────────────────────────────
          Expanded(
            child: IndexedStack(
              index: _selectedTabIndex,
              children: [
                _buildDashboardTab(font, appsState, allApps),
                _buildMenuTab(font),
                _buildAllPermitsTab(font, appsState, allApps),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTab(String font, int index, String label) {
    final isActive = _selectedTabIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedTabIndex = index),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontFamily: font,
              fontSize: 14,
              fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
              color: isActive ? AppColors.primaryGreen : AppColors.textGrey,
            ),
          ),
          if (isActive) ...[
            const SizedBox(height: 4),
            Container(
              height: 2,
              width: 24,
              color: AppColors.primaryGreen,
            ),
          ] else
            const SizedBox(height: 6),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(String font) {
    return AppBar(
      backgroundColor: AppColors.white,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      automaticallyImplyLeading: false,
      titleSpacing: 0,
      toolbarHeight: 60,
      title: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            Image.asset(
              'assets/images/logo.png',
              height: 44,
              fit: BoxFit.contain,
            ),
            const Spacer(),
            IconButton(
              icon: const Icon(
                LucideIcons.bell,
                color: AppColors.textDark,
                size: 24,
              ),
              onPressed: () {},
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            ),
          ],
        ),
      ),
    );
  }

  // ── Dashboard Tab ───────────────────────────────────────────────────────────
  Widget _buildDashboardTab(String font, dynamic appsState, List<PermitApplication> allApps) {
    final totalApps = allApps.length;
    final approvedApps = allApps.where((a) => a.status.toUpperCase() == 'APPROVED').length;
    final cancelledApps = allApps.where((a) => a.status.toUpperCase() == 'CANCELLED' || a.status.toUpperCase() == 'REJECTED').length;

    final activeApps = allApps.where((a) => a.status.toUpperCase() != 'CANCELLED' && a.status.toUpperCase() != 'REJECTED' && a.status.toUpperCase() != 'DRAFT').toList();
    final draftApps = allApps.where((a) => a.status.toUpperCase() == 'DRAFT').toList();

    return RefreshIndicator(
      color: AppColors.primaryGreen,
      onRefresh: () => ref.read(applicationsProvider.notifier).loadApplications(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Create Application Button
            Container(
              color: AppColors.white,
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: _openApplicationForm,
                      icon: const Icon(LucideIcons.plus, size: 20),
                      label: Text(
                        '+ ট্রাভেল পারমিট আবেদন করুন',
                        style: TextStyle(
                          fontFamily: font,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryGreen,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Stat Cards
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  _statCard(
                    font: font,
                    title: 'মোট পারমিট আবেদন',
                    subtitle: 'আবেদনের মোট সংখ্যা',
                    count: totalApps,
                    icon: LucideIcons.fileText,
                    iconColor: AppColors.primaryGreen,
                  ),
                  const SizedBox(height: 12),
                  _statCard(
                    font: font,
                    title: 'অনুমোদিত পারমিট',
                    subtitle: 'অনুমোদিত পারমিটের মোট সংখ্যা',
                    count: approvedApps,
                    icon: LucideIcons.userCheck,
                    iconColor: AppColors.primaryGreen,
                  ),
                  const SizedBox(height: 12),
                  _statCard(
                    font: font,
                    title: 'বাতিলকৃত পারমিট',
                    subtitle: 'বাতিলকৃত পারমিটের মোট সংখ্যা',
                    count: cancelledApps,
                    icon: LucideIcons.userX,
                    iconColor: const Color(0xFFF97316),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Active Applications Section
            if (appsState is ApplicationsLoading)
              const Center(child: Padding(padding: EdgeInsets.all(48), child: CircularProgressIndicator(color: AppColors.primaryGreen)))
            else if (appsState is ApplicationsError)
              _buildErrorState(font, appsState.message)
            else if (allApps.isEmpty)
              _buildEmptyDashboard(font)
            else ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
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
                        const SizedBox(height: 4),
                        Text(
                          'আপনার বর্তমানে সক্রিয়\nআবেদনসমূহ এখান থেকে দেখুন',
                          style: TextStyle(
                            fontFamily: font,
                            fontSize: 12,
                            color: AppColors.textGrey,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                    TextButton(
                      onPressed: () => setState(() => _selectedTabIndex = 2),
                      child: Row(
                        children: [
                          Text(
                            'সকল পারমিট দেখুন',
                            style: TextStyle(fontFamily: font, fontSize: 12, color: AppColors.primaryGreen, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(width: 4),
                          const Icon(LucideIcons.arrowRight, size: 14, color: AppColors.primaryGreen),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              _buildActiveApplicationsHorizontal(font, activeApps),
              const SizedBox(height: 24),
              if (draftApps.isNotEmpty) _buildDraftsList(font, draftApps),
              const SizedBox(height: 24),
            ],
          ],
        ),
      ),
    );
  }

  // ── All Permits Tab ────────────────────────────────────────────────────────
  Widget _buildAllPermitsTab(String font, dynamic appsState, List<PermitApplication> allApps) {
    if (appsState is ApplicationsLoading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primaryGreen));
    }

    final filteredApps = allApps.where((app) {
      final query = _searchQuery.toLowerCase();
      return app.displayId.toLowerCase().contains(query) ||
             app.destination.toLowerCase().contains(query) ||
             app.status.toLowerCase().contains(query);
    }).toList();

    if (allApps.isEmpty) {
      return _buildEmptyState(font);
    }

    return Column(
      children: [
        // Search & Filter Bar
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'অনুসন্ধান করুন...',
                    hintStyle: TextStyle(fontFamily: font, color: AppColors.textGrey),
                    prefixIcon: const Icon(LucideIcons.search, size: 18),
                    suffixIcon: _searchQuery.isNotEmpty 
                      ? IconButton(icon: const Icon(Icons.clear), onPressed: () => _searchController.clear())
                      : null,
                    filled: true,
                    fillColor: AppColors.white,
                    contentPadding: const EdgeInsets.symmetric(vertical: 0),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.borderGrey)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.borderGrey)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.primaryGreen)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.borderGrey),
                ),
                child: const Icon(LucideIcons.sliders, size: 20, color: AppColors.textDark),
              ),
            ],
          ),
        ),
        Expanded(
          child: filteredApps.isEmpty 
            ? Center(child: Text('কোনো আবেদন খুঁজে পাওয়া যায়নি', style: TextStyle(fontFamily: font, color: AppColors.textGrey)))
            : ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                itemCount: filteredApps.length,
                itemBuilder: (context, index) => _buildApplicationCard(font, filteredApps[index], isVertical: true),
              ),
        ),
      ],
    );
  }

  // ── Menu Tab ────────────────────────────────────────────────────────────────
  Widget _buildMenuTab(String font) {
    final profileState = ref.watch(profileProvider);
    final user = profileState is ProfileLoaded 
        ? profileState.profile 
        : profileState is ProfileUpdating 
            ? profileState.profile 
            : null;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // User Info Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.borderGrey),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: AppColors.primaryGreen.withValues(alpha: 0.1),
                  child: const Icon(LucideIcons.user, color: AppColors.primaryGreen, size: 32),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user?.fullName ?? 'আপনার নাম',
                        style: TextStyle(fontFamily: font, fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textDark),
                      ),
                      Text(
                        user?.email ?? 'email@example.com',
                        style: const TextStyle(fontFamily: AppFonts.english, fontSize: 13, color: AppColors.textGrey),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Menu Items
          Container(
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.borderGrey),
            ),
            child: Column(
              children: [
                _menuItem(font, LucideIcons.user, 'প্রোফাইল তথ্য', onTap: () => Navigator.pushNamed(context, '/profile')),
                const Divider(height: 1, color: AppColors.borderGrey),
                _menuItem(font, LucideIcons.lock, 'নিরাপত্তা ও পাসওয়ার্ড', onTap: () => Navigator.pushNamed(context, '/profile')),
                const Divider(height: 1, color: AppColors.borderGrey),
                _menuItem(font, LucideIcons.bell, 'নোটিফিকেশন', onTap: () {}),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // Logout Button
          SizedBox(
            width: double.infinity,
            height: 52,
            child: OutlinedButton.icon(
              onPressed: () => _showLogoutDialog(font),
              icon: const Icon(LucideIcons.logOut, size: 20),
              label: Text(
                'প্রস্থান করুন',
                style: TextStyle(fontFamily: font, fontSize: 15, fontWeight: FontWeight.w600),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.errorRed,
                side: const BorderSide(color: AppColors.errorRed),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Shared Widgets ──────────────────────────────────────────────────────────
  Widget _statCard({
    required String font,
    required String title,
    required String subtitle,
    required int count,
    required IconData icon,
    required Color iconColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderGrey),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontFamily: font, fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.textDark)),
                const SizedBox(height: 4),
                Text(count.toString().padLeft(2, '0'), style: const TextStyle(fontFamily: AppFonts.english, fontSize: 26, fontWeight: FontWeight.bold, color: AppColors.textDark)),
                Text(subtitle, style: TextStyle(fontFamily: font, fontSize: 11, color: AppColors.textGrey)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: iconColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: iconColor, size: 24),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveApplicationsHorizontal(String font, List<PermitApplication> apps) {
    if (apps.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Text('বর্তমানে কোনো সক্রিয় আবেদন নেই', style: TextStyle(fontFamily: font, color: AppColors.textGrey)),
      );
    }
    return SizedBox(
      height: 310,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: apps.length,
        itemBuilder: (context, index) => Container(
          width: MediaQuery.of(context).size.width * 0.82,
          margin: const EdgeInsets.only(right: 12),
          child: _buildApplicationCard(font, apps[index], isVertical: false),
        ),
      ),
    );
  }

  Widget _buildDraftsList(String font, List<PermitApplication> drafts) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ড্রাফটসমূহ',
                    style: TextStyle(fontFamily: font, fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textDark),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'আপনার সকল ড্রাফটসমূহের লিস্ট',
                    style: TextStyle(fontFamily: font, fontSize: 12, color: AppColors.textGrey),
                  ),
                ],
              ),
              TextButton(
                onPressed: () => setState(() => _selectedTabIndex = 2),
                child: Row(
                  children: [
                    Text(
                      'সকল পারমিট দেখুন',
                      style: TextStyle(fontFamily: font, fontSize: 12, color: AppColors.primaryGreen, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(width: 4),
                    const Icon(LucideIcons.arrowRight, size: 14, color: AppColors.primaryGreen),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: drafts.length,
          itemBuilder: (context, index) {
            final draft = drafts[index];
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.borderGrey),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3F4F6),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.borderGrey),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(LucideIcons.fileEdit, size: 12, color: AppColors.textDark),
                        const SizedBox(width: 4),
                        Text('ড্রাফট', style: TextStyle(fontFamily: font, fontSize: 10, color: AppColors.textDark, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _infoColumn(font, 'আইডি', draft.displayId),
                      _infoColumn(font, 'গন্তব্য', draft.destination),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _infoColumn(font, 'ভ্রমণের সময়সীমা', draft.travelPeriod, isEnglish: true),
                      _infoColumn(font, 'আবেদনের তারিখ', draft.formattedCreatedAt, isEnglish: true),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildApplicationCard(String font, PermitApplication app, {required bool isVertical}) {
    final isApproved = app.status.toUpperCase() == 'APPROVED';
    
    if (isVertical) {
      // For all permits list
      return Container(
        margin: const EdgeInsets.only(bottom: 12),
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
                _buildStatusBadge(font, app.status),
                if (isApproved)
                  InkWell(
                    onTap: () => _downloadPermit(app.id),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.borderGrey),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(LucideIcons.downloadCloud, size: 14, color: AppColors.textDark),
                          const SizedBox(width: 6),
                          const Text('Download QR', style: TextStyle(fontFamily: AppFonts.english, fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textDark)),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _infoColumn(font, 'আইডি', app.displayId),
                _infoColumn(font, 'গন্তব্য', app.destination),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _infoColumn(font, 'ভ্রমণের সময়সীমা', app.travelPeriod, isEnglish: true),
                _infoColumn(font, 'আবেদনের তারিখ', app.formattedCreatedAt, isEnglish: true),
              ],
            ),
          ],
        ),
      );
    }
    
    // For dashboard horizontal scroll
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderGrey),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left Box
              GestureDetector(
                onTap: isApproved ? () => _downloadPermit(app.id) : null,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9FAFB),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFF3F4F6)),
                  ),
                  child: Center(
                    child: isApproved
                        ? Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(LucideIcons.downloadCloud, color: AppColors.primaryGreen, size: 28),
                              const SizedBox(height: 4),
                              const Text('Download', style: TextStyle(fontFamily: AppFonts.english, fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.primaryGreen)),
                            ],
                          )
                        : const Icon(LucideIcons.lock, color: AppColors.textDark, size: 28),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // Right details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _infoRow(font, 'আবেদনের আইডি', app.displayId, true),
                    const SizedBox(height: 8),
                    _infoRow(font, 'ভ্রমণের সময়সীমা', app.travelPeriod, true),
                    const SizedBox(height: 8),
                    _infoRow(font, 'গন্তব্য', app.destination, false),
                    const SizedBox(height: 8),
                    _infoRow(font, 'আবেদনের তারিখ', app.formattedCreatedAt, true),
                  ],
                ),
              ),
            ],
          ),
          const Spacer(),
          _buildStatusStepper(font, app.status),
        ],
      ),
    );
  }

  Widget _infoRow(String font, String label, String value, bool isEnglish) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontFamily: font, fontSize: 9, color: AppColors.textGrey)),
        const SizedBox(height: 2),
        Text(value, style: TextStyle(fontFamily: isEnglish ? AppFonts.english : font, fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textDark)),
      ],
    );
  }

  Widget _infoColumn(String font, String label, String value, {bool isEnglish = false}) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontFamily: font, fontSize: 10, color: AppColors.textGrey)),
          Text(value, style: TextStyle(fontFamily: isEnglish ? AppFonts.english : font, fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textDark)),
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
          return Expanded(child: Container(height: 2, color: done ? AppColors.primaryGreen : AppColors.borderGrey));
        }
        final idx = i ~/ 2;
        final done = idx < activeIndex;
        final active = idx == activeIndex;
        return Column(
          children: [
            Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: done ? AppColors.primaryGreen : active ? AppColors.white : const Color(0xFFF3F4F6),
                border: Border.all(color: done || active ? AppColors.primaryGreen : AppColors.borderGrey, width: 1.5),
              ),
              child: done ? const Icon(LucideIcons.check, color: Colors.white, size: 10) : null,
            ),
            const SizedBox(height: 4),
            Text(steps[idx], style: TextStyle(fontFamily: font, fontSize: 9, color: done || active ? AppColors.primaryGreen : AppColors.textGrey, fontWeight: active ? FontWeight.bold : FontWeight.normal)),
          ],
        );
      }),
    );
  }

  int _statusToStep(String status) {
    switch (status.toUpperCase()) {
      case 'SUBMITTED': case 'DRAFT': return 0;
      case 'PAYMENT_PENDING': case 'FEE_PENDING': return 1;
      case 'PAYMENT_DONE': case 'UNDER_REVIEW': return 2;
      case 'APPROVED': return 3;
      default: return 0;
    }
  }

  Widget _buildStatusBadge(String font, String status) {
    Color color;
    String label;
    IconData icon;
    switch (status.toUpperCase()) {
      case 'APPROVED':
        color = AppColors.primaryGreen;
        label = 'অনুমোদিত';
        icon = LucideIcons.checkCircle;
        break;
      case 'CANCELLED':
      case 'REJECTED':
        color = AppColors.errorRed;
        label = 'বাতিল';
        icon = LucideIcons.xCircle;
        break;
      case 'PAYMENT_PENDING':
      case 'FEE_PENDING':
        color = const Color(0xFFF97316);
        label = 'ফি প্রদান';
        icon = LucideIcons.sun;
        break;
      case 'UNDER_REVIEW':
        color = const Color(0xFF0EA5E9);
        label = 'যাচাইকরণ';
        icon = LucideIcons.sun;
        break;
      default:
        color = AppColors.textDark;
        label = 'ড্রাফট';
        icon = LucideIcons.sun;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontFamily: font, fontSize: 10, color: color, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _menuItem(String font, IconData icon, String label, {required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          children: [
            Icon(icon, color: AppColors.textDark, size: 20),
            const SizedBox(width: 16),
            Expanded(child: Text(label, style: TextStyle(fontFamily: font, fontSize: 15, color: AppColors.textDark))),
            const Icon(LucideIcons.chevronRight, color: AppColors.textGrey, size: 18),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyDashboard(String font) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(20),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.asset('assets/images/Blank_dashboard.png', fit: BoxFit.contain),
          ),
        ),
        Text('এখনও কোনো আবেদন করা হয়নি', style: TextStyle(fontFamily: font, fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Text('আপনার সফর পরিকল্পনা শুরু করতে ট্রাভেল পারমিট আবেদন করুন।', textAlign: TextAlign.center, style: TextStyle(fontFamily: font, color: AppColors.textGrey)),
        ),
      ],
    );
  }

  Widget _buildEmptyState(String font) {
    return Center(child: Text('কোনো তথ্য পাওয়া যায়নি', style: TextStyle(fontFamily: font, color: AppColors.textGrey)));
  }

  Widget _buildErrorState(String font, String message) {
    return Center(
      child: Column(
        children: [
          const Icon(LucideIcons.alertCircle, color: AppColors.errorRed, size: 40),
          const SizedBox(height: 12),
          Text(message, style: TextStyle(fontFamily: font, color: AppColors.errorRed)),
          TextButton(onPressed: () => ref.read(applicationsProvider.notifier).loadApplications(), child: const Text('আবার চেষ্টা করুন')),
        ],
      ),
    );
  }

  Future<void> _downloadPermit(int id) async {
    final url = Uri.parse('https://travel-pass-backend.onrender.com/api/applications/$id/download');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('ডাউনলোড লিঙ্ক খোলা সম্ভব হচ্ছে না')));
      }
    }
  }
}
