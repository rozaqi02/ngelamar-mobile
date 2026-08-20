import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/job_application.dart';
import '../../providers/job_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/apple_toast.dart';

/// Screen 3: Tahapan Seleksi & Interview (100% Indonesian Localization & Fluid Animations).
class InterviewStagesScreen extends ConsumerStatefulWidget {
  final JobApplication job;

  const InterviewStagesScreen({super.key, required this.job});

  @override
  ConsumerState<InterviewStagesScreen> createState() => _InterviewStagesScreenState();
}

class _InterviewStagesScreenState extends ConsumerState<InterviewStagesScreen> {
  int _expandedStage = 0; // Default Stage 1 expanded

  void _showStageOptions(BuildContext context, JobApplication currentJob) {
    HapticFeedback.selectionClick();
    showCupertinoModalPopup(
      context: context,
      builder: (ctx) => CupertinoActionSheet(
        title: Text('Opsi Seleksi: ${currentJob.companyName}'),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(ctx);
              AppleToast.success(context, 'Pengingat jadwal interview berhasil diaktifkan!');
            },
            child: const Text('Aktifkan Notifikasi H-1'),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(ctx);
              AppleToast.success(context, 'Daftar pertanyaan interview disalin!');
            },
            child: const Text('Salin Bank Soal Interview'),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          isDefaultAction: true,
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Tutup'),
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

    const bg = AppTheme.warmBackground;

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // Top Navigation Bar (Matching Screen 3)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Row(
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
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(0xFFDCD8CE),
                            width: 1.2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.04),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Icon(
                          CupertinoIcons.chevron_back,
                          size: 20,
                          color: Color(0xFF121214),
                        ),
                      ),
                    ),

                    // Middle Title "Tahapan Seleksi"
                    const Text(
                      'Tahapan Seleksi',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF121214),
                        letterSpacing: -0.3,
                      ),
                    ),

                    // Circular Options Button (⋮)
                    GestureDetector(
                      onTap: () => _showStageOptions(context, currentJob),
                      child: Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(0xFFDCD8CE),
                            width: 1.2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.04),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Icon(
                          CupertinoIcons.ellipsis_vertical,
                          size: 18,
                          color: Color(0xFF121214),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Large Title Header: "[Company]\nTahapan Seleksi"
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                child: Text(
                  '${currentJob.companyName}\nTahapan Seleksi',
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF121214),
                    letterSpacing: -1.2,
                    height: 1.12,
                  ),
                ),
              ),
            ),

            // STACKED STAGE CARDS (Matching Screen 3)
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // Stage 1: Screening CV (Purple #5C44E4)
                  _buildStageCard(
                    stageNumber: 1,
                    title: 'Screening CV & Berkas',
                    shortDesc: 'Perekrut meninjau kecocokan CV ATS, portofolio projek GitHub, dan profil LinkedIn kamu.',
                    fullTips: 'Tips Lolos Screening:\n• Gunakan format standar ATS (1 halaman rapi).\n• Cantumkan tech stack yang relevan dengan kualifikasi lowongan.\n• Tambahkan tautan GitHub & portofolio aplikasi yang sudah live.',
                    cardColor: AppTheme.cardPurple,
                    isDarkText: false,
                    isExpanded: _expandedStage == 0,
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() => _expandedStage = _expandedStage == 0 ? -1 : 0);
                    },
                  ),

                  const SizedBox(height: 14),

                  // Stage 2: Panggilan HR (Coral Red #E55444)
                  _buildStageCard(
                    stageNumber: 2,
                    title: 'Panggilan HR & Psikotes',
                    shortDesc: 'Sesi interview perkenalan diri (30 menit), motivasi kerja, ekspektasi gaji, dan tes logika.',
                    fullTips: 'Tips Interview HR:\n• Siapkan perkenalan diri terstruktur metode STAR (Situation, Task, Action, Result).\n• Ketahui profil perusahaan dan produk utamanya.\n• Tanyakan 2 pertanyaan berbobot di akhir sesi wawancara.',
                    cardColor: AppTheme.cardCoral,
                    isDarkText: false,
                    isExpanded: _expandedStage == 1,
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() => _expandedStage = _expandedStage == 1 ? -1 : 1);
                    },
                  ),

                  const SizedBox(height: 14),

                  // Stage 3: Interview User & Teknis (Golden Yellow #F8BA38)
                  _buildStageCard(
                    stageNumber: 3,
                    title: 'Interview User & Teknis',
                    shortDesc: 'Live coding, studi kasus arsitektur sistem, algoritma, dan diskusi langsung dengan Lead Engineer.',
                    fullTips: 'Tips Interview User:\n• Jelaskan alur berpikirmu dengan suara lantang (think aloud).\n• Tunjukkan pemahaman clean architecture & state management.\n• Bersikap terbuka terhadap saran dan diskusi teknis.',
                    cardColor: AppTheme.cardYellow,
                    isDarkText: true,
                    isExpanded: _expandedStage == 2,
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() => _expandedStage = _expandedStage == 2 ? -1 : 2);
                    },
                  ),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStageCard({
    required int stageNumber,
    required String title,
    required String shortDesc,
    required String fullTips,
    required Color cardColor,
    required bool isDarkText,
    required bool isExpanded,
    required VoidCallback onTap,
  }) {
    final titleColor = isDarkText ? const Color(0xFF121214) : Colors.white;
    final descColor = isDarkText ? const Color(0xFF333336) : Colors.white.withValues(alpha: 0.90);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.fastOutSlowIn,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(AppTheme.radiusCardLarge),
          boxShadow: [
            BoxShadow(
              color: cardColor.withValues(alpha: 0.28),
              blurRadius: 14,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: "Stage X" Pill Badge + Circular Action Button ↗
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Stage Pill Badge (Matching Screen 3)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: isDarkText
                        ? const Color(0xFF1C1C1E)
                        : Colors.white.withValues(alpha: 0.22),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Tahap $stageNumber',
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),

                // Circular Action Button ↗ (Matching Screen 3)
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: isDarkText ? const Color(0xFF1C1C1E) : Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Icon(
                      isExpanded ? CupertinoIcons.chevron_up : CupertinoIcons.arrow_up_right,
                      size: 16,
                      color: isDarkText ? Colors.white : cardColor,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Stage Title
            Text(
              title,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: titleColor,
                letterSpacing: -0.5,
              ),
            ),

            const SizedBox(height: 8),

            // Stage Description
            Text(
              shortDesc,
              style: TextStyle(
                fontSize: 13.5,
                height: 1.4,
                fontWeight: FontWeight.w500,
                color: descColor,
              ),
            ),

            // Expanded Stage Tips & Preparation Checklist
            if (isExpanded) ...[
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDarkText
                      ? Colors.white.withValues(alpha: 0.95)
                      : Colors.black.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Text(
                  fullTips,
                  style: TextStyle(
                    fontSize: 12.5,
                    height: 1.45,
                    fontWeight: FontWeight.w600,
                    color: isDarkText ? const Color(0xFF121214) : Colors.white,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
