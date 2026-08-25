import 'dart:async';
import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import '../../models/job_application.dart';
import '../../providers/job_provider.dart';
import '../../services/backup_service.dart';
import '../../services/cloud_sync_service.dart';
import '../../services/feedback_service.dart';
import '../../services/notification_service.dart';
import '../../services/prefs_service.dart';
import '../../services/supabase_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_dialog.dart';
import '../../widgets/app_toast.dart';
import '../../widgets/apple_animations.dart';
import '../../widgets/apple_toast.dart';
import '../../widgets/app_motion.dart';
import '../../widgets/app_layout_metrics.dart';
import '../../widgets/company_logo_badge.dart';
import '../../widgets/delight_celebration.dart';
import '../jobs/add_edit_job_screen.dart';
import '../jobs/job_detail_screen.dart';
import '../jobs/job_list_screen.dart';
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
  final _aboutController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  static const String _appVersion = '2.25.5';
  static const String _buildNumber = '242';

  List<String> _userInterests = [];
  bool? _notificationsEnabled;
  String _about = '';
  String? _cvPdfPath;
  AccountIdentity? _accountIdentity;
  bool _isAccountBusy = false;
  late final StreamSubscription<dynamic> _authSubscription;

  static const Map<String, List<String>> _categorizedInterests = {
    'Teknologi & Software': [
      'Frontend Developer',
      'Mobile Developer (Flutter)',
      'Backend Engineer',
      'Fullstack Developer',
      'UI/UX Designer',
      'QA / Software Tester',
      'DevOps & Cloud',
      'Data Analyst / Scientist',
    ],
    'Bisnis & Manajemen': [
      'Product Manager',
      'Business Development (BD)',
      'Project Management',
      'Operations & Supply Chain',
      'Account Executive',
    ],
    'Keuangan & Akuntansi': [
      'Finance & Accounting',
      'Tax & Perpajakan',
      'Financial Analyst',
      'Internal Auditor',
    ],
    'Pemasaran & Media': [
      'Digital Marketing & SEO',
      'Social Media Specialist',
      'Content Creator / Writer',
      'Graphic Designer',
    ],
    'SDM & Psikologi': [
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
    _loadAboutAndCv();
    _refreshNotificationStatus();
    _authSubscription = SupabaseService.client.auth.onAuthStateChange.listen((
      _,
    ) {
      _refreshCloudAccount();
    });
    _refreshCloudAccount();
  }

  Future<void> _loadAboutAndCv() async {
    final about = await PrefsService.getUserAbout();
    final cvPath = await PrefsService.getCvPdf();
    if (!mounted) return;
    setState(() {
      _about = about ?? '';
      _cvPdfPath = cvPath;
    });
  }

  Future<void> _refreshCloudAccount() async {
    try {
      await SupabaseService.ensureAuthenticated();
      if (mounted) {
        setState(() => _accountIdentity = SupabaseService.currentIdentity);
      }
      if (_hasCloudAccount) {
        await _restoreCloudProfileIfNeeded();
      }
    } catch (_) {
      // Local profile remains available when the device is offline.
    }
  }

  /// A cloud account should also work on a new device. Local values win when
  /// already present; missing preferences and a missing CV are restored safely.
  Future<void> _restoreCloudProfileIfNeeded() async {
    try {
      final cloud = await CloudSyncService.fetchPreferences();
      if (cloud != null) {
        final state = ref.read(jobProvider);
        final cloudName = cloud['name']?.toString().trim() ?? '';
        final cloudEmail = cloud['email']?.toString().trim() ?? '';
        final cloudAbout = cloud['about']?.toString() ?? '';
        final rawInterests = cloud['interests'];
        final cloudInterests = rawInterests is List
            ? rawInterests.map((item) => item.toString()).toList()
            : const <String>[];

        if (state.userName.isEmpty && cloudName.isNotEmpty) {
          await ref.read(jobProvider.notifier).setUserName(cloudName);
        }
        if (state.userEmail.isEmpty && cloudEmail.isNotEmpty) {
          await ref.read(jobProvider.notifier).setUserEmail(cloudEmail);
        }
        if (_about.isEmpty && cloudAbout.isNotEmpty) {
          await PrefsService.setUserAbout(cloudAbout);
        }
        if (_userInterests.isEmpty && cloudInterests.isNotEmpty) {
          await PrefsService.setUserInterests(cloudInterests);
        }
        if (mounted) {
          setState(() {
            if (_about.isEmpty) _about = cloudAbout;
            if (_userInterests.isEmpty) _userInterests = cloudInterests;
          });
        }
      }

      final localCv = _cvPdfPath;
      if (localCv == null || localCv.isEmpty || !await File(localCv).exists()) {
        final bytes = await CloudSyncService.downloadCv();
        if (bytes != null) {
          final directory = await getApplicationDocumentsDirectory();
          final destination = File('${directory.path}/cv/cv_cloud.pdf');
          await destination.parent.create(recursive: true);
          await destination.writeAsBytes(bytes, flush: true);
          await PrefsService.setCvPdf(destination.path);
          if (mounted) setState(() => _cvPdfPath = destination.path);
        }
      }
    } catch (_) {
      // Cloud restoration is opportunistic and must not block the local profile.
    }
  }

  Future<void> _refreshNotificationStatus() async {
    final enabled = await NotificationService.areNotificationsEnabled();
    if (mounted) setState(() => _notificationsEnabled = enabled);
  }

  Future<void> _handleThemeToggle(JobState state) async {
    HapticFeedback.selectionClick();
    if (!state.isProUser) {
      AppleToast.info(context, 'Mode gelap tersedia untuk Member PRO.');
      await Navigator.push(
        context,
        CupertinoPageRoute(builder: (_) => const SubscriptionScreen()),
      );
      return;
    }
    await ref.read(jobProvider.notifier).toggleThemeMode();
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
    _authSubscription.cancel();
    _nameController.dispose();
    _emailController.dispose();
    _aboutController.dispose();
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
    final isDark = AppTheme.isDark(context);
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
            style: TextStyle(
              color: isDark ? Colors.white : const Color(0xFF121214),
            ),
            decoration: InputDecoration(
              hintText: 'Nama Lengkap...',
              hintStyle: TextStyle(
                color: isDark ? const Color(0xFF8E8E93) : Colors.grey,
              ),
              prefixIcon: Icon(
                Icons.badge_outlined,
                size: 20,
                color: isDark
                    ? const Color(0xFFA0A0A8)
                    : const Color(0xFF707074),
              ),
              filled: true,
              fillColor: isDark
                  ? const Color(0xFF282830)
                  : const Color(0xFFF9F7F2),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 12,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: isDark
                      ? const Color(0xFF383842)
                      : const Color(0xFFE5E0D5),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: isDark
                      ? const Color(0xFF383842)
                      : const Color(0xFFE5E0D5),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            style: TextStyle(
              color: isDark ? Colors.white : const Color(0xFF121214),
            ),
            decoration: InputDecoration(
              hintText: 'Alamat Email (opsional)...',
              hintStyle: TextStyle(
                color: isDark ? const Color(0xFF8E8E93) : Colors.grey,
              ),
              prefixIcon: Icon(
                Icons.mail_outline_rounded,
                size: 20,
                color: isDark
                    ? const Color(0xFFA0A0A8)
                    : const Color(0xFF707074),
              ),
              filled: true,
              fillColor: isDark
                  ? const Color(0xFF282830)
                  : const Color(0xFFF9F7F2),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 12,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: isDark
                      ? const Color(0xFF383842)
                      : const Color(0xFFE5E0D5),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: isDark
                      ? const Color(0xFF383842)
                      : const Color(0xFFE5E0D5),
                ),
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
        await _syncPreferencesToCloud();
        if (mounted) {
          Navigator.pop(context);
          DelightCelebration.show(
            context,
            message: 'Profilmu makin siap dilirik!',
            accent: const Color(0xFF5C44E4),
            icon: Icons.person_rounded,
            preset: DelightPreset.profile,
          );
          AppToast.success(context, 'Profil berhasil diperbarui!');
        }
      },
    );
  }

  void _showCareerInterestsSheet() {
    HapticFeedback.selectionClick();
    final tempInterests = List<String>.from(_userInterests);
    final isDark = AppTheme.isDark(context);
    final sheetBg = isDark ? const Color(0xFF1A1A1F) : const Color(0xFFFBF8F2);
    final primary = isDark ? Colors.white : const Color(0xFF121214);
    final secondary = isDark
        ? const Color(0xFFA0A0A8)
        : const Color(0xFF707074);

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
            decoration: BoxDecoration(
              color: sheetBg,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(32),
              ),
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
                Text(
                  'Target & Minat Karir',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: primary,
                    letterSpacing: -0.4,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Pilih posisi yang kamu minati berdasarkan keahlian:',
                  style: TextStyle(fontSize: 13, color: secondary),
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
                                style: TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w800,
                                  color: primary,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: category.value.map((interest) {
                                  final isSelected = tempInterests.contains(
                                    interest,
                                  );
                                  return FilterChip(
                                    selected: isSelected,
                                    showCheckmark: false,
                                    label: Text(interest),
                                    labelStyle: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: isSelected
                                          ? Colors.white
                                          : primary,
                                    ),
                                    selectedColor: const Color(0xFF19191B),
                                    backgroundColor: isDark
                                        ? const Color(0xFF29292F)
                                        : Colors.white,
                                    side: BorderSide(
                                      color: isSelected
                                          ? const Color(0xFF19191B)
                                          : (isDark
                                                ? const Color(0xFF3B3B42)
                                                : const Color(0xFFE5E0D5)),
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
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
                      await _syncPreferencesToCloud();
                      if (!mounted) return;
                      nav.pop();
                      AppleToast.success(
                        context,
                        'Minat karir berhasil disimpan',
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF19191B),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(26),
                      ),
                    ),
                    child: const Text(
                      'Simpan Pilihan',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
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

  void _showEditAboutDialog() {
    final isDark = AppTheme.isDark(context);
    _aboutController.text = _about;
    _aboutController.selection = TextSelection.fromPosition(
      TextPosition(offset: _aboutController.text.length),
    );
    AppDialog.show(
      context: context,
      icon: Icons.edit_note_rounded,
      iconColor: const Color(0xFF5C44E4),
      title: 'Tentang Saya',
      content: 'Tulis ringkasan singkat yang ingin ditampilkan di profil Anda.',
      secondaryLabel: 'Batal',
      primaryLabel: 'Simpan',
      customBody: TextField(
        controller: _aboutController,
        maxLines: 5,
        maxLength: 500,
        textCapitalization: TextCapitalization.sentences,
        decoration: InputDecoration(
          hintText:
              'Contoh: Mobile developer yang senang memecahkan masalah...',
          filled: true,
          fillColor: isDark ? const Color(0xFF282830) : const Color(0xFFF9F7F2),
          alignLabelWithHint: true,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(
              color: isDark ? const Color(0xFF3A3A42) : const Color(0xFFE5E0D5),
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(
              color: isDark ? const Color(0xFF3A3A42) : const Color(0xFFE5E0D5),
            ),
          ),
        ),
      ),
      onPrimary: () async {
        final value = _aboutController.text.trim();
        await PrefsService.setUserAbout(value);
        if (!mounted) return;
        setState(() => _about = value);
        await _syncPreferencesToCloud();
        if (!mounted) return;
        Navigator.pop(context);
        AppleToast.success(context, 'Tentang saya berhasil diperbarui');
      },
    );
  }

  Future<void> _pickCvPdf() async {
    HapticFeedback.selectionClick();
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['pdf'],
        withData: kIsWeb,
      );
      if (result == null || result.files.isEmpty) return;
      final selected = result.files.single;
      final appDir = await getApplicationDocumentsDirectory();
      final profileDir = Directory('${appDir.path}/profile');
      await profileDir.create(recursive: true);
      final destination = File('${profileDir.path}/cv.pdf');
      if (selected.bytes != null) {
        await destination.writeAsBytes(selected.bytes!, flush: true);
      } else if (selected.path != null) {
        await File(selected.path!).copy(destination.path);
      } else {
        throw const FileSystemException('Berkas CV tidak dapat dibaca');
      }
      await PrefsService.setCvPdf(destination.path);
      var uploadedToCloud = false;
      if (_accountIdentity != null && !_accountIdentity!.isAnonymous) {
        try {
          await CloudSyncService.uploadCv(destination);
          uploadedToCloud = true;
        } catch (_) {
          // Salinan lokal tetap sah; pengguna tidak boleh kehilangan CV hanya
          // karena jaringan atau Storage cloud sedang tidak tersedia.
        }
      }
      if (!mounted) return;
      setState(() => _cvPdfPath = destination.path);
      DelightCelebration.show(
        context,
        message: 'CV berhasil dipasang!',
        accent: const Color(0xFF3884F5),
        icon: Icons.picture_as_pdf_rounded,
        preset: DelightPreset.cv,
      );
      AppleToast.success(
        context,
        uploadedToCloud
            ? 'CV tersimpan di perangkat dan cloud.'
            : 'CV PDF berhasil disimpan di profil.',
      );
    } catch (_) {
      if (mounted) AppleToast.error(context, 'CV PDF belum dapat disimpan.');
    }
  }

  Future<void> _openCvPdf() async {
    HapticFeedback.selectionClick();
    var path = _cvPdfPath;
    if (path == null || path.isEmpty || !await File(path).exists()) {
      await _pickCvPdf();
      path = _cvPdfPath;
    }
    if (!mounted || path == null || path.isEmpty) return;
    final result = await OpenFilex.open(path, type: 'application/pdf');
    if (result.type != ResultType.done && mounted) {
      AppleToast.info(
        context,
        'Tidak ada pembaca PDF. Pilih aplikasi untuk membuka CV.',
      );
      await Share.shareXFiles([XFile(path)], subject: 'CV Saya');
    }
  }

  bool get _hasCloudAccount =>
      _accountIdentity != null && !_accountIdentity!.isAnonymous;

  Future<void> _connectGoogleAccount() async {
    if (_isAccountBusy) return;
    setState(() => _isAccountBusy = true);
    try {
      final launched = await SupabaseService.connectGoogle();
      if (mounted) {
        AppToast.info(
          context,
          launched
              ? 'Lanjutkan masuk dengan Google di browser, lalu kembali ke aplikasi.'
              : 'Browser login Google belum dapat dibuka.',
        );
      }
    } catch (_) {
      if (mounted) {
        AppToast.error(
          context,
          'Login Google belum tersedia. Periksa konfigurasi OAuth.',
        );
      }
    } finally {
      if (mounted) setState(() => _isAccountBusy = false);
    }
  }

  Future<void> _syncPreferencesToCloud() async {
    if (!_hasCloudAccount) return;
    try {
      await CloudSyncService.syncPreferences({
        'name': ref.read(jobProvider).userName,
        'email': ref.read(jobProvider).userEmail,
        'about': _about,
        'interests': _userInterests,
      });
    } catch (_) {
      // Preferences stay local and will be retried on a later edit.
    }
  }

  Future<void> _uploadCloudBackup() async {
    if (!_hasCloudAccount) {
      final proceed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            'Hubungkan Akun Google',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: const Text(
            'Untuk mencadangkan data lamaran ke cloud secara aman, silakan hubungkan akun Google Anda terlebih dahulu.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4285F4),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Masuk Google'),
            ),
          ],
        ),
      );
      if (proceed == true) {
        await _connectGoogleAccount();
      }
      return;
    }
    final state = ref.read(jobProvider);
    if (state.jobs.isEmpty) {
      AppToast.info(context, 'Belum ada data lamaran untuk dicadangkan.');
      return;
    }
    final password = await _requestBackupPassword(isRestoring: false);
    if (password == null || !mounted) return;

    File? temporaryBackup;
    try {
      final temporaryDirectory = await getTemporaryDirectory();
      temporaryBackup = await BackupService.createBackup(
        state.jobs,
        password: password,
        outputDirectory: temporaryDirectory,
      );
      await CloudSyncService.uploadEncryptedBackup(
        temporaryBackup,
        appVersion: _appVersion,
      );
      if (mounted) {
        AppToast.success(
          context,
          'Backup terenkripsi berhasil disimpan ke cloud.',
        );
      }
    } on BackupException catch (error) {
      if (mounted) AppToast.error(context, error.message);
    } catch (e) {
      debugPrint('Upload cloud backup error: $e');
      if (mounted) {
        AppToast.error(
          context,
          'Backup cloud belum dapat disimpan. Periksa koneksi internet.',
        );
      }
    } finally {
      if (temporaryBackup != null && await temporaryBackup.exists()) {
        await temporaryBackup.delete();
      }
    }
  }

  Future<void> _restoreCloudBackup() async {
    if (!_hasCloudAccount) {
      final proceed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            'Hubungkan Akun Google',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: const Text(
            'Untuk memulihkan data backup dari cloud, silakan hubungkan akun Google yang Anda gunakan untuk mencadangkan sebelumnya.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4285F4),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Masuk Google'),
            ),
          ],
        ),
      );
      if (proceed == true) {
        await _connectGoogleAccount();
      }
      return;
    }
    try {
      final backups = await CloudSyncService.listBackups();
      if (!mounted) return;
      if (backups.isEmpty) {
        AppToast.info(context, 'Belum ada backup cloud pada akun ini.');
        return;
      }
      final isDark = AppTheme.isDark(context);
      final sheetBg = isDark ? const Color(0xFF1E1E24) : Colors.white;
      final txtPri = isDark ? Colors.white : const Color(0xFF121214);
      final txtSec = isDark ? const Color(0xFFA0A0A8) : const Color(0xFF707074);

      final selected = await showModalBottomSheet<CloudBackupInfo>(
        context: context,
        backgroundColor: Colors.transparent,
        builder: (sheetContext) => Container(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 30),
          decoration: BoxDecoration(
            color: sheetBg,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 38,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF383842)
                      : const Color(0xFFD7D1C7),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'Pilih Backup Cloud',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: txtPri,
                ),
              ),
              const SizedBox(height: 8),
              ...backups.map(
                (backup) => ListTile(
                  leading: const Icon(
                    CupertinoIcons.cloud_download_fill,
                    color: Color(0xFF5C44E4),
                  ),
                  title: Text(
                    DateFormat(
                      'd MMM y • HH:mm',
                      'id_ID',
                    ).format(backup.createdAt.toLocal()),
                    style: TextStyle(
                      color: txtPri,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  subtitle: Text(
                    '${(backup.bytes / 1024 / 1024).toStringAsFixed(1)} MB • v${backup.appVersion}',
                    style: TextStyle(color: txtSec),
                  ),
                  trailing: Icon(
                    CupertinoIcons.chevron_right,
                    size: 14,
                    color: txtSec,
                  ),
                  onTap: () => Navigator.pop(sheetContext, backup),
                ),
              ),
            ],
          ),
        ),
      );
      if (selected == null || !mounted) return;
      final password = await _requestBackupPassword(isRestoring: true);
      if (password == null || !mounted) return;
      final bytes = await CloudSyncService.downloadBackup(selected);
      final payload = await BackupService.restoreFromBytes(
        bytes,
        password: password,
      );
      final importResult = await ref
          .read(jobProvider.notifier)
          .importJobs(payload.jobs);
      await ref
          .read(jobProvider.notifier)
          .discardUnreferencedAttachments(payload.extractedAttachmentPaths);
      if (mounted) {
        AppToast.success(
          context,
          '${importResult.importedCount} lamaran dipulihkan dari cloud.',
        );
      }
    } on BackupException catch (error) {
      if (mounted) AppToast.error(context, error.message);
    } catch (_) {
      if (mounted) {
        AppToast.error(context, 'Backup cloud belum dapat dipulihkan.');
      }
    }
  }

  Future<void> _showFeedbackDialog() async {
    final sent = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _FeedbackDialog(appVersion: _appVersion),
    );
    if (sent == true && mounted) {
      AppToast.success(context, 'Masukan berhasil dikirim. Terima kasih!');
    }
  }

  Future<void> _exportApplicationsData() async {
    HapticFeedback.mediumImpact();
    final state = ref.read(jobProvider);
    if (state.jobs.isEmpty) {
      AppToast.info(context, 'Belum ada data lamaran untuk diekspor.');
      return;
    }
    final password = await _requestBackupPassword(isRestoring: false);
    if (password == null || !mounted) return;

    try {
      final backupFile = await BackupService.createBackup(
        state.jobs,
        password: password,
      );
      await Share.shareXFiles(
        [XFile(backupFile.path)],
        subject: 'Backup_Ngelamar_${DateTime.now().year}.zip',
        text:
            'Backup Ngelamar terenkripsi. Simpan kata sandinya karena diperlukan saat pemulihan.',
      );
      if (mounted) {
        AppToast.success(
          context,
          'Backup ZIP terenkripsi beserta lampiran berhasil dibuat.',
        );
      }
    } on BackupException catch (error) {
      if (mounted) AppToast.error(context, error.message);
    } catch (_) {
      if (mounted) {
        AppToast.error(
          context,
          'Backup belum dapat dibuat. Silakan coba lagi.',
        );
      }
    }
  }

  Future<void> _importApplicationsData() async {
    HapticFeedback.mediumImpact();
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['zip', 'json'],
        withData: kIsWeb,
      );
      if (result == null || result.files.isEmpty) return;

      final selected = result.files.single;
      final bytes =
          selected.bytes ??
          (selected.path == null
              ? null
              : await File(selected.path!).readAsBytes());
      if (bytes == null) {
        throw const BackupException('File backup tidak dapat dibaca.');
      }

      String? password;
      if (!BackupService.isLegacyJsonBackup(bytes)) {
        password = await _requestBackupPassword(isRestoring: true);
        if (password == null || !mounted) return;
      }
      final payload = await BackupService.restoreFromBytes(
        bytes,
        password: password,
      );
      final importResult = await ref
          .read(jobProvider.notifier)
          .importJobs(payload.jobs);
      await ref
          .read(jobProvider.notifier)
          .discardUnreferencedAttachments(payload.extractedAttachmentPaths);

      if (mounted) {
        DelightCelebration.show(
          context,
          message: '${importResult.importedCount} lamaran kembali!',
          accent: const Color(0xFF1E8E3E),
          icon: Icons.restore_rounded,
          preset: DelightPreset.restore,
        );
        AppToast.success(
          context,
          '${importResult.importedCount} lamaran dipulihkan${importResult.skippedCount > 0 ? ', ${importResult.skippedCount} duplikat dilewati' : ''}${BackupService.isLegacyJsonBackup(bytes) ? '. Backup JSON lama tidak memuat lampiran.' : '.'}',
        );
      }
    } on BackupException catch (error) {
      if (mounted) AppToast.error(context, error.message);
    } catch (_) {
      if (mounted) {
        AppToast.error(context, 'Backup belum dapat dipulihkan.');
      }
    }
  }

  Future<String?> _requestBackupPassword({required bool isRestoring}) async {
    final controller = TextEditingController();
    final confirmationController = TextEditingController();
    var obscurePassword = true;
    final password = await AppDialog.show<String>(
      context: context,
      icon: CupertinoIcons.lock_fill,
      iconColor: const Color(0xFF1E8E3E),
      title: isRestoring ? 'Kata Sandi Backup' : 'Amankan Backup',
      content: isRestoring
          ? 'Masukkan kata sandi yang dipakai ketika membuat backup. Backup lama tetap dapat dibuka dengan kata sandi apa pun.'
          : 'Buat kata sandi minimal 12 karakter. Kata sandi tidak disimpan dan tidak dapat dipulihkan jika lupa.',
      secondaryLabel: 'Batal',
      primaryLabel: isRestoring ? 'Pulihkan' : 'Buat Backup',
      customBody: StatefulBuilder(
        builder: (dialogContext, setDialogState) => Column(
          children: [
            TextField(
              controller: controller,
              obscureText: obscurePassword,
              autofocus: true,
              autocorrect: false,
              enableSuggestions: false,
              textInputAction: isRestoring
                  ? TextInputAction.done
                  : TextInputAction.next,
              decoration: InputDecoration(
                labelText: 'Kata sandi backup',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  tooltip: obscurePassword ? 'Tampilkan' : 'Sembunyikan',
                  icon: Icon(
                    obscurePassword
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                  ),
                  onPressed: () =>
                      setDialogState(() => obscurePassword = !obscurePassword),
                ),
              ),
            ),
            if (!isRestoring) ...[
              const SizedBox(height: 10),
              TextField(
                controller: confirmationController,
                obscureText: obscurePassword,
                autocorrect: false,
                enableSuggestions: false,
                textInputAction: TextInputAction.done,
                decoration: const InputDecoration(
                  labelText: 'Ulangi kata sandi',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ],
        ),
      ),
      onPrimary: () {
        final value = controller.text;
        if (!isRestoring && value.trim().length < 12) {
          AppToast.error(context, 'Kata sandi minimal 12 karakter.');
          return;
        }
        if (!isRestoring && value != confirmationController.text) {
          AppToast.error(context, 'Konfirmasi kata sandi belum cocok.');
          return;
        }
        Navigator.of(context).pop(value);
      },
    );
    controller.dispose();
    confirmationController.dispose();
    return password;
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
      final cleared = await ref.read(jobProvider.notifier).clearAllJobs();
      if (!mounted) return;
      if (cleared) {
        AppToast.success(
          context,
          'Semua data lamaran dan lampiran telah dibersihkan.',
        );
      } else {
        AppToast.error(context, 'Data belum dapat dihapus. Silakan coba lagi.');
      }
    }
  }

  void _showPrivacyPolicyModal() {
    HapticFeedback.selectionClick();
    final bottomInset = MediaQuery.of(context).padding.bottom;
    final isDark = AppTheme.isDark(context);
    final sheetBg = isDark ? const Color(0xFF1E1E24) : Colors.white;
    final cardBg = isDark ? const Color(0xFF282830) : const Color(0xFFFBF8F2);
    final cardBorder = isDark
        ? const Color(0xFF383842)
        : const Color(0xFFE5E0D5);
    final txtPri = isDark ? Colors.white : const Color(0xFF121214);
    final txtSec = isDark ? const Color(0xFFA0A0A8) : const Color(0xFF555558);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        padding: EdgeInsets.fromLTRB(
          24,
          20,
          24,
          bottomInset > 0 ? bottomInset + 16 : 24,
        ),
        decoration: BoxDecoration(
          color: sheetBg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF383842) : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(10),
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
                  child: const Icon(
                    CupertinoIcons.lock_shield_fill,
                    color: Color(0xFF5C44E4),
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Kebijakan Privasi & Data',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: txtPri,
                        ),
                      ),
                      Text(
                        'Offline-First & Keamanan Data Pengguna',
                        style: TextStyle(fontSize: 12, color: txtSec),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close_rounded, size: 20, color: txtPri),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: cardBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        CupertinoIcons.lock_shield,
                        size: 16,
                        color: Color(0xFF5C44E4),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Data Lamaran Tersimpan di Perangkat',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 13.5,
                            color: txtPri,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Catatan lamaran, besaran gaji, jadwal seleksi, dan foto lampiran disimpan terenkripsi di perangkat. Menghapus seluruh data juga menghapus lampiran yang tersimpan oleh aplikasi.',
                    style: TextStyle(fontSize: 12, color: txtSec, height: 1.4),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(
                        CupertinoIcons.shield_lefthalf_fill,
                        size: 16,
                        color: Color(0xFF1E8E3E),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Tanpa Tracking & Tanpa Iklan Pihak Ketiga',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 13.5,
                            color: txtPri,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Ngelamar tidak mengumpulkan, menjual, atau mentransfer data pribadi Anda ke server analitik pihak ketiga manapun.',
                    style: TextStyle(fontSize: 12, color: txtSec, height: 1.4),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(
                        CupertinoIcons.globe,
                        size: 16,
                        color: Color(0xFFF59E0B),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Koneksi Opsional untuk Pencarian',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 13.5,
                            color: txtPri,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Koneksi hanya terjadi saat Anda membuka portal loker atau meminta isi otomatis dari tautan HTTPS portal yang didukung. Data lamaran Anda tidak dikirim untuk fitur tersebut.',
                    style: TextStyle(fontSize: 12, color: txtSec, height: 1.4),
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
                  backgroundColor: isDark
                      ? const Color(0xFF5C44E4)
                      : const Color(0xFF19191B),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
                child: const Text(
                  'Mengerti',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
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
    final isDark = AppTheme.isDark(context);
    final sheetBg = isDark ? const Color(0xFF1E1E24) : Colors.white;
    final cardBg = isDark ? const Color(0xFF282830) : const Color(0xFFF9F7F2);
    final cardBorder = isDark
        ? const Color(0xFF383842)
        : const Color(0xFFE5E0D5);
    final txtPri = isDark ? Colors.white : const Color(0xFF121214);
    final txtSec = isDark ? const Color(0xFFA0A0A8) : const Color(0xFF555558);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        padding: EdgeInsets.fromLTRB(
          24,
          20,
          24,
          bottomInset > 0 ? bottomInset + 16 : 24,
        ),
        decoration: BoxDecoration(
          color: sheetBg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF383842) : Colors.grey.shade300,
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
                  'android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png',
                  width: 68,
                  height: 68,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    color: const Color(0xFF19191B),
                    child: const Center(
                      child: Icon(
                        Icons.mail_rounded,
                        color: Color(0xFFF59E0B),
                        size: 36,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Ngelamar Mobile',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: txtPri,
              ),
            ),
            Text(
              'Versi $_appVersion (Build $_buildNumber) • Production Ready',
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF5C44E4),
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Teman personal untuk mencatat lamaran dan menyiapkan karirmu dari satu tempat.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12.5, color: txtSec, height: 1.45),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: cardBorder),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.email_outlined,
                        size: 16,
                        color: Color(0xFF5C44E4),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Email Bantuan:',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: txtPri,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        'support@ngelamar.id',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: txtSec,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(
                        Icons.chat_bubble_outline_rounded,
                        size: 16,
                        color: Color(0xFF25D366),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'WhatsApp Resmi:',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: txtPri,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '+62 831-3604-9987',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: txtSec,
                        ),
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
                  backgroundColor: isDark
                      ? const Color(0xFF5C44E4)
                      : const Color(0xFF19191B),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
                child: const Text(
                  'Tutup',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
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
    final hasPhoto =
        state.userProfilePhoto.isNotEmpty &&
        File(state.userProfilePhoto).existsSync();
    final displayName = state.userName.isNotEmpty
        ? state.userName
        : 'Pencari Kerja';
    final isDark = AppTheme.isDark(context);
    final bg = AppTheme.getBackground(context);
    final cardBg = AppTheme.getSurface(context);
    final cardBorder = AppTheme.getBorder(context);
    final txtPri = AppTheme.getTextPrimary(context);
    final txtSec = AppTheme.getTextSecondary(context);
    final profileCompletion =
        [
          state.userName.trim().isNotEmpty,
          hasPhoto,
          _cvPdfPath?.isNotEmpty == true,
          state.jobs.isNotEmpty,
        ].where((complete) => complete).length /
        4;
    final activeApplications = state.jobs
        .where((job) => job.status != 'Diterima' && job.status != 'Ditolak')
        .length;
    final profilePercent = (profileCompletion * 100).round();

    return Scaffold(
      backgroundColor: bg,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ── TOP BAR: shared title/action language with the Home dashboard ──
          SliverToBoxAdapter(
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      'PROFIL\nSAYA',
                      style: TextStyle(
                        fontSize: 34,
                        height: 0.96,
                        fontWeight: FontWeight.w900,
                        color: txtPri,
                        letterSpacing: -1.6,
                      ),
                    ),
                    FluidBounceButton(
                      onTap: _showEditProfileDialog,
                      semanticLabel: 'Edit profil pengguna',
                      child: Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: bg,
                          shape: BoxShape.circle,
                          border: Border.all(color: cardBorder, width: 1.4),
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
                        child: Center(
                          child: Icon(
                            CupertinoIcons.pencil,
                            size: 19,
                            color: txtPri,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── MAIN PROFILE CARD: warm Home-style surface ──
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(AppTheme.radiusCardLarge),
                  border: Border.all(
                    color: cardBorder,
                    width: AppTheme.borderHairline,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(
                        alpha: isDark ? 0.2 : 0.04,
                      ),
                      blurRadius: 14,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Row: Avatar + Name & Subtitle Info
                    Row(
                      children: [
                        // Circular Avatar (with camera badge)
                        GestureDetector(
                          onTap: _pickProfilePhoto,
                          child: Stack(
                            children: [
                              Container(
                                width: 80,
                                height: 80,
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? const Color(0xFF282830)
                                      : const Color(0xFF333336),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: isDark
                                        ? const Color(0xFF383842)
                                        : Colors.white,
                                    width: 2.5,
                                  ),
                                ),
                                child: ClipOval(
                                  child: hasPhoto
                                      ? Image.file(
                                          File(state.userProfilePhoto),
                                          width: 80,
                                          height: 80,
                                          fit: BoxFit.cover,
                                        )
                                      : Container(
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF333336),
                                          ),
                                          child: const Center(
                                            child: Icon(
                                              CupertinoIcons.person_fill,
                                              size: 38,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                ),
                              ),
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: Container(
                                  padding: const EdgeInsets.all(5),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF5C44E4),
                                    shape: BoxShape.circle,
                                    border: Border.all(color: cardBg, width: 2),
                                  ),
                                  child: const Icon(
                                    Icons.camera_alt_rounded,
                                    size: 12,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(width: 16),

                        // User Name & Subtitle
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                displayName,
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w900,
                                  color: txtPri,
                                  letterSpacing: -0.5,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                state.isProUser
                                    ? 'Member PRO • ${state.jobs.length} lamaran tercatat'
                                    : (state.jobs.isNotEmpty
                                          ? '${state.jobs.length} Lamaran Aktif • Siap Kerja'
                                          : 'Pencari Karir • Terbuka Peluang'),
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                  color: txtSec,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        ProfileCompletionRing(
                          value: profileCompletion,
                          color: const Color(0xFF5C44E4),
                          trackColor: isDark
                              ? const Color(0xFF383842)
                              : const Color(0xFFE9E4F5),
                        ),
                      ],
                    ),

                    const SizedBox(height: 18),

                    // A small career pulse makes the profile feel like part
                    // of the applicant journey, not a generic settings page.
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF282438)
                            : const Color(0xFFF0EAFF),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: isDark
                              ? const Color(0xFF4B426F)
                              : const Color(0xFFD9CDF8),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 38,
                            height: 38,
                            decoration: const BoxDecoration(
                              color: Color(0xFF5C44E4),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.auto_graph_rounded,
                              size: 19,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 11),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  activeApplications == 0
                                      ? 'Mulai peta kariermu'
                                      : '$activeApplications lamaran sedang berjalan',
                                  style: TextStyle(
                                    color: txtPri,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 12.5,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Profilmu sudah $profilePercent% siap untuk melamar.',
                                  style: TextStyle(
                                    color: txtSec,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 11.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            CupertinoIcons.sparkles,
                            size: 17,
                            color: isDark
                                ? const Color(0xFFC4B5FD)
                                : const Color(0xFF5C44E4),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Two high-contrast actions, matching Home's primary/green CTA pair.
                    Row(
                      children: [
                        // Left Capsule: CV
                        Expanded(
                          child: FluidBounceButton(
                            onTap: _openCvPdf,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                vertical: 12,
                                horizontal: 12,
                              ),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? const Color(0xFF5C44E4)
                                    : const Color(0xFF19191B),
                                borderRadius: BorderRadius.circular(
                                  AppTheme.radiusPill,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.12),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    CupertinoIcons.doc_text_fill,
                                    size: 14,
                                    color: Colors.white,
                                  ),
                                  const SizedBox(width: 6),
                                  Flexible(
                                    child: Text(
                                      _cvPdfPath == null || _cvPdfPath!.isEmpty
                                          ? 'Tambah CV'
                                          : 'Buka CV',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w800,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(width: 10),

                        // Right Capsule: Target Karir
                        Expanded(
                          child: FluidBounceButton(
                            onTap: _showCareerInterestsSheet,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                vertical: 12,
                                horizontal: 12,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF5C44E4),
                                borderRadius: BorderRadius.circular(
                                  AppTheme.radiusPill,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.12),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    CupertinoIcons.briefcase_fill,
                                    size: 14,
                                    color: Colors.white,
                                  ),
                                  SizedBox(width: 6),
                                  Flexible(
                                    child: Text(
                                      'Target Karir',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w800,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── SECTION: TENTANG (ABOUT) ──
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tentang',
                    style: TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w900,
                      color: txtPri,
                      letterSpacing: -0.4,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? cardBg : const Color(0xFFFFFBFF),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isDark ? cardBorder : const Color(0xFFD9CDF8),
                      ),
                    ),
                    child: GestureDetector(
                      onTap: _showEditAboutDialog,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 34,
                            height: 34,
                            margin: const EdgeInsets.only(right: 11),
                            decoration: BoxDecoration(
                              color: const Color(
                                0xFF5C44E4,
                              ).withValues(alpha: isDark ? 0.24 : 0.12),
                              borderRadius: BorderRadius.circular(11),
                            ),
                            child: const Icon(
                              Icons.subject_rounded,
                              size: 18,
                              color: Color(0xFF5C44E4),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              _about.isEmpty
                                  ? 'Tambahkan ringkasan singkat tentang dirimu.'
                                  : _about,
                              style: TextStyle(
                                fontSize: 13.5,
                                color: _about.isEmpty
                                    ? txtSec
                                    : (isDark
                                          ? const Color(0xFFD1D1D6)
                                          : const Color(0xFF374151)),
                                height: 1.5,
                                fontWeight: FontWeight.w500,
                                fontStyle: _about.isEmpty
                                    ? FontStyle.italic
                                    : FontStyle.normal,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Icon(CupertinoIcons.pencil, size: 17, color: txtSec),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── SECTION: PENGALAMAN & RIWAYAT LAMARAN (WORK EXPERIENCE) ──
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Riwayat Lamaran',
                    style: TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w900,
                      color: txtPri,
                      letterSpacing: -0.4,
                    ),
                  ),
                  if (state.jobs.length > 3)
                    TextButton(
                      onPressed: () => Navigator.push(
                        context,
                        CupertinoPageRoute(
                          builder: (_) => const JobListScreen(),
                        ),
                      ),
                      child: Text(
                        'Lihat semua (${state.jobs.length})',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF5C44E4),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // List Cards of Work Experience / Job Applications
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final jobList = state.jobs.take(3).toList();
                  if (jobList.isEmpty) {
                    return Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: cardBorder),
                      ),
                      child: Column(
                        children: [
                          Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              color: const Color(
                                0xFF5C44E4,
                              ).withValues(alpha: 0.10),
                              shape: BoxShape.circle,
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.work_history_outlined,
                                color: Color(0xFF5C44E4),
                                size: 25,
                              ),
                            ),
                          ),
                          const SizedBox(height: 11),
                          Text(
                            'Belum ada riwayat lamaran',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                              color: txtPri,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Lamaran yang kamu catat akan tampil di sini.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12.5,
                              color: txtSec,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  final job = jobList[index];
                  final appliedDate = DateFormat(
                    'd MMM yyyy',
                    'id_ID',
                  ).format(job.appliedDate);

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: cardBorder),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(
                            alpha: isDark ? 0.2 : 0.03,
                          ),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Hero(
                          tag: 'company_logo_${job.id}',
                          child: CompanyLogoBadge(
                            companyName: job.companyName,
                            customImagePath: job.companyLogoPath,
                            size: 46,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      job.companyName,
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w900,
                                        color: txtPri,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    appliedDate,
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      color: txtSec,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 3),
                              Text(
                                '${job.position} • ${job.status}',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: isDark
                                      ? const Color(0xFFA0A0A8)
                                      : const Color(0xFF55555A),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        PopupMenuButton<String>(
                          icon: Icon(
                            CupertinoIcons.ellipsis_vertical,
                            color: txtSec,
                            size: 16,
                          ),
                          color: cardBg,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          onSelected: (val) async {
                            if (val == 'detail') {
                              Navigator.push(
                                context,
                                AppMotion.detailDockRoute(
                                  builder: (_) => JobDetailScreen(job: job),
                                ),
                              );
                            } else if (val == 'edit') {
                              final result =
                                  await Navigator.push<JobApplication>(
                                    context,
                                    CupertinoPageRoute(
                                      builder: (_) =>
                                          AddEditJobScreen(jobToEdit: job),
                                    ),
                                  );
                              if (!context.mounted || result == null) return;
                              if (result.status != job.status) {
                                DelightCelebration.show(
                                  context,
                                  message: 'Tahap baru: ${result.status}',
                                  accent: AppTheme.getStatusColor(
                                    result.status,
                                  ),
                                  icon: DelightCelebration.iconForStatus(
                                    result.status,
                                  ),
                                  preset: DelightCelebration.forStatus(
                                    result.status,
                                  ),
                                );
                              }
                            }
                          },
                          itemBuilder: (ctx) => [
                            const PopupMenuItem(
                              value: 'detail',
                              child: Row(
                                children: [
                                  Icon(CupertinoIcons.eye, size: 16),
                                  SizedBox(width: 8),
                                  Text(
                                    'Lihat Detail',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'edit',
                              child: Row(
                                children: [
                                  Icon(CupertinoIcons.pencil, size: 16),
                                  SizedBox(width: 8),
                                  Text(
                                    'Edit Lamaran',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
                childCount: state.jobs.isEmpty ? 1 : state.jobs.take(3).length,
              ),
            ),
          ),

          // ── SECTION: PENGATURAN & PREFERENSI SISTEM ──
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Pengaturan & Preferensi',
                    style: TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w900,
                      color: txtPri,
                      letterSpacing: -0.4,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Kelola preferensi akun, paket langganan, dan keamanan data lamaran Anda.',
                    style: TextStyle(
                      fontSize: 12.5,
                      color: txtSec,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── ALL SETTINGS LIST TILES & ACTIONS ──
          SliverPadding(
            padding: EdgeInsets.fromLTRB(
              20,
              0,
              20,
              AppLayoutMetrics.contentBottomClearance(context),
            ),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // 1. PRO Banner Card
                if (state.isProUser)
                  Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF1E1E24)
                          : const Color(0xFF19191B),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isDark
                            ? const Color(0xFF383842)
                            : Colors.transparent,
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.workspace_premium_rounded,
                          color: Color(0xFFF59E0B),
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Member PRO Aktif',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 13.5,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Akses tak terbatas ekspor & fitur eksklusif',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              CupertinoPageRoute(
                                builder: (_) => const SubscriptionScreen(),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFF59E0B),
                            foregroundColor: const Color(0xFF19191B),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                          ),
                          child: const Text(
                            'Kelola',
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 11.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        CupertinoPageRoute(
                          builder: (_) => const SubscriptionScreen(),
                        ),
                      );
                    },
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF1E3A8A), Color(0xFF3B82F6)],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(
                              0xFF1E3A8A,
                            ).withValues(alpha: 0.25),
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
                            child: const Icon(
                              Icons.workspace_premium_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Upgrade ke Ngelamar PRO',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 13.5,
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'Rp 10.000 / bln • Buka seluruh fitur',
                                  style: TextStyle(
                                    color: Color(0xFFDBEAFE),
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(
                            CupertinoIcons.chevron_right,
                            color: Colors.white,
                            size: 16,
                          ),
                        ],
                      ),
                    ),
                  ),

                // 2. Settings Option Tiles Box
                Container(
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: cardBorder),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(
                          alpha: isDark ? 0.2 : 0.03,
                        ),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      _buildSettingTile(
                        icon: CupertinoIcons.person_crop_circle_badge_checkmark,
                        color: const Color(0xFF4285F4),
                        title: _hasCloudAccount
                            ? 'Akun Google Terhubung'
                            : 'Hubungkan Akun Google',
                        subtitle: _hasCloudAccount
                            ? (_accountIdentity!.email ??
                                  'Cloud backup dan sinkronisasi aktif')
                            : 'Amankan backup dan pulihkan data saat ganti perangkat',
                        trailing: _isAccountBusy
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : null,
                        onTap: _connectGoogleAccount,
                      ),
                      Divider(
                        height: 1,
                        indent: 16,
                        endIndent: 16,
                        color: isDark
                            ? const Color(0xFF2E2E38)
                            : const Color(0xFFE6E0D5),
                      ),
                      // Mode Gelap (Dark Mode OLED)
                      _buildSettingTile(
                        icon: state.isDarkMode
                            ? CupertinoIcons.moon_stars_fill
                            : CupertinoIcons.sun_max_fill,
                        color: state.isDarkMode
                            ? const Color(0xFFA78BFA)
                            : const Color(0xFFF59E0B),
                        title: 'Mode Gelap (Dark Mode OLED)',
                        subtitle: !state.isProUser
                            ? 'Fitur PRO • aktifkan untuk memakai tema gelap'
                            : (state.isDarkMode
                                  ? 'Tema gelap aktif'
                                  : 'Tema terang aktif'),
                        trailing: CupertinoSwitch(
                          value: state.isDarkMode,
                          activeTrackColor: const Color(0xFF1E3A8A),
                          onChanged: state.isProUser
                              ? (_) => _handleThemeToggle(state)
                              : null,
                        ),
                        onTap: () => _handleThemeToggle(state),
                      ),
                      Divider(
                        height: 1,
                        indent: 16,
                        endIndent: 16,
                        color: isDark
                            ? const Color(0xFF2E2E38)
                            : const Color(0xFFE6E0D5),
                      ),

                      // Target & Minat Karir
                      _buildSettingTile(
                        icon: CupertinoIcons.briefcase,
                        color: const Color(0xFF1E3A8A),
                        title: 'Target & Minat Karir',
                        subtitle: _userInterests.isNotEmpty
                            ? '${_userInterests.length} bidang: ${_userInterests.first}'
                            : 'Atur posisi lowongan yang diminati',
                        onTap: _showCareerInterestsSheet,
                      ),
                      Divider(
                        height: 1,
                        indent: 16,
                        endIndent: 16,
                        color: isDark
                            ? const Color(0xFF2E2E38)
                            : const Color(0xFFE6E0D5),
                      ),

                      // Ekspor Data Lamaran
                      _buildSettingTile(
                        icon: CupertinoIcons.arrow_down_doc_fill,
                        color: const Color(0xFF0A66C2),
                        title: 'Ekspor Data (Backup ZIP)',
                        subtitle: 'Simpan riwayat lamaran dan lampiran',
                        onTap: _exportApplicationsData,
                      ),
                      Divider(
                        height: 1,
                        indent: 16,
                        endIndent: 16,
                        color: isDark
                            ? const Color(0xFF2E2E38)
                            : const Color(0xFFE6E0D5),
                      ),

                      _buildSettingTile(
                        icon: CupertinoIcons.arrow_up_doc_fill,
                        color: const Color(0xFF5C44E4),
                        title: 'Pulihkan Backup',
                        subtitle: 'Impor backup ZIP atau JSON lama',
                        onTap: _importApplicationsData,
                      ),
                      Divider(
                        height: 1,
                        indent: 16,
                        endIndent: 16,
                        color: isDark
                            ? const Color(0xFF2E2E38)
                            : const Color(0xFFE6E0D5),
                      ),

                      _buildSettingTile(
                        icon: CupertinoIcons.cloud_upload_fill,
                        color: const Color(0xFF1E8E3E),
                        title: 'Backup Cloud Terenkripsi',
                        subtitle: _hasCloudAccount
                            ? 'Simpan ZIP terenkripsi ke akun Google Anda'
                            : 'Hubungkan Google untuk mengaktifkan backup cloud',
                        onTap: _uploadCloudBackup,
                      ),
                      Divider(
                        height: 1,
                        indent: 16,
                        endIndent: 16,
                        color: isDark
                            ? const Color(0xFF2E2E38)
                            : const Color(0xFFE6E0D5),
                      ),

                      _buildSettingTile(
                        icon: CupertinoIcons.cloud_download_fill,
                        color: const Color(0xFF5C44E4),
                        title: 'Pulihkan dari Cloud',
                        subtitle: 'Ambil backup terenkripsi dari akun Anda',
                        onTap: _restoreCloudBackup,
                      ),
                      Divider(
                        height: 1,
                        indent: 16,
                        endIndent: 16,
                        color: isDark
                            ? const Color(0xFF2E2E38)
                            : const Color(0xFFE6E0D5),
                      ),

                      // Notifikasi Interview
                      _buildNotificationStatusCard(state, isDark),
                      Divider(
                        height: 1,
                        indent: 16,
                        endIndent: 16,
                        color: isDark
                            ? const Color(0xFF2E2E38)
                            : const Color(0xFFE6E0D5),
                      ),

                      // Kebijakan Privasi
                      _buildSettingTile(
                        icon: CupertinoIcons.lock_shield_fill,
                        color: const Color(0xFF1E8E3E),
                        title: 'Keamanan & Privasi',
                        subtitle:
                            'Data terenkripsi di perangkat • koneksi opsional',
                        onTap: _showPrivacyPolicyModal,
                      ),
                      Divider(
                        height: 1,
                        indent: 16,
                        endIndent: 16,
                        color: isDark
                            ? const Color(0xFF2E2E38)
                            : const Color(0xFFE6E0D5),
                      ),

                      _buildSettingTile(
                        icon: CupertinoIcons.chat_bubble_2_fill,
                        color: const Color(0xFF5C44E4),
                        title: 'Kirim Masukan',
                        subtitle:
                            'Laporkan bug atau usulkan fitur langsung ke tim',
                        onTap: _showFeedbackDialog,
                      ),
                      Divider(
                        height: 1,
                        indent: 16,
                        endIndent: 16,
                        color: isDark
                            ? const Color(0xFF2E2E38)
                            : const Color(0xFFE6E0D5),
                      ),

                      // Panduan Fitur Aplikasi (Tutorial Overlay)
                      _buildSettingTile(
                        icon: CupertinoIcons.sparkles,
                        color: const Color(0xFFE65100),
                        title: 'Panduan Fitur Aplikasi',
                        subtitle:
                            'Tampilkan kembali tur interaktif fitur aplikasi',
                        onTap: () async {
                          await PrefsService.setAppTourSeen(false);
                          if (context.mounted) {
                            AppleToast.info(
                              context,
                              'Panduan tur akan muncul saat kembali ke Beranda',
                            );
                          }
                        },
                      ),
                      Divider(
                        height: 1,
                        indent: 16,
                        endIndent: 16,
                        color: isDark
                            ? const Color(0xFF2E2E38)
                            : const Color(0xFFE6E0D5),
                      ),

                      // Tentang Aplikasi
                      _buildSettingTile(
                        icon: CupertinoIcons.info_circle_fill,
                        color: const Color(0xFF0288D1),
                        title: 'Tentang Aplikasi & Versi',
                        subtitle: 'Ngelamar v$_appVersion ($_buildNumber)',
                        onTap: _showAboutAppModal,
                      ),
                      Divider(
                        height: 1,
                        indent: 16,
                        endIndent: 16,
                        color: isDark
                            ? const Color(0xFF2E2E38)
                            : const Color(0xFFE6E0D5),
                      ),

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

  JobApplication? _nextUpcomingReminder(Iterable<JobApplication> jobs) {
    final now = DateTime.now();
    final upcoming =
        jobs.where((job) {
          final schedule = job.interviewDate ?? job.testDate;
          final isSelection =
              job.status == 'Tes / Psikotes' ||
              job.status.startsWith('Interview');
          return isSelection &&
              schedule != null &&
              schedule.isAfter(now) &&
              (schedule.hour != 0 || schedule.minute != 0);
        }).toList()..sort((a, b) {
          final aDate = a.interviewDate ?? a.testDate!;
          final bDate = b.interviewDate ?? b.testDate!;
          return aDate.compareTo(bDate);
        });
    return upcoming.isEmpty ? null : upcoming.first;
  }

  Future<void> _repairNotificationPermission() async {
    if (_notificationsEnabled == true) {
      AppToast.info(context, 'Izin notifikasi sudah aktif di perangkat.');
      return;
    }
    final granted = await NotificationService.promptPermissionIfNeeded(context);
    await _refreshNotificationStatus();
    if (!mounted) return;
    if (granted) {
      AppToast.success(context, 'Izin notifikasi sudah diperbarui.');
    } else {
      AppToast.warning(
        context,
        'Izin notifikasi belum aktif. Periksa pengaturan perangkat.',
      );
    }
  }

  Widget _buildNotificationStatusCard(JobState state, bool isDark) {
    final nextReminder = _nextUpcomingReminder(state.jobs);
    final permissionLabel = _notificationsEnabled == null
        ? 'Memeriksa izin…'
        : _notificationsEnabled!
        ? 'Izin aktif'
        : 'Izin nonaktif';
    final permissionColor = _notificationsEnabled == null
        ? const Color(0xFF8E8E93)
        : _notificationsEnabled!
        ? const Color(0xFF1E8E3E)
        : const Color(0xFFE53935);

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF24242B) : const Color(0xFFFFFBF2),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? const Color(0xFF3A3A44) : const Color(0xFFF0E2C1),
        ),
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
                  color: const Color(0xFFF59E0B).withValues(alpha: 0.14),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  CupertinoIcons.bell_fill,
                  color: Color(0xFFF59E0B),
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pengingat Seleksi',
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : const Color(0xFF121214),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      permissionLabel,
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: permissionColor,
                      ),
                    ),
                  ],
                ),
              ),
              OutlinedButton(
                onPressed: _repairNotificationPermission,
                style: OutlinedButton.styleFrom(
                  foregroundColor: isDark
                      ? const Color(0xFFC5B8FF)
                      : const Color(0xFF5C44E4),
                  side: BorderSide(
                    color: isDark
                        ? const Color(0xFF5C44E4)
                        : const Color(0xFFD7C9FF),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  minimumSize: const Size(48, 44),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  _notificationsEnabled == true ? 'Kelola' : 'Perbaiki izin',
                  style: const TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF2D2D35) : Colors.white,
              borderRadius: BorderRadius.circular(13),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.event_available_rounded,
                  size: 17,
                  color: isDark
                      ? const Color(0xFFC5B8FF)
                      : const Color(0xFF5C44E4),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    nextReminder == null
                        ? 'Pengingat berikutnya: belum ada jadwal'
                        : 'Berikutnya: ${nextReminder.position} • ${DateFormat('dd MMM, HH:mm', 'id_ID').format(nextReminder.interviewDate ?? nextReminder.testDate!)}',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: isDark
                          ? const Color(0xFFD5D5DC)
                          : const Color(0xFF555558),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
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
    final isDark = AppTheme.isDark(context);
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
        style: TextStyle(
          fontSize: 13.5,
          fontWeight: FontWeight.w800,
          color: isDark ? Colors.white : const Color(0xFF121214),
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 11.5,
          color: isDark ? const Color(0xFFA0A0A8) : const Color(0xFF707074),
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing:
          trailing ??
          Icon(
            CupertinoIcons.chevron_right,
            size: 14,
            color: isDark ? Colors.white38 : const Color(0xFFA0A0A5),
          ),
      onTap: onTap,
    );
  }
}

class _FeedbackDialog extends StatefulWidget {
  final String appVersion;

  const _FeedbackDialog({required this.appVersion});

  @override
  State<_FeedbackDialog> createState() => _FeedbackDialogState();
}

class _FeedbackDialogState extends State<_FeedbackDialog> {
  final _controller = TextEditingController();
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_submitting) return;
    if (_controller.text.trim().length < 10) {
      setState(
        () => _error = 'Tulis sedikitnya 10 karakter agar masukan jelas.',
      );
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await FeedbackService.submit(
        category: 'feedback',
        message: _controller.text.trim(),
        appVersion: widget.appVersion,
      );
      if (mounted) Navigator.pop(context, true);
    } on FeedbackSubmissionException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (_) {
      if (mounted) {
        setState(
          () => _error =
              'Masukan belum dapat dikirim. Periksa internet lalu coba lagi.',
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return PopScope(
      canPop: !_submitting,
      child: Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E1E22) : Colors.white,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: isDark
                    ? const Color(0xFF37373D)
                    : const Color(0xFFE5E0D5),
              ),
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(22),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(
                    CupertinoIcons.chat_bubble_2_fill,
                    color: Color(0xFF5C44E4),
                    size: 34,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Kirim Masukan',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: isDark ? Colors.white : const Color(0xFF121214),
                      fontSize: 19,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    'Ceritakan bug, ide fitur, atau bagian aplikasi yang perlu diperbaiki.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: isDark ? Colors.white70 : const Color(0xFF66666B),
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _controller,
                    enabled: !_submitting,
                    minLines: 4,
                    maxLines: 7,
                    maxLength: 3000,
                    autofocus: true,
                    textCapitalization: TextCapitalization.sentences,
                    onChanged: (_) => setState(() => _error = null),
                    decoration: InputDecoration(
                      hintText: 'Tulis masukanmu…',
                      errorText: _error,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _submitting
                              ? null
                              : () => Navigator.pop(context, false),
                          child: const Text('Batal'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton(
                          onPressed:
                              _submitting || _controller.text.trim().length < 10
                              ? null
                              : _submit,
                          child: _submitting
                              ? const SizedBox.square(
                                  dimension: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text('Kirim'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
