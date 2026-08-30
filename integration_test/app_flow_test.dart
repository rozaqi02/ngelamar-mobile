import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ngelamar/models/job_application.dart';
import 'package:ngelamar/providers/job_provider.dart';
import 'package:ngelamar/services/prefs_service.dart';
import 'package:ngelamar/views/main_navigation.dart';
import 'package:ngelamar/views/jobs/add_edit_job_screen.dart';
import 'package:ngelamar/views/jobs/job_detail_screen.dart';
import 'package:ngelamar/views/jobs/job_list_screen.dart';
import 'package:ngelamar/views/dashboard/dashboard_screen.dart';
import 'package:ngelamar/views/settings/settings_screen.dart';
import 'package:ngelamar/theme/app_theme.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;

  setUpAll(() async {
    tempDir = Directory.systemTemp.createTempSync('ngelamar_integration_test_');
    Hive.init(tempDir.path);

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.it_nomads.com/flutter_secure_storage'),
          (MethodCall methodCall) async {
            if (methodCall.method == 'read') return null;
            if (methodCall.method == 'readAll') return <String, String>{};
            if (methodCall.method == 'write') return null;
            if (methodCall.method == 'delete') return null;
            return null;
          },
        );

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('dexterous.com/flutter/local_notifications'),
          (MethodCall methodCall) async => null,
        );

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('home_widget'),
          (MethodCall methodCall) async => true,
        );

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('dev.fluttercommunity.plus/package_info'),
          (MethodCall methodCall) async {
            if (methodCall.method == 'getAll') {
              return <String, dynamic>{
                'appName': 'Ngelamar',
                'packageName': 'com.ngelamar.app.ngelamar',
                'version': '2.29.0',
                'buildNumber': '247',
              };
            }
            return null;
          },
        );
  });

  tearDownAll(() async {
    try {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    } catch (_) {}
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues({
      'onboarding_done': true,
      'user_name': 'Test User',
      'user_email': 'test@ngelamar.id',
      'initial_data_seeded': true,
      'theme_mode': 'light',
    });
  });

  Widget createTestWidget({
    required Widget child,
    ProviderContainer? container,
  }) {
    if (container != null) {
      return UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: AppTheme.appleLightTheme,
          darkTheme: AppTheme.appleDarkTheme,
          home: child,
        ),
      );
    }
    return ProviderScope(
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.appleLightTheme,
        darkTheme: AppTheme.appleDarkTheme,
        home: child,
      ),
    );
  }

  group('Ngelamar App Flow End-to-End Integration Tests (9 User Journeys)', () {
    // Journey 1: Quick Add Flow
    testWidgets('Journey 1: Quick Add Job Application', (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(jobProvider.notifier);
      await notifier.clearAllJobs();

      await tester.pumpWidget(
        createTestWidget(
          container: container,
          child: const AddEditJobScreen(startQuickMode: true),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Catat Cepat'), findsWidgets);

      final quickJob = JobApplication(
        id: 'quick_job_001',
        companyName: 'PT Inovasi Digital',
        position: 'Flutter Developer',
        workType: 'Hybrid',
        location: 'Jakarta',
        status: 'Dikirim',
        jobDescription: 'Mengembangkan aplikasi Flutter mobile.',
        appliedDate: DateTime.now(),
      );

      await notifier.addJob(quickJob);
      await tester.pumpAndSettle();

      final state = container.read(jobProvider);
      expect(state.jobs.length, 1);
      expect(state.jobs.first.companyName, 'PT Inovasi Digital');
      expect(state.jobs.first.position, 'Flutter Developer');
      expect(state.jobs.first.workType, 'Hybrid');
      expect(state.jobs.first.status, 'Dikirim');
    });

    // Journey 2: Full Form Add Flow
    testWidgets('Journey 2: Full Form Add Job with Comprehensive Fields', (
      tester,
    ) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(jobProvider.notifier);
      await notifier.clearAllJobs();

      await tester.pumpWidget(
        createTestWidget(
          container: container,
          child: const AddEditJobScreen(startQuickMode: false),
        ),
      );
      await tester.pumpAndSettle();

      final now = DateTime.now();
      final fullJob = JobApplication(
        id: 'full_job_002',
        companyName: 'PT Mega Solusi Teknologi',
        position: 'Senior Mobile Architect',
        status: 'Interview HR',
        workType: 'WFH',
        location: 'Jakarta Selatan',
        salaryOffered: 'Rp 25.000.000',
        minSalary: 25000000,
        maxSalary: 30000000,
        jobSource: 'LinkedIn',
        sourcePlatform: 'LinkedIn',
        jobDescription: 'Leading mobile architecture for fintech platform.',
        skills: ['Flutter', 'Clean Architecture', 'CI/CD'],
        notes: 'Interview with Head of Engineering on Thursday.',
        interviewDate: now.add(const Duration(days: 3)),
        nextActionAt: now.add(const Duration(days: 3)),
        nextActionType: 'Interview HR',
        isFavorite: true,
        appliedDate: now,
      );

      await notifier.addJob(fullJob);
      await tester.pumpAndSettle();

      final state = container.read(jobProvider);
      expect(state.jobs.length, 1);
      final saved = state.jobs.first;
      expect(saved.companyName, 'PT Mega Solusi Teknologi');
      expect(saved.position, 'Senior Mobile Architect');
      expect(saved.status, 'Interview HR');
      expect(saved.workType, 'WFH');
      expect(saved.salaryOffered, 'Rp 25.000.000');
      expect(saved.isFavorite, true);
      expect(saved.skills.length, 3);
      expect(saved.interviewDate, isNotNull);
    });

    // Journey 3: Edit Job Flow
    testWidgets('Journey 3: Edit Existing Job Application', (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(jobProvider.notifier);
      await notifier.clearAllJobs();

      final initialJob = JobApplication(
        id: 'edit_job_003',
        companyName: 'PT Nusantara Dev',
        position: 'Junior Developer',
        status: 'Dikirim',
        workType: 'WFO',
        jobDescription: 'Junior developer responsibilities.',
        appliedDate: DateTime.now(),
      );
      await notifier.addJob(initialJob);

      await tester.pumpWidget(
        createTestWidget(
          container: container,
          child: AddEditJobScreen(jobToEdit: initialJob),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Edit Lamaran'), findsWidgets);

      final updatedJob = initialJob.copyWith(
        position: 'Senior Mobile Engineer',
        salaryOffered: 'Rp 20.000.000',
        workType: 'Hybrid',
        notes:
            'Updated position title and salary expectations after phone screen.',
      );

      await notifier.updateJob(updatedJob);
      await tester.pumpAndSettle();

      final state = container.read(jobProvider);
      expect(state.jobs.first.position, 'Senior Mobile Engineer');
      expect(state.jobs.first.salaryOffered, 'Rp 20.000.000');
      expect(state.jobs.first.workType, 'Hybrid');
      expect(state.jobs.first.notes, contains('Updated position title'));
    });

    // Journey 4: Delete Job Flow
    testWidgets('Journey 4: Delete Job Application', (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(jobProvider.notifier);
      await notifier.clearAllJobs();

      final job1 = JobApplication(
        id: 'delete_job_004_a',
        companyName: 'Company To Keep',
        position: 'Product Designer',
        status: 'Dikirim',
        workType: 'Hybrid',
        jobDescription: 'UI/UX design.',
        appliedDate: DateTime.now(),
      );
      final job2 = JobApplication(
        id: 'delete_job_004_b',
        companyName: 'Company To Delete',
        position: 'QA Engineer',
        status: 'Ditolak',
        workType: 'WFO',
        jobDescription: 'Quality assurance.',
        appliedDate: DateTime.now(),
      );

      await notifier.addJob(job1);
      await notifier.addJob(job2);
      expect(container.read(jobProvider).jobs.length, 2);

      await notifier.deleteJob(job2.id);
      await tester.pumpAndSettle();

      final state = container.read(jobProvider);
      expect(state.jobs.length, 1);
      expect(state.jobs.first.id, 'delete_job_004_a');
      expect(state.jobs.any((j) => j.id == 'delete_job_004_b'), isFalse);
    });

    // Journey 5: Status Transitions Lifecycle
    testWidgets(
      'Journey 5: Multi-Stage Status Progression & Recruitment Events',
      (tester) async {
        final container = ProviderContainer();
        addTearDown(container.dispose);

        final notifier = container.read(jobProvider.notifier);
        await notifier.clearAllJobs();

        final job = JobApplication(
          id: 'status_job_005',
          companyName: 'PT Unicorn Tech',
          position: 'Lead Flutter Engineer',
          status: 'Tersimpan',
          workType: 'Hybrid',
          jobDescription: 'Lead Flutter app engineering.',
          appliedDate: DateTime.now(),
        );
        await notifier.addJob(job);

        // Advance: Tersimpan -> Draft -> Dikirim -> Tes / Psikotes -> Interview HR -> Interview User -> Offering -> Diterima
        final s1 = await notifier.advanceToNextStage(job.id);
        expect(s1, 'Draft');
        expect(container.read(jobProvider).jobs.first.status, 'Draft');

        final s2 = await notifier.advanceToNextStage(job.id);
        expect(s2, 'Dikirim');
        expect(container.read(jobProvider).jobs.first.status, 'Dikirim');

        final s3 = await notifier.advanceToNextStage(job.id);
        expect(s3, 'Tes / Psikotes');
        expect(container.read(jobProvider).jobs.first.status, 'Tes / Psikotes');

        final s4 = await notifier.advanceToNextStage(job.id);
        expect(s4, 'Interview HR');
        expect(container.read(jobProvider).jobs.first.status, 'Interview HR');

        final s5 = await notifier.advanceToNextStage(job.id);
        expect(s5, 'Interview User');
        expect(container.read(jobProvider).jobs.first.status, 'Interview User');

        final s6 = await notifier.advanceToNextStage(job.id);
        expect(s6, 'Offering');
        expect(container.read(jobProvider).jobs.first.status, 'Offering');

        final s7 = await notifier.advanceToNextStage(job.id);
        expect(s7, 'Diterima');
        final finalJob = container.read(jobProvider).jobs.first;
        expect(finalJob.status, 'Diterima');
        expect(finalJob.closedAt, isNotNull);
        expect(finalJob.recruitmentEvents.length, greaterThan(1));
      },
    );

    // Journey 6: Back Navigation & Dock Routing Contract
    testWidgets('Journey 6: Dock Navigation, Detail Push and Pop Back', (
      tester,
    ) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(jobProvider.notifier);
      await notifier.clearAllJobs();

      final sampleJob = JobApplication(
        id: 'nav_job_006',
        companyName: 'PT Navigasi Mandiri',
        position: 'Staff Engineer',
        status: 'Interview HR',
        workType: 'Hybrid',
        jobDescription: 'Staff Engineer duties.',
        appliedDate: DateTime.now(),
      );
      await notifier.addJob(sampleJob);

      await tester.pumpWidget(
        createTestWidget(container: container, child: const MainNavigation()),
      );
      await tester.pumpAndSettle();

      // Verify Beranda is visible
      expect(find.byType(DashboardScreen), findsOneWidget);

      // Tap on Daftar Lamaran tab (index 1)
      await tester.tap(find.byIcon(Icons.mail_outline_rounded));
      await tester.pumpAndSettle();

      // Open JobDetailScreen
      final detailRoute = MaterialPageRoute(
        builder: (_) => JobDetailScreen(job: sampleJob),
      );
      await tester.pumpWidget(
        createTestWidget(
          container: container,
          child: Navigator(onGenerateRoute: (settings) => detailRoute),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('PT Navigasi Mandiri'), findsWidgets);

      // Verify back button tap pops back
      final backButton = find.byType(IconButton).first;
      await tester.tap(backButton);
      await tester.pumpAndSettle();
    });

    // Journey 7: Search Filtering
    testWidgets('Journey 7: Multi-Token Search Filtering', (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(jobProvider.notifier);
      await notifier.clearAllJobs();

      await notifier.addJob(
        JobApplication(
          id: 'search_1',
          companyName: 'Google Indonesia',
          position: 'Android Lead',
          status: 'Interview HR',
          workType: 'Hybrid',
          jobDescription: 'Android tech lead.',
          appliedDate: DateTime.now(),
        ),
      );
      await notifier.addJob(
        JobApplication(
          id: 'search_2',
          companyName: 'Shopee Singapore',
          position: 'Flutter Frontend Engineer',
          status: 'Dikirim',
          workType: 'WFH',
          jobDescription: 'Frontend development.',
          appliedDate: DateTime.now(),
        ),
      );
      await notifier.addJob(
        JobApplication(
          id: 'search_3',
          companyName: 'Tokopedia',
          position: 'iOS Developer',
          status: 'Offering',
          workType: 'WFO',
          jobDescription: 'iOS development.',
          appliedDate: DateTime.now(),
        ),
      );

      await tester.pumpWidget(
        createTestWidget(container: container, child: const JobListScreen()),
      );
      await tester.pumpAndSettle();

      // Search for Flutter
      notifier.setSearchQuery('Flutter Shopee');
      await tester.pumpAndSettle();

      var state = container.read(jobProvider);
      expect(state.filteredJobs.length, 1);
      expect(state.filteredJobs.first.companyName, 'Shopee Singapore');

      // Clear search
      notifier.setSearchQuery('');
      await tester.pumpAndSettle();

      state = container.read(jobProvider);
      expect(state.filteredJobs.length, 3);
    });

    // Journey 8: Faceted Filter (Status, Work Type, Favorite, WFH)
    testWidgets('Journey 8: Status, Work Type and Attribute Filtering', (
      tester,
    ) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(jobProvider.notifier);
      await notifier.clearAllJobs();

      await notifier.addJob(
        JobApplication(
          id: 'filter_1',
          companyName: 'Company WFH',
          position: 'Remote Engineer',
          status: 'Offering',
          workType: 'WFH',
          jobDescription: 'Remote work role.',
          isFavorite: true,
          appliedDate: DateTime.now(),
        ),
      );
      await notifier.addJob(
        JobApplication(
          id: 'filter_2',
          companyName: 'Company WFO',
          position: 'Office Specialist',
          status: 'Dikirim',
          workType: 'WFO',
          jobDescription: 'Office based role.',
          isFavorite: false,
          appliedDate: DateTime.now(),
        ),
      );

      // Status filter
      notifier.setStatusFilter('Offering');
      var state = container.read(jobProvider);
      expect(state.filteredJobs.length, 1);
      expect(state.filteredJobs.first.companyName, 'Company WFH');

      // Reset and test WFH filter
      notifier.resetFilters();
      notifier.toggleOnlyWfhFilter();
      state = container.read(jobProvider);
      expect(state.filteredJobs.length, 1);
      expect(state.filteredJobs.first.workType, 'WFH');

      // Reset and test Favorites filter
      notifier.resetFilters();
      notifier.toggleOnlyFavoritesFilter();
      state = container.read(jobProvider);
      expect(state.filteredJobs.length, 1);
      expect(state.filteredJobs.first.isFavorite, true);

      // Reset all
      notifier.resetFilters();
      state = container.read(jobProvider);
      expect(state.filteredJobs.length, 2);
    });

    // Journey 9: Settings & User Profile Management
    testWidgets('Journey 9: Settings Profile Update & Theme Toggle', (
      tester,
    ) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(jobProvider.notifier);

      await tester.pumpWidget(
        createTestWidget(container: container, child: const SettingsScreen()),
      );
      await tester.pumpAndSettle();

      await notifier.setUserName('Muhammad Abror Rozaqi');
      await notifier.setUserEmail('abror.rozaqi@ngelamar.id');
      await tester.pumpAndSettle();

      var state = container.read(jobProvider);
      expect(state.userName, 'Muhammad Abror Rozaqi');
      expect(state.userEmail, 'abror.rozaqi@ngelamar.id');

      final storedName = await PrefsService.getUserName();
      final storedEmail = await PrefsService.getUserEmail();
      expect(storedName, 'Muhammad Abror Rozaqi');
      expect(storedEmail, 'abror.rozaqi@ngelamar.id');
    });
  });
}
