import 'dart:convert';

/// Kelas untuk tipe dokumen yang didukung
class DocumentType {
  static const String idCard = 'idCard';
  static const String passport = 'passport';
  static const String drivingLicense = 'drivingLicense';
  static const String birthCertificate = 'birthCertificate';
  static const String socialSecurityCard = 'socialSecurityCard';
  static const String taxId = 'taxId';
  static const String residencePermit = 'residencePermit';
  static const String visaDocument = 'visaDocument';
  static const String medicalRecord = 'medicalRecord';
  static const String educationCertificate = 'educationCertificate';
  static const String marriageCertificate = 'marriageCertificate';
  static const String other = 'other'; // Menambahkan tipe other

  /// Mendapatkan nama tampilan untuk tipe dokumen
  static String getDisplayName(String type) {
    switch (type) {
      case idCard:
        return 'Kartu Identitas';
      case passport:
        return 'Paspor';
      case drivingLicense:
        return 'SIM';
      case birthCertificate:
        return 'Akta Kelahiran';
      case socialSecurityCard:
        return 'Kartu BPJS';
      case taxId:
        return 'NPWP';
      case residencePermit:
        return 'Izin Tinggal';
      case visaDocument:
        return 'Visa';
      case medicalRecord:
        return 'Rekam Medis';
      case educationCertificate:
        return 'Ijazah';
      case marriageCertificate:
        return 'Akta Pernikahan';
      default:
        return 'Dokumen Lainnya';
    }
  }

  /// Mendapatkan semua tipe dokumen yang tersedia
  static List<String> getAllTypes() {
    return [
      idCard,
      passport,
      drivingLicense,
      birthCertificate,
      socialSecurityCard,
      taxId,
      residencePermit,
      visaDocument,
      medicalRecord,
      educationCertificate,
      marriageCertificate,
    ];
  }
}

/// Kelas untuk dokumen identitas
class Document {
  String id;
  String name;
  String type;
  Map<String, dynamic> fields;
  bool isVerified;
  String? verifiedBy;
  DateTime? verifiedAt;
  DateTime createdAt;
  DateTime updatedAt;
  String? ipfsCid; // IPFS Content ID untuk data terenkripsi
  String? principalId; // Internet Computer principal ID (pemilik)
  Map<String, dynamic>? metadata; // Metadata tambahan
  String? txHash; // Transaction hash dari blockchain
  String? owner; // Pemilik dokumen

  Document({
    required this.id,
    required this.name,
    required this.type,
    required this.fields,
    this.isVerified = false,
    this.verifiedBy,
    this.verifiedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.ipfsCid,
    this.principalId,
    this.metadata,
    this.txHash,
    this.owner,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  /// Membuat dokumen kosong
  factory Document.empty() {
    return Document(
      id: '',
      name: '',
      type: '',
      fields: {},
    );
  }

  /// Konversi dokumen ke JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'fields': fields,
      'isVerified': isVerified,
      'verifiedBy': verifiedBy,
      'verifiedAt': verifiedAt?.millisecondsSinceEpoch,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
      'ipfsCid': ipfsCid,
      'principalId': principalId,
      'metadata': metadata,
      'txHash': txHash,
      'owner': owner,
    };
  }

  /// Membuat dokumen dari JSON
  factory Document.fromJson(Map<String, dynamic> json) {
    return Document(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      type: json['type'] ?? '',
      fields: json['fields'] ?? {},
      isVerified: json['isVerified'] ?? false,
      verifiedBy: json['verifiedBy'],
      verifiedAt: json['verifiedAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['verifiedAt'])
          : null,
      createdAt: json['createdAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['createdAt'])
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['updatedAt'])
          : DateTime.now(),
      ipfsCid: json['ipfsCid'],
      principalId: json['principalId'],
      metadata: json['metadata'],
      txHash: json['txHash'],
      owner: json['owner'],
    );
  }

  /// Membuat dokumen dari string JSON
  factory Document.fromJsonString(String jsonString) {
    return Document.fromJson(jsonDecode(jsonString));
  }

  /// Mendapatkan string JSON dari dokumen
  String toJsonString() {
    return jsonEncode(toJson());
  }

  /// Membuat salinan dokumen dengan beberapa properti yang diubah
  Document copyWith({
    String? id,
    String? name,
    String? type,
    Map<String, dynamic>? fields,
    bool? isVerified,
    String? verifiedBy,
    DateTime? verifiedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? ipfsCid,
    String? principalId,
    Map<String, dynamic>? metadata,
    String? txHash,
    String? owner,
  }) {
    return Document(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      fields: fields ?? this.fields,
      isVerified: isVerified ?? this.isVerified,
      verifiedBy: verifiedBy ?? this.verifiedBy,
      verifiedAt: verifiedAt ?? this.verifiedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      ipfsCid: ipfsCid ?? this.ipfsCid,
      principalId: principalId ?? this.principalId,
      metadata: metadata ?? this.metadata,
      txHash: txHash ?? this.txHash,
      owner: owner ?? this.owner,
    );
  }
}

// Document verification status
enum VerificationStatus {
  notVerified,
  pending,
  verified,
}

// Document token for selective disclosure
class DocumentToken {
  final String tokenId;
  final String documentId;
  final Map<String, dynamic> data;
  final DateTime createdAt;
  final DateTime expiryTime;

  DocumentToken({
    required this.tokenId,
    required this.documentId,
    required this.data,
    required this.createdAt,
    required this.expiryTime,
  });

  bool get isValid => DateTime.now().isBefore(expiryTime);

  // Convert token to map for JSON serialization
  Map<String, dynamic> toJson() {
    return {
      'tokenId': tokenId,
      'documentId': documentId,
      'data': data,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'expiryTime': expiryTime.millisecondsSinceEpoch,
    };
  }

  // Create token from JSON map
  factory DocumentToken.fromJson(Map<String, dynamic> json) {
    return DocumentToken(
      tokenId: json['tokenId'],
      documentId: json['documentId'],
      data: Map<String, dynamic>.from(json['data']),
      createdAt: DateTime.fromMillisecondsSinceEpoch(json['createdAt']),
      expiryTime: DateTime.fromMillisecondsSinceEpoch(json['expiryTime']),
    );
  }
}
