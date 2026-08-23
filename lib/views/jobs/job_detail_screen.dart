import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/job_application.dart';
import '../../providers/job_provider.dart';
import '../../services/followup_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/apple_animations.dart';
import '../../widgets/app_dialog.dart';
import '../../widgets/apple_toast.dart';
import '../../widgets/app_toast.dart';
import '../../widgets/company_logo_badge.dart';
import '../../widgets/delight_celebration.dart';
import '../../widgets/container_morph_route.dart';
import 'add_edit_job_screen.dart';
import 'interview_stages_screen.dart';

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

  const JobDetailScreen({super.key, required this.job});

  @override
  ConsumerState<JobDetailScreen> createState() => _JobDetailScreenState();
}

class _JobDetailScreenState extends ConsumerState<JobDetailScreen>
    with SingleTickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  late AnimationController _bookmarkAnimController;
  late Animation<double> _bookmarkScaleAnim;

  int _selectedTab =
      0; // 0: Kualifikasi Minimum, 1: Deskripsi Pekerjaan, 2: Benefit & Fasilitas
  double _scrollOffset = 0.0;
  int? _expandedInfoChipIndex =
      1; // Mode kerja menjadi fokus awal; chip lain tetap bulat.

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

    _scrollController.addListener(() {
      setState(() {
        _scrollOffset = _scrollController.offset.clamp(0.0, 300.0);
      });
    });
  }

  @override
  void dispose() {
    _bookmarkAnimController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _shareJob(JobApplication currentJob) {
    HapticFeedback.selectionClick();
    final salary = currentJob.salaryOffered != null
        ? '\n💰 Gaji: ${currentJob.salaryOffered}'
        : '';
    final loc = currentJob.location != null
        ? '\n📍 Lokasi: ${currentJob.location}'
        : '';
    final url = currentJob.jobUrl != null
        ? '\n🔗 Link: ${currentJob.jobUrl}'
        : '';
    final date =
        '📅 Dilamar: ${currentJob.appliedDate.day}/${currentJob.appliedDate.month}/${currentJob.appliedDate.year}';
    final status = '📊 Status: ${currentJob.status} (${currentJob.workType})';

    final text =
        '📄 *Lowongan Kerja - Ngelamar App*\n'
        '🏢 *${currentJob.companyName}*\n'
        '💼 Posisi: ${currentJob.position}'
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

  void _openEditJob(JobApplication currentJob) async {
    HapticFeedback.selectionClick();
    final result = await MorphSheetRoute.openMorphingSheet<JobApplication>(
      context: context,
      child: AddEditJobScreen(jobToEdit: currentJob),
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

  void _pickCompanyLogo(JobApplication currentJob) async {
    HapticFeedback.selectionClick();
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 600,
      maxHeight: 600,
      imageQuality: 85,
    );
    if (image == null || !mounted) return;

    try {
      final appDocDir = await getApplicationDocumentsDirectory();
      final logosDir = Directory('${appDocDir.path}/logos');
      if (!await logosDir.exists()) {
        await logosDir.create(recursive: true);
      }
      final savedImage = await File(image.path).copy(
        '${logosDir.path}/logo_${DateTime.now().millisecondsSinceEpoch}.png',
      );
      if (!mounted) return;
      final updated = currentJob.copyWith(companyLogoPath: savedImage.path);
      await ref.read(jobProvider.notifier).updateJob(updated);
      if (mounted) {
        AppleToast.success(context, 'Foto perusahaan berhasil diubah!');
      }
    } catch (_) {
      if (mounted) {
        AppleToast.warning(context, 'Foto perusahaan gagal disimpan.');
      }
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

  void _showStatusPicker(BuildContext context, JobApplication currentJob) {
    HapticFeedback.selectionClick();
    if (currentJob.isSampleData) {
      AppleToast.info(context, 'Status dikunci karena ini data contoh.');
      return;
    }
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
              children: _statusOptions.map((status) {
                final isSelected = status == currentJob.status;
                final statusColor = AppTheme.getStatusColor(status);

                return GestureDetector(
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
                );
              }).toList(),
            ),
            const SizedBox(height: 10),
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
                            'Follow-Up HR Cerdas',
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
                                  borderRadius: BorderRadius.circular(8),
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
                              borderRadius: BorderRadius.circular(12),
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
                                child: ElevatedButton.icon(
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
                                  label: const Text('Salin Pesan'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF19191B),
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
                              if (currentJob.hrContact != null &&
                                  currentJob.hrContact!.isNotEmpty) ...[
                                const SizedBox(width: 8),
                                ElevatedButton.icon(
                                  onPressed: () async {
                                    final contact = currentJob.hrContact!;
                                    try {
                                      if (tpl.type == FollowupType.whatsapp) {
                                        final cleanNum = contact.replaceAll(
                                          RegExp(r'[^0-9+]'),
                                          '',
                                        );
                                        final encoded = Uri.encodeComponent(
                                          tpl.body,
                                        );
                                        final uri = Uri.parse(
                                          'https://wa.me/$cleanNum?text=$encoded',
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
                                        ClipboardData(text: contact),
                                      );
                                      if (context.mounted) {
                                        AppleToast.info(
                                          context,
                                          'Kontak disalin (Aplikasi tidak ditemukan)',
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
                                        ? 'Kirim WA'
                                        : 'Kirim Email',
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
                                      horizontal: 14,
                                    ),
                                  ),
                                ),
                              ],
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
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (_, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Color(0xFFFBF8F2),
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
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
                      color: const Color(0xFFD5CEBF),
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
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF121214),
                              letterSpacing: -0.4,
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
                      icon: const Icon(
                        Icons.close_rounded,
                        size: 22,
                        color: Color(0xFF121214),
                      ),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: Color(0xFFE6E0D5)),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(22, 18, 22, 40),
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFE5E0D5)),
                      ),
                      child: Column(
                        children: [
                          _buildDetailRow(
                            icon: Icons.flag_rounded,
                            label: 'Status Tahapan',
                            value: currentJob.status,
                            badgeColor: AppTheme.getStatusColor(
                              currentJob.status,
                            ),
                          ),
                          const Divider(height: 20, color: Color(0xFFF0ECE3)),
                          _buildDetailRow(
                            icon: Icons.payments_rounded,
                            label: 'Tawaran Gaji',
                            value:
                                currentJob.salaryOffered ?? 'Tidak dicantumkan',
                          ),
                          const Divider(height: 20, color: Color(0xFFF0ECE3)),
                          _buildDetailRow(
                            icon: Icons.work_outline_rounded,
                            label: 'Tipe Kerja',
                            value: currentJob.workType,
                          ),
                          const Divider(height: 20, color: Color(0xFFF0ECE3)),
                          _buildDetailRow(
                            icon: Icons.location_on_outlined,
                            label: 'Lokasi Kantor',
                            value:
                                currentJob.location?.trim().isNotEmpty == true
                                ? currentJob.location!.trim()
                                : 'Belum dicantumkan',
                          ),
                          const Divider(height: 20, color: Color(0xFFF0ECE3)),
                          _buildDetailRow(
                            icon: Icons.calendar_today_rounded,
                            label: 'Tanggal Melamar',
                            value:
                                '${currentJob.appliedDate.day}/${currentJob.appliedDate.month}/${currentJob.appliedDate.year}',
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFE5E0D5)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(
                                Icons.contact_phone_rounded,
                                size: 18,
                                color: Color(0xFF5C44E4),
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Kontak HRD / Rekruter',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF121214),
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
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF333336),
                            ),
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
                                          'Kontak disalin (Aplikasi tidak ditemukan)',
                                        );
                                      }
                                    }
                                  },
                                  icon: const Icon(
                                    Icons.send_rounded,
                                    size: 14,
                                  ),
                                  label: Text(
                                    currentJob.hrContact!.contains('@')
                                        ? 'Kirim Email'
                                        : 'Hubungi via WhatsApp',
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF25D366),
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
                                    foregroundColor: const Color(0xFF121214),
                                    side: const BorderSide(
                                      color: Color(0xFFDCD8CE),
                                    ),
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
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFFE5E0D5)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Row(
                                  children: [
                                    Icon(
                                      Icons.photo_library_rounded,
                                      size: 18,
                                      color: Color(0xFF5C44E4),
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      'Screenshot Bukti Loker',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w800,
                                        color: Color(0xFF121214),
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
                                child: Image.file(
                                  File(currentJob.screenshotPath!),
                                  height: 180,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
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
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFFE5E0D5)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(
                                  Icons.note_alt_rounded,
                                  size: 18,
                                  color: Color(0xFF5C44E4),
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'Catatan Pribadi',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF121214),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              currentJob.notes!,
                              style: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFF333336),
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
    Color? badgeColor,
  }) {
    return Row(
      children: [
        Icon(icon, size: 18, color: const Color(0xFF707074)),
        const SizedBox(width: 12),
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            color: Color(0xFF707074),
            fontWeight: FontWeight.w500,
          ),
        ),
        const Spacer(),
        if (badgeColor != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              color: badgeColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
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
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Color(0xFF121214),
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
            Color(0xFF143820),
            Color(0xFF16291C),
            Color(0xFF131A15),
            Color(0xFF121214),
          ];
        case 'Offering':
          return const [
            Color(0xFF38153A),
            Color(0xFF28112A),
            Color(0xFF190F1A),
            Color(0xFF121214),
          ];
        case 'Interview User':
          return const [
            Color(0xFF261942),
            Color(0xFF1C1330),
            Color(0xFF151020),
            Color(0xFF121214),
          ];
        case 'Interview HR':
        case 'Interview':
          return const [
            Color(0xFF362810),
            Color(0xFF281F0E),
            Color(0xFF1A160F),
            Color(0xFF121214),
          ];
        case 'Tes / Psikotes':
          return const [
            Color(0xFF381618),
            Color(0xFF291214),
            Color(0xFF1A1011),
            Color(0xFF121214),
          ];
        case 'Ditolak':
          return const [
            Color(0xFF24242A),
            Color(0xFF1C1C20),
            Color(0xFF161618),
            Color(0xFF121214),
          ];
        case 'Dikirim':
        case 'Tersedia':
        default:
          return const [
            Color(0xFF16263B),
            Color(0xFF131C28),
            Color(0xFF12161E),
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
          Color(0xFFF0ABFC),
          Color(0xFFF5D0FE),
          Color(0xFFFAF5FF),
          Color(0xFFFBF8F2),
        ];
      case 'Interview User':
        return const [
          Color(0xFFC4B5FD),
          Color(0xFFDDD6FE),
          Color(0xFFF5F3FF),
          Color(0xFFFBF8F2),
        ];
      case 'Interview HR':
      case 'Interview':
        return const [
          Color(0xFFFDE047),
          Color(0xFFFEF08A),
          Color(0xFFFEFCE8),
          Color(0xFFFBF8F2),
        ];
      case 'Tes / Psikotes':
        return const [
          Color(0xFFFCA5A5),
          Color(0xFFFECACA),
          Color(0xFFFEF2F2),
          Color(0xFFFBF8F2),
        ];
      case 'Ditolak':
        return const [
          Color(0xFFCBD5E1),
          Color(0xFFE2E8F0),
          Color(0xFFF8FAFC),
          Color(0xFFFBF8F2),
        ];
      case 'Dikirim':
      case 'Tersedia':
      default:
        return const [
          Color(0xFF93C5FD),
          Color(0xFFBFDBFE),
          Color(0xFFEFF6FF),
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

    // Scroll animation factor (0.0 to 1.0)
    final scrollRatio = (_scrollOffset / 160.0).clamp(0.0, 1.0);
    final logoSize = 64.0 - (scrollRatio * 18.0); // Shrinks from 64 to 46

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF121214)
          : const Color(0xFFFBF8F2),
      body: Stack(
        children: [
          // ── DYNAMIC STATUS-BASED GRADIENT BACKGROUND ──
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 480,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: _getStatusGradients(
                    currentJob.status,
                    isDark: isDark,
                  ),
                  stops: const [0.0, 0.45, 0.78, 1.0],
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
                    padding: const EdgeInsets.fromLTRB(20, 10, 20, 14),
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

                        // Center Company Logo Badge with scroll shrink animation
                        Hero(
                          tag: 'company_logo_${currentJob.id}',
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
                          child: CompanyLogoBadge(
                            companyName: currentJob.companyName,
                            size: logoSize,
                            customImagePath: currentJob.companyLogoPath,
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
                              DelightCelebration.show(
                                context,
                                message: 'Lowongan favorit tersimpan!',
                                accent: const Color(0xFFF8BA38),
                                icon: Icons.bookmark_rounded,
                                preset: DelightPreset.bookmark,
                              );
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

                        // ── 3 KEY INFO BUBBLES ──
                        // Lebar dihitung eksplisit agar dua bubble yang menyusut
                        // selalu 50×50, bukan oval karena tekanan flex layout.
                        LayoutBuilder(
                          builder: (context, constraints) {
                            return Row(
                              children: [
                                _buildInteractiveInfoChip(
                                  index: 0,
                                  availableWidth: constraints.maxWidth,
                                  iconWidget: const Text(
                                    'Rp',
                                    style: TextStyle(
                                      color: Color(0xFF19191B),
                                      fontWeight: FontWeight.w900,
                                      fontSize: 12,
                                    ),
                                  ),
                                  shortText: salaryText,
                                  fullText:
                                      currentJob.salaryOffered != null &&
                                          currentJob.salaryOffered!.isNotEmpty
                                      ? currentJob.salaryOffered!
                                      : 'Gaji belum dicantumkan',
                                ),
                                const SizedBox(width: 8),
                                _buildInteractiveInfoChip(
                                  index: 1,
                                  availableWidth: constraints.maxWidth,
                                  iconWidget: const Icon(
                                    Icons.access_time_rounded,
                                    size: 18,
                                    color: Color(0xFF5C44E4),
                                  ),
                                  shortText: currentJob.workType == 'WFO'
                                      ? 'On-Site'
                                      : currentJob.workType,
                                  fullText: currentJob.workType == 'WFO'
                                      ? 'Mode: On-Site (WFO)'
                                      : (currentJob.workType == 'WFH'
                                            ? 'Mode: Remote (WFH)'
                                            : 'Mode: Hybrid (Fleksibel)'),
                                ),
                                const SizedBox(width: 8),
                                _buildInteractiveInfoChip(
                                  index: 2,
                                  availableWidth: constraints.maxWidth,
                                  iconWidget: const Icon(
                                    Icons.work_outline_rounded,
                                    size: 18,
                                    color: Color(0xFF1E8E3E),
                                  ),
                                  shortText: experienceText,
                                  fullText: currentJob.status != 'Tersedia'
                                      ? 'Tahap: ${currentJob.status}'
                                      : 'Portal: ${currentJob.sourcePlatform}',
                                ),
                              ],
                            );
                          },
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

                // ── DETAIL PEKERJAAN: SEMUA TAB SELALU TERLIHAT ──
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 10),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF1E1E24)
                                : const Color(0xFFECE8DF),
                            borderRadius: BorderRadius.circular(19),
                            border: Border.all(
                              color: isDark
                                  ? const Color(0xFF33333A)
                                  : const Color(0xFFE1DCD2),
                            ),
                          ),
                          child: Row(
                            children: [
                              _buildTabItem(
                                0,
                                'Kualifikasi',
                                Icons.verified_outlined,
                              ),
                              const SizedBox(width: 4),
                              _buildTabItem(
                                1,
                                'Deskripsi',
                                Icons.subject_rounded,
                              ),
                              const SizedBox(width: 4),
                              _buildTabItem(
                                2,
                                'Benefit',
                                Icons.redeem_outlined,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 240),
                          switchInCurve: Curves.easeOutCubic,
                          switchOutCurve: Curves.easeInCubic,
                          transitionBuilder: (child, animation) => ClipRect(
                            child: SizeTransition(
                              sizeFactor: animation,
                              alignment: Alignment.topCenter,
                              child: child,
                            ),
                          ),
                          child: _buildDetailSectionCard(currentJob, isDark),
                        ),
                      ],
                    ),
                  ),
                ),

                // ── BAGIAN BAWAH: OPSI MELIHAT DATA DENGAN LENGKAP ──
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 14, 20, 160),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(left: 4, bottom: 10),
                          child: Text(
                            'DATA & RIWAYAT LENGKAP',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                              color: Colors.grey,
                              letterSpacing: 0.6,
                            ),
                          ),
                        ),

                        // Option 1: Timeline & Riwayat Seleksi with Hero Morph
                        _buildOptionCard(
                          icon: Icons.timeline_rounded,
                          iconColor: const Color(0xFF5C44E4),
                          title: 'Timeline & Riwayat Tahapan',
                          subtitle: 'Status saat ini: ${currentJob.status}',
                          trailingBadge: currentJob.status,
                          badgeColor: AppTheme.getStatusColor(
                            currentJob.status,
                          ),
                          heroTag: 'job_status_pill_${currentJob.id}',
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

                        // Option 2: Panduan & Tips Interview
                        _buildOptionCard(
                          icon: Icons.psychology_rounded,
                          iconColor: const Color(0xFF19191B),
                          title: 'Panduan & Tips Interview',
                          subtitle:
                              'Cheat-sheet jawaban dan strategi wawancara',
                          onTap: () {
                            HapticFeedback.selectionClick();
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    InterviewStagesScreen(job: currentJob),
                              ),
                            );
                          },
                        ),

                        const SizedBox(height: 10),

                        // Option 3: Kontak HR & Template Follow-Up
                        _buildOptionCard(
                          icon: Icons.send_rounded,
                          iconColor: const Color(0xFF25D366),
                          title: 'Kontak HR & Follow-Up',
                          subtitle:
                              currentJob.hrContact != null &&
                                  currentJob.hrContact!.isNotEmpty
                              ? 'Tersimpan: ${currentJob.hrContact}'
                              : 'Kirim pesan follow-up via WhatsApp / Email',
                          onTap: () => _showFollowupSheet(context, currentJob),
                        ),

                        const SizedBox(height: 10),

                        // Option 4: Detail Penuh, Screenshot & Catatan
                        _buildOptionCard(
                          icon: Icons.feed_outlined,
                          iconColor: const Color(0xFFE58F00),
                          title: 'Lihat Detail Penuh & Screenshot',
                          subtitle:
                              'Bukti poster loker, catatan pelamar, dan riwayat',
                          onTap: () =>
                              _showFullDetailsSheet(context, currentJob),
                        ),

                        const SizedBox(height: 10),

                        // Option 5: Unggah / Ubah Foto Logo Perusahaan
                        _buildOptionCard(
                          icon: Icons.camera_alt_rounded,
                          iconColor: const Color(0xFF5C44E4),
                          title: 'Ubah / Unggah Foto Perusahaan',
                          subtitle: currentJob.companyLogoPath != null
                              ? 'Foto kustom terpasang (ketuk untuk ganti)'
                              : 'Pilih foto logo atau kantor dari galeri HP',
                          onTap: () => _pickCompanyLogo(currentJob),
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
                                icon: const Icon(Icons.edit_outlined, size: 15),
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
                    (isDark ? const Color(0xFF121214) : const Color(0xFFFBF8F2))
                        .withValues(alpha: 0.0),
                    (isDark ? const Color(0xFF121214) : const Color(0xFFFBF8F2))
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
                  label: const Text(
                    'Perbarui Status Lamaran',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.2,
                    ),
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
    );
  }

  List<String> _getQualificationsList(JobApplication job) {
    final raw = job.jobDescription;
    if (raw.isEmpty) {
      return const ['Kualifikasi belum dicantumkan pada lamaran ini.'];
    }

    final lines = raw.split('\n').where((l) => l.trim().isNotEmpty).toList();
    final quals = <String>[];
    for (final l in lines) {
      final clean = l.replaceAll(RegExp(r'^[•\-\*\d\.\s]+'), '').trim();
      if (clean.toLowerCase().contains('lulusan') ||
          clean.toLowerCase().contains('pengalaman') ||
          clean.toLowerCase().contains('menguasai') ||
          clean.toLowerCase().contains('memiliki') ||
          clean.toLowerCase().contains('keahlian') ||
          clean.toLowerCase().contains('pendidikan') ||
          clean.toLowerCase().contains('kualifikasi') ||
          clean.toLowerCase().contains('skill') ||
          clean.toLowerCase().contains('syarat')) {
        quals.add(clean);
      }
    }

    if (quals.isNotEmpty) return quals;

    return const [
      'Kualifikasi belum dapat dipisahkan dari deskripsi asli. Buka tab Deskripsi untuk membaca teks lengkap.',
    ];
  }

  List<String> _getJobResponsibilitiesList(JobApplication job) {
    final raw = job.jobDescription;
    if (raw.isEmpty) {
      return const ['Deskripsi pekerjaan belum dicantumkan pada lamaran ini.'];
    }

    final lines = raw.split('\n').where((l) => l.trim().isNotEmpty).toList();
    final resps = <String>[];
    for (final l in lines) {
      final clean = l.replaceAll(RegExp(r'^[•\-\*\d\.\s]+'), '').trim();
      if (clean.toLowerCase().contains('mengembangkan') ||
          clean.toLowerCase().contains('merancang') ||
          clean.toLowerCase().contains('membuat') ||
          clean.toLowerCase().contains('mengelola') ||
          clean.toLowerCase().contains('bertanggung') ||
          clean.toLowerCase().contains('berkolaborasi') ||
          clean.toLowerCase().contains('melakukan') ||
          clean.toLowerCase().contains('tugas') ||
          clean.toLowerCase().contains('tanggung jawab')) {
        resps.add(clean);
      }
    }

    if (resps.isNotEmpty) return resps;

    return lines
        .map((line) => line.replaceAll(RegExp(r'^[•\-\*\d\.\s]+'), '').trim())
        .where((line) => line.isNotEmpty)
        .toList();
  }

  List<String> _getBenefitsList(JobApplication job) {
    final lines = job.jobDescription
        .split('\n')
        .map((line) => line.replaceAll(RegExp(r'^[•\-\*\d\.\s]+'), '').trim())
        .where((line) => line.isNotEmpty);
    const keywords = [
      'benefit',
      'fasilitas',
      'tunjangan',
      'bpjs',
      'bonus',
      'cuti',
      'asuransi',
      'allowance',
      'insurance',
      'leave',
      'training',
    ];
    final benefits = lines
        .where((line) {
          final normalized = line.toLowerCase();
          return keywords.any(normalized.contains);
        })
        .toSet()
        .toList();

    if (benefits.isNotEmpty) return benefits;
    return const ['Informasi benefit belum dicantumkan pada lowongan ini.'];
  }

  Widget _buildInteractiveInfoChip({
    required int index,
    required double availableWidth,
    required Widget iconWidget,
    required String shortText,
    required String fullText,
  }) {
    final isExpanded = _expandedInfoChipIndex == index;
    final anyExpanded = _expandedInfoChipIndex != null;
    final isCompact = anyExpanded && !isExpanded;
    final isDark = AppTheme.isDark(context);
    const compactWidth = 50.0;
    const totalSpacing = 16.0;
    final equalWidth = (availableWidth - totalSpacing) / 3;
    final expandedWidth = availableWidth - totalSpacing - (compactWidth * 2);
    final targetWidth = anyExpanded
        ? (isExpanded ? expandedWidth : compactWidth)
        : equalWidth;

    return Semantics(
      button: true,
      selected: isExpanded,
      label: '$fullText. Ketuk untuk ${isExpanded ? 'tutup' : 'buka'} detail.',
      child: Tooltip(
        message: fullText,
        child: GestureDetector(
          onTap: () {
            HapticFeedback.selectionClick();
            setState(() {
              if (_expandedInfoChipIndex == index) {
                _expandedInfoChipIndex = null;
              } else {
                _expandedInfoChipIndex = index;
              }
            });
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOutCubicEmphasized,
            width: targetWidth,
            height: compactWidth,
            padding: EdgeInsets.symmetric(horizontal: isCompact ? 0 : 14),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF242428) : Colors.white,
              borderRadius: BorderRadius.circular(compactWidth / 2),
              border: Border.all(
                color: isExpanded
                    ? const Color(0xFFB9A7F3)
                    : (isDark
                          ? const Color(0xFF383842)
                          : const Color(0xFFE5E0D5)),
              ),
              boxShadow: [
                BoxShadow(
                  color: isExpanded
                      ? const Color(0xFF5C44E4).withValues(alpha: 0.12)
                      : Colors.black.withValues(alpha: isDark ? 0.18 : 0.04),
                  blurRadius: isExpanded ? 12 : 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                iconWidget,
                if (!isCompact) ...[
                  const SizedBox(width: 9),
                  Flexible(
                    child: Text(
                      isExpanded ? fullText : shortText,
                      style: TextStyle(
                        fontSize: isExpanded ? 12.5 : 12,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : const Color(0xFF121214),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTabItem(int index, String label, IconData icon) {
    final isSelected = _selectedTab == index;
    final isDark = AppTheme.isDark(context);
    final activeColor = switch (index) {
      0 => const Color(0xFFFFE39A),
      1 => const Color(0xFFDCCEF8),
      _ => const Color(0xFFCDECCF),
    };
    return Expanded(
      child: FluidBounceButton(
        semanticLabel: 'Tampilkan $label',
        selected: isSelected,
        onTap: () {
          if (_selectedTab != index) setState(() => _selectedTab = index);
        },
        scaleFactor: 0.97,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 240),
          curve: Curves.easeOutCubic,
          constraints: const BoxConstraints(minHeight: 48),
          decoration: BoxDecoration(
            color: isSelected
                ? (isDark ? activeColor.withValues(alpha: 0.22) : Colors.white)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(15),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(
                        alpha: isDark ? 0.16 : 0.07,
                      ),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 15,
                color: isSelected
                    ? (isDark ? activeColor : const Color(0xFF252529))
                    : (isDark ? Colors.white54 : const Color(0xFF77777C)),
              ),
              const SizedBox(width: 5),
              Flexible(
                child: Text(
                  label,
                  maxLines: 2,
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    height: 1.1,
                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                    color: isSelected
                        ? (isDark ? Colors.white : const Color(0xFF252529))
                        : (isDark ? Colors.white60 : const Color(0xFF68686D)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailSectionCard(JobApplication job, bool isDark) {
    final items = switch (_selectedTab) {
      0 => _getQualificationsList(job),
      1 => _getJobResponsibilitiesList(job),
      _ => _getBenefitsList(job),
    };
    final title = switch (_selectedTab) {
      0 => 'Kualifikasi minimum',
      1 => 'Deskripsi pekerjaan',
      _ => 'Benefit & fasilitas',
    };
    final subtitle = switch (_selectedTab) {
      0 => 'Hal penting yang perlu kamu siapkan',
      1 => 'Tanggung jawab utama posisi ini',
      _ => 'Fasilitas yang tercantum di lowongan',
    };
    final icon = switch (_selectedTab) {
      0 => Icons.verified_outlined,
      1 => Icons.subject_rounded,
      _ => Icons.redeem_outlined,
    };
    final accent = switch (_selectedTab) {
      0 => const Color(0xFFF1B82D),
      1 => const Color(0xFF7257D9),
      _ => const Color(0xFF2E8B57),
    };

    return Container(
      key: ValueKey(_selectedTab),
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 19, 20, 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E24) : Colors.white,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(
          color: accent.withValues(alpha: isDark ? 0.28 : 0.22),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.18 : 0.055),
            blurRadius: 18,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: isDark ? 0.18 : 0.12),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(icon, size: 19, color: accent),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        color: isDark ? Colors.white : const Color(0xFF19191B),
                        letterSpacing: -0.25,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 11.5,
                        color: isDark
                            ? const Color(0xFFA8A8AF)
                            : const Color(0xFF747478),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          Divider(
            height: 1,
            color: isDark
                ? Colors.white.withValues(alpha: 0.08)
                : const Color(0xFFEDE9E1),
          ),
          const SizedBox(height: 14),
          ...List.generate(
            items.length,
            (index) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    margin: const EdgeInsets.only(top: 1),
                    decoration: BoxDecoration(
                      color: accent,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 11),
                  Expanded(
                    child: Text(
                      items[index],
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w500,
                        color: isDark
                            ? const Color(0xFFE7E7EA)
                            : const Color(0xFF343438),
                        height: 1.46,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
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
          borderRadius: BorderRadius.circular(20),
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
                    maxLines: 1,
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
                      borderRadius: BorderRadius.circular(10),
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
                    borderRadius: BorderRadius.circular(10),
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
}
