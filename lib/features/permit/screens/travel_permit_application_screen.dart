import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:travel_pass/core/constants/app_colors.dart';
import 'package:travel_pass/core/constants/app_fonts.dart';
import 'package:travel_pass/features/payment/data/payment_repository.dart';
import 'package:travel_pass/features/payment/screens/payment_screens.dart';
import 'package:travel_pass/features/permit/data/permit_models.dart';
import 'package:travel_pass/features/permit/provider/permit_provider.dart';

class TravelPermitApplicationScreen extends ConsumerStatefulWidget {
  const TravelPermitApplicationScreen({super.key});

  @override
  ConsumerState<TravelPermitApplicationScreen> createState() =>
      _TravelPermitApplicationScreenState();
}

class _TravelPermitApplicationScreenState
    extends ConsumerState<TravelPermitApplicationScreen> {
  int _currentStep = 0; // 0=form, 1=documents, 2=payment

  // ── Step 1 form ────────────────────────────────────────────────
  final _formKey = GlobalKey<FormState>();
  final _touristNameCtrl = TextEditingController();
  final _mobileCtrl = TextEditingController();
  final _occupationCtrl = TextEditingController();
  final _guardianNameCtrl = TextEditingController();
  final _guardianMobileCtrl = TextEditingController();
  final _presentAddressCtrl = TextEditingController();
  final _permanentAddressCtrl = TextEditingController();
  final _placeOfOriginCtrl = TextEditingController();
  String _touristType = 'DOMESTIC';
  String? _destination;
  DateTime? _arrivalDate;
  DateTime? _departureDate;

  static const List<String> _destinations = [
    'Cox\'s Bazar',
    'Sundarbans',
    'Bandarban',
    'Rangamati',
    'Khagrachhari',
    'Sylhet',
    'Sreemangal',
    'Kuakata',
    "Saint Martin's Island",
    'Sajek Valley',
    'Dhaka',
    'Chittagong',
    'Rajshahi',
    'Khulna',
    'Mymensingh',
  ];

  // ── Step 2 documents ───────────────────────────────────────────
  XFile? _nidFront;
  XFile? _nidBack;
  final _picker = ImagePicker();

  // ── Step 3 payment gateway ─────────────────────────────────────
  PaymentGateway? _selectedGateway;

  @override
  void dispose() {
    _touristNameCtrl.dispose();
    _mobileCtrl.dispose();
    _occupationCtrl.dispose();
    _guardianNameCtrl.dispose();
    _guardianMobileCtrl.dispose();
    _presentAddressCtrl.dispose();
    _permanentAddressCtrl.dispose();
    _placeOfOriginCtrl.dispose();
    super.dispose();
  }

  // ── Navigation helpers ─────────────────────────────────────────
  void _goNext() {
    if (_currentStep == 0) {
      if (!_formKey.currentState!.validate()) return;
      if (_destination == null) {
        _showError('গন্তব্য নির্বাচন করুন');
        return;
      }
      if (_arrivalDate == null || _departureDate == null) {
        _showError('ভ্রমণের তারিখ নির্বাচন করুন');
        return;
      }
    } else if (_currentStep == 1) {
      if (_nidFront == null || _nidBack == null) {
        _showError('উভয় এনআইডি ছবি আপলোড করুন');
        return;
      }
    }
    setState(() => _currentStep++);
  }

  void _goBack() => setState(() => _currentStep--);

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg,
          style: const TextStyle(fontFamily: AppFonts.bengali, color: Colors.white)),
      backgroundColor: AppColors.errorRed,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      margin: const EdgeInsets.all(16),
    ));
  }

  Future<void> _submit() async {
    final docs = <PermitDocument>[];
    if (_nidFront != null) {
      docs.add(PermitDocument(
          name: 'NID Front', url: 'https://example.com/media/nid_front.jpg'));
    }
    if (_nidBack != null) {
      docs.add(PermitDocument(
          name: 'NID Back', url: 'https://example.com/media/nid_back.jpg'));
    }

    final request = CreateApplicationRequest(
      touristName: _touristNameCtrl.text.trim(),
      mobileNumber: '+88${_mobileCtrl.text.trim()}',
      guardianName: _guardianNameCtrl.text.trim(),
      guardianMobile: '+88${_guardianMobileCtrl.text.trim()}',
      permanentAddress: _permanentAddressCtrl.text.trim(),
      presentAddress: _presentAddressCtrl.text.trim(),
      occupation: _occupationCtrl.text.trim(),
      placeOfOrigin: _placeOfOriginCtrl.text.trim(),
      destination: _destination ?? '',
      arrivalDate: _arrivalDate!.toUtc().toIso8601String(),
      departureDate: _departureDate!.toUtc().toIso8601String(),
      touristType: _touristType,
      documents: docs,
    );

    await ref.read(createApplicationProvider.notifier).createApplication(request);
  }

  // ── Date Picker ────────────────────────────────────────────────
  Future<void> _pickDate({required bool isArrival}) async {
    final now = DateTime.now();
    final initial = isArrival
        ? (_arrivalDate ?? now)
        : (_departureDate ?? (_arrivalDate ?? now));
    final first = isArrival ? now : (_arrivalDate ?? now);
    final picked = await showDatePicker(
      context: context,
      initialDate: initial.isBefore(first) ? first : initial,
      firstDate: first,
      lastDate: DateTime(now.year + 2),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: ColorScheme.light(
            primary: AppColors.primaryGreen,
            onPrimary: Colors.white,
            surface: Colors.white,
            onSurface: AppColors.textDark,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        if (isArrival) {
          _arrivalDate = picked;
          if (_departureDate != null && _departureDate!.isBefore(picked)) {
            _departureDate = null;
          }
        } else {
          _departureDate = picked;
        }
      });
    }
  }

  // ── Image Picker ──────────────────────────────────────────────
  Future<void> _pickImage(bool isFront) async {
    final file = await _picker.pickImage(
        source: ImageSource.gallery, imageQuality: 80);
    if (file != null) setState(() => isFront ? _nidFront = file : _nidBack = file);
  }

  String _formatDate(DateTime? dt) {
    if (dt == null) return 'তারিখ নির্বাচন করুন';
    return DateFormat('dd MMM yyyy').format(dt);
  }

  @override
  Widget build(BuildContext context) {
    final font = AppFonts.bengali;

    // Listen to submit result
    ref.listen<CreateApplicationState>(createApplicationProvider, (prev, next) {
      if (next is CreateApplicationSuccess) {
        final app = next.application;
        ref.read(createApplicationProvider.notifier).reset();
        ref.read(applicationsProvider.notifier).loadApplications();

        // Build the payment URL
        final repo = PaymentRepository();
        const successUrl = 'travelpass://payment/success';
        const failUrl = 'travelpass://payment/fail';
        final String payUrl;
        if (_selectedGateway == PaymentGateway.shurjopay) {
          payUrl = repo.getShurjopayUrl(
            paymentId: app.id,
            successUrl: successUrl,
            failUrl: failUrl,
          );
        } else {
          payUrl = repo.getBkashPayUrl(
            paymentId: app.id,
            successUrl: successUrl,
            failUrl: failUrl,
          );
        }

        // Navigate to WebView for payment
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => PaymentWebViewScreen(
              paymentUrl: payUrl,
              application: app,
            ),
          ),
        );
      } else if (next is CreateApplicationError) {
        _showError(next.message);
        ref.read(createApplicationProvider.notifier).reset();
      }
    });

    final submitState = ref.watch(createApplicationProvider);
    final isSubmitting = submitState is CreateApplicationLoading;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              color: AppColors.textDark, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Column(
        children: [
          // Title
          Container(
            color: AppColors.white,
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
            child: Text(
              'ট্রাভেল পারমিট আবেদনফর্ম',
              style: TextStyle(
                fontFamily: font,
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
              textAlign: TextAlign.center,
            ),
          ),

          // Step Indicator
          Container(
            color: AppColors.white,
            padding: const EdgeInsets.fromLTRB(32, 0, 32, 20),
            child: _buildStepIndicator(font),
          ),

          const Divider(height: 1, color: Color(0xFFE5E7EB)),

          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 540),
                  child: [
                    _buildStep1(font),
                    _buildStep2(font),
                    _buildStep3(font, isSubmitting),
                  ][_currentStep],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Step Indicator ─────────────────────────────────────────────
  Widget _buildStepIndicator(String font) {
    final steps = ['আবেদনফর্ম', 'নথিপত্র আপলোড', 'ফি প্রদান'];
    return Row(
      children: List.generate(steps.length * 2 - 1, (i) {
        if (i.isOdd) {
          // connector line
          final stepIndex = i ~/ 2;
          final done = _currentStep > stepIndex;
          return Expanded(
            child: Container(
              height: 2,
              color: done ? AppColors.primaryGreen : AppColors.borderGrey,
            ),
          );
        }
        final stepIndex = i ~/ 2;
        final done = _currentStep > stepIndex;
        final active = _currentStep == stepIndex;
        return Column(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: done || active
                    ? AppColors.primaryGreen
                    : AppColors.white,
                border: Border.all(
                  color: done || active
                      ? AppColors.primaryGreen
                      : AppColors.borderGrey,
                  width: 2,
                ),
              ),
              child: Center(
                child: done
                    ? const Icon(Icons.check, color: Colors.white, size: 16)
                    : Text(
                        '${stepIndex + 1}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: active ? Colors.white : AppColors.textGrey,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              steps[stepIndex],
              style: TextStyle(
                fontFamily: font,
                fontSize: 11,
                color: done || active
                    ? AppColors.primaryGreen
                    : AppColors.textGrey,
                fontWeight:
                    active ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        );
      }),
    );
  }

  // ── Step 1: Application Form ───────────────────────────────────
  Widget _buildStep1(String font) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(font, 'আবেদনফর্ম'),
          const SizedBox(height: 16),

          // Personal Info
          _sectionCard(font, 'ব্যক্তিগত তথ্য', [
            _fieldLabel(font, 'আপনার নামঃ'),
            _textField(
              controller: _touristNameCtrl,
              font: font,
              hint: 'আপনার পূর্ণ নাম লিখুন',
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'নাম দিন' : null,
            ),
            const SizedBox(height: 14),
            _fieldLabel(font, 'মোবাইল নম্বর'),
            _phoneField(font, _mobileCtrl),
            const SizedBox(height: 14),
            _fieldLabel(font, 'পেশাঃ'),
            _textField(
              controller: _occupationCtrl,
              font: font,
              hint: 'আপনার পেশা লিখুন',
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'পেশা দিন' : null,
            ),
            const SizedBox(height: 14),
            _fieldLabel(font, 'পর্যটকের ধরন'),
            const SizedBox(height: 8),
            _touristTypeSelector(font),
          ]),
          const SizedBox(height: 16),

          // Emergency Contact
          _sectionCard(font, 'জরুরি যোগাযোগ', [
            _fieldLabel(font, 'অভিভাবকের নামঃ'),
            _textField(
              controller: _guardianNameCtrl,
              font: font,
              hint: 'আপনার পূর্ণ নাম লিখুন',
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'অভিভাবকের নাম দিন' : null,
            ),
            const SizedBox(height: 14),
            _fieldLabel(font, 'অভিভাবকের মোবাইল নম্বর'),
            _phoneField(font, _guardianMobileCtrl),
          ]),
          const SizedBox(height: 16),

          // Address
          _sectionCard(font, 'ঠিকানার বিবরণ', [
            _fieldLabel(font, 'বর্তমান ঠিকানা'),
            _textField(
              controller: _presentAddressCtrl,
              font: font,
              hint: 'বর্তমান থাকার ঠিকানা লিখুন',
              maxLines: 2,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'বর্তমান ঠিকানা দিন' : null,
            ),
            const SizedBox(height: 14),
            _fieldLabel(font, 'স্থায়ী ঠিকানা'),
            _textField(
              controller: _permanentAddressCtrl,
              font: font,
              hint: 'স্থায়ী ঠিকানা লিখুন',
              maxLines: 2,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'স্থায়ী ঠিকানা দিন' : null,
            ),
            const SizedBox(height: 14),
            _fieldLabel(font, 'উৎপত্তিস্থল'),
            _textField(
              controller: _placeOfOriginCtrl,
              font: font,
              hint: 'যেখান থেকে ভ্রমণ শুরু করবেন',
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'উৎপত্তিস্থল দিন' : null,
            ),
          ]),
          const SizedBox(height: 16),

          // Travel Plan
          _sectionCard(font, 'ভ্রমণ পরিকল্পনা', [
            _fieldLabel(font, 'গন্তব্য'),
            const SizedBox(height: 6),
            _destinationDropdown(font),
            const SizedBox(height: 14),
            _fieldLabel(font, 'ভ্রমণের সময়সীমা'),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _datePicker(
                    font: font,
                    label: 'আগমন তারিখ',
                    selectedDate: _arrivalDate,
                    onTap: () => _pickDate(isArrival: true),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _datePicker(
                    font: font,
                    label: 'প্রস্থান তারিখ',
                    selectedDate: _departureDate,
                    onTap: () => _pickDate(isArrival: false),
                  ),
                ),
              ],
            ),
          ]),
          const SizedBox(height: 24),

          // Next Button
          _nextButton(font, 'এগিয়ে যান  →', _goNext),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // ── Step 2: Document Upload ────────────────────────────────────
  Widget _buildStep2(String font) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle(font, 'নথিপত্র আপলোড'),
        const SizedBox(height: 16),

        _sectionCard(font, '', [
          // NID Front
          _fieldLabel(font, 'এনআইডির সামনের অংশ'),
          const SizedBox(height: 10),
          _documentUploadBox(
            font: font,
            file: _nidFront,
            hint: 'আপনার এনআইডির সামনের দিকের পরিষ্কার ছবি আপলোড করুন',
            onTap: () => _pickImage(true),
          ),
          const SizedBox(height: 20),

          // NID Back
          _fieldLabel(font, 'এনআইডির পেছনের অংশ'),
          const SizedBox(height: 10),
          _documentUploadBox(
            font: font,
            file: _nidBack,
            hint: 'আপনার এনআইডির পেছনের দিকের পরিষ্কার ছবি আপলোড করুন',
            onTap: () => _pickImage(false),
          ),
        ]),
        const SizedBox(height: 24),

        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _goBack,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.textDark,
                  side: const BorderSide(color: AppColors.borderGrey),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                child: Text('← পূর্ববর্তী',
                    style: TextStyle(fontFamily: font, fontSize: 15)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: _nextButton(font, 'এগিয়ে যান  →', _goNext),
            ),
          ],
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  // ── Step 3: Payment ────────────────────────────────────────────
  Widget _buildStep3(String font, bool isSubmitting) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle(font, 'ফি প্রদান'),
        const SizedBox(height: 16),

        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.borderGrey),
          ),
          child: Column(
            children: [
              // Icon
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AppColors.primaryGreen.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.payment_outlined,
                    color: AppColors.primaryGreen, size: 32),
              ),
              const SizedBox(height: 16),
              Text(
                'আবেদন ফি',
                style: TextStyle(
                    fontFamily: font,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark),
              ),
              const SizedBox(height: 8),
              Text(
                'আপনার ট্রাভেল পারমিটের জন্য প্রযোজ্য ফি প্রদান করুন।',
                style: TextStyle(
                    fontFamily: font,
                    fontSize: 13,
                    color: AppColors.textGrey,
                    height: 1.5),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),

              // Fee Details
              _feeRow(font, 'আবেদন ফি', '৳ ৫০০'),
              const Divider(height: 20),
              _feeRow(font, 'প্রক্রিয়াকরণ ফি', '৳ ৫০'),
              const Divider(height: 20),
              _feeRow(font, 'মোট', '৳ ৫৫০',
                  bold: true, color: AppColors.primaryGreen),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // ── Payment Gateway Selector ──────────────────────────────
        Text(
          'পেমেন্ট মাধ্যম নির্বাচন করুন',
          style: TextStyle(
              fontFamily: font,
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textDark),
        ),
        const SizedBox(height: 12),

        Row(
          children: [
            Expanded(
              child: _gatewayCard(
                font: font,
                gateway: PaymentGateway.bkash,
                label: 'bKash',
                icon: Icons.phone_android_rounded,
                color: const Color(0xFFE2136E),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _gatewayCard(
                font: font,
                gateway: PaymentGateway.shurjopay,
                label: 'ShurjoPay',
                icon: Icons.account_balance_rounded,
                color: const Color(0xFF5C2D91),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: isSubmitting ? null : _goBack,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.textDark,
                  side: const BorderSide(color: AppColors.borderGrey),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                child: Text('← পূর্ববর্তী',
                    style: TextStyle(fontFamily: font, fontSize: 15)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: ElevatedButton(
                onPressed: isSubmitting || _selectedGateway == null
                    ? null
                    : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryGreen,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor:
                      AppColors.primaryGreen.withValues(alpha: 0.4),
                  disabledForegroundColor: Colors.white70,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                child: isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : Text('ফি প্রদান করুন',
                        style: TextStyle(
                            fontFamily: font,
                            fontSize: 15,
                            fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _gatewayCard({
    required String font,
    required PaymentGateway gateway,
    required String label,
    required IconData icon,
    required Color color,
  }) {
    final isSelected = _selectedGateway == gateway;
    return GestureDetector(
      onTap: () => setState(() => _selectedGateway = gateway),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.06) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : AppColors.borderGrey,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 10),
            Text(
              label,
              style: TextStyle(
                fontFamily: AppFonts.english,
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: isSelected ? color : AppColors.textDark,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              gateway == PaymentGateway.bkash
                  ? 'মোবাইল পেমেন্ট'
                  : 'অনলাইন পেমেন্ট',
              style: TextStyle(
                fontFamily: font,
                fontSize: 11,
                color: AppColors.textGrey,
              ),
            ),
            const SizedBox(height: 8),
            // Selection indicator
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? color : AppColors.borderGrey,
                  width: 2,
                ),
                color: isSelected ? color : Colors.transparent,
              ),
              child: isSelected
                  ? const Icon(Icons.check, color: Colors.white, size: 14)
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  // ── Shared Widgets ─────────────────────────────────────────────

  Widget _sectionTitle(String font, String title) {
    return Text(
      title,
      style: TextStyle(
          fontFamily: font,
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: AppColors.textDark),
    );
  }

  Widget _sectionCard(String font, String title, List<Widget> children) {
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
          if (title.isNotEmpty) ...[
            Text(
              title,
              style: TextStyle(
                  fontFamily: font,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textDark),
            ),
            const SizedBox(height: 14),
          ],
          ...children,
        ],
      ),
    );
  }

  Widget _fieldLabel(String font, String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        label,
        style: TextStyle(
            fontFamily: font,
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: AppColors.textDark),
      ),
    );
  }

  Widget _textField({
    required TextEditingController controller,
    required String font,
    required String hint,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
            fontFamily: font, fontSize: 13, color: AppColors.textGrey),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
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
        filled: true,
        fillColor: AppColors.white,
      ),
      style: TextStyle(fontFamily: font, fontSize: 14),
      validator: validator,
    );
  }

  Widget _phoneField(String font, TextEditingController ctrl) {
    return TextFormField(
      controller: ctrl,
      keyboardType: TextInputType.phone,
      decoration: InputDecoration(
        hintText: '17XXXXXXXX',
        hintStyle: TextStyle(
            fontFamily: font, fontSize: 13, color: AppColors.textGrey),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        prefixIcon: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🇧🇩', style: TextStyle(fontSize: 18)),
              const SizedBox(width: 4),
              Text('+880',
                  style: TextStyle(
                      fontFamily: font,
                      fontSize: 13,
                      color: AppColors.textDark,
                      fontWeight: FontWeight.w500)),
              const SizedBox(width: 4),
              Icon(Icons.arrow_drop_down,
                  color: AppColors.textGrey, size: 18),
            ],
          ),
        ),
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
        filled: true,
        fillColor: AppColors.white,
      ),
      style: TextStyle(fontFamily: font, fontSize: 14),
      validator: (v) =>
          (v == null || v.trim().isEmpty) ? 'মোবাইল নম্বর দিন' : null,
    );
  }

  Widget _touristTypeSelector(String font) {
    return Column(
      children: [
        _radioOption(font, 'অভ্যন্তরীণ পর্যটক (Domestic Tourist)', 'DOMESTIC'),
        const SizedBox(height: 8),
        _radioOption(font, 'বিদেশি পর্যটক (Foreign Tourist)', 'FOREIGN'),
      ],
    );
  }

  Widget _radioOption(String font, String label, String value) {
    final selected = _touristType == value;
    return GestureDetector(
      onTap: () => setState(() => _touristType = value),
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
                  width: 2),
            ),
            child: selected
                ? Center(
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(
                          color: AppColors.primaryGreen,
                          shape: BoxShape.circle),
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 10),
          Text(label,
              style: TextStyle(
                  fontFamily: font,
                  fontSize: 13,
                  color: selected ? AppColors.textDark : AppColors.textGrey,
                  fontWeight:
                      selected ? FontWeight.w600 : FontWeight.normal)),
        ],
      ),
    );
  }

  Widget _destinationDropdown(String font) {
    return DropdownButtonFormField<String>(
      initialValue: _destination,
      hint: Text('গন্তব্য নির্বাচন করুন',
          style: TextStyle(
              fontFamily: font, fontSize: 13, color: AppColors.textGrey)),
      decoration: InputDecoration(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
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
        filled: true,
        fillColor: AppColors.white,
      ),
      style: TextStyle(
          fontFamily: font, fontSize: 14, color: AppColors.textDark),
      icon: const Icon(Icons.keyboard_arrow_down_rounded,
          color: AppColors.textGrey),
      items: _destinations
          .map((d) => DropdownMenuItem(
              value: d,
              child: Text(d,
                  style: TextStyle(fontFamily: font, fontSize: 14))))
          .toList(),
      onChanged: (v) => setState(() => _destination = v),
    );
  }

  Widget _datePicker({
    required String font,
    required String label,
    required DateTime? selectedDate,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.borderGrey),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today_outlined,
                size: 16, color: AppColors.textGrey),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                selectedDate != null ? _formatDate(selectedDate) : label,
                style: TextStyle(
                    fontFamily: font,
                    fontSize: 12,
                    color: selectedDate != null
                        ? AppColors.textDark
                        : AppColors.textGrey),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _documentUploadBox({
    required String font,
    required XFile? file,
    required String hint,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: const Color(0xFFF8F9FA),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
              color:
                  file != null ? AppColors.primaryGreen : AppColors.borderGrey,
              width: file != null ? 1.5 : 1),
        ),
        child: file != null
            ? Column(
                children: [
                  ClipRRect(
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(9)),
                    child: Image.file(
                      File(file.path),
                      height: 160,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.check_circle,
                            color: AppColors.primaryGreen, size: 16),
                        const SizedBox(width: 6),
                        Text('ছবি নির্বাচিত হয়েছে। পরিবর্তন করতে ক্লিক করুন',
                            style: TextStyle(
                                fontFamily: font,
                                fontSize: 12,
                                color: AppColors.primaryGreen)),
                      ],
                    ),
                  ),
                ],
              )
            : Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    const Icon(Icons.cloud_upload_outlined,
                        size: 36, color: AppColors.textGrey),
                    const SizedBox(height: 8),
                    Text(hint,
                        style: TextStyle(
                            fontFamily: font,
                            fontSize: 12,
                            color: AppColors.textGrey),
                        textAlign: TextAlign.center),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: onTap,
                      icon: const Icon(Icons.image_outlined,
                          size: 16, color: AppColors.textDark),
                      label: Text('ছবি নির্বাচন করুন (JPG,PNG,PDF)',
                          style: TextStyle(
                              fontFamily: font,
                              fontSize: 12,
                              color: AppColors.textDark)),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.borderGrey),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6)),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _nextButton(String font, String label, VoidCallback onPressed) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryGreen,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: Text(label,
            style: TextStyle(
                fontFamily: font,
                fontSize: 15,
                fontWeight: FontWeight.w600)),
      ),
    );
  }

  Widget _feeRow(String font, String label, String amount,
      {bool bold = false, Color? color}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: TextStyle(
                fontFamily: font,
                fontSize: 14,
                color: color ?? AppColors.textDark,
                fontWeight: bold ? FontWeight.bold : FontWeight.normal)),
        Text(amount,
            style: TextStyle(
                fontFamily: font,
                fontSize: 14,
                color: color ?? AppColors.textDark,
                fontWeight: bold ? FontWeight.bold : FontWeight.normal)),
      ],
    );
  }
}
