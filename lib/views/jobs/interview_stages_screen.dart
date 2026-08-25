import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/job_application.dart';
import '../../providers/job_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_toast.dart';

/// Screen: Tahapan Seleksi & Interview.
/// Tampilan visual & interaksi diselaraskan 100% dengan menu Persiapan Karir.
class InterviewStagesScreen extends ConsumerStatefulWidget {
  final JobApplication job;

  const InterviewStagesScreen({super.key, required this.job});

  @override
  ConsumerState<InterviewStagesScreen> createState() =>
      _InterviewStagesScreenState();
}

class _InterviewStagesScreenState extends ConsumerState<InterviewStagesScreen> {
  int _expandedStage = 0; // Default Stage 1 expanded

  final List<Map<String, String>> _stageItems = [
    {
      'tag': 'TAHAP 01',
      'sub': 'Tahap Awal: CV ATS & Portofolio',
      'title': 'Screening CV & Berkas',
      'desc':
          'Perekrut meninjau kecocokan CV ATS, portofolio projek GitHub, dan profil LinkedIn Anda.',
      'tips':
          '• Gunakan format standar ATS (1 halaman rapi, format PDF).\n• Cantumkan tech stack & keahlian yang relevan dengan posisi dilamar.\n• Tambahkan tautan GitHub & demo aplikasi portofolio yang sudah live.\n• Pastikan info kontak (email & no. WhatsApp) aktif dan benar.',
    },
    {
      'tag': 'TAHAP 02',
      'sub': 'Wawancara HR & Logika',
      'title': 'Panggilan HR & Psikotes',
      'desc':
          'Sesi interview perkenalan diri (30 menit), motivasi kerja, ekspektasi gaji, dan tes potensi akademik/logika.',
      'tips':
          '• Siapkan pitch perkenalan diri 60 detik dengan metode STAR.\n• Pelajari profil perusahaan, visi, produk, dan berita terkini tentang mereka.\n• Ketahui kisaran gaji pasar (UMR/standar industri posisi terkait).\n• Siapkan 2 pertanyaan strategis untuk HR di akhir sesi.',
    },
    {
      'tag': 'TAHAP 03',
      'sub': 'Live Coding & Ujian Teknis',
      'title': 'Tes Teknis & Studi Kasus',
      'desc':
          'Ujian kemampuan teknis, live coding, studi kasus arsitektur sistem, algoritma, atau take-home assignment.',
      'tips':
          '• Lakukan "think aloud" (utarakan alur berpikir secara jelas saat coding).\n• Kuasai clean architecture, state management, dan error handling.\n• Tulis kode yang bersih, mudah dibaca, dan gunakan nama variabel deskriptif.\n• Tanyakan klarifikasi jika requirement soal kurang spesifik.',
    },
    {
      'tag': 'TAHAP 04',
      'sub': 'Wawancara User & Lead Team',
      'title': 'Interview User & Culture Fit',
      'desc':
          'Wawancara mendalam bersama calon atasan langsung (Lead/Manager/Director) mengenai kultur kerja dan kecocokan tim.',
      'tips':
          '• Ceritakan pengalaman menyelesaikan kendala sulit (troubleshooting).\n• Tunjukkan mindset growth, kemauan belajar cepat, dan komunikasi tim yang baik.\n• Berikan contoh konkret kontribusi Anda di proyek sebelumnya.\n• Tunjukkan antusiasme tinggi untuk berkembang di perusahaan ini.',
    },
    {
      'tag': 'TAHAP 05',
      'sub': 'Offering Letter & Negosiasi',
      'title': 'Offering & Tanda Tangan Kontrak',
      'desc':
          'Penawaran resmi surat penerimaan kerja (Offering Letter), rincian kompensasi gaji, benefit, dan tanggal mulai masuk.',
      'tips':
          '• Cek detail komponen gaji pokok, tunjangan, asuransi (BPJS), dan bonus.\n• Pahami masa percobaan (probation period) dan status karyawan.\n• Berikan respons profesional dalam batas waktu yang diberikan.\n• Negosiasikan benefit secara sopan dan berbasis riset pasar.',
    },
  ];

  void _showStageOptions(BuildContext context, JobApplication currentJob) {
    HapticFeedback.selectionClick();
    final isDark = AppTheme.isDark(context);
    final sheetBg = isDark ? const Color(0xFF1E1E24) : Colors.white;
    final txtPri = isDark ? Colors.white : const Color(0xFF121214);
    final txtSec = isDark ? const Color(0xFFA0A0A8) : const Color(0xFF707074);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        decoration: BoxDecoration(
          color: sheetBg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF383842) : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Opsi Seleksi: ${currentJob.companyName}',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w900,
                color: txtPri,
              ),
            ),
            const SizedBox(height: 14),
            ListTile(
              leading: const Icon(
                Icons.notifications_active_rounded,
                color: Color(0xFF5C44E4),
              ),
              title: Text(
                'Aktifkan Notifikasi H-1',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13.5,
                  color: txtPri,
                ),
              ),
              trailing: Icon(
                CupertinoIcons.chevron_right,
                size: 14,
                color: txtSec,
              ),
              onTap: () {
                Navigator.pop(ctx);
                AppToast.success(
                  context,
                  'Pengingat jadwal interview berhasil diaktifkan!',
                );
              },
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            ListTile(
              leading: Icon(
                Icons.copy_rounded,
                color: isDark ? Colors.white : const Color(0xFF19191B),
              ),
              title: Text(
                'Salin Panduan Tahapan',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13.5,
                  color: txtPri,
                ),
              ),
              trailing: Icon(
                CupertinoIcons.chevron_right,
                size: 14,
                color: txtSec,
              ),
              onTap: () {
                Navigator.pop(ctx);
                final allTips = _stageItems
                    .map((s) => '[${s['tag']}] ${s['title']}\n${s['tips']}')
                    .join('\n\n');
                Clipboard.setData(ClipboardData(text: allTips));
                AppToast.success(context, 'Panduan tahapan seleksi disalin!');
              },
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentJob = ref
        .watch(jobProvider)
        .jobs
        .firstWhere((j) => j.id == widget.job.id, orElse: () => widget.job);
    final isDark = AppTheme.isDark(context);
    final txtPri = isDark ? Colors.white : const Color(0xFF121214);
    final txtSec = isDark ? const Color(0xFFA0A0A8) : const Color(0xFF707074);
    final btnBg = isDark ? const Color(0xFF242428) : Colors.white;
    final btnBorder = isDark
        ? const Color(0xFF383842)
        : const Color(0xFFDCD8CE);

    const cardColors = [
      AppTheme.cardPurple,
      AppTheme.cardCoral,
      AppTheme.cardYellow,
      AppTheme.cardGreen,
      AppTheme.cardDark,
    ];

    final bg = isDark ? const Color(0xFF121214) : AppTheme.warmBackground;

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // Top Navigation Bar
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
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
                          color: btnBg,
                          shape: BoxShape.circle,
                          border: Border.all(color: btnBorder, width: 1.2),
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
                        child: Icon(
                          CupertinoIcons.chevron_back,
                          size: 20,
                          color: txtPri,
                        ),
                      ),
                    ),

                    // Middle Title "Tahapan Seleksi"
                    Text(
                      'Tahapan Seleksi',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: txtPri,
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
                          color: btnBg,
                          shape: BoxShape.circle,
                          border: Border.all(color: btnBorder, width: 1.2),
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
                        child: Icon(
                          CupertinoIcons.ellipsis_vertical,
                          size: 18,
                          color: txtPri,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Large Title Header with Status Pill Morph
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.getStatusColor(
                          currentJob.status,
                        ).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppTheme.getStatusColor(
                            currentJob.status,
                          ).withValues(alpha: 0.4),
                          width: 1.2,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 7,
                            height: 7,
                            decoration: BoxDecoration(
                              color: AppTheme.getStatusColor(currentJob.status),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Status Saat Ini: ${currentJob.status}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.getStatusColor(currentJob.status),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      currentJob.companyName,
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        color: txtPri,
                        letterSpacing: -0.8,
                        height: 1.15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Panduan & cheat sheet 5 tahapan seleksi ${currentJob.position}',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: txtSec,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Actual, user-owned history. The guides below remain useful, but
            // this section is the source of truth for this particular
            // application and survives status changes or restores.
            if (currentJob.recruitmentEvents.isNotEmpty ||
                currentJob.labels.isNotEmpty ||
                currentJob.hasNextAction)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 18),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: btnBg,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: btnBorder),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.history_rounded,
                              color: Color(0xFF5C44E4),
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Riwayat Lamaran Ini',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w900,
                                color: txtPri,
                              ),
                            ),
                          ],
                        ),
                        if (currentJob.hasNextAction) ...[
                          const SizedBox(height: 12),
                          _buildActualEventRow(
                            icon: Icons.task_alt_rounded,
                            title: currentJob.nextActionType!,
                            detail:
                                'Berikutnya: ${_formatEventDate(currentJob.nextActionAt!)}${currentJob.nextActionNote?.trim().isNotEmpty == true ? ' — ${currentJob.nextActionNote}' : ''}',
                            color: const Color(0xFF22A06B),
                            textColor: txtPri,
                            secondaryColor: txtSec,
                          ),
                        ],
                        ...currentJob.recruitmentEvents.reversed.map(
                          (event) => Padding(
                            padding: const EdgeInsets.only(top: 12),
                            child: _buildActualEventRow(
                              icon: Icons.circle,
                              title: event.title,
                              detail:
                                  '${_formatEventDate(event.occurredAt)}${event.notes?.trim().isNotEmpty == true ? ' — ${event.notes}' : ''}',
                              color: const Color(0xFF5C44E4),
                              textColor: txtPri,
                              secondaryColor: txtSec,
                            ),
                          ),
                        ),
                        if (currentJob.labels.isNotEmpty) ...[
                          const SizedBox(height: 14),
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: currentJob.labels
                                .map(
                                  (label) => Chip(
                                    label: Text(label),
                                    visualDensity: VisualDensity.compact,
                                    backgroundColor: const Color(
                                      0xFF5C44E4,
                                    ).withValues(alpha: 0.10),
                                    side: BorderSide.none,
                                    labelStyle: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF5C44E4),
                                    ),
                                  ),
                                )
                                .toList(),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),

            // 5 STAGE CARDS (STYLING PERSIS SAMA DENGAN PERSIAPAN KARIR INTERVIEW)
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(0, 0, 0, 100),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate((context, idx) {
                  final stage = _stageItems[idx];
                  final isExpanded = _expandedStage == idx;
                  final cardColor = cardColors[idx % cardColors.length];
                  final isDarkText =
                      cardColor == AppTheme.cardYellow ||
                      cardColor == AppTheme.cardGreen;
                  final titleColor = isDarkText
                      ? const Color(0xFF121214)
                      : Colors.white;
                  final descColor = isDarkText
                      ? const Color(0xFF333336)
                      : Colors.white.withValues(alpha: 0.90);

                  return GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() {
                        _expandedStage = isExpanded ? -1 : idx;
                      });
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 280),
                      curve: Curves.fastOutSlowIn,
                      width: double.infinity,
                      margin: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(
                          AppTheme.radiusCardLarge,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: AnimatedSize(
                        duration: const Duration(milliseconds: 280),
                        curve: Curves.fastOutSlowIn,
                        alignment: Alignment.topCenter,
                        child: Padding(
                          padding: const EdgeInsets.all(18),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Top Row: Tag Pill & Expand Icon
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isDarkText
                                          ? const Color(
                                              0xFF19191B,
                                            ).withValues(alpha: 0.12)
                                          : Colors.white.withValues(
                                              alpha: 0.22,
                                            ),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      stage['tag']!,
                                      style: TextStyle(
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.w900,
                                        color: titleColor,
                                        letterSpacing: 0.4,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    width: 32,
                                    height: 32,
                                    decoration: BoxDecoration(
                                      color: isDarkText
                                          ? const Color(0xFF19191B)
                                          : Colors.white,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      isExpanded
                                          ? CupertinoIcons.chevron_up
                                          : CupertinoIcons.chevron_down,
                                      size: 14,
                                      color: isDarkText
                                          ? Colors.white
                                          : cardColor,
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 10),

                              // Focus Subtitle
                              Text(
                                stage['sub']!,
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                  color: descColor,
                                ),
                              ),

                              const SizedBox(height: 4),

                              // Stage Title
                              Text(
                                stage['title']!,
                                style: TextStyle(
                                  fontSize: 15.5,
                                  fontWeight: FontWeight.w900,
                                  color: titleColor,
                                  letterSpacing: -0.3,
                                  height: 1.3,
                                ),
                              ),

                              const SizedBox(height: 6),

                              // Stage Description
                              Text(
                                stage['desc']!,
                                style: TextStyle(
                                  fontSize: 12.5,
                                  height: 1.4,
                                  fontWeight: FontWeight.w500,
                                  color: descColor,
                                ),
                              ),

                              // Expanded Answer & Strategy Box
                              if (isExpanded) ...[
                                const SizedBox(height: 14),
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: isDarkText
                                        ? Colors.white.withValues(alpha: 0.95)
                                        : Colors.black.withValues(alpha: 0.20),
                                    borderRadius: BorderRadius.circular(18),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.tips_and_updates_outlined,
                                            size: 14,
                                            color: isDarkText
                                                ? const Color(0xFF121214)
                                                : Colors.white,
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            'Tips Lolos & Checklist Tahapan:',
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w900,
                                              color: isDarkText
                                                  ? const Color(0xFF121214)
                                                  : Colors.white,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        stage['tips']!,
                                        style: TextStyle(
                                          fontSize: 12.5,
                                          height: 1.45,
                                          fontWeight: FontWeight.w500,
                                          color: isDarkText
                                              ? const Color(0xFF222224)
                                              : Colors.white.withValues(
                                                  alpha: 0.95,
                                                ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }, childCount: _stageItems.length),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatEventDate(DateTime date) {
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

  Widget _buildActualEventRow({
    required IconData icon,
    required String title,
    required String detail,
    required Color color,
    required Color textColor,
    required Color secondaryColor,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Icon(icon, size: icon == Icons.circle ? 8 : 18, color: color),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                detail,
                style: TextStyle(fontSize: 11.5, color: secondaryColor),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
