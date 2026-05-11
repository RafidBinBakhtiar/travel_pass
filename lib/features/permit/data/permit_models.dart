class PermitDocument {
  final String name;
  final String url;

  PermitDocument({required this.name, required this.url});

  Map<String, dynamic> toJson() => {'name': name, 'url': url};

  factory PermitDocument.fromJson(Map<String, dynamic> json) =>
      PermitDocument(name: json['name'] as String, url: json['url'] as String);
}

class CreateApplicationRequest {
  final String touristName;
  final String mobileNumber;
  final String guardianName;
  final String guardianMobile;
  final String permanentAddress;
  final String presentAddress;
  final String occupation;
  final String placeOfOrigin;
  final String destination;
  final String arrivalDate;   // ISO8601
  final String departureDate; // ISO8601
  final String touristType;   // 'DOMESTIC' | 'FOREIGN'
  final List<PermitDocument> documents;

  CreateApplicationRequest({
    required this.touristName,
    required this.mobileNumber,
    required this.guardianName,
    required this.guardianMobile,
    required this.permanentAddress,
    required this.presentAddress,
    required this.occupation,
    required this.placeOfOrigin,
    required this.destination,
    required this.arrivalDate,
    required this.departureDate,
    required this.touristType,
    required this.documents,
  });

  Map<String, dynamic> toJson() => {
        'touristName': touristName,
        'mobileNumber': mobileNumber,
        'guardianName': guardianName,
        'guardianMobile': guardianMobile,
        'permanentAddress': permanentAddress,
        'presentAddress': presentAddress,
        'occupation': occupation,
        'placeOfOrigin': placeOfOrigin,
        'destination': destination,
        'arrivalDate': arrivalDate,
        'departureDate': departureDate,
        'touristType': touristType,
        'documents': documents.map((d) => d.toJson()).toList(),
      };
}

class PermitApplication {
  final int id;
  final String? applicationId;
  final String touristName;
  final String mobileNumber;
  final String destination;
  final String arrivalDate;
  final String departureDate;
  final String status;
  final String createdAt;
  final List<PermitDocument> documents;

  PermitApplication({
    required this.id,
    this.applicationId,
    required this.touristName,
    required this.mobileNumber,
    required this.destination,
    required this.arrivalDate,
    required this.departureDate,
    required this.status,
    required this.createdAt,
    required this.documents,
  });

  factory PermitApplication.fromJson(Map<String, dynamic> json) {
    return PermitApplication(
      id: json['id'] as int? ?? 0,
      applicationId: json['applicationId'] as String?,
      touristName: json['touristName'] as String? ?? '',
      mobileNumber: json['mobileNumber'] as String? ?? '',
      destination: json['destination'] as String? ?? '',
      arrivalDate: json['arrivalDate'] as String? ?? '',
      departureDate: json['departureDate'] as String? ?? '',
      status: json['status'] as String? ?? 'DRAFT',
      createdAt: json['createdAt'] as String? ?? '',
      documents: (json['documents'] as List<dynamic>?)
              ?.map((d) => PermitDocument.fromJson(d as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  String get displayId => applicationId ?? id.toString().padLeft(6, '0');

  String get formattedArrival => _formatDate(arrivalDate);
  String get formattedDeparture => _formatDate(departureDate);
  String get formattedCreatedAt => _formatDate(createdAt);

  String get travelPeriod => '${_formatDateShort(arrivalDate)} to ${_formatDateShort(departureDate)}';

  static String _formatDate(String isoDate) {
    if (isoDate.isEmpty) return '—';
    try {
      final dt = DateTime.parse(isoDate).toLocal();
      return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year.toString().substring(2)}';
    } catch (_) {
      return isoDate;
    }
  }

  static String _formatDateShort(String isoDate) => _formatDate(isoDate);
}

// Step-tracking enum for the 3-step wizard
enum ApplicationStep { applicationForm, documentUpload, payment }

// Application Status Enum
enum ApplicationStatus {
  draft,
  submitted,
  feePending,
  underReview,
  approved,
  rejected;

  static ApplicationStatus fromString(String value) {
    return switch (value.toUpperCase()) {
      'DRAFT' => ApplicationStatus.draft,
      'SUBMITTED' => ApplicationStatus.submitted,
      'FEE_PENDING' => ApplicationStatus.feePending,
      'UNDER_REVIEW' => ApplicationStatus.underReview,
      'APPROVED' => ApplicationStatus.approved,
      'REJECTED' => ApplicationStatus.rejected,
      _ => ApplicationStatus.draft,
    };
  }

  String toApiString() {
    return switch (this) {
      ApplicationStatus.draft => 'DRAFT',
      ApplicationStatus.submitted => 'SUBMITTED',
      ApplicationStatus.feePending => 'FEE_PENDING',
      ApplicationStatus.underReview => 'UNDER_REVIEW',
      ApplicationStatus.approved => 'APPROVED',
      ApplicationStatus.rejected => 'REJECTED',
    };
  }

  bool get isCompleted =>
      this == ApplicationStatus.approved || this == ApplicationStatus.rejected;
  bool get isPending =>
      this == ApplicationStatus.draft || this == ApplicationStatus.submitted;
  bool get needsPayment => this == ApplicationStatus.feePending;
  bool get isUnderReview => this == ApplicationStatus.underReview;
  bool get isApproved => this == ApplicationStatus.approved;
  bool get isRejected => this == ApplicationStatus.rejected;
}

// Application Response Model from API
class ApplicationResponse {
  final int id;
  final String applicationId;
  final String touristName;
  final String mobileNumber;
  final String guardianName;
  final String guardianMobile;
  final String presentAddress;
  final String occupation;
  final String destination;
  final String arrivalDate;
  final String departureDate;
  final String touristType;
  final ApplicationStatus status;
  final String createdAt;
  final String? updatedAt;
  final List<PermitDocument> documents;

  ApplicationResponse({
    required this.id,
    required this.applicationId,
    required this.touristName,
    required this.mobileNumber,
    required this.guardianName,
    required this.guardianMobile,
    required this.presentAddress,
    required this.occupation,
    required this.destination,
    required this.arrivalDate,
    required this.departureDate,
    required this.touristType,
    required this.status,
    required this.createdAt,
    this.updatedAt,
    required this.documents,
  });

  factory ApplicationResponse.fromJson(Map<String, dynamic> json) {
    return ApplicationResponse(
      id: json['id'] as int? ?? 0,
      applicationId: json['applicationId'] as String? ?? '',
      touristName: json['touristName'] as String? ?? '',
      mobileNumber: json['mobileNumber'] as String? ?? '',
      guardianName: json['guardianName'] as String? ?? '',
      guardianMobile: json['guardianMobile'] as String? ?? '',
      presentAddress: json['presentAddress'] as String? ?? '',
      occupation: json['occupation'] as String? ?? '',
      destination: json['destination'] as String? ?? '',
      arrivalDate: json['arrivalDate'] as String? ?? '',
      departureDate: json['departureDate'] as String? ?? '',
      touristType: json['touristType'] as String? ?? 'DOMESTIC',
      status: ApplicationStatus.fromString(
        json['status'] as String? ?? 'DRAFT',
      ),
      createdAt: json['createdAt'] as String? ?? '',
      updatedAt: json['updatedAt'] as String?,
      documents: (json['documents'] as List<dynamic>?)
              ?.map((d) => PermitDocument.fromJson(d as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  String get displayId => applicationId.padLeft(6, '0');
  String get formattedArrival => _formatDate(arrivalDate);
  String get formattedDeparture => _formatDate(departureDate);
  String get travelPeriod =>
      '${_formatDateShort(arrivalDate)} to ${_formatDateShort(departureDate)}';

  static String _formatDate(String isoDate) {
    if (isoDate.isEmpty) return '—';
    try {
      final dt = DateTime.parse(isoDate).toLocal();
      return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year.toString().substring(2)}';
    } catch (_) {
      return isoDate;
    }
  }

  static String _formatDateShort(String isoDate) => _formatDate(isoDate);
}

// Payment Model
class PaymentModel {
  final int id;
  final int applicationId;
  final double amount;
  final String currency;
  final String paymentId;
  final String status; // PENDING, COMPLETED, FAILED, CANCELLED
  final String createdAt;
  final String? completedAt;

  PaymentModel({
    required this.id,
    required this.applicationId,
    required this.amount,
    required this.currency,
    required this.paymentId,
    required this.status,
    required this.createdAt,
    this.completedAt,
  });

  factory PaymentModel.fromJson(Map<String, dynamic> json) {
    return PaymentModel(
      id: json['id'] as int? ?? 0,
      applicationId: json['applicationId'] as int? ?? 0,
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      currency: json['currency'] as String? ?? 'BDT',
      paymentId: json['paymentId'] as String? ?? '',
      status: json['status'] as String? ?? 'PENDING',
      createdAt: json['createdAt'] as String? ?? '',
      completedAt: json['completedAt'] as String?,
    );
  }

  bool get isPending => status == 'PENDING';
  bool get isCompleted => status == 'COMPLETED';
  bool get isFailed => status == 'FAILED';
  bool get isCancelled => status == 'CANCELLED';
}

// Filter Model for All Permits Screen
class PermitFilter {
  final String? searchQuery;
  final List<ApplicationStatus>? statuses;
  final DateTime? startDate;
  final DateTime? endDate;

  PermitFilter({
    this.searchQuery,
    this.statuses,
    this.startDate,
    this.endDate,
  });

  PermitFilter copyWith({
    String? searchQuery,
    List<ApplicationStatus>? statuses,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    return PermitFilter(
      searchQuery: searchQuery ?? this.searchQuery,
      statuses: statuses ?? this.statuses,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
    );
  }

  bool get isEmpty =>
      (searchQuery == null || searchQuery!.isEmpty) &&
      (statuses == null || statuses!.isEmpty) &&
      startDate == null &&
      endDate == null;
}

// Profile Update Model
class ProfileUpdateRequest {
  final String fullName;
  final String email;
  final String phone;
  final String touristType;

  ProfileUpdateRequest({
    required this.fullName,
    required this.email,
    required this.phone,
    required this.touristType,
  });

  Map<String, dynamic> toJson() => {
        'fullName': fullName,
        'email': email,
        'phone': phone,
        'touristType': touristType,
      };
}
