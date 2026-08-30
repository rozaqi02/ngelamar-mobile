import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ngelamar/models/job_application.dart';
import 'package:ngelamar/models/user_profile.dart';
import 'package:ngelamar/repositories/profile_repository.dart';
import 'package:ngelamar/services/android_home_widget_service.dart';
import 'package:ngelamar/widgets/app_back_policy.dart';
import 'package:ngelamar/widgets/app_layout_metrics.dart';
import 'package:ngelamar/widgets/safe_avatar_image.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({
      'user_name': 'Budi Prakoso',
      'user_email': 'budi.prakoso@example.com',
      'user_about': 'Senior Flutter Engineer',
      'user_career_interests': ['Flutter Developer', 'Mobile Lead'],
      'onboarding_done': true,
    });
  });

  group('WP-02: Navigation & Back Policy Contract', () {
    test('Root dock tabs never require app-bar back buttons', () {
      expect(
        AppBackPolicy.shouldShowAppBarBackButton(isRootShellTab: true),
        isFalse,
      );
      expect(
        AppBackPolicy.shouldShowAppBarBackButton(isRootShellTab: false),
        isTrue,
      );
    });

    testWidgets(
      'Secondary tab back gesture navigates back to Tab 0 (Beranda)',
      (tester) async {
        var activeTab = 3;
        DateTime? lastBackPress;

        await tester.pumpWidget(
          MaterialApp(
            home: Builder(
              builder: (context) {
                return AppBackScope(
                  isRootShell: true,
                  currentTabIndex: activeTab,
                  onSwitchTab: (tab) => activeTab = tab,
                  lastBackPressTime: lastBackPress,
                  onUpdateBackPressTime: (time) => lastBackPress = time,
                  child: const Scaffold(body: Text('Root Shell Tab 3')),
                );
              },
            ),
          ),
        );

        final handled = AppBackPolicy.handleRootBack(
          context: tester.element(find.byType(Scaffold)),
          currentIndex: activeTab,
          onSwitchTab: (tab) => activeTab = tab,
          lastBackPressTime: lastBackPress,
          onUpdateBackPressTime: (time) => lastBackPress = time,
        );

        expect(handled, isFalse);
        expect(activeTab, equals(0));
      },
    );

    testWidgets(
      'First back press on Tab 0 updates timestamp and displays warning toast',
      (tester) async {
        var activeTab = 0;
        DateTime? lastBackPress;

        await tester.pumpWidget(
          MaterialApp(
            home: Builder(
              builder: (context) {
                return Scaffold(
                  body: AppBackScope(
                    isRootShell: true,
                    currentTabIndex: activeTab,
                    onSwitchTab: (tab) => activeTab = tab,
                    lastBackPressTime: lastBackPress,
                    onUpdateBackPressTime: (time) => lastBackPress = time,
                    child: const Text('Beranda Tab 0'),
                  ),
                );
              },
            ),
          ),
        );

        final context = tester.element(find.byType(Scaffold));
        final handled = AppBackPolicy.handleRootBack(
          context: context,
          currentIndex: activeTab,
          onSwitchTab: (tab) => activeTab = tab,
          lastBackPressTime: lastBackPress,
          onUpdateBackPressTime: (time) => lastBackPress = time,
        );

        expect(handled, isFalse);
        expect(lastBackPress, isNotNull);
        await tester.pump(const Duration(seconds: 4));
      },
    );

    testWidgets('Child screen pop contract safely executes without throwing', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (ctx) => const AppBackScope(
                        child: Scaffold(body: Text('Child Screen')),
                      ),
                    ),
                  );
                },
                child: const Text('Open Child'),
              );
            },
          ),
        ),
      );

      await tester.tap(find.text('Open Child'));
      await tester.pumpAndSettle();
      expect(find.text('Child Screen'), findsOneWidget);

      AppBackPolicy.handleChildBack(
        context: tester.element(find.text('Child Screen')),
      );
      await tester.pumpAndSettle();
      expect(find.text('Open Child'), findsOneWidget);
    });
  });

  group('WP-03: Profile Persistence & Safe Avatar', () {
    test(
      'UserProfile computes initials and fallback colors deterministically',
      () {
        const p1 = UserProfile(name: 'Budi Prakoso');
        expect(p1.initials, equals('BP'));
        expect(p1.fallbackColor, isNotNull);

        const p2 = UserProfile(name: 'Anita');
        expect(p2.initials, equals('AN'));

        const p3 = UserProfile(name: '');
        expect(p3.initials, equals('N'));
      },
    );

    test('ProfileRepository initializes and persists user profile', () async {
      final repo = ProfileRepository();
      final profile = await repo.loadProfile();

      expect(profile.name, equals('Budi Prakoso'));
      expect(profile.email, equals('budi.prakoso@example.com'));
      expect(profile.about, equals('Senior Flutter Engineer'));
      expect(profile.careerInterests, contains('Flutter Developer'));

      final updated = profile.copyWith(about: 'Lead Mobile Architect');
      await repo.saveProfile(updated);
      expect(repo.currentProfile.about, equals('Lead Mobile Architect'));
    });

    test(
      'ProfileRepository saveAvatarBytes stores data URI safely on web format',
      () async {
        final repo = ProfileRepository();
        final dummyBytes = Uint8List.fromList([
          137,
          80,
          78,
          71,
          13,
          10,
          26,
          10,
        ]);
        final uri = await repo.saveAvatarBytes(dummyBytes);

        expect(uri, isNotNull);
        expect(repo.currentProfile.avatarPath, isNotNull);
      },
    );

    testWidgets(
      'SafeAvatarImage renders monogram initials fallback on missing/null path',
      (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: SafeAvatarImage(
                imagePath: null,
                size: 48,
                displayName: 'Budi Prakoso',
              ),
            ),
          ),
        );

        expect(find.text('BP'), findsOneWidget);
      },
    );

    testWidgets(
      'SafeAvatarImage handles corrupted base64 data URI without throwing',
      (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: SafeAvatarImage(
                imagePath:
                    'data:image/png;base64,not_valid_base64_data_corrupt!',
                size: 48,
                displayName: 'Dewi Sartika',
              ),
            ),
          ),
        );

        expect(find.text('DS'), findsOneWidget);
      },
    );

    testWidgets('SafeAvatarImage renders valid Base64 PNG image', (
      tester,
    ) async {
      // 1x1 transparent PNG
      const validPngBase64 =
          'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=';

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SafeAvatarImage(
              imagePath: validPngBase64,
              size: 56,
              displayName: 'Budi Prakoso',
            ),
          ),
        ),
      );

      expect(find.byType(Image), findsOneWidget);
    });
  });

  group('WP-04: Android Home Widget Adaptive Projection & Reliability', () {
    test(
      'AndroidHomeWidgetService buildProjection produces valid multi-field projection',
      () {
        final now = DateTime.now();
        final interviewJob = JobApplication(
          id: 'job_interview_1',
          companyName: 'PT GoTo Gojek Tokopedia',
          position: 'Senior Mobile Engineer',
          status: 'Interview HR',
          workType: 'WFO',
          jobDescription: 'Senior Flutter Developer role.',
          interviewDate: now.add(const Duration(days: 2)),
          location: 'Menara Pasaraya Blok M',
          appliedDate: now,
          updatedAt: now,
        );

        final projection = AndroidHomeWidgetService.buildProjection([
          interviewJob,
        ], now: now);

        expect(projection.hasContent, isTrue);
        expect(projection.companyName, equals('PT GoTo Gojek Tokopedia'));
        expect(projection.position, equals('Senior Mobile Engineer'));
        expect(projection.stageLabel, equals('Interview HR'));
        expect(projection.activeCount, equals(1));
      },
    );

    test(
      'AndroidHomeWidgetService projection toMap serializes without nulls',
      () {
        final projection = AndroidWidgetProjection.empty();
        final map = projection.toMap();

        expect(map['kind'], equals('empty'));
        expect(map['activeCount'], equals(0));
        expect(map['hasContent'], equals(false));
        expect(map['label'], equals('NGELAMAR'));
      },
    );

    test(
      'AndroidHomeWidgetService projects active job when no interview is scheduled',
      () {
        final now = DateTime.now();
        final savedJob = JobApplication(
          id: 'job_saved_1',
          companyName: 'PT Tokopedia',
          position: 'Flutter Specialist',
          status: 'Tersimpan',
          workType: 'WFO',
          jobDescription: 'Flutter specialist role.',
          appliedDate: now,
          updatedAt: now,
        );

        final projection = AndroidHomeWidgetService.buildProjection([
          savedJob,
        ], now: now);

        expect(projection.hasContent, isTrue);
        expect(projection.jobId, equals('job_saved_1'));
        expect(projection.companyName, equals('PT Tokopedia'));
      },
    );
  });

  group('WP-09: Safe Area & AppScaffoldInsets Centralization', () {
    testWidgets(
      'AppScaffoldInsets resolves valid metrics for rootTab and fullScreenRoute',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Builder(
              builder: (context) {
                final rootInsets = AppScaffoldInsets.of(
                  context,
                  mode: ScaffoldInsetMode.rootTab,
                );
                final fullInsets = AppScaffoldInsets.of(
                  context,
                  mode: ScaffoldInsetMode.fullScreenRoute,
                );

                expect(rootInsets.topHeader, greaterThanOrEqualTo(16.0));
                expect(rootInsets.bottomDock, greaterThanOrEqualTo(12.0));
                expect(
                  rootInsets.contentBottom,
                  greaterThan(rootInsets.bottomDock),
                );

                expect(fullInsets.topHeader, greaterThanOrEqualTo(16.0));
                expect(fullInsets.bottomDock, greaterThan(0));

                return const Scaffold(body: Text('Insets Test'));
              },
            ),
          ),
        );

        expect(find.text('Insets Test'), findsOneWidget);
      },
    );

    test('AppLayoutMetrics provides non-zero dock height and gap', () {
      expect(AppLayoutMetrics.floatingNavigationHeight, equals(94.0));
      expect(AppLayoutMetrics.floatingNavigationGap, equals(24.0));
    });
  });
}
