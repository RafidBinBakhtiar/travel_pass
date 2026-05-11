import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:travel_pass/core/constants/app_colors.dart';
import 'package:travel_pass/core/constants/app_fonts.dart';
import 'package:travel_pass/features/permit/data/permit_models.dart';
import 'package:travel_pass/features/permit/provider/permit_provider.dart';

class AllPermitsScreen extends ConsumerStatefulWidget {
  const AllPermitsScreen({super.key});

  @override
  ConsumerState<AllPermitsScreen> createState() => _AllPermitsScreenState();
}

class _AllPermitsScreenState extends ConsumerState<AllPermitsScreen> {
  final TextEditingController _searchController = TextEditingController();
  PermitFilter _filter = PermitFilter();

  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref.read(applicationsProvider.notifier).loadApplications(),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _applySearch(String query) {
    setState(() {
      _filter = _filter.copyWith(searchQuery: query.isEmpty ? null : query);
    });
  }

  List<PermitApplication> _applyFilters(List<PermitApplication> apps) {
    var filtered = List<PermitApplication>.from(apps);

    if (_filter.searchQuery != null && _filter.searchQuery!.isNotEmpty) {
      final query = _filter.searchQuery!.toLowerCase();
      filtered = filtered
          .where(
            (app) =>
                app.displayId.toLowerCase().contains(query) ||
                app.touristName.toLowerCase().contains(query) ||
                app.mobileNumber.toLowerCase().contains(query),
          )
          .toList();
    }

    if (_filter.statuses != null && _filter.statuses!.isNotEmpty) {
      final allowed = _filter.statuses!
          .map((status) => status.toApiString())
          .toSet();
      filtered = filtered
          .where((app) => allowed.contains(app.status.toUpperCase()))
          .toList();
    }

    if (_filter.startDate != null || _filter.endDate != null) {
      final start = _filter.startDate;
      final end = _filter.endDate;
      filtered = filtered.where((app) {
        final parsed = DateTime.tryParse(app.arrivalDate);
        if (parsed == null) return false;
        final date = DateTime(parsed.year, parsed.month, parsed.day);
        final matchesStart = start == null ||
            !date.isBefore(DateTime(start.year, start.month, start.day));
        final matchesEnd = end == null ||
            !date.isAfter(DateTime(end.year, end.month, end.day));
        return matchesStart && matchesEnd;
      }).toList();
    }

    return filtered;
  }

  Future<void> _openFiltersSheet(String font, List<PermitApplication> apps) async {
    final uniqueDestinations = apps
        .map((e) => e.destination)
        .where((destination) => destination.trim().isNotEmpty)
        .toSet()
        .toList()
      ..sort();

    final currentQuery = _filter.searchQuery ?? '';
    var selectedStatus = _filter.statuses?.isNotEmpty == true
        ? _filter.statuses!.first
        : null;
    var selectedDestination = currentQuery.isNotEmpty ? currentQuery : 'ALL';
    DateTime? selectedDate = _filter.startDate;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            Future<void> pickDate() async {
              final picked = await showDatePicker(
                context: context,
                initialDate: selectedDate ?? DateTime.now(),
                firstDate: DateTime(2020),
                lastDate: DateTime(2100),
              );
              if (picked != null) {
                setSheetState(() => selectedDate = picked);
              }
            }

            String statusLabel(ApplicationStatus status) {
              return switch (status) {
                ApplicationStatus.submitted => 'আবেদন জমা',
                ApplicationStatus.feePending => 'ফি প্রদান',
                ApplicationStatus.underReview => 'যাচাইকরণ',
                ApplicationStatus.approved => 'অনুমোদন',
                _ => 'ড্রাফট',
              };
            }

            return Padding(
              padding: EdgeInsets.fromLTRB(
                20,
                20,
                20,
                20 + MediaQuery.of(context).viewInsets.bottom,
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'ফিল্টার',
                          style: TextStyle(
                            fontFamily: font,
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            setSheetState(() {
                              selectedStatus = null;
                              selectedDestination = 'ALL';
                              selectedDate = null;
                            });
                          },
                          child: Text(
                            'সব মুছুন',
                            style: TextStyle(
                              fontFamily: font,
                              color: AppColors.textDark,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'স্ট্যাটাস',
                      style: TextStyle(
                        fontFamily: font,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<ApplicationStatus>(
                      value: selectedStatus,
                      items: [
                        const DropdownMenuItem<ApplicationStatus>(
                          value: null,
                          child: Text('স্ট্যাটাস নির্বাচন করুন'),
                        ),
                        ...[
                          ApplicationStatus.submitted,
                          ApplicationStatus.feePending,
                          ApplicationStatus.underReview,
                          ApplicationStatus.approved,
                        ].map(
                          (status) => DropdownMenuItem<ApplicationStatus>(
                            value: status,
                            child: Text(statusLabel(status)),
                          ),
                        ),
                      ],
                      onChanged: (value) =>
                          setSheetState(() => selectedStatus = value),
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.borderGrey),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 14,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'গন্তব্য',
                      style: TextStyle(
                        fontFamily: font,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        _buildDestinationChip(
                          font,
                          'ALL',
                          selectedDestination == 'ALL',
                          () => setSheetState(() => selectedDestination = 'ALL'),
                        ),
                        ...uniqueDestinations.map(
                          (destination) => _buildDestinationChip(
                            font,
                            destination,
                            selectedDestination == destination,
                            () => setSheetState(
                              () => selectedDestination = destination,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'আবেদনের তারিখ',
                      style: TextStyle(
                        fontFamily: font,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    InkWell(
                      onTap: pickDate,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.borderGrey),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              LucideIcons.calendar,
                              size: 18,
                              color: AppColors.textGrey,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              selectedDate == null
                                  ? 'তারিখ নির্বাচন করুন'
                                  : '${selectedDate!.day.toString().padLeft(2, '0')}/${selectedDate!.month.toString().padLeft(2, '0')}/${selectedDate!.year}',
                              style: TextStyle(
                                fontFamily: font,
                                color: AppColors.textGrey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _filter = PermitFilter(
                              searchQuery: selectedDestination == 'ALL'
                                  ? null
                                  : selectedDestination,
                              statuses: selectedStatus == null
                                  ? null
                                  : [selectedStatus!],
                              startDate: selectedDate,
                              endDate: selectedDate,
                            );
                            if (_searchController.text.isNotEmpty &&
                                selectedDestination != 'ALL') {
                              _searchController.clear();
                            }
                          });
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryGreen,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'ফিল্টার করুন',
                          style: TextStyle(
                            fontFamily: font,
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
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
    final filteredApps = _applyFilters(allApps);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        automaticallyImplyLeading: true,
        title: Text(
          'সকল পারমিট',
          style: TextStyle(
            fontFamily: font,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Column(
        children: [
          // ── Search and Filter Bar ──
          Container(
            color: AppColors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    onChanged: _applySearch,
                    decoration: InputDecoration(
                      hintText: 'Search',
                      hintStyle: const TextStyle(
                        color: AppColors.textGrey,
                        fontSize: 14,
                      ),
                      prefixIcon: const Icon(
                        LucideIcons.search,
                        size: 18,
                        color: AppColors.textGrey,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(
                          color: AppColors.borderGrey,
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      isDense: true,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                InkWell(
                  onTap: () => _openFiltersSheet(font, allApps),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3F4F6),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.borderGrey),
                    ),
                    child: Icon(
                      LucideIcons.sliders,
                      size: 18,
                      color: AppColors.textGrey,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Permits List ──
          Expanded(
            child: appsState is ApplicationsLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.primaryGreen,
                    ),
                  )
                : appsState is ApplicationsError
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          LucideIcons.alertCircle,
                          size: 48,
                          color: AppColors.errorRed,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          appsState.message,
                          style: const TextStyle(color: AppColors.errorRed),
                        ),
                      ],
                    ),
                  )
                : filteredApps.isEmpty
                ? Center(
                    child: Text(
                      'No permits found',
                      style: TextStyle(
                        fontFamily: font,
                        color: AppColors.textGrey,
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    itemCount: filteredApps.length,
                    itemBuilder: (context, index) {
                      final app = filteredApps[index];
                      return _buildPermitCard(font, app);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(
    String font,
    String label,
    bool isSelected,
    VoidCallback onTap,
  ) {
    return FilterChip(
      label: Text(
        label,
        style: TextStyle(
          fontFamily: font,
          fontSize: 12,
          color: isSelected ? Colors.white : AppColors.textGrey,
          fontWeight: FontWeight.w500,
        ),
      ),
      selected: isSelected,
      onSelected: (_) => onTap(),
      backgroundColor: const Color(0xFFF3F4F6),
      selectedColor: AppColors.primaryGreen,
      side: BorderSide(
        color: isSelected ? AppColors.primaryGreen : AppColors.borderGrey,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    );
  }

  Widget _buildDestinationChip(
    String font,
    String label,
    bool isSelected,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: isSelected
              ? AppColors.primaryGreen.withValues(alpha: 0.1)
              : Colors.white,
          border: Border.all(
            color: isSelected ? AppColors.primaryGreen : AppColors.borderGrey,
          ),
        ),
        child: Text(
          label == 'ALL' ? 'সকল' : label,
          style: TextStyle(
            fontFamily: font,
            fontSize: 13,
            color: isSelected ? AppColors.primaryGreen : AppColors.textDark,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildPermitCard(String font, PermitApplication app) {
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
                    style: const TextStyle(
                      fontFamily: AppFonts.english,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              _buildStatusBadge(font, app.status),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                app.touristName,
                style: TextStyle(
                  fontFamily: font,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                app.mobileNumber,
                style: const TextStyle(
                  fontFamily: AppFonts.english,
                  fontSize: 12,
                  color: AppColors.textGrey,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
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
                    style: const TextStyle(
                      fontFamily: AppFonts.english,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
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
      case 'REJECTED':
        color = AppColors.errorRed;
        label = 'বাতিল';
        break;
      case 'FEE_PENDING':
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
