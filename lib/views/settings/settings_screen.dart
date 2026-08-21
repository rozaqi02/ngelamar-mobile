import 'dart:convert';
import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:share_plus/share_plus.dart';
import '../../providers/job_provider.dart';
import '../../services/prefs_service.dart';
import '../../widgets/apple_animations.dart';
import '../../widgets/app_dialog.dart';
import '../../widgets/apple_toast.dart';
import '../../widgets/app_toast.dart';
import '../subscription/subscription_screen.dart';

/// Screen 5: Profil & Pengaturan.
/// Mengadopsi tata letak modern sesuai foto referensi:
/// - Top Curved Pastel Lilac Banner dengan watermark dan tombol aksi melingkar
/// - Avatar profil melingkar yang tumpang-tindih (overlapping) di batas banner
/// - Nama pengguna & status karir
/// - 3 Kotak Ringkasan Info (Total Lamaran, Minat Karir, Status Akun)
/// - Kartu Kualifikasi & Kesiapan Karir dengan checklist rapi
/// - Ringkasan Akun & Opsi Pengaturan lengkap (PRO, Privasi, Ekspor, dll.)
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  static const String _appVersion = '2.1.0';
  static const String _buildNumber = '210';

  List<String> _userInterests = [];

  static const Map<String, List<String>> _categorizedInterests = {
    '💻 Lulusan IT & Software': [
      'Frontend Developer',
      'Mobile Developer (Flutter)',
      'Backend Engineer',
      'Fullstack Developer',
      'UI/UX Designer',
      'QA / Software Tester',
      'DevOps & Cloud',
      'Data Analyst / Scientist',
    ],
    '📊 Lulusan Manajemen & Bisnis': [
      'Product Manager',
      'Business Development (BD)',
      'Project Management',
      'Operations & Supply Chain',
      'Account Executive',
    ],
    '💰 Lulusan Keuangan & Akuntansi': [
      'Finance & Accounting',
      'Tax & Perpajakan',
      'Financial Analyst',
      'Internal Auditor',
    ],
    '📣 Lulusan Pemasaran & Media': [
      'Digital Marketing & SEO',
      'Social Media Specialist',
      'Content Creator / Writer',
      'Graphic Designer',
    ],
    '👥 Lulusan SDM & Psikologi': [
      'Human Resources (HR)',
      'Talent Acquisition / Recruiter',
      'Admin & General Affair',
      'Customer Relations / CS',
    ],
  };

  @override
  void initState() {
    super.initState();
    _loadUserInterests();
  }

  Future<void> _loadUserInterests() async {
    final list = await PrefsService.getUserInterests();
    if (mounted) {
      setState(() {
        _userInterests = list;
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _pickProfilePhoto() async {
    HapticFeedback.selectionClick();
    try {
      final XFile? picked = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 600,
        maxHeight: 600,
        imageQuality: 85,
      );
      if (picked != null) {
        await ref.read(jobProvider.notifier).setUserProfilePhoto(picked.path);
        if (mounted) {
          AppleToast.success(context, 'Foto profil berhasil diperbarui!');
        }
      }
    } catch (e) {
      if (mounted) {
        AppleToast.error(context, 'Gagal memilih gambar: $e');
      }
    }
  }

  void _showEditProfileDialog() {
    _nameController.text = ref.read(jobProvider).userName;
    _emailController.text = ref.read(jobProvider).userEmail;

    AppDialog.show(
      context: context,
      icon: Icons.person_outline_rounded,
      iconColor: const Color(0xFF5C44E4),
      title: 'Edit Informasi Profil',
      content: 'Perbarui nama dan email profil pencari kerja Anda:',
      secondaryLabel: 'Batal',
      primaryLabel: 'Simpan',
      customBody: Column(
        children: [
          TextField(
            controller: _nameController,
            decoration: InputDecoration(
              hintText: 'Nama Lengkap...',
              prefixIcon: const Icon(Icons.badge_outlined, size: 20),
              filled: true,
              fillColor: const Color(0xFFF9F7F2),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: Color(0xFFE5E0D5)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: Color(0xFFE5E0D5)),
              ),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              hintText: 'Alamat Email (opsional)...',
              prefixIcon: const Icon(Icons.mail_outline_rounded, size: 20),
              filled: true,
              fillColor: const Color(0xFFF9F7F2),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: Color(0xFFE5E0D5)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: Color(0xFFE5E0D5)),
              ),
            ),
          ),
        ],
      ),
      onPrimary: () async {
        final newName = _nameController.text.trim();
        final newEmail = _emailController.text.trim();
        if (newName.isNotEmpty) {
          await ref.read(jobProvider.notifier).setUserName(newName);
        }
        await ref.read(jobProvider.notifier).setUserEmail(newEmail);
        if (mounted) {
          Navigator.pop(context);
          AppToast.success(context, 'Profil berhasil diperbarui!');
        }
      },
    );
  }

  void _showCareerInterestsSheet() {
    HapticFeedback.selectionClick();
    final tempInterests = List<String>.from(_userInterests);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (sheetContext, setModalState) {
          return Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.85,
            ),
            padding: const EdgeInsets.fromLTRB(22, 16, 22, 24),
            decoration: const BoxDecoration(
              color: Color(0xFFFBF8F2),
              borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 44,
                    height: 5,
                    decoration: BoxDecoration(
                      color: const Color(0xFFD5CEBF),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Target & Minat Karir',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF121214),
                    letterSpacing: -0.4,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Pilih posisi yang kamu minati berdasarkan keahlian:',
                  style: TextStyle(fontSize: 13, color: Color(0xFF707074)),
                ),
                const SizedBox(height: 14),
                Flexible(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: _categorizedInterests.entries.map((category) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                category.key,
                                style: const TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF121214),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: category.value.map((interest) {
                                  final isSelected = tempInterests.contains(interest);
                                  return FilterChip(
                                    selected: isSelected,
                                    label: Text(interest),
                                    labelStyle: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: isSelected ? Colors.white : const Color(0xFF121214),
                                    ),
                                    selectedColor: const Color(0xFF19191B),
                                    backgroundColor: Colors.white,
                                    side: BorderSide(
                                      color: isSelected ? const Color(0xFF19191B) : const Color(0xFFE5E0D5),
                                    ),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                    onSelected: (val) {
                                      setModalState(() {
                                        if (val) {
                                          tempInterests.add(interest);
                                        } else {
                                          tempInterests.remove(interest);
                                        }
                                      });
                                    },
                                  );
                                }).toList(),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: () async {
                      final nav = Navigator.of(ctx);
                      await PrefsService.setUserInterests(tempInterests);
                      if (!mounted) return;
                      setState(() {
                        _userInterests = tempInterests;
                      });
                      nav.pop();
                      AppleToast.success(context, 'Minat karir berhasil disimpan');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF19191B),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
                    ),
                    child: const Text(
                      'Simpan Pilihan',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _exportApplicationsData() async {
    HapticFeedback.mediumImpact();
    final state = ref.read(jobProvider);
    if (!state.isProUser) {
      final upgrade = await AppDialog.show<bool>(
        context: context,
        icon: Icons.stars_rounded,
        iconColor: const Color(0xFFF59E0B),
        title: 'Fitur Eksklusif Ngelamar PRO ✨',
        content:
            'Ekspor data lamaran kerja ke format JSON/Spreadsheet adalah fitur khusus member PRO. Upgrade sekarang untuk backup data Anda kapan saja!',
        secondaryLabel: 'Nanti Saja',
        primaryLabel: 'Lihat PRO',
      );
      if (upgrade == true && mounted) {
        Navigator.push(context, CupertinoPageRoute(builder: (_) => const SubscriptionScreen()));
      }
      return;
    }

    if (state.jobs.isEmpty) {
      AppToast.info(context, 'Belum ada data lamaran untuk diekspor.');
      return;
    }

    final backupPayload = {
      'schemaVersion': 2,
      'appVersion': '2.1.0+210',
      'exportedAt': DateTime.now().toIso8601String(),
      'totalCount': state.jobs.length,
      'jobs': state.jobs.map((j) => j.toJson()).toList(),
    };

    final jsonString = const JsonEncoder.withIndent('  ').convert(backupPayload);

    await Share.share(
      jsonString,
      subject: 'Backup_Ngelamar_v2_${DateTime.now().year}.json',
    );
    if (mounted) {
      AppToast.success(context, 'Backup data (JSON v2) berhasil dibuat!');
    }
  }

  Future<void> _clearAllData() async {
    final confirm = await AppDialog.show<bool>(
      context: context,
      icon: Icons.delete_outline_rounded,
      iconColor: const Color(0xFFE53935),
      title: 'Hapus Seluruh Data Lamaran?',
      content:
          'Semua catatan lamaran kerja, riwayat interview, dan screenshot bukti akan dihapus secara permanen dari perangkat.',
      secondaryLabel: 'Batal',
      primaryLabel: 'Hapus Semua',
      isDestructive: true,
    );
    if (confirm == true) {
      await ref.read(jobProvider.notifier).clearAllJobs();
      if (mounted) AppToast.success(context, 'Semua data lamaran telah dibersihkan.');
    }
  }

  void _showPrivacyPolicyModal() {
    HapticFeedback.selectionClick();
    final bottomInset = MediaQuery.of(context).padding.bottom;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        padding: EdgeInsets.fromLTRB(24, 20, 24, bottomInset > 0 ? bottomInset + 16 : 24),
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
            const SizedBox(height: 18),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF5C44E4).withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(CupertinoIcons.lock_shield_fill, color: Color(0xFF5C44E4), size: 22),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Kebijakan Privasi & Data',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF121214)),
                      ),
                      Text(
                        'Offline-First & Keamanan Data Pengguna',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 20, color: Color(0xFF121214)),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFBF8F2),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFE5E0D5)),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '🔒 100% Data Tersimpan Lokal',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5, color: Color(0xFF121214)),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Seluruh catatan lamaran kerja, besaran gaji, tanggal interview, foto screenshot, dan identitas Anda tersimpan secara eksklusif di database internal perangkat (Hive).',
                    style: TextStyle(fontSize: 12, color: Color(0xFF555558), height: 1.4),
                  ),
                  SizedBox(height: 12),
                  Text(
                    '🛡️ Tanpa Tracking & Tanpa Iklan Pihak Ketiga',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5, color: Color(0xFF121214)),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Ngelamar tidak mengumpulkan, menjual, atau mentransfer data pribadi Anda ke server analitik pihak ketiga manapun.',
                    style: TextStyle(fontSize: 12, color: Color(0xFF555558), height: 1.4),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF19191B),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                ),
                child: const Text('Mengerti', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAboutAppModal() {
    HapticFeedback.selectionClick();
    final bottomInset = MediaQuery.of(context).padding.bottom;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        padding: EdgeInsets.fromLTRB(24, 20, 24, bottomInset > 0 ? bottomInset + 16 : 24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(height: 18),
            Container(
              width: 68,
              height: 68,
              decoration: BoxDecoration(
                color: const Color(0xFF19191B),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.asset(
                  'ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-1024x1024@1x.png',
                  width: 68,
                  height: 68,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    color: const Color(0xFF19191B),
                    child: const Center(
                      child: Icon(Icons.mail_rounded, color: Color(0xFFF59E0B), size: 36),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Ngelamar Mobile',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF121214)),
            ),
            const Text(
              'Versi 2.1.0 (Build 210) • Production Ready',
              style: TextStyle(fontSize: 12, color: Color(0xFF5C44E4), fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            const Text(
              'Asisten pelacak lamaran kerja modern dan persiapan karir all-in-one untuk pencari kerja dan fresh graduate di Indonesia.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12.5, color: Color(0xFF555558), height: 1.45),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF9F7F2),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE5E0D5)),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(Icons.email_outlined, size: 16, color: Color(0xFF5C44E4)),
                      const SizedBox(width: 8),
                      const Text(
                        'Email Bantuan:',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF121214)),
                      ),
                      const Spacer(),
                      Text(
                        'support@ngelamar.id',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey.shade700),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.chat_bubble_outline_rounded, size: 16, color: Color(0xFF25D366)),
                      const SizedBox(width: 8),
                      const Text(
                        'WhatsApp Resmi:',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF121214)),
                      ),
                      const Spacer(),
                      Text(
                        '+62 831-3604-9987',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey.shade700),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF19191B),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                ),
                child: const Text('Tutup', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showQuickActionsMenu() {
    HapticFeedback.selectionClick();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Opsi Pengaturan',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF121214)),
            ),
            const SizedBox(height: 14),
            _buildActionItem(
              icon: CupertinoIcons.person_crop_circle,
              title: 'Edit Profil',
              onTap: () {
                Navigator.pop(ctx);
                _showEditProfileDialog();
              },
            ),
            _buildActionItem(
              icon: CupertinoIcons.briefcase,
              title: 'Atur Minat Karir',
              onTap: () {
                Navigator.pop(ctx);
                _showCareerInterestsSheet();
              },
            ),
            _buildActionItem(
              icon: CupertinoIcons.arrow_down_doc,
              title: 'Ekspor Data (Backup)',
              onTap: () {
                Navigator.pop(ctx);
                _exportApplicationsData();
              },
            ),
            _buildActionItem(
              icon: CupertinoIcons.lock_shield,
              title: 'Kebijakan Privasi',
              onTap: () {
                Navigator.pop(ctx);
                _showPrivacyPolicyModal();
              },
            ),
            _buildActionItem(
              icon: CupertinoIcons.info_circle,
              title: 'Tentang Aplikasi',
              onTap: () {
                Navigator.pop(ctx);
                _showAboutAppModal();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFF121214), size: 20),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
      trailing: const Icon(CupertinoIcons.chevron_right, size: 14, color: Colors.grey),
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(jobProvider);
    final hasPhoto = state.userProfilePhoto.isNotEmpty && File(state.userProfilePhoto).existsSync();
    final displayName = state.userName.isNotEmpty ? state.userName : 'Pencari Kerja';
    final topPadding = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: const Color(0xFFF7FAF7), // Clean subtle off-white
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ── TOP CURVED PASTEL BANNER WITH OVERLAPPING AVATAR (PERSIS MOCKUP FOTO) ──
          SliverToBoxAdapter(
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                // Curved Pastel Lilac Header Banner
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.fromLTRB(20, topPadding + 10, 20, 52),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFFE8D5FF), // Soft pastel purple from mockup
                        Color(0xFFF3E8FF),
                      ],
                    ),
                    borderRadius: BorderRadius.vertical(
                      bottom: Radius.circular(38),
                    ),
                  ),
                  child: Stack(
                    children: [
                      // Large Faint Watermark Text in Banner
                      Positioned(
                        right: -10,
                        top: -15,
                        child: Text(
                          'PROFIL',
                          style: TextStyle(
                            fontSize: 70,
                            fontWeight: FontWeight.w900,
                            color: Colors.white.withValues(alpha: 0.35),
                            letterSpacing: -2,
                          ),
                        ),
                      ),

                      // Banner Action Buttons & Title
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Left Circular Button (Back if canPop, else Info)
                          FluidBounceButton(
                            onTap: () {
                              if (Navigator.canPop(context)) {
                                Navigator.pop(context);
                              } else {
                                _showAboutAppModal();
                              }
                            },
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
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Center(
                                child: Icon(
                                  Navigator.canPop(context)
                                      ? CupertinoIcons.chevron_back
                                      : CupertinoIcons.info,
                                  size: 18,
                                  color: const Color(0xFF121214),
                                ),
                              ),
                            ),
                          ),

                          // Center Screen Title
                          const Text(
                            'Profil & Pengaturan',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF121214),
                              letterSpacing: -0.3,
                            ),
                          ),

                          // Right Circular 3-Dots Button
                          FluidBounceButton(
                            onTap: _showQuickActionsMenu,
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
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: const Center(
                                child: Icon(
                                  CupertinoIcons.ellipsis_vertical,
                                  size: 18,
                                  color: Color(0xFF121214),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Central Overlapping Profile Avatar Badge (Persis Mockup Foto)
                Positioned(
                  bottom: -36,
                  child: GestureDetector(
                    onTap: _pickProfilePhoto,
                    child: Stack(
                      children: [
                        Hero(
                          tag: 'user_profile_avatar_hero',
                          flightShuttleBuilder: (flightContext, animation, flightDirection, fromHeroContext, toHeroContext) {
                            return Material(
                              type: MaterialType.transparency,
                              child: toHeroContext.widget,
                            );
                          },
                          child: Container(
                            width: 78,
                            height: 78,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 4),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.12),
                                  blurRadius: 14,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: ClipOval(
                              child: hasPhoto
                                  ? Image.file(
                                      File(state.userProfilePhoto),
                                      width: 78,
                                      height: 78,
                                      fit: BoxFit.cover,
                                    )
                                  : Container(
                                      color: const Color(0xFF19191B),
                                      child: const Center(
                                        child: Icon(
                                          CupertinoIcons.person_fill,
                                          color: Colors.white,
                                          size: 38,
                                        ),
                                      ),
                                    ),
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 2,
                          right: 2,
                          child: Container(
                            padding: const EdgeInsets.all(5),
                            decoration: const BoxDecoration(
                              color: Color(0xFF5C44E4),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.camera_alt_rounded,
                              color: Colors.white,
                              size: 12,
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

          // ── USER NAME & STATUS HEADLINE ──
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 46, 20, 0),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        displayName,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF121214),
                          letterSpacing: -0.6,
                        ),
                      ),
                      const SizedBox(width: 6),
                      GestureDetector(
                        onTap: _showEditProfileDialog,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.05),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(CupertinoIcons.pencil, size: 14, color: Color(0xFF5C44E4)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    state.userEmail.isNotEmpty
                        ? state.userEmail
                        : 'Pencari Karir Pro • ${state.isProUser ? 'Member PRO ✨' : 'Akun Standar'}',
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF707074),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── 3 INFO SUMMARY CARDS (PERSIS MOCKUP: SALARY, JOB TIME, LOCATION) ──
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Row(
                children: [
                  // Card 1: Total Lamaran
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.03),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          const Text(
                            'Lamaran',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF88888D),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${state.totalCount}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF121214),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),

                  // Card 2: Minat Karir
                  Expanded(
                    child: GestureDetector(
                      onTap: _showCareerInterestsSheet,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.03),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            const Text(
                              'Minat Karir',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF88888D),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _userInterests.isNotEmpty ? '${_userInterests.length} Bidang' : 'Pilih',
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF5C44E4),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),

                  // Card 3: Status Akun
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        Navigator.push(context, CupertinoPageRoute(builder: (_) => const SubscriptionScreen()));
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.03),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            const Text(
                              'Status Akun',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF88888D),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              state.isProUser ? 'PRO ✨' : 'Aktif',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w900,
                                color: state.isProUser ? const Color(0xFFF59E0B) : const Color(0xFF1E8E3E),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── KUALIFIKASI & KESIAPAN KARIR (PERSIS KARTU "QUALIFICATIONS" DI MOCKUP) ──
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 12,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Row: Briefcase Icon + Title + Atur Action
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: const Color(0xFF5C44E4).withValues(alpha: 0.10),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(CupertinoIcons.briefcase, size: 18, color: Color(0xFF5C44E4)),
                            ),
                            const SizedBox(width: 10),
                            const Text(
                              'Kesiapan & Minat Karir',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF121214),
                                letterSpacing: -0.3,
                              ),
                            ),
                          ],
                        ),
                        GestureDetector(
                          onTap: _showCareerInterestsSheet,
                          child: const Text(
                            'Atur >',
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF5C44E4),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Checkmarked Item 1: Minat Karir
                    _buildCheckmarkItem(
                      _userInterests.isNotEmpty
                          ? 'Minat: ${_userInterests.take(2).join(", ")}${_userInterests.length > 2 ? " +${_userInterests.length - 2} lainnya" : ""}'
                          : 'Belum memilih bidang minat karir (Ketuk untuk atur)',
                    ),
                    const SizedBox(height: 10),

                    // Checkmarked Item 2: Offline-First & Keamanan
                    _buildCheckmarkItem('Database 100% Offline & Tersimpan di Perangkat'),
                    const SizedBox(height: 10),

                    // Checkmarked Item 3: Notifikasi Jadwal
                    _buildCheckmarkItem('Pengingat Jadwal & Notifikasi H-1 Interview Siap'),
                    const SizedBox(height: 10),

                    // Checkmarked Item 4: Backup Data
                    _buildCheckmarkItem('Fitur Backup & Ekspor Data Lamaran Siap Digunakan'),
                  ],
                ),
              ),
            ),
          ),

          // ── RINGKASAN AKUN & PENGATURAN LENGKAP (PERSIS "JOB OVERVIEW" SECTION) ──
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(22, 22, 22, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Ringkasan Akun & Preferensi',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF121214),
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Kelola preferensi akun, paket langganan, dan keamanan data lamaran Anda.',
                    style: TextStyle(
                      fontSize: 12.5,
                      color: Color(0xFF707074),
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── SETTINGS MENU TILES ──
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // 1. PRO Banner Card
                if (state.isProUser)
                  Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF19191B),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.workspace_premium_rounded, color: Color(0xFFF59E0B), size: 24),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Member PRO Aktif ✨',
                                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 13.5),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Akses tak terbatas ekspor & fitur eksklusif',
                                style: TextStyle(color: Colors.grey, fontSize: 11),
                              ),
                            ],
                          ),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.push(context, CupertinoPageRoute(builder: (_) => const SubscriptionScreen()));
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFF59E0B),
                            foregroundColor: const Color(0xFF19191B),
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          ),
                          child: const Text('Kelola', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11.5)),
                        ),
                      ],
                    ),
                  )
                else
                  GestureDetector(
                    onTap: () {
                      Navigator.push(context, CupertinoPageRoute(builder: (_) => const SubscriptionScreen()));
                    },
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF5C44E4), Color(0xFF7B1FA2)],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF5C44E4).withValues(alpha: 0.25),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.workspace_premium_rounded, color: Colors.white, size: 20),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Upgrade ke Ngelamar PRO ✨',
                                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 13.5),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'Rp 10.000 / bln • Buka seluruh fitur',
                                  style: TextStyle(color: Color(0xFFEDE9FE), fontSize: 11),
                                ),
                              ],
                            ),
                          ),
                          const Icon(CupertinoIcons.chevron_right, color: Colors.white, size: 16),
                        ],
                      ),
                    ),
                  ),

                // 2. Settings Option Tiles Box
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Mode Gelap (Dark Mode OLED)
                      _buildSettingTile(
                        icon: state.isDarkMode ? CupertinoIcons.moon_stars_fill : CupertinoIcons.sun_max_fill,
                        color: state.isDarkMode ? const Color(0xFFA78BFA) : const Color(0xFFF59E0B),
                        title: 'Mode Gelap (Dark Mode OLED)',
                        subtitle: state.isProUser
                            ? (state.isDarkMode ? 'Tema Gelap Premium Aktif 🌙' : 'Tema Terang Aktif ☀️')
                            : 'Fitur Eksklusif Ngelamar PRO ✨',
                        trailing: CupertinoSwitch(
                          value: state.isDarkMode,
                          activeTrackColor: const Color(0xFF5C44E4),
                          onChanged: (val) async {
                            HapticFeedback.selectionClick();
                            if (!state.isProUser) {
                              Navigator.push(context, CupertinoPageRoute(builder: (_) => const SubscriptionScreen()));
                              return;
                            }
                            await ref.read(jobProvider.notifier).toggleThemeMode();
                          },
                        ),
                        onTap: () async {
                          HapticFeedback.selectionClick();
                          if (!state.isProUser) {
                            Navigator.push(context, CupertinoPageRoute(builder: (_) => const SubscriptionScreen()));
                            return;
                          }
                          await ref.read(jobProvider.notifier).toggleThemeMode();
                        },
                      ),
                      const Divider(height: 1, indent: 16, endIndent: 16),

                      // Target & Minat Karir
                      _buildSettingTile(
                        icon: CupertinoIcons.briefcase,
                        color: const Color(0xFF5C44E4),
                        title: 'Target & Minat Karir',
                        subtitle: _userInterests.isNotEmpty
                            ? '${_userInterests.length} bidang: ${_userInterests.first}'
                            : 'Atur posisi lowongan yang diminati',
                        onTap: _showCareerInterestsSheet,
                      ),
                      const Divider(height: 1, indent: 16, endIndent: 16),

                      // Ekspor Data Lamaran
                      _buildSettingTile(
                        icon: CupertinoIcons.arrow_down_doc_fill,
                        color: const Color(0xFF0A66C2),
                        title: 'Ekspor Data (Backup JSON v2)',
                        subtitle: state.isProUser ? 'Unduh seluruh riwayat lamaran' : 'Fitur Khusus Ngelamar PRO ✨',
                        onTap: _exportApplicationsData,
                      ),
                      const Divider(height: 1, indent: 16, endIndent: 16),

                      // Notifikasi Interview
                      _buildSettingTile(
                        icon: CupertinoIcons.bell_fill,
                        color: const Color(0xFFF59E0B),
                        title: 'Pengingat Jadwal Interview',
                        subtitle: 'Otomatis aktif H-1 & jam acara',
                        onTap: () {
                          AppleToast.info(context, 'Pengingat otomatis aktif saat ada jadwal interview.');
                        },
                      ),
                      const Divider(height: 1, indent: 16, endIndent: 16),

                      // Kebijakan Privasi
                      _buildSettingTile(
                        icon: CupertinoIcons.lock_shield_fill,
                        color: const Color(0xFF1E8E3E),
                        title: 'Keamanan & Privasi 100% Offline',
                        subtitle: 'Data hanya tersimpan di perangkat HP',
                        onTap: _showPrivacyPolicyModal,
                      ),
                      const Divider(height: 1, indent: 16, endIndent: 16),

                      // Tentang Aplikasi
                      _buildSettingTile(
                        icon: CupertinoIcons.info_circle_fill,
                        color: const Color(0xFF0288D1),
                        title: 'Tentang Aplikasi & Versi',
                        subtitle: 'Ngelamar v$_appVersion ($_buildNumber)',
                        onTap: _showAboutAppModal,
                      ),
                      const Divider(height: 1, indent: 16, endIndent: 16),

                      // Bersihkan Data
                      _buildSettingTile(
                        icon: CupertinoIcons.trash,
                        color: const Color(0xFFE53935),
                        title: 'Bersihkan Semua Data Lamaran',
                        subtitle: 'Hapus seluruh catatan dari penyimpanan',
                        onTap: _clearAllData,
                      ),
                    ],
                  ),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCheckmarkItem(String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            color: const Color(0xFF1E8E3E).withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: const Center(
            child: Icon(Icons.check_rounded, size: 13, color: Color(0xFF1E8E3E)),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF2D3748),
              height: 1.35,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSettingTile({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Widget? trailing,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      leading: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: color, size: 18),
      ),
      title: Text(
        title,
        style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, color: Color(0xFF121214)),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(fontSize: 11.5, color: Color(0xFF707074)),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: trailing ?? const Icon(CupertinoIcons.chevron_right, size: 14, color: Color(0xFFA0A0A5)),
      onTap: onTap,
    );
  }
}
