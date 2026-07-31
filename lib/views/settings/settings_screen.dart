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
import '../../widgets/apple_toast.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _importController = TextEditingController();
  final _nameController = TextEditingController();
  static const String _appVersion = '1.6.0';
  static const String _buildNumber = '160';

  @override
  void initState() {
    super.initState();
    final name = ref.read(jobProvider).userName;
    _nameController.text = name;
  }

  @override
  void dispose() {
    _importController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  // ─────────────────────── Data Actions ────────────────────────────

  void _exportData() {
    final jobs = ref.read(jobProvider).jobs;
    final jsonStr =
        const JsonEncoder.withIndent('  ').convert(jobs.map((j) => j.toMap()).toList());
    Share.share(jsonStr, subject: 'Backup Data Ngelamar App');
  }

  void _copyBackupText() {
    final jobs = ref.read(jobProvider).jobs;
    final jsonStr = jsonEncode(jobs.map((j) => j.toMap()).toList());
    Clipboard.setData(ClipboardData(text: jsonStr));
    _showSnackbar('Data backup berhasil disalin ke Clipboard!',
        color: AppTheme.systemGreen);
  }

  void _shareTextReport() {
    final state = ref.read(jobProvider);
    final buffer = StringBuffer();
    buffer.writeln('LAPORAN PROGRES NGELAMAR');
    buffer.writeln('================================');
    buffer.writeln('Total Lamaran : ${state.totalCount}');
    buffer.writeln('Dikirim       : ${state.appliedCount}');
    buffer.writeln('Interview     : ${state.interviewCount}');
    buffer.writeln('Offering      : ${state.offeringCount}');
    buffer.writeln('Diterima      : ${state.acceptedCount}');
    buffer.writeln('Ditolak       : ${state.rejectedCount}');
    buffer.writeln(
        'Response Rate : ${state.responseRate.toStringAsFixed(0)}%');
    buffer.writeln('================================\n');
    for (var i = 0; i < state.jobs.length; i++) {
      final j = state.jobs[i];
      buffer.writeln('${i + 1}. ${j.position} @ ${j.companyName} [${j.status}]');
    }
    Share.share(buffer.toString(), subject: 'Laporan Progres Ngelamar');
  }

  Future<void> _importData() async {
    final text = _importController.text.trim();
    if (text.isEmpty) {
      _showSnackbar('Silakan tempel teks JSON backup dahulu!',
          color: AppTheme.systemRed);
      return;
    }
    try {
      final List<dynamic> parsed = jsonDecode(text);
      final List<JobApplication> imported =
          parsed.map((m) => JobApplication.fromMap(m)).toList();
      for (var job in imported) {
        await ref.read(jobProvider.notifier).addJob(job);
      }
      _importController.clear();
      if (mounted) {
        _showSnackbar('Berhasil mengimpor ${imported.length} lamaran!',
            color: AppTheme.systemGreen);
      }
    } catch (e) {
      _showSnackbar('Format JSON tidak valid!', color: AppTheme.systemRed);
    }
  }

  Future<void> _clearAllData() async {
    final confirm = await showCupertinoDialog<bool>(
      context: context,
      builder: (_) => CupertinoAlertDialog(
        title: const Text('Hapus Semua Data?'),
        content: const Text(
            'Semua data lamaran akan dihapus permanen. Pastikan sudah backup terlebih dahulu.'),
        actions: [
          CupertinoDialogAction(
              child: const Text('Batal'),
              onPressed: () => Navigator.pop(context, false)),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hapus Semua'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      final jobs = ref.read(jobProvider).jobs;
      for (var j in jobs) {
        await ref.read(jobProvider.notifier).deleteJob(j.id);
      }
      if (mounted) {
        _showSnackbar('Semua data berhasil dihapus.', color: AppTheme.systemRed);
      }
    }
  }

  void _showSnackbar(String msg, {required Color color}) {
    if (color == AppTheme.systemGreen) {
      AppleToast.success(context, msg);
    } else if (color == AppTheme.systemRed) {
      AppleToast.error(context, msg);
    } else {
      AppleToast.warning(context, msg);
    }
  }

  // ─────────────────────── UI ──────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(jobProvider);
    final bottomInset = MediaQuery.of(context).viewPadding.bottom;
    final bg = AppTheme.getBackground(context);
    final txtPri = AppTheme.getTextPrimary(context);
    final txtSec = AppTheme.getTextSecondary(context);
    final txtTer = AppTheme.getTextTertiary(context);

    return Scaffold(
      backgroundColor: bg,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // Apple Large Title
          SliverAppBar(
            backgroundColor: bg,
            surfaceTintColor: Colors.transparent,
            pinned: true,
            expandedHeight: 100,
            collapsedHeight: 56,
            flexibleSpace: LayoutBuilder(
              builder: (context, constraints) {
                final topPadding = MediaQuery.of(context).padding.top;
                const collapsedH = 56.0;
                const expandedH = 100.0;
                final available = constraints.maxHeight - topPadding;
                final progress = 1.0 -
                    ((available - collapsedH) / (expandedH - collapsedH))
                        .clamp(0.0, 1.0);
                return Stack(
                  children: [
                    Positioned(
                      left: 16,
                      bottom: 12,
                      child: Opacity(
                        opacity: (1.0 - progress * 2.5).clamp(0.0, 1.0),
                        child: Text(
                          'Pengaturan',
                          style: TextStyle(
                            fontSize: 34,
                            fontWeight: FontWeight.w700,
                            color: txtPri,
                            letterSpacing: -0.8,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      left: 16,
                      bottom: 14,
                      child: Opacity(
                        opacity: ((progress - 0.6) * 3.0).clamp(0.0, 1.0),
                        child: Text(
                          'Pengaturan',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: txtPri,
                            letterSpacing: -0.3,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),

          // Settings Content
          SliverPadding(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              bottom: bottomInset + 100,
            ),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // ── Profil ──────────────────────────────────────────
                _sectionLabel('PROFIL'),
                _settingsCard([
                  _buildProfileRow(state),
                ]),
                const SizedBox(height: 24),

                // ── Tampilan ────────────────────────────────────────
                _sectionLabel('TAMPILAN'),
                _settingsCard([
                  _buildSwitchRow(
                    icon: CupertinoIcons.moon_fill,
                    iconColor: AppTheme.systemIndigo,
                    title: 'Mode Gelap',
                    subtitle: state.isDarkMode ? 'Aktif' : 'Nonaktif (Mode Terang)',
                    value: state.isDarkMode,
                    onChanged: (_) =>
                        ref.read(jobProvider.notifier).toggleThemeMode(),
                  ),
                ]),
                const SizedBox(height: 24),

                // ── Ekspor & Laporan ─────────────────────────────────
                _sectionLabel('EKSPOR & LAPORAN'),
                _settingsCard([
                  _buildActionRow(
                    icon: CupertinoIcons.share,
                    iconColor: AppTheme.systemBlue,
                    title: 'Bagikan Laporan Teks',
                    subtitle: 'Kirim rekap ke WhatsApp / Catatan',
                    onTap: _shareTextReport,
                  ),
                  _divider(),
                  _buildActionRow(
                    icon: CupertinoIcons.arrow_up_doc,
                    iconColor: AppTheme.systemGreen,
                    title: 'Export JSON Backup',
                    subtitle: 'Simpan & kirim file backup data',
                    onTap: _exportData,
                  ),
                  _divider(),
                  _buildActionRow(
                    icon: CupertinoIcons.doc_on_clipboard,
                    iconColor: AppTheme.systemTeal,
                    title: 'Salin Backup ke Clipboard',
                    subtitle: 'Copy teks JSON backup',
                    onTap: _copyBackupText,
                  ),
                ]),
                const SizedBox(height: 24),

                // ── Impor & Pulihkan Data ────────────────────────────
                _sectionLabel('IMPOR & PULIHKAN DATA'),
                _settingsCard([
                  Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(CupertinoIcons.arrow_down_doc,
                                color: AppTheme.systemOrange, size: 18),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Pulihkan Data (Restore)',
                                      style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 15,
                                          color: txtPri)),
                                  Text('Tempel teks JSON backup di bawah ini',
                                      style: TextStyle(
                                          color: txtSec,
                                          fontSize: 12)),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _importController,
                          maxLines: 4,
                          style: TextStyle(fontSize: 13, color: txtPri),
                          decoration: const InputDecoration(
                            hintText: 'Tempel kode JSON backup di sini...',
                            contentPadding: EdgeInsets.all(12),
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: CupertinoButton(
                            padding: EdgeInsets.zero,
                            onPressed: _importData,
                            child: Container(
                              height: 46,
                              decoration: BoxDecoration(
                                color: AppTheme.systemOrange,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(CupertinoIcons.arrow_down_doc,
                                      color: Colors.white, size: 16),
                                  SizedBox(width: 6),
                                  Text('Impor Data Sekarang',
                                      style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14)),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ]),
                const SizedBox(height: 24),

                // ── Statistik ───────────────────────────────────────
                _sectionLabel('STATISTIK'),
                _settingsCard([
                  _buildStatRow('Total Lamaran', '${state.totalCount}'),
                  _divider(),
                  _buildStatRow('Diterima', '${state.acceptedCount}',
                      valueColor: AppTheme.systemGreen),
                  _divider(),
                  _buildStatRow('Ditolak', '${state.rejectedCount}',
                      valueColor: AppTheme.systemRed),
                  _divider(),
                  _buildStatRow('Response Rate',
                      '${state.responseRate.toStringAsFixed(0)}%'),
                ]),
                const SizedBox(height: 24),

                // ── Berbahaya ────────────────────────────────────────
                _sectionLabel('ZONA BAHAYA'),
                _settingsCard([
                  _buildActionRow(
                    icon: CupertinoIcons.trash,
                    iconColor: AppTheme.systemRed,
                    title: 'Hapus Semua Data',
                    subtitle: 'Menghapus seluruh data lamaran',
                    titleColor: AppTheme.systemRed,
                    showChevron: false,
                    onTap: _clearAllData,
                  ),
                ]),
                const SizedBox(height: 24),

                // ── Tentang Aplikasi ─────────────────────────────────
                _sectionLabel('TENTANG APLIKASI'),
                _settingsCard([
                  _buildInfoRow('Versi Aplikasi', '$_appVersion ($_buildNumber)'),
                  _divider(),
                  _buildInfoRow('Developer', 'idka-solutions team'),
                  _divider(),
                  _buildInfoRow('Framework', 'Flutter + Riverpod'),
                ]),
                const SizedBox(height: 8),
                Center(
                  child: Text(
                    '\u00a9 ${DateTime.now().year} Ngelamar App. All rights reserved.',
                    style: TextStyle(
                        color: txtTer, fontSize: 11),
                  ),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        label,
        style: TextStyle(
          color: AppTheme.getTextTertiary(context),
          fontSize: 12,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.4,
        ),
      ),
    );
  }

  Widget _settingsCard(List<Widget> children) {
    final surf = AppTheme.getSurface(context);
    final bdr = AppTheme.getBorder(context);

    return Container(
      decoration: BoxDecoration(
        color: surf,
        borderRadius: BorderRadius.circular(AppTheme.radiusSettings),
        border: Border.all(color: bdr, width: AppTheme.borderHairline),
      ),
      child: Column(children: children),
    );
  }

  Widget _divider() => Container(
        height: 0.5,
        margin: const EdgeInsets.only(left: 50),
        color: AppTheme.getBorder(context),
      );

  Widget _buildProfileRow(JobState state) {
    final txtPri = AppTheme.getTextPrimary(context);
    final txtSec = AppTheme.getTextSecondary(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppTheme.systemBlue, AppTheme.systemIndigo],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(AppTheme.radiusCard),
            ),
            child: Center(
              child: Text(
                state.userName.isEmpty
                    ? 'J'
                    : state.userName[0].toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  state.userName.isEmpty ? 'Job Seeker' : state.userName,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color: txtPri,
                  ),
                ),
                Text(
                  'Ketuk untuk mengubah nama',
                  style:
                      TextStyle(color: txtSec, fontSize: 12),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: _showEditNameDialog,
            child: const Icon(CupertinoIcons.pencil,
                color: AppTheme.systemBlue, size: 18),
          ),
        ],
      ),
    );
  }

  void _showEditNameDialog() {
    showCupertinoDialog(
      context: context,
      builder: (_) => CupertinoAlertDialog(
        title: const Text('Ubah Nama'),
        content: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: CupertinoTextField(
            controller: _nameController,
            placeholder: 'Nama kamu...',
            autofocus: true,
            textCapitalization: TextCapitalization.words,
          ),
        ),
        actions: [
          CupertinoDialogAction(
            isDestructiveAction: true,
            child: const Text('Batal'),
            onPressed: () {
              _nameController.text = ref.read(jobProvider).userName;
              Navigator.pop(context);
            },
          ),
          CupertinoDialogAction(
            child: const Text('Simpan'),
            onPressed: () async {
              await ref
                  .read(jobProvider.notifier)
                  .setUserName(_nameController.text.trim());
              if (mounted) Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSwitchRow({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    final txtPri = AppTheme.getTextPrimary(context);
    final txtSec = AppTheme.getTextSecondary(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: iconColor,
              borderRadius: BorderRadius.circular(AppTheme.radiusBadge),
            ),
            child: Icon(icon, color: Colors.white, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: txtPri)),
                Text(subtitle,
                    style: TextStyle(
                        fontSize: 12, color: txtSec)),
              ],
            ),
          ),
          CupertinoSwitch(
            value: value,
            activeTrackColor: AppTheme.systemBlue,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildActionRow({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color? titleColor,
    bool showChevron = true,
  }) {
    final txtPri = AppTheme.getTextPrimary(context);
    final txtSec = AppTheme.getTextSecondary(context);
    final txtTer = AppTheme.getTextTertiary(context);

    return AppleBouncyCard(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: iconColor,
                borderRadius: BorderRadius.circular(AppTheme.radiusBadge),
              ),
              child: Icon(icon, color: Colors.white, size: 16),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: titleColor ?? txtPri)),
                  Text(subtitle,
                      style: TextStyle(
                          fontSize: 12, color: txtSec)),
                ],
              ),
            ),
            if (showChevron)
              Icon(CupertinoIcons.chevron_right,
                  color: txtTer, size: 14),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value, {Color? valueColor}) {
    final txtPri = AppTheme.getTextPrimary(context);
    final txtSec = AppTheme.getTextSecondary(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: 15,
                  color: txtPri,
                  fontWeight: FontWeight.w400)),
          Text(value,
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: valueColor ?? txtSec)),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    final txtPri = AppTheme.getTextPrimary(context);
    final txtSec = AppTheme.getTextSecondary(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: 15, color: txtPri)),
          Text(value,
              style: TextStyle(
                  fontSize: 14,
                  color: txtSec,
                  fontWeight: FontWeight.w400)),
        ],
      ),
    );
  }
}
