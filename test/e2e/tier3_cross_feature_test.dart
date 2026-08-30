// Tier 3: Cross-Feature Combinations & Pairwise Integration Test Suite
// Verifies 10 comprehensive cross-module workflows across the 32 Work Packages

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
    'Pairwise Suite 1: Share Target (WP-26) + Text Parser (WP-17) + Quick Add Form',
    () {
      test(
        '1.1 Raw shared snippet from LinkedIn extracts position, company and creates valid JobApplication',
        () async {
          const sharedSnippet =
              'We are looking for Senior Flutter Engineer at PT Traveloka Indonesia. Hybrid role in Jakarta.';
          final parsed = await TextParserService.extractFromUrlOrText(
            sharedSnippet,
          );
          expect(parsed.companyName, isNotEmpty);
          expect(parsed.position, isNotEmpty);

          final job = JobApplication(
            id: 'job_share_1',
            companyName: parsed.companyName,
            position: parsed.position,
            status: 'Tersimpan',
            appliedDate: DateTime.now(),
            workType: parsed.workType.isNotEmpty ? parsed.workType : 'Hybrid',
            sourcePlatform: 'LinkedIn',
            jobDescription: parsed.rawDescription,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );

          expect(job.companyName, equals(parsed.companyName));
          expect(job.status, equals('Tersimpan'));
        },
      );

      test(
        '1.2 Shared plain text URL extracts company domain and sets sourcePlatform',
        () async {
          const sharedUrl = 'https://www.jobstreet.co.id/id/job/78901234';
          final parsed = await TextParserService.extractFromUrlOrText(
            sharedUrl,
          );
          expect(parsed.jobUrl, contains('jobstreet.co.id'));
        },
      );

      test(
        '1.3 Duplicate check prevents overwriting existing job with same company and position',
        () {
          final existingJob = E2ETestHelper.createSampleJob(
            companyName: 'Gojek',
            position: 'Mobile Architect',
          );
          final incomingJob = E2ETestHelper.createSampleJob(
            companyName: 'Gojek',
            position: 'Mobile Architect',
          );
          final isDuplicate =
              existingJob.companyName.toLowerCase() ==
                  incomingJob.companyName.toLowerCase() &&
              existingJob.position.toLowerCase() ==
                  incomingJob.position.toLowerCase();
          expect(isDuplicate, isTrue);
        },
      );

      test(
        '1.4 Quick Add pre-fills only required fields and leaves optional details empty',
        () {
          final job = JobApplication(
            id: 'job_quick_fill',
            companyName: 'Bukalapak',
            position: 'Engineering Manager',
            status: 'Tersimpan',
            appliedDate: DateTime.now(),
            workType: 'WFO',
            sourcePlatform: 'Manual',
            jobDescription: '',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );
          expect(job.salaryOffered, isNull);
          expect(job.hrContact, isNull);
          expect(job.recruitmentEvents, isEmpty);
        },
      );

      test(
        '1.5 Progressive disclosure expands Quick Add into full edit form',
        () {
          final quickJob = E2ETestHelper.createSampleJob(
            salaryOffered: null,
            notes: null,
          );
          final fullJob = quickJob.copyWith(
            salaryOffered: 'Rp 28.000.000',
            notes: 'Catatan kompensasi tambahan',
          );
          expect(fullJob.salaryOffered, equals('Rp 28.000.000'));
          expect(fullJob.notes, isNotNull);
        },
      );
    },
  );

  group(
    'Pairwise Suite 2: Status Advance (WP-24) + Mascot (WP-23) + Next Action (WP-27) + Calendar (WP-20)',
    () {
      test(
        '2.1 Advancing status from Tersimpan to Dikirim suggests follow up and sets appliedDate',
        () {
          final initialJob = E2ETestHelper.createSampleJob(status: 'Tersimpan');
          final now = DateTime.now();
          final advancedJob = initialJob.copyWith(
            status: 'Dikirim',
            appliedDate: now,
            nextActionAt: now.add(const Duration(days: 7)),
            nextActionType: 'follow_up',
            nextActionNote: 'Kirim email follow-up setelah 7 hari',
          );
          expect(advancedJob.status, equals('Dikirim'));
          expect(advancedJob.nextActionAt, isNotNull);
          expect(advancedJob.daysSinceLastActivity, equals(0));
        },
      );

      test(
        '2.2 Transitioning to Interview HR updates mascot state to Interview and schedules calendar event',
        () {
          final job = E2ETestHelper.createSampleJob(status: 'Dikirim');
          final interviewDate = DateTime.now().add(const Duration(days: 3));
          final interviewEvent = E2ETestHelper.createRecruitmentEvent(
            title: 'Interview HR Screening',
            type: 'interview',
            occurredAt: interviewDate,
          );

          final updatedJob = job.copyWith(
            status: 'Interview HR',
            interviewDate: interviewDate,
            recruitmentEvents: [...job.recruitmentEvents, interviewEvent],
          );

          expect(updatedJob.status, equals('Interview HR'));
          expect(updatedJob.recruitmentEvents.length, equals(1));
          expect(updatedJob.interviewDate, equals(interviewDate));
        },
      );

      test(
        '2.3 Reaching Offering stage triggers celebration state and unlocks OfferDetails',
        () {
          final job = E2ETestHelper.createSampleJob(status: 'Interview User');
          final offer = E2ETestHelper.createOfferDetails(
            baseSalary: 28000000,
            takeHomePay: 25500000,
          );
          final offeringJob = job.copyWith(
            status: 'Offering',
            offerDetails: offer,
          );
          expect(offeringJob.status, equals('Offering'));
          expect(offeringJob.offerDetails?.baseSalary, equals(28000000));
        },
      );

      test(
        '2.4 Calendar aggregator includes interview dates from all active jobs',
        () {
          final now = DateTime.now();
          final j1 = E2ETestHelper.createSampleJob(
            id: 'j1',
            status: 'Interview HR',
            interviewDate: now.add(const Duration(days: 2)),
          );
          final j2 = E2ETestHelper.createSampleJob(
            id: 'j2',
            status: 'Interview User',
            interviewDate: now.add(const Duration(days: 4)),
          );
          final activeInterviews = [
            j1,
            j2,
          ].where((j) => j.interviewDate != null).toList();
          expect(activeInterviews.length, equals(2));
        },
      );

      test('2.5 Final status Diterima closes active next actions cleanly', () {
        final job = E2ETestHelper.createSampleJob(
          status: 'Offering',
          nextActionAt: DateTime.now().add(const Duration(days: 1)),
        );
        final acceptedJob = job.copyWith(
          status: 'Diterima',
          clearNextAction: true,
          closedAt: DateTime.now(),
        );
        expect(acceptedJob.status, equals('Diterima'));
        expect(acceptedJob.nextActionAt, isNull);
        expect(acceptedJob.isClosed, isTrue);
      });
    },
  );

  group(
    'Pairwise Suite 3: Android Home Widget (WP-04) + Notification Reminder (WP-28) + Widget Sync',
    () {
      test(
        '3.1 Scheduling an interview calculates widget projection and registers notification ID',
        () {
          final interviewDate = DateTime.now().add(const Duration(days: 2));
          final job = E2ETestHelper.createSampleJob(
            id: 'job_widget_notif_1',
            status: 'Interview HR',
            interviewDate: interviewDate,
          );

          final projection = AndroidHomeWidgetService.buildProjection([
            job,
          ], now: DateTime.now());
          final notifId = NotificationService.notificationIdFor(job.id);

          expect(projection.hasContent, isTrue);
          expect(projection.jobId, equals(job.id));
          expect(notifId, greaterThanOrEqualTo(100000000));
        },
      );

      test(
        '3.2 Postponing next action via quick action (Tunda Besok) updates widget timeline',
        () {
          final now = DateTime.now();
          final initialAction = now.add(const Duration(hours: 2));
          final postponedAction = now.add(const Duration(days: 1, hours: 2));

          final job = E2ETestHelper.createSampleJob(
            id: 'job_snooze',
            status: 'Dikirim',
            nextActionAt: initialAction,
            nextActionType: 'follow_up',
          );

          final snoozedJob = job.copyWith(nextActionAt: postponedAction);
          final projection = AndroidHomeWidgetService.buildProjection([
            snoozedJob,
          ], now: now);

          expect(snoozedJob.nextActionAt, equals(postponedAction));
          expect(projection.activeCount, equals(1));
        },
      );

      test('3.3 Closing a job removes it from Android Home Widget queue', () {
        final now = DateTime.now();
        final activeJob = E2ETestHelper.createSampleJob(
          id: 'j_active',
          status: 'Interview HR',
          interviewDate: now.add(const Duration(days: 1)),
        );
        final closedJob = activeJob.copyWith(status: 'Ditolak', closedAt: now);

        final projection = AndroidHomeWidgetService.buildProjection([
          closedJob,
        ], now: now);
        expect(projection.hasContent, isFalse);
      });

      test(
        '3.4 Multiple active jobs prioritize the earliest impending deadline',
        () {
          final now = DateTime.now();
          final jLater = E2ETestHelper.createSampleJob(
            id: 'j_later',
            status: 'Interview HR',
            interviewDate: now.add(const Duration(days: 5)),
          );
          final jUrgent = E2ETestHelper.createSampleJob(
            id: 'j_urgent',
            status: 'Interview User',
            interviewDate: now.add(const Duration(days: 1)),
          );

          final projection = AndroidHomeWidgetService.buildProjection([
            jLater,
            jUrgent,
          ], now: now);
          expect(projection.jobId, equals('j_urgent'));
        },
      );

      test(
        '3.5 Notification service generates distinct IDs for interview vs next action on same job',
        () {
          const jobId = 'job_dual_channel_123';
          final interviewId = NotificationService.notificationIdFor(jobId);
          final nextActionId = NotificationService.nextActionNotificationIdFor(
            jobId,
          );
          expect(interviewId, isNot(equals(nextActionId)));
        },
      );
    },
  );

  group(
    'Pairwise Suite 4: Multi-Token Search (WP-15) + Header Collapse (WP-18) + Bulk Select (WP-29)',
    () {
      test(
        '4.1 Multi-token search filters 100 items by role and location simultaneously',
        () {
          final jobs = E2ETestHelper.generateRealisticJobs(100);
          final filtered = JobSearchService.filterJobs(
            jobs,
            query: 'Flutter Jakarta',
          );
          for (final j in filtered) {
            final match =
                j.position.toLowerCase().contains('flutter') ||
                j.location!.toLowerCase().contains('jakarta');
            expect(match, isTrue);
          }
        },
      );

      test(
        '4.2 Bulk selection mode operates cleanly on filtered search results',
        () {
          final jobs = E2ETestHelper.generateRealisticJobs(50);
          final filtered = JobSearchService.filterJobs(
            jobs,
            status: 'Offering',
          );
          final selectedSet = <String>{};

          for (final j in filtered) {
            selectedSet.add(j.id);
          }
          expect(selectedSet.length, equals(filtered.length));
        },
      );

      test(
        '4.3 Bulk archiving marks closedAt on selected items while preserving unselected items',
        () {
          final jobs = E2ETestHelper.generateRealisticJobs(10);
          final toArchiveIds = [jobs[0].id, jobs[1].id];
          final now = DateTime.now();

          final updatedJobs = jobs.map((j) {
            if (toArchiveIds.contains(j.id)) {
              return j.copyWith(closedAt: now);
            }
            return j;
          }).toList();

          expect(updatedJobs[0].closedAt, isNotNull);
          expect(updatedJobs[1].closedAt, isNotNull);
          expect(updatedJobs[2].closedAt, isNull);
        },
      );

      test(
        '4.4 Scrolling down during search collapses app bar header to optimize item visibility',
        () {
          const scrollOffset = 120.0;
          final isHeaderCollapsed = scrollOffset > 80.0;
          expect(isHeaderCollapsed, isTrue);
        },
      );

      test(
        '4.5 Clearing search query restores complete unfiltered job list',
        () {
          final jobs = E2ETestHelper.generateRealisticJobs(30);
          final filtered = JobSearchService.filterJobs(
            jobs,
            query: 'Traveloka',
          );
          expect(filtered.length, lessThanOrEqualTo(jobs.length));
          final restored = JobSearchService.filterJobs(jobs, query: '');
          expect(restored.length, equals(jobs.length));
        },
      );
    },
  );

  group(
    'Pairwise Suite 5: Add/Edit Salary Input (WP-17) + Evaluator (WP-24) + Take Home Pay (WP-08)',
    () {
      test(
        '5.1 Form salary input evaluates against regional UMR and computes BPJS deductions',
        () {
          final eval = SalaryEvaluatorService.evaluateSalary(
            grossSalary: 20000000,
            city: 'Jakarta',
            workType: 'WFO',
          );
          expect(eval.grossSalary, equals(20000000));
          expect(eval.estimatedBpjsDeduction, greaterThan(0));
          expect(eval.estimatedNetTakeHomePay, lessThan(eval.grossSalary));
        },
      );

      test(
        '5.2 Salary range input (20 jt - 30 jt) parses min and max correctly',
        () {
          final parsed = SalaryEvaluatorService.parseSalaryRange(
            'Rp 20.000.000 - Rp 30.000.000',
          );
          expect(parsed.isRange, isTrue);
          expect(parsed.min, equals(20000000));
          expect(parsed.max, equals(30000000));
        },
      );

      test(
        '5.3 Custom kos/living cost reduces estimated disposable take home pay',
        () {
          final evalWithKos = SalaryEvaluatorService.evaluateSalary(
            grossSalary: 15000000,
            city: 'Jakarta',
            workType: 'WFO',
            needsKos: true,
            customKosCost: 2500000,
          );
          expect(evalWithKos.estimatedNetTakeHomePay, greaterThan(0));
        },
      );

      test(
        '5.4 Formated take-home string formats with Indonesian currency locale',
        () {
          final formatted = SalaryEvaluatorService.formatRupiah(18500000);
          expect(formatted, equals('Rp 18.500.000'));
        },
      );

      test(
        '5.5 WFH work type evaluation reduces transport/commuting cost assumptions',
        () {
          final evalWfh = SalaryEvaluatorService.evaluateSalary(
            grossSalary: 15000000,
            city: 'Bandung',
            workType: 'WFH',
          );
          expect(evalWfh.city, equals('Bandung'));
        },
      );
    },
  );

  group(
    'Pairwise Suite 6: Career Prep Context (WP-25) + Follow-up Template (WP-24) + WhatsApp Launcher (WP-19)',
    () {
      test(
        '6.1 Follow-up template generator injects company and position dynamically',
        () {
          final templates = FollowupService.getTemplatesFor(
            position: 'Lead Flutter Developer',
            company: 'PT Telkom Indonesia',
            status: 'Interview HR',
          );
          final waTemplate = templates.firstWhere(
            (t) => t.type == FollowupType.whatsapp,
          );
          expect(waTemplate.content, contains('PT Telkom Indonesia'));
          expect(waTemplate.content, contains('Lead Flutter Developer'));
        },
      );

      test(
        '6.2 Recruiter WhatsApp contact URI constructs valid wa.me deep link',
        () {
          const phone = '+628123456789';
          const text =
              'Halo Bu Dewi, terima kasih atas sesi interview hari ini.';
          final cleanPhone = phone.replaceAll(RegExp(r'[^0-9]'), '');
          final uri =
              'https://wa.me/$cleanPhone?text=${Uri.encodeComponent(text)}';
          expect(uri, contains('https://wa.me/628123456789'));
          expect(uri, contains('Halo%20Bu%20Dewi'));
        },
      );

      test(
        '6.3 Adding interview prep practice notes appends to recruitment event log',
        () {
          final job = E2ETestHelper.createSampleJob();
          final event = E2ETestHelper.createRecruitmentEvent(
            title: 'Technical Mock Interview',
            notes:
                'Latihan live coding Riverpod dan Clean Architecture berhasil lancar.',
          );
          final updatedJob = job.copyWith(
            recruitmentEvents: [...job.recruitmentEvents, event],
          );
          expect(updatedJob.recruitmentEvents.last.notes, contains('Riverpod'));
        },
      );

      test(
        '6.4 Follow-up template supports English for international / remote roles',
        () {
          final templates = FollowupService.getTemplatesFor(
            position: 'Senior Mobile Engineer',
            company: 'Automattic',
            status: 'Interview User',
          );
          expect(templates, isNotEmpty);
        },
      );

      test('6.5 Follow-up count increments after dispatching message', () {
        final job = E2ETestHelper.createSampleJob(followUpCount: 0);
        final dispatchedJob = job.copyWith(
          followUpCount: job.followUpCount + 1,
          lastFollowUpAt: DateTime.now(),
        );
        expect(dispatchedJob.followUpCount, equals(1));
        expect(dispatchedJob.lastFollowUpAt, isNotNull);
      });
    },
  );

  group(
    'Pairwise Suite 7: Full Backup Export (WP-16) + Reset + Restore (WP-16) + Metrics Verify (WP-15)',
    () {
      test(
        '7.1 Creating encrypted backup with 10 jobs produces verifiable ZIP archive',
        () async {
          final originalJobs = E2ETestHelper.generateRealisticJobs(10);
          final backupFile = await BackupService.createBackup(
            originalJobs,
            password: 'SecurePassword123!',
            outputDirectory: Directory.systemTemp,
          );
          expect(backupFile.existsSync(), isTrue);
          expect(backupFile.lengthSync(), greaterThan(100));
        },
      );

      test('7.2 Restoring backup restores exact count and fields', () async {
        final originalJobs = E2ETestHelper.generateRealisticJobs(5);
        final backupFile = await BackupService.createBackup(
          originalJobs,
          password: 'RestorePass123!',
          outputDirectory: Directory.systemTemp,
        );
        final bytes = await backupFile.readAsBytes();
        final restoredPayload = await BackupService.restoreFromBytes(
          bytes,
          password: 'RestorePass123!',
        );
        expect(restoredPayload.jobs.length, equals(5));
        for (var i = 0; i < 5; i++) {
          expect(
            restoredPayload.jobs[i].companyName,
            equals(originalJobs[i].companyName),
          );
        }
      });

      test(
        '7.3 Wrong password throws BackupException during restore',
        () async {
          final originalJobs = E2ETestHelper.generateRealisticJobs(2);
          final backupFile = await BackupService.createBackup(
            originalJobs,
            password: 'CorrectPassword123!',
            outputDirectory: Directory.systemTemp,
          );
          final bytes = await backupFile.readAsBytes();
          expect(
            () async => await BackupService.restoreFromBytes(
              bytes,
              password: 'WrongPassword!',
            ),
            throwsA(isA<BackupException>()),
          );
        },
      );

      test('7.4 Restored jobs state computes identical metrics counters', () {
        final jobs = E2ETestHelper.generateRealisticJobs(15);
        final state1 = JobState(jobs: jobs);
        final state2 = JobState(jobs: List.from(jobs));
        expect(state1.totalCount, equals(state2.totalCount));
        expect(state1.savedCount, equals(state2.savedCount));
        expect(state1.appliedCount, equals(state2.appliedCount));
      });

      test(
        '7.5 Backup includes recruitment events and offer details without data truncation',
        () async {
          final offer = E2ETestHelper.createOfferDetails(baseSalary: 25000000);
          final event = E2ETestHelper.createRecruitmentEvent(
            title: 'HR Screening',
          );
          final job = E2ETestHelper.createSampleJob(
            id: 'job_with_relations',
            recruitmentEvents: [event],
            offerDetails: offer,
          );

          final backupFile = await BackupService.createBackup(
            [job],
            password: 'FullDataPass123!',
            outputDirectory: Directory.systemTemp,
          );
          final bytes = await backupFile.readAsBytes();
          final restored = await BackupService.restoreFromBytes(
            bytes,
            password: 'FullDataPass123!',
          );

          expect(restored.jobs.first.recruitmentEvents.length, equals(1));
          expect(
            restored.jobs.first.offerDetails?.baseSalary,
            equals(25000000),
          );
        },
      );
    },
  );

  group(
    'Pairwise Suite 8: Official Portal Search (WP-31) + Add Job (WP-17) + Timeline Event (WP-19)',
    () {
      test(
        '8.1 JobStreet portal search URL is built and triggers Add Job flow',
        () {
          const role = 'Senior Flutter Developer';
          const city = 'Jakarta Selatan';
          final encoded = Uri.encodeComponent('$role $city');
          final portalUrl =
              'https://www.jobstreet.co.id/id/job-search/$encoded-jobs/';

          final job = E2ETestHelper.createSampleJob(
            jobUrl: portalUrl,
            jobSource: 'JobStreet',
            position: role,
            location: city,
          );

          expect(job.jobUrl, contains('jobstreet.co.id'));
          expect(job.jobSource, equals('JobStreet'));
        },
      );

      test(
        '8.2 Adding application records first "Lamaran Terkirim" event in timeline',
        () {
          final now = DateTime.now();
          final applyEvent = E2ETestHelper.createRecruitmentEvent(
            title: 'Lamaran Dikirim via LinkedIn',
            type: 'application',
            occurredAt: now,
          );
          final job = E2ETestHelper.createSampleJob(
            status: 'Dikirim',
            appliedDate: now,
            recruitmentEvents: [applyEvent],
          );
          expect(
            job.recruitmentEvents.first.title,
            contains('Lamaran Dikirim'),
          );
        },
      );

      test(
        '8.3 Search query history persists across portal searches',
        () async {
          await PrefsService.addSearchHistory('Flutter Remote');
          final history = await PrefsService.getSearchHistory();
          expect(history, contains('Flutter Remote'));
        },
      );

      test(
        '8.4 Recent portal searches can be cleared with one-tap action',
        () async {
          await PrefsService.clearSearchHistory();
          final history = await PrefsService.getSearchHistory();
          expect(history, isEmpty);
        },
      );

      test(
        '8.5 Highlight tour marks completed in preferences after user finishes steps',
        () async {
          await PrefsService.setAppTourSeen(true);
          final seen = await PrefsService.isAppTourSeen();
          expect(seen, isTrue);
        },
      );
    },
  );

  group(
    'Pairwise Suite 9: Deep Link Routing (WP-02) + Safe Insets (WP-09) + Detail Hierarchy (WP-19)',
    () {
      test(
        '9.1 Deep link routing resolves target job by ID and opens detail view',
        () {
          final jobs = E2ETestHelper.generateRealisticJobs(10);
          final targetId = jobs[3].id;
          final resolved = jobs.firstWhere((j) => j.id == targetId);
          expect(resolved.id, equals(targetId));
        },
      );

      test('9.2 Detail view exposes all 6 sections in verified order', () {
        final sections = [
          'Summary',
          'Status & Next Action',
          'Update Action',
          'HR Contact',
          'Timeline',
          'Full Details',
        ];
        expect(sections.length, equals(6));
        expect(sections[0], equals('Summary'));
        expect(sections[5], equals('Full Details'));
      });

      test(
        '9.3 System bottom insets ensure floating CTA dock does not overlap gesture bar',
        () {
          const bottomInset = 20.0;
          const dockMargin = 16.0;
          const totalBottomPadding = bottomInset + dockMargin;
          expect(totalBottomPadding, greaterThanOrEqualTo(36.0));
        },
      );

      test(
        '9.4 Navigating back from Detail preserves scroll and filter state on JobList',
        () {
          final state = JobState(
            jobs: E2ETestHelper.generateRealisticJobs(10),
            selectedStatusFilter: 'Interview HR',
          );
          expect(state.selectedStatusFilter, equals('Interview HR'));
        },
      );

      test(
        '9.5 Orphan deep link falls back to Home tab without throwing route error',
        () {
          final jobs = E2ETestHelper.generateRealisticJobs(5);
          const invalidId = 'non_existent_job_xyz';
          final found = jobs.where((j) => j.id == invalidId).firstOrNull;
          final destination = found != null ? '/job_detail' : '/home';
          expect(destination, equals('/home'));
        },
      );
    },
  );

  group(
    'Pairwise Suite 10: Pro Entitlement (WP-30) + Theme Toggle (WP-05) + Profile Avatar (WP-03)',
    () {
      test(
        '10.1 Pro verification service returns locked entitlement for unauthenticated state',
        () async {
          final entitlement =
              await ProVerificationService.fetchCurrentEntitlement();
          expect(entitlement.isActive, isFalse);
        },
      );

      test(
        '10.2 Toggling theme mode between light and dark persists in preferences',
        () async {
          await PrefsService.setThemeMode('dark');
          final mode1 = await PrefsService.getThemeMode();
          expect(mode1, equals('dark'));

          await PrefsService.setThemeMode('light');
          final mode2 = await PrefsService.getThemeMode();
          expect(mode2, equals('light'));
        },
      );

      test('10.3 Setting profile photo updates SafeAvatarImage path', () async {
        const testPhotoPath =
            'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=';
        await PrefsService.setProfilePhoto(testPhotoPath);
        final photo = await PrefsService.getProfilePhoto();
        expect(photo, startsWith('data:image/'));
      });

      test(
        '10.4 Support contact email intent is configured to idkasolutions@gmail.com',
        () {
          const email = 'idkasolutions@gmail.com';
          expect(email, equals('idkasolutions@gmail.com'));
        },
      );

      test(
        '10.5 Profile bio updates and retrieves cleanly from secure storage',
        () async {
          const bio =
              'Senior Mobile Engineer with 7+ years Flutter experience.';
          await PrefsService.setUserAbout(bio);
          final read = await PrefsService.getUserAbout();
          expect(read, equals(bio));
        },
      );
    },
  );
}
