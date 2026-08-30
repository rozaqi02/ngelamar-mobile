import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive/hive.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ngelamar/models/job_application.dart';
import 'package:ngelamar/services/supabase_service.dart';
import 'package:ngelamar/providers/job_provider.dart';
import 'package:ngelamar/views/dashboard/dashboard_screen.dart';
import 'package:ngelamar/views/jobs/job_list_screen.dart';
import 'package:ngelamar/views/jobs/job_detail_screen.dart';
import 'package:ngelamar/views/calendar/calendar_screen.dart';
import 'package:ngelamar/views/settings/settings_screen.dart';
import 'package:ngelamar/theme/app_theme.dart';

List<JobApplication> _createGoldenSampleJobs() {
  final baseDate = DateTime(2026, 8, 25, 10, 0, 0);
  return [
    JobApplication(
      id: 'golden_job_1',
      companyName: 'PT Teknologi Karya Nusantara',
      position: 'Senior Mobile Flutter Developer',
      status: 'Interview HR',
      appliedDate: baseDate,
      workType: 'Hybrid',
      location: 'Jakarta Selatan',
      salaryOffered: 'Rp 20.000.000',
      minSalary: 20000000,
      maxSalary: 25000000,
      sourcePlatform: 'LinkedIn',
      jobSource: 'LinkedIn',
      jobDescription:
          'Mengembangkan aplikasi mobile enterprise menggunakan Flutter & Riverpod. Membangun clean architecture, integrasi REST API & CI/CD.',
      skills: [
        'Pengalaman 3+ tahun dengan Flutter & Dart',
        'Mahir State Management Riverpod/Bloc',
        'Memahami CI/CD Fastlane & GitHub Actions',
      ],
      nextActionAt: baseDate.add(const Duration(days: 2, hours: 4)),
      nextActionType: 'Technical Interview',
      notes:
          'Pelajari arsitektur clean architecture & Riverpod 2.0. Interview bersama Lead Mobile Engineer jam 14:00.',
      isFavorite: true,
      recruitmentEvents: [
        RecruitmentEvent(
          id: 'ev1',
          type: 'lamaran_dikirim',
          title: 'Lamaran Dikirim',
          occurredAt: baseDate,
        ),
        RecruitmentEvent(
          id: 'ev2',
          type: 'interview_hr',
          title: 'Interview HR Selesai',
          occurredAt: baseDate.add(const Duration(days: 2)),
        ),
      ],
    ),
    JobApplication(
      id: 'golden_job_2',
      companyName: 'Gojek (GoTo Group)',
      position: 'UI/UX Product Designer',
      status: 'Offering',
      appliedDate: baseDate.subtract(const Duration(days: 5)),
      workType: 'WFH',
      location: 'Jakarta Pusat',
      salaryOffered: 'Rp 18.000.000',
      minSalary: 18000000,
      maxSalary: 22000000,
      sourcePlatform: 'Glints',
      jobSource: 'Glints',
      jobDescription:
          'Merancang pengalaman pengguna untuk produk finansial consumer.',
      skills: [
        'Portofolio UI/UX yang kuat di mobile app',
        'Fasih Figma, Design Tokens, & Prototyping',
      ],
      notes: 'Offering letter sudah diterima. Batas konfirmasi akhir minggu.',
      isFavorite: true,
    ),
    JobApplication(
      id: 'golden_job_3',
      companyName: 'Shopee Indonesia',
      position: 'Frontend Engineer (React / Mobile)',
      status: 'Dikirim',
      appliedDate: baseDate.subtract(const Duration(days: 1)),
      workType: 'WFO',
      location: 'Jakarta Barat',
      salaryOffered: 'Rp 16.000.000',
      sourcePlatform: 'Jobstreet',
      jobSource: 'Jobstreet',
      jobDescription: 'Mengembangkan fitur marketplace dengan performa tinggi.',
    ),
    JobApplication(
      id: 'golden_job_4',
      companyName: 'Bank Central Asia (BCA)',
      position: 'IT Application Specialist',
      status: 'Diterima',
      appliedDate: baseDate.subtract(const Duration(days: 15)),
      workType: 'WFO',
      location: 'Jakarta Pusat',
      salaryOffered: 'Rp 15.000.000',
      sourcePlatform: 'Kalibrr',
      jobSource: 'Kalibrr',
      jobDescription: 'Pengembangan sistem perbankan digital core banking.',
    ),
    JobApplication(
      id: 'golden_job_5',
      companyName: 'Traveloka',
      position: 'Associate Product Manager',
      status: 'Tersimpan',
      appliedDate: baseDate.subtract(const Duration(days: 2)),
      workType: 'Hybrid',
      location: 'Tangerang Selatan',
      salaryOffered: 'Rp 14.000.000',
      sourcePlatform: 'LinkedIn',
      jobSource: 'LinkedIn',
      jobDescription: 'Menganalisis kebutuhan pasar dan roadmap produk.',
    ),
  ];
}

class _GoldenMockJobNotifier extends JobNotifier {
  _GoldenMockJobNotifier(List<JobApplication> jobs, {required bool isDark})
    : super() {
    state = JobState(
      jobs: jobs,
      isLoading: false,
      userName: 'Muhammad Abror Rozaqi',
      userEmail: 'abror.rozaqi@ngelamar.id',
      isProUser: true,
      isDarkMode: isDark,
    );
  }
}

Widget _buildGoldenWrapper({
  required Widget child,
  required bool isDark,
  required double width,
  required double height,
  required List<JobApplication> jobs,
}) {
  final notifier = _GoldenMockJobNotifier(jobs, isDark: isDark);
  return ProviderScope(
    overrides: [jobProvider.overrideWith((ref) => notifier)],
    child: MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.appleLightTheme,
      darkTheme: AppTheme.appleDarkTheme,
      themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
      home: RepaintBoundary(
        key: const ValueKey('golden_root'),
        child: SizedBox(width: width, height: height, child: child),
      ),
    ),
  );
}

void main() {
  late Directory tempDir;

  setUpAll(() async {
    tempDir = Directory.systemTemp.createTempSync('ngelamar_golden_test_');
    Hive.init(tempDir.path);

    try {
      await initializeDateFormatting('id_ID', null);
    } catch (_) {}

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

    SharedPreferences.setMockInitialValues({
      'user_name': 'Muhammad Abror Rozaqi',
      'user_email': 'abror.rozaqi@ngelamar.id',
      'onboarding_done': true,
      'theme_mode': 'light',
    });

    try {
      await SupabaseService.initialize();
    } catch (_) {}

    const fontPaths = <String>[
      'assets/google_fonts/PlusJakartaSans-Regular.ttf',
      'assets/google_fonts/PlusJakartaSans-Medium.ttf',
      'assets/google_fonts/PlusJakartaSans-SemiBold.ttf',
      'assets/google_fonts/PlusJakartaSans-Bold.ttf',
      'assets/google_fonts/PlusJakartaSans-ExtraBold.ttf',
    ];
    final fontBytesByPath = <String, Uint8List>{
      for (final path in fontPaths) path: File(path).readAsBytesSync(),
    };

    final manifestMap = <String, List<Map<String, Object>>>{
      for (final path in fontPaths)
        path: <Map<String, Object>>[
          <String, Object>{'asset': path},
        ],
    };
    final manifestBinBytes = const StandardMessageCodec().encodeMessage(
      manifestMap,
    );
    final manifestJsonBytes = Uint8List.fromList(
      utf8.encode(jsonEncode(manifestMap)),
    );

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMessageHandler('flutter/assets', (ByteData? message) async {
          if (message == null) return null;
          final key = utf8.decode(
            message.buffer.asUint8List(
              message.offsetInBytes,
              message.lengthInBytes,
            ),
          );
          if (key.contains('AssetManifest.bin')) {
            return manifestBinBytes;
          }
          if (key.contains('AssetManifest.json')) {
            return ByteData.view(manifestJsonBytes.buffer);
          }
          if (key.contains('FontManifest.json')) {
            final fontManifest = [
              {
                'family': 'PlusJakartaSans',
                'fonts': [
                  {'asset': 'assets/google_fonts/PlusJakartaSans-Regular.ttf'},
                ],
              },
            ];
            return ByteData.view(
              Uint8List.fromList(utf8.encode(jsonEncode(fontManifest))).buffer,
            );
          }
          final fontBytes = fontBytesByPath[key];
          if (fontBytes != null) {
            return ByteData.view(fontBytes.buffer);
          }
          return null;
        });

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('dexterous.com/flutter/local_notifications'),
          (MethodCall methodCall) async => true,
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

  tearDownAll(() {
    try {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    } catch (_) {}
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({
      'user_name': 'Muhammad Abror Rozaqi',
      'user_email': 'abror.rozaqi@ngelamar.id',
      'onboarding_done': true,
      'theme_mode': 'light',
    });
  });

  final viewports = [
    {'name': '360', 'width': 360.0, 'height': 800.0},
    {'name': '412', 'width': 412.0, 'height': 915.0},
  ];

  final themes = [
    {'name': 'light', 'isDark': false},
    {'name': 'dark', 'isDark': true},
  ];

  final jobs = _createGoldenSampleJobs();

  group('Automated Golden UI Regression Baselines (20 Matrix Snapshots)', () {
    // 1. Home / Dashboard Screen
    for (final theme in themes) {
      for (final vp in viewports) {
        final isDark = theme['isDark'] as bool;
        final themeName = theme['name'] as String;
        final vpName = vp['name'] as String;
        final width = vp['width'] as double;
        final height = vp['height'] as double;
        final fileName = 'goldens/home_${themeName}_$vpName.png';

        testWidgets('Golden: Home ($themeName mode, ${vpName}dp)', (
          tester,
        ) async {
          tester.view.physicalSize = Size(width, height);
          tester.view.devicePixelRatio = 1.0;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);

          await tester.pumpWidget(
            _buildGoldenWrapper(
              isDark: isDark,
              width: width,
              height: height,
              jobs: jobs,
              child: const DashboardScreen(),
            ),
          );
          await tester.pump(const Duration(milliseconds: 300));

          await expectLater(
            find.byKey(const ValueKey('golden_root')),
            matchesGoldenFile(fileName),
          );
        });
      }
    }

    // 2. JobList Screen
    for (final theme in themes) {
      for (final vp in viewports) {
        final isDark = theme['isDark'] as bool;
        final themeName = theme['name'] as String;
        final vpName = vp['name'] as String;
        final width = vp['width'] as double;
        final height = vp['height'] as double;
        final fileName = 'goldens/job_list_${themeName}_$vpName.png';

        testWidgets('Golden: JobList ($themeName mode, ${vpName}dp)', (
          tester,
        ) async {
          tester.view.physicalSize = Size(width, height);
          tester.view.devicePixelRatio = 1.0;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);

          await tester.pumpWidget(
            _buildGoldenWrapper(
              isDark: isDark,
              width: width,
              height: height,
              jobs: jobs,
              child: const JobListScreen(),
            ),
          );
          await tester.pump(const Duration(milliseconds: 300));

          await expectLater(
            find.byKey(const ValueKey('golden_root')),
            matchesGoldenFile(fileName),
          );
        });
      }
    }

    // 3. JobDetail Screen
    for (final theme in themes) {
      for (final vp in viewports) {
        final isDark = theme['isDark'] as bool;
        final themeName = theme['name'] as String;
        final vpName = vp['name'] as String;
        final width = vp['width'] as double;
        final height = vp['height'] as double;
        final fileName = 'goldens/job_detail_${themeName}_$vpName.png';

        testWidgets('Golden: JobDetail ($themeName mode, ${vpName}dp)', (
          tester,
        ) async {
          tester.view.physicalSize = Size(width, height);
          tester.view.devicePixelRatio = 1.0;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);

          await tester.pumpWidget(
            _buildGoldenWrapper(
              isDark: isDark,
              width: width,
              height: height,
              jobs: jobs,
              child: JobDetailScreen(job: jobs.first),
            ),
          );
          await tester.pump(const Duration(milliseconds: 300));
          await GoogleFonts.pendingFonts();
          await tester.pump();

          await expectLater(
            find.byKey(const ValueKey('golden_root')),
            matchesGoldenFile(fileName),
          );
        });
      }
    }

    // 4. Calendar Screen
    for (final theme in themes) {
      for (final vp in viewports) {
        final isDark = theme['isDark'] as bool;
        final themeName = theme['name'] as String;
        final vpName = vp['name'] as String;
        final width = vp['width'] as double;
        final height = vp['height'] as double;
        final fileName = 'goldens/calendar_${themeName}_$vpName.png';

        testWidgets('Golden: Calendar ($themeName mode, ${vpName}dp)', (
          tester,
        ) async {
          tester.view.physicalSize = Size(width, height);
          tester.view.devicePixelRatio = 1.0;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);

          await tester.pumpWidget(
            _buildGoldenWrapper(
              isDark: isDark,
              width: width,
              height: height,
              jobs: jobs,
              child: const CalendarScreen(),
            ),
          );
          await tester.pump(const Duration(milliseconds: 300));

          await expectLater(
            find.byKey(const ValueKey('golden_root')),
            matchesGoldenFile(fileName),
          );
        });
      }
    }

    // 5. Settings / Profile Screen
    for (final theme in themes) {
      for (final vp in viewports) {
        final isDark = theme['isDark'] as bool;
        final themeName = theme['name'] as String;
        final vpName = vp['name'] as String;
        final width = vp['width'] as double;
        final height = vp['height'] as double;
        final fileName = 'goldens/profile_${themeName}_$vpName.png';

        testWidgets('Golden: Profile ($themeName mode, ${vpName}dp)', (
          tester,
        ) async {
          tester.view.physicalSize = Size(width, height);
          tester.view.devicePixelRatio = 1.0;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);

          await tester.pumpWidget(
            _buildGoldenWrapper(
              isDark: isDark,
              width: width,
              height: height,
              jobs: jobs,
              child: const SettingsScreen(),
            ),
          );
          await tester.pump(const Duration(milliseconds: 300));

          await expectLater(
            find.byKey(const ValueKey('golden_root')),
            matchesGoldenFile(fileName),
          );
        });
      }
    }
  });
}
