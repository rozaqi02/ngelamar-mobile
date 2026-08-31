import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:ngelamar/services/backup_service.dart';
import 'package:ngelamar/services/spreadsheet_import_service.dart';
import 'package:ngelamar/services/text_parser_service.dart';
import 'package:ngelamar/services/salary_evaluator_service.dart';
import 'package:ngelamar/models/job_application.dart';
import 'package:ngelamar/services/notification_service.dart';
import 'package:ngelamar/services/android_home_widget_service.dart';
import 'package:ngelamar/services/pro_verification_service.dart';
import 'package:ngelamar/services/app_version_service.dart';
import 'package:ngelamar/services/job_search_service.dart';
import 'package:ngelamar/providers/job_provider.dart';

void main() {
  group('TextParserService Tests', () {
    test(
      'Should parse company, position, workType, and salary from job text',
      () {
        const sampleText = '''
We are hiring Flutter Developer at PT Tech Innovations.
Work Location: Jakarta (WFH available).
Salary: Rp 12.000.000 - Rp 15.000.000.
Requirements: Flutter, Dart, Riverpod, Firebase.
''';

        final result = TextParserService.parseJobText(sampleText);
        expect(result.position, contains('Flutter Developer'));
        expect(result.companyName, contains('PT Tech Innovations'));
        expect(result.workType, equals('WFH'));
        expect(result.salary, contains('12.000.000'));
        expect(result.salary, contains('15.000.000'));
      },
    );

    test('keeps salary ranges with Rp on both sides', () {
      const sample =
          'Gaji: Rp 12.000.000 - Rp 15.000.000 per bulan di PT Mandiri.';
      final result = TextParserService.parseJobText(sample);
      expect(result.salary, contains('12.000.000'));
      expect(result.salary, contains('15.000.000'));
      expect(result.companyName, contains('PT Mandiri'));
    });

    test('reads Indonesian job titles and labeled company fields', () {
      const sample = '''
Perusahaan: Gojek
Posisi: Content Creator
Penempatan: Surabaya
''';
      final result = TextParserService.parseJobText(sample);
      expect(result.companyName, equals('Gojek'));
      expect(result.position.toLowerCase(), contains('content creator'));
      expect(result.location, equals('Surabaya'));
      expect(result.hasUsableCompany, isTrue);
      expect(result.hasUsablePosition, isTrue);
    });

    test('does not treat excellent as Excel skill', () {
      const sample = 'Looking for Sales Executive with excellent communication.';
      final result = TextParserService.parseJobText(sample);
      expect(result.extractedSkills, isNot(contains('Excel')));
      expect(result.position.toLowerCase(), contains('sales executive'));
    });

    test('classifies mixed WFH and office text as Hybrid', () {
      const sample =
          'Staff Administrasi WFO di kantor BSD, WFH 2 hari seminggu.';
      final result = TextParserService.parseJobText(sample);
      expect(result.workType, equals('Hybrid'));
    });

    test('does not fetch an unsupported or local URL', () async {
      const url = 'http://127.0.0.1/private-job-posting';

      final result = await TextParserService.extractFromUrlOrText(url);

      expect(result.jobUrl, equals(url));
      expect(result.sourcePlatform, equals('Manual'));
    });
  });

  group('SalaryEvaluatorService Tests', () {
    test('Should format Rupiah currency correctly', () {
      expect(
        SalaryEvaluatorService.formatRupiah(10000000),
        equals('Rp 10.000.000'),
      );
      expect(
        SalaryEvaluatorService.formatRupiah(-500000),
        equals('-Rp 500.000'),
      );
      expect(SalaryEvaluatorService.formatRupiah(0), equals('Rp 0'));
    });

    test('Should parse salary amount string correctly', () {
      expect(
        SalaryEvaluatorService.parseSalaryAmount('Rp 12.000.000'),
        equals(12000000.0),
      );
      expect(
        SalaryEvaluatorService.parseSalaryAmount('15 jt'),
        equals(15000000.0),
      );
      expect(SalaryEvaluatorService.parseSalaryAmount(''), equals(0.0));
    });

    test('Should evaluate salary against UMR correctly', () {
      final eval = SalaryEvaluatorService.evaluateSalary(
        grossSalary: 10000000,
        city: 'Jakarta',
        workType: 'WFO',
        needsKos: true,
      );
      expect(eval.grossSalary, equals(10000000.0));
      expect(eval.city, equals('Jakarta'));
      expect(eval.estimatedNetTakeHomePay, greaterThan(0));
    });
  });

  group('JobApplication persistence', () {
    test('JSON round-trip preserves all fields', () {
      final job = JobApplication(
        id: 'job-123',
        companyName: 'PT Contoh',
        position: 'Flutter Developer',
        status: 'Interview User',
        appliedDate: DateTime(2026, 8, 1, 9, 30),
        salaryOffered: 'Rp 10.000.000',
        workType: 'Hybrid',
        location: 'Jakarta Selatan',
        jobSource: 'LinkedIn',
        jobDescription: 'Flutter dan Riverpod',
        hrContact: '+628123456789',
        interviewDate: DateTime(2026, 8, 5, 10),
        notes: 'Bawa portofolio',
        isFavorite: true,
        isSampleData: true,
      );

      final restored = JobApplication.fromJson(job.toJson());

      expect(restored.toMap(), equals(job.toMap()));
      expect(restored.isSampleData, isTrue);
    });

    test('nullable interview date remains null', () {
      final job = JobApplication(
        id: 'job-124',
        companyName: 'PT Contoh',
        position: 'QA Engineer',
        status: 'Dikirim',
        appliedDate: DateTime(2026, 8, 1),
        workType: 'WFO',
        jobDescription: '',
      );

      expect(JobApplication.fromJson(job.toJson()).interviewDate, isNull);
    });

    test('normalizes legacy on-site work type to WFO', () {
      final job = JobApplication(
        id: 'job-125',
        companyName: 'PT Contoh',
        position: 'Business Analyst',
        status: 'Dikirim',
        appliedDate: DateTime(2026, 8, 1),
        workType: 'On-Site',
        jobDescription: '',
      );

      expect(job.workType, equals('WFO'));
      expect(JobApplication.fromJson(job.toJson()).workType, equals('WFO'));
    });

    test('migrates a legacy HR contact without losing the original field', () {
      final restored = JobApplication.fromMap({
        'id': 'legacy-contact',
        'companyName': 'PT Lama',
        'position': 'Product Designer',
        'status': 'Dikirim',
        'appliedDate': '2026-08-01T00:00:00.000',
        'workType': 'WFH',
        'jobDescription': '',
        'hrContact': 'recruiter@contoh.id',
      });

      expect(restored.hrContact, equals('recruiter@contoh.id'));
      expect(restored.recruiterContacts, hasLength(1));
      expect(restored.recruiterContacts.single.channel, equals('Email'));
    });

    test('JSON round-trip preserves recruitment tracking data', () {
      final job = JobApplication(
        id: 'job-tracking',
        companyName: 'PT Tracking',
        position: 'Engineer',
        status: 'Offering',
        appliedDate: DateTime(2026, 8, 1),
        workType: 'Hybrid',
        jobDescription: 'Dart, Flutter, dan komunikasi.',
        priority: 'Tinggi',
        labels: const ['Target', 'Remote'],
        nextActionAt: DateTime(2026, 8, 28, 9),
        nextActionType: 'Ambil keputusan',
        nextActionNote: 'Tinjau offering letter',
        recruitmentEvents: [
          RecruitmentEvent(
            id: 'event-1',
            type: 'status',
            title: 'Status menjadi Offering',
            occurredAt: DateTime(2026, 8, 24, 10),
          ),
        ],
        recruiterContacts: const [
          RecruiterContact(
            id: 'contact-1',
            name: 'Nadia',
            role: 'Talent Acquisition',
            channel: 'Email',
            value: 'nadia@contoh.id',
          ),
        ],
        offerDetails: OfferDetails(
          baseSalary: 15000000,
          period: 'Bulanan',
          decisionDeadline: DateTime(2026, 8, 28),
        ),
      );

      final restored = JobApplication.fromJson(job.toJson());

      expect(restored.priority, equals('Tinggi'));
      expect(restored.labels, equals(['Target', 'Remote']));
      expect(restored.nextActionType, equals('Ambil keputusan'));
      expect(restored.recruitmentEvents.single.title, contains('Offering'));
      expect(restored.recruiterContacts.single.name, equals('Nadia'));
      expect(restored.offerDetails?.baseSalary, equals(15000000));
    });
  });

  group('State integrity', () {
    test('PRO expiry can be explicitly cleared on cancellation', () {
      final state = JobState(
        jobs: const [],
        isProUser: true,
        proExpiryDate: DateTime(2026, 9, 1),
      );

      final cancelled = state.copyWith(
        isProUser: false,
        clearProExpiryDate: true,
      );

      expect(cancelled.isProUser, isFalse);
      expect(cancelled.proExpiryDate, isNull);
    });
  });

  group('NotificationService', () {
    test('notification ID is stable and positive', () {
      final first = NotificationService.notificationIdFor('job-123');
      final second = NotificationService.notificationIdFor('job-123');

      expect(first, equals(second));
      expect(first, greaterThanOrEqualTo(100000000));
    });

    test('different job IDs produce different reminder IDs', () {
      expect(
        NotificationService.notificationIdFor('job-123'),
        isNot(NotificationService.notificationIdFor('job-124')),
      );
    });

    test(
      'next-action reminder ID is stable and isolated from interview IDs',
      () {
        final nextAction = NotificationService.nextActionNotificationIdFor(
          'job-123',
        );

        expect(
          nextAction,
          equals(NotificationService.nextActionNotificationIdFor('job-123')),
        );
        expect(
          nextAction,
          isNot(NotificationService.notificationIdFor('job-123')),
        );
      },
    );
  });

  group('Android home widget projection', () {
    test('prioritizes the nearest interview over a later next action', () {
      final now = DateTime(2026, 8, 25, 8);
      final projection = AndroidHomeWidgetService.buildProjection([
        JobApplication(
          id: 'later-action',
          companyName: 'PT Aksi',
          position: 'UI Designer',
          status: 'Dikirim',
          appliedDate: now,
          workType: 'WFH',
          jobDescription: '',
          nextActionAt: now.add(const Duration(days: 2)),
          nextActionType: 'Kirim dokumen',
        ),
        JobApplication(
          id: 'nearest-interview',
          companyName: 'PT Interview',
          position: 'Flutter Developer',
          status: 'Interview HR',
          appliedDate: now,
          workType: 'Hybrid',
          jobDescription: '',
          interviewDate: now.add(const Duration(hours: 4)),
          notes: 'Siapkan portofolio dan CV.',
        ),
      ], now: now);

      expect(projection.kind, equals('interview'));
      expect(projection.jobId, equals('nearest-interview'));
      expect(projection.label, equals('PENGINGAT INTERVIEW'));
      expect(projection.activeCount, equals(2));
    });

    test('uses the latest active note when no reminder is scheduled', () {
      final now = DateTime(2026, 8, 25, 8);
      final projection = AndroidHomeWidgetService.buildProjection([
        JobApplication(
          id: 'note-job',
          companyName: 'PT Catatan',
          position: 'QA Engineer',
          status: 'Dikirim',
          appliedDate: now,
          updatedAt: now,
          workType: 'WFO',
          jobDescription: '',
          notes: 'Tanyakan estimasi waktu kabar lanjutan.',
        ),
      ], now: now);

      expect(projection.kind, equals('note'));
      expect(projection.jobId, equals('note-job'));
      expect(projection.title, contains('Tanyakan estimasi'));
    });

    test('does not expose accepted or rejected applications', () {
      final now = DateTime(2026, 8, 25, 8);
      final projection = AndroidHomeWidgetService.buildProjection([
        JobApplication(
          id: 'finished-job',
          companyName: 'PT Selesai',
          position: 'Analyst',
          status: 'Diterima',
          appliedDate: now,
          workType: 'WFH',
          jobDescription: '',
          nextActionAt: now.add(const Duration(days: 1)),
          nextActionType: 'Tindak lanjut',
        ),
      ], now: now);

      expect(projection.hasContent, isFalse);
      expect(projection.kind, equals('empty'));
    });
  });

  group('ProVerificationService', () {
    test('does not activate PRO without a verified Supabase session', () async {
      final result = await ProVerificationService.verify(
        code: '1234567890',
        plan: 'monthly',
      );

      expect(result.isValid, isFalse);
      expect(result.message, contains('belum dapat diverifikasi'));
    });
  });

  group('BackupService', () {
    test('ZIP backup restores a job and all managed attachments', () async {
      final temporaryRoot = await Directory.systemTemp.createTemp(
        'ngelamar_backup_test_',
      );
      try {
        final screenshot = File('${temporaryRoot.path}/poster.png');
        await screenshot.writeAsBytes([1, 2, 3, 4]);
        final cv = File('${temporaryRoot.path}/cv.pdf');
        await cv.writeAsBytes([37, 80, 68, 70, 45, 49, 46, 55]);
        final offer = File('${temporaryRoot.path}/offer.pdf');
        await offer.writeAsBytes([37, 80, 68, 70, 45, 49, 46, 56]);
        final job = JobApplication(
          id: 'backup-job-1',
          companyName: 'PT Backup',
          position: 'Flutter Developer',
          status: 'Dikirim',
          appliedDate: DateTime(2026, 8, 1),
          workType: 'WFH',
          jobDescription: 'Data backup',
          screenshotPath: screenshot.path,
          pdfCvPath: cv.path,
          attachments: [
            JobAttachment(
              id: 'offer-letter',
              type: 'surat_penawaran',
              name: 'Offering Letter.pdf',
              path: offer.path,
              createdAt: DateTime(2026, 8, 2),
            ),
          ],
        );

        final backup = await BackupService.createBackup(
          [job],
          password: 'kata-sandi-backup',
          outputDirectory: temporaryRoot,
        );
        final restored = await BackupService.restoreFromBytes(
          await backup.readAsBytes(),
          password: 'kata-sandi-backup',
          appDirectory: Directory('${temporaryRoot.path}/restored'),
        );

        expect(restored.jobs, hasLength(1));
        expect(restored.jobs.single.companyName, equals('PT Backup'));
        expect(restored.jobs.single.screenshotPath, isNotNull);
        expect(File(restored.jobs.single.screenshotPath!).existsSync(), isTrue);
        expect(restored.jobs.single.pdfCvPath, isNotNull);
        expect(File(restored.jobs.single.pdfCvPath!).existsSync(), isTrue);
        expect(restored.jobs.single.attachments, hasLength(1));
        expect(
          File(restored.jobs.single.attachments.single.path).existsSync(),
          isTrue,
        );
        await expectLater(
          BackupService.restoreFromBytes(
            await backup.readAsBytes(),
            password: 'kata-sandi-yang-salah',
            appDirectory: Directory('${temporaryRoot.path}/wrong-password'),
          ),
          throwsA(isA<BackupException>()),
        );
      } finally {
        await temporaryRoot.delete(recursive: true);
      }
    });

    test('rejects invalid backup bytes', () async {
      await expectLater(
        BackupService.restoreFromBytes(Uint8List.fromList([1, 2, 3])),
        throwsA(isA<BackupException>()),
      );
    });

    test('imports legacy JSON v2 without trusting attachment paths', () async {
      final bytes = Uint8List.fromList(
        utf8.encode(
          jsonEncode({
            'schemaVersion': 2,
            'jobs': [
              jsonEncode({
                'id': 'legacy-1',
                'companyName': 'PT Lama',
                'position': 'UI Designer',
                'status': 'Dikirim',
                'appliedDate': '2026-08-01T00:00:00.000',
                'workType': 'WFH',
                'jobDescription': '',
                'screenshotPath': 'C:/untrusted/file.png',
              }),
            ],
          }),
        ),
      );

      final restored = await BackupService.restoreFromBytes(bytes);

      expect(restored.jobs, hasLength(1));
      expect(restored.jobs.single.screenshotPath, isNull);
    });
  });

  group('2026 Audit Fixes Verification', () {
    test(
      'JobApplication calculates lastMeaningfulActivityAt and handles Tersimpan status',
      () {
        final now = DateTime.now();
        final oldApplied = now.subtract(const Duration(days: 20));
        final recentEvent = now.subtract(const Duration(days: 2));

        final savedJob = JobApplication(
          id: 'job_saved',
          companyName: 'PT Saved Corp',
          position: 'QA Engineer',
          status: 'Tersimpan',
          appliedDate: now,
          savedAt: now,
          workType: 'WFH',
          jobDescription: 'Testing specs',
        );

        expect(savedJob.isSaved, isTrue);
        expect(savedJob.isGhosted, isFalse);
        expect(savedJob.needsFollowup, isFalse);

        final activeJob = JobApplication(
          id: 'job_active',
          companyName: 'PT Active Corp',
          position: 'Backend Developer',
          status: 'Dikirim',
          appliedDate: oldApplied,
          workType: 'WFO',
          jobDescription: 'Go, PostgreSQL',
          recruitmentEvents: [
            RecruitmentEvent(
              id: 'evt_1',
              type: 'interview',
              title: 'Technical Screen',
              occurredAt: recentEvent,
            ),
          ],
        );

        expect(activeJob.lastMeaningfulActivityAt, equals(recentEvent));
        expect(activeJob.isGhosted, isFalse);
        expect(activeJob.needsFollowup, isFalse);
      },
    );

    test('SalaryEvaluatorService 2025/2026 data and progressive deduction', () {
      final result = SalaryEvaluatorService.evaluateSalary(
        grossSalary: 10000000,
        city: 'Jakarta',
        workType: 'WFO',
        needsKos: false,
        bpjsPercent: 4.0,
        includePph21: true,
      );

      expect(result.estimatedBpjsDeduction, equals(400000.0));
      expect(result.estimatedPph21Deduction, equals(500000.0)); // 5% for 10jt
      expect(result.estimatedNetTakeHomePay, equals(9100000.0));
      expect(result.effectiveYear, equals('2025/2026'));
      expect(result.umrAmount, equals(5396761.0));
    });

    test(
      'TextParserService preserves legitimate keywords like Recruitment Specialist',
      () {
        const title = 'We are hiring: Recruitment Specialist';
        final parsed = TextParserService.parseJobText(title);
        expect(parsed.position, contains('Recruitment'));
      },
    );

    test('AppVersionService provides semantic version comparison', () {
      expect(AppVersionService.version, equals('2.28.1'));
      expect(AppVersionService.buildNumber, equals('246'));
      expect(
        AppVersionService.compareVersions('2.28.1', '2.25.5'),
        greaterThan(0),
      );
      expect(
        AppVersionService.compareVersions('2.25.0', '2.28.1'),
        lessThan(0),
      );
      expect(AppVersionService.compareVersions('2.28.1', '2.28.1'), equals(0));
      expect(AppVersionService.isVersionSupported('2.28.1', '2.25.0'), isTrue);
      expect(AppVersionService.isVersionSupported('2.24.0', '2.25.0'), isFalse);
    });

    test(
      'JobApplication lifecycle distinguishing Draft, Tersimpan, Dikirim, and Closed',
      () {
        final now = DateTime.now();

        final draftJob = JobApplication(
          id: 'job_draft',
          companyName: 'PT Draft Corp',
          position: 'Mobile Engineer',
          status: 'Draft',
          appliedDate: now,
          savedAt: now,
          workType: 'Hybrid',
          jobDescription: 'Draft description',
        );
        expect(draftJob.isDraft, isTrue);
        expect(draftJob.isSaved, isFalse);
        expect(draftJob.isApplied, isFalse);
        expect(draftJob.appliedAt, isNull);
        expect(draftJob.daysSinceApplied, equals(0));

        final sentJob = JobApplication(
          id: 'job_sent',
          companyName: 'PT Sent Corp',
          position: 'Mobile Engineer',
          status: 'Dikirim',
          appliedDate: now.subtract(const Duration(days: 3)),
          workType: 'WFO',
          jobDescription: 'Sent description',
        );
        expect(sentJob.isDraft, isFalse);
        expect(sentJob.isSaved, isFalse);
        expect(sentJob.isApplied, isTrue);
        expect(sentJob.appliedAt, isNotNull);
        expect(sentJob.daysSinceApplied, equals(3));

        final closedJob = sentJob.copyWith(status: 'Diterima', closedAt: now);
        expect(closedJob.isClosed, isTrue);
      },
    );

    test('RecruitmentEvent full serialization round-trip', () {
      final now = DateTime.now();
      final event = RecruitmentEvent(
        id: 'evt_full',
        type: 'interview_user',
        title: 'Interview User with VP',
        occurredAt: now,
        scheduledAt: now.add(const Duration(days: 2)),
        completedAt: now.add(const Duration(days: 2, hours: 1)),
        notes: 'Passed technical questions',
        outcome: 'Lolos ke tahap Offering',
        roundNumber: 2,
        source: 'manual',
        isDeleted: false,
      );

      final map = event.toMap();
      final restored = RecruitmentEvent.fromMap(map);

      expect(restored.id, equals('evt_full'));
      expect(restored.type, equals('interview_user'));
      expect(restored.title, equals('Interview User with VP'));
      expect(restored.roundNumber, equals(2));
      expect(restored.outcome, equals('Lolos ke tahap Offering'));
      expect(restored.isDeleted, isFalse);
      expect(restored.eventDate, equals(event.scheduledAt));
    });

    test(
      'JobSearchService normalizes query and matches multi-attribute tokens',
      () {
        final jobs = [
          JobApplication(
            id: 'job_1',
            companyName: 'Tokopedia',
            position: 'Senior Flutter Developer',
            status: 'Interview HR',
            appliedDate: DateTime.now(),
            workType: 'Hybrid',
            location: 'Jakarta Selatan',
            jobDescription:
                'State management with Riverpod and clean architecture',
          ),
          JobApplication(
            id: 'job_2',
            companyName: 'Gojek',
            position: 'Backend Go Engineer',
            status: 'Dikirim',
            appliedDate: DateTime.now(),
            workType: 'WFH',
            location: 'Jakarta Pusat',
            jobDescription: 'Microservices with gRPC and PostgreSQL',
          ),
          JobApplication(
            id: 'job_3',
            companyName: 'Shopee',
            position: 'QA Automation Lead',
            status: 'Tersimpan',
            appliedDate: DateTime.now(),
            workType: 'WFO',
            location: 'BSD Tangerang',
            jobDescription: 'Appium, Flutter integration testing',
          ),
        ];

        // Multi-token match across position and location
        final result1 = JobSearchService.filterJobs(
          jobs,
          query: 'flutter jakarta',
        );
        expect(result1, hasLength(1));
        expect(result1.first.companyName, equals('Tokopedia'));

        // Punctuation and case-insensitive normalization
        final result2 = JobSearchService.filterJobs(
          jobs,
          query: 'GOJEK, backend!',
        );
        expect(result2, hasLength(1));
        expect(result2.first.id, equals('job_2'));

        // Status filter with query
        final result3 = JobSearchService.filterJobs(jobs, status: 'Tersimpan');
        expect(result3, hasLength(1));
        expect(result3.first.companyName, equals('Shopee'));
      },
    );

    test('AndroidHomeWidgetService excludes sample data from projection', () {
      final now = DateTime.now();
      final sampleJob = JobApplication(
        id: 'sample_interview',
        companyName: 'Sample Corp',
        position: 'Demo Engineer',
        status: 'Interview HR',
        appliedDate: now,
        interviewDate: now.add(const Duration(days: 1)),
        isSampleData: true,
        workType: 'WFO',
        jobDescription: 'Tutorial mock job',
      );

      final projection = AndroidHomeWidgetService.buildProjection([
        sampleJob,
      ], now: now);

      expect(projection.hasContent, isFalse);
      expect(projection.activeCount, equals(0));
    });

    test(
      'JobApplication fromMap gracefully migrates legacy data without savedAt/closedAt',
      () {
        final legacyMap = {
          'id': 'legacy_001',
          'companyName': 'PT Lama Sukses',
          'position': 'System Analyst',
          'status': 'Dikirim',
          'appliedDate': '2025-01-15T10:00:00.000',
          'workType': 'On-site',
          'jobDescription': 'Analisis sistem ERP',
          'hrContact': 'hr@lama.co.id',
        };

        final migrated = JobApplication.fromMap(legacyMap);
        expect(migrated.id, equals('legacy_001'));
        expect(migrated.workType, equals('WFO')); // normalized from On-site
        expect(migrated.isApplied, isTrue);
        expect(migrated.savedAt, isNull);
        expect(migrated.closedAt, isNull);
        expect(
          migrated.recruiterContacts.map((c) => c.value),
          contains('hr@lama.co.id'),
        );
      },
    );

    test('Unified nextDueAt and overdueDueAt calculate properly', () {
      final now = DateTime.now();
      final futureInterview = now.add(const Duration(days: 3));
      final futureNextAction = now.add(const Duration(days: 5));
      final pastTest = now.subtract(const Duration(days: 2));

      final activeJob = JobApplication(
        id: 'job_due_test',
        companyName: 'PT Maju Bersama',
        position: 'Flutter Dev',
        status: 'Interview HR',
        appliedDate: now.subtract(const Duration(days: 10)),
        interviewDate: futureInterview,
        nextActionAt: futureNextAction,
        nextActionType: 'Follow-up User',
        workType: 'WFH',
        jobDescription: '',
      );

      // nextDueAt should pick the earliest future date (interview at +3 days)
      expect(activeJob.nextDueAt, equals(futureInterview));
      expect(activeJob.overdueDueAt, isNull);

      final overdueJob = JobApplication(
        id: 'job_overdue_test',
        companyName: 'PT Telat',
        position: 'Backend Dev',
        status: 'Tes / Psikotes',
        appliedDate: now.subtract(const Duration(days: 10)),
        testDate: pastTest,
        workType: 'WFO',
        jobDescription: '',
      );

      expect(overdueJob.nextDueAt, isNull);
      expect(overdueJob.overdueDueAt, equals(pastTest));

      final closedJob = activeJob.copyWith(status: 'Diterima');
      expect(closedJob.nextDueAt, isNull);
      expect(closedJob.overdueDueAt, isNull);
    });

    test(
      'lastMeaningfulActivityAt considers latest recruitment event for follow-up triggers',
      () {
        final now = DateTime.now();
        final appliedDate = now.subtract(const Duration(days: 14));
        final recentEventDate = now.subtract(const Duration(days: 2));

        final event = RecruitmentEvent(
          id: 'evt_interview',
          type: 'interview_hr',
          title: 'Interview HR Selesai',
          occurredAt: recentEventDate,
          completedAt: recentEventDate,
        );

        final jobWithEvent = JobApplication(
          id: 'job_event_activity',
          companyName: 'PT Startup Baru',
          position: 'Mobile Engineer',
          status: 'Dikirim',
          appliedDate: appliedDate,
          recruitmentEvents: [event],
          workType: 'Remote',
          jobDescription: '',
        );

        // Even though applied 14 days ago, meaningful activity happened 2 days ago
        expect(jobWithEvent.lastMeaningfulActivityAt, equals(recentEventDate));
        expect(jobWithEvent.daysSinceLastActivity, equals(2));
        expect(jobWithEvent.needsFollowup, isFalse);
      },
    );

    test(
      'NotificationService returns structured NotificationScheduleResult for invalid/sample jobs',
      () async {
        final sampleJob = JobApplication(
          id: 'sample_notification',
          companyName: 'Sample Corp',
          position: 'Engineer',
          status: 'Interview HR',
          appliedDate: DateTime.now(),
          isSampleData: true,
          workType: 'WFO',
          jobDescription: '',
        );

        final result = await NotificationService.syncInterviewReminder(
          sampleJob,
        );
        expect(
          result.state,
          anyOf(
            equals(ScheduleState.unsupported), // on Web
            equals(ScheduleState.skippedClosedOrSample), // on mobile
          ),
        );
        expect(result.isSuccess, isFalse);
      },
    );
  });
}
