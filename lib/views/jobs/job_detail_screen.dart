import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/job_application.dart';
import '../../models/career_context.dart';
import '../../providers/job_provider.dart';
import '../../services/followup_service.dart';
import '../../services/next_action_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/apple_animations.dart';
import '../../widgets/app_dialog.dart';
import '../../widgets/apple_toast.dart';
import '../../widgets/app_toast.dart';
import '../../widgets/app_back_policy.dart';
import '../../widgets/bookmark_thumbs_up_mascot.dart';
import '../../widgets/company_logo_badge.dart';
import '../../widgets/company_logo_preview.dart';
import '../../widgets/delight_celebration.dart';
import '../../widgets/app_motion.dart';
import '../../widgets/app_layout_metrics.dart';
import 'add_edit_job_screen.dart';
import 'interview_stages_screen.dart';
import '../hub/career_hub_screen.dart';

/// Screen: Job Detail terinspirasi desain modern iOS (sesuai mockup referensi).
/// Fitur:
/// - Header gradien hangat (warm gold/amber)
/// - Baris navigasi: Back, Logo Perusahaan di tengah, Bookmark
/// - Pill badge posisi, nama perusahaan tebal, baris lokasi
/// - 3 Pill info kunci (Gaji, Tipe Kerja, Pengalaman/Status)
/// - Kartu kualifikasi & deskripsi ber-tab dengan format bullet points
/// - Animasi scroll fluida (interaktif saat scroll atas/bawah)
/// - Bagian bawah dengan opsi lengkap: Timeline, Kontak HR, Screenshot, Evaluasi UMR, Foto Perusahaan
/// - Tombol aksi utama sticky di bawah
class JobDetailScreen extends ConsumerStatefulWidget {
  final JobApplication job;
  final String? companyLogoHeroTag;

  const JobDetailScreen({
    super.key,
    required this.job,
    this.companyLogoHeroTag,
  });

  @override
  ConsumerState<JobDetailScreen> createState() => _JobDetailScreenState();
}

class _JobDetailScreenState extends ConsumerState<JobDetailScreen>
    with TickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  late AnimationController _bookmarkAnimController;
  late Animation<double> _bookmarkScaleAnim;
  late AnimationController _logoBounceController;
  late Animation<double> _logoBounceAnim;

  double _scrollOffset = 0.0;
  int? _expandedInfoBubbleIndex;

  final List<String> _statusOptions = [
    'Dikirim',
    'Tes / Psikotes',
    'Interview HR',
    'Interview User',
    'Offering',
    'Diterima',
    'Ditolak',
  ];

  @override
  void initState() {
    super.initState();
    _bookmarkAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
    );
    _bookmarkScaleAnim = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 1.0,
          end: 1.45,
        ).chain(CurveTween(curve: Curves.easeOutBack)),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 1.45,
          end: 1.0,
        ).chain(CurveTween(curve: Curves.elasticOut)),
        weight: 50,
      ),
    ]).animate(_bookmarkAnimController);

    _logoBounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 460),
    );
    _logoBounceAnim = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 1.0,
          end: 1.18,
        ).chain(CurveTween(curve: Curves.easeOutBack)),
        weight: 35,
      ),
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 1.18,
          end: 0.94,
        ).chain(CurveTween(curve: Curves.easeInOut)),
        weight: 30,
      ),
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 0.94,
          end: 1.0,
        ).chain(CurveTween(curve: Curves.elasticOut)),
        weight: 35,
      ),
    ]).animate(_logoBounceController);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final route = ModalRoute.of(context);
      if (route != null) {
        void listener(AnimationStatus status) {
          if (status == AnimationStatus.completed && mounted) {
            _logoBounceController.forward(from: 0.0);
            route.animation?.removeStatusListener(listener);
          }
        }

        if (route.animation?.isCompleted ?? false) {
          _logoBounceController.forward(from: 0.0);
        } else {
          route.animation?.addStatusListener(listener);
        }
      }
    });

    _scrollController.addListener(() {
      setState(() {
        _scrollOffset = _scrollController.offset.clamp(0.0, 300.0);
      });
    });
  }

  @override
  void dispose() {
    _logoBounceController.dispose();
    _bookmarkAnimController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _shareJob(JobApplication currentJob) {
    HapticFeedback.selectionClick();
    final salary = currentJob.salaryOffered != null
        ? '\nGaji: ${currentJob.salaryOffered}'
        : '';
    final loc = currentJob.location != null
        ? '\nLokasi: ${currentJob.location}'
        : '';
    final url = currentJob.jobUrl != null ? '\nLink: ${currentJob.jobUrl}' : '';
    final date =
        'Dilamar: ${currentJob.appliedDate.day}/${currentJob.appliedDate.month}/${currentJob.appliedDate.year}';
    final status = 'Status: ${currentJob.status} (${currentJob.workType})';

    final text =
        '*Lowongan Kerja - Ngelamar App*\n'
        '*${currentJob.companyName}*\n'
        'Posisi: ${currentJob.position}'
        '$loc'
        '$salary\n'
        '$status\n'
        '$date'
        '$url\n\n'
        'Dicatat via Ngelamar App';

    Share.share(
      text,
      subject: 'Lowongan: ${currentJob.position} di ${currentJob.companyName}',
    );
  }

  String _formatTimelineDate(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Agu',
      'Sep',
      'Okt',
      'Nov',
      'Des',
    ];
    final time = date.hour == 0 && date.minute == 0
        ? ''
        : ', ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    return '${date.day} ${months[date.month - 1]} ${date.year}$time';
  }

  void _openEditJob(JobApplication currentJob) async {
    HapticFeedback.selectionClick();
    final result = await Navigator.of(context).push<JobApplication>(
      AppMotion.editorRoute<JobApplication>(
        builder: (_) => AddEditJobScreen(
          jobToEdit: currentJob,
          actionHeroTag: 'edit_job_action_button_${currentJob.id}',
        ),
      ),
    );
    if (result != null && mounted) {
      if (result.status != currentJob.status) {
        DelightCelebration.show(
          context,
          message: 'Tahap baru: ${result.status}',
          accent: AppTheme.getStatusColor(result.status),
          icon: DelightCelebration.iconForStatus(result.status),
          preset: DelightCelebration.forStatus(result.status),
        );
      }
      AppleToast.success(context, 'Perubahan lamaran berhasil disimpan');
    }
  }

  void _deleteJob(JobApplication currentJob) async {
    HapticFeedback.heavyImpact();
    final confirm = await AppDialog.show<bool>(
      context: context,
      icon: Icons.delete_outline_rounded,
      iconColor: const Color(0xFFE53935),
      title: 'Hapus Lamaran?',
      content:
          'Apakah Anda yakin ingin menghapus data lamaran di ${currentJob.companyName} (${currentJob.position})?',
      secondaryLabel: 'Batal',
      primaryLabel: 'Hapus',
      isDestructive: true,
    );

    if (confirm == true && mounted) {
      await ref.read(jobProvider.notifier).deleteJob(currentJob.id);
      if (mounted) {
        Navigator.pop(context);
        AppToast.success(
          context,
          'Lamaran di ${currentJob.companyName} dihapus.',
        );
      }
    }
  }

  void _openScreenshotViewer(String path) {
    HapticFeedback.selectionClick();
    showDialog(
      context: context,
      builder: (ctx) => Dialog.fullscreen(
        backgroundColor: Colors.black,
        child: Stack(
          children: [
            Center(
              child: InteractiveViewer(
                minScale: 0.5,
                maxScale: 4.0,
                child: Image(
                  image: ResizeImage(FileImage(File(path)), width: 1440),
                  fit: BoxFit.contain,
                ),
              ),
            ),
            Positioned(
              top: 40,
              right: 20,
              child: GestureDetector(
                onTap: () => Navigator.pop(ctx),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: Colors.black54,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.close_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openOriginalUrl(String? url) async {
    if (url == null || url.trim().isEmpty) {
      AppleToast.info(context, 'Tautan lowongan tidak tersedia');
      return;
    }
    final cleanUrl = url.trim();
    try {
      final uri = Uri.parse(cleanUrl);
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched) {
        await Clipboard.setData(ClipboardData(text: cleanUrl));
        if (mounted) {
          AppleToast.info(context, 'Tautan lowongan disalin ke clipboard');
        }
      }
    } catch (_) {
      await Clipboard.setData(ClipboardData(text: cleanUrl));
      if (mounted) {
        AppleToast.info(context, 'Tautan lowongan disalin ke clipboard');
      }
    }
  }

  Future<void> _showNextActionEditor(
    BuildContext context,
    JobApplication currentJob,
  ) async {
    final isDark = AppTheme.isDark(context);
    final noteController = TextEditingController(
      text: currentJob.nextActionNote ?? '',
    );
    var actionType = currentJob.nextActionType ?? 'Tindak lanjut';
    var actionAt = currentJob.nextActionAt;
    const actionTypes = [
      'Tindak lanjut',
      'Kirim dokumen',
      'Siapkan tes',
      'Jadwal interview',
      'Ambil keputusan',
    ];

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) {
          final txtPri = AppTheme.getTextPrimary(context);
          final txtSec = AppTheme.getTextSecondary(context);
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.viewInsetsOf(context).bottom,
            ),
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E1E24) : Colors.white,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(30),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 42,
                      height: 5,
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white24
                            : const Color(0xFFD5CEBF),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Tindakan Berikutnya',
                    style: TextStyle(
                      color: txtPri,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Tentukan satu langkah konkret untuk lamaran ini.',
                    style: TextStyle(color: txtSec, fontSize: 12.5),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue: actionType,
                    decoration: const InputDecoration(
                      labelText: 'Jenis tindakan',
                      prefixIcon: Icon(Icons.task_alt_rounded),
                    ),
                    items: actionTypes
                        .map(
                          (type) =>
                              DropdownMenuItem(value: type, child: Text(type)),
                        )
                        .toList(),
                    onChanged: (value) =>
                        setSheetState(() => actionType = value ?? actionType),
                  ),
                  const SizedBox(height: 12),
                  FluidBounceButton(
                    onTap: () async {
                      final base = actionAt ?? DateTime.now();
                      final date = await showDatePicker(
                        context: context,
                        initialDate: base,
                        firstDate: DateTime.now().subtract(
                          const Duration(days: 1),
                        ),
                        lastDate: DateTime.now().add(const Duration(days: 730)),
                      );
                      if (date == null || !context.mounted) return;
                      final time = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay.fromDateTime(base),
                      );
                      if (time == null) return;
                      setSheetState(() {
                        actionAt = DateTime(
                          date.year,
                          date.month,
                          date.day,
                          time.hour,
                          time.minute,
                        );
                      });
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF282830)
                            : const Color(0xFFF8F5EF),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.schedule_rounded,
                            color: Color(0xFF5C44E4),
                            size: 19,
                          ),
                          const SizedBox(width: 9),
                          Expanded(
                            child: Text(
                              actionAt == null
                                  ? 'Pilih tanggal dan waktu'
                                  : _formatTimelineDate(actionAt!),
                              style: TextStyle(
                                color: actionAt == null ? txtSec : txtPri,
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: noteController,
                    maxLength: 240,
                    decoration: const InputDecoration(
                      labelText: 'Catatan singkat',
                      hintText: 'Contoh: Kirim portofolio terbaru',
                      prefixIcon: Icon(Icons.notes_rounded),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      if (currentJob.hasNextAction)
                        TextButton(
                          onPressed: () async {
                            Navigator.pop(sheetContext);
                            await ref
                                .read(jobProvider.notifier)
                                .setNextAction(
                                  jobId: currentJob.id,
                                  dueAt: null,
                                );
                            if (mounted) {
                              AppleToast.success(
                                this.context,
                                'Tindakan berikutnya dihapus',
                              );
                            }
                          },
                          child: const Text('Hapus'),
                        ),
                      const Spacer(),
                      FilledButton(
                        onPressed: actionAt == null
                            ? null
                            : () async {
                                final note = noteController.text.trim();
                                Navigator.pop(sheetContext);
                                await ref
                                    .read(jobProvider.notifier)
                                    .setNextAction(
                                      jobId: currentJob.id,
                                      dueAt: actionAt,
                                      type: actionType,
                                      note: note,
                                    );
                                if (mounted) {
                                  AppleToast.success(
                                    this.context,
                                    'Tindakan berikutnya diperbarui',
                                  );
                                }
                              },
                        child: const Text('Simpan Tindakan'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
    noteController.dispose();
  }

  void _showStatusPicker(BuildContext context, JobApplication currentJob) {
    HapticFeedback.selectionClick();
    final isDark = AppTheme.isDark(context);
    final sheetBg = isDark ? const Color(0xFF1E1E24) : const Color(0xFFFBF8F2);
    final txtPri = isDark ? Colors.white : const Color(0xFF121214);
    final txtSec = isDark ? const Color(0xFFA0A0A8) : const Color(0xFF707074);
    final pillUnselBg = isDark ? const Color(0xFF282830) : Colors.white;
    final pillBorder = isDark
        ? const Color(0xFF383842)
        : const Color(0xFFE5E0D5);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
        decoration: BoxDecoration(
          color: sheetBg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 5,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : const Color(0xFFD5CEBF),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Perbarui Status Lamaran',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: txtPri,
                letterSpacing: -0.4,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Pilih tahapan seleksi terbaru untuk ${currentJob.companyName}:',
              style: TextStyle(fontSize: 13, color: txtSec),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: _statusOptions.indexed.map((entry) {
                final index = entry.$1;
                final status = entry.$2;
                final isSelected = status == currentJob.status;
                final statusColor = AppTheme.getStatusColor(status);

                return StaggeredReveal(
                  index: index,
                  child: GestureDetector(
                    onTap: () async {
                      Navigator.pop(ctx);
                      await ref
                          .read(jobProvider.notifier)
                          .updateStatus(currentJob.id, status);
                      if (!context.mounted) return;
                      DelightCelebration.show(
                        context,
                        message: 'Tahap baru: $status',
                        accent: statusColor,
                        icon: DelightCelebration.iconForStatus(status),
                        preset: DelightCelebration.forStatus(status),
                      );
                      AppleToast.success(
                        context,
                        'Status berhasil diubah ke $status',
                      );
                      final updatedJob = ref
                          .read(jobProvider)
                          .jobs
                          .where((job) => job.id == currentJob.id)
                          .firstOrNull;
                      final suggestion = updatedJob == null
                          ? null
                          : NextActionService.suggest(updatedJob);
                      if (suggestion != null) {
                        final reduceMotion =
                            MediaQuery.maybeOf(context)?.disableAnimations ??
                            false;
                        if (!reduceMotion) {
                          await Future<void>.delayed(
                            const Duration(milliseconds: 850),
                          );
                        }
                        if (context.mounted) {
                          _showNextActionSuggestion(
                            context,
                            updatedJob!,
                            suggestion,
                          );
                        }
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected ? statusColor : pillUnselBg,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected ? statusColor : pillBorder,
                          width: 1.3,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(
                              alpha: isSelected ? 0.15 : 0.03,
                            ),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: isSelected ? Colors.white : statusColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            status,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: isSelected ? Colors.white : txtPri,
                            ),
                          ),
                          if (isSelected) ...[
                            const SizedBox(width: 6),
                            const Icon(
                              Icons.check_rounded,
                              size: 14,
                              color: Colors.white,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  void _showNextActionSuggestion(
    BuildContext context,
    JobApplication job,
    NextActionSuggestion suggestion,
  ) {
    final isDark = AppTheme.isDark(context);
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => Container(
        padding: EdgeInsets.fromLTRB(
          22,
          14,
          22,
          MediaQuery.paddingOf(sheetContext).bottom + 22,
        ),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E24) : const Color(0xFFFBF8F2),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 42,
                height: 5,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : const Color(0xFFD5CEBF),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(
                  Icons.auto_awesome_rounded,
                  color: Color(0xFF6750E8),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Langkah berikutnya?',
                    style: TextStyle(
                      color: AppTheme.getTextPrimary(sheetContext),
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              suggestion.note,
              style: TextStyle(
                color: AppTheme.getTextSecondary(sheetContext),
                fontSize: 13,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF292632)
                    : const Color(0xFFEDE8FF),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Text(
                '${suggestion.type} - ${_formatTimelineDate(suggestion.dueAt)}',
                style: TextStyle(
                  color: AppTheme.getTextPrimary(sheetContext),
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(sheetContext),
                    child: const Text('Nanti saja'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: FilledButton(
                    onPressed: () async {
                      await ref
                          .read(jobProvider.notifier)
                          .setNextAction(
                            jobId: job.id,
                            dueAt: suggestion.dueAt,
                            type: suggestion.type,
                            note: suggestion.note,
                          );
                      if (!sheetContext.mounted) return;
                      Navigator.pop(sheetContext);
                      AppleToast.success(
                        context,
                        'Tindakan ditambahkan ke Kalender',
                      );
                    },
                    child: const Text('Tambahkan'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showFollowupSheet(BuildContext context, JobApplication currentJob) {
    HapticFeedback.selectionClick();
    final isDark = AppTheme.isDark(context);
    final sheetBg = isDark ? const Color(0xFF1E1E24) : const Color(0xFFFBF8F2);
    final txtPri = isDark ? Colors.white : const Color(0xFF121214);
    final txtSec = isDark ? const Color(0xFFA0A0A8) : const Color(0xFF707074);
    final cardBg = isDark ? const Color(0xFF282830) : Colors.white;
    final cardBorder = isDark
        ? const Color(0xFF383842)
        : const Color(0xFFE5E0D5);

    final templates = FollowupService.getTemplatesFor(
      position: currentJob.position,
      company: currentJob.companyName,
      status: currentJob.status,
    );

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.78,
        minChildSize: 0.45,
        maxChildSize: 0.94,
        builder: (_, scrollController) => Container(
          decoration: BoxDecoration(
            color: sheetBg,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 14, bottom: 8),
                child: Center(
                  child: Container(
                    width: 44,
                    height: 5,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white24 : const Color(0xFFD5CEBF),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 6, 22, 14),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Follow Up HR',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              color: txtPri,
                              letterSpacing: -0.4,
                            ),
                          ),
                          Text(
                            'Templat pesan profesional untuk ${currentJob.companyName}',
                            style: TextStyle(fontSize: 12.5, color: txtSec),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close_rounded, size: 22, color: txtPri),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
              ),
              Divider(
                height: 1,
                color: isDark
                    ? const Color(0xFF383842)
                    : const Color(0xFFE6E0D5),
              ),
              Expanded(
                child: ListView.separated(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
                  itemCount: templates.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 14),
                  itemBuilder: (context, idx) {
                    final tpl = templates[idx];
                    return Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: cardBorder),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                tpl.title,
                                style: TextStyle(
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w800,
                                  color: txtPri,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: tpl.type == FollowupType.whatsapp
                                      ? (isDark
                                            ? const Color(0xFF132E1D)
                                            : const Color(0xFFE8F9EE))
                                      : (isDark
                                            ? const Color(0xFF261E3E)
                                            : const Color(0xFFF3EEFF)),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  tpl.type == FollowupType.whatsapp
                                      ? 'WhatsApp'
                                      : 'Email',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: tpl.type == FollowupType.whatsapp
                                        ? const Color(0xFF1E8E3E)
                                        : const Color(0xFF5C44E4),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? const Color(0xFF29292F)
                                  : const Color(0xFFF9F7F2),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              tpl.body,
                              style: TextStyle(
                                fontSize: 12.5,
                                height: 1.45,
                                color: isDark
                                    ? Colors.white70
                                    : const Color(0xFF333336),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () {
                                    Clipboard.setData(
                                      ClipboardData(text: tpl.body),
                                    );
                                    AppleToast.success(
                                      context,
                                      'Pesan disalin ke clipboard',
                                    );
                                  },
                                  icon: const Icon(
                                    Icons.copy_rounded,
                                    size: 15,
                                  ),
                                  label: const Text('Salin'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: isDark
                                        ? Colors.white
                                        : const Color(0xFF19191B),
                                    side: BorderSide(
                                      color: isDark
                                          ? const Color(0xFF484852)
                                          : const Color(0xFFDCD8CE),
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 10,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                flex: 2,
                                child: ElevatedButton.icon(
                                  onPressed: () async {
                                    final contact = currentJob.hrContact ?? '';
                                    try {
                                      if (tpl.type == FollowupType.whatsapp) {
                                        final cleanNum = contact.replaceAll(
                                          RegExp(r'[^0-9+]'),
                                          '',
                                        );
                                        final encoded = Uri.encodeComponent(
                                          tpl.body,
                                        );
                                        final uri = cleanNum.isNotEmpty
                                            ? Uri.parse(
                                                'https://wa.me/$cleanNum?text=$encoded',
                                              )
                                            : Uri.parse(
                                                'https://wa.me/?text=$encoded',
                                              );
                                        final launched = await launchUrl(
                                          uri,
                                          mode: LaunchMode.externalApplication,
                                        );
                                        if (!launched) throw Exception('Gagal');
                                      } else {
                                        final encodedSubject =
                                            Uri.encodeComponent(tpl.title);
                                        final encodedBody = Uri.encodeComponent(
                                          tpl.body,
                                        );
                                        final uri = Uri.parse(
                                          'mailto:$contact?subject=$encodedSubject&body=$encodedBody',
                                        );
                                        final launched = await launchUrl(
                                          uri,
                                          mode: LaunchMode.externalApplication,
                                        );
                                        if (!launched) throw Exception('Gagal');
                                      }
                                    } catch (_) {
                                      await Clipboard.setData(
                                        ClipboardData(text: tpl.body),
                                      );
                                      if (context.mounted) {
                                        AppleToast.info(
                                          context,
                                          'Pesan disalin ke clipboard',
                                        );
                                      }
                                    }
                                  },
                                  icon: Icon(
                                    tpl.type == FollowupType.whatsapp
                                        ? Icons.chat_rounded
                                        : Icons.send_rounded,
                                    size: 15,
                                  ),
                                  label: Text(
                                    tpl.type == FollowupType.whatsapp
                                        ? 'Kirim ke WhatsApp'
                                        : 'Buka Email',
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor:
                                        tpl.type == FollowupType.whatsapp
                                        ? const Color(0xFF25D366)
                                        : const Color(0xFF5C44E4),
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 10,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showFullDetailsSheet(BuildContext context, JobApplication currentJob) {
    HapticFeedback.selectionClick();
    final isDark = AppTheme.isDark(context);
    final sheetBg = isDark ? const Color(0xFF1E1E24) : const Color(0xFFFBF8F2);
    final cardBg = isDark ? const Color(0xFF282830) : Colors.white;
    final cardBorder = isDark
        ? const Color(0xFF383842)
        : const Color(0xFFE5E0D5);
    final dividerColor = isDark
        ? const Color(0xFF383842)
        : const Color(0xFFF0ECE3);
    final txtPri = isDark ? Colors.white : const Color(0xFF121214);
    final bodyText = isDark ? const Color(0xFFD1D1D6) : const Color(0xFF333336);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (_, scrollController) => Container(
          decoration: BoxDecoration(
            color: sheetBg,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 14, bottom: 8),
                child: Center(
                  child: Container(
                    width: 44,
                    height: 5,
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF383842)
                          : const Color(0xFFD5CEBF),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 6, 22, 14),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            currentJob.companyName,
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                              color: txtPri,
                              letterSpacing: -0.6,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            currentJob.position,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF5C44E4),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close_rounded, size: 22, color: txtPri),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
              ),
              Divider(
                height: 1,
                color: isDark
                    ? const Color(0xFF383842)
                    : const Color(0xFFE6E0D5),
              ),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(22, 18, 22, 40),
                  children: [
                    Row(
                      children: [
                        _buildFactChip(
                          eyebrow: 'Status',
                          value: currentJob.status,
                          color: AppTheme.cardPurple,
                          icon: Icons.flag_rounded,
                        ),
                        const SizedBox(width: 8),
                        _buildFactChip(
                          eyebrow: 'Gaji',
                          value: currentJob.salaryOffered ?? 'Belum diisi',
                          color: AppTheme.cardYellow,
                          icon: Icons.payments_rounded,
                        ),
                        const SizedBox(width: 8),
                        _buildFactChip(
                          eyebrow: 'Mode',
                          value: currentJob.workType,
                          color: AppTheme.cardGreen,
                          icon: Icons.home_work_rounded,
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(color: cardBorder),
                      ),
                      child: Column(
                        children: [
                          _buildDetailRow(
                            icon: Icons.location_on_outlined,
                            label: 'Lokasi',
                            value:
                                currentJob.location?.trim().isNotEmpty == true
                                ? currentJob.location!.trim()
                                : 'Belum dicantumkan',
                            isDark: isDark,
                          ),
                          Divider(height: 18, color: dividerColor),
                          _buildDetailRow(
                            icon: Icons.event_available_rounded,
                            label: 'Melamar',
                            value:
                                '${currentJob.appliedDate.day}/${currentJob.appliedDate.month}/${currentJob.appliedDate.year}',
                            isDark: isDark,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: cardBorder),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.contact_phone_rounded,
                                size: 18,
                                color: Color(0xFF5C44E4),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Kontak HRD / Rekruter',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  color: txtPri,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            currentJob.hrContact != null &&
                                    currentJob.hrContact!.isNotEmpty
                                ? currentJob.hrContact!
                                : 'Belum ada kontak HR yang disimpan.',
                            style: TextStyle(fontSize: 13, color: bodyText),
                          ),
                          if (currentJob.hrContact != null &&
                              currentJob.hrContact!.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                ElevatedButton.icon(
                                  onPressed: () async {
                                    final contact = currentJob.hrContact!;
                                    try {
                                      if (contact.contains('@')) {
                                        final uri = Uri.parse(
                                          'mailto:$contact',
                                        );
                                        final launched = await launchUrl(
                                          uri,
                                          mode: LaunchMode.externalApplication,
                                        );
                                        if (!launched) throw Exception('Gagal');
                                      } else {
                                        final cleanNum = contact.replaceAll(
                                          RegExp(r'[^0-9+]'),
                                          '',
                                        );
                                        final uri = Uri.parse(
                                          'https://wa.me/$cleanNum',
                                        );
                                        final launched = await launchUrl(
                                          uri,
                                          mode: LaunchMode.externalApplication,
                                        );
                                        if (!launched) throw Exception('Gagal');
                                      }
                                    } catch (_) {
                                      await Clipboard.setData(
                                        ClipboardData(text: contact),
                                      );
                                      if (context.mounted) {
                                        AppleToast.info(
                                          context,
                                          'Kontak HR disalin ke clipboard',
                                        );
                                      }
                                    }
                                  },
                                  icon: Icon(
                                    currentJob.hrContact!.contains('@')
                                        ? Icons.email_rounded
                                        : Icons.chat_rounded,
                                    size: 16,
                                  ),
                                  label: Text(
                                    currentJob.hrContact!.contains('@')
                                        ? 'Kirim Email'
                                        : 'Hubungi via WhatsApp',
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor:
                                        currentJob.hrContact!.contains('@')
                                        ? const Color(0xFF5C44E4)
                                        : const Color(0xFF25D366),
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 8,
                                    ),
                                  ),
                                ),
                                OutlinedButton.icon(
                                  onPressed: () {
                                    Clipboard.setData(
                                      ClipboardData(
                                        text: currentJob.hrContact!,
                                      ),
                                    );
                                    AppleToast.success(
                                      context,
                                      'Kontak HR disalin',
                                    );
                                  },
                                  icon: const Icon(
                                    Icons.copy_rounded,
                                    size: 14,
                                  ),
                                  label: const Text('Salin Kontak'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: txtPri,
                                    side: BorderSide(color: cardBorder),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (currentJob.screenshotPath != null &&
                        currentJob.screenshotPath!.isNotEmpty) ...[
                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: cardBg,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: cardBorder),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.photo_library_rounded,
                                      size: 18,
                                      color: Color(0xFF5C44E4),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Screenshot Bukti Loker',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w800,
                                        color: txtPri,
                                      ),
                                    ),
                                  ],
                                ),
                                TextButton(
                                  onPressed: () => _openScreenshotViewer(
                                    currentJob.screenshotPath!,
                                  ),
                                  child: const Text(
                                    'Perbesar',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            GestureDetector(
                              onTap: () => _openScreenshotViewer(
                                currentJob.screenshotPath!,
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(14),
                                child:
                                    kIsWeb ||
                                        currentJob.screenshotPath!.startsWith(
                                          'http',
                                        ) ||
                                        currentJob.screenshotPath!.startsWith(
                                          'blob:',
                                        )
                                    ? Image.network(
                                        currentJob.screenshotPath!,
                                        height: 180,
                                        width: double.infinity,
                                        fit: BoxFit.cover,
                                        errorBuilder:
                                            (context, error, stackTrace) =>
                                                const SizedBox.shrink(),
                                      )
                                    : Image.file(
                                        File(currentJob.screenshotPath!),
                                        height: 180,
                                        width: double.infinity,
                                        fit: BoxFit.cover,
                                        errorBuilder:
                                            (context, error, stackTrace) =>
                                                const SizedBox.shrink(),
                                      ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    if (currentJob.notes != null &&
                        currentJob.notes!.isNotEmpty) ...[
                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: cardBg,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: cardBorder),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.note_alt_rounded,
                                  size: 18,
                                  color: Color(0xFF5C44E4),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Catatan Lamaran',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                    color: txtPri,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              currentJob.notes!,
                              style: TextStyle(
                                fontSize: 13,
                                color: bodyText,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: cardBorder),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.checklist_rounded,
                                size: 18,
                                color: Color(0xFF5C44E4),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Kualifikasi & Deskripsi',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  color: txtPri,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            currentJob.jobDescription.isNotEmpty
                                ? currentJob.jobDescription
                                : 'Tidak ada deskripsi yang dicatat.',
                            style: TextStyle(
                              fontSize: 13,
                              color: bodyText,
                              height: 1.4,
                            ),
                          ),
                        ],
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

  Widget _buildFactChip({
    required String eyebrow,
    required String value,
    required Color color,
    required IconData icon,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 12, 10, 12),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 18, color: const Color(0xFF121214)),
            const SizedBox(height: 10),
            Text(
              eyebrow,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.2,
                color: const Color(0xFF121214).withValues(alpha: 0.62),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w900,
                color: Color(0xFF121214),
                height: 1.15,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
    Color? badgeColor,
    bool isDark = false,
  }) {
    final txtPri = isDark ? Colors.white : const Color(0xFF121214);
    final txtSec = isDark ? const Color(0xFFA0A0A8) : const Color(0xFF707074);

    return Row(
      children: [
        Icon(icon, size: 18, color: txtSec),
        const SizedBox(width: 12),
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: txtSec,
            fontWeight: FontWeight.w500,
          ),
        ),
        const Spacer(),
        if (badgeColor != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              color: badgeColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(
              value,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w800,
                color: badgeColor,
              ),
            ),
          )
        else
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: txtPri,
            ),
          ),
      ],
    );
  }

  List<Color> _getStatusGradients(String status, {bool isDark = false}) {
    if (isDark) {
      switch (status) {
        case 'Diterima':
          return const [
            Color(0xFF064E3B),
            Color(0xFF063A2D),
            Color(0xFF04241C),
            Color(0xFF121214),
          ];
        case 'Offering':
          return const [
            Color(0xFF500724),
            Color(0xFF380619),
            Color(0xFF230410),
            Color(0xFF121214),
          ];
        case 'Interview User':
        case 'Interview':
          return const [
            Color(0xFF2E1065),
            Color(0xFF220C4C),
            Color(0xFF160833),
            Color(0xFF121214),
          ];
        case 'Interview HR':
        case 'HR Screening':
          return const [
            Color(0xFF1E1B4B),
            Color(0xFF17153B),
            Color(0xFF100E2B),
            Color(0xFF121214),
          ];
        case 'Tes / Psikotes':
          return const [
            Color(0xFF451A03),
            Color(0xFF331402),
            Color(0xFF210D01),
            Color(0xFF121214),
          ];
        case 'Ditolak':
          return const [
            Color(0xFF450A0A),
            Color(0xFF330707),
            Color(0xFF210505),
            Color(0xFF121214),
          ];
        case 'Dikirim':
        case 'Tersedia':
        default:
          return const [
            Color(0xFF1E293B),
            Color(0xFF192231),
            Color(0xFF141A25),
            Color(0xFF121214),
          ];
      }
    }
    switch (status) {
      case 'Diterima':
        return const [
          Color(0xFF86EFAC),
          Color(0xFFBBF7D0),
          Color(0xFFF0FDF4),
          Color(0xFFFBF8F2),
        ];
      case 'Offering':
        return const [
          Color(0xFFF472B6),
          Color(0xFFFBCFE8),
          Color(0xFFFDF2F8),
          Color(0xFFFBF8F2),
        ];
      case 'Interview User':
      case 'Interview':
        return const [
          Color(0xFFA78BFA),
          Color(0xFFDDD6FE),
          Color(0xFFF5F3FF),
          Color(0xFFFBF8F2),
        ];
      case 'Interview HR':
      case 'HR Screening':
        return const [
          Color(0xFF818CF8),
          Color(0xFFC7D2FE),
          Color(0xFFEEF2FF),
          Color(0xFFFBF8F2),
        ];
      case 'Tes / Psikotes':
        return const [
          Color(0xFFFDE047),
          Color(0xFFFEF08A),
          Color(0xFFFEFCE8),
          Color(0xFFFBF8F2),
        ];
      case 'Ditolak':
        return const [
          Color(0xFFFCA5A5),
          Color(0xFFFECACA),
          Color(0xFFFEF2F2),
          Color(0xFFFBF8F2),
        ];
      case 'Dikirim':
      case 'Tersedia':
      default:
        return const [
          Color(0xFFCBD5E1),
          Color(0xFFE2E8F0),
          Color(0xFFF1F5F9),
          Color(0xFFFBF8F2),
        ];
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppTheme.isDark(context);
    final jobs = ref.watch(jobProvider).jobs;
    final currentJob = jobs.firstWhere(
      (j) => j.id == widget.job.id,
      orElse: () => widget.job,
    );

    final salaryText =
        currentJob.salaryOffered != null && currentJob.salaryOffered!.isNotEmpty
        ? currentJob.salaryOffered!
        : 'Gaji belum dicantumkan';

    final locationText =
        currentJob.location != null && currentJob.location!.isNotEmpty
        ? currentJob.location!
        : 'Lokasi belum dicantumkan';
    final hasLocation =
        currentJob.location != null && currentJob.location!.trim().isNotEmpty;

    final experienceText = currentJob.status;
    // Keep the softer light-mode palette that lets the content stay legible.
    // The gradient itself extends farther down the page below.
    final statusBackground =
        _getStatusGradients(currentJob.status, isDark: isDark)
            .map((color) {
              if (isDark) return color;
              return Color.lerp(color, AppTheme.warmBackground, 0.42)!;
            })
            .toList(growable: false);

    // Scroll animation factor (0.0 to 1.0)
    final scrollRatio = (_scrollOffset / 160.0).clamp(0.0, 1.0);
    final logoSize = 64.0 - (scrollRatio * 18.0); // Shrinks from 64 to 46

    return AppBackScope(
      child: Scaffold(
        backgroundColor: isDark
            ? const Color(0xFF121214)
            : AppTheme.warmBackground,
        body: Stack(
          children: [
            // ── DYNAMIC STATUS-BASED GRADIENT BACKGROUND ──
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: statusBackground,
                    stops: const [0.0, 0.52, 0.88, 1.0],
                  ),
                ),
              ),
            ),

            // ── MAIN SCROLLABLE CONTENT ──
            SafeArea(
              bottom: false,
              child: CustomScrollView(
                controller: _scrollController,
                physics: const BouncingScrollPhysics(),
                slivers: [
                  // TOP NAV APP BAR (Back, Logo, Bookmark)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(
                        20,
                        AppLayoutMetrics.headerTopInsideSafeArea(
                          context,
                          extra: 10,
                        ),
                        20,
                        14,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Left Circular Back Button
                          FluidBounceButton(
                            semanticLabel: 'Kembali',
                            hapticEnabled: false,
                            onTap: () {
                              HapticFeedback.selectionClick();
                              Navigator.pop(context);
                            },
                            child: Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: isDark
                                    ? const Color(0xFF242428)
                                    : Colors.white,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isDark
                                      ? const Color(0xFF383842)
                                      : const Color(0xFFE5E0D5),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(
                                      alpha: isDark ? 0.2 : 0.06,
                                    ),
                                    blurRadius: 10,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: Center(
                                child: Icon(
                                  CupertinoIcons.chevron_back,
                                  size: 20,
                                  color: isDark
                                      ? Colors.white
                                      : const Color(0xFF121214),
                                ),
                              ),
                            ),
                          ),

                          // Center Company Logo Badge with landing bounce & scroll shrink animation
                          Transform.translate(
                            offset: const Offset(0, 3),
                            child: ScaleTransition(
                              scale: _logoBounceAnim,
                              child: GestureDetector(
                                onTap: () {
                                  final tag =
                                      widget.companyLogoHeroTag ??
                                      'company_logo_${currentJob.id}';
                                  CompanyLogoPreviewPage.open(
                                    context,
                                    companyName: currentJob.companyName,
                                    customImagePath: currentJob.companyLogoPath,
                                    heroTag: tag,
                                  );
                                },
                                child: Hero(
                                  tag:
                                      widget.companyLogoHeroTag ??
                                      'company_logo_${currentJob.id}',
                                  createRectTween: companyLogoRectTween,
                                  flightShuttleBuilder:
                                      companyLogoFlightShuttle,
                                  placeholderBuilder:
                                      companyLogoHeroPlaceholder,
                                  child: CompanyLogoBadge(
                                    companyName: currentJob.companyName,
                                    size: logoSize,
                                    customImagePath: currentJob.companyLogoPath,
                                  ),
                                ),
                              ),
                            ),
                          ),

                          // Circular Bookmark Button with Animated Scale & Pop Feedback
                          FluidBounceButton(
                            semanticLabel: currentJob.isFavorite
                                ? 'Hapus dari bookmark'
                                : 'Simpan ke bookmark',
                            selected: currentJob.isFavorite,
                            hapticEnabled: false,
                            onTap: () {
                              HapticFeedback.heavyImpact();
                              _bookmarkAnimController.forward(from: 0.0);
                              ref
                                  .read(jobProvider.notifier)
                                  .toggleFavorite(currentJob.id);
                              if (!currentJob.isFavorite) {
                                // The mascot jumps up from the bottom edge,
                                // shows a thumbs-up, then lands back below.
                                BookmarkThumbsUpMascot.show(context);
                              }
                              AppleToast.success(
                                context,
                                currentJob.isFavorite
                                    ? 'Dihapus dari Bookmark'
                                    : 'Disimpan ke Bookmark',
                                subtitle: currentJob.companyName,
                              );
                            },
                            child: ScaleTransition(
                              scale: _bookmarkScaleAnim,
                              child: Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: currentJob.isFavorite
                                      ? (isDark
                                            ? const Color(0xFF5C44E4)
                                            : const Color(0xFF19191B))
                                      : (isDark
                                            ? const Color(0xFF242428)
                                            : Colors.white),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: currentJob.isFavorite
                                        ? (isDark
                                              ? const Color(0xFF5C44E4)
                                              : const Color(0xFF19191B))
                                        : (isDark
                                              ? const Color(0xFF383842)
                                              : const Color(0xFFE5E0D5)),
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: currentJob.isFavorite
                                          ? const Color(
                                              0xFF5C44E4,
                                            ).withValues(alpha: 0.35)
                                          : Colors.black.withValues(
                                              alpha: isDark ? 0.2 : 0.06,
                                            ),
                                      blurRadius: 12,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Center(
                                  child: Icon(
                                    currentJob.isFavorite
                                        ? CupertinoIcons.bookmark_fill
                                        : CupertinoIcons.bookmark,
                                    size: 20,
                                    color: currentJob.isFavorite
                                        ? const Color(0xFFFFD54F)
                                        : (isDark
                                              ? Colors.white
                                              : const Color(0xFF121214)),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // HERO IDENTITY SECTION (Company Name, Role Pill, Location)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        children: [
                          const SizedBox(height: 6),
                          // Company Name
                          Text(
                            currentJob.companyName,
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w900,
                              color: isDark
                                  ? Colors.white
                                  : const Color(0xFF121214),
                              letterSpacing: -0.8,
                            ),
                            textAlign: TextAlign.center,
                          ),

                          if (currentJob.isSampleData) ...[
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 3.5,
                              ),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? const Color(0xFF382A68)
                                    : const Color(0xFFEDE9FE),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: isDark
                                      ? const Color(0xFF6D52C7)
                                      : const Color(0xFFC4B5FD),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.lightbulb_outline_rounded,
                                    size: 13,
                                    color: isDark
                                        ? const Color(0xFFD8B4FE)
                                        : const Color(0xFF6B21A8),
                                  ),
                                  const SizedBox(width: 5),
                                  Text(
                                    'Data Contoh',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                      color: isDark
                                          ? const Color(0xFFD8B4FE)
                                          : const Color(0xFF6B21A8),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],

                          const SizedBox(height: 10),

                          // Role / Position Pill (Clean NO OUTLINE)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? const Color(0xFF242428)
                                  : Colors.white.withValues(alpha: 0.85),
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color: isDark
                                    ? const Color(0xFF383842)
                                    : const Color(0xFFE5E0D5),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(
                                    alpha: isDark ? 0.2 : 0.04,
                                  ),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Text(
                              currentJob.position,
                              style: TextStyle(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w800,
                                color: isDark
                                    ? Colors.white
                                    : const Color(0xFF121214),
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),

                          const SizedBox(height: 10),

                          // Location Row (Clickable to open in Google Maps / Apple Maps)
                          Semantics(
                            button: hasLocation,
                            enabled: hasLocation,
                            label: hasLocation
                                ? 'Buka lokasi $locationText di peta'
                                : 'Lokasi belum dicantumkan',
                            child: GestureDetector(
                              onTap: !hasLocation
                                  ? null
                                  : () async {
                                      HapticFeedback.selectionClick();
                                      final loc = currentJob.location!.trim();
                                      final Uri mapUri;
                                      if (loc.startsWith('http://') ||
                                          loc.startsWith('https://')) {
                                        mapUri = Uri.parse(loc);
                                      } else {
                                        mapUri = Uri.parse(
                                          'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(loc)}',
                                        );
                                      }
                                      try {
                                        await launchUrl(
                                          mapUri,
                                          mode: LaunchMode.externalApplication,
                                        );
                                      } catch (_) {
                                        if (context.mounted) {
                                          AppleToast.info(
                                            context,
                                            'Tidak dapat membuka aplikasi peta',
                                          );
                                        }
                                      }
                                    },
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.location_on_rounded,
                                    size: 15,
                                    color: hasLocation
                                        ? Color(0xFFE53935)
                                        : Color(0xFF8E8E93),
                                  ),
                                  const SizedBox(width: 5),
                                  Flexible(
                                    child: Text(
                                      locationText,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: isDark
                                            ? Colors.white70
                                            : const Color(0xFF454549),
                                      ),
                                    ),
                                  ),
                                  if (hasLocation) ...[
                                    const SizedBox(width: 4),
                                    Icon(
                                      Icons.open_in_new_rounded,
                                      size: 12,
                                      color: isDark
                                          ? Colors.white54
                                          : const Color(0xFF77777A),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(height: 18),

                          LayoutBuilder(
                            builder: (context, constraints) {
                              final salaryBubble = _buildInfoBubble(
                                icon: const Icon(
                                  Icons.payments_rounded,
                                  size: 17,
                                  color: Color(0xFFB45309),
                                ),
                                label: salaryText,
                                index: 0,
                              );
                              final workTypeBubble = _buildInfoBubble(
                                icon: const Icon(
                                  Icons.home_work_rounded,
                                  size: 17,
                                  color: Color(0xFF5C44E4),
                                ),
                                label: currentJob.workType,
                                index: 1,
                              );
                              final statusBubble = StatusPulse(
                                status: currentJob.status,
                                child: _buildInfoBubble(
                                  icon: const Icon(
                                    Icons.work_outline_rounded,
                                    size: 17,
                                    color: Color(0xFF1E8E3E),
                                  ),
                                  label: experienceText,
                                  index: 2,
                                ),
                              );

                              if (constraints.maxWidth < 340) {
                                return Column(
                                  children: [
                                    SizedBox(
                                      width: double.infinity,
                                      child: salaryBubble,
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Expanded(child: workTypeBubble),
                                        const SizedBox(width: 8),
                                        Expanded(child: statusBubble),
                                      ],
                                    ),
                                  ],
                                );
                              }

                              return Row(
                                children: [
                                  Expanded(flex: 2, child: salaryBubble),
                                  const SizedBox(width: 8),
                                  Expanded(child: workTypeBubble),
                                  const SizedBox(width: 8),
                                  Expanded(child: statusBubble),
                                ],
                              );
                            },
                          ),

                          AnimatedSize(
                            duration: const Duration(milliseconds: 220),
                            curve: Curves.easeOutCubic,
                            alignment: Alignment.topCenter,
                            child: _expandedInfoBubbleIndex == null
                                ? const SizedBox.shrink()
                                : Padding(
                                    padding: const EdgeInsets.only(top: 10),
                                    child: _buildExpandedBubbleDetail(
                                      currentJob,
                                      _expandedInfoBubbleIndex!,
                                      isDark,
                                    ),
                                  ),
                          ),

                          const SizedBox(height: 18),
                          Divider(
                            height: 1,
                            color: Colors.black.withValues(alpha: 0.08),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // ── MINIMUM QUALIFICATION: matches the reference card and
                  // displays the user's original job description verbatim. ──
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(28, 16, 28, 10),
                      child: _buildReferenceQualificationCard(
                        currentJob,
                        isDark,
                      ),
                    ),
                  ),

                  // ── BAGIAN BAWAH: OPSI MELIHAT DATA DENGAN LENGKAP ──
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(
                        20,
                        14,
                        20,
                        AppLayoutMetrics.contentBottomClearance(context),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Padding(
                            padding: EdgeInsets.only(left: 4, bottom: 10),
                            child: Text(
                              'DATA & RIWAYAT LENGKAP',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: Colors.grey,
                                letterSpacing: 0.6,
                              ),
                            ),
                          ),

                          // Timeline is the single entry point for stages and
                          // interview guidance, avoiding duplicate destinations.
                          _buildOptionCard(
                            icon: Icons.timeline_rounded,
                            iconColor: const Color(0xFF5C44E4),
                            title: 'Timeline',
                            subtitle:
                                '${currentJob.status} • ${currentJob.recruitmentEvents.length} aktivitas',
                            onTap: () {
                              HapticFeedback.selectionClick();
                              Navigator.push(
                                context,
                                CupertinoPageRoute(
                                  builder: (_) =>
                                      InterviewStagesScreen(job: currentJob),
                                ),
                              );
                            },
                          ),

                          const SizedBox(height: 10),

                          _buildOptionCard(
                            icon: Icons.task_alt_rounded,
                            iconColor: const Color(0xFF22A06B),
                            title: 'Tindakan Berikutnya',
                            subtitle: currentJob.hasNextAction
                                ? '${currentJob.nextActionType} • ${_formatTimelineDate(currentJob.nextActionAt!)}'
                                : 'Atur agenda tindak lanjut',
                            onTap: () =>
                                _showNextActionEditor(context, currentJob),
                          ),

                          const SizedBox(height: 10),

                          _buildOptionCard(
                            icon: Icons.school_rounded,
                            iconColor: const Color(0xFF17824F),
                            title: 'Persiapan untuk Posisi Ini',
                            subtitle: 'Berkas, interview, gaji, dan pesan HR',
                            onTap: () => Navigator.of(context).push(
                              AppMotion.hubRoute(
                                builder: (_) => CareerHubScreen(
                                  initialSection: 1,
                                  careerContext: CareerContext.fromJob(
                                    currentJob,
                                  ),
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 10),

                          // Kontak HR & Template Follow-Up
                          _buildOptionCard(
                            icon: Icons.send_rounded,
                            iconColor: const Color(0xFF25D366),
                            title: 'Kontak HR',
                            subtitle:
                                currentJob.hrContact != null &&
                                    currentJob.hrContact!.isNotEmpty
                                ? currentJob.hrContact!
                                : 'Hubungi dan follow-up',
                            onTap: () =>
                                _showFollowupSheet(context, currentJob),
                          ),

                          if (currentJob.status == 'Offering' ||
                              currentJob.offerDetails != null) ...[
                            const SizedBox(height: 10),
                            _buildOptionCard(
                              icon: Icons.local_offer_rounded,
                              iconColor: const Color(0xFFE11D48),
                              title: 'Rincian & Komparasi Penawaran',
                              subtitle:
                                  'Bandingkan komponen gaji, benefit, dan masa probation',
                              trailingBadge: 'Offering',
                              badgeColor: const Color(0xFFE11D48),
                              onTap: () => _showOfferComparisonSheet(
                                context,
                                currentJob,
                              ),
                            ),
                          ],

                          const SizedBox(height: 10),

                          // Option 4: Detail Penuh, Screenshot & Catatan
                          _buildOptionCard(
                            icon: Icons.feed_outlined,
                            iconColor: const Color(0xFFE58F00),
                            title: 'Detail Lamaran',
                            subtitle: 'Poster, catatan, dan bukti',
                            onTap: () =>
                                _showFullDetailsSheet(context, currentJob),
                          ),

                          if (currentJob.jobUrl != null &&
                              currentJob.jobUrl!.isNotEmpty) ...[
                            const SizedBox(height: 10),
                            _buildOptionCard(
                              icon: Icons.open_in_new_rounded,
                              iconColor: const Color(0xFF19191B),
                              title: 'Buka di Portal Asli',
                              subtitle:
                                  'Kunjungi postingan resmi di ${currentJob.sourcePlatform}',
                              onTap: () => _openOriginalUrl(currentJob.jobUrl),
                            ),
                          ],

                          const SizedBox(height: 14),

                          // Edit, Bagikan & Hapus Buttons
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () => _openEditJob(currentJob),
                                  icon: const Icon(
                                    Icons.edit_outlined,
                                    size: 15,
                                  ),
                                  label: const Text(
                                    'Edit Lamaran',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 14,
                                    ),
                                    foregroundColor: isDark
                                        ? Colors.white
                                        : const Color(0xFF121214),
                                    backgroundColor: isDark
                                        ? const Color(0xFF242428)
                                        : Colors.white,
                                    side: BorderSide(
                                      color: isDark
                                          ? const Color(0xFF383842)
                                          : const Color(0xFFDCD8CE),
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(18),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              OutlinedButton.icon(
                                onPressed: () => _shareJob(currentJob),
                                icon: const Icon(
                                  Icons.share_outlined,
                                  size: 15,
                                  color: Color(0xFF5C44E4),
                                ),
                                label: const Text(
                                  'Bagikan',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    color: Color(0xFF5C44E4),
                                  ),
                                ),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                    horizontal: 14,
                                  ),
                                  backgroundColor: isDark
                                      ? const Color(0xFF242428)
                                      : Colors.white,
                                  side: BorderSide(
                                    color: isDark
                                        ? const Color(0xFF4C38C2)
                                        : const Color(0xFFD6C8F8),
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(18),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              OutlinedButton(
                                onPressed: () => _deleteJob(currentJob),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                    horizontal: 14,
                                  ),
                                  backgroundColor: isDark
                                      ? const Color(0xFF242428)
                                      : Colors.white,
                                  side: BorderSide(
                                    color: isDark
                                        ? const Color(0xFF8B2525)
                                        : const Color(0xFFFFCDD2),
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(18),
                                  ),
                                ),
                                child: const Icon(
                                  Icons.delete_outline_rounded,
                                  size: 18,
                                  color: Color(0xFFE53935),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── STICKY BOTTOM ACTION BUTTON (ALWAYS SHOWS STATUS PICKER DOCK) ──
            Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                padding: EdgeInsets.fromLTRB(
                  20,
                  12,
                  20,
                  MediaQuery.of(context).padding.bottom > 0
                      ? MediaQuery.of(context).padding.bottom + 12
                      : 24,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      (isDark
                              ? const Color(0xFF121214)
                              : const Color(0xFFFBF8F2))
                          .withValues(alpha: 0.0),
                      (isDark
                              ? const Color(0xFF121214)
                              : const Color(0xFFFBF8F2))
                          .withValues(alpha: 0.95),
                      (isDark
                          ? const Color(0xFF121214)
                          : const Color(0xFFFBF8F2)),
                    ],
                  ),
                ),
                child: SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      HapticFeedback.heavyImpact();
                      _showStatusPicker(context, currentJob);
                    },
                    icon: const Icon(
                      Icons.swap_horiz_rounded,
                      size: 20,
                      color: Colors.white,
                    ),
                    label: Text(
                      'Perbarui Status Lamaran',
                      style: statusActionLabelTextStyle(context),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isDark
                          ? const Color(0xFF5C44E4)
                          : const Color(0xFF19191B),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28),
                      ),
                      elevation: 8,
                      shadowColor: Colors.black.withValues(alpha: 0.35),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<String> _getQualificationsList(JobApplication job) {
    final raw = job.jobDescription;
    if (raw.isEmpty) {
      return const ['Kualifikasi belum dicantumkan pada lamaran ini.'];
    }

    // The reference design calls this section "Kualifikasi minimum", but the
    // app must not invent qualifications. Display the exact user-entered job
    // description, only normalizing visual bullet prefixes.
    return raw
        .split('\n')
        .map((line) => line.replaceAll(RegExp(r'^[•\-\*\d\.\s]+'), '').trim())
        .where((line) => line.isNotEmpty)
        .toList();
  }

  Widget _buildInfoBubble({
    required Widget icon,
    required String label,
    required int index,
  }) {
    final isDark = AppTheme.isDark(context);
    final expanded = _expandedInfoBubbleIndex == index;
    return FluidBounceButton(
      selected: expanded,
      semanticLabel: 'Lihat detail $label',
      onTap: () => setState(() {
        _expandedInfoBubbleIndex = expanded ? null : index;
      }),
      scaleFactor: 0.97,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        height: 50,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: expanded
              ? (isDark ? const Color(0xFF3A325D) : const Color(0xFFFFF4C7))
              : (isDark ? const Color(0xFF242428) : Colors.white),
          borderRadius: BorderRadius.circular(25),
          border: Border.all(
            color: expanded
                ? const Color(0xFFF8BA38)
                : (isDark ? const Color(0xFF383842) : const Color(0xFFE5E0D5)),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            icon,
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : const Color(0xFF121214),
                ),
              ),
            ),
            const SizedBox(width: 2),
            Icon(
              expanded
                  ? Icons.keyboard_arrow_up_rounded
                  : Icons.keyboard_arrow_down_rounded,
              size: 15,
              color: isDark ? Colors.white70 : const Color(0xFF55555A),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpandedBubbleDetail(
    JobApplication job,
    int index,
    bool isDark,
  ) {
    final (icon, title, detail) = switch (index) {
      0 => (
        Icons.payments_rounded,
        'Rincian gaji',
        job.salaryOffered?.trim().isNotEmpty == true
            ? job.salaryOffered!.trim()
            : 'Nominal gaji belum dicantumkan.',
      ),
      1 => (
        Icons.home_work_rounded,
        'Mode kerja',
        '${job.workType}${job.location?.trim().isNotEmpty == true ? ' di ${job.location!.trim()}' : ''}',
      ),
      _ => (
        Icons.work_outline_rounded,
        'Status lamaran',
        'Tahap saat ini: ${job.status}. Dilamar pada ${job.appliedDate.day}/${job.appliedDate.month}/${job.appliedDate.year}.',
      ),
    };
    return MotionReveal(
      key: ValueKey('job-bubble-$index'),
      duration: const Duration(milliseconds: 220),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF242428) : Colors.white,
          borderRadius: BorderRadius.circular(17),
          border: Border.all(
            color: isDark ? const Color(0xFF383842) : const Color(0xFFE5E0D5),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: const Color(0xFF5C44E4), size: 19),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    detail,
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.3,
                      color: isDark ? Colors.white70 : const Color(0xFF5C5C62),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReferenceQualificationCard(JobApplication job, bool isDark) {
    final description = _getQualificationsList(job);
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: double.infinity,
          margin: const EdgeInsets.only(top: 17),
          padding: const EdgeInsets.fromLTRB(20, 31, 20, 20),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF232329) : Colors.white,
            borderRadius: BorderRadius.circular(25),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.20 : 0.08),
                blurRadius: 22,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ...description.map(
                (line) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 5,
                        height: 5,
                        margin: const EdgeInsets.only(top: 6, right: 9),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white
                              : const Color(0xFF151515),
                          shape: BoxShape.circle,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          line,
                          style: TextStyle(
                            fontSize: 13,
                            height: 1.35,
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? Colors.white
                                : const Color(0xFF202124),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        Positioned.fill(
          top: 0,
          bottom: null,
          child: Align(
            alignment: Alignment.topCenter,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 9),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF3A325D)
                    : const Color(0xFFFFF4C7),
                borderRadius: BorderRadius.circular(17),
              ),
              child: const Text(
                'Deskripsi',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOptionCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    String? trailingBadge,
    Color? badgeColor,
    String? heroTag,
    required VoidCallback onTap,
  }) {
    final isDark = AppTheme.isDark(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E24) : Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: isDark ? const Color(0xFF383842) : const Color(0xFFE5E0D5),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 18, color: iconColor),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : const Color(0xFF121214),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 11.5,
                      color: isDark
                          ? const Color(0xFFA0A0A8)
                          : const Color(0xFF707074),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (trailingBadge != null && badgeColor != null) ...[
              if (heroTag != null)
                Hero(
                  tag: heroTag,
                  flightShuttleBuilder:
                      (
                        flightContext,
                        animation,
                        flightDirection,
                        fromHeroContext,
                        toHeroContext,
                      ) {
                        return Material(
                          type: MaterialType.transparency,
                          child: toHeroContext.widget,
                        );
                      },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: badgeColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      trailingBadge,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: badgeColor,
                      ),
                    ),
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: badgeColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    trailingBadge,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: badgeColor,
                    ),
                  ),
                ),
              const SizedBox(width: 6),
            ],
            const Icon(
              CupertinoIcons.chevron_right,
              size: 14,
              color: Colors.grey,
            ),
          ],
        ),
      ),
    );
  }

  void _showOfferComparisonSheet(
    BuildContext context,
    JobApplication currentJob,
  ) {
    HapticFeedback.selectionClick();
    final isDark = AppTheme.isDark(context);
    final sheetBg = isDark ? const Color(0xFF1E1E24) : Colors.white;
    final txtPri = isDark ? Colors.white : const Color(0xFF121214);
    final txtSec = isDark ? const Color(0xFFA0A0A8) : const Color(0xFF707074);
    final cardBg = isDark ? const Color(0xFF282830) : const Color(0xFFF7F5F0);

    final otherOfferingJobs = ref
        .read(jobProvider)
        .jobs
        .where(
          (j) =>
              !j.isSampleData &&
              j.status == 'Offering' &&
              j.id != currentJob.id,
        )
        .toList();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        padding: EdgeInsets.fromLTRB(
          20,
          16,
          20,
          MediaQuery.of(ctx).padding.bottom + 24,
        ),
        decoration: BoxDecoration(
          color: sheetBg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF383842)
                        : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE11D48).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.local_offer_rounded,
                      color: Color(0xFFE11D48),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Rincian Penawaran Kerja',
                          style: TextStyle(
                            fontSize: 16.5,
                            fontWeight: FontWeight.w900,
                            color: txtPri,
                          ),
                        ),
                        Text(
                          '${currentJob.position} di ${currentJob.companyName}',
                          style: TextStyle(fontSize: 12, color: txtSec),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Offer breakdown card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Column(
                  children: [
                    _buildOfferRow(
                      'Gaji Ditawarkan',
                      currentJob.salaryOffered?.trim().isNotEmpty == true
                          ? currentJob.salaryOffered!
                          : 'Belum dicantumkan',
                      txtPri,
                      txtSec,
                      isHighlighted: true,
                    ),
                    const Divider(height: 16),
                    _buildOfferRow(
                      'Mode Kerja',
                      '${currentJob.workType}${currentJob.location != null ? " • ${currentJob.location}" : ""}',
                      txtPri,
                      txtSec,
                    ),
                    const Divider(height: 16),
                    _buildOfferRow(
                      'Kontak Perekrut',
                      currentJob.hrContact ?? 'Tidak ada kontak tersimpan',
                      txtPri,
                      txtSec,
                    ),
                    if (currentJob.offerDetails?.decisionDeadline != null) ...[
                      const Divider(height: 16),
                      _buildOfferRow(
                        'Tenggat Konfirmasi',
                        _formatTimelineDate(
                          currentJob.offerDetails!.decisionDeadline!,
                        ),
                        txtPri,
                        txtSec,
                      ),
                    ],
                    if (currentJob.offerDetails?.startDate != null) ...[
                      const Divider(height: 16),
                      _buildOfferRow(
                        'Tanggal Masuk',
                        _formatTimelineDate(
                          currentJob.offerDetails!.startDate!,
                        ),
                        txtPri,
                        txtSec,
                      ),
                    ],
                    if (currentJob.offerDetails?.compensationNotes.isNotEmpty ==
                        true) ...[
                      const Divider(height: 16),
                      _buildOfferRow(
                        'Catatan Paket',
                        currentJob.offerDetails!.compensationNotes,
                        txtPri,
                        txtSec,
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Comparison section
              if (otherOfferingJobs.isNotEmpty) ...[
                Text(
                  'PENASARAN DENGAN TAWARAN LAIN?',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    color: isDark
                        ? const Color(0xFFA78BFA)
                        : const Color(0xFF5C44E4),
                    letterSpacing: 0.6,
                  ),
                ),
                const SizedBox(height: 8),
                ...otherOfferingJobs.map(
                  (other) => Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${other.position} • ${other.companyName}',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w800,
                                  color: txtPri,
                                ),
                              ),
                              Text(
                                other.salaryOffered ?? 'Gaji belum diisi',
                                style: const TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFFE11D48),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(
                              0xFF5C44E4,
                            ).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            other.workType,
                            style: const TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF5C44E4),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ] else ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF5C44E4).withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.info_outline_rounded,
                        size: 16,
                        color: Color(0xFF5C44E4),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Saat ada lebih dari satu lowongan berstatus Offering, perbandingan komparasi gaji akan otomatis ditampilkan di sini.',
                          style: TextStyle(fontSize: 11, color: txtSec),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF5C44E4),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Tutup',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOfferRow(
    String label,
    String value,
    Color txtPri,
    Color txtSec, {
    bool isHighlighted = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 12.5, color: txtSec)),
        Flexible(
          child: Text(
            value,
            style: TextStyle(
              fontSize: isHighlighted ? 14 : 12.5,
              fontWeight: isHighlighted ? FontWeight.w900 : FontWeight.w700,
              color: isHighlighted ? const Color(0xFFE11D48) : txtPri,
            ),
            textAlign: TextAlign.end,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
