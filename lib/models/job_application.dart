import 'dart:convert';

/// One immutable point in a recruitment process.  Keeping the event separate
/// from the current status lets a user answer both "where am I now?" and
/// "what actually happened?" without overwriting earlier information.
class RecruitmentEvent {
  final String id;
  final String type;
  final String title;
  final DateTime occurredAt;
  final DateTime? scheduledAt;
  final String? notes;
  final String? outcome;

  RecruitmentEvent({
    required this.id,
    required this.type,
    required this.title,
    required this.occurredAt,
    this.scheduledAt,
    this.notes,
    this.outcome,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'type': type,
    'title': title,
    'occurredAt': occurredAt.toIso8601String(),
    'scheduledAt': scheduledAt?.toIso8601String(),
    'notes': notes,
    'outcome': outcome,
  };

  factory RecruitmentEvent.fromMap(Map<String, dynamic> map) {
    final occurredAt = DateTime.tryParse(map['occurredAt']?.toString() ?? '');
    return RecruitmentEvent(
      id: map['id']?.toString() ?? '',
      type: map['type']?.toString() ?? 'catatan',
      title: map['title']?.toString() ?? 'Pembaruan proses',
      occurredAt: occurredAt ?? DateTime.now(),
      scheduledAt: DateTime.tryParse(map['scheduledAt']?.toString() ?? ''),
      notes: map['notes']?.toString(),
      outcome: map['outcome']?.toString(),
    );
  }
}

/// A recruiter or hiring contact.  The legacy [hrContact] field remains
/// available and is automatically exposed as a contact when old records are
/// read, so no existing address or number disappears during migration.
class RecruiterContact {
  final String id;
  final String name;
  final String role;
  final String channel;
  final String value;
  final String? notes;

  const RecruiterContact({
    required this.id,
    required this.name,
    required this.role,
    required this.channel,
    required this.value,
    this.notes,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'role': role,
    'channel': channel,
    'value': value,
    'notes': notes,
  };

  factory RecruiterContact.fromMap(Map<String, dynamic> map) =>
      RecruiterContact(
        id: map['id']?.toString() ?? '',
        name: map['name']?.toString() ?? 'Kontak rekrutmen',
        role: map['role']?.toString() ?? 'Recruiter',
        channel: map['channel']?.toString() ?? 'Lainnya',
        value: map['value']?.toString() ?? '',
        notes: map['notes']?.toString(),
      );
}

/// Metadata for an attachment owned by a job.  The three old attachment
/// fields remain supported because their file lifecycle is already managed by
/// the provider; this model is for new, typed attachments going forward.
class JobAttachment {
  final String id;
  final String type;
  final String name;
  final String path;
  final DateTime createdAt;

  const JobAttachment({
    required this.id,
    required this.type,
    required this.name,
    required this.path,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'type': type,
    'name': name,
    'path': path,
    'createdAt': createdAt.toIso8601String(),
  };

  factory JobAttachment.fromMap(Map<String, dynamic> map) => JobAttachment(
    id: map['id']?.toString() ?? '',
    type: map['type']?.toString() ?? 'dokumen',
    name: map['name']?.toString() ?? 'Lampiran',
    path: map['path']?.toString() ?? '',
    createdAt:
        DateTime.tryParse(map['createdAt']?.toString() ?? '') ?? DateTime.now(),
  );
}

/// Structured offer information avoids relying on a display-only salary
/// string when the user needs to compare an offer or decide before a deadline.
class OfferDetails {
  final int? baseSalary;
  final int? takeHomePay;
  final String period;
  final String compensationNotes;
  final DateTime? decisionDeadline;
  final DateTime? startDate;

  const OfferDetails({
    this.baseSalary,
    this.takeHomePay,
    this.period = 'Bulanan',
    this.compensationNotes = '',
    this.decisionDeadline,
    this.startDate,
  });

  Map<String, dynamic> toMap() => {
    'baseSalary': baseSalary,
    'takeHomePay': takeHomePay,
    'period': period,
    'compensationNotes': compensationNotes,
    'decisionDeadline': decisionDeadline?.toIso8601String(),
    'startDate': startDate?.toIso8601String(),
  };

  factory OfferDetails.fromMap(Map<String, dynamic> map) => OfferDetails(
    baseSalary: _asInt(map['baseSalary']),
    takeHomePay: _asInt(map['takeHomePay']),
    period: map['period']?.toString() ?? 'Bulanan',
    compensationNotes: map['compensationNotes']?.toString() ?? '',
    decisionDeadline: DateTime.tryParse(
      map['decisionDeadline']?.toString() ?? '',
    ),
    startDate: DateTime.tryParse(map['startDate']?.toString() ?? ''),
  );
}

int? _asInt(dynamic value) => value is int ? value : int.tryParse('$value');

List<T> _readMapList<T>(dynamic value, T Function(Map<String, dynamic>) read) {
  if (value is! List) return const [];
  return value
      .whereType<Map>()
      .map((item) => read(Map<String, dynamic>.from(item)))
      .where((item) {
        if (item is RecruitmentEvent) return item.id.isNotEmpty;
        if (item is RecruiterContact) return item.value.isNotEmpty;
        if (item is JobAttachment) return item.path.isNotEmpty;
        return true;
      })
      .toList(growable: false);
}

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
  final String? pdfCvPath; // Path file dokumen PDF CV yang dilampirkan
  final DateTime createdAt;
  final DateTime updatedAt;
  final String priority; // 'Rendah', 'Normal', 'Tinggi'
  final bool isTargetCompany;
  final List<String> labels;
  final DateTime? nextActionAt;
  final String? nextActionType;
  final String? nextActionNote;
  final DateTime? lastFollowUpAt;
  final int followUpCount;
  final String? outcomeReason;
  final String? employmentType;
  final String? seniority;
  final DateTime? applicationDeadline;
  final List<String> skills;
  final List<String> benefits;
  final List<RecruitmentEvent> recruitmentEvents;
  final List<RecruiterContact> recruiterContacts;
  final List<JobAttachment> attachments;
  final OfferDetails? offerDetails;

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
    this.pdfCvPath,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.priority = 'Normal',
    this.isTargetCompany = false,
    List<String>? labels,
    this.nextActionAt,
    this.nextActionType,
    this.nextActionNote,
    this.lastFollowUpAt,
    this.followUpCount = 0,
    this.outcomeReason,
    this.employmentType,
    this.seniority,
    this.applicationDeadline,
    List<String>? skills,
    List<String>? benefits,
    List<RecruitmentEvent>? recruitmentEvents,
    List<RecruiterContact>? recruiterContacts,
    List<JobAttachment>? attachments,
    this.offerDetails,
  }) : createdAt = createdAt ?? appliedDate,
       updatedAt = updatedAt ?? createdAt ?? appliedDate,
       labels = List.unmodifiable(labels ?? const []),
       skills = List.unmodifiable(skills ?? const []),
       benefits = List.unmodifiable(benefits ?? const []),
       recruitmentEvents = List.unmodifiable(recruitmentEvents ?? const []),
       recruiterContacts = List.unmodifiable(recruiterContacts ?? const []),
       attachments = List.unmodifiable(attachments ?? const []),
       workType = normalizeWorkType(workType);

  int get daysSinceApplied => DateTime.now().difference(appliedDate).inDays;

  bool get isGhosted => status == 'Dikirim' && daysSinceApplied >= 14;

  bool get needsFollowup => status == 'Dikirim' && daysSinceApplied >= 7;

  bool get hasNextAction => nextActionAt != null && nextActionType != null;

  List<RecruiterContact> get effectiveRecruiterContacts {
    if (recruiterContacts.isNotEmpty ||
        hrContact == null ||
        hrContact!.trim().isEmpty) {
      return recruiterContacts;
    }
    return [
      RecruiterContact(
        id: 'legacy_hr_contact',
        name: 'Kontak rekrutmen',
        role: 'Recruiter',
        channel: hrContact!.contains('@') ? 'Email' : 'WhatsApp',
        value: hrContact!,
      ),
    ];
  }

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
    String? pdfCvPath,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? priority,
    bool? isTargetCompany,
    List<String>? labels,
    DateTime? nextActionAt,
    String? nextActionType,
    String? nextActionNote,
    bool clearNextAction = false,
    DateTime? lastFollowUpAt,
    int? followUpCount,
    String? outcomeReason,
    String? employmentType,
    String? seniority,
    DateTime? applicationDeadline,
    List<String>? skills,
    List<String>? benefits,
    List<RecruitmentEvent>? recruitmentEvents,
    List<RecruiterContact>? recruiterContacts,
    List<JobAttachment>? attachments,
    OfferDetails? offerDetails,
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
      pdfCvPath: pdfCvPath ?? this.pdfCvPath,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      priority: priority ?? this.priority,
      isTargetCompany: isTargetCompany ?? this.isTargetCompany,
      labels: labels ?? this.labels,
      nextActionAt: clearNextAction
          ? null
          : (nextActionAt ?? this.nextActionAt),
      nextActionType: clearNextAction
          ? null
          : (nextActionType ?? this.nextActionType),
      nextActionNote: clearNextAction
          ? null
          : (nextActionNote ?? this.nextActionNote),
      lastFollowUpAt: lastFollowUpAt ?? this.lastFollowUpAt,
      followUpCount: followUpCount ?? this.followUpCount,
      outcomeReason: outcomeReason ?? this.outcomeReason,
      employmentType: employmentType ?? this.employmentType,
      seniority: seniority ?? this.seniority,
      applicationDeadline: applicationDeadline ?? this.applicationDeadline,
      skills: skills ?? this.skills,
      benefits: benefits ?? this.benefits,
      recruitmentEvents: recruitmentEvents ?? this.recruitmentEvents,
      recruiterContacts: recruiterContacts ?? this.recruiterContacts,
      attachments: attachments ?? this.attachments,
      offerDetails: offerDetails ?? this.offerDetails,
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
      'pdfCvPath': pdfCvPath,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'priority': priority,
      'isTargetCompany': isTargetCompany,
      'labels': labels,
      'nextActionAt': nextActionAt?.toIso8601String(),
      'nextActionType': nextActionType,
      'nextActionNote': nextActionNote,
      'lastFollowUpAt': lastFollowUpAt?.toIso8601String(),
      'followUpCount': followUpCount,
      'outcomeReason': outcomeReason,
      'employmentType': employmentType,
      'seniority': seniority,
      'applicationDeadline': applicationDeadline?.toIso8601String(),
      'skills': skills,
      'benefits': benefits,
      'recruitmentEvents': recruitmentEvents
          .map((event) => event.toMap())
          .toList(),
      'recruiterContacts': effectiveRecruiterContacts
          .map((contact) => contact.toMap())
          .toList(),
      'attachments': attachments
          .map((attachment) => attachment.toMap())
          .toList(),
      'offerDetails': offerDetails?.toMap(),
    };
  }

  factory JobApplication.fromMap(Map<String, dynamic> map) {
    final rawStatus = map['status'] ?? 'Dikirim';
    final cleanStatus = rawStatus == 'HR Screening'
        ? 'Interview HR'
        : rawStatus;
    final legacyContact = map['hrContact']?.toString();
    final contacts = _readMapList(
      map['recruiterContacts'],
      RecruiterContact.fromMap,
    );
    final migratedContacts =
        contacts.isNotEmpty ||
            legacyContact == null ||
            legacyContact.trim().isEmpty
        ? contacts
        : [
            RecruiterContact(
              id: 'legacy_hr_contact',
              name: 'Kontak rekrutmen',
              role: 'Recruiter',
              channel: legacyContact.contains('@') ? 'Email' : 'WhatsApp',
              value: legacyContact,
            ),
          ];

    return JobApplication(
      id: map['id'] ?? '',
      companyName: map['companyName'] ?? '',
      position: map['position'] ?? '',
      status: cleanStatus,
      appliedDate: map['appliedDate'] != null
          ? (DateTime.tryParse(map['appliedDate']) ?? DateTime.now())
          : DateTime.now(),
      salaryOffered: map['salaryOffered'],
      minSalary: _asInt(map['minSalary']),
      maxSalary: _asInt(map['maxSalary']),
      workType: normalizeWorkType(map['workType']?.toString()),
      location: map['location'],
      jobSource: map['jobSource'],
      sourcePlatform: map['sourcePlatform'] ?? 'Manual',
      jobUrl: map['jobUrl'],
      jobDescription: map['jobDescription'] ?? '',
      hrContact: legacyContact,
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
      pdfCvPath: map['pdfCvPath'],
      createdAt: DateTime.tryParse(map['createdAt']?.toString() ?? ''),
      updatedAt: DateTime.tryParse(map['updatedAt']?.toString() ?? ''),
      priority: map['priority']?.toString() ?? 'Normal',
      isTargetCompany: map['isTargetCompany'] == true,
      labels: (map['labels'] as List? ?? const [])
          .map((item) => item.toString())
          .where((item) => item.trim().isNotEmpty)
          .toList(),
      nextActionAt: DateTime.tryParse(map['nextActionAt']?.toString() ?? ''),
      nextActionType: map['nextActionType']?.toString(),
      nextActionNote: map['nextActionNote']?.toString(),
      lastFollowUpAt: DateTime.tryParse(
        map['lastFollowUpAt']?.toString() ?? '',
      ),
      followUpCount: _asInt(map['followUpCount']) ?? 0,
      outcomeReason: map['outcomeReason']?.toString(),
      employmentType: map['employmentType']?.toString(),
      seniority: map['seniority']?.toString(),
      applicationDeadline: DateTime.tryParse(
        map['applicationDeadline']?.toString() ?? '',
      ),
      skills: (map['skills'] as List? ?? const [])
          .map((item) => item.toString())
          .where((item) => item.trim().isNotEmpty)
          .toList(),
      benefits: (map['benefits'] as List? ?? const [])
          .map((item) => item.toString())
          .where((item) => item.trim().isNotEmpty)
          .toList(),
      recruitmentEvents: _readMapList(
        map['recruitmentEvents'],
        RecruitmentEvent.fromMap,
      ),
      recruiterContacts: migratedContacts,
      attachments: _readMapList(map['attachments'], JobAttachment.fromMap),
      offerDetails: map['offerDetails'] is Map
          ? OfferDetails.fromMap(Map<String, dynamic>.from(map['offerDetails']))
          : null,
    );
  }

  String toJson() => jsonEncode(toMap());

  factory JobApplication.fromJson(String source) =>
      JobApplication.fromMap(jsonDecode(source));
}
