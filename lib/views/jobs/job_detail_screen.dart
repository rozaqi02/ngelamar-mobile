import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/job_application.dart';
import '../../providers/job_provider.dart';
import '../../services/followup_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/apple_sheet_window.dart';
import '../../widgets/apple_toast.dart';
import '../../widgets/company_logo_badge.dart';
import 'add_edit_job_screen.dart';
import 'interview_stages_screen.dart';

/// Screen 2: Job Detail (Progres 1-Klik, Tautan Asli Glints/JobStreet, & Follow-Up Cerdas).
class JobDetailScreen extends ConsumerStatefulWidget {
  final JobApplication job;

  const JobDetailScreen({super.key, required this.job});

  @override
  ConsumerState<JobDetailScreen> createState() => _JobDetailScreenState();
}

class _JobDetailScreenState extends ConsumerState<JobDetailScreen> {
  final List<String> _statusOptions = [
    'Dikirim',
    'Tes / Psikotes',
    'Interview HR',
    'Interview User',
    'Offering',
    'Diterima',
    'Ditolak',
  ];

  void _openEditJob(JobApplication currentJob) async {
    HapticFeedback.selectionClick();
    final result = await AppleSheetWindow.showAppleModalSheet<JobApplication>(
      context: context,
      child: AddEditJobScreen(jobToEdit: currentJob),
    );
    if (result != null && mounted) {
      AppleToast.success(context, 'Perubahan lamaran berhasil disimpan');
    }
  }

  void _advanceStage(JobApplication currentJob) async {
    HapticFeedback.heavyImpact();
    final next = await ref.read(jobProvider.notifier).advanceToNextStage(currentJob.id);
    if (next != null && mounted) {
      if (next == 'Offering' || next == 'Diterima') {
        AppleToast.success(
          context,
          '🎉 SELAMAT! Tahap $next',
          subtitle: 'Perjuanganmu di ${currentJob.companyName} membuahkan hasil!',
        );
      } else {
        AppleToast.success(
          context,
          'Tahapan dinaikkan ke $next 🚀',
          subtitle: 'Tetap semangat mempersiapkan tahap selanjutnya!',
        );
      }
    }
  }

  void _openOriginalUrl(String? url) async {
    if (url == null || url.isEmpty) return;
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _showStatusPicker(BuildContext context, JobApplication currentJob) {
    HapticFeedback.selectionClick();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Perbarui Status Lamaran',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: Color(0xFF121214),
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Pilih tahapan seleksi terbaru untuk lamaran ini:',
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _statusOptions.map((status) {
                final isSelected = status == currentJob.status;
                final statusColor = AppTheme.getStatusColor(status);

                return ChoiceChip(
                  selected: isSelected,
                  label: Text(status),
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : const Color(0xFF121214),
                    fontWeight: FontWeight.w700,
                  ),
                  selectedColor: statusColor,
                  backgroundColor: const Color(0xFFF5EFE6),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(
                      color: isSelected ? statusColor : const Color(0xFFDCD8CE),
                    ),
                  ),
                  onSelected: (_) {
                    Navigator.pop(ctx);
                    ref.read(jobProvider.notifier).updateStatus(currentJob.id, status);
                    AppleToast.success(context, 'Status diubah ke $status');
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _showFollowupSheet(BuildContext context, JobApplication currentJob) {
    HapticFeedback.selectionClick();
    final templates = FollowupService.generateTemplates(currentJob);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Template Follow-Up HR',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF121214)),
            ),
            const SizedBox(height: 8),
            const Text(
              'Salin pesan profesional ini untuk menanyakan status lamaranmu ke HR:',
              style: TextStyle(fontSize: 13, color: Color(0xFF707074)),
            ),
            const SizedBox(height: 16),
            ...templates.map((tpl) => Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF5EFE6),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFDCD8CE)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(tpl.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      IconButton(
                        icon: const Icon(Icons.copy_rounded, size: 18),
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: tpl.content));
                          Navigator.pop(ctx);
                          AppleToast.success(context, 'Pesan follow-up disalin ke clipboard!');
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(tpl.content, style: const TextStyle(fontSize: 12.5, height: 1.4, color: Color(0xFF333336))),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentJob = ref.watch(jobProvider).jobs.firstWhere(
      (j) => j.id == widget.job.id,
      orElse: () => widget.job,
    );

    final heroBg = AppTheme.getCompanyCardColor(currentJob.companyName);
    final canAdvance = currentJob.status != 'Diterima' && currentJob.status != 'Ditolak';

    return Scaffold(
      backgroundColor: AppTheme.warmBackground,
      body: Stack(
        children: [
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // HERO HEADER CONTAINER
              SliverToBoxAdapter(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: heroBg,
                    borderRadius: const BorderRadius.vertical(bottom: Radius.circular(32)),
                  ),
                  child: SafeArea(
                    bottom: false,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 10, 16, 26),
                      child: Column(
                        children: [
                          // Top Navigation Bar
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // Circular Back Button
                              GestureDetector(
                                onTap: () {
                                  HapticFeedback.selectionClick();
                                  Navigator.pop(context);
                                },
                                child: Container(
                                  width: 42,
                                  height: 42,
                                  decoration: const BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.arrow_back_rounded,
                                    size: 20,
                                    color: Color(0xFF121214),
                                  ),
                                ),
                              ),

                              // Header Actions (Edit & Bookmark)
                              Row(
                                children: [
                                  GestureDetector(
                                    onTap: () => _openEditJob(currentJob),
                                    child: Container(
                                      width: 42,
                                      height: 42,
                                      decoration: const BoxDecoration(
                                        color: Colors.white,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.edit_rounded,
                                        size: 18,
                                        color: Color(0xFF121214),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  GestureDetector(
                                    onTap: () {
                                      HapticFeedback.selectionClick();
                                      ref.read(jobProvider.notifier).toggleFavorite(currentJob.id);
                                    },
                                    child: Container(
                                      width: 42,
                                      height: 42,
                                      decoration: const BoxDecoration(
                                        color: Colors.white,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        currentJob.isFavorite
                                            ? Icons.bookmark_rounded
                                            : Icons.bookmark_border_rounded,
                                        size: 20,
                                        color: const Color(0xFF121214),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),

                          const SizedBox(height: 12),

                          // Large 64px White Circular Company Logo Badge
                          CompanyLogoBadge(
                            companyName: currentJob.companyName,
                            size: 64,
                          ),

                          const SizedBox(height: 12),

                          // Company Name Header
                          Text(
                            currentJob.companyName,
                            style: const TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF121214),
                              letterSpacing: -0.6,
                            ),
                            textAlign: TextAlign.center,
                          ),

                          const SizedBox(height: 10),

                          // Position Title Pill Badge
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.92),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              currentJob.position,
                              style: const TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF121214),
                              ),
                            ),
                          ),

                          const SizedBox(height: 10),

                          // Location
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.location_on_rounded,
                                size: 16,
                                color: Color(0xFF121214),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                currentJob.location ?? 'Jakarta Selatan, Indonesia',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF121214),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 18),

                          // Metadata Chips
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _buildMetadataChip(
                                icon: Icons.payments_rounded,
                                label: currentJob.salaryOffered ?? 'Rp 18 Jt - 25 Jt',
                              ),
                              const SizedBox(width: 8),
                              _buildMetadataChip(
                                icon: Icons.work_rounded,
                                label: currentJob.workType,
                              ),
                              const SizedBox(width: 8),
                              _buildMetadataChip(
                                icon: Icons.schedule_rounded,
                                label: '1-3 Thn',
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // BODY CONTENT
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 160),
                  child: Column(
                    children: [
                      // 1-Tap Advance Stage Action Card
                      if (canAdvance) ...[
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(AppTheme.radiusCardLarge),
                            border: Border.all(color: const Color(0xFFDCD8CE), width: 1.2),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.04),
                                blurRadius: 10,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Tahapan Saat Ini:',
                                    style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: AppTheme.getStatusColor(currentJob.status).withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      currentJob.status,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.getStatusColor(currentJob.status),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              SizedBox(
                                width: double.infinity,
                                height: 46,
                                child: ElevatedButton.icon(
                                  onPressed: () => _advanceStage(currentJob),
                                  icon: const Icon(Icons.rocket_launch_rounded, size: 16),
                                  label: const Text(
                                    'Naik ke Tahap Berikutnya 🚀',
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF5C44E4),
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                      ],

                      // Minimum Qualifications Card
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(22),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(AppTheme.radiusCardLarge),
                          border: Border.all(
                            color: const Color(0xFFDCD8CE),
                            width: 1.2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.04),
                              blurRadius: 16,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF5EFE6),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: const Color(0xFFDCD8CE)),
                              ),
                              child: const Text(
                                'Kualifikasi & Deskripsi',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF121214),
                                ),
                              ),
                            ),
                            const SizedBox(height: 18),
                            Text(
                              currentJob.jobDescription,
                              style: const TextStyle(
                                fontSize: 13.5,
                                height: 1.5,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF333336),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 14),

                      // Tautan Lowongan Asli (Glints/JobStreet) jika ada
                      if (currentJob.jobUrl != null && currentJob.jobUrl!.isNotEmpty) ...[
                        OutlinedButton.icon(
                          onPressed: () => _openOriginalUrl(currentJob.jobUrl),
                          icon: const Icon(Icons.open_in_new_rounded, size: 16),
                          label: Text('Buka di Portal Asli (${currentJob.sourcePlatform}) ↗'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF121214),
                            backgroundColor: Colors.white,
                            side: const BorderSide(color: Color(0xFFDCD8CE)),
                            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                          ),
                        ),
                        const SizedBox(height: 14),
                      ],

                      // "Lihat Tahapan Interview & Tips" Button
                      GestureDetector(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => InterviewStagesScreen(job: currentJob),
                            ),
                          );
                        },
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1C1C1E),
                            borderRadius: BorderRadius.circular(AppTheme.radiusCard),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.15),
                                blurRadius: 14,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.psychology_rounded, color: Colors.white, size: 20),
                                  SizedBox(width: 12),
                                  Text(
                                    'Lihat Panduan & Tips Seleksi',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 14.5,
                                    ),
                                  ),
                                ],
                              ),
                              Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 18),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Quick Actions Row: Update Status & Template Follow-up HR
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => _showStatusPicker(context, currentJob),
                              icon: const Icon(Icons.tune_rounded, size: 16),
                              label: Text(
                                'Status: ${currentJob.status}',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                side: const BorderSide(color: Color(0xFFDCD8CE), width: 1.4),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                backgroundColor: Colors.white,
                                foregroundColor: const Color(0xFF121214),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          OutlinedButton(
                            onPressed: () => _showFollowupSheet(context, currentJob),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              side: const BorderSide(color: Color(0xFFDCD8CE), width: 1.4),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                              backgroundColor: Colors.white,
                              foregroundColor: const Color(0xFF121214),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.send_rounded, size: 16, color: Color(0xFF5C44E4)),
                                SizedBox(width: 6),
                                Text('Follow-Up HR', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                              ],
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

          // STICKY BOTTOM ACTION BUTTON: "Perbarui Status Lamaran"
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () => _showStatusPicker(context, currentJob),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1C1C1E),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                    elevation: 6,
                    shadowColor: Colors.black.withValues(alpha: 0.3),
                  ),
                  child: const Text(
                    'Pilih Status Manual',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.2,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetadataChip({required IconData icon, required String label}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: const Color(0xFF121214)),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: Color(0xFF121214),
            ),
          ),
        ],
      ),
    );
  }
}
