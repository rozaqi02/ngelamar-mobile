import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'providers/job_provider.dart';
import 'theme/app_theme.dart';
import 'views/splash_screen.dart';
import 'services/inbox_service.dart';
import 'services/notification_service.dart';
import 'services/supabase_service.dart';
import 'services/analytics_service.dart';
import 'services/remote_config_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await SupabaseService.initialize();
  await NotificationService.init();
  try {
    await initializeDateFormatting('id_ID', null);
  } catch (e) {
    debugPrint('DateFormatting init error: $e');
  }

  runApp(const ProviderScope(child: NgelamarApp()));
}

class NgelamarApp extends ConsumerStatefulWidget {
  const NgelamarApp({super.key});

  @override
  ConsumerState<NgelamarApp> createState() => _NgelamarAppState();
}

class _NgelamarAppState extends ConsumerState<NgelamarApp>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(SupabaseService.markUserActive(force: true));
    unawaited(RemoteConfigService.refresh());
    unawaited(AnalyticsService.track('app_open'));
    unawaited(InboxService.fetch());
    InboxService.initRealtimeListener();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(SupabaseService.markUserActive());
      unawaited(RemoteConfigService.refresh());
      unawaited(InboxService.fetch());
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ref.watch(jobProvider).isDarkMode;
    return MaterialApp(
      title: 'Ngelamar',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.appleLightTheme,
      darkTheme: AppTheme.appleDarkTheme,
      themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
      home: const SplashScreen(),
    );
  }
}
