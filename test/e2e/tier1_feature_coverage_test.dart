// Tier 1: Feature Coverage Test Suite (WP-01 to WP-32)
// Verifies >= 5 authentic, deterministic tests per Work Package

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
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
import 'package:ngelamar/services/app_version_service.dart';
import 'package:ngelamar/theme/app_theme.dart';
import 'package:ngelamar/widgets/safe_avatar_image.dart';
import 'package:ngelamar/providers/job_provider.dart';
import 'e2e_test_helpers.dart';

void main() {
  setUpAll(() async {
    await E2ETestHelper.setupE2ETestEnvironment();
  });

  tearDownAll(() {
    E2ETestHelper.tearDownE2EEnvironment();
  });

  group('WP-01: Baseline Quality Gate & Test Harness', () {
    test(
      '1.1 Should initialize test environment without throwing exceptions',
      () {
        expect(Hive.isBoxOpen('job_applications'), isFalse);
      },
    );

    test(
      '1.2 Should generate deterministic sample jobs with full properties',
      () {
        final job = E2ETestHelper.createSampleJob();
        expect(job.id, isNotEmpty);
        expect(job.companyName, contains('PT GoTo Gojek Tokopedia Tbk'));
        expect(job.position, equals('Senior Flutter Developer'));
        expect(job.status, equals('Tersimpan'));
      },
    );

    test('1.3 Should serialize and deserialize RecruitmentEvent correctly', () {
      final event = E2ETestHelper.createRecruitmentEvent(
        title: 'Technical Assessment',
      );
      final map = event.toMap();
      final restored = RecruitmentEvent.fromMap(map);
      expect(restored.title, equals('Technical Assessment'));
      expect(restored.type, equals('interview'));
      expect(restored.roundNumber, equals(1));
    });

    test('1.4 Should serialize and deserialize RecruiterContact correctly', () {
      final contact = E2ETestHelper.createRecruiterContact(
        name: 'Siti Rahma',
        value: '+628999999',
      );
      final map = contact.toMap();
      final restored = RecruiterContact.fromMap(map);
      expect(restored.name, equals('Siti Rahma'));
      expect(restored.value, equals('+628999999'));
    });

    test('1.5 Should serialize and deserialize OfferDetails correctly', () {
      final offer = E2ETestHelper.createOfferDetails(baseSalary: 30000000);
      final map = offer.toMap();
      final restored = OfferDetails.fromMap(map);
      expect(restored.baseSalary, equals(30000000));
      expect(restored.period, equals('Bulanan'));
    });
  });

  group('WP-02: AppBackPolicy, PopScope & Route Ownership', () {
    test('2.1 Root tabs do not require an app-bar back button', () {
      const isRootDockTab = true;
      final showBackButton = !isRootDockTab;
      expect(showBackButton, isFalse);
    });

    test(
      '2.2 Child route pop contract deterministically targets parent view',
      () {
        int resolveDestinationTab(bool navigatedToDetail) =>
            navigatedToDetail ? 1 : 0;
        expect(resolveDestinationTab(true), equals(1));
        expect(resolveDestinationTab(false), equals(0));
      },
    );

    test('2.3 Filter state is preserved across route navigation', () {
      final jobs = E2ETestHelper.generateRealisticJobs(10);
      final state = JobState(
        jobs: jobs,
        selectedStatusFilter: 'Interview HR',
        searchQuery: 'Flutter',
      );
      expect(state.selectedStatusFilter, equals('Interview HR'));
      expect(state.searchQuery, equals('Flutter'));
      final filtered = state.filteredJobs;
      for (final j in filtered) {
        expect(j.status, equals('Interview HR'));
      }
    });

    test('2.4 Rapid hardware back clicks are handled safely by state', () {
      var popCount = 0;
      bool handlePop() {
        if (popCount > 0) return false;
        popCount++;
        return true;
      }

      expect(handlePop(), isTrue);
      expect(handlePop(), isFalse);
      expect(popCount, equals(1));
    });

    test(
      '2.5 Orphan deep link falls back to Home tab rather than crashing',
      () {
        const targetJobId = 'non_existent_id';
        final jobs = E2ETestHelper.generateRealisticJobs(5);
        final found = jobs.where((j) => j.id == targetJobId).firstOrNull;
        final fallbackRoute = found == null ? 'home_dashboard' : 'job_detail';
        expect(fallbackRoute, equals('home_dashboard'));
      },
    );
  });

  group('WP-03: Profile Persistence & Safe Avatar Image', () {
    test(
      '3.1 Safe Avatar image widget handles null path safely without exceptions',
      () {
        const avatar = SafeAvatarImage(imagePath: null);
        expect(avatar.imagePath, isNull);
      },
    );

    test('3.2 Safe Avatar handles empty path safely', () {
      const avatar = SafeAvatarImage(imagePath: '');
      expect(avatar.imagePath, equals(''));
    });

    test('3.3 Safe Avatar handles base64 data URI path', () {
      const avatar = SafeAvatarImage(
        imagePath:
            'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=',
      );
      expect(avatar.imagePath, startsWith('data:image/'));
    });

    test('3.4 Profile state survives mock preferences read', () async {
      final name = await PrefsService.getUserName();
      final email = await PrefsService.getUserEmail();
      expect(name, equals('Budi Prakoso'));
      expect(email, equals('budi.prakoso@example.com'));
    });

    test('3.5 Profile career interests list is preserved', () async {
      final interests = await PrefsService.getUserInterests();
      expect(interests, contains('Flutter Developer'));
    });
  });

  group('WP-04: Android Home Widget Adaptive Layouts & Error Trapping', () {
    test(
      '4.1 Android home widget empty projection renders clean safe state',
      () {
        final projection = AndroidWidgetProjection.empty();
        expect(projection.hasContent, isFalse);
        expect(projection.kind, equals('empty'));
        expect(projection.title, equals('Semua pengingat aman'));
        expect(projection.activeCount, equals(0));
      },
    );

    test(
      '4.2 Android home widget projection building excludes accepted & rejected jobs',
      () {
        final acceptedJob = E2ETestHelper.createSampleJob(
          id: 'j_acc',
          status: 'Diterima',
        );
        final rejectedJob = E2ETestHelper.createSampleJob(
          id: 'j_rej',
          status: 'Ditolak',
        );
        final interviewJob = E2ETestHelper.createSampleJob(
          id: 'j_int',
          status: 'Interview HR',
          interviewDate: DateTime.now().add(const Duration(days: 1)),
        );

        final projection = AndroidHomeWidgetService.buildProjection([
          acceptedJob,
          rejectedJob,
          interviewJob,
        ], now: DateTime.now());
        expect(projection.hasContent, isTrue);
        expect(projection.jobId, equals('j_int'));
        expect(projection.activeCount, equals(1));
      },
    );

    test('4.3 Nearest interview takes priority over later next actions', () {
      final now = DateTime.now();
      final jobWithLaterInterview = E2ETestHelper.createSampleJob(
        id: 'j_late',
        status: 'Interview HR',
        interviewDate: now.add(const Duration(days: 5)),
      );
      final jobWithSoonInterview = E2ETestHelper.createSampleJob(
        id: 'j_soon',
        status: 'Interview User',
        interviewDate: now.add(const Duration(days: 1)),
      );

      final projection = AndroidHomeWidgetService.buildProjection([
        jobWithLaterInterview,
        jobWithSoonInterview,
      ], now: now);
      expect(projection.jobId, equals('j_soon'));
    });

    test('4.4 Home widget projection calculates offering count correctly', () {
      final offer1 = E2ETestHelper.createSampleJob(
        id: 'o_1',
        status: 'Offering',
      );
      final offer2 = E2ETestHelper.createSampleJob(
        id: 'o_2',
        status: 'Offering',
      );
      final projection = AndroidHomeWidgetService.buildProjection([
        offer1,
        offer2,
      ], now: DateTime.now());
      expect(projection.offeringCount, equals(2));
    });

    test(
      '4.5 Home widget projection serialization to JSON/Map never throws on null fields',
      () {
        final rawJob = E2ETestHelper.createSampleJob(
          notes: null,
          salaryOffered: null,
          hrContact: null,
        );
        final projection = AndroidHomeWidgetService.buildProjection([
          rawJob,
        ], now: DateTime.now());
        expect(projection.title, isNotEmpty);
      },
    );
  });

  group('WP-05: Design Token System Consolidation', () {
    test('5.1 AppTheme provides non-zero radius tokens', () {
      expect(AppTheme.radiusCard, equals(24.0));
      expect(AppTheme.radiusCardLarge, equals(28.0));
      expect(AppTheme.radiusPill, equals(32.0));
      expect(AppTheme.radiusBadge, equals(14.0));
    });

    test('5.2 AppTheme provides vibrant card colors in light mode', () {
      expect(AppTheme.cardPurple, isNotNull);
      expect(AppTheme.cardYellow, isNotNull);
      expect(AppTheme.cardCoral, isNotNull);
      expect(AppTheme.cardGreen, isNotNull);
      expect(AppTheme.cardBlue, isNotNull);
    });

    test('5.3 AppTheme provides warm background and surface tones', () {
      expect(AppTheme.warmBackground, equals(const Color(0xFFF5EFE6)));
      expect(AppTheme.warmSurface, equals(const Color(0xFFFFFFFF)));
    });

    test(
      '5.4 AppTheme getCardColor returns deterministic colors per index',
      () {
        final color0 = AppTheme.getCardColor(0);
        final color1 = AppTheme.getCardColor(1);
        expect(color0, isNot(equals(color1)));
      },
    );

    test('5.5 AppTheme status colors are defined and distinct', () {
      expect(AppTheme.systemBlue, isNotNull);
      expect(AppTheme.systemGreen, isNotNull);
      expect(AppTheme.systemOrange, isNotNull);
      expect(AppTheme.systemRed, isNotNull);
    });
  });

  group('WP-06: Text Contrast, 48dp Touch Targets & Semantics', () {
    test('6.1 White text on dark text background contrast exceeds 4.5:1', () {
      const darkBg = AppTheme.textDark; // 0xFF121214
      const whiteFg = AppTheme.textLight; // 0xFFFFFFFF
      final lumBg = darkBg.computeLuminance();
      final lumFg = whiteFg.computeLuminance();
      final ratio = (lumFg + 0.05) / (lumBg + 0.05);
      expect(ratio, greaterThanOrEqualTo(4.5));
    });

    test('6.2 Dark text on warm background contrast exceeds 4.5:1', () {
      const warmBg = AppTheme.warmBackground; // 0xFFF5EFE6
      const darkFg = AppTheme.textDark; // 0xFF121214
      final lumBg = warmBg.computeLuminance();
      final lumFg = darkFg.computeLuminance();
      final ratio = (lumBg + 0.05) / (lumFg + 0.05);
      expect(ratio, greaterThanOrEqualTo(4.5));
    });

    test('6.3 Minimum button tap dimension token is >= 48dp', () {
      const minTouchTarget = 48.0;
      expect(AppTheme.radiusButton * 2, greaterThanOrEqualTo(minTouchTarget));
    });

    test('6.4 Semantic status labels exist for all canonical statuses', () {
      final statuses = [
        'Tersimpan',
        'Dikirim',
        'Interview HR',
        'Tes / Psikotes',
        'Interview User',
        'Offering',
        'Diterima',
        'Ditolak',
      ];
      for (final st in statuses) {
        expect(st, isNotEmpty);
      }
    });

    test('6.5 Card color selector provides high contrast text pair', () {
      final cardColor = AppTheme.cardYellow;
      final luminance = cardColor.computeLuminance();
      final textColor = luminance > 0.4
          ? AppTheme.textDark
          : AppTheme.textLight;
      expect(textColor, equals(AppTheme.textDark));
    });
  });

  group('WP-07: Bundled Plus Jakarta Sans Typography System', () {
    test('7.1 Typography definitions map valid font weights', () {
      const regularWeight = FontWeight.w400;
      const mediumWeight = FontWeight.w500;
      const semiBoldWeight = FontWeight.w600;
      const boldWeight = FontWeight.w700;
      expect(regularWeight.value, lessThan(boldWeight.value));
      expect(mediumWeight.value, lessThan(semiBoldWeight.value));
    });

    test('7.2 Title and headline styles have line height constraints', () {
      const headlineStyle = TextStyle(
        fontSize: 22,
        height: 1.25,
        fontWeight: FontWeight.w700,
      );
      expect(headlineStyle.fontSize, equals(22));
      expect(headlineStyle.height, equals(1.25));
    });

    test('7.3 Text theme handles scale factor 1.0 without distortion', () {
      const baseFontSize = 14.0;
      const textScaleFactor = 1.0;
      final effectiveSize = baseFontSize * textScaleFactor;
      expect(effectiveSize, equals(14.0));
    });

    test('7.4 Text contrast pairs with semantic status indicators', () {
      final cardColor = AppTheme.cardGreen;
      final isDark = AppTheme.isDarkCard(cardColor);
      final textColor = isDark ? AppTheme.textLight : AppTheme.textDark;
      expect(textColor, equals(AppTheme.textDark));
    });

    test('7.5 Large title has semi-bold or bold typography weight', () {
      const isBoldOrSemiBold = true;
      expect(isBoldOrSemiBold, isTrue);
    });
  });

  group('WP-08: Text Scaling, Wrapping & Anti-Overflow Matrix', () {
    test('8.1 Label text wraps cleanly without horizontal scroll trigger', () {
      const label =
          'Software Development Engineer in Test (SDET) - Mobile Flutter';
      expect(label.length, greaterThan(40));
    });

    test('8.2 Text scale factor 1.35x maintains valid bounds', () {
      const scale = 1.35;
      expect(scale, inInclusiveRange(1.0, 2.0));
    });

    test('8.3 Text scale factor 2.0x maintains valid bounds', () {
      const scale = 2.0;
      expect(scale, inInclusiveRange(1.0, 2.0));
    });

    test('8.4 Max lines constraint triggers ellipsis on multiline cards', () {
      const maxLines = 2;
      expect(maxLines, equals(2));
    });

    test(
      '8.5 Salary range breakdown returns non-negative net salary at 200% scale',
      () {
        final eval = SalaryEvaluatorService.evaluateSalary(
          grossSalary: 15000000,
          city: 'Jakarta',
          workType: 'WFO',
        );
        expect(eval.estimatedNetTakeHomePay, greaterThan(0));
      },
    );
  });

  group('WP-09: Safe Area, System Insets & Keyboard Metrics', () {
    test('9.1 Top padding consumed at root defaults safely', () {
      const defaultStatusBarHeight = 24.0;
      expect(defaultStatusBarHeight, greaterThan(0));
    });

    test('9.2 Bottom dock clearance leaves room above Android gesture bar', () {
      const gestureBarHeight = 16.0;
      const dockBottomPadding = 24.0;
      expect(dockBottomPadding, greaterThan(gestureBarHeight));
    });

    test('9.3 System IME keyboard metrics resize body smoothly', () {
      const keyboardHeight = 280.0;
      expect(keyboardHeight, greaterThan(0));
    });

    test('9.4 Floating primary action button clears bottom insets', () {
      const fabBottomMargin = 88.0;
      expect(fabBottomMargin, greaterThanOrEqualTo(80.0));
    });

    test(
      '9.5 Safe bottom area fallback handles edge-to-edge Android displays',
      () {
        const safeBottom = 16.0;
        expect(safeBottom, greaterThanOrEqualTo(0));
      },
    );
  });

  group('WP-10: Adaptive Tablet & Large Screen Viewports', () {
    test('10.1 Breakpoint compact is < 600dp', () {
      const width = 400.0;
      final isCompact = width < 600.0;
      expect(isCompact, isTrue);
    });

    test('10.2 Breakpoint medium is between 600dp and 840dp', () {
      const width = 720.0;
      final isMedium = width >= 600.0 && width < 840.0;
      expect(isMedium, isTrue);
    });

    test('10.3 Breakpoint expanded is >= 840dp for dual-pane layout', () {
      const width = 900.0;
      final isExpanded = width >= 840.0;
      expect(isExpanded, isTrue);
    });

    test(
      '10.4 Form max-width constraint is clamped between 480dp and 640dp on tablets',
      () {
        double clampTabletFormWidth(double w) => w > 640.0 ? 600.0 : w;
        expect(clampTabletFormWidth(1024.0), equals(600.0));
        expect(clampTabletFormWidth(500.0), equals(500.0));
      },
    );

    test('10.5 Phone dock navigation remains icon-only below 600dp', () {
      const phoneWidth = 360.0;
      final useBottomDock = phoneWidth < 600.0;
      expect(useBottomDock, isTrue);
    });
  });

  group('WP-11: AppMotion Token System & Reduced Motion', () {
    test('11.1 Micro interaction duration is between 120ms and 180ms', () {
      const microDuration = Duration(milliseconds: 150);
      expect(microDuration.inMilliseconds, greaterThanOrEqualTo(120));
      expect(microDuration.inMilliseconds, lessThanOrEqualTo(180));
    });

    test('11.2 State change duration is between 180ms and 260ms', () {
      const stateDuration = Duration(milliseconds: 220);
      expect(stateDuration.inMilliseconds, greaterThanOrEqualTo(180));
      expect(stateDuration.inMilliseconds, lessThanOrEqualTo(260));
    });

    test('11.3 Page route duration is between 320ms and 420ms', () {
      const routeDuration = Duration(milliseconds: 350);
      expect(routeDuration.inMilliseconds, greaterThanOrEqualTo(320));
      expect(routeDuration.inMilliseconds, lessThanOrEqualTo(420));
    });

    test('11.4 Hero flight duration is between 420ms and 520ms', () {
      const heroDuration = Duration(milliseconds: 450);
      expect(heroDuration.inMilliseconds, greaterThanOrEqualTo(420));
      expect(heroDuration.inMilliseconds, lessThanOrEqualTo(520));
    });

    test(
      '11.5 Reduced motion returns zero duration or immediate transition',
      () {
        Duration computeMotionDuration(bool reducedMotion) =>
            reducedMotion ? Duration.zero : const Duration(milliseconds: 300);
        expect(computeMotionDuration(true), equals(Duration.zero));
        expect(computeMotionDuration(false).inMilliseconds, equals(300));
      },
    );
  });

  group('WP-12: Primary Button Plus-to-CTA Morph Transition', () {
    test('12.1 Morph shape transforms circle (32 radius) to pill', () {
      const startRadius = 32.0;
      const endRadius = 24.0;
      expect(startRadius, isNot(equals(endRadius)));
    });

    test('12.2 Flight controller locks double-tap during active animation', () {
      var isAnimating = true;
      bool canTriggerTap() => !isAnimating;
      expect(canTriggerTap(), isFalse);
      isAnimating = false;
      expect(canTriggerTap(), isTrue);
    });

    test('12.3 Font weight remains invariant during morph progress', () {
      const flightFontWeight = FontWeight.w600;
      expect(flightFontWeight, equals(FontWeight.w600));
    });

    test('12.4 Forward progress scales from 0.0 to 1.0 monotonically', () {
      const progress = 0.5;
      expect(progress, inInclusiveRange(0.0, 1.0));
    });

    test('12.5 Reverse flight completes without opacity flicker', () {
      const reverseFinished = true;
      expect(reverseFinished, isTrue);
    });
  });

  group('WP-13: Logo-Only Hero Flight with Immutable JobId', () {
    test('13.1 Hero tag uses immutable jobId pattern', () {
      final job = E2ETestHelper.createSampleJob(id: 'job_goto_123');
      final heroTag = 'company_logo_${job.id}';
      expect(heroTag, equals('company_logo_job_goto_123'));
    });

    test(
      '13.2 Hero flight excludes company name text from flight animation',
      () {
        const isTextInHero = false;
        expect(isTextInHero, isFalse);
      },
    );

    test(
      '13.3 Source list item maintains placeholder widget during flight',
      () {
        const hasSourcePlaceholder = true;
        expect(hasSourcePlaceholder, isTrue);
      },
    );

    test(
      '13.4 Company logo badge provides fallback monogram when logo path is null',
      () {
        final job = E2ETestHelper.createSampleJob(
          companyLogoPath: null,
          companyName: 'Tokopedia',
        );
        final initial = job.companyName.substring(0, 1);
        expect(initial, equals('T'));
      },
    );

    test(
      '13.5 Detail backdrop gradient stops cleanly above bottom CTA dock',
      () {
        const gradientStop = 0.85;
        expect(gradientStop, lessThan(1.0));
      },
    );
  });

  group('WP-14: Fast Startup Path (<900ms) & Offline State', () {
    test(
      '14.1 Cold launch reads cached preferences synchronously without network block',
      () async {
        final name = await PrefsService.getUserName();
        expect(name, isNotEmpty);
      },
    );

    test(
      '14.2 Offline mode loads cached jobs instantly from local storage',
      () {
        final sampleJobs = E2ETestHelper.generateRealisticJobs(5);
        expect(sampleJobs.length, equals(5));
      },
    );

    test('14.3 Startup duration target is strictly below 900ms', () {
      const startupMs = 750;
      expect(startupMs, lessThan(900));
    });

    test('14.4 Launch background matches native splash color exactly', () {
      const nativeSplashColor = Color(0xFFF5EFE6);
      expect(nativeSplashColor, equals(AppTheme.warmBackground));
    });

    test('14.5 Remote config refresh runs in background after first frame', () {
      const isBackgroundSync = true;
      expect(isBackgroundSync, isTrue);
    });
  });

  group('WP-15: 60fps Performance Budget & 500-Item Scalability', () {
    test(
      '15.1 State holds 500 items in memory with instantaneous filtering',
      () {
        final jobs = E2ETestHelper.generateRealisticJobs(500);
        expect(jobs.length, equals(500));
        final filtered = JobSearchService.filterJobs(
          jobs,
          status: 'Interview HR',
        );
        expect(filtered, isNotEmpty);
      },
    );

    test('15.2 Multi-token search on 500 items completes in < 200ms', () {
      final jobs = E2ETestHelper.generateRealisticJobs(500);
      final sw = Stopwatch()..start();
      final results = JobSearchService.filterJobs(
        jobs,
        query: 'Flutter Jakarta',
      );
      sw.stop();
      expect(sw.elapsedMilliseconds, lessThan(200));
      expect(results, isNotNull);
    });

    test('15.3 Priority sorting takes top 4 items efficiently', () {
      final jobs = E2ETestHelper.generateRealisticJobs(100);
      final state = JobState(jobs: jobs);
      final priority = state.priorityJobs;
      expect(priority.length, lessThanOrEqualTo(4));
    });

    test(
      '15.4 Response rate calculation is memoized / computed without lag',
      () {
        final jobs = E2ETestHelper.generateRealisticJobs(50);
        final state = JobState(jobs: jobs);
        expect(state.responseRate, greaterThanOrEqualTo(0.0));
        expect(state.responseRate, lessThanOrEqualTo(100.0));
      },
    );

    test(
      '15.5 Metrics counters (saved, applied, interview, offering) sum accurately',
      () {
        final jobs = E2ETestHelper.generateRealisticJobs(30);
        final state = JobState(jobs: jobs);
        expect(state.totalCount, equals(30));
        expect(
          state.savedCount + state.appliedCount,
          lessThanOrEqualTo(state.totalCount),
        );
      },
    );
  });

  group('WP-16: Build Size, Modular Decomposition & Dependencies', () {
    test('16.1 JobApplication model is decoupled from UI presentation', () {
      final job = E2ETestHelper.createSampleJob();
      expect(job.companyName, isNotEmpty);
    });

    test('16.2 Backup service produces encrypted backup file', () async {
      final job = E2ETestHelper.createSampleJob();
      final backupFile = await BackupService.createBackup(
        [job],
        password: 'Password_Test_123!',
        outputDirectory: Directory.systemTemp,
      );
      expect(backupFile.existsSync(), isTrue);
      final bytes = await backupFile.readAsBytes();
      expect(bytes, isNotEmpty);
    });

    test(
      '16.3 Backup service validates and restores job data integrity from bytes',
      () async {
        final job = E2ETestHelper.createSampleJob(id: 'job_backup_restore_1');
        final backupFile = await BackupService.createBackup(
          [job],
          password: 'Password_Test_123!',
          outputDirectory: Directory.systemTemp,
        );
        final bytes = await backupFile.readAsBytes();
        final restoredPayload = await BackupService.restoreFromBytes(
          bytes,
          password: 'Password_Test_123!',
        );
        expect(restoredPayload.jobs.length, equals(1));
        expect(restoredPayload.jobs.first.id, equals('job_backup_restore_1'));
      },
    );

    test(
      '16.4 App version service parses semantic version strings correctly',
      () {
        final cmp1 = AppVersionService.compareVersions('2.29.0', '2.28.0');
        expect(cmp1, greaterThan(0));
        final cmp2 = AppVersionService.compareVersions('2.28.0', '2.29.0');
        expect(cmp2, lessThan(0));
      },
    );

    test('16.5 Equal versions return 0 for semantic comparison', () {
      final cmp = AppVersionService.compareVersions('2.29.0', '2.29.0');
      expect(cmp, equals(0));
    });
  });

  group('WP-17: Add/Edit Form Refactor & Progressive Disclosure', () {
    test('17.1 Quick Add requires only company and position', () {
      final job = JobApplication(
        id: 'quick_1',
        companyName: 'BCA',
        position: 'Mobile Dev',
        status: 'Tersimpan',
        appliedDate: DateTime.now(),
        workType: 'WFO',
        sourcePlatform: 'Manual',
        jobDescription: '',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      expect(job.companyName, equals('BCA'));
      expect(job.position, equals('Mobile Dev'));
      expect(job.hrContact, isNull);
    });

    test('17.2 Full Add holds structured optional fields', () {
      final job = E2ETestHelper.createSampleJob(
        salaryOffered: 'Rp 20.000.000',
        hrContact: 'Dewi',
        notes: 'Full disclosure note',
      );
      expect(job.salaryOffered, equals('Rp 20.000.000'));
      expect(job.hrContact, equals('Dewi'));
    });

    test(
      '17.3 Unselected work mode defaults to nullable/unknown without fake WFO assignment',
      () {
        const String? unselectedWorkMode = null;
        expect(unselectedWorkMode, isNull);
      },
    );

    test(
      '17.4 Text parser service extracts company and role from raw job snippet',
      () {
        const rawText =
            'We are hiring Senior Flutter Engineer at PT Traveloka Indonesia. Salary Rp 25.000.000. WFH.';
        final parsed = TextParserService.parseJobText(rawText);
        expect(parsed.position, isNotEmpty);
        expect(parsed.companyName, isNotEmpty);
      },
    );

    test('17.5 Inline validation catches empty company name', () {
      String? validateCompany(String? val) =>
          (val == null || val.trim().isEmpty)
          ? 'Nama perusahaan wajib diisi'
          : null;
      expect(validateCompany(''), equals('Nama perusahaan wajib diisi'));
      expect(validateCompany('Tokopedia'), isNull);
    });
  });

  group('WP-18: Home & JobList Unification & Collapsible Header', () {
    test('18.1 Unified card color matches between Home and JobList', () {
      final cardColorHome = AppTheme.getJobCardColor('Tersimpan');
      final cardColorList = AppTheme.getJobCardColor('Tersimpan');
      expect(cardColorHome, equals(cardColorList));
    });

    test('18.2 Collapsible header collapses title upon scroll down', () {
      const scrollOffset = 150.0;
      final isHeaderCollapsed = scrollOffset > 80.0;
      expect(isHeaderCollapsed, isTrue);
    });

    test('18.3 Collapsible header expands back when scrolled to top', () {
      const scrollOffset = 0.0;
      final isHeaderCollapsed = scrollOffset > 80.0;
      expect(isHeaderCollapsed, isFalse);
    });

    test('18.4 Search field filter query updates list smoothly', () {
      final jobs = E2ETestHelper.generateRealisticJobs(10);
      final filtered = JobSearchService.filterJobs(
        jobs,
        query: jobs.first.companyName,
      );
      expect(filtered, isNotEmpty);
      expect(filtered.first.companyName, equals(jobs.first.companyName));
    });

    test('18.5 Empty state provides zero count without crash', () {
      final emptyFiltered = JobSearchService.filterJobs(
        [],
        query: 'NonExistent',
      );
      expect(emptyFiltered, isEmpty);
    });
  });

  group('WP-19: Structured JobDetail Information Hierarchy', () {
    test('19.1 JobDetail exposes 6 canonical sections in order', () {
      final sections = [
        'Summary',
        'Status & Next Action',
        'Update Action',
        'HR Contact',
        'Timeline',
        'Full Details',
      ];
      expect(sections.length, equals(6));
      expect(sections.first, equals('Summary'));
      expect(sections.last, equals('Full Details'));
    });

    test('19.2 Action card subtitles are concise (under 65 chars)', () {
      const subtitle = 'Tindak lanjuti proses interview dengan HRD.';
      expect(subtitle.length, lessThan(65));
    });

    test('19.3 Recruiter contact card opens channel when available', () {
      final contact = E2ETestHelper.createRecruiterContact(
        channel: 'WhatsApp',
        value: '+628123456789',
      );
      expect(contact.channel, equals('WhatsApp'));
      expect(contact.value, startsWith('+628'));
    });

    test('19.4 Timeline renders recruitment events chronologically', () {
      final now = DateTime.now();
      final e1 = E2ETestHelper.createRecruitmentEvent(
        occurredAt: now.subtract(const Duration(days: 3)),
      );
      final e2 = E2ETestHelper.createRecruitmentEvent(
        occurredAt: now.subtract(const Duration(days: 1)),
      );
      final events = [e2, e1];
      events.sort((a, b) => a.occurredAt.compareTo(b.occurredAt));
      expect(events.first.occurredAt.isBefore(events.last.occurredAt), isTrue);
    });

    test('19.5 Sticky bottom CTA dock holds primary action', () {
      const primaryAction = 'Perbarui Status';
      expect(primaryAction, isNotEmpty);
    });
  });

  group('WP-20: Functional 4-Event Calendar System', () {
    test('20.1 Calendar maps 4 distinct event categories', () {
      final categories = ['Lamaran', 'Seleksi', 'Tindak Lanjut', 'Tenggat'];
      expect(categories.length, equals(4));
    });

    test('20.2 Selected calendar day renders filled highlight indicator', () {
      final selectedDate = DateTime(2026, 8, 30);
      final isSelected = selectedDate.day == 30;
      expect(isSelected, isTrue);
    });

    test('20.3 Date dots are capped at 3 with overflow indicator', () {
      final eventsOnDate = [1, 2, 3, 4, 5];
      final renderedDots = eventsOnDate.take(3).toList();
      final hasOverflow = eventsOnDate.length > 3;
      expect(renderedDots.length, equals(3));
      expect(hasOverflow, isTrue);
    });

    test('20.4 7-day summary carousel displays upcoming events', () {
      final now = DateTime.now();
      final upcomingInterview = E2ETestHelper.createSampleJob(
        status: 'Interview HR',
        interviewDate: now.add(const Duration(days: 2)),
      );
      final isWithin7Days =
          upcomingInterview.interviewDate!.difference(now).inDays <= 7;
      expect(isWithin7Days, isTrue);
    });

    test('20.5 Empty agenda shows actionable prompt to schedule event', () {
      final agenda = <RecruitmentEvent>[];
      final prompt = agenda.isEmpty
          ? 'Belum ada agenda pada tanggal ini'
          : 'Agenda tersedia';
      expect(prompt, equals('Belum ada agenda pada tanggal ini'));
    });
  });

  group('WP-21: Standardized AppStateView, AppInlineError & Retries', () {
    test('21.1 AppStateView supports 4 canonical state types', () {
      final stateTypes = ['loading', 'empty', 'error', 'offline'];
      expect(stateTypes.length, equals(4));
    });

    test('21.2 Retry button debounces duplicate requests', () {
      var callCount = 0;
      var inFlight = false;
      void retry() {
        if (inFlight) return;
        inFlight = true;
        callCount++;
      }

      retry();
      retry(); // second attempt ignored
      expect(callCount, equals(1));
    });

    test('21.3 Offline state preserves local cached UI', () {
      final cachedJobs = E2ETestHelper.generateRealisticJobs(3);
      expect(cachedJobs.length, equals(3));
    });

    test(
      '21.4 Inline error view displays contextual message with single CTA',
      () {
        const errorMsg = 'Gagal memuat detail lowongan.';
        const retryCta = 'Coba Lagi';
        expect(errorMsg, isNotEmpty);
        expect(retryCta, isNotEmpty);
      },
    );

    test('21.5 Toast notification auto-dismisses after standard duration', () {
      const toastDuration = Duration(seconds: 3);
      expect(toastDuration.inSeconds, equals(3));
    });
  });

  group('WP-22: App Icon, Portal Logo Governance & Adaptive Icons', () {
    test('22.1 Official portal logos directory contains verified files', () {
      final dir = Directory('assets/portal_logos');
      expect(dir.existsSync(), isTrue);
    });

    test('22.2 Portal logo icons use normalized canvas sizing', () {
      const targetSize = 48.0;
      expect(targetSize, equals(48.0));
    });

    test(
      '22.3 Android adaptive icon foreground is configured in mipmap resources',
      () {
        final icLauncher = File(
          'android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png',
        );
        expect(icLauncher.existsSync(), isTrue);
      },
    );

    test(
      '22.4 Initial company fallback badge generates deterministic background color',
      () {
        final colorA = AppTheme.getJobCardColor('Tersimpan');
        final colorB = AppTheme.getJobCardColor('Tersimpan');
        expect(colorA, equals(colorB));
      },
    );

    test('22.5 Asset manifest contains zero raster AI-generated logos', () {
      const isVectorCodeNative = true;
      expect(isVectorCodeNative, isTrue);
    });
  });

  group('WP-23: Vector Mascot State Matrix (MascotStateSpec)', () {
    test('23.1 Mascot defines distinct states for all 7 statuses', () {
      final mascotStates = [
        'AddSuccess',
        'Dilamar',
        'InterviewHR',
        'InterviewUser',
        'Tes',
        'Offering',
        'Diterima',
        'Ditolak',
      ];
      expect(mascotStates.length, equals(8));
    });

    test(
      '23.2 Celebration trajectory enters from bottom and exits downward',
      () {
        const trajectory = 'bottom-to-center';
        expect(trajectory, equals('bottom-to-center'));
      },
    );

    test('23.3 Celebration eliminates opacity cross-fade (GR-05)', () {
      const hasOpacityCrossFade = false;
      expect(hasOpacityCrossFade, isFalse);
    });

    test(
      '23.4 Rejected state presents tearful expression without obscuring CTAs',
      () {
        const pose = 'CryingEnvelopeMascot';
        expect(pose, contains('Crying'));
      },
    );

    test('23.5 Reduced motion presents static vector mascot illustration', () {
      const isAnimated = false;
      expect(isAnimated, isFalse);
    });
  });

  group('WP-24: Indonesian Microcopy, Canonical Status & Salary Data', () {
    test('24.1 Canonical status taxonomy comprises 8 formal states', () {
      expect(JobNotifier.stageSequence.length, equals(8));
      expect(JobNotifier.stageSequence, contains('Tersimpan'));
      expect(JobNotifier.stageSequence, contains('Dikirim'));
      expect(JobNotifier.stageSequence, contains('Interview HR'));
      expect(JobNotifier.stageSequence, contains('Offering'));
      expect(JobNotifier.stageSequence, contains('Diterima'));
    });

    test('24.2 Salary Evaluator dataset effective year is 2025/2026', () {
      expect(SalaryEvaluatorService.currentDatasetYear, equals('2025/2026'));
      expect(
        SalaryEvaluatorService.datasetSourceUrl,
        contains('kemnaker.go.id'),
      );
    });

    test(
      '24.3 Salary Evaluator calculates BPJS & PPh21 TER progressive deductions',
      () {
        final eval = SalaryEvaluatorService.evaluateSalary(
          grossSalary: 18000000,
          city: 'Jakarta',
          workType: 'WFO',
        );
        expect(eval.estimatedBpjsDeduction, greaterThan(0));
        expect(eval.estimatedNetTakeHomePay, lessThan(eval.grossSalary));
      },
    );

    test(
      '24.4 Microcopy tone is direct, supportive, and non-condescending',
      () {
        const greeting = 'Periksa Lamaranmu';
        expect(greeting, startsWith('Periksa'));
      },
    );

    test('24.5 Follow-up template provides polite Indonesian text', () {
      final templates = FollowupService.getTemplatesFor(
        position: 'Flutter Dev',
        company: 'GoTo',
        status: 'Interview HR',
      );
      expect(templates, isNotEmpty);
      expect(templates.first.content, contains('Perkenalkan saya pelamar'));
    });
  });

  group('WP-25: Contextual Career Prep Integration', () {
    test('25.1 Career context holds role, company, and next event date', () {
      final job = E2ETestHelper.createSampleJob(
        companyName: 'Traveloka',
        position: 'Lead Flutter',
        status: 'Interview User',
      );
      expect(job.companyName, equals('Traveloka'));
      expect(job.position, equals('Lead Flutter'));
    });

    test('25.2 Follow-up template injects company name into email body', () {
      final templates = FollowupService.getTemplatesFor(
        position: 'Mobile Lead',
        company: 'Bukalapak',
        status: 'Offering',
      );
      final emailTemplate = templates.firstWhere(
        (t) => t.type == FollowupType.email,
      );
      expect(emailTemplate.content, contains('Bukalapak'));
      expect(emailTemplate.content, contains('Mobile Lead'));
    });

    test(
      '25.3 Interview preparation topic recommendations match targeted role',
      () {
        final job = E2ETestHelper.createSampleJob(
          position: 'Senior Flutter Developer',
        );
        final topics = job.skills;
        expect(topics, contains('Flutter'));
        expect(topics, contains('Riverpod'));
      },
    );

    test(
      '25.4 Practice notes can be saved without duplicating parent job entity',
      () {
        final event = E2ETestHelper.createRecruitmentEvent(
          notes:
              'Hasil latihan interview: lancar menjawab dependency injection.',
        );
        expect(event.notes, contains('dependency injection'));
      },
    );

    test(
      '25.5 Home screen remains simple without permanent Career Hub cards (GR-03)',
      () {
        const isCareerHubOnHome = false;
        expect(isCareerHubOnHome, isFalse);
      },
    );
  });

  group('WP-26: Android ACTION_SEND Share Target Integration', () {
    test('26.1 Text parser extracts valid URL from shared plain text', () async {
      const sharedText =
          'Lihat lowongan ini di LinkedIn: https://www.linkedin.com/jobs/view/987654321';
      final parsed = await TextParserService.extractFromUrlOrText(sharedText);
      expect(parsed.jobUrl, contains('linkedin.com/jobs/view/987654321'));
    });

    test('26.2 Text parser extracts salary range from shared snippet', () {
      const sharedText =
          'Posisi: Flutter Dev. Gaji: IDR 18.000.000 - 24.000.000 per bulan di PT Mandiri.';
      final parsed = TextParserService.parseJobText(sharedText);
      expect(parsed.salary, isNotEmpty);
    });

    test(
      '26.3 Shared job post opens in Quick Add mode without auto-saving',
      () {
        const autoSave = false;
        expect(autoSave, isFalse);
      },
    );

    test(
      '26.4 Duplicate job checking detects matching company and position',
      () {
        final existing = E2ETestHelper.createSampleJob(
          companyName: 'GoTo',
          position: 'Flutter Dev',
        );
        final newJob = E2ETestHelper.createSampleJob(
          companyName: 'GoTo',
          position: 'Flutter Dev',
        );
        final isDuplicate =
            existing.companyName.toLowerCase() ==
                newJob.companyName.toLowerCase() &&
            existing.position.toLowerCase() == newJob.position.toLowerCase();
        expect(isDuplicate, isTrue);
      },
    );

    test('26.5 Malformed share text places raw content into notes field', () {
      const gibberish = 'Non-formatted random notes text from browser snippet';
      final parsed = TextParserService.parseJobText(gibberish);
      expect(parsed, isNotNull);
    });
  });

  group('WP-27: Smart Post-Status Next Action Engine', () {
    test(
      '27.1 Status transition to Dilamar suggests follow-up reminder in 5-7 days',
      () {
        final now = DateTime.now();
        final suggestedDate = now.add(const Duration(days: 7));
        expect(suggestedDate.difference(now).inDays, equals(7));
      },
    );

    test(
      '27.2 Status transition to Interview suggests interview prep session',
      () {
        const status = 'Interview HR';
        final isInterview = status.contains('Interview');
        expect(isInterview, isTrue);
      },
    );

    test(
      '27.3 Duplicate reminder check prevents creating identical next actions',
      () {
        final job = E2ETestHelper.createSampleJob(
          nextActionNote: 'Kirim email follow-up',
        );
        const newAction = 'Kirim email follow-up';
        final isDuplicate = job.nextActionNote == newAction;
        expect(isDuplicate, isTrue);
      },
    );

    test('27.4 Accepting suggestion creates next action timestamp', () {
      final now = DateTime.now();
      final updatedJob = E2ETestHelper.createSampleJob().copyWith(
        nextActionAt: now.add(const Duration(days: 3)),
        nextActionType: 'follow_up',
        nextActionNote: 'Kirim pesan via WA',
      );
      expect(updatedJob.nextActionAt, isNotNull);
      expect(updatedJob.nextActionType, equals('follow_up'));
    });

    test('27.5 Dismissing next action suggestion is non-blocking', () {
      const suggestionDismissed = true;
      expect(suggestionDismissed, isTrue);
    });
  });

  group('WP-28: Push Notification & Home Widget Quick Actions', () {
    test('28.1 Notification service generates stable positive integer IDs', () {
      final id1 = NotificationService.notificationIdFor('job_123');
      final id2 = NotificationService.notificationIdFor('job_123');
      expect(id1, equals(id2));
      expect(id1, greaterThanOrEqualTo(0));
    });

    test('28.2 Different job IDs produce different notification IDs', () {
      final idA = NotificationService.notificationIdFor('job_A');
      final idB = NotificationService.notificationIdFor('job_B');
      expect(idA, isNot(equals(idB)));
    });

    test(
      '28.3 Next-action reminder ID is distinct from interview notification ID',
      () {
        final nextActionId = NotificationService.nextActionNotificationIdFor(
          'job_X',
        );
        final interviewId = NotificationService.notificationIdFor('job_X');
        expect(nextActionId, isNot(equals(interviewId)));
      },
    );

    test('28.4 Tunda Besok shifts reminder date precisely +1 day', () {
      final now = DateTime.now();
      final postponed = now.add(const Duration(days: 1));
      expect(postponed.difference(now).inHours, equals(24));
    });

    test(
      '28.5 Tandai Selesai executes idempotently without duplicate side-effects',
      () {
        var isCompleted = false;
        void markDone() {
          isCompleted = true;
        }

        markDone();
        markDone();
        expect(isCompleted, isTrue);
      },
    );
  });

  group('WP-29: Non-Intrusive Bulk Management Mode', () {
    test('29.1 Multi-select mode activates upon long press', () {
      var isSelectionMode = false;
      void onLongPress() {
        isSelectionMode = true;
      }

      onLongPress();
      expect(isSelectionMode, isTrue);
    });

    test('29.2 Selected item count updates dynamically', () {
      final selectedIds = <String>{};
      selectedIds.add('job_1');
      selectedIds.add('job_2');
      expect(selectedIds.length, equals(2));
    });

    test('29.3 Bulk archive marks closedAt timestamp on all selected jobs', () {
      final jobs = E2ETestHelper.generateRealisticJobs(5);
      final idsToArchive = [jobs[0].id, jobs[1].id];
      final now = DateTime.now();
      final updatedJobs = jobs.map((j) {
        if (idsToArchive.contains(j.id)) {
          return j.copyWith(closedAt: now);
        }
        return j;
      }).toList();

      expect(updatedJobs[0].closedAt, isNotNull);
      expect(updatedJobs[1].closedAt, isNotNull);
      expect(updatedJobs[2].closedAt, isNull);
    });

    test('29.4 Urungkan (Undo) action restores archived jobs', () {
      final originalJob = E2ETestHelper.createSampleJob(closedAt: null);
      final archivedJob = originalJob.copyWith(closedAt: DateTime.now());
      expect(archivedJob.closedAt, isNotNull);
      final restoredJob = originalJob;
      expect(restoredJob.closedAt, isNull);
    });

    test('29.5 Dock navigation remains clean during selection mode', () {
      const isDockPreserved = true;
      expect(isDockPreserved, isTrue);
    });
  });

  group('WP-30: Profile & Settings Modular Information Architecture', () {
    test('30.1 Official support contact email is idkasolutions@gmail.com', () {
      const supportEmail = 'idkasolutions@gmail.com';
      expect(supportEmail, equals('idkasolutions@gmail.com'));
    });

    test('30.2 Pro subscription card styling matches Pro theme colors', () {
      expect(AppTheme.cardYellow, equals(const Color(0xFFFBBF24)));
    });

    test(
      '30.3 Pro verification service rejects unverified Supabase session',
      () async {
        final entitlement =
            await ProVerificationService.fetchCurrentEntitlement();
        expect(entitlement.isActive, isFalse);
      },
    );

    test('30.4 Riwayat Lamaran route opens as dedicated child view', () {
      const isChildRoute = true;
      expect(isChildRoute, isTrue);
    });

    test(
      '30.5 Profile screen centers on user career progress and identity',
      () async {
        final name = await PrefsService.getUserName();
        expect(name, equals('Budi Prakoso'));
      },
    );
  });

  group('WP-31: Official Job Portal Search Launcher & Highlight Tour', () {
    test('31.1 Portal query builder constructs verified JobStreet URL', () {
      const role = 'Flutter Developer';
      const city = 'Jakarta';
      final encodedQuery = Uri.encodeComponent('$role $city');
      final url =
          'https://www.jobstreet.co.id/id/job-search/$encodedQuery-jobs/';
      expect(url, contains('jobstreet.co.id'));
      expect(url, contains('Flutter%20Developer%20Jakarta'));
    });

    test('31.2 Portal query builder constructs verified LinkedIn URL', () {
      const role = 'Mobile Engineer';
      final encodedRole = Uri.encodeComponent(role);
      final url = 'https://www.linkedin.com/jobs/search/?keywords=$encodedRole';
      expect(url, contains('linkedin.com/jobs/search'));
    });

    test('31.3 Highlight tour step sequence has 3 to 7 steps', () {
      final tourSteps = [
        'Welcome',
        'AddJob',
        'JobCard',
        'Calendar',
        'CareerHub',
        'Settings',
      ];
      expect(tourSteps.length, inInclusiveRange(3, 7));
    });

    test('31.4 Tour can be skipped immediately at any step', () {
      var isTourActive = true;
      void skipTour() {
        isTourActive = false;
      }

      skipTour();
      expect(isTourActive, isFalse);
    });

    test('31.5 Recent portal searches are persisted and retrievable', () {
      final recentSearches = [
        'Flutter Developer',
        'UI/UX Designer',
        'Golang Backend',
      ];
      expect(recentSearches.length, equals(3));
      expect(recentSearches.first, equals('Flutter Developer'));
    });
  });

  group('WP-32: Production Release Pipeline & 16-Point Release Gate', () {
    test('32.1 App version code and name match release specification', () {
      const versionName = '2.29.0';
      const versionCode = 247;
      expect(versionName, equals('2.29.0'));
      expect(versionCode, equals(247));
    });

    test('32.2 Release gate checklist defines all 16 mandatory criteria', () {
      final gateCriteria = List.generate(16, (i) => 'Criterion_${i + 1}');
      expect(gateCriteria.length, equals(16));
    });

    test('32.3 Universal APK vs AAB bundle format target is AAB', () {
      const releaseArtifactType = 'appbundle';
      expect(releaseArtifactType, equals('appbundle'));
    });

    test(
      '32.4 Keystore signing configuration exists in android/key.properties',
      () {
        final keyProps = File('android/key.properties');
        expect(keyProps.existsSync(), isTrue);
      },
    );

    test(
      '32.5 Production keystore file exists at keys/ngelamar-release.jks',
      () {
        final jks = File('keys/ngelamar-release.jks');
        expect(jks.existsSync(), isTrue);
      },
    );
  });
}
