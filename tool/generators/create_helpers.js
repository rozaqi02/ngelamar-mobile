const fs = require('fs');

const helpersContent = `import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ngelamar/models/job_application.dart';

/// Test helper providing deterministic setup and mock fixtures for Ngelamar E2E test suite.
class E2ETestHelper {
  static Directory? _tempDir;

  static Future<void> setupE2ETestEnvironment() async {
    TestWidgetsFlutterBinding.ensureInitialized();

    _tempDir = Directory.systemTemp.createTempSync('ngelamar_e2e_test_');
    Hive.init(_tempDir!.path);

    // Mock FlutterSecureStorage with proper key-value storage
    final secureStorageData = <String, String>{
      'ngelamar_secure_user_name': 'Budi Prakoso',
      'ngelamar_secure_user_email': 'budi.prakoso@example.com',
      'ngelamar_secure_user_career_interests': '["Flutter Developer", "Mobile Engineer"]',
      'hive_encryption_key': 'test_key_32b_hex_deterministic!',
    };

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.it_nomads.com/flutter_secure_storage'),
          (MethodCall methodCall) async {
            if (methodCall.method == 'read') {
              final key = methodCall.arguments['key'] as String?;
              return secureStorageData[key];
            }
            if (methodCall.method == 'readAll') return secureStorageData;
            if (methodCall.method == 'write') {
              final key = methodCall.arguments['key'] as String?;
              final val = methodCall.arguments['value'] as String?;
              if (key != null && val != null) secureStorageData[key] = val;
              return null;
            }
            return null;
          },
        );

    // Mock local notifications
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('dexterous.com/flutter/local_notifications'),
          (MethodCall methodCall) async => null,
        );

    // Mock home widget
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('home_widget'),
          (MethodCall methodCall) async => true,
        );

    // Mock url_launcher
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/url_launcher'),
          (MethodCall methodCall) async => true,
        );

    // Mock share_plus
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/share_plus'),
          (MethodCall methodCall) async => null,
        );

    // Mock initial SharedPreferences
    SharedPreferences.setMockInitialValues({
      'user_name': 'Budi Prakoso',
      'user_email': 'budi.prakoso@example.com',
      'user_career_interests': ['Flutter Developer', 'Mobile Engineer'],
      'onboarding_done': true,
      'theme_mode': 'light',
      'user_about': 'Senior Mobile Software Engineer specializing in Flutter & Dart.',
    });
  }

  static void tearDownE2EEnvironment() {
    try {
      if (_tempDir != null && _tempDir!.existsSync()) {
        _tempDir!.deleteSync(recursive: true);
      }
    } catch (_) {}
  }

  static RecruitmentEvent createRecruitmentEvent({
    String? id,
    String type = 'interview',
    String title = 'Interview HR & User Tech',
    DateTime? occurredAt,
    DateTime? scheduledAt,
    DateTime? completedAt,
    String? notes = 'Live coding Flutter',
    String? outcome = 'Lolos tahap offering',
    int? roundNumber = 1,
    String? source = 'HR recruiter',
    bool isDeleted = false,
  }) {
    final now = DateTime.now();
    return RecruitmentEvent(
      id: id ?? 'event_\${now.millisecondsSinceEpoch}',
      type: type,
      title: title,
      occurredAt: occurredAt ?? now.subtract(const Duration(days: 1)),
      scheduledAt: scheduledAt ?? now.add(const Duration(days: 2)),
      completedAt: completedAt,
      notes: notes,
      outcome: outcome,
      roundNumber: roundNumber,
      source: source,
      isDeleted: isDeleted,
    );
  }

  static RecruiterContact createRecruiterContact({
    String? id,
    String name = 'Dewi Lestari',
    String role = 'Lead Technical Recruiter',
    String channel = 'WhatsApp',
    String value = '+628123456789',
    String? notes = 'Fast response 09:00 - 17:00 WIB',
  }) {
    return RecruiterContact(
      id: id ?? 'contact_\${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      role: role,
      channel: channel,
      value: value,
      notes: notes,
    );
  }

  static JobAttachment createAttachment({
    String? id,
    String type = 'pdf',
    String name = 'CV_Budi_Prakoso.pdf',
    String path = '/data/files/CV_Budi_Prakoso.pdf',
    DateTime? createdAt,
  }) {
    return JobAttachment(
      id: id ?? 'att_\${DateTime.now().millisecondsSinceEpoch}',
      type: type,
      name: name,
      path: path,
      createdAt: createdAt ?? DateTime.now(),
    );
  }

  static OfferDetails createOfferDetails({
    int? baseSalary = 25000000,
    int? takeHomePay = 23200000,
    String period = 'Bulanan',
    String compensationNotes = 'THR 1x, Asuransi, Bonus Kinerja',
    DateTime? decisionDeadline,
    DateTime? startDate,
  }) {
    final now = DateTime.now();
    return OfferDetails(
      baseSalary: baseSalary,
      takeHomePay: takeHomePay,
      period: period,
      compensationNotes: compensationNotes,
      decisionDeadline: decisionDeadline ?? now.add(const Duration(days: 5)),
      startDate: startDate ?? now.add(const Duration(days: 30)),
    );
  }

  static JobApplication createSampleJob({
    String? id,
    String companyName = 'PT GoTo Gojek Tokopedia Tbk',
    String position = 'Senior Flutter Developer',
    String status = 'Tersimpan',
    DateTime? appliedDate,
    DateTime? savedAt,
    String? salaryOffered = 'Rp 22.000.000 - Rp 30.000.000',
    int? minSalary = 22000000,
    int? maxSalary = 30000000,
    String workType = 'Hybrid',
    String? location = 'Jakarta Selatan',
    String? jobSource = 'LinkedIn',
    String sourcePlatform = 'LinkedIn',
    String? jobUrl = 'https://linkedin.com/jobs/view/123456',
    String jobDescription = 'Membangun fitur mobile kelas dunia dengan Flutter.',
    String? hrContact = 'Dewi Lestari (+628123456789)',
    DateTime? testDate,
    DateTime? interviewDate,
    String? notes = 'Portofolio dan GitHub siap.',
    bool isFavorite = true,
    bool isSampleData = false,
    String? screenshotPath,
    String? companyLogoPath,
    String? pdfCvPath,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? closedAt,
    String priority = 'Tinggi',
    bool isTargetCompany = true,
    List<String>? labels,
    DateTime? nextActionAt,
    String? nextActionType,
    String? nextActionNote,
    DateTime? lastFollowUpAt,
    int followUpCount = 0,
    String? outcomeReason,
    String? employmentType = 'Full-time',
    String? seniority = 'Senior',
    DateTime? applicationDeadline,
    List<String>? skills,
    List<String>? benefits,
    List<RecruitmentEvent>? recruitmentEvents,
    List<RecruiterContact>? recruiterContacts,
    List<JobAttachment>? attachments,
    OfferDetails? offerDetails,
  }) {
    final now = DateTime.now();
    return JobApplication(
      id: id ?? 'job_\${now.millisecondsSinceEpoch}_\${1000 + (now.microsecond % 9000)}',
      companyName: companyName,
      position: position,
      status: status,
      appliedDate: appliedDate ?? now.subtract(const Duration(days: 2)),
      savedAt: savedAt ?? (status == 'Tersimpan' ? now.subtract(const Duration(days: 3)) : null),
      salaryOffered: salaryOffered,
      minSalary: minSalary,
      maxSalary: maxSalary,
      workType: workType,
      location: location,
      jobSource: jobSource,
      sourcePlatform: sourcePlatform,
      jobUrl: jobUrl,
      jobDescription: jobDescription,
      hrContact: hrContact,
      testDate: testDate,
      interviewDate: interviewDate,
      notes: notes,
      isFavorite: isFavorite,
      isSampleData: isSampleData,
      screenshotPath: screenshotPath,
      companyLogoPath: companyLogoPath,
      pdfCvPath: pdfCvPath,
      createdAt: createdAt ?? now.subtract(const Duration(days: 5)),
      updatedAt: updatedAt ?? now,
      closedAt: closedAt,
      priority: priority,
      isTargetCompany: isTargetCompany,
      labels: labels ?? ['Tier 1 Tech', 'Dream Job', 'Flutter'],
      nextActionAt: nextActionAt,
      nextActionType: nextActionType,
      nextActionNote: nextActionNote,
      lastFollowUpAt: lastFollowUpAt,
      followUpCount: followUpCount,
      outcomeReason: outcomeReason,
      employmentType: employmentType,
      seniority: seniority,
      applicationDeadline: applicationDeadline,
      skills: skills ?? ['Flutter', 'Dart', 'Riverpod', 'CI/CD'],
      benefits: benefits ?? ['BPJS Kesehatan', 'Asuransi Swasta', 'Bonus Tahunan'],
      recruitmentEvents: recruitmentEvents ?? [],
      recruiterContacts: recruiterContacts ?? (hrContact != null ? [RecruiterContact(id: 'c_1', name: hrContact, role: 'Recruiter', channel: 'WhatsApp', value: '+628123456789')] : []),
      attachments: attachments ?? [],
      offerDetails: offerDetails,
    );
  }

  static List<JobApplication> generateRealisticJobs(int count) {
    final companies = ['GoTo', 'Bukalapak', 'Traveloka', 'BCA', 'Mandiri', 'Telkom', 'Shopee', 'Blibli', 'Tiket.com', 'Halodoc'];
    final roles = ['Flutter Developer', 'Backend Engineer', 'Mobile Engineer', 'UI/UX Designer', 'Product Manager'];
    final statuses = ['Tersimpan', 'Dikirim', 'Interview HR', 'Tes / Psikotes', 'Offering', 'Diterima', 'Ditolak'];
    final workTypes = ['WFO', 'WFH', 'Hybrid'];
    final cities = ['Jakarta Selatan', 'Bandung', 'Surabaya', 'Yogyakarta'];
    final now = DateTime.now();
    return List.generate(count, (index) {
      final comp = companies[index % companies.length];
      final role = roles[index % roles.length];
      final st = statuses[index % statuses.length];
      final wt = workTypes[index % workTypes.length];
      final city = cities[index % cities.length];
      final minSal = 12000000 + (index % 10) * 1500000;
      final maxSal = minSal + 5000000;
      return createSampleJob(
        id: 'job_seeded_\${index + 1}',
        companyName: '\$comp #\${index + 1}',
        position: role,
        status: st,
        workType: wt,
        location: city,
        minSalary: minSal,
        maxSalary: maxSal,
        salaryOffered: 'Rp \${minSal ~/ 1000000}.000.000 - Rp \${maxSal ~/ 1000000}.000.000',
        isFavorite: index % 3 == 0,
        appliedDate: now.subtract(Duration(days: (index % 15) + 1)),
      );
    });
  }

  static ProviderContainer createTestContainer() {
    return ProviderContainer();
  }
}
`;

fs.mkdirSync('test/e2e', { recursive: true });
fs.writeFileSync('test/e2e/e2e_test_helpers.dart', helpersContent, 'utf8');
console.log('e2e_test_helpers.dart generated successfully.');