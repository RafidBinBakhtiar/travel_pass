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
