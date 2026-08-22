import 'dart:convert';

class JobApplication {
  final String id;
  final String companyName;
  final String position;
  final String
  status; // 'Contoh', 'Dikirim', 'Tes / Psikotes', 'Interview HR', 'Interview User', 'Offering', 'Diterima', 'Ditolak'
  final DateTime appliedDate;
  final String? salaryOffered; // Contoh: "Rp 18.000.000 - Rp 25.000.000"
  final int? minSalary; // Numeric value untuk sorting / filtering
  final int? maxSalary;
  final String workType; // 'WFO', 'WFH', 'Hybrid'
  final String? location;
  final String?
  jobSource; // 'LinkedIn', 'Glints', 'JobStreet', 'Kalibrr', 'Email', 'Lainnya'
  final String sourcePlatform; // 'Manual', 'Glints', 'JobStreet', 'LinkedIn'
  final String? jobUrl; // URL postingan asli dari portal lowongan
  final String jobDescription; // Snapshot deskripsi/kualifikasi awal
  final String? hrContact; // Nomor WA atau email HR
  final DateTime? testDate; // Tanggal Tes / Psikotes
  final DateTime? interviewDate; // Tanggal Wawancara / Interview
  final String? notes;
  final bool isFavorite; // Status bookmark / simpan
  final bool isSampleData; // Data tutorial yang tidak boleh mengubah status.
  final String? screenshotPath; // Path file lampiran screenshot poster loker
  final String?
  companyLogoPath; // Path file custom logo / foto perusahaan yang diunggah

  JobApplication({
    required this.id,
    required this.companyName,
    required this.position,
    required this.status,
    required this.appliedDate,
    this.salaryOffered,
    this.minSalary,
    this.maxSalary,
    required String workType,
    this.location,
    this.jobSource,
    this.sourcePlatform = 'Manual',
    this.jobUrl,
    required this.jobDescription,
    this.hrContact,
    this.testDate,
    this.interviewDate,
    this.notes,
    this.isFavorite = false,
    this.isSampleData = false,
    this.screenshotPath,
    this.companyLogoPath,
  }) : workType = normalizeWorkType(workType);

  bool get needsFollowup =>
      status == 'Dikirim' && DateTime.now().difference(appliedDate).inDays >= 7;

  static String normalizeWorkType(String? rawWorkType) {
    switch (rawWorkType?.trim().toLowerCase()) {
      case 'wfh':
      case 'remote':
      case 'work from home':
        return 'WFH';
      case 'hybrid':
        return 'Hybrid';
      case 'on-site':
      case 'onsite':
      case 'on site':
      case 'wfo':
      default:
        return 'WFO';
    }
  }

  JobApplication copyWith({
    String? id,
    String? companyName,
    String? position,
    String? status,
    DateTime? appliedDate,
    String? salaryOffered,
    int? minSalary,
    int? maxSalary,
    String? workType,
    String? location,
    String? jobSource,
    String? sourcePlatform,
    String? jobUrl,
    String? jobDescription,
    String? hrContact,
    DateTime? testDate,
    DateTime? interviewDate,
    String? notes,
    bool? isFavorite,
    bool? isSampleData,
    String? screenshotPath,
    String? companyLogoPath,
  }) {
    return JobApplication(
      id: id ?? this.id,
      companyName: companyName ?? this.companyName,
      position: position ?? this.position,
      status: status ?? this.status,
      appliedDate: appliedDate ?? this.appliedDate,
      salaryOffered: salaryOffered ?? this.salaryOffered,
      minSalary: minSalary ?? this.minSalary,
      maxSalary: maxSalary ?? this.maxSalary,
      workType: workType ?? this.workType,
      location: location ?? this.location,
      jobSource: jobSource ?? this.jobSource,
      sourcePlatform: sourcePlatform ?? this.sourcePlatform,
      jobUrl: jobUrl ?? this.jobUrl,
      jobDescription: jobDescription ?? this.jobDescription,
      hrContact: hrContact ?? this.hrContact,
      testDate: testDate ?? this.testDate,
      interviewDate: interviewDate ?? this.interviewDate,
      notes: notes ?? this.notes,
      isFavorite: isFavorite ?? this.isFavorite,
      isSampleData: isSampleData ?? this.isSampleData,
      screenshotPath: screenshotPath ?? this.screenshotPath,
      companyLogoPath: companyLogoPath ?? this.companyLogoPath,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'companyName': companyName,
      'position': position,
      'status': status == 'HR Screening' ? 'Interview HR' : status,
      'appliedDate': appliedDate.toIso8601String(),
      'salaryOffered': salaryOffered,
      'minSalary': minSalary,
      'maxSalary': maxSalary,
      'workType': normalizeWorkType(workType),
      'location': location,
      'jobSource': jobSource,
      'sourcePlatform': sourcePlatform,
      'jobUrl': jobUrl,
      'jobDescription': jobDescription,
      'hrContact': hrContact,
      'testDate': testDate?.toIso8601String(),
      'interviewDate': interviewDate?.toIso8601String(),
      'notes': notes,
      'isFavorite': isFavorite,
      'isSampleData': isSampleData,
      'screenshotPath': screenshotPath,
      'companyLogoPath': companyLogoPath,
    };
  }

  factory JobApplication.fromMap(Map<String, dynamic> map) {
    final rawStatus = map['status'] ?? 'Dikirim';
    final cleanStatus = rawStatus == 'HR Screening'
        ? 'Interview HR'
        : rawStatus;

    return JobApplication(
      id: map['id'] ?? '',
      companyName: map['companyName'] ?? '',
      position: map['position'] ?? '',
      status: cleanStatus,
      appliedDate: map['appliedDate'] != null
          ? (DateTime.tryParse(map['appliedDate']) ?? DateTime.now())
          : DateTime.now(),
      salaryOffered: map['salaryOffered'],
      minSalary: map['minSalary'] is int ? map['minSalary'] : null,
      maxSalary: map['maxSalary'] is int ? map['maxSalary'] : null,
      workType: normalizeWorkType(map['workType']?.toString()),
      location: map['location'],
      jobSource: map['jobSource'],
      sourcePlatform: map['sourcePlatform'] ?? 'Manual',
      jobUrl: map['jobUrl'],
      jobDescription: map['jobDescription'] ?? '',
      hrContact: map['hrContact'],
      testDate: map['testDate'] != null
          ? DateTime.tryParse(map['testDate'])
          : null,
      interviewDate: map['interviewDate'] != null
          ? DateTime.tryParse(map['interviewDate'])
          : null,
      notes: map['notes'],
      isFavorite: map['isFavorite'] ?? false,
      isSampleData: map['isSampleData'] ?? false,
      screenshotPath: map['screenshotPath'],
      companyLogoPath: map['companyLogoPath'],
    );
  }

  String toJson() => jsonEncode(toMap());

  factory JobApplication.fromJson(String source) =>
      JobApplication.fromMap(jsonDecode(source));
}
