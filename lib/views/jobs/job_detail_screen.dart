import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../models/job_application.dart';
import '../../providers/job_provider.dart';
import '../../services/followup_service.dart';
import '../../services/salary_evaluator_service.dart';
import '../../services/text_parser_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/apple_sheet_window.dart';
import '../../widgets/apple_toast.dart';
import 'add_edit_job_screen.dart';

class JobDetailScreen extends ConsumerStatefulWidget {
  final JobApplication job;

  const JobDetailScreen({super.key, required this.job});

  @override
  ConsumerState<JobDetailScreen> createState() => _JobDetailScreenState();
}

class _JobDetailScreenState extends ConsumerState<JobDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final List<String> _statusOptions = [
    'Dikirim',
    'HR Screening',
    'Tes / Psikotes',
    'Interview HR',
    'Interview User',
    'Offering',
    'Diterima',
    'Ditolak',
  ];

  // Salary Evaluator State
  String _selectedCity = 'Jakarta';
  bool _needsKos = true;

  // Follow-up State
  int _selectedTemplateIndex = 0;
  late TextEditingController _followupContentController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);

    if (widget.job.location != null && widget.job.location!.isNotEmpty) {
      final match = SalaryEvaluatorService.umrList.firstWhere(
        (u) => u.city.toLowerCase() == widget.job.location!.toLowerCase(),
        orElse: () => SalaryEvaluatorService.umrList.first,
      );
      _selectedCity = match.city;
    }

    final templates = FollowupService.generateTemplates(widget.job);
    _followupContentController = TextEditingController(
      text: templates[_selectedTemplateIndex].content,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _followupContentController.dispose();
    super.dispose();
  }

  Future<void> _updateStatus(
    JobApplication currentJob,
    String newStatus,
  ) async {
    try {
      await ref
          .read(jobProvider.notifier)
          .updateStatus(currentJob.id, newStatus);
      if (mounted) {
        AppleToast.success(
          context,
          'Status berhasil diubah menjadi "$newStatus"',
        );
      }
    } catch (_) {
      if (mounted) {
        AppleToast.error(context, 'Status gagal disimpan. Coba lagi.');
      }
    }
  }

  void _deleteJob(JobApplication currentJob) async {
    final confirm = await showCupertinoDialog<bool>(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Hapus Lamaran?'),
        content: Text(
          'Apakah Anda yakin ingin menghapus lamaran ${currentJob.position} di ${currentJob.companyName}?',
        ),
        actions: [
          CupertinoDialogAction(
            child: const Text('Batal'),
            onPressed: () => Navigator.pop(context, false),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await ref.read(jobProvider.notifier).deleteJob(currentJob.id);
      } catch (_) {
        if (mounted) AppleToast.error(context, 'Lamaran gagal dihapus.');
        return;
      }
      if (mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Live reactive job state from provider
    final currentJob = ref
        .watch(jobProvider)
        .jobs
        .firstWhere((j) => j.id == widget.job.id, orElse: () => widget.job);

    final isDark = AppTheme.isDark(context);
    final statusColor = AppTheme.getStatusColor(
      currentJob.status,
      isDark: isDark,
    );
    final bg = AppTheme.getBackground(context);
    final surf = AppTheme.getSurface(context);
    final surfSec = AppTheme.getSurfaceSecondary(context);
    final txtPri = AppTheme.getTextPrimary(context);
    final txtSec = AppTheme.getTextSecondary(context);

    return Scaffold(
      backgroundColor: bg,
      body: Column(
        children: [
          // Custom Sheet Header
          Container(
            color: surf,
            child: SafeArea(
              bottom: false,
              child: Column(
                children: [
                  // Drag handle + actions row
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    child: Row(
                      children: [
                        // Back / Close
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            padding: const EdgeInsets.all(7),
                            decoration: BoxDecoration(
                              color: surfSec,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              CupertinoIcons.chevron_down,
                              size: 16,
                              color: txtSec,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                currentJob.position,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: txtPri,
                                  letterSpacing: -0.3,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                currentJob.companyName,
                                style: TextStyle(fontSize: 13, color: txtSec),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        // Edit
                        IconButton(
                          icon: const Icon(
                            CupertinoIcons.pencil,
                            color: AppTheme.systemBlue,
                            size: 20,
                          ),
                          onPressed: () async {
                            final result =
                                await AppleSheetWindow.showAppleModalSheet(
                                  context: context,
                                  child: AddEditJobScreen(
                                    jobToEdit: currentJob,
                                  ),
                                );
                            if (result != null && context.mounted) {
                              AppleToast.success(context, 'Perubahan disimpan');
                            }
                          },
                        ),
                        // Delete
                        IconButton(
                          icon: const Icon(
                            CupertinoIcons.trash,
                            color: AppTheme.systemRed,
                            size: 20,
                          ),
                          onPressed: () => _deleteJob(currentJob),
                        ),
                      ],
                    ),
                  ),
                  // Tab bar with Icons (Request 2)
                  TabBar(
                    controller: _tabController,
                    isScrollable: true,
                    tabAlignment: TabAlignment.start,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    labelPadding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    splashFactory: NoSplash.splashFactory,
                    indicatorSize: TabBarIndicatorSize.tab,
                    indicator: BoxDecoration(
                      color:
                          (isDark ? AppTheme.systemBlue : AppTheme.lSystemBlue)
                              .withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    labelColor: AppTheme.systemBlue,
                    unselectedLabelColor: txtSec,
                    dividerColor: Colors.transparent,
                    dividerHeight: 0,
                    labelStyle: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                    tabs: const [
                      Tab(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(CupertinoIcons.info_circle, size: 14),
                            SizedBox(width: 4),
                            Text('Detail'),
                          ],
                        ),
                      ),
                      Tab(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(CupertinoIcons.doc_plaintext, size: 14),
                            SizedBox(width: 4),
                            Text('Cheat-Sheet'),
                          ],
                        ),
                      ),
                      Tab(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(CupertinoIcons.chat_bubble_2, size: 14),
                            SizedBox(width: 4),
                            Text('Follow-Up'),
                          ],
                        ),
                      ),
                      Tab(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(CupertinoIcons.number_circle, size: 14),
                            SizedBox(width: 4),
                            Text('Gaji & Offer'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Tab Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              physics: const BouncingScrollPhysics(),
              children: [
                _buildAppleDetailTab(currentJob, statusColor),
                _buildAppleInterviewCheatSheetTab(currentJob),
                _buildAppleFollowupGeneratorTab(currentJob),
                _buildAppleSalaryEvaluatorTab(currentJob),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // TAB 1: DETAIL (Comprehensive)
  Widget _buildAppleDetailTab(JobApplication currentJob, Color statusColor) {
    final dateStr = DateFormat('dd MMMM yyyy').format(currentJob.appliedDate);
    final interviewStr = currentJob.interviewDate != null
        ? DateFormat('EEEE, dd MMMM yyyy').format(currentJob.interviewDate!)
        : null;

    final surf = AppTheme.getSurface(context);
    final surfSec = AppTheme.getSurfaceSecondary(context);
    final bdr = AppTheme.getBorder(context);
    final txtPri = AppTheme.getTextPrimary(context);
    final txtSec = AppTheme.getTextSecondary(context);

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status & Favorit Card
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: surf,
              borderRadius: BorderRadius.circular(AppTheme.radiusCard),
              border: Border.all(
                color: statusColor.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Status Lamaran',
                        style: TextStyle(
                          fontSize: 11,
                          color: txtSec,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          currentJob.status,
                          style: TextStyle(
                            color: statusColor,
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Status action sheet
                GestureDetector(
                  onTap: () {
                    showCupertinoModalPopup(
                      context: context,
                      builder: (_) => CupertinoActionSheet(
                        title: const Text('Ubah Status Lamaran'),
                        actions: _statusOptions.map((s) {
                          final sColor = AppTheme.getStatusColor(
                            s,
                            isDark: AppTheme.isDark(context),
                          );
                          return CupertinoActionSheetAction(
                            onPressed: () {
                              Navigator.pop(context);
                              _updateStatus(currentJob, s);
                            },
                            child: Text(
                              s,
                              style: TextStyle(
                                color: sColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          );
                        }).toList(),
                        cancelButton: CupertinoActionSheetAction(
                          isDefaultAction: true,
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Batal'),
                        ),
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: surfSec,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      CupertinoIcons.arrow_up_arrow_down,
                      size: 14,
                      color: txtSec,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                // Favorite toggle (Instant reactive update)
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    ref
                        .read(jobProvider.notifier)
                        .toggleFavorite(currentJob.id);
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Icon(
                      currentJob.isFavorite
                          ? CupertinoIcons.star_fill
                          : CupertinoIcons.star,
                      color: currentJob.isFavorite
                          ? AppTheme.systemOrange
                          : AppTheme.getTextTertiary(context),
                      size: 24,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Info Grid
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: surf,
              borderRadius: BorderRadius.circular(AppTheme.radiusCard),
              border: Border.all(color: bdr, width: 0.8),
            ),
            child: Column(
              children: [
                _infoRow(CupertinoIcons.calendar, 'Tanggal Melamar', dateStr),
                _divider(),
                _infoRow(
                  CupertinoIcons.briefcase,
                  'Tipe Kerja',
                  currentJob.workType,
                ),
                if (currentJob.location != null) ...[
                  _divider(),
                  _infoRow(
                    CupertinoIcons.location,
                    'Lokasi',
                    currentJob.location!,
                  ),
                ],
                if (currentJob.jobSource != null) ...[
                  _divider(),
                  _infoRow(
                    CupertinoIcons.link,
                    'Sumber Loker',
                    currentJob.jobSource!,
                  ),
                ],
                if (currentJob.salaryOffered != null) ...[
                  _divider(),
                  _infoRow(
                    CupertinoIcons.money_dollar_circle,
                    'Ekspektasi / Gaji Ditawarkan',
                    currentJob.salaryOffered!,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Jadwal Interview
          if (interviewStr != null)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.systemOrange.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(AppTheme.radiusCard),
                border: Border.all(
                  color: AppTheme.systemOrange.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppTheme.systemOrange.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      CupertinoIcons.calendar_badge_plus,
                      color: AppTheme.systemOrange,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Jadwal Interview',
                          style: TextStyle(
                            color: AppTheme.systemOrange,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          interviewStr,
                          style: TextStyle(
                            color: txtPri,
                            fontWeight: FontWeight.w500,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

          if (interviewStr != null) const SizedBox(height: 12),

          // HR Contact
          if (currentJob.hrContact != null && currentJob.hrContact!.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.systemBlue.withValues(alpha: 0.07),
                borderRadius: BorderRadius.circular(AppTheme.radiusCard),
                border: Border.all(
                  color: AppTheme.systemBlue.withValues(alpha: 0.25),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppTheme.systemBlue.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      CupertinoIcons.phone_fill,
                      color: AppTheme.systemBlue,
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Kontak HRD',
                          style: TextStyle(
                            fontSize: 12,
                            color: txtSec,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          currentJob.hrContact!,
                          style: TextStyle(
                            color: txtPri,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () => _tabController.animateTo(2),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.systemBlue,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text(
                        'Follow Up',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

          if (currentJob.hrContact != null && currentJob.hrContact!.isNotEmpty)
            const SizedBox(height: 12),

          // Catatan Pribadi
          if (currentJob.notes != null && currentJob.notes!.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: surf,
                borderRadius: BorderRadius.circular(AppTheme.radiusCard),
                border: Border.all(color: bdr, width: 0.8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        CupertinoIcons.pencil_outline,
                        size: 14,
                        color: txtSec,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Catatan Pribadi',
                        style: TextStyle(
                          fontSize: 12,
                          color: txtSec,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    currentJob.notes!,
                    style: TextStyle(
                      fontSize: 14,
                      color: txtPri,
                      height: 1.5,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),

          if (currentJob.notes != null && currentJob.notes!.isNotEmpty)
            const SizedBox(height: 12),

          // Snapshot Deskripsi
          if (currentJob.jobDescription.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: surf,
                borderRadius: BorderRadius.circular(AppTheme.radiusCard),
                border: Border.all(color: bdr, width: 0.8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        CupertinoIcons.doc_plaintext,
                        size: 14,
                        color: txtSec,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Snapshot Deskripsi Loker',
                        style: TextStyle(
                          fontSize: 12,
                          color: txtSec,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    currentJob.jobDescription,
                    style: TextStyle(fontSize: 13, color: txtPri, height: 1.6),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    final txtPri = AppTheme.getTextPrimary(context);
    final txtSec = AppTheme.getTextSecondary(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: txtSec),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: txtSec,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    color: txtPri,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider() =>
      Container(height: 0.5, color: AppTheme.getBorder(context));

  // TAB 2: INTERVIEW CHEAT-SHEET
  Widget _buildAppleInterviewCheatSheetTab(JobApplication currentJob) {
    final parsed = TextParserService.parseJobText(currentJob.jobDescription);
    final skills = parsed.extractedSkills;
    final surf = AppTheme.getSurface(context);
    final txtPri = AppTheme.getTextPrimary(context);
    final txtSec = AppTheme.getTextSecondary(context);

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Skill Highlights Card
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: surf,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppTheme.systemGreen.withValues(alpha: 0.3),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(
                      CupertinoIcons.sparkles,
                      color: AppTheme.systemGreen,
                      size: 20,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Skill Kunci Terdeteksi',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (skills.isEmpty)
                  Text(
                    'Belum ada skill spesifik terdeteksi dari deskripsi.',
                    style: TextStyle(color: txtSec, fontSize: 13),
                  )
                else
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: skills
                        .map(
                          (s) => Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.systemGreen.withValues(
                                alpha: 0.15,
                              ),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Text(
                              s,
                              style: const TextStyle(
                                color: AppTheme.systemGreen,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Starter Questions Card
          Text(
            'Pertanyaan yang Sering Ditanyakan',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 17,
              color: txtPri,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 10),
          _cheatSheetItem(
            '1. Ceritakan tentang diri Anda & alasan melamar di ${currentJob.companyName}.',
            'Fokus pada kecocokan skill Anda dengan kualifikasi ${currentJob.position}.',
          ),
          _cheatSheetItem(
            '2. Kenapa Anda tertarik pada posisi ${currentJob.position}?',
            'Sebutkan proyek/skill terkait dan bagaimana Anda bisa memberikan dampak.',
          ),
          _cheatSheetItem(
            '3. Berapa ekspektasi gaji Anda?',
            'Gunakan fitur Gaji & Offer di tab sebelah untuk mengevaluasi UMR & biaya hidup.',
          ),
        ],
      ),
    );
  }

  Widget _cheatSheetItem(String question, String tip) {
    final surf = AppTheme.getSurface(context);
    final bdr = AppTheme.getBorder(context);
    final txtPri = AppTheme.getTextPrimary(context);
    final txtSec = AppTheme.getTextSecondary(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surf,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: bdr),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            question,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: txtPri,
            ),
          ),
          const SizedBox(height: 6),
          Text(tip, style: TextStyle(color: txtSec, fontSize: 13, height: 1.4)),
        ],
      ),
    );
  }

  // TAB 3: FOLLOW-UP GENERATOR
  Widget _buildAppleFollowupGeneratorTab(JobApplication currentJob) {
    final templates = FollowupService.generateTemplates(currentJob);
    final surf = AppTheme.getSurface(context);
    final surfSec = AppTheme.getSurfaceSecondary(context);
    final bdr = AppTheme.getBorder(context);
    final txtPri = AppTheme.getTextPrimary(context);
    final txtSec = AppTheme.getTextSecondary(context);

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Pilih Jenis Template',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 17,
              color: txtPri,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 10),

          // Template selector chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: List.generate(templates.length, (index) {
                final selected = _selectedTemplateIndex == index;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedTemplateIndex = index;
                        _followupContentController.text =
                            templates[index].content;
                      });
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: selected ? AppTheme.systemBlue : surfSec,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: selected ? AppTheme.systemBlue : bdr,
                          width: AppTheme.borderHairline,
                        ),
                      ),
                      child: Text(
                        templates[index].title,
                        style: TextStyle(
                          color: selected ? Colors.white : txtSec,
                          fontSize: 12,
                          fontWeight: selected
                              ? FontWeight.w600
                              : FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 20),

          // Editor box
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: surf,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: bdr),
            ),
            child: Column(
              children: [
                TextField(
                  controller: _followupContentController,
                  maxLines: 8,
                  style: TextStyle(fontSize: 13, height: 1.5, color: txtPri),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    enabledBorder: InputBorder.none,
                  ),
                ),
                const Divider(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          final text = _followupContentController.text;
                          Clipboard.setData(ClipboardData(text: text));
                          final hrContact = currentJob.hrContact;
                          final isPhone =
                              hrContact != null &&
                              RegExp(r'^\+?[0-9]+$').hasMatch(
                                hrContact.replaceAll(RegExp(r'\s+'), ''),
                              );
                          if (isPhone) {
                            AppleToast.success(
                              context,
                              'Pesan Follow-Up Disalin',
                              subtitle: 'Siap dikirim ke $hrContact',
                              actionLabel: 'Kirim WA',
                              onAction: () => FollowupService.launchWhatsApp(
                                hrContact,
                                text,
                              ),
                            );
                          } else {
                            AppleToast.success(
                              context,
                              'Pesan Follow-Up Disalin',
                            );
                          }
                        },
                        icon: const Icon(CupertinoIcons.doc_on_doc, size: 16),
                        label: const Text('Salin Pesan'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // TAB 4: SALARY & OFFER EVALUATOR
  Widget _buildAppleSalaryEvaluatorTab(JobApplication currentJob) {
    final parsedSalary = SalaryEvaluatorService.parseSalaryAmount(
      currentJob.salaryOffered,
    );
    final evaluation = SalaryEvaluatorService.evaluateSalary(
      grossSalary: parsedSalary,
      city: _selectedCity,
      workType: currentJob.workType,
      needsKos: _needsKos,
    );

    final isFeasible = evaluation.estimatedNetSavings >= 0;
    final surf = AppTheme.getSurface(context);
    final bdr = AppTheme.getBorder(context);
    final txtPri = AppTheme.getTextPrimary(context);
    final txtSec = AppTheme.getTextSecondary(context);

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (parsedSalary == 0) ...[
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.systemOrange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppTheme.radiusCard),
                border: Border.all(
                  color: AppTheme.systemOrange.withValues(alpha: 0.3),
                ),
              ),
              child: const Row(
                children: [
                  Icon(
                    CupertinoIcons.info_circle_fill,
                    color: AppTheme.systemOrange,
                    size: 18,
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Gaji belum diisi atau berupa angka non-nominal (misal: "Negosiasi"). Edit data lamaran untuk hasil evaluasi yang akurat.',
                      style: TextStyle(
                        color: AppTheme.systemOrange,
                        fontSize: 12,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // City & Kos options
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: surf,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: bdr),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Lokasi Pekerjaan & Biaya Hidup',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: txtPri,
                  ),
                ),
                const SizedBox(height: 12),
                InkWell(
                  onTap: () {
                    showCupertinoModalPopup(
                      context: context,
                      builder: (_) => CupertinoActionSheet(
                        title: const Text('Pilih Kota Penempatan'),
                        actions: SalaryEvaluatorService.umrList.map((u) {
                          final isSelected = u.city == _selectedCity;
                          return CupertinoActionSheetAction(
                            onPressed: () {
                              setState(() => _selectedCity = u.city);
                              Navigator.pop(context);
                            },
                            child: Text(
                              '${u.city} (UMR: ${SalaryEvaluatorService.formatRupiah(u.umrAmount)})',
                              style: TextStyle(
                                color: AppTheme.systemBlue,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                fontSize: 14,
                              ),
                            ),
                          );
                        }).toList(),
                        cancelButton: CupertinoActionSheetAction(
                          isDefaultAction: true,
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Batal'),
                        ),
                      ),
                    );
                  },
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Kota Penempatan',
                      prefixIcon: Icon(
                        CupertinoIcons.building_2_fill,
                        size: 18,
                      ),
                      suffixIcon: Icon(CupertinoIcons.chevron_down, size: 14),
                    ),
                    child: Text(
                      '$_selectedCity (UMR: ${SalaryEvaluatorService.formatRupiah(SalaryEvaluatorService.umrList.firstWhere((u) => u.city == _selectedCity, orElse: () => SalaryEvaluatorService.umrList.first).umrAmount)})',
                      style: TextStyle(fontSize: 13, color: txtPri),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Perlu Sewa Kos / Kontrakan?',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: txtPri,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Menambahkan estimasi kos ke biaya hidup minimal',
                            style: TextStyle(fontSize: 11, color: txtSec),
                          ),
                        ],
                      ),
                    ),
                    CupertinoSwitch(
                      value: _needsKos,
                      activeTrackColor: AppTheme.systemBlue,
                      onChanged: (val) => setState(() => _needsKos = val),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Evaluation Result Card
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: surf,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isFeasible
                    ? AppTheme.systemGreen.withValues(alpha: 0.4)
                    : AppTheme.systemRed.withValues(alpha: 0.4),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      isFeasible
                          ? CupertinoIcons.checkmark_circle_fill
                          : CupertinoIcons.exclamationmark_circle_fill,
                      color: isFeasible
                          ? AppTheme.systemGreen
                          : AppTheme.systemRed,
                      size: 24,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        isFeasible
                            ? 'Tawaran Gaji Layak & Cukup untuk Biaya Hidup'
                            : 'Gaji Berpotensi Defisit / Di Bawah Biaya Hidup Minim',
                        style: TextStyle(
                          color: isFeasible
                              ? AppTheme.systemGreen
                              : AppTheme.systemRed,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                _evalRow(
                  'Estimasi Gaji Bersih',
                  SalaryEvaluatorService.formatRupiah(
                    evaluation.estimatedNetTakeHomePay,
                  ),
                ),
                _evalRow(
                  'UMR $_selectedCity',
                  SalaryEvaluatorService.formatRupiah(evaluation.umrAmount),
                ),
                _evalRow(
                  'Estimasi Biaya Hidup + Kos',
                  SalaryEvaluatorService.formatRupiah(
                    evaluation.estimatedOperationalCost,
                  ),
                ),
                const Divider(height: 20),
                _evalRow(
                  'Estimasi Tabungan / Bulan',
                  SalaryEvaluatorService.formatRupiah(
                    evaluation.estimatedNetSavings,
                  ),
                  isBold: true,
                  color: evaluation.estimatedNetSavings >= 0
                      ? AppTheme.systemGreen
                      : AppTheme.systemRed,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _evalRow(
    String label,
    String val, {
    bool isBold = false,
    Color? color,
  }) {
    final txtPri = AppTheme.getTextPrimary(context);
    final txtSec = AppTheme.getTextSecondary(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: isBold ? txtPri : txtSec,
                fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              val,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
                color: color ?? txtPri,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
