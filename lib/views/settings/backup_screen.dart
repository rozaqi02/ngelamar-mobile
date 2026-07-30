import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import '../../models/job_application.dart';
import '../../providers/job_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/apple_animations.dart';

class BackupScreen extends ConsumerStatefulWidget {
  const BackupScreen({super.key});

  @override
  ConsumerState<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends ConsumerState<BackupScreen> {
  final TextEditingController _importController = TextEditingController();

  @override
  void dispose() {
    _importController.dispose();
    super.dispose();
  }

  void _exportData() {
    final jobs = ref.read(jobProvider).jobs;
    final jsonList = jobs.map((j) => j.toMap()).toList();
    final jsonStr = const JsonEncoder.withIndent('  ').convert(jsonList);

    Share.share(jsonStr, subject: 'Backup Data Ngelamar App');
  }

  void _copyBackupText() {
    final jobs = ref.read(jobProvider).jobs;
    final jsonList = jobs.map((j) => j.toMap()).toList();
    final jsonStr = jsonEncode(jsonList);

    Clipboard.setData(ClipboardData(text: jsonStr));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        backgroundColor: AppTheme.systemGreen,
        content: Text('Data backup JSON berhasil disalin ke Clipboard!'),
      ),
    );
  }

  // NEW UX FEATURE: Generate Text Report to WhatsApp / Notes
  void _shareTextReport() {
    final state = ref.read(jobProvider);
    final buffer = StringBuffer();
    buffer.writeln('📋 LAPORAN PROGRES NGELAMAR APP');
    buffer.writeln('==============================');
    buffer.writeln('🗃️ Total Lamaran: ${state.totalCount}');
    buffer.writeln('✈️ Dikirim: ${state.appliedCount}');
    buffer.writeln('🎙️ Interview: ${state.interviewCount}');
    buffer.writeln('🎁 Offering: ${state.offeringCount}');
    buffer.writeln('📈 Response Rate: ${state.responseRate.toStringAsFixed(0)}%');
    buffer.writeln('==============================\n');

    for (var i = 0; i < state.jobs.length; i++) {
      final j = state.jobs[i];
      buffer.writeln(
          '${i + 1}. ${j.position} - ${j.companyName} [${j.status}]');
    }

    Share.share(buffer.toString(), subject: 'Laporan Progres Ngelamar App');
  }

  void _importData() async {
    final text = _importController.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Silakan tempel teks JSON backup dahulu!')),
      );
      return;
    }

    try {
      final List<dynamic> parsedList = jsonDecode(text);
      final List<JobApplication> importedJobs =
          parsedList.map((m) => JobApplication.fromMap(m)).toList();

      for (var job in importedJobs) {
        await ref.read(jobProvider.notifier).addJob(job);
      }

      _importController.clear();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppTheme.systemGreen,
            content: Text(
                '🎉 Berhasil mengimpor ${importedJobs.length} data lamaran!'),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppTheme.systemRed,
          content: Text('Format JSON tidak valid. Periksa kembali teks backup.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(jobProvider);

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // iOS Header Title
              const Text(
                'Pengaturan',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 20),

              // NEW UX FEATURE: Quick Share Text Report Section
              const Text(
                'EKSPOR LAPORAN TEKS',
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 8),

              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: Colors.white.withValues(alpha: 0.08)),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color:
                                AppTheme.systemGreen.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(CupertinoIcons.doc_plaintext,
                              color: AppTheme.systemGreen, size: 20),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Laporan Ringkasan Teks',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15)),
                              Text('Kirim rekap progres lamaran ke WA/Catatan',
                                  style: TextStyle(
                                      color: AppTheme.textSecondary,
                                      fontSize: 12)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    AppleBouncyCard(
                      onTap: _shareTextReport,
                      child: Container(
                        width: double.infinity,
                        height: 44,
                        decoration: BoxDecoration(
                          color: AppTheme.systemGreen,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(CupertinoIcons.paperplane_fill,
                                size: 16, color: Colors.white),
                            SizedBox(width: 6),
                            Text('Bagikan Laporan ke WA / Catatan',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Backup Export Card
              const Text(
                'BACKUP & EKSPOR DATA JSON',
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 8),

              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: Colors.white.withValues(alpha: 0.08)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color:
                                AppTheme.systemBlue.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(CupertinoIcons.cloud_upload_fill,
                              color: AppTheme.systemBlue, size: 20),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Cadangkan Data JSON',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15)),
                              Text('Pindahkan data ke HP baru dengan mudah',
                                  style: TextStyle(
                                      color: AppTheme.textSecondary,
                                      fontSize: 12)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Semua data (${state.totalCount} lamaran) tersimpan 100% aman di memori HP lokalmu.',
                      style: const TextStyle(
                          color: AppTheme.textSecondary, fontSize: 12),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: AppleBouncyCard(
                            onTap: _copyBackupText,
                            child: Container(
                              height: 44,
                              decoration: BoxDecoration(
                                border: Border.all(
                                    color: Colors.white
                                        .withValues(alpha: 0.2)),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(CupertinoIcons.doc_on_clipboard,
                                      size: 16, color: AppTheme.textPrimary),
                                  SizedBox(width: 6),
                                  Text('Salin JSON',
                                      style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600)),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: AppleBouncyCard(
                            onTap: _exportData,
                            child: Container(
                              height: 44,
                              decoration: BoxDecoration(
                                color: AppTheme.systemBlue,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(CupertinoIcons.share,
                                      size: 16, color: Colors.white),
                                  SizedBox(width: 6),
                                  Text('Bagikan File',
                                      style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12)),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Restore Import Card
              const Text(
                'IMPOR & PULIHKAN DATA',
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 8),

              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: Colors.white.withValues(alpha: 0.08)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppTheme.systemGreen
                                .withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                              CupertinoIcons.cloud_download_fill,
                              color: AppTheme.systemGreen,
                              size: 20),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Pulihkan Data (Restore)',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15)),
                              Text('Impor file JSON cadanganmu',
                                  style: TextStyle(
                                      color: AppTheme.textSecondary,
                                      fontSize: 12)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: _importController,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        hintText: 'Tempel kode JSON backup di sini...',
                      ),
                    ),
                    const SizedBox(height: 14),
                    AppleBouncyCard(
                      onTap: _importData,
                      child: Container(
                        width: double.infinity,
                        height: 46,
                        decoration: BoxDecoration(
                          color: AppTheme.systemGreen,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(CupertinoIcons.arrow_down_doc,
                                color: Colors.white, size: 18),
                            SizedBox(width: 6),
                            Text('Impor Data Sekarang',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
