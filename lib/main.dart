import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'providers/job_provider.dart';
import 'theme/app_theme.dart';
import 'views/splash_screen.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await NotificationService.init();

  runApp(const ProviderScope(child: NgelamarApp()));
}

class NgelamarApp extends ConsumerWidget {
  const NgelamarApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
