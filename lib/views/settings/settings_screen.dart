import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../providers/job_provider.dart';
import '../../services/prefs_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/apple_toast.dart';
import '../subscription/subscription_screen.dart';
import 'package:share_plus/share_plus.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  static const String _appVersion = '2.0.0';
  static const String _buildNumber = '200';

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

    showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('Edit Informasi Profil'),
        content: Padding(
          padding: const EdgeInsets.only(top: 12),
          child: Column(
            children: [
              CupertinoTextField(
                controller: _nameController,
                placeholder: 'Nama Lengkap...',
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
              const SizedBox(height: 10),
              CupertinoTextField(
                controller: _emailController,
                placeholder: 'Alamat Email (opsional)...',
                keyboardType: TextInputType.emailAddress,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
            ],
          ),
        ),
        actions: [
          CupertinoDialogAction(
            child: const Text('Batal'),
            onPressed: () => Navigator.pop(ctx),
          ),
          CupertinoDialogAction(
            child: const Text('Simpan'),
            onPressed: () async {
              final newName = _nameController.text.trim();
              final newEmail = _emailController.text.trim();
              if (newName.isNotEmpty) {
                await ref.read(jobProvider.notifier).setUserName(newName);
              }
              await ref.read(jobProvider.notifier).setUserEmail(newEmail);
              if (ctx.mounted) {
                Navigator.pop(ctx);
              }
              if (mounted) {
                AppleToast.success(context, 'Profil berhasil diperbarui!');
              }
            },
          ),
        ],
      ),
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
                  'Pilih posisi yang kamu minati berdasarkan jurusan atau keahlian:',
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
      final upgrade = await showCupertinoDialog<bool>(
        context: context,
        builder: (ctx) => CupertinoAlertDialog(
          title: const Text('Fitur Eksklusif Ngelamar PRO ✨'),
          content: const Text(
            'Ekspor data lamaran kerja ke format spreadsheet adalah fitur khusus member PRO. Upgrade sekarang hanya Rp 10.000 / bulan!',
          ),
          actions: [
            CupertinoDialogAction(
              child: const Text('Nanti Saja'),
              onPressed: () => Navigator.pop(ctx, false),
            ),
            CupertinoDialogAction(
              isDefaultAction: true,
              child: const Text('Lihat PRO'),
              onPressed: () => Navigator.pop(ctx, true),
            ),
          ],
        ),
      );
      if (upgrade == true && mounted) {
        Navigator.push(context, CupertinoPageRoute(builder: (_) => const SubscriptionScreen()));
      }
      return;
    }

    if (state.jobs.isEmpty) {
      AppleToast.info(context, 'Belum ada data lamaran untuk diekspor.');
      return;
    }

    final buffer = StringBuffer();
    buffer.writeln('ID,Perusahaan,Posisi,Status,Tipe Kerja,Lokasi,Gaji Ditawarkan,Tanggal Melamar,Kontak HR,Catatan');
    for (final j in state.jobs) {
      buffer.writeln('"${j.id}","${j.companyName}","${j.position}","${j.status}","${j.workType}","${j.location ?? '-'}","${j.salaryOffered ?? '-'}","${j.appliedDate.toIso8601String()}","${j.hrContact ?? '-'}","${(j.notes ?? '').replaceAll('\n', ' ')}"');
    }

    await Share.share(
      buffer.toString(),
      subject: 'Rekap_Lamaran_Ngelamar_${DateTime.now().year}.csv',
    );
    if (mounted) {
      AppleToast.success(context, 'Data lamaran berhasil diekspor!');
    }
  }

  Future<void> _clearAllData() async {
    final confirm = await showCupertinoDialog<bool>(
      context: context,
      builder: (_) => CupertinoAlertDialog(
        title: const Text('Hapus Seluruh Data Lamaran?'),
        content: const Text(
          'Semua catatan lamaran kerja, riwayat interview, dan screenshot bukti akan dihapus secara permanen dari perangkat.',
        ),
        actions: [
          CupertinoDialogAction(
            child: const Text('Batal'),
            onPressed: () => Navigator.pop(context, false),
          ),
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
      if (mounted) AppleToast.success(context, 'Semua data lamaran telah dibersihkan.');
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
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                image: const DecorationImage(
                  image: AssetImage('assets/images/app_icon.png'),
                  fit: BoxFit.cover,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.12),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Ngelamar Mobile',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF121214)),
            ),
            const Text(
              'Versi 2.0.0 (Build 200)',
              style: TextStyle(fontSize: 12, color: Color(0xFF5C44E4), fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 14),
            const Text(
              'Asisten pelacak lamaran kerja modern dan persiapan karir all-in-one untuk pencari kerja dan fresh graduate di Indonesia.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12.5, color: Color(0xFF555558), height: 1.45),
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
                child: const Text('Tutup', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              ),
            ),
          ],
        ),
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

    final hasPhoto = state.userProfilePhoto.isNotEmpty && File(state.userProfilePhoto).existsSync();
    final displayName = state.userName.isNotEmpty ? state.userName : 'Pencari Kerja';

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
              padding: EdgeInsets.fromLTRB(20, 0, 20, 120 + (MediaQuery.of(context).padding.bottom > 0 ? MediaQuery.of(context).padding.bottom : 0)),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // User Profile Hero Card
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFF19191B),
                      borderRadius: BorderRadius.circular(AppTheme.radiusCardLarge),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.16),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        // Avatar with Tap to Pick
                        GestureDetector(
                          onTap: _pickProfilePhoto,
                          child: Stack(
                            children: [
                              Container(
                                width: 58,
                                height: 58,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 2),
                                ),
                                child: ClipOval(
                                  child: hasPhoto
                                      ? Image.file(
                                          File(state.userProfilePhoto),
                                          width: 58,
                                          height: 58,
                                          fit: BoxFit.cover,
                                        )
                                      : const Center(
                                          child: Icon(
                                            CupertinoIcons.person_fill,
                                            color: Color(0xFF19191B),
                                            size: 32,
                                          ),
                                        ),
                                ),
                              ),
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF5C44E4),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.camera_alt_rounded,
                                    color: Colors.white,
                                    size: 11,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 14),

                        // Name & Status
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                displayName,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.3,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (state.userEmail.isNotEmpty) ...[
                                const SizedBox(height: 2),
                                Text(
                                  state.userEmail,
                                  style: TextStyle(color: Colors.grey.shade400, fontSize: 12.5),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ] else ...[
                                const SizedBox(height: 2),
                                Text(
                                  'Ketuk edit untuk isi email',
                                  style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                                ),
                              ],
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.16),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  '${state.totalCount} Lamaran Terlacak',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
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

                  // ── PRO SUBSCRIPTION STATUS BANNER ──
                  const SizedBox(height: 14),
                  if (state.isProUser)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF231C3D), Color(0xFF19191B)],
                        ),
                        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
                        border: Border.all(color: const Color(0xFFF59E0B), width: 1.2),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.12),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.workspace_premium_rounded, color: Color(0xFFF59E0B), size: 24),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Ngelamar PRO Member ✨',
                                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 13.5),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Semua fitur supercharger aktif (${state.proPlanType == "yearly" ? "Tahunan" : "Bulanan"})',
                                  style: TextStyle(color: Colors.grey.shade300, fontSize: 11),
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
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF5C44E4), Color(0xFF7B1FA2)],
                        ),
                        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF5C44E4).withValues(alpha: 0.28),
                            blurRadius: 12,
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
                            child: const Icon(Icons.workspace_premium_rounded, color: Colors.white, size: 22),
                          ),
                          const SizedBox(width: 14),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Upgrade ke Ngelamar PRO ✨', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 13.5)),
                                SizedBox(height: 2),
                                Text('Hanya Rp 10.000 / bln • Buka semua fitur', style: TextStyle(color: Color(0xFFEDE9FE), fontSize: 11, fontWeight: FontWeight.w500)),
                              ],
                            ),
                          ),
                          ElevatedButton(
                            onPressed: () {
                              Navigator.push(context, CupertinoPageRoute(builder: (_) => const SubscriptionScreen()));
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: const Color(0xFF5C44E4),
                              elevation: 0,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                            child: const Text('Upgrade', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12)),
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 20),

                  // Section 1: Preferensi Karir
                  _sectionHeader('PREFERENSI KARIR'),
                  Container(
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(AppTheme.radiusCard),
                      border: Border.all(color: const Color(0xFFE6E3D8)),
                    ),
                    child: Column(
                      children: [
                        _buildSettingTile(
                          icon: CupertinoIcons.briefcase,
                          color: AppTheme.cardPurple,
                          title: 'Minat & Target Posisi',
                          subtitle: _userInterests.isNotEmpty
                              ? '${_userInterests.length} bidang dipilih: ${_userInterests.first}...'
                              : 'Atur posisi lowongan yang kamu minati',
                          onTap: _showCareerInterestsSheet,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 18),

                  // Section 2: Notifikasi & Pengingat
                  _sectionHeader('NOTIFIKASI & PENGINGAT'),
                  Container(
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(AppTheme.radiusCard),
                      border: Border.all(color: const Color(0xFFE6E3D8)),
                    ),
                    child: Column(
                      children: [
                        _buildSettingTile(
                          icon: CupertinoIcons.bell,
                          color: AppTheme.cardYellow,
                          title: 'Alarm Jadwal Interview',
                          subtitle: 'Otomatis aktif: Pengingat H-1 (09:00) & Jam Acara',
                          onTap: () {
                            AppleToast.info(context, 'Pengingat interview otomatis dijadwalkan saat ada tanggal interview.');
                          },
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 18),

                  // Section 3: Privasi & Penyimpanan
                  _sectionHeader('KEAMANAN & PRIVASI'),
                  Container(
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(AppTheme.radiusCard),
                      border: Border.all(color: const Color(0xFFE6E3D8)),
                    ),
                    child: Column(
                      children: [
                        _buildSettingTile(
                          icon: CupertinoIcons.lock_shield,
                          color: AppTheme.cardGreen,
                          title: 'Penyimpanan Lokal 100% Offline',
                          subtitle: 'Data dan dokumen tersimpan aman hanya di HP kamu (Ketuk detail)',
                          onTap: _showPrivacyPolicyModal,
                        ),
                        Divider(height: 1, color: isDark ? const Color(0xFF2C2C30) : const Color(0xFFEFECE4)),
                        _buildSettingTile(
                          icon: CupertinoIcons.info_circle,
                          color: const Color(0xFF0288D1),
                          title: 'Tentang Aplikasi & Versi',
                          subtitle: 'Informasi rilis, tim developer & lisensi',
                          onTap: _showAboutAppModal,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 18),

                  // Section 4: Manajemen Data & Ekspor
                  _sectionHeader('MANAJEMEN DATA'),
                  Container(
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(AppTheme.radiusCard),
                      border: Border.all(color: const Color(0xFFE6E3D8)),
                    ),
                    child: Column(
                      children: [
                        _buildSettingTile(
                          icon: CupertinoIcons.arrow_down_doc_fill,
                          color: const Color(0xFF5C44E4),
                          title: 'Ekspor Riwayat Lamaran (Excel / CSV)',
                          subtitle: state.isProUser
                              ? 'Unduh seluruh riwayat catatan lamaran kerja'
                              : 'Fitur Khusus Ngelamar PRO ✨',
                          onTap: _exportApplicationsData,
                        ),
                        Divider(height: 1, color: isDark ? const Color(0xFF2C2C30) : const Color(0xFFEFECE4)),
                        _buildSettingTile(
                          icon: CupertinoIcons.trash,
                          color: AppTheme.systemRed,
                          title: 'Bersihkan Semua Data Lamaran',
                          subtitle: 'Menghapus seluruh catatan lamaran dari penyimpanan',
                          onTap: _clearAllData,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // App Info & Version with Clickable Modal
                  GestureDetector(
                    onTap: _showAboutAppModal,
                    child: Center(
                      child: Column(
                        children: [
                          Text(
                            'Ngelamar v$_appVersion ($_buildNumber)',
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Aplikasi Pelacak Lamaran Kerja Offline • idka-solutions',
                            style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                          ),
                        ],
                      ),
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
      title: Text(title, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold)),
      subtitle: Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
      trailing: const Icon(CupertinoIcons.chevron_right, size: 14, color: Colors.grey),
      onTap: onTap,
    );
  }
}
