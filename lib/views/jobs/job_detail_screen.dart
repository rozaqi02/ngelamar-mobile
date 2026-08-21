import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/job_application.dart';
import '../../providers/job_provider.dart';
import '../../services/followup_service.dart';
import '../../services/notification_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/apple_animations.dart';
import '../../widgets/apple_sheet_window.dart';
import '../../widgets/apple_toast.dart';
import '../../widgets/company_logo_badge.dart';
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

  int _selectedTab = 0; // 0: Kualifikasi Minimum, 1: Deskripsi Pekerjaan, 2: Benefit & Fasilitas
  double _scrollOffset = 0.0;
  int? _expandedInfoChipIndex; // 0: Gaji, 1: Tipe Kerja, 2: Status/Pengalaman (Expandable on click)

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
      TweenSequenceItem(tween: Tween<double>(begin: 1.0, end: 1.45).chain(CurveTween(curve: Curves.easeOutBack)), weight: 50),
      TweenSequenceItem(tween: Tween<double>(begin: 1.45, end: 1.0).chain(CurveTween(curve: Curves.elasticOut)), weight: 50),
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
    final salary = currentJob.salaryOffered != null ? '\n💰 Gaji: ${currentJob.salaryOffered}' : '';
    final loc = currentJob.location != null ? '\n📍 Lokasi: ${currentJob.location}' : '';
    final url = currentJob.jobUrl != null ? '\n🔗 Link: ${currentJob.jobUrl}' : '';
    final date = '📅 Dilamar: ${currentJob.appliedDate.day}/${currentJob.appliedDate.month}/${currentJob.appliedDate.year}';
    final status = '📊 Status: ${currentJob.status} (${currentJob.workType})';

    final text = '📄 *Lowongan Kerja - Ngelamar App*\n'
        '🏢 *${currentJob.companyName}*\n'
        '💼 Posisi: ${currentJob.position}'
        '$loc'
        '$salary\n'
        '$status\n'
        '$date'
        '$url\n\n'
        'Dicatat via Ngelamar App';

    Share.share(text, subject: 'Lowongan: ${currentJob.position} di ${currentJob.companyName}');
  }

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

  void _pickCompanyLogo(JobApplication currentJob) async {
    HapticFeedback.selectionClick();
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 600,
      maxHeight: 600,
      imageQuality: 85,
    );
    if (image != null && mounted) {
      final updated = currentJob.copyWith(companyLogoPath: image.path);
      await ref.read(jobProvider.notifier).updateJob(updated);
      if (mounted) {
        AppleToast.success(context, 'Foto perusahaan berhasil diubah!');
      }
    }
  }

  void _deleteJob(JobApplication currentJob) async {
    HapticFeedback.heavyImpact();
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Hapus Lamaran?', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text(
          'Apakah Anda yakin ingin menghapus data lamaran di ${currentJob.companyName} (${currentJob.position})?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE53935),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: const Text('Hapus', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      await ref.read(jobProvider.notifier).deleteJob(currentJob.id);
      if (mounted) {
        Navigator.pop(context);
        AppleToast.success(context, 'Lamaran di ${currentJob.companyName} dihapus.');
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
                child: Image.file(File(path)),
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
                  child: const Icon(Icons.close_rounded, color: Colors.white, size: 24),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _advanceStage(JobApplication currentJob) async {
    HapticFeedback.heavyImpact();
    final next = await ref.read(jobProvider.notifier).advanceToNextStage(currentJob.id);
    if (next != null && mounted) {
      if (next == 'Offering' || next == 'Diterima') {
        AppleToast.success(
          context,
          'SELAMAT! Tahap $next',
          subtitle: 'Perjuanganmu di ${currentJob.companyName} membuahkan hasil!',
        );
      } else {
        AppleToast.success(
          context,
          'Tahapan dinaikkan ke $next',
          subtitle: 'Tetap semangat mempersiapkan tahap selanjutnya!',
        );
      }
    }
  }

  void _openOriginalUrl(String? url) async {
    if (url == null || url.trim().isEmpty) {
      AppleToast.info(context, 'Tautan lowongan tidak tersedia');
      return;
    }
    try {
      final uri = Uri.parse(url.trim());
      if (await canLaunchUrl(uri)) {
        final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
        if (!launched) {
          await launchUrl(uri, mode: LaunchMode.platformDefault);
        }
      } else {
        if (mounted) {
          AppleToast.error(context, 'Tidak dapat membuka tautan eksternal');
        }
      }
    } catch (_) {
      if (mounted) {
        AppleToast.error(context, 'Format tautan web tidak valid');
      }
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
                    side: BorderSide.none,
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
                          const Text(
                            'Follow-Up HR Cerdas',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF121214),
                              letterSpacing: -0.4,
                            ),
                          ),
                          Text(
                            'Templat pesan profesional untuk ${currentJob.companyName}',
                            style: const TextStyle(fontSize: 12.5, color: Color(0xFF707074)),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 22, color: Color(0xFF121214)),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: Color(0xFFE6E0D5)),
              Expanded(
                child: ListView.separated(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
                  itemCount: templates.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 14),
                  itemBuilder: (context, idx) {
                    final tpl = templates[idx];
                    return Container(
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
                              Text(
                                tpl.title,
                                style: const TextStyle(
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF121214),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: tpl.type == FollowupType.whatsapp
                                      ? const Color(0xFFE8F9EE)
                                      : const Color(0xFFF3EEFF),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  tpl.type == FollowupType.whatsapp ? 'WhatsApp' : 'Email',
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
                              color: const Color(0xFFF9F7F2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              tpl.body,
                              style: const TextStyle(fontSize: 12.5, height: 1.45, color: Color(0xFF333336)),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () {
                                    Clipboard.setData(ClipboardData(text: tpl.body));
                                    AppleToast.success(context, 'Pesan disalin ke clipboard');
                                  },
                                  icon: const Icon(Icons.copy_rounded, size: 15),
                                  label: const Text('Salin Pesan'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF19191B),
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                    padding: const EdgeInsets.symmetric(vertical: 10),
                                  ),
                                ),
                              ),
                              if (currentJob.hrContact != null && currentJob.hrContact!.isNotEmpty) ...[
                                const SizedBox(width: 8),
                                ElevatedButton.icon(
                                  onPressed: () async {
                                    final contact = currentJob.hrContact!;
                                    if (tpl.type == FollowupType.whatsapp) {
                                      final cleanNum = contact.replaceAll(RegExp(r'[^0-9+]'), '');
                                      final encoded = Uri.encodeComponent(tpl.body);
                                      final uri = Uri.parse('https://wa.me/$cleanNum?text=$encoded');
                                      try { await launchUrl(uri, mode: LaunchMode.externalApplication); } catch (_) {}
                                    } else {
                                      final encodedSubject = Uri.encodeComponent(tpl.title);
                                      final encodedBody = Uri.encodeComponent(tpl.body);
                                      final uri = Uri.parse('mailto:$contact?subject=$encodedSubject&body=$encodedBody');
                                      try { await launchUrl(uri, mode: LaunchMode.externalApplication); } catch (_) {}
                                    }
                                  },
                                  icon: Icon(tpl.type == FollowupType.whatsapp ? Icons.chat_rounded : Icons.send_rounded, size: 15),
                                  label: Text(tpl.type == FollowupType.whatsapp ? 'Kirim WA' : 'Kirim Email'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: tpl.type == FollowupType.whatsapp ? const Color(0xFF25D366) : const Color(0xFF5C44E4),
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
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
                      icon: const Icon(Icons.close_rounded, size: 22, color: Color(0xFF121214)),
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
                            badgeColor: AppTheme.getStatusColor(currentJob.status),
                          ),
                          const Divider(height: 20, color: Color(0xFFF0ECE3)),
                          _buildDetailRow(
                            icon: Icons.payments_rounded,
                            label: 'Tawaran Gaji',
                            value: currentJob.salaryOffered ?? 'Tidak dicantumkan',
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
                            value: currentJob.location ?? 'Jakarta / Remote',
                          ),
                          const Divider(height: 20, color: Color(0xFFF0ECE3)),
                          _buildDetailRow(
                            icon: Icons.calendar_today_rounded,
                            label: 'Tanggal Melamar',
                            value: '${currentJob.appliedDate.day}/${currentJob.appliedDate.month}/${currentJob.appliedDate.year}',
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
                              Icon(Icons.contact_phone_rounded, size: 18, color: Color(0xFF5C44E4)),
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
                            currentJob.hrContact != null && currentJob.hrContact!.isNotEmpty
                                ? currentJob.hrContact!
                                : 'Belum ada kontak HR yang disimpan.',
                            style: const TextStyle(fontSize: 13, color: Color(0xFF333336)),
                          ),
                          if (currentJob.hrContact != null && currentJob.hrContact!.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                ElevatedButton.icon(
                                  onPressed: () async {
                                    final contact = currentJob.hrContact!;
                                    if (contact.contains('@')) {
                                      final uri = Uri.parse('mailto:$contact');
                                      try { await launchUrl(uri, mode: LaunchMode.externalApplication); } catch (_) {}
                                    } else {
                                      final cleanNum = contact.replaceAll(RegExp(r'[^0-9+]'), '');
                                      final uri = Uri.parse('https://wa.me/$cleanNum');
                                      try { await launchUrl(uri, mode: LaunchMode.externalApplication); } catch (_) {}
                                    }
                                  },
                                  icon: const Icon(Icons.send_rounded, size: 14),
                                  label: Text(currentJob.hrContact!.contains('@') ? 'Kirim Email' : 'Hubungi via WhatsApp'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF25D366),
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                  ),
                                ),
                                OutlinedButton.icon(
                                  onPressed: () {
                                    Clipboard.setData(ClipboardData(text: currentJob.hrContact!));
                                    AppleToast.success(context, 'Kontak HR disalin');
                                  },
                                  icon: const Icon(Icons.copy_rounded, size: 14),
                                  label: const Text('Salin Kontak'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: const Color(0xFF121214),
                                    side: const BorderSide(color: Color(0xFFDCD8CE)),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (currentJob.screenshotPath != null && currentJob.screenshotPath!.isNotEmpty) ...[
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
                                    Icon(Icons.photo_library_rounded, size: 18, color: Color(0xFF5C44E4)),
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
                                  onPressed: () => _openScreenshotViewer(currentJob.screenshotPath!),
                                  child: const Text('Perbesar', style: TextStyle(fontWeight: FontWeight.bold)),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            GestureDetector(
                              onTap: () => _openScreenshotViewer(currentJob.screenshotPath!),
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
                    if (currentJob.notes != null && currentJob.notes!.isNotEmpty) ...[
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
                                Icon(Icons.note_alt_rounded, size: 18, color: Color(0xFF5C44E4)),
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
                              style: const TextStyle(fontSize: 13, color: Color(0xFF333336), height: 1.4),
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
          style: const TextStyle(fontSize: 13, color: Color(0xFF707074), fontWeight: FontWeight.w500),
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
              style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: badgeColor),
            ),
          )
        else
          Text(
            value,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF121214)),
          ),
      ],
    );
  }

  List<Color> _getStatusGradients(String status) {
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
          Color(0xFFFCD34D),
          Color(0xFFFDE68A),
          Color(0xFFFFFBEB),
          Color(0xFFFBF8F2),
        ];
      case 'Interview HR':
      case 'Interview User':
      case 'Interview':
        return const [
          Color(0xFFC4B5FD),
          Color(0xFFDDD6FE),
          Color(0xFFF5F3FF),
          Color(0xFFFBF8F2),
        ];
      case 'Tes / Psikotes':
        return const [
          Color(0xFFA5B4FC),
          Color(0xFFC7D2FE),
          Color(0xFFEEF2FF),
          Color(0xFFFBF8F2),
        ];
      case 'Ditolak':
        return const [
          Color(0xFFFDA4AF),
          Color(0xFFFECDD3),
          Color(0xFFFFF1F2),
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
    final jobs = ref.watch(jobProvider).jobs;
    final currentJob = jobs.firstWhere(
      (j) => j.id == widget.job.id,
      orElse: () => widget.job,
    );

    final canAdvance = currentJob.status != 'Offering' &&
        currentJob.status != 'Diterima' &&
        currentJob.status != 'Ditolak';

    final salaryText = currentJob.salaryOffered != null && currentJob.salaryOffered!.isNotEmpty
        ? currentJob.salaryOffered!
        : 'Gaji Menarik';

    final locationText = currentJob.location != null && currentJob.location!.isNotEmpty
        ? currentJob.location!
        : 'Jakarta, Indonesia';

    final experienceText = currentJob.status == 'Diterima'
        ? 'Diterima'
        : (currentJob.jobSource ?? 'Full-Time');

    // Scroll animation factor (0.0 to 1.0)
    final scrollRatio = (_scrollOffset / 160.0).clamp(0.0, 1.0);
    final logoSize = 64.0 - (scrollRatio * 18.0); // Shrinks from 64 to 46

    return Scaffold(
      backgroundColor: const Color(0xFFFBF8F2),
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
                  colors: _getStatusGradients(currentJob.status),
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
                        // Circular Back Button with Fluid Bounce
                        FluidBounceButton(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.06),
                                  blurRadius: 10,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: const Center(
                              child: Icon(
                                CupertinoIcons.chevron_back,
                                size: 20,
                                color: Color(0xFF121214),
                              ),
                            ),
                          ),
                        ),

                        // Center Company Logo Badge with scroll shrink animation
                        Hero(
                          tag: 'company_logo_${currentJob.id}',
                          flightShuttleBuilder: (flightContext, animation, flightDirection, fromHeroContext, toHeroContext) {
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
                        GestureDetector(
                          onTap: () {
                            HapticFeedback.heavyImpact();
                            _bookmarkAnimController.forward(from: 0.0);
                            ref.read(jobProvider.notifier).toggleFavorite(currentJob.id);
                            AppleToast.success(
                              context,
                              currentJob.isFavorite ? 'Dihapus dari Bookmark' : 'Disimpan ke Bookmark',
                              subtitle: currentJob.companyName,
                            );
                          },
                          child: ScaleTransition(
                            scale: _bookmarkScaleAnim,
                            child: Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: currentJob.isFavorite ? const Color(0xFF19191B) : Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: currentJob.isFavorite
                                        ? const Color(0xFF19191B).withValues(alpha: 0.35)
                                        : Colors.black.withValues(alpha: 0.06),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Center(
                                child: Icon(
                                  currentJob.isFavorite ? CupertinoIcons.bookmark_fill : CupertinoIcons.bookmark,
                                  size: 20,
                                  color: currentJob.isFavorite ? const Color(0xFFFFD54F) : const Color(0xFF121214),
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
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF121214),
                            letterSpacing: -0.8,
                          ),
                          textAlign: TextAlign.center,
                        ),

                        const SizedBox(height: 10),

                        // Role / Position Pill (Clean NO OUTLINE)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.85),
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.04),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Text(
                            currentJob.position,
                            style: const TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF121214),
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),

                        const SizedBox(height: 10),

                        // Location Row (Clickable to open in Google Maps / Apple Maps)
                        GestureDetector(
                          onTap: () async {
                            HapticFeedback.selectionClick();
                            final loc = currentJob.location ?? 'Jakarta, Indonesia';
                            final Uri mapUri;
                            if (loc.startsWith('http://') || loc.startsWith('https://')) {
                              mapUri = Uri.parse(loc);
                            } else {
                              mapUri = Uri.parse('https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(loc)}');
                            }
                            try {
                              await launchUrl(mapUri, mode: LaunchMode.externalApplication);
                            } catch (_) {
                              if (context.mounted) {
                                AppleToast.info(context, 'Tidak dapat membuka aplikasi peta');
                              }
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFF19191B).withValues(alpha: 0.06),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.location_on_rounded,
                                  size: 15,
                                  color: Color(0xFFE53935),
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  locationText,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF121214),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Icon(
                                  Icons.open_in_new_rounded,
                                  size: 12,
                                  color: Color(0xFF77777A),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 18),

                        // ── 3 HORIZONTAL KEY INFO CHIPS (INTERACTIVE EXPANDABLE ON CLICK) ──
                        Row(
                          children: [
                            // 1. Gaji (Expandable)
                            _buildInteractiveInfoChip(
                              index: 0,
                              iconWidget: Container(
                                width: 30,
                                height: 30,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF19191B),
                                  shape: BoxShape.circle,
                                ),
                                child: const Center(
                                  child: Text(
                                    'S',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w900,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ),
                              shortText: salaryText,
                              fullText: currentJob.salaryOffered != null && currentJob.salaryOffered!.isNotEmpty
                                  ? currentJob.salaryOffered!
                                  : 'Gaji Kompetitif',
                            ),
                            const SizedBox(width: 8),

                            // 2. Tipe Kerja (Expandable)
                            _buildInteractiveInfoChip(
                              index: 1,
                              iconWidget: Container(
                                width: 30,
                                height: 30,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF3EEFF),
                                  shape: BoxShape.circle,
                                  border: Border.all(color: const Color(0xFFD6C8F8)),
                                ),
                                child: const Center(
                                  child: Icon(Icons.access_time_rounded, size: 16, color: Color(0xFF5C44E4)),
                                ),
                              ),
                              shortText: currentJob.workType == 'WFO' ? 'On-Site' : currentJob.workType,
                              fullText: currentJob.workType == 'WFO'
                                  ? 'Mode: On-Site (WFO)'
                                  : (currentJob.workType == 'WFH' ? 'Mode: Remote (WFH)' : 'Mode: Hybrid (Fleksibel)'),
                            ),
                            const SizedBox(width: 8),

                            // 3. Status / Pengalaman (Expandable)
                            _buildInteractiveInfoChip(
                              index: 2,
                              iconWidget: Container(
                                width: 30,
                                height: 30,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE8F9EE),
                                  shape: BoxShape.circle,
                                  border: Border.all(color: const Color(0xFFB7E4C7)),
                                ),
                                child: const Center(
                                  child: Icon(Icons.work_outline_rounded, size: 16, color: Color(0xFF1E8E3E)),
                                ),
                              ),
                              shortText: experienceText,
                              fullText: currentJob.status != 'Tersedia'
                                  ? 'Tahap: ${currentJob.status}'
                                  : 'Portal: ${currentJob.sourcePlatform}',
                            ),
                          ],
                        ),

                        const SizedBox(height: 18),
                        Divider(height: 1, color: Colors.black.withValues(alpha: 0.08)),
                      ],
                    ),
                  ),
                ),

                // ── TABBED CARD: KUALIFIKASI & DESKRIPSI (SCROLLABLE TAB BAR) ──
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 10),
                    child: Column(
                      children: [
                        // Tab Selector (Scrollable so it never clips on narrow screens)
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _buildTabItem(0, 'Kualifikasi Minimum'),
                                const SizedBox(width: 8),
                                _buildTabItem(1, 'Deskripsi Kerja'),
                                const SizedBox(width: 8),
                                _buildTabItem(2, 'Benefit'),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 14),

                        // Pure White Card Container
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(22),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(28),
                            border: Border.all(color: const Color(0xFFE5E0D5), width: 1.3),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.04),
                                blurRadius: 16,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (_selectedTab == 0) ...[
                                // TAB 0: KUALIFIKASI MINIMUM (Syarat pendidikan, pengalaman, dan keahlian teknis)
                                ..._getQualificationsList(currentJob).map((item) => Padding(
                                      padding: const EdgeInsets.only(bottom: 12),
                                      child: Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Container(
                                            margin: const EdgeInsets.only(top: 3, right: 10),
                                            padding: const EdgeInsets.all(2),
                                            decoration: const BoxDecoration(
                                              color: Color(0xFF19191B),
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Icon(Icons.check, size: 10, color: Colors.white),
                                          ),
                                          Expanded(
                                            child: Text(
                                              item,
                                              style: const TextStyle(
                                                fontSize: 13.5,
                                                fontWeight: FontWeight.w600,
                                                color: Color(0xFF222226),
                                                height: 1.42,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    )),
                              ] else if (_selectedTab == 1) ...[
                                // TAB 1: DESKRIPSI KERJA (Tanggung jawab & ruang lingkup pekerjaan nyata)
                                ..._getJobResponsibilitiesList(currentJob).map((item) => Padding(
                                      padding: const EdgeInsets.only(bottom: 12),
                                      child: Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            '• ',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w900,
                                              color: Color(0xFF5C44E4),
                                            ),
                                          ),
                                          Expanded(
                                            child: Text(
                                              item,
                                              style: const TextStyle(
                                                fontSize: 13.5,
                                                fontWeight: FontWeight.w500,
                                                color: Color(0xFF333338),
                                                height: 1.45,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    )),
                              ] else ...[
                                _buildBenefitRow('BPJS Ketenagakerjaan & Kesehatan'),
                                _buildBenefitRow('Tunjangan Makan & Transportasi'),
                                _buildBenefitRow('Cuti Tahunan & Bonus Kinerja'),
                                _buildBenefitRow('Pengembangan Karir & Pelatihan Bersertifikat'),
                              ],
                            ],
                          ),
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
                          badgeColor: AppTheme.getStatusColor(currentJob.status),
                          heroTag: 'job_status_pill_${currentJob.id}',
                          onTap: () => _showStatusPicker(context, currentJob),
                        ),

                        const SizedBox(height: 10),

                        // Option 2: Panduan & Tips Interview
                        _buildOptionCard(
                          icon: Icons.psychology_rounded,
                          iconColor: const Color(0xFF19191B),
                          title: 'Panduan & Tips Interview',
                          subtitle: 'Cheat-sheet jawaban dan strategi wawancara',
                          onTap: () {
                            HapticFeedback.selectionClick();
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => InterviewStagesScreen(job: currentJob),
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
                          subtitle: currentJob.hrContact != null && currentJob.hrContact!.isNotEmpty
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
                          subtitle: 'Bukti poster loker, catatan pelamar, dan riwayat',
                          onTap: () => _showFullDetailsSheet(context, currentJob),
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

                        if (currentJob.jobUrl != null && currentJob.jobUrl!.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          _buildOptionCard(
                            icon: Icons.open_in_new_rounded,
                            iconColor: const Color(0xFF19191B),
                            title: 'Buka di Portal Asli',
                            subtitle: 'Kunjungi postingan resmi di ${currentJob.sourcePlatform}',
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
                                label: const Text('Edit Lamaran', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  foregroundColor: const Color(0xFF121214),
                                  backgroundColor: Colors.white,
                                  side: const BorderSide(color: Color(0xFFDCD8CE)),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            OutlinedButton.icon(
                              onPressed: () => _shareJob(currentJob),
                              icon: const Icon(Icons.share_outlined, size: 15, color: Color(0xFF5C44E4)),
                              label: const Text('Bagikan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF5C44E4))),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
                                backgroundColor: Colors.white,
                                side: const BorderSide(color: Color(0xFFD6C8F8)),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                              ),
                            ),
                            const SizedBox(width: 8),
                            OutlinedButton(
                              onPressed: () => _deleteJob(currentJob),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
                                backgroundColor: Colors.white,
                                side: const BorderSide(color: Color(0xFFFFCDD2)),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                              ),
                              child: const Icon(Icons.delete_outline_rounded, size: 18, color: Color(0xFFE53935)),
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

          // ── STICKY BOTTOM ACTION BUTTON (PERSIS MOCKUP) ──
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              padding: EdgeInsets.fromLTRB(20, 12, 20, MediaQuery.of(context).padding.bottom > 0 ? MediaQuery.of(context).padding.bottom + 12 : 24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    const Color(0xFFFBF8F2).withValues(alpha: 0.0),
                    const Color(0xFFFBF8F2).withValues(alpha: 0.95),
                    const Color(0xFFFBF8F2),
                  ],
                ),
              ),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () {
                    HapticFeedback.heavyImpact();
                    if (canAdvance) {
                      _advanceStage(currentJob);
                    } else {
                      _showStatusPicker(context, currentJob);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF19191B),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                    elevation: 8,
                    shadowColor: Colors.black.withValues(alpha: 0.35),
                  ),
                  child: Text(
                    canAdvance ? 'Naik ke Tahap Berikutnya' : 'Perbarui Status Lamaran',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
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


  List<String> _getQualificationsList(JobApplication job) {
    final raw = job.jobDescription;
    if (raw.isEmpty) {
      return [
        'Minimal lulusan D3 / S1 jurusan terkait atau pengalaman kerja setara.',
        'Memiliki pemahaman kuat mengenai dasar industri dan tools yang digunakan.',
        'Kemampuan komunikasi verbal dan tulisan yang baik serta proaktif.',
        'Mampu bekerja secara mandiri maupun berkolaborasi dalam tim agile.',
      ];
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

    // Fallback split
    if (lines.length >= 2) {
      return lines.take(lines.length ~/ 2 + 1).map((l) => l.replaceAll(RegExp(r'^[•\-\*\d\.\s]+'), '').trim()).toList();
    }

    return [
      'Pendidikan minimal Diploma (D3) / Sarjana (S1) atau sederajat.',
      'Pengalaman kerja minimal 1 tahun di bidang ${job.position}.',
      'Menguasai kompetensi utama dan problem-solving yang sistematis.',
      'Disiplin, bertanggung jawab, dan berorientasi pada target.',
    ];
  }

  List<String> _getJobResponsibilitiesList(JobApplication job) {
    final raw = job.jobDescription;
    if (raw.isEmpty) {
      return [
        'Merancang, mengembangkan, dan memelihara kebutuhan operasional pada posisi ${job.position}.',
        'Berkolaborasi erat dengan tim lintas fungsi untuk memastikan target perusahaan tercapai.',
        'Membuat dokumentasi teknis dan laporan evaluasi berkala secara terstruktur.',
        'Melakukan perbaikan berkelanjutan untuk efisiensi dan performa tim.',
      ];
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

    if (lines.length >= 2) {
      return lines.skip(lines.length ~/ 2).map((l) => l.replaceAll(RegExp(r'^[•\-\*\d\.\s]+'), '').trim()).toList();
    }

    return [
      'Menjalankan tugas utama dan tanggung jawab harian sebagai ${job.position} di ${job.companyName}.',
      'Memastikan kualitas dan ketepatan waktu pengiriman pekerjaan sesuai standar perusahaan.',
      'Berkoordinasi dengan rekan tim dalam sesi perencanaan dan review rutin.',
      'Mengidentifikasi kendala dan memberikan solusi inovatif secara proaktif.',
    ];
  }

  Widget _buildInteractiveInfoChip({
    required int index,
    required Widget iconWidget,
    required String shortText,
    required String fullText,
  }) {
    final isExpanded = _expandedInfoChipIndex == index;
    final anyExpanded = _expandedInfoChipIndex != null;

    return Expanded(
      flex: isExpanded ? 6 : (anyExpanded ? 1 : 2),
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
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOutCubic,
          padding: EdgeInsets.symmetric(
            horizontal: isExpanded ? 12 : (anyExpanded ? 4 : 10),
            vertical: 10,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: isExpanded
                    ? const Color(0xFF5C44E4).withValues(alpha: 0.14)
                    : Colors.black.withValues(alpha: 0.05),
                blurRadius: isExpanded ? 14 : 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              iconWidget,
              if (!anyExpanded || isExpanded) ...[
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    isExpanded ? fullText : shortText,
                    style: TextStyle(
                      fontSize: isExpanded ? 12.5 : 12,
                      fontWeight: FontWeight.w900,
                      color: const Color(0xFF121214),
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
    );
  }

  Widget _buildTabItem(int index, String label) {
    final isSelected = _selectedTab == index;
    return FluidBounceButton(
      onTap: () {
        setState(() => _selectedTab = index);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFFE8B2) : Colors.white.withValues(alpha: 0.85),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isSelected ? 0.08 : 0.03),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: isSelected ? FontWeight.w900 : FontWeight.w700,
            color: const Color(0xFF121214),
          ),
        ),
      ),
    );
  }

  Widget _buildBenefitRow(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          const Icon(Icons.check_circle_rounded, size: 18, color: Color(0xFF2E7D32)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                color: Color(0xFF333338),
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
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE5E0D5)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
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
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF121214),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 11.5, color: Color(0xFF707074)),
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
                  flightShuttleBuilder: (flightContext, animation, flightDirection, fromHeroContext, toHeroContext) {
                    return Material(
                      type: MaterialType.transparency,
                      child: toHeroContext.widget,
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
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
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
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
            const Icon(CupertinoIcons.chevron_right, size: 14, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}
