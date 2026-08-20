import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import '../../models/job_application.dart';
import '../../providers/job_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/apple_toast.dart';
import '../prep/fresh_grad_prep_screen.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _importController = TextEditingController();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  static const String _appVersion = '1.7.6';
  static const String _buildNumber = '176';

  @override
  void initState() {
    super.initState();
    _nameController.text = ref.read(jobProvider).userName;
    _emailController.text = ref.read(jobProvider).userEmail;
  }

  @override
  void dispose() {
    _importController.dispose();
    _nameController.dispose();
    _emailController.dispose();
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
    AppleToast.success(context, 'Data backup JSON disalin ke Clipboard');
  }

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
      buffer.writeln('${i + 1}. ${j.position} - ${j.companyName} [${j.status}]');
    }

    Share.share(buffer.toString(), subject: 'Laporan Progres Ngelamar App');
  }

  void _importData() async {
    final text = _importController.text.trim();
    if (text.isEmpty) {
      AppleToast.warning(context, 'Tempel teks JSON backup terlebih dahulu.');
      return;
    }

    try {
      final decoded = jsonDecode(text);
      if (decoded is! List) throw const FormatException();
      final importedJobs = decoded.map((item) => JobApplication.fromMap(Map<String, dynamic>.from(item))).toList();
      await ref.read(jobProvider.notifier).importJobs(importedJobs);

      _importController.clear();
      if (mounted) {
        AppleToast.success(context, 'Berhasil mengimpor ${importedJobs.length} data lamaran!');
      }
    } catch (_) {
      if (mounted) AppleToast.error(context, 'Format JSON backup tidak valid.');
    }
  }

  Future<void> _clearAllData() async {
    final confirm = await showCupertinoDialog<bool>(
      context: context,
      builder: (_) => CupertinoAlertDialog(
        title: const Text('Hapus Semua Data?'),
        content: const Text('Semua data lamaran akan dihapus permanen.'),
        actions: [
          CupertinoDialogAction(child: const Text('Batal'), onPressed: () => Navigator.pop(context, false)),
          CupertinoDialogAction(
            isDestructiveAction: true,
            child: const Text('Hapus Semua'),
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await ref.read(jobProvider.notifier).clearAllJobs();
      if (mounted) AppleToast.success(context, 'Semua data telah dibersihkan.');
    }
  }

  void _showEditProfileDialog() {
    _nameController.text = ref.read(jobProvider).userName;
    _emailController.text = ref.read(jobProvider).userEmail;

    showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('Edit Profil'),
        content: Padding(
          padding: const EdgeInsets.only(top: 12),
          child: Column(
            children: [
              CupertinoTextField(
                controller: _nameController,
                placeholder: 'Nama Lengkap...',
              ),
              const SizedBox(height: 8),
              CupertinoTextField(
                controller: _emailController,
                placeholder: 'Email...',
              ),
            ],
          ),
        ),
        actions: [
          CupertinoDialogAction(child: const Text('Batal'), onPressed: () => Navigator.pop(ctx)),
          CupertinoDialogAction(
            child: const Text('Simpan'),
            onPressed: () async {
              await ref.read(jobProvider.notifier).setUserName(_nameController.text.trim());
              await ref.read(jobProvider.notifier).setUserEmail(_emailController.text.trim());
              if (mounted) Navigator.pop(ctx);
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(jobProvider);
    final isDark = AppTheme.isDark(context);
    final bg = AppTheme.getBackground(context);
    final cardBg = isDark ? const Color(0xFF1E1E22) : Colors.white;
    final txtPri = AppTheme.getTextPrimary(context);

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                child: Text(
                  'PROFIL &\nPENGATURAN',
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w900,
                    color: txtPri,
                    letterSpacing: -1.2,
                    height: 1.0,
                  ),
                ),
              ),
            ),

            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 110),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // User Profile Hero Card
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFF19191B),
                      borderRadius: BorderRadius.circular(AppTheme.radiusCardLarge),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 52,
                          height: 52,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: const Center(
                            child: Icon(CupertinoIcons.person_fill, color: Color(0xFF19191B), size: 28),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                state.userName.isNotEmpty ? state.userName : 'Michel Clark',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              Text(
                                state.userEmail.isNotEmpty ? state.userEmail : 'Software Engineer',
                                style: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: _showEditProfileDialog,
                          icon: const Icon(CupertinoIcons.pencil, color: Colors.white),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 18),

                  // Data & Backup Section
                  _sectionHeader('BACKUP & EKSPOR DATA'),
                  Container(
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(AppTheme.radiusCard),
                      border: Border.all(color: const Color(0xFFE6E3D8)),
                    ),
                    child: Column(
                      children: [
                        _buildSettingTile(
                          icon: CupertinoIcons.share,
                          color: AppTheme.cardPurple,
                          title: 'Bagikan Laporan Teks',
                          subtitle: 'Kirim rekap status ke WhatsApp / Catatan',
                          onTap: _shareTextReport,
                        ),
                        const Divider(height: 1, indent: 54),
                        _buildSettingTile(
                          icon: CupertinoIcons.doc_on_doc,
                          color: AppTheme.cardYellow,
                          title: 'Salin JSON Backup',
                          subtitle: 'Simpan backup ke Clipboard',
                          onTap: _copyBackupText,
                        ),
                        const Divider(height: 1, indent: 54),
                        _buildSettingTile(
                          icon: CupertinoIcons.arrow_up_doc,
                          color: AppTheme.cardGreen,
                          title: 'Ekspor File JSON',
                          subtitle: 'Kirim file backup ke cloud / chat',
                          onTap: _exportData,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 18),

                  // Restore Section
                  _sectionHeader('PULIHKAN DATA (RESTORE)'),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(AppTheme.radiusCard),
                      border: Border.all(color: const Color(0xFFE6E3D8)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextField(
                          controller: _importController,
                          maxLines: 3,
                          style: const TextStyle(fontSize: 12),
                          decoration: const InputDecoration(
                            hintText: 'Tempel teks JSON backup di sini...',
                          ),
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _importData,
                            icon: const Icon(CupertinoIcons.arrow_down_doc, size: 16),
                            label: const Text('Impor & Pulihkan'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF19191B),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 18),

                  // Danger Zone
                  _sectionHeader('ZONA BERSIH DATA'),
                  Container(
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(AppTheme.radiusCard),
                      border: Border.all(color: const Color(0xFFE6E3D8)),
                    ),
                    child: _buildSettingTile(
                      icon: CupertinoIcons.trash,
                      color: AppTheme.systemRed,
                      title: 'Hapus Semua Data',
                      subtitle: 'Menghapus seluruh lamaran yang tersimpan',
                      onTap: _clearAllData,
                    ),
                  ),

                  const SizedBox(height: 24),

                  // App Info
                  Center(
                    child: Column(
                      children: [
                        Text(
                          'Ngelamar v$_appVersion ($_buildNumber)',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey.shade600),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Personal Career CRM • idka-solutions team',
                          style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                        ),
                      ],
                    ),
                  ),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader(String label) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: Colors.grey,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildSettingTile({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: color, size: 18),
      ),
      title: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
      subtitle: Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
      trailing: const Icon(CupertinoIcons.chevron_right, size: 14, color: Colors.grey),
      onTap: onTap,
    );
  }
}
