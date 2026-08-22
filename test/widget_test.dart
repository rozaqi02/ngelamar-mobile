import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:ngelamar/services/backup_service.dart';
import 'package:ngelamar/services/text_parser_service.dart';
import 'package:ngelamar/services/salary_evaluator_service.dart';
import 'package:ngelamar/models/job_application.dart';
import 'package:ngelamar/services/notification_service.dart';
import 'package:ngelamar/services/pro_verification_service.dart';
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
        expect(result.salary, equals('Rp 12.000.000'));
      },
    );

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
    test('ZIP backup restores a job and its managed attachment', () async {
      final temporaryRoot = await Directory.systemTemp.createTemp(
        'ngelamar_backup_test_',
      );
      try {
        final screenshot = File('${temporaryRoot.path}/poster.png');
        await screenshot.writeAsBytes([1, 2, 3, 4]);
        final job = JobApplication(
          id: 'backup-job-1',
          companyName: 'PT Backup',
          position: 'Flutter Developer',
          status: 'Dikirim',
          appliedDate: DateTime(2026, 8, 1),
          workType: 'WFH',
          jobDescription: 'Data backup',
          screenshotPath: screenshot.path,
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
}
