// ignore_for_file: invalid_use_of_visible_for_testing_member, avoid_print

import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:ngelamar/models/job_application.dart';
import 'package:ngelamar/providers/job_provider.dart';
import 'package:ngelamar/views/dashboard/dashboard_screen.dart';
import 'package:ngelamar/views/discovery/job_discovery_screen.dart';
import 'package:ngelamar/views/jobs/job_detail_screen.dart';
import 'package:ngelamar/views/jobs/job_list_screen.dart';
import 'package:ngelamar/views/notifications/notification_center_screen.dart';
import 'package:ngelamar/views/prep/fresh_grad_prep_screen.dart';
import 'package:ngelamar/views/settings/settings_screen.dart';
import 'package:ngelamar/views/main_navigation.dart';
import 'package:shared_preferences/shared_preferences.dart';

List<JobApplication> _createSampleJobs() {
  final now = DateTime.now();
  return [
    JobApplication(
      id: 'job-1',
      companyName: 'PT Teknologi Karya Nusantara',
      position: 'Senior Mobile Flutter Developer',
      status: 'Interview & Tes',
      appliedDate: now.subtract(const Duration(days: 4)),
      workType: 'Hybrid',
      location: 'Jakarta Selatan',
      salaryOffered: 'Rp 20.000.000',
      sourcePlatform: 'LinkedIn',
      jobDescription:
          'Mengembangkan aplikasi mobile enterprise menggunakan Flutter & Riverpod. Membangun clean architecture, integrasi REST API & CI/CD.',
      skills: [
        'Pengalaman 3+ tahun dengan Flutter & Dart',
        'Mahir State Management Riverpod/Bloc',
        'Memahami CI/CD Fastlane & GitHub Actions',
      ],
      nextActionAt: now.add(const Duration(days: 2, hours: 4)),
      nextActionType: 'Technical Interview',
      notes:
          'Pelajari arsitektur clean architecture & Riverpod 2.0. Interview bersama Lead Mobile Engineer jam 14:00.',
      isFavorite: true,
    ),
    JobApplication(
      id: 'job-2',
      companyName: 'Gojek (GoTo Group)',
      position: 'UI/UX Product Designer',
      status: 'Offering',
      appliedDate: now.subtract(const Duration(days: 12)),
      workType: 'WFH',
      location: 'Jakarta Pusat',
      salaryOffered: 'Rp 18.000.000',
      sourcePlatform: 'Glints',
      jobDescription:
          'Merancang pengalaman pengguna untuk produk finansial consumer. Melakukan riset pengguna, prototyping di Figma, dan design system.',
      skills: [
        'Portofolio UI/UX yang kuat di mobile app',
        'Fasih Figma, Design Tokens, & Prototyping',
      ],
      notes: 'Offering letter sudah diterima. Batas konfirmasi akhir minggu.',
      isFavorite: true,
    ),
    JobApplication(
      id: 'job-3',
      companyName: 'Shopee Indonesia',
      position: 'Frontend Engineer (React / Mobile)',
      status: 'Dikirim',
      appliedDate: now.subtract(const Duration(days: 2)),
      workType: 'WFO',
      location: 'Jakarta Barat',
      salaryOffered: 'Rp 16.000.000',
      sourcePlatform: 'Jobstreet',
      jobDescription: 'Mengembangkan fitur marketplace dengan performa tinggi.',
    ),
    JobApplication(
      id: 'job-4',
      companyName: 'Bank Central Asia (BCA)',
      position: 'IT Application Specialist',
      status: 'Diterima',
      appliedDate: now.subtract(const Duration(days: 20)),
      workType: 'WFO',
      location: 'Jakarta Pusat',
      salaryOffered: 'Rp 15.000.000',
      sourcePlatform: 'Kalibrr',
      jobDescription: 'Pengembangan sistem perbankan digital core banking.',
    ),
    JobApplication(
      id: 'job-5',
      companyName: 'Traveloka',
      position: 'Associate Product Manager',
      status: 'Tersimpan',
      appliedDate: now.subtract(const Duration(days: 1)),
      workType: 'Hybrid',
      location: 'Tangerang Selatan',
      salaryOffered: 'Rp 14.000.000',
      sourcePlatform: 'LinkedIn',
      jobDescription:
          'Menganalisis kebutuhan pasar dan menyusun roadmap produk travel & lifestyle.',
    ),
    JobApplication(
      id: 'job-6',
      companyName: 'PT Global Tiket Network',
      position: 'Quality Assurance Engineer',
      status: 'Ditolak',
      appliedDate: now.subtract(const Duration(days: 15)),
      workType: 'WFH',
      location: 'Jakarta',
      salaryOffered: 'Rp 10.000.000',
      sourcePlatform: 'KitaLulus',
      jobDescription:
          'Manual & Automation Testing menggunakan Appium & Selenium.',
    ),
  ];
}

class _MockJobNotifier extends JobNotifier {
  _MockJobNotifier(List<JobApplication> jobs) : super() {
    state = JobState(
      jobs: jobs,
      isLoading: false,
      userName: 'Abror Rozaqi',
      userEmail: 'abror.rozaqi@gmail.com',
      isProUser: true,
      isDarkMode: false,
    );
  }
}

Future<void> _captureScreen(
  WidgetTester tester, {
  required Widget widget,
  required String outputFileName,
}) async {
  tester.view.physicalSize = const Size(1080, 2240);
  tester.view.devicePixelRatio = 2.0;

  final jobs = _createSampleJobs();
  final notifier = _MockJobNotifier(jobs);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [jobProvider.overrideWith((ref) => notifier)],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          brightness: Brightness.light,
          scaffoldBackgroundColor: const Color(0xFFF5EFE6),
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF6366F1),
            brightness: Brightness.light,
          ),
        ),
        home: RepaintBoundary(
          key: const ValueKey('screen_capture_root'),
          child: widget,
        ),
      ),
    ),
  );

  await tester.pumpAndSettle(const Duration(seconds: 1));

  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(const ValueKey('screen_capture_root')),
  );

  final image = await boundary.toImage(pixelRatio: 2.0);
  final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
  final pngBytes = byteData!.buffer.asUint8List();

  final encoded = base64Encode(pngBytes);
  debugPrint('CAPTURE_EXPORT:$outputFileName:$encoded');
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    final tempDir = Directory.systemTemp.createTempSync(
      'ngelamar_screenshot_test_',
    );
    Hive.init(tempDir.path);

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.it_nomads.com/flutter_secure_storage'),
          (MethodCall methodCall) async {
            if (methodCall.method == 'read') return null;
            if (methodCall.method == 'readAll') return <String, String>{};
            if (methodCall.method == 'write') return null;
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
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues({
      'user_name': 'Abror Rozaqi',
      'user_career_interests': [
        'Mobile Developer',
        'UI/UX Designer',
        'Software Engineer',
      ],
      'onboarding_done': true,
      'theme_mode': 'light',
      'user_about':
          'Mobile Software Engineer dengan spesialisasi Flutter & Dart. Berpengalaman membangun aplikasi Android & iOS dengan performa tinggi, clean architecture, dan state management modern.',
    });
  });

  testWidgets('Capture all 8 promotional screenshots', (tester) async {
    final jobs = _createSampleJobs();

    // 1. Dashboard
    await _captureScreen(
      tester,
      widget: const DashboardScreen(),
      outputFileName: 'screenshot_01_dashboard.png',
    );

    // 2. Job Tracker
    await _captureScreen(
      tester,
      widget: const JobListScreen(),
      outputFileName: 'screenshot_02_job_tracker.png',
    );

    // 3. Job Detail
    await _captureScreen(
      tester,
      widget: JobDetailScreen(job: jobs.first),
      outputFileName: 'screenshot_03_job_detail.png',
    );

    // 4. Portal Loker
    await _captureScreen(
      tester,
      widget: const JobDiscoveryScreen(),
      outputFileName: 'screenshot_04_portal_loker.png',
    );

    // 5. Career Prep
    await _captureScreen(
      tester,
      widget: const FreshGradPrepScreen(),
      outputFileName: 'screenshot_05_career_prep.png',
    );

    // 6. Notifications
    await _captureScreen(
      tester,
      widget: const NotificationCenterScreen(),
      outputFileName: 'screenshot_06_notifications.png',
    );

    // 7. Settings Profile
    await _captureScreen(
      tester,
      widget: const SettingsScreen(),
      outputFileName: 'screenshot_07_settings_profile.png',
    );

    // 8. Main App Overview
    await _captureScreen(
      tester,
      widget: const MainNavigation(),
      outputFileName: 'screenshot_08_main_app.png',
    );
  });
}
