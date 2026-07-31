import 'dart:convert';

class JobApplication {
  final String id;
  final String companyName;
  final String position;
  final String
  status; // 'Dikirim', 'HR Screening', 'Tes / Psikotes', 'Interview HR', 'Interview User', 'Offering', 'Diterima', 'Ditolak'
  final DateTime appliedDate;
  final String? salaryOffered;
  final String workType; // 'WFO', 'WFH', 'Hybrid'
  final String? location;
  final String?
  jobSource; // 'LinkedIn', 'Glints', 'JobStreet', 'Kalibrr', 'Email', 'Lainnya'
  final String jobDescription; // Snapshot deskripsi/kualifikasi awal
  final String? hrContact; // Nomor WA atau email HR
  final DateTime? interviewDate;
  final String? notes;
  final bool isFavorite;

  JobApplication({
    required this.id,
    required this.companyName,
    required this.position,
    required this.status,
    required this.appliedDate,
    this.salaryOffered,
    required this.workType,
    this.location,
    this.jobSource,
    required this.jobDescription,
    this.hrContact,
    this.interviewDate,
    this.notes,
    this.isFavorite = false,
  });

  JobApplication copyWith({
    String? id,
    String? companyName,
    String? position,
    String? status,
    DateTime? appliedDate,
    String? salaryOffered,
    String? workType,
    String? location,
    String? jobSource,
    String? jobDescription,
    String? hrContact,
    DateTime? interviewDate,
    String? notes,
    bool? isFavorite,
  }) {
    return JobApplication(
      id: id ?? this.id,
      companyName: companyName ?? this.companyName,
      position: position ?? this.position,
      status: status ?? this.status,
      appliedDate: appliedDate ?? this.appliedDate,
      salaryOffered: salaryOffered ?? this.salaryOffered,
      workType: workType ?? this.workType,
      location: location ?? this.location,
      jobSource: jobSource ?? this.jobSource,
      jobDescription: jobDescription ?? this.jobDescription,
      hrContact: hrContact ?? this.hrContact,
      interviewDate: interviewDate ?? this.interviewDate,
      notes: notes ?? this.notes,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'companyName': companyName,
      'position': position,
      'status': status,
      'appliedDate': appliedDate.toIso8601String(),
      'salaryOffered': salaryOffered,
      'workType': workType,
      'location': location,
      'jobSource': jobSource,
      'jobDescription': jobDescription,
      'hrContact': hrContact,
      'interviewDate': interviewDate?.toIso8601String(),
      'notes': notes,
      'isFavorite': isFavorite,
    };
  }

  factory JobApplication.fromMap(Map<String, dynamic> map) {
    return JobApplication(
      id: map['id'] ?? '',
      companyName: map['companyName'] ?? '',
      position: map['position'] ?? '',
      status: map['status'] ?? 'Dikirim',
      appliedDate: map['appliedDate'] != null
          ? DateTime.parse(map['appliedDate'])
          : DateTime.now(),
      salaryOffered: map['salaryOffered'],
      workType: map['workType'] ?? 'WFO',
      location: map['location'],
      jobSource: map['jobSource'],
      jobDescription: map['jobDescription'] ?? '',
      hrContact: map['hrContact'],
      interviewDate: map['interviewDate'] != null
          ? DateTime.parse(map['interviewDate'])
          : null,
      notes: map['notes'],
      isFavorite: map['isFavorite'] ?? false,
    );
  }

  String toJson() => jsonEncode(toMap());

  factory JobApplication.fromJson(String source) =>
      JobApplication.fromMap(jsonDecode(source));
}
