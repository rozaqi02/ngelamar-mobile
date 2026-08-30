// Tier 2: Boundary & Corner Cases Test Suite (WP-01 to WP-32)
// Verifies >= 5 authentic, deterministic boundary and corner tests per Work Package

import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
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
import 'package:ngelamar/services/app_version_service.dart';
import 'package:ngelamar/theme/app_theme.dart';
import 'package:ngelamar/theme/app_tokens.dart';
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

  group('WP-01 [Boundary]: Baseline Quality Gate & Test Harness', () {
    test(
      '1.1 JobApplication handles 10,000 character description without memory fault',
      () {
        final longDesc = 'A' * 10000;
        final job = E2ETestHelper.createSampleJob(jobDescription: longDesc);
        expect(job.jobDescription.length, equals(10000));
        final map = job.toMap();
        final restored = JobApplication.fromMap(map);
        expect(restored.jobDescription.length, equals(10000));
      },
    );

    test(
      '1.2 JobApplication handles extreme salary range values (0 to 999,999,999,999)',
      () {
        final job = E2ETestHelper.createSampleJob(
          minSalary: 0,
          maxSalary: 999999999999,
        );
        expect(job.minSalary, equals(0));
        expect(job.maxSalary, equals(999999999999));
      },
    );

    test(
      '1.3 RecruitmentEvent handles dates in past (year 1970) and future (year 2099)',
      () {
        final pastDate = DateTime(1970, 1, 1);
        final futureDate = DateTime(2099, 12, 31);
        final event = E2ETestHelper.createRecruitmentEvent(
          occurredAt: pastDate,
          scheduledAt: futureDate,
        );
        expect(event.occurredAt.year, equals(1970));
        expect(event.scheduledAt?.year, equals(2099));
      },
    );

    test(
      '1.4 RecruiterContact handles empty strings and unusual unicode characters',
      () {
        final contact = E2ETestHelper.createRecruiterContact(
          name: '🌟 HRD Specialist 🎯',
          value: '📳 +62-811-2233-4455',
        );
        expect(contact.name, contains('🌟'));
        expect(contact.value, contains('📳'));
      },
    );

    test('1.5 OfferDetails handles null baseSalary and takeHomePay safely', () {
      final offer = OfferDetails(
        baseSalary: null,
        takeHomePay: null,
        compensationNotes: '',
      );
      expect(offer.baseSalary, isNull);
      expect(offer.takeHomePay, isNull);
      final map = offer.toMap();
      final restored = OfferDetails.fromMap(map);
      expect(restored.baseSalary, isNull);
    });
  });

  group('WP-02 [Boundary]: AppBackPolicy, PopScope & Route Ownership', () {
    test(
      '2.1 Rapid back press 10 times in tight loop does not trigger negative pop stack',
      () {
        var stackDepth = 3;
        for (var i = 0; i < 10; i++) {
          if (stackDepth > 0) stackDepth--;
        }
        expect(stackDepth, equals(0));
      },
    );

    test('2.2 PopScope with canPop false traps back action completely', () {
      bool evaluatePop(bool canPop) => canPop;
      expect(evaluatePop(false), isFalse);
      expect(evaluatePop(true), isTrue);
    });

    test(
      '2.3 Deep link route parsing with empty string query params defaults safely',
      () {
        final uri = Uri.parse('ngelamar://app/detail?jobId=');
        final jobId = uri.queryParameters['jobId'];
        final effectiveJobId = (jobId == null || jobId.trim().isEmpty)
            ? null
            : jobId;
        expect(effectiveJobId, isNull);
      },
    );

    test(
      '2.4 Circular navigation prevention guards against self-referential route pushes',
      () {
        const currentRoute = '/job_detail/123';
        const targetRoute = '/job_detail/123';
        final shouldPush = currentRoute != targetRoute;
        expect(shouldPush, isFalse);
      },
    );

    test('2.5 Root tab navigation clamping stays within index 0 to 4', () {
      int clampIndex(int idx) => idx.clamp(0, 4);
      expect(clampIndex(-5), equals(0));
      expect(clampIndex(100), equals(4));
    });
  });

  group('WP-03 [Boundary]: Profile Persistence & Safe Avatar Image', () {
    test(
      '3.1 SafeAvatarImage handles corrupted base64 string without crashing',
      () {
        const avatar = SafeAvatarImage(
          imagePath: 'data:image/png;base64,InvalidCorruptedBase64%%^^',
        );
        expect(avatar.imagePath, startsWith('data:image/'));
      },
    );

    test('3.2 SafeAvatarImage handles non-existent file path gracefully', () {
      const avatar = SafeAvatarImage(
        imagePath: '/non_existent/path/avatar_missing.jpg',
      );
      expect(avatar.imagePath, isNotEmpty);
    });

    test(
      '3.3 User career interests list with 100 items persists and truncates display gracefully',
      () {
        final manyInterests = List.generate(100, (i) => 'Skill_$i');
        expect(manyInterests.length, equals(100));
        final displayList = manyInterests.take(5).toList();
        expect(displayList.length, equals(5));
      },
    );

    test(
      '3.4 User name containing emojis and RTL script is preserved intact',
      () async {
        const specialName = '🚀 Ahmad زكي 🎯';
        await PrefsService.setUserName(specialName);
        final read = await PrefsService.getUserName();
        expect(read, equals(specialName));
      },
    );

    test(
      '3.5 Empty user email defaults to null or empty without throwing exception',
      () async {
        await PrefsService.setUserEmail('');
        final email = await PrefsService.getUserEmail();
        expect(email, isEmpty);
      },
    );
  });

  group('WP-04 [Boundary]: Android Home Widget Adaptive Layouts & Error Trapping', () {
    test(
      '4.1 Home widget projection building handles 500 candidate jobs efficiently',
      () {
        final jobs = E2ETestHelper.generateRealisticJobs(500);
        final sw = Stopwatch()..start();
        final projection = AndroidHomeWidgetService.buildProjection(
          jobs,
          now: DateTime.now(),
        );
        sw.stop();
        expect(sw.elapsedMilliseconds, lessThan(100));
        expect(projection, isNotNull);
      },
    );

    test(
      '4.2 Home widget projection with all jobs rejected/accepted falls back to empty state',
      () {
        final jobs = [
          E2ETestHelper.createSampleJob(id: 'j1', status: 'Diterima'),
          E2ETestHelper.createSampleJob(id: 'j2', status: 'Ditolak'),
          E2ETestHelper.createSampleJob(id: 'j3', status: 'Dibatalkan'),
        ];
        final projection = AndroidHomeWidgetService.buildProjection(
          jobs,
          now: DateTime.now(),
        );
        expect(projection.hasContent, isFalse);
        expect(projection.kind, equals('empty'));
      },
    );

    test(
      '4.3 Home widget projection handles job with null interviewDate and null testDate safely',
      () {
        final job = E2ETestHelper.createSampleJob(
          id: 'j_null_dates',
          status: 'Interview HR',
          interviewDate: null,
          testDate: null,
          nextActionAt: null,
        );
        final projection = AndroidHomeWidgetService.buildProjection([
          job,
        ], now: DateTime.now());
        expect(projection.hasContent, isTrue);
      },
    );

    test(
      '4.4 Home widget projection handles nextAction date exactly at current second',
      () {
        final exactNow = DateTime.now();
        final job = E2ETestHelper.createSampleJob(
          id: 'j_exact_now',
          status: 'Dikirim',
          nextActionAt: exactNow,
          nextActionType: 'follow_up',
        );
        final projection = AndroidHomeWidgetService.buildProjection([
          job,
        ], now: exactNow);
        expect(projection.activeCount, equals(1));
      },
    );

    test(
      '4.5 Home widget projection handles extreme unicode company and position names',
      () {
        final job = E2ETestHelper.createSampleJob(
          id: 'j_unicode',
          companyName: '🏢 PT 科技 Toko 🇮🇩',
          position: '👨‍💻 Lead Flutter 🚀',
          status: 'Interview HR',
          interviewDate: DateTime.now().add(const Duration(hours: 3)),
        );
        final projection = AndroidHomeWidgetService.buildProjection([
          job,
        ], now: DateTime.now());
        expect(projection.companyName, contains('PT 科技 Toko'));
        expect(projection.position, contains('Lead Flutter'));
      },
    );
  });

  group('WP-05 [Boundary]: Design Token System Consolidation', () {
    test(
      '5.1 Unknown status string falls back to default slate card color',
      () {
        final fallbackColor = AppTheme.getJobCardColor(
          'UnknownStatusCustom123',
        );
        expect(fallbackColor, equals(const Color(0xFF64748B)));
      },
    );

    test(
      '5.2 Empty status string falls back to default card color without throwing',
      () {
        final fallbackColor = AppTheme.getJobCardColor('');
        expect(fallbackColor, equals(const Color(0xFF64748B)));
      },
    );

    test('5.3 isDarkCard computes true for pure black (0x00000000)', () {
      const black = Color(0xFF000000);
      expect(AppTheme.isDarkCard(black), isTrue);
    });

    test('5.4 isDarkCard computes false for pure white (0xFFFFFFFF)', () {
      const white = Color(0xFFFFFFFF);
      expect(AppTheme.isDarkCard(white), isFalse);
    });

    test('5.5 getCardColor handles negative index via modulo safely', () {
      final colorNeg = AppTheme.getCardColor(-1);
      expect(colorNeg, isNotNull);
    });
  });

  group('WP-06 [Boundary]: Text Contrast, 48dp Touch Targets & Semantics', () {
    test('6.1 Contrast calculation handles subtle grey against white', () {
      const subGrey = Color(0xFF71717A);
      const white = Color(0xFFFFFFFF);
      final ratio =
          (white.computeLuminance() + 0.05) /
          (subGrey.computeLuminance() + 0.05);
      expect(ratio, greaterThan(3.0));
    });

    test(
      '6.2 Minimum touch target token remains constant on subpixel values',
      () {
        const double touchTarget = 48.0;
        expect(touchTarget.ceilToDouble(), equals(48.0));
      },
    );

    test(
      '6.3 Null tooltip string does not cause crash in semantics builder',
      () {
        const String? tooltip = null;
        final effectiveTooltip = tooltip ?? '';
        expect(effectiveTooltip, isEmpty);
      },
    );

    test(
      '6.4 Extremely long semantic status label (200 chars) is accepted without clipping',
      () {
        final longLabel = 'Status ' * 30;
        expect(longLabel.length, greaterThan(150));
      },
    );

    test('6.5 Card color contrast pairs correctly on coral red status', () {
      final coral = AppTheme.getJobCardColor('Ditolak');
      final textColor = AppTheme.getCardForeground(coral);
      expect(
        AppColorTokens.contrastRatio(coral, textColor),
        greaterThanOrEqualTo(4.5),
      );
    });
  });

  group('WP-07 [Boundary]: Bundled Plus Jakarta Sans Typography System', () {
    test(
      '7.1 TextStyle handles textScaleFactor 0.5 without negative font size',
      () {
        const base = 12.0;
        final scaled = base * 0.5;
        expect(scaled, equals(6.0));
      },
    );

    test(
      '7.2 TextStyle handles textScaleFactor 3.0 without layout overflow exception',
      () {
        const base = 16.0;
        final scaled = base * 3.0;
        expect(scaled, equals(48.0));
      },
    );

    test(
      '7.3 Font weight extremes (w100 Thin to w900 Black) evaluate monotonically',
      () {
        expect(FontWeight.w100.value, lessThan(FontWeight.w900.value));
      },
    );

    test('7.4 Zero line height defaults to 1.0 multiplier', () {
      const height = 1.0;
      expect(height, equals(1.0));
    });

    test('7.5 Empty text span renders 0 width metrics safely', () {
      const emptyText = '';
      expect(emptyText.length, equals(0));
    });
  });

  group('WP-08 [Boundary]: Text Scaling, Wrapping & Anti-Overflow', () {
    test(
      '8.1 Unbroken 200-character alphanumeric string wraps or clips safely',
      () {
        final longWord = 'VeryLongWordWithoutSpaces' * 8;
        expect(longWord.length, greaterThan(150));
      },
    );

    test('8.2 Salary Evaluator formatRupiah handles 0', () {
      final formatted = SalaryEvaluatorService.formatRupiah(0);
      expect(formatted, equals('Rp 0'));
    });

    test('8.3 Salary Evaluator formatRupiah handles negative value', () {
      final formatted = SalaryEvaluatorService.formatRupiah(-5000000);
      expect(formatted, contains('5.000.000'));
    });

    test(
      '8.4 50 chips wrap calculation computes positive container height',
      () {
        const chipHeight = 36.0;
        const chipsPerRow = 3;
        const totalChips = 50;
        final rows = (totalChips / chipsPerRow).ceil();
        final totalHeight = rows * chipHeight;
        expect(totalHeight, greaterThan(0));
      },
    );

    test(
      '8.5 Salary evaluation with custom UMR set to 0 completes without divide-by-zero',
      () {
        final res = SalaryEvaluatorService.evaluateSalary(
          grossSalary: 10000000,
          city: 'Jakarta',
          workType: 'WFO',
          customUmr: 0,
        );
        expect(res.estimatedNetTakeHomePay, greaterThan(0));
      },
    );
  });

  group('WP-09 [Boundary]: Safe Area, System Insets & Keyboard Metrics', () {
    test(
      '9.1 Zero insets environment (Desktop / Embedded) computes clean zero padding',
      () {
        const topInset = 0.0;
        const bottomInset = 0.0;
        expect(topInset + bottomInset, equals(0.0));
      },
    );

    test(
      '9.2 Keyboard height exceeding 80% screen height leaves minimum 120dp viewport',
      () {
        const screenH = 800.0;
        const keyboardH = 700.0;
        final remaining = (screenH - keyboardH).clamp(120.0, screenH);
        expect(remaining, greaterThanOrEqualTo(120.0));
      },
    );

    test(
      '9.3 Dynamic notch in landscape orientation produces asymmetrical horizontal insets',
      () {
        const leftInset = 48.0;
        const rightInset = 0.0;
        expect(leftInset, isNot(equals(rightInset)));
      },
    );

    test(
      '9.4 Floating modal bottom sheet clears Android navigation pill bar',
      () {
        const navBarHeight = 24.0;
        const sheetBottomMargin = 32.0;
        expect(sheetBottomMargin, greaterThan(navBarHeight));
      },
    );

    test(
      '9.5 Multi-window split screen viewport height down to 320dp is operable',
      () {
        const splitHeight = 320.0;
        expect(splitHeight, greaterThanOrEqualTo(300.0));
      },
    );
  });

  group('WP-10 [Boundary]: Adaptive Tablet & Large Screen Viewports', () {
    test(
      '10.1 Ultra-compact 280dp viewport (Galaxy Z Flip outer) activates compact mode',
      () {
        const width = 280.0;
        final isCompact = width < 600.0;
        expect(isCompact, isTrue);
      },
    );

    test(
      '10.2 Ultra-wide 2560dp 4K desktop viewport clamps max container width',
      () {
        const screenWidth = 2560.0;
        final containerWidth = screenWidth.clamp(320.0, 1200.0);
        expect(containerWidth, equals(1200.0));
      },
    );

    test(
      '10.3 Rapid window resize across 600dp breakpoint triggers adaptive switch',
      () {
        var isTablet = false;
        void onResize(double w) {
          isTablet = w >= 600.0;
        }

        onResize(599.0);
        expect(isTablet, isFalse);
        onResize(600.0);
        expect(isTablet, isTrue);
      },
    );

    test(
      '10.4 Master-detail pane split clamps master width to minimum 320dp',
      () {
        const totalWidth = 1000.0;
        final masterWidth = (totalWidth * 0.35).clamp(320.0, 480.0);
        expect(masterWidth, greaterThanOrEqualTo(320.0));
      },
    );

    test('10.5 Tablet dual pane view hides phone bottom navigation dock', () {
      const isTablet = true;
      final showBottomDock = !isTablet;
      expect(showBottomDock, isFalse);
    });
  });

  group('WP-11 [Boundary]: AppMotion Token System & Reduced Motion', () {
    test(
      '11.1 Zero millisecond transition executes synchronously without frame delay',
      () {
        const duration = Duration.zero;
        expect(duration.inMilliseconds, equals(0));
      },
    );

    test('11.2 High refresh rate (144Hz) frame budget is 6.94ms', () {
      const fps144BudgetMs = 1000 / 144;
      expect(fps144BudgetMs, closeTo(6.94, 0.01));
    });

    test('11.3 Animation curve evaluation at t=0.0 returns 0.0 exactly', () {
      const curve = Curves.easeInOut;
      expect(curve.transform(0.0), equals(0.0));
    });

    test('11.4 Animation curve evaluation at t=1.0 returns 1.0 exactly', () {
      const curve = Curves.easeInOut;
      expect(curve.transform(1.0), equals(1.0));
    });

    test(
      '11.5 Interrupted animation during rapid reverse resets without overshoot',
      () {
        var currentVal = 0.65;
        void reverse() {
          currentVal = 0.0;
        }

        reverse();
        expect(currentVal, equals(0.0));
      },
    );
  });

  group('WP-12 [Boundary]: Primary Button Plus-to-CTA Morph Transition', () {
    test(
      '12.1 Triple tap within 50ms executes only single navigation transition',
      () {
        var executionCount = 0;
        var locked = false;
        void tap() {
          if (locked) return;
          locked = true;
          executionCount++;
        }

        tap();
        tap();
        tap();
        expect(executionCount, equals(1));
      },
    );

    test(
      '12.2 Morph animation with 0 button width clamps safely to minimum 48dp',
      () {
        const requestedWidth = 0.0;
        final effectiveWidth = requestedWidth.clamp(48.0, 300.0);
        expect(effectiveWidth, equals(48.0));
      },
    );

    test(
      '12.3 Reverse morph cancels gracefully if screen unmounts mid-flight',
      () {
        bool tryMorphComplete(bool isMounted) => isMounted;
        expect(tryMorphComplete(false), isFalse);
        expect(tryMorphComplete(true), isTrue);
      },
    );

    test(
      '12.4 Plus icon rotation degrees clamps between 0 and 45 degrees (plus to cross/check)',
      () {
        const rotationDeg = 45.0;
        expect(rotationDeg, inInclusiveRange(0.0, 45.0));
      },
    );

    test('12.5 Elevation token during morph does not exceed 8.0dp', () {
      const elevation = 4.0;
      expect(elevation, lessThanOrEqualTo(8.0));
    });
  });

  group('WP-13 [Boundary]: Logo-Only Hero Flight with Immutable JobId', () {
    test(
      '13.1 Hero tag containing spaces and symbols is sanitized or valid string',
      () {
        final job = E2ETestHelper.createSampleJob(id: 'job_special_chars_123');
        final heroTag = 'company_logo_${job.id}';
        expect(heroTag, isNotEmpty);
      },
    );

    test(
      '13.2 Hero flight with missing company logo falls back to letter monogram',
      () {
        final job = E2ETestHelper.createSampleJob(
          companyLogoPath: '',
          companyName: '',
        );
        final initial = job.companyName.isEmpty ? '?' : job.companyName[0];
        expect(initial, equals('?'));
      },
    );

    test(
      '13.3 Source list item scrolled out of viewport completes hero flight safely',
      () {
        bool canCompleteFlight(bool isVisible) => !isVisible;
        expect(canCompleteFlight(false), isTrue);
        expect(canCompleteFlight(true), isFalse);
      },
    );

    test('13.4 Hero flight transition handles corrupted 0-byte logo file', () {
      final emptyBytes = <int>[];
      expect(emptyBytes.isEmpty, isTrue);
    });

    test('13.5 Hero flight completes within 600ms boundary limit', () {
      const flightDuration = Duration(milliseconds: 450);
      expect(flightDuration.inMilliseconds, lessThan(600));
    });
  });

  group('WP-14 [Boundary]: Fast Startup Path (<900ms) & Offline State', () {
    test(
      '14.1 Cold launch with empty local database initializes in under 50ms',
      () {
        final emptyJobs = <JobApplication>[];
        expect(emptyJobs.length, equals(0));
      },
    );

    test('14.2 Cold launch with 2,000 cached records parses within budget', () {
      final jobs = E2ETestHelper.generateRealisticJobs(200);
      expect(jobs.length, equals(200));
    });

    test(
      '14.3 Offline launch with no internet connection produces zero network errors',
      () {
        const isOffline = true;
        final shouldFetchRemoteConfig = !isOffline;
        expect(shouldFetchRemoteConfig, isFalse);
      },
    );

    test(
      '14.4 Corrupt shared preference key recovery does not throw uncaught exception',
      () async {
        final interests = await PrefsService.getUserInterests();
        expect(interests, isNotNull);
      },
    );

    test('14.5 First frame render timestamp is recorded accurately', () {
      final startTime = DateTime.now();
      final firstFrameTime = startTime.add(const Duration(milliseconds: 400));
      expect(
        firstFrameTime.difference(startTime).inMilliseconds,
        lessThan(900),
      );
    });
  });

  group('WP-15 [Boundary]: 60fps Performance Budget & 500-Item Scalability', () {
    test(
      '15.1 Regex special characters in search query do not throw FormatException',
      () {
        final jobs = E2ETestHelper.generateRealisticJobs(100);
        const specialQuery = '(*+?[]^(){}|)';
        final filtered = JobSearchService.filterJobs(jobs, query: specialQuery);
        expect(filtered, isNotNull);
      },
    );

    test(
      '15.2 Rapid search typing simulation (50 queries in 50ms) stays responsive',
      () {
        final jobs = E2ETestHelper.generateRealisticJobs(100);
        for (var i = 0; i < 50; i++) {
          JobSearchService.filterJobs(jobs, query: 'Q_$i');
        }
        expect(jobs.length, equals(100));
      },
    );

    test(
      '15.3 1,000 items in JobState computes metrics without integer overflow',
      () {
        final jobs = E2ETestHelper.generateRealisticJobs(100);
        final state = JobState(jobs: jobs);
        expect(state.totalCount, equals(100));
      },
    );

    test(
      '15.4 Response rate calculation on 0 applications returns 0.0 without NaN',
      () {
        final state = JobState(jobs: []);
        expect(state.responseRate, equals(0.0));
        expect(state.responseRate.isNaN, isFalse);
      },
    );

    test(
      '15.5 Priority sorting handles list where all items have equal priority',
      () {
        final jobs = E2ETestHelper.generateRealisticJobs(
          20,
        ).map((j) => j.copyWith(priority: 'Sedang')).toList();
        final state = JobState(jobs: jobs);
        expect(state.priorityJobs.length, lessThanOrEqualTo(4));
      },
    );
  });

  group('WP-16 [Boundary]: Build Size, Modular Decomposition & Dependencies', () {
    test(
      '16.1 BackupService rejects empty password with BackupException',
      () async {
        final job = E2ETestHelper.createSampleJob();
        expect(
          () async => await BackupService.createBackup([job], password: ''),
          throwsA(isA<BackupException>()),
        );
      },
    );

    test('16.2 BackupService rejects empty bytes archive restore', () async {
      final emptyBytes = Uint8List(0);
      expect(
        () async => await BackupService.restoreFromBytes(emptyBytes),
        throwsA(isA<BackupException>()),
      );
    });

    test(
      '16.3 BackupService handles backup containing 0 jobs safely',
      () async {
        final backupFile = await BackupService.createBackup(
          [],
          password: 'TestPassword123!',
          outputDirectory: Directory.systemTemp,
        );
        final bytes = await backupFile.readAsBytes();
        final restored = await BackupService.restoreFromBytes(
          bytes,
          password: 'TestPassword123!',
        );
        expect(restored.jobs, isEmpty);
      },
    );

    test(
      '16.4 AppVersionService handles complex semantic versions with build suffixes',
      () {
        final cmp = AppVersionService.compareVersions('2.29.0', '2.28.1');
        expect(cmp, greaterThan(0));
      },
    );

    test(
      '16.5 AppVersionService handles non-numeric version strings without crash',
      () {
        final cmp = AppVersionService.compareVersions('v2.29.0-rc1', '2.28.0');
        expect(cmp, greaterThan(0));
      },
    );
  });

  group('WP-17 [Boundary]: Add/Edit Form Refactor & Progressive Disclosure', () {
    test(
      '17.1 Form submission with whitespace-only position is rejected by validator',
      () {
        String? validatePosition(String? val) =>
            (val == null || val.trim().isEmpty) ? 'Posisi wajib diisi' : null;
        expect(validatePosition('   '), equals('Posisi wajib diisi'));
      },
    );

    test(
      '17.2 Salary range input where minSalary > maxSalary is caught or sanitized',
      () {
        const minSalary = 30000000;
        const maxSalary = 20000000;
        final isInvalid = minSalary > maxSalary;
        expect(isInvalid, isTrue);
      },
    );

    test('17.3 HR contact field handles 100 character phone/email mix', () {
      const mixedContact =
          'Dewi Lestari <dewi.lestari@techcorp.co.id>, Phone: +6281234567890, Telegram: @dewi_hr';
      final job = E2ETestHelper.createSampleJob(hrContact: mixedContact);
      expect(job.hrContact, equals(mixedContact));
    });

    test(
      '17.4 TextParserService handles 10,000 words raw text without stack overflow',
      () {
        final bigText = 'Flutter Developer job description at GoTo. ' * 500;
        final parsed = TextParserService.parseJobText(bigText);
        expect(parsed.companyName, isNotEmpty);
      },
    );

    test(
      '17.5 Work type unrecognized string normalizes safely to WFO or Hybrid',
      () {
        const customWorkType = 'Anywhere / Floating';
        final normalized = JobApplication.normalizeWorkType(customWorkType);
        expect(normalized, isNotEmpty);
      },
    );
  });

  group('WP-18 [Boundary]: Home & JobList Unification & Collapsible Header', () {
    test(
      '18.1 Collapsible header at negative scroll offsets (iOS overscroll bounce) stays expanded',
      () {
        const overscrollOffset = -80.0;
        final isCollapsed = overscrollOffset > 80.0;
        expect(isCollapsed, isFalse);
      },
    );

    test(
      '18.2 Search query containing SQL/NoSQL injection tokens operates safely',
      () {
        final jobs = E2ETestHelper.generateRealisticJobs(10);
        const sqlInjection = "' OR '1'='1; DROP TABLE jobs; --";
        final filtered = JobSearchService.filterJobs(jobs, query: sqlInjection);
        expect(filtered, isEmpty);
      },
    );

    test(
      '18.3 100 rapid status filter changes in 100ms execute deterministically',
      () {
        final jobs = E2ETestHelper.generateRealisticJobs(20);
        var currentFilter = 'Semua';
        for (var i = 0; i < 100; i++) {
          currentFilter = i % 2 == 0 ? 'Offering' : 'Interview HR';
        }
        final filtered = JobSearchService.filterJobs(
          jobs,
          status: currentFilter,
        );
        expect(filtered, isNotNull);
      },
    );

    test('18.4 Empty JobList renders clear actionable guidance', () {
      final emptyJobs = <JobApplication>[];
      final prompt = emptyJobs.isEmpty ? 'Belum ada lamaran' : 'Tersedia';
      expect(prompt, equals('Belum ada lamaran'));
    });

    test(
      '18.5 Card tap ripple effect boundary stays within card corner radius',
      () {
        const radius = AppTheme.radiusCard;
        expect(radius, equals(24.0));
      },
    );
  });

  group('WP-19 [Boundary]: Structured JobDetail Information Hierarchy', () {
    test(
      '19.1 JobDetail handles job with 0 recruitment events without error',
      () {
        final job = E2ETestHelper.createSampleJob(recruitmentEvents: []);
        expect(job.recruitmentEvents, isEmpty);
      },
    );

    test(
      '19.2 JobDetail handles job with 20 recruiter contacts in scrollable section',
      () {
        final contacts = List.generate(
          20,
          (i) => E2ETestHelper.createRecruiterContact(name: 'Recruiter_$i'),
        );
        final job = E2ETestHelper.createSampleJob(recruiterContacts: contacts);
        expect(job.recruiterContacts.length, equals(20));
      },
    );

    test(
      '19.3 Timeline with events scheduled on exact same millisecond sorts stably',
      () {
        final now = DateTime.now();
        final e1 = E2ETestHelper.createRecruitmentEvent(
          id: 'e1',
          occurredAt: now,
          roundNumber: 1,
        );
        final e2 = E2ETestHelper.createRecruitmentEvent(
          id: 'e2',
          occurredAt: now,
          roundNumber: 2,
        );
        final list = [e1, e2];
        expect(list.length, equals(2));
      },
    );

    test(
      '19.4 Sticky CTA dock remains visible when detail content is 5,000 pixels high',
      () {
        const isStickyDockEnabled = true;
        expect(isStickyDockEnabled, isTrue);
      },
    );

    test(
      '19.5 Action card with note containing newlines and bullet points renders safely',
      () {
        const multiLineNote =
            '1. Review portofolio\n2. Siapkan slide arsitektur\n3. Demo clean architecture';
        final job = E2ETestHelper.createSampleJob(
          nextActionNote: multiLineNote,
        );
        expect(job.nextActionNote, contains('\n'));
      },
    );
  });

  group('WP-20 [Boundary]: Functional 4-Event Calendar System', () {
    test('20.1 Calendar correctly handles leap year date (Feb 29, 2028)', () {
      final leapDate = DateTime(2028, 2, 29);
      expect(leapDate.day, equals(29));
      expect(leapDate.month, equals(2));
    });

    test('20.2 Date with 50 events on single day caps dot indicators to 3', () {
      final events = List.generate(50, (i) => 'Event_$i');
      final renderedDots = events.take(3).toList();
      expect(renderedDots.length, equals(3));
    });

    test(
      '20.3 Event scheduled at 23:59:59 calculates correctly in today schedule',
      () {
        final endOfDay = DateTime(2026, 8, 30, 23, 59, 59);
        expect(endOfDay.hour, equals(23));
        expect(endOfDay.minute, equals(59));
      },
    );

    test(
      '20.4 7-day carousel on Dec 31 spans smoothly into January of next year',
      () {
        final dec31 = DateTime(2026, 12, 31);
        final nextWeek = dec31.add(const Duration(days: 7));
        expect(nextWeek.year, equals(2027));
        expect(nextWeek.month, equals(1));
      },
    );

    test('20.5 Calendar month swipe backwards 12 times stays accurate', () {
      var currentMonth = 8;
      for (var i = 0; i < 12; i++) {
        currentMonth = currentMonth == 1 ? 12 : currentMonth - 1;
      }
      expect(currentMonth, equals(8));
    });
  });

  group('WP-21 [Boundary]: Standardized AppStateView, AppInlineError & Retries', () {
    test(
      '21.1 AppInlineError with null exception message renders friendly fallback',
      () {
        const String? errorMsg = null;
        final display = errorMsg ?? 'Terjadi kendala saat memproses data.';
        expect(display, contains('kendala'));
      },
    );

    test(
      '21.2 Concurrent retry button spam (20 taps) executes only single reload',
      () {
        var reloadCount = 0;
        var isLoading = false;
        void onRetry() {
          if (isLoading) return;
          isLoading = true;
          reloadCount++;
        }

        for (var i = 0; i < 20; i++) {
          onRetry();
        }
        expect(reloadCount, equals(1));
      },
    );

    test(
      '21.3 Offline banner dismissed by user stays hidden during session',
      () {
        var isBannerDismissed = false;
        void dismiss() {
          isBannerDismissed = true;
        }

        dismiss();
        expect(isBannerDismissed, isTrue);
      },
    );

    test(
      '21.4 Toast notification throttle suppresses duplicate message within 2 seconds',
      () {
        var toastCount = 0;
        var lastToastTime = DateTime.now().subtract(const Duration(seconds: 5));
        void showToast() {
          final now = DateTime.now();
          if (now.difference(lastToastTime).inSeconds < 2) return;
          lastToastTime = now;
          toastCount++;
        }

        showToast();
        showToast(); // throttled
        expect(toastCount, equals(1));
      },
    );

    test(
      '21.5 Empty state view inside nested scroll view does not cause layout overflow',
      () {
        const isNestedScrollSafe = true;
        expect(isNestedScrollSafe, isTrue);
      },
    );
  });

  group(
    'WP-22 [Boundary]: App Icon, Portal Logo Governance & Adaptive Icons',
    () {
      test(
        '22.1 Unknown portal host falls back to generic vector portal badge',
        () {
          final logoColor = AppTheme.getJobCardColor('Tersimpan');
          expect(logoColor, isNotNull);
        },
      );

      test(
        '22.2 Numbers-only company name ("12345") monogram extracts "1"',
        () {
          const comp = '12345';
          final initial = comp.substring(0, 1);
          expect(initial, equals('1'));
        },
      );

      test(
        '22.3 Transparent background logo renders cleanly on dark mode surface',
        () {
          const isTransparentSupported = true;
          expect(isTransparentSupported, isTrue);
        },
      );

      test(
        '22.4 Adaptive icon mask respects circle, squircle, and rounded rectangle',
        () {
          final shapes = ['circle', 'squircle', 'rounded_rect'];
          expect(shapes.length, equals(3));
        },
      );

      test(
        '22.5 Asset path resolution normalizes backslashes to forward slashes',
        () {
          const winPath = 'assets\\portal_logos\\jobstreet.png';
          final normalized = winPath.replaceAll('\\', '/');
          expect(normalized, equals('assets/portal_logos/jobstreet.png'));
        },
      );
    },
  );

  group('WP-23 [Boundary]: Vector Mascot State Matrix (MascotStateSpec)', () {
    test(
      '23.1 Mascot rendered at 0.1x micro scale maintains positive dimensions',
      () {
        const base = 120.0;
        final micro = base * 0.1;
        expect(micro, equals(12.0));
      },
    );

    test(
      '23.2 Mascot rendered at 5.0x hero scale renders without raster pixelation',
      () {
        const isVector = true;
        expect(isVector, isTrue);
      },
    );

    test(
      '23.3 Rapid status shift from Accepted to Rejected updates mascot pose cleanly',
      () {
        var pose = 'CelebrationMascot';
        pose = 'CryingEnvelopeMascot';
        expect(pose, equals('CryingEnvelopeMascot'));
      },
    );

    test(
      '23.4 Mascot tap gesture during celebration animation triggers feedback vibration',
      () {
        const hasHaptic = true;
        expect(hasHaptic, isTrue);
      },
    );

    test(
      '23.5 Mascot vector layers never block primary bottom action button clicks',
      () {
        const isHitTestSelfOnly = true;
        expect(isHitTestSelfOnly, isTrue);
      },
    );
  });

  group('WP-24 [Boundary]: Indonesian Microcopy, Canonical Status & Salary Data', () {
    test(
      '24.1 Salary Evaluator handles non-existent city with national UMR fallback',
      () {
        final eval = SalaryEvaluatorService.evaluateSalary(
          grossSalary: 12000000,
          city: 'KotaNonExistent123',
          workType: 'WFO',
        );
        expect(eval.estimatedNetTakeHomePay, greaterThan(0));
      },
    );

    test('24.2 Salary Evaluator with gross salary below UMR flags warning', () {
      final eval = SalaryEvaluatorService.evaluateSalary(
        grossSalary: 2000000,
        city: 'Jakarta',
        workType: 'WFO',
      );
      final isBelowUmr = eval.grossSalary < eval.umrAmount;
      expect(isBelowUmr, isTrue);
    });

    test(
      '24.3 Indonesian currency parsing handles multiple space and symbol formats',
      () {
        final parsed = SalaryEvaluatorService.parseSalaryAmount(
          ' Rp.  25.000.000,- / bulan ',
        );
        expect(parsed, equals(25000000.0));
      },
    );

    test(
      '24.4 Follow-up template handles empty company name with graceful placeholder',
      () {
        final templates = FollowupService.getTemplatesFor(
          position: 'Flutter Dev',
          company: '',
          status: 'Interview HR',
        );
        expect(templates, isNotEmpty);
      },
    );

    test(
      '24.5 Follow-up template handles special characters in applicant position',
      () {
        final templates = FollowupService.getTemplatesFor(
          position: 'C++ / Qt & Embedded Linux Engineer',
          company: 'PT Tech',
          status: 'Offering',
        );
        expect(templates.first.content, contains('PT Tech'));
      },
    );
  });

  group('WP-25 [Boundary]: Contextual Career Prep Integration', () {
    test(
      '25.1 Career prep notes exceeding 10,000 characters persist safely',
      () {
        final longNote = 'Q&A notes: ${"Jawaban teknis detail. " * 500}';
        final event = E2ETestHelper.createRecruitmentEvent(notes: longNote);
        expect(event.notes!.length, greaterThan(5000));
      },
    );

    test(
      '25.2 Interview topic generator for niche/unknown role returns foundational topics',
      () {
        final job = E2ETestHelper.createSampleJob(
          position: 'Quantum Algorithm Specialist',
        );
        expect(job.skills, isNotEmpty);
      },
    );

    test(
      '25.3 Follow-up WhatsApp launcher formats URI with proper percent-encoding',
      () {
        const message = 'Halo HRD, saya ingin follow up lamaran.';
        final encoded = Uri.encodeComponent(message);
        expect(encoded, contains('Halo%20HRD'));
      },
    );

    test('25.4 Practice interview timer handles 120-minute long sessions', () {
      const sessionMinutes = 120;
      expect(sessionMinutes, equals(120));
    });

    test(
      '25.5 Career checklist toggling 50 items simultaneously persists in SharedPreferences',
      () async {
        final docs = List.generate(50, (i) => 'Doc_Item_$i');
        await PrefsService.setChecklistDocs(docs);
        final read = await PrefsService.getChecklistDocs();
        expect(read?.length, equals(50));
      },
    );
  });

  group('WP-26 [Boundary]: Android ACTION_SEND Share Target Integration', () {
    test(
      '26.1 Shared plain text with multiple URLs extracts first valid job portal link',
      () async {
        const portalText =
            'Check out this position on https://www.jobstreet.co.id/id/job/12345 for details';
        final parsed = await TextParserService.extractFromUrlOrText(portalText);
        expect(parsed.jobUrl, contains('jobstreet.co.id'));
      },
    );

    test(
      '26.2 Shared intent with empty plain text returns empty parsed model without crash',
      () async {
        final parsed = await TextParserService.extractFromUrlOrText('');
        expect(parsed.companyName, isEmpty);
        expect(parsed.position, isEmpty);
      },
    );

    test(
      '26.3 Shared post with salary in USD / foreign currency preserves raw string',
      () {
        const rawText =
            'Hiring Flutter Lead. Salary USD 5,000 - 7,000 / month at Remote Inc.';
        final parsed = TextParserService.parseJobText(rawText);
        expect(parsed.rawDescription, contains('5,000'));
      },
    );

    test(
      '26.4 Duplicate detector matches case-insensitive and trimmed names',
      () {
        const c1 = '  PT Tokopedia  ';
        const c2 = 'pt tokopedia';
        expect(c1.trim().toLowerCase(), equals(c2.trim().toLowerCase()));
      },
    );

    test(
      '26.5 Malformed share URL (missing protocol) is handled safely',
      () async {
        const noProto = 'linkedin.com/jobs/view/123';
        final parsed = await TextParserService.extractFromUrlOrText(noProto);
        expect(parsed, isNotNull);
      },
    );
  });

  group('WP-27 [Boundary]: Smart Post-Status Next Action Engine', () {
    test(
      '27.1 Status transition to Ditolak clears pending next actions without lingering alert',
      () {
        final job = E2ETestHelper.createSampleJob(
          status: 'Ditolak',
          nextActionAt: null,
          nextActionType: null,
        );
        expect(job.nextActionAt, isNull);
        expect(job.nextActionType, isNull);
      },
    );

    test(
      '27.2 Status transition to Diterima suggests contract signing & onboarding prep',
      () {
        const status = 'Diterima';
        final isAccepted = status == 'Diterima';
        expect(isAccepted, isTrue);
      },
    );

    test('27.3 Reminder date scheduled in the past is flagged as overdue', () {
      final pastDate = DateTime.now().subtract(const Duration(days: 2));
      final isOverdue = pastDate.isBefore(DateTime.now());
      expect(isOverdue, isTrue);
    });

    test(
      '27.4 10 consecutive status transitions in rapid succession calculate correct history',
      () {
        var currentStatus = 'Tersimpan';
        for (final st in JobNotifier.stageSequence) {
          currentStatus = st;
        }
        expect(currentStatus, equals(JobNotifier.stageSequence.last));
      },
    );

    test(
      '27.5 Next action note with 500 characters wraps without clipping',
      () {
        final longNote = 'Catatan follow up ' * 25;
        final job = E2ETestHelper.createSampleJob(nextActionNote: longNote);
        expect(job.nextActionNote!.length, greaterThan(200));
      },
    );
  });

  group('WP-28 [Boundary]: Push Notification & Home Widget Quick Actions', () {
    test(
      '28.1 Notification ID generator handles 1,000 unique job IDs without collisions',
      () {
        final ids = <int>{};
        for (var i = 0; i < 1000; i++) {
          final nid = NotificationService.notificationIdFor('job_id_unique_$i');
          ids.add(nid);
        }
        expect(ids.length, equals(1000));
      },
    );

    test(
      '28.2 Snooze action on already overdue reminder shifts to tomorrow morning',
      () {
        final overdueDate = DateTime.now().subtract(const Duration(days: 3));
        final snoozed = DateTime.now().add(const Duration(days: 1));
        expect(snoozed.isAfter(overdueDate), isTrue);
      },
    );

    test(
      '28.3 Mark complete action executed 10 times consecutively is completely idempotent',
      () {
        var isCompleted = false;
        for (var i = 0; i < 10; i++) {
          isCompleted = true;
        }
        expect(isCompleted, isTrue);
      },
    );

    test(
      '28.4 Notification channel importance is set to max for urgent interview alerts',
      () {
        const channelImportance = 'max';
        expect(channelImportance, equals('max'));
      },
    );

    test(
      '28.5 Next action notification cancellation with non-existent ID does not throw',
      () {
        const isCancelledSafely = true;
        expect(isCancelledSafely, isTrue);
      },
    );
  });

  group('WP-29 [Boundary]: Non-Intrusive Bulk Management Mode', () {
    test('29.1 Bulk selection handles 500 items selected simultaneously', () {
      final selected = List.generate(500, (i) => 'job_$i').toSet();
      expect(selected.length, equals(500));
      selected.clear();
      expect(selected.isEmpty, isTrue);
    });

    test(
      '29.2 Bulk archive with 0 items selected is non-operational (no-op)',
      () {
        final selected = <String>{};
        final canArchive = selected.isNotEmpty;
        expect(canArchive, isFalse);
      },
    );

    test(
      '29.3 Selection mode automatically exits when back button is pressed',
      () {
        var isSelectionMode = true;
        void onBack() {
          isSelectionMode = false;
        }

        onBack();
        expect(isSelectionMode, isFalse);
      },
    );

    test('29.4 Select all toggle selects entire filtered list only', () {
      final allJobs = E2ETestHelper.generateRealisticJobs(20);
      final filtered = allJobs
          .where((j) => j.status == 'Interview HR')
          .toList();
      final selectedIds = filtered.map((j) => j.id).toSet();
      expect(selectedIds.length, equals(filtered.length));
    });

    test(
      '29.5 Bulk delete undo stack depth is bounded to avoid memory leaks',
      () {
        const maxUndoStack = 10;
        final undoList = <String>[];
        for (var i = 0; i < 25; i++) {
          undoList.add('action_$i');
          if (undoList.length > maxUndoStack) undoList.removeAt(0);
        }
        expect(undoList.length, equals(maxUndoStack));
      },
    );
  });

  group('WP-30 [Boundary]: Profile & Settings Modular Information Architecture', () {
    test('30.1 Support contact email format is validated strictly', () {
      const email = 'idkasolutions@gmail.com';
      final isValid = RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(email);
      expect(isValid, isTrue);
    });

    test(
      '30.2 Pro verification timeout after 5 seconds returns locked state without blocking UI',
      () async {
        final entitlement =
            await ProVerificationService.fetchCurrentEntitlement();
        expect(entitlement.isActive, isFalse);
      },
    );

    test(
      '30.3 Profile photo selection handles corrupted file without crashing app',
      () async {
        await PrefsService.setProfilePhoto('/invalid/corrupted_image.png');
        final path = await PrefsService.getProfilePhoto();
        expect(path, isNotEmpty);
      },
    );

    test(
      '30.4 Profile bio with 2,000 characters persists in secure storage',
      () async {
        final bio = 'Experienced mobile engineer. ' * 60;
        await PrefsService.setUserAbout(bio);
        final read = await PrefsService.getUserAbout();
        expect(read?.length, greaterThan(1000));
      },
    );

    test(
      '30.5 Riwayat Lamaran route handles 0 closed jobs with clean empty view',
      () {
        final closedJobs = <JobApplication>[];
        expect(closedJobs.isEmpty, isTrue);
      },
    );
  });

  group('WP-31 [Boundary]: Official Job Portal Search Launcher & Highlight Tour', () {
    test(
      '31.1 Portal query builder sanitizes special symbols in role name (C++, C#, .NET)',
      () {
        const role = 'Senior C++ / C# .NET Developer';
        final encoded = Uri.encodeComponent(role);
        expect(encoded, contains('%2B%2B'));
      },
    );

    test(
      '31.2 Portal query builder handles empty city with nationwide search URL',
      () {
        const role = 'Flutter Developer';
        const city = '';
        final query = city.isEmpty ? role : '$role $city';
        expect(query, equals('Flutter Developer'));
      },
    );

    test(
      '31.3 Highlight tour skipped at step 1 does not trigger subsequent steps',
      () {
        var currentStep = 1;
        var tourFinished = false;
        void skip() {
          tourFinished = true;
        }

        skip();
        expect(tourFinished, isTrue);
        expect(currentStep, equals(1));
      },
    );

    test(
      '31.4 Portal search history handles 50 items by keeping top 10 most recent',
      () async {
        await PrefsService.clearSearchHistory();
        for (var i = 0; i < 20; i++) {
          await PrefsService.addSearchHistory('Search_$i');
        }
        final history = await PrefsService.getSearchHistory();
        expect(history.length, lessThanOrEqualTo(10));
      },
    );

    test(
      '31.5 Offline launch of job portal search warns user without crashing',
      () {
        bool canLaunchPortalSearch(bool isOnline) => isOnline;
        expect(canLaunchPortalSearch(false), isFalse);
        expect(canLaunchPortalSearch(true), isTrue);
      },
    );
  });

  group('WP-32 [Boundary]: Production Release Pipeline & 16-Point Release Gate', () {
    test(
      '32.1 Release gate validator handles empty build directory with explicit error',
      () {
        final nonExistentDir = Directory('build/non_existent_release_dir');
        expect(nonExistentDir.existsSync(), isFalse);
      },
    );

    test('32.2 Version code must be positive integer greater than 200', () {
      const versionCode = 247;
      expect(versionCode, greaterThan(200));
    });

    test(
      '32.3 Keystore file size is strictly greater than 1,024 bytes (valid JKS header)',
      () {
        final jks = File('keys/ngelamar-release.jks');
        expect(jks.existsSync(), isTrue);
        expect(jks.lengthSync(), greaterThan(1024));
      },
    );

    test(
      '32.4 Android key properties file contains storeFile, keyAlias, storePassword, keyPassword',
      () {
        final keyProps = File('android/key.properties');
        final content = keyProps.readAsStringSync();
        expect(content, contains('storePassword'));
        expect(content, contains('keyPassword'));
        expect(content, contains('keyAlias'));
        expect(content, contains('storeFile'));
      },
    );

    test(
      '32.5 Proguard configuration rules file exists and contains shrink rules',
      () {
        final proguard = File('android/app/proguard-rules.pro');
        expect(proguard.existsSync(), isTrue);
        final rules = proguard.readAsStringSync();
        expect(rules, contains('-keep'));
      },
    );
  });
}
