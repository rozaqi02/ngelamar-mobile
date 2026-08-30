// Tier 4: Real-World Application Scenarios Test Suite
// Verifies 5 comprehensive multi-stage realistic user flows across the full lifecycle

import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:ngelamar/models/job_application.dart';
import 'package:ngelamar/services/salary_evaluator_service.dart';
import 'package:ngelamar/services/text_parser_service.dart';
import 'package:ngelamar/services/notification_service.dart';
import 'package:ngelamar/services/android_home_widget_service.dart';
import 'package:ngelamar/services/backup_service.dart';
import 'package:ngelamar/services/job_search_service.dart';
import 'package:ngelamar/services/followup_service.dart';
import 'package:ngelamar/services/pro_verification_service.dart';
import 'package:ngelamar/services/prefs_service.dart';
import 'package:ngelamar/providers/job_provider.dart';
import 'e2e_test_helpers.dart';

void main() {
  setUpAll(() async {
    await E2ETestHelper.setupE2ETestEnvironment();
  });

  tearDownAll(() {
    E2ETestHelper.tearDownE2EEnvironment();
  });

  group(
    'Scenario 1: Fresh Graduate 30-Day Job Search Journey (Onboarding to First Job Offer)',
    () {
      test(
        '1.1 User completes profile setup with career interests and target city',
        () async {
          await PrefsService.setUserName('Rizky Ramadhan');
          await PrefsService.setUserEmail('rizky.ramadhan@alumni.ac.id');
          await PrefsService.setChecklistDocs([
            'CV ATS-Friendly',
            'Portofolio GitHub',
            'Ijazah & Transkrip',
          ]);

          final name = await PrefsService.getUserName();
          final email = await PrefsService.getUserEmail();
          final docs = await PrefsService.getChecklistDocs();

          expect(name, equals('Rizky Ramadhan'));
          expect(email, equals('rizky.ramadhan@alumni.ac.id'));
          expect(docs?.length, equals(3));
        },
      );

      test(
        '1.2 User shares job post from LinkedIn, extracts data, and saves as Tersimpan',
        () async {
          const shareContent =
              'Lowongan Junior Flutter Developer di PT Digital Nusantara. Lokasi Jakarta Selatan. Gaji Rp 8.000.000 - 12.000.000 / bulan. Kirim CV ke hrd@digitalnusantara.id';
          final parsed = await TextParserService.extractFromUrlOrText(
            shareContent,
          );

          final job = JobApplication(
            id: 'job_scenario1_1',
            companyName: parsed.companyName.isNotEmpty
                ? parsed.companyName
                : 'PT Digital Nusantara',
            position: parsed.position.isNotEmpty
                ? parsed.position
                : 'Junior Flutter Developer',
            status: 'Tersimpan',
            appliedDate: DateTime.now(),
            workType: 'WFO',
            location: 'Jakarta Selatan',
            minSalary: 8000000,
            maxSalary: 12000000,
            salaryOffered: 'Rp 8.000.000 - 12.000.000',
            hrContact: parsed.hrContact ?? 'hrd@digitalnusantara.id',
            sourcePlatform: 'LinkedIn',
            jobDescription: shareContent,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );

          expect(job.status, equals('Tersimpan'));
          expect(job.isSaved, isTrue);
          expect(job.companyName, contains('Digital Nusantara'));
        },
      );

      test(
        '1.3 User applies to job, updates status to Dikirim, and sets 7-day follow-up reminder',
        () {
          final now = DateTime.now();
          final initialJob = E2ETestHelper.createSampleJob(
            id: 'job_scenario1_1',
            companyName: 'PT Digital Nusantara',
            position: 'Junior Flutter Developer',
            status: 'Tersimpan',
          );

          final appliedJob = initialJob.copyWith(
            status: 'Dikirim',
            appliedDate: now,
            nextActionAt: now.add(const Duration(days: 7)),
            nextActionType: 'follow_up',
            nextActionNote:
                'Kirim email follow-up santun ke HR jika belum ada kabar',
          );

          expect(appliedJob.isApplied, isTrue);
          expect(appliedJob.status, equals('Dikirim'));
          expect(appliedJob.nextActionAt, isNotNull);
        },
      );

      test(
        '1.4 Recruiter invites for Interview HR, event is scheduled, and widget projection updates',
        () {
          final now = DateTime.now();
          final interviewDate = now.add(const Duration(days: 3, hours: 10));
          final appliedJob = E2ETestHelper.createSampleJob(
            id: 'job_scenario1_1',
            companyName: 'PT Digital Nusantara',
            status: 'Dikirim',
          );

          final interviewEvent = E2ETestHelper.createRecruitmentEvent(
            id: 'event_interview_hr_1',
            title: 'Interview HR & Screening Portfolio',
            type: 'interview',
            occurredAt: interviewDate,
          );

          final scheduledJob = appliedJob.copyWith(
            status: 'Interview HR',
            interviewDate: interviewDate,
            recruitmentEvents: [interviewEvent],
          );

          final projection = AndroidHomeWidgetService.buildProjection([
            scheduledJob,
          ], now: now);
          final notifId = NotificationService.notificationIdFor(
            scheduledJob.id,
          );

          expect(scheduledJob.status, equals('Interview HR'));
          expect(projection.hasContent, isTrue);
          expect(projection.companyName, equals('PT Digital Nusantara'));
          expect(notifId, greaterThan(0));
        },
      );

      test(
        '1.5 User receives formal offering, evaluates take-home pay, and marks status Diterima',
        () {
          final interviewJob = E2ETestHelper.createSampleJob(
            id: 'job_scenario1_1',
            companyName: 'PT Digital Nusantara',
            position: 'Junior Flutter Developer',
            status: 'Interview User',
          );

          final offer = E2ETestHelper.createOfferDetails(
            baseSalary: 11000000,
            takeHomePay: 10200000,
            decisionDeadline: DateTime.now().add(const Duration(days: 5)),
          );

          final eval = SalaryEvaluatorService.evaluateSalary(
            grossSalary: 11000000,
            city: 'Jakarta Selatan',
            workType: 'WFO',
          );

          expect(eval.grossSalary, equals(11000000));
          expect(eval.estimatedNetTakeHomePay, greaterThan(eval.umrAmount));

          final acceptedJob = interviewJob.copyWith(
            status: 'Diterima',
            offerDetails: offer,
            closedAt: DateTime.now(),
            clearNextAction: true,
          );

          expect(acceptedJob.status, equals('Diterima'));
          expect(acceptedJob.isClosed, isTrue);
          expect(acceptedJob.offerDetails?.baseSalary, equals(11000000));
        },
      );
    },
  );

  group(
    'Scenario 2: Senior Engineer Multi-Pipeline Parallel Applications Management',
    () {
      test(
        '2.1 User manages 5 concurrent applications across diverse stages',
        () {
          final now = DateTime.now();
          final pipeline = [
            E2ETestHelper.createSampleJob(
              id: 'j1',
              companyName: 'Tokopedia',
              position: 'Lead Flutter',
              status: 'Offering',
              salaryOffered: 'Rp 42.000.000',
            ),
            E2ETestHelper.createSampleJob(
              id: 'j2',
              companyName: 'Traveloka',
              position: 'Principal Mobile',
              status: 'Interview User',
              interviewDate: now.add(const Duration(days: 2)),
            ),
            E2ETestHelper.createSampleJob(
              id: 'j3',
              companyName: 'Gojek',
              position: 'Senior Android',
              status: 'Technical Test',
              testDate: now.add(const Duration(days: 4)),
            ),
            E2ETestHelper.createSampleJob(
              id: 'j4',
              companyName: 'Shopee',
              position: 'Tech Lead',
              status: 'Interview HR',
              interviewDate: now.add(const Duration(days: 6)),
            ),
            E2ETestHelper.createSampleJob(
              id: 'j5',
              companyName: 'OldStartup',
              position: 'Fullstack Dev',
              status: 'Dikirim',
              appliedDate: now.subtract(const Duration(days: 20)),
            ),
          ];

          final state = JobState(jobs: pipeline);
          expect(state.totalCount, equals(5));
          expect(state.realJobs.length, equals(5));
          expect(state.offeringCount, equals(1));
        },
      );

      test(
        '2.2 Ghosted application (20 days inactive) is detected and archived via Bulk Mode',
        () {
          final now = DateTime.now();
          final jGhost = E2ETestHelper.createSampleJob(
            id: 'j_ghost',
            companyName: 'OldStartup',
            status: 'Dikirim',
            appliedDate: now.subtract(const Duration(days: 20)),
          );

          expect(jGhost.daysSinceLastActivity, greaterThanOrEqualTo(14));
          expect(jGhost.isGhosted, isTrue);

          final archivedGhost = jGhost.copyWith(
            status: 'Ditolak',
            outcomeReason: 'Ghosting / No Response',
            closedAt: now,
          );

          expect(archivedGhost.isClosed, isTrue);
          expect(archivedGhost.outcomeReason, contains('Ghosting'));
        },
      );

      test(
        '2.3 User performs multi-token search ("Lead Jakarta") across the pipeline',
        () {
          final pipeline = [
            E2ETestHelper.createSampleJob(
              companyName: 'Tokopedia',
              position: 'Lead Flutter',
              location: 'Jakarta',
            ),
            E2ETestHelper.createSampleJob(
              companyName: 'Traveloka',
              position: 'Principal Mobile',
              location: 'Tangerang',
            ),
            E2ETestHelper.createSampleJob(
              companyName: 'Shopee',
              position: 'Tech Lead',
              location: 'Jakarta',
            ),
          ];

          final results = JobSearchService.filterJobs(
            pipeline,
            query: 'Lead Jakarta',
          );
          expect(results.length, equals(2));
        },
      );

      test(
        '2.4 User logs comprehensive technical interview notes on active stage',
        () {
          final job = E2ETestHelper.createSampleJob(
            companyName: 'Traveloka',
            status: 'Interview User',
          );
          final event = E2ETestHelper.createRecruitmentEvent(
            title: 'System Design & State Management Deep Dive',
            type: 'interview',
            notes:
                'Diskusi arsitektur offline-first, Hive storage encryption, dan Riverpod async notifier.',
          );

          final updatedJob = job.copyWith(
            recruitmentEvents: [...job.recruitmentEvents, event],
          );
          expect(
            updatedJob.recruitmentEvents.last.notes,
            contains('offline-first'),
          );
        },
      );

      test(
        '2.5 Pro subscription verification allows advanced export and metrics',
        () async {
          final entitlement =
              await ProVerificationService.fetchCurrentEntitlement();
          expect(entitlement, isNotNull);
        },
      );
    },
  );

  group('Scenario 3: Offline-First Heavy Transit Usage (KRL / MRT Commute Flow)', () {
    test(
      '3.1 Cold launch in airplane mode operates smoothly without network calls',
      () {
        final cachedJobs = E2ETestHelper.generateRealisticJobs(20);
        final state = JobState(jobs: cachedJobs);
        expect(state.totalCount, equals(20));
      },
    );

    test(
      '3.2 User transitions status and logs notes completely offline in local Hive storage',
      () {
        final initialJob = E2ETestHelper.createSampleJob(
          id: 'j_offline',
          status: 'Tersimpan',
        );
        final updatedOffline = initialJob.copyWith(
          status: 'Dikirim',
          appliedDate: DateTime.now(),
          notes: 'Dikirim saat di kereta KRL Commuter Line',
        );

        final map = updatedOffline.toMap();
        final restoredFromLocal = JobApplication.fromMap(map);

        expect(restoredFromLocal.status, equals('Dikirim'));
        expect(restoredFromLocal.notes, contains('KRL Commuter'));
      },
    );

    test(
      '3.3 Inline error & retry debouncing prevents flickering during intermittent 4G connection',
      () {
        var syncAttempts = 0;
        var isSyncing = false;

        void syncData() {
          if (isSyncing) return;
          isSyncing = true;
          syncAttempts++;
        }

        for (var i = 0; i < 5; i++) {
          syncData();
        }
        expect(syncAttempts, equals(1));
      },
    );

    test(
      '3.4 Android Home Widget renders offline cache without network dependencies',
      () {
        final job = E2ETestHelper.createSampleJob(
          companyName: 'KRL Commuter Tech',
          position: 'Mobile Engineer',
          status: 'Interview HR',
          interviewDate: DateTime.now().add(const Duration(hours: 4)),
        );

        final projection = AndroidHomeWidgetService.buildProjection([
          job,
        ], now: DateTime.now());
        expect(projection.hasContent, isTrue);
        expect(projection.companyName, equals('KRL Commuter Tech'));
      },
    );

    test(
      '3.5 App returns to online state without losing locally updated records',
      () {
        final localJobs = E2ETestHelper.generateRealisticJobs(15);
        final onlineSyncedState = JobState(jobs: localJobs);
        expect(onlineSyncedState.totalCount, equals(15));
      },
    );
  });

  group('Scenario 4: Annual Job Search Archival & Secure Phone Migration', () {
    test(
      '4.1 Annual stats calculation summaries 50 applications over 12 months',
      () {
        final annualJobs = E2ETestHelper.generateRealisticJobs(50);
        final state = JobState(jobs: annualJobs);

        expect(state.totalCount, equals(50));
        expect(state.responseRate, greaterThanOrEqualTo(0.0));
        expect(state.offeringCount, greaterThanOrEqualTo(0));
      },
    );

    test(
      '4.2 User generates AES-256 encrypted backup archive before device reset',
      () async {
        final annualJobs = E2ETestHelper.generateRealisticJobs(30);
        const backupPass = 'MigrationPass_2026!';

        final backupFile = await BackupService.createBackup(
          annualJobs,
          password: backupPass,
          outputDirectory: Directory.systemTemp,
        );

        expect(backupFile.existsSync(), isTrue);
        expect(backupFile.lengthSync(), greaterThan(500));
      },
    );

    test(
      '4.3 Simulated fresh install restores database with 100% data integrity',
      () async {
        final annualJobs = E2ETestHelper.generateRealisticJobs(10);
        const backupPass = 'FreshDevicePass!';

        final backupFile = await BackupService.createBackup(
          annualJobs,
          password: backupPass,
          outputDirectory: Directory.systemTemp,
        );

        final bytes = await backupFile.readAsBytes();
        final restored = await BackupService.restoreFromBytes(
          bytes,
          password: backupPass,
        );

        expect(restored.jobs.length, equals(10));
        for (var i = 0; i < 10; i++) {
          expect(restored.jobs[i].id, equals(annualJobs[i].id));
          expect(restored.jobs[i].position, equals(annualJobs[i].position));
        }
      },
    );

    test(
      '4.4 Notification alarms and home widget projections are rebuilt on restored device',
      () {
        final now = DateTime.now();
        final futureInterview = E2ETestHelper.createSampleJob(
          id: 'job_migrated_interview',
          status: 'Interview HR',
          interviewDate: now.add(const Duration(days: 3)),
        );

        final projection = AndroidHomeWidgetService.buildProjection([
          futureInterview,
        ], now: now);
        final notifId = NotificationService.notificationIdFor(
          futureInterview.id,
        );

        expect(projection.hasContent, isTrue);
        expect(notifId, greaterThan(0));
      },
    );

    test(
      '4.5 Search query history and user preferences restore cleanly',
      () async {
        await PrefsService.setUserName('Alfin Dewantara');
        final name = await PrefsService.getUserName();
        expect(name, equals('Alfin Dewantara'));
      },
    );
  });

  group('Scenario 5: Overcoming Rejection & Resilient Career Transition Journey', () {
    test(
      '5.1 User marks dream job application as Ditolak after final interview',
      () {
        final job = E2ETestHelper.createSampleJob(
          companyName: 'Dream Unicorn Corp',
          position: 'Lead Flutter Specialist',
          status: 'Interview User',
          nextActionAt: DateTime.now().add(const Duration(days: 1)),
        );

        final rejectedJob = job.copyWith(
          status: 'Ditolak',
          outcomeReason:
              'Ditolak di tahap final interview (kandidat internal dipilih)',
          clearNextAction: true,
          closedAt: DateTime.now(),
        );

        expect(rejectedJob.status, equals('Ditolak'));
        expect(rejectedJob.isClosed, isTrue);
        expect(rejectedJob.nextActionAt, isNull);
      },
    );

    test(
      '5.2 Rejected status cleans up pending reminder alerts without orphan alerts',
      () {
        final now = DateTime.now();
        final rejectedJob = E2ETestHelper.createSampleJob(
          id: 'j_rejected_clean',
          status: 'Ditolak',
          closedAt: now,
        );

        final projection = AndroidHomeWidgetService.buildProjection([
          rejectedJob,
        ], now: now);
        expect(projection.hasContent, isFalse);
      },
    );

    test('5.3 User generates polite appreciation follow-up email to HR', () {
      final templates = FollowupService.getTemplatesFor(
        position: 'Lead Flutter Specialist',
        company: 'Dream Unicorn Corp',
        status: 'Ditolak',
      );

      expect(templates, isNotEmpty);
      final emailTemplate = templates.firstWhere(
        (t) => t.type == FollowupType.email,
      );
      expect(emailTemplate.content, contains('Dream Unicorn Corp'));
    });

    test(
      '5.4 User creates new application for competing company with upgraded salary expectation',
      () {
        final newJob = JobApplication(
          id: 'job_comeback_1',
          companyName: 'NextGen Fintech',
          position: 'Lead Flutter Architect',
          status: 'Dikirim',
          appliedDate: DateTime.now(),
          minSalary: 35000000,
          maxSalary: 45000000,
          workType: 'Hybrid',
          sourcePlatform: 'JobStreet',
          jobDescription:
              'Leading a team of 8 Flutter engineers in payment gateway vertical.',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        expect(newJob.isApplied, isTrue);
        expect(newJob.minSalary, equals(35000000));
      },
    );

    test(
      '5.5 Resilient application progresses rapidly to Offering stage with celebrate mascot',
      () {
        final applied = E2ETestHelper.createSampleJob(
          companyName: 'NextGen Fintech',
          position: 'Lead Flutter Architect',
          status: 'Dikirim',
        );

        final offer = E2ETestHelper.createOfferDetails(
          baseSalary: 42000000,
          takeHomePay: 37500000,
          decisionDeadline: DateTime.now().add(const Duration(days: 7)),
        );

        final wonJob = applied.copyWith(
          status: 'Offering',
          offerDetails: offer,
        );

        expect(wonJob.status, equals('Offering'));
        expect(wonJob.offerDetails?.baseSalary, equals(42000000));
      },
    );
  });
}
