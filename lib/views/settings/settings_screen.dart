import 'dart:async';
import 'dart:convert';
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
import '../../constants/app_version.dart';
import '../../providers/job_provider.dart';
import '../../repositories/profile_repository.dart';
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
import '../../widgets/safe_avatar_image.dart';
import '../../widgets/company_logo_badge.dart';
import '../../widgets/delight_celebration.dart';
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
  const SettingsScreen({super.key, this.onStartAppTour});

  final VoidCallback? onStartAppTour;

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _aboutController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  static String get _appVersion => AppVersion.version;
  static String get _buildNumber => AppVersion.buildNumber;

  int _selectedSegment = 0;
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
    _notifyOAuthRedirectError();
  }

  /// Supabase bounces rejected OAuth links back with ?error=... in the URL
  /// (only reachable on web). Explain it kindly instead of leaving a silent
  /// blank restart.
  void _notifyOAuthRedirectError() {
    final failure = SupabaseService.consumeOAuthError();
    if (failure == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (failure.code == 'identity_already_exists') {
        _offerExistingAccountSignIn();
      } else {
        AppToast.error(
          context,
          'Sinkronisasi akun Google belum berhasil. Silakan coba lagi dari menu Akun & Sync.',
        );
      }
    });
  }

  /// The Google identity belongs to another Supabase user. Offer a explicit,
  /// informed switch to that existing account instead of failing silently.
  Future<void> _offerExistingAccountSignIn() async {
    final isDark = AppTheme.isDark(context);
    final proceed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E1E22) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        icon: const Icon(
          CupertinoIcons.person_crop_circle_badge_checkmark,
          size: 34,
          color: Color(0xFF5C44E4),
        ),
        title: const Text(
          'Akun Sudah Pernah Terhubung',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'Akun Google ini sudah terhubung ke sesi Ngelamar yang lain.\n\n'
          'Anda bisa masuk langsung dengan akun tersebut, tetapi data cloud '
          'dan status PRO dari sesi anonim saat ini tidak akan ikut. '
          'Data lokal di perangkat ini tetap aman.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF5C44E4),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Tetap Masuk'),
          ),
        ],
      ),
    );
    if (proceed != true || !mounted) return;
    final launched = await SupabaseService.signInWithGoogle();
    if (!mounted) return;
    AppToast.info(
      context,
      launched
          ? 'Pilih akun Google Anda, lalu kembali ke aplikasi.'
          : 'Browser login Google belum dapat dibuka.',
    );
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
      final identity = SupabaseService.currentIdentity;
      final wasAnonymous =
          _accountIdentity == null || _accountIdentity!.isAnonymous;
      if (mounted) {
        setState(() => _accountIdentity = identity);
        // Beri kepastian begitu sinkronisasi akun benar-benar berhasil.
        if (wasAnonymous && identity != null && !identity.isAnonymous) {
          AppToast.success(
            context,
            'Akun Google berhasil tersambung. Data siap disinkronkan.',
          );
        }
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
        // On web `XFile.path` is a temporary blob URL. It works only until
        // refresh, so keep an encoded local copy instead of persisting that
        // expiring URL. Native builds continue to use the managed file path.
        final String photoSource;
        if (kIsWeb) {
          photoSource = await _webPhotoDataUri(picked);
        } else {
          photoSource = picked.path;
        }
        await ref.read(jobProvider.notifier).setUserProfilePhoto(photoSource);
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

  Future<String> _webPhotoDataUri(XFile picked) async {
    final bytes = await picked.readAsBytes();
    final extension = picked.name.split('.').last.toLowerCase();
    final mimeType = switch (extension) {
      'png' => 'image/png',
      'webp' => 'image/webp',
      'gif' => 'image/gif',
      _ => 'image/jpeg',
    };
    return 'data:$mimeType;base64,${base64Encode(bytes)}';
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
                      await ProfileRepository().saveProfile(
                        ProfileRepository().currentProfile.copyWith(
                          careerInterests: tempInterests,
                        ),
                      );
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
        await ProfileRepository().saveProfile(
          ProfileRepository().currentProfile.copyWith(about: value),
        );
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
      await ProfileRepository().saveProfile(
        ProfileRepository().currentProfile.copyWith(
          cvPdfPath: destination.path,
        ),
      );
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
    if (_hasCloudAccount) {
      AppToast.info(
        context,
        'Akun Google sudah tersambung. Sinkronisasi berjalan otomatis.',
      );
      return;
    }
    setState(() => _isAccountBusy = true);
    try {
      final launched = await SupabaseService.connectGoogle();
      if (mounted) {
        AppToast.info(
          context,
          launched
              ? 'Pilih akun Google yang tersimpan, lalu kembali ke aplikasi.'
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
      if (mounted && temporaryBackup != null) {
        final saveLocally = await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            title: const Text('Cloud belum tersedia'),
            content: const Text(
              'Backup terenkripsi sudah berhasil dibuat. Simpan berkasnya di perangkat agar datamu tetap aman.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('Nanti'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: const Text('Simpan lokal'),
              ),
            ],
          ),
        );
        if (saveLocally == true) {
          await Share.shareXFiles(
            [XFile(temporaryBackup.path)],
            subject: 'Backup Ngelamar terenkripsi',
            text: 'Simpan berkas ini. Kata sandi diperlukan saat pemulihan.',
          );
          if (mounted) {
            AppToast.success(context, 'Backup lokal siap disimpan.');
          }
        }
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
      if (!mounted) return;
      final confirmed = await _showRestorePreviewModal(
        context: context,
        title: 'Cloud (${selected.objectPath.split('/').last})',
        jobsCount: payload.jobs.length,
        attachmentsCount: payload.extractedAttachmentPaths.length,
        isLegacy: false,
      );
      if (confirmed != true || !mounted) return;

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
      if (!mounted) return;
      final confirmed = await _showRestorePreviewModal(
        context: context,
        title: selected.name,
        jobsCount: payload.jobs.length,
        attachmentsCount: payload.extractedAttachmentPaths.length,
        isLegacy: BackupService.isLegacyJsonBackup(bytes),
      );
      if (confirmed != true || !mounted) return;

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

  Future<bool?> _showRestorePreviewModal({
    required BuildContext context,
    required String title,
    required int jobsCount,
    required int attachmentsCount,
    required bool isLegacy,
  }) {
    final isDark = AppTheme.isDark(context);
    final sheetBg = isDark ? const Color(0xFF1E1E24) : Colors.white;
    final txtPri = isDark ? Colors.white : const Color(0xFF121214);
    final txtSec = isDark ? const Color(0xFFA0A0A8) : const Color(0xFF707074);

    return showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
        decoration: BoxDecoration(
          color: sheetBg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
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
                    color: const Color(0xFF1E8E3E).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.settings_backup_restore_rounded,
                    color: Color(0xFF1E8E3E),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Konfirmasi Pemulihan Data',
                        style: TextStyle(
                          fontSize: 16.5,
                          fontWeight: FontWeight.w900,
                          color: txtPri,
                        ),
                      ),
                      Text(
                        'Ringkasan data cadangan yang akan dipulihkan',
                        style: TextStyle(fontSize: 12, color: txtSec),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF282830)
                    : const Color(0xFFF7F5F0),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Sumber Cadangan',
                        style: TextStyle(fontSize: 12.5, color: txtSec),
                      ),
                      Flexible(
                        child: Text(
                          title,
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: txtPri,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Jumlah Lamaran',
                        style: TextStyle(fontSize: 12.5, color: txtSec),
                      ),
                      Text(
                        '$jobsCount lowongan',
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF5C44E4),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Lampiran Terhubung',
                        style: TextStyle(fontSize: 12.5, color: txtSec),
                      ),
                      Text(
                        isLegacy
                            ? 'Format JSON Lama (tanpa file)'
                            : '$attachmentsCount file berkas',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: txtPri,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: BorderSide(
                        color: isDark
                            ? const Color(0xFF383842)
                            : const Color(0xFFE5E0D5),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(
                      'Batal',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: txtPri,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1E8E3E),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Pulihkan Data',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
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
    final sheetBg = isDark ? const Color(0xFF1E1E24) : const Color(0xFFFFFCF6);
    final cardBg = isDark ? const Color(0xFF282830) : const Color(0xFFF1E9DC);
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
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(24),
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
                    'Catatan lamaran, jadwal, gaji, dan lampiran disimpan terenkripsi di perangkatmu.',
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
                          'Transparansi Data & Layanan Cloud',
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
                    'Cloud hanya dipakai saat kamu memilih sinkronisasi atau backup. Isi backup tetap terenkripsi dan data tidak dijual kepada pengiklan.',
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
                          'Koneksi Jaringan & Kontrol Penuh',
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
                    'Kamu dapat mengekspor, memulihkan, atau menghapus data kapan saja dari Pengaturan.',
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
                        'idkasolutions@gmail.com',
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
    // `dart:io` files do not exist in browser builds. Web photos are stored
    // as data URIs, while native photos keep their managed file paths.
    final hasPhoto =
        state.userProfilePhoto.isNotEmpty &&
        (kIsWeb || File(state.userProfilePhoto).existsSync());
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
      body: SafeArea(
        bottom: false,
        child: ListView(
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.fromLTRB(
            20,
            AppLayoutMetrics.headerTopInsideSafeArea(context, extra: 12),
            20,
            AppLayoutMetrics.contentBottomClearance(context),
          ),
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'PROFIL SAYA',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          color: txtPri,
                          letterSpacing: -1.1,
                          height: 1.0,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Kelola data karir dan pengaturan akunmu.',
                        style: TextStyle(
                          fontSize: 13,
                          color: txtSec,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _showEditProfileDialog,
                    borderRadius: BorderRadius.circular(22),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: cardBg,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: cardBorder.withValues(
                            alpha: isDark ? 0.3 : 0.6,
                          ),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(
                              alpha: isDark ? 0.15 : 0.03,
                            ),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Icon(
                          CupertinoIcons.pencil,
                          size: 18,
                          color: Color(0xFF5C44E4),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(AppTheme.radiusCardLarge),
                border: Border.all(
                  color: cardBorder.withValues(alpha: isDark ? 0.25 : 0.5),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.03),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      GestureDetector(
                        onTap: _pickProfilePhoto,
                        child: Stack(
                          children: [
                            Container(
                              width: 68,
                              height: 68,
                              decoration: BoxDecoration(
                                color: isDark
                                    ? const Color(0xFF282830)
                                    : const Color(0xFF333336),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isDark
                                      ? const Color(0xFF383842)
                                      : Colors.white,
                                  width: 2,
                                ),
                              ),
                              child: ClipOval(
                                child: SafeAvatarImage(
                                  imagePath: state.userProfilePhoto,
                                  size: 68,
                                  fallback: Container(
                                    decoration: const BoxDecoration(
                                      color: Color(0xFF333336),
                                    ),
                                    child: const Center(
                                      child: Icon(
                                        CupertinoIcons.person_fill,
                                        size: 32,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF5C44E4),
                                  shape: BoxShape.circle,
                                  border: Border.all(color: cardBg, width: 2),
                                ),
                                child: const Icon(
                                  Icons.camera_alt_rounded,
                                  size: 11,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
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
                                    displayName,
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                      color: txtPri,
                                      letterSpacing: -0.4,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (state.isProUser) ...[
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFEF3C7),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: const Text(
                                      'PRO',
                                      style: TextStyle(
                                        color: Color(0xFFB45309),
                                        fontSize: 9,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 0.3,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 3),
                            Text(
                              state.jobs.isNotEmpty
                                  ? '$activeApplications Lamaran Berjalan / ${state.jobs.length} Total'
                                  : 'Pencari Karir / Terbuka Peluang',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: txtSec,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Expanded(
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(4),
                                    child: LinearProgressIndicator(
                                      value: profileCompletion,
                                      backgroundColor: isDark
                                          ? const Color(0xFF2E2E38)
                                          : const Color(0xFFE9E4F5),
                                      valueColor: const AlwaysStoppedAnimation(
                                        Color(0xFF5C44E4),
                                      ),
                                      minHeight: 4.5,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '$profilePercent% Lengkap',
                                  style: const TextStyle(
                                    color: Color(0xFF5C44E4),
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: FluidBounceButton(
                          onTap: _openCvPdf,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              vertical: 10,
                              horizontal: 10,
                            ),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? const Color(0xFF27272A)
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
                                      fontSize: 12,
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
                      const SizedBox(width: 8),
                      Expanded(
                        child: FluidBounceButton(
                          onTap: _showCareerInterestsSheet,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              vertical: 10,
                              horizontal: 10,
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
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  CupertinoIcons.briefcase_fill,
                                  size: 14,
                                  color: Colors.white,
                                ),
                                const SizedBox(width: 6),
                                Flexible(
                                  child: Text(
                                    _userInterests.isEmpty
                                        ? 'Target Karir'
                                        : 'Target (${_userInterests.length})',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
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
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF1E1E22)
                    : const Color(0xFFE8E3DA),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() => _selectedSegment = 0);
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(vertical: 9),
                        decoration: BoxDecoration(
                          color: _selectedSegment == 0
                              ? (isDark
                                    ? const Color(0xFF2E2E38)
                                    : Colors.white)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: _selectedSegment == 0
                              ? [
                                  BoxShadow(
                                    color: Colors.black.withValues(
                                      alpha: isDark ? 0.2 : 0.06,
                                    ),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ]
                              : null,
                        ),
                        child: Center(
                          child: Text(
                            'Karir & Dokumen',
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: _selectedSegment == 0
                                  ? FontWeight.w700
                                  : FontWeight.w700,
                              color: _selectedSegment == 0 ? txtPri : txtSec,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() => _selectedSegment = 1);
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(vertical: 9),
                        decoration: BoxDecoration(
                          color: _selectedSegment == 1
                              ? (isDark
                                    ? const Color(0xFF2E2E38)
                                    : Colors.white)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: _selectedSegment == 1
                              ? [
                                  BoxShadow(
                                    color: Colors.black.withValues(
                                      alpha: isDark ? 0.2 : 0.06,
                                    ),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ]
                              : null,
                        ),
                        child: Center(
                          child: Text(
                            'Pengaturan & Data',
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: _selectedSegment == 1
                                  ? FontWeight.w700
                                  : FontWeight.w700,
                              color: _selectedSegment == 1 ? txtPri : txtSec,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            if (_selectedSegment == 0) ...[
              _buildCareerAndDocsSegment(
                context,
                state,
                isDark,
                cardBg,
                cardBorder,
                txtPri,
                txtSec,
              ),
            ] else ...[
              _buildSettingsAndDataSegment(
                context,
                state,
                isDark,
                cardBg,
                cardBorder,
                txtPri,
                txtSec,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, {Widget? trailing}) {
    final isDark = AppTheme.isDark(context);
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8, top: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
                color: isDark
                    ? const Color(0xFFA0A0AB)
                    : const Color(0xFF71717A),
              ),
            ),
          ),
          if (trailing != null) ...[const SizedBox(width: 8), trailing],
        ],
      ),
    );
  }

  Widget _buildSettingsCard({
    required List<Widget> children,
    required bool isDark,
    required Color cardBg,
    required Color cardBorder,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
        border: Border.all(
          color: cardBorder.withValues(alpha: isDark ? 0.25 : 0.5),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.12 : 0.02),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildSettingDivider(bool isDark) {
    return Divider(
      height: 1,
      indent: 16,
      endIndent: 16,
      color: isDark ? const Color(0xFF282830) : const Color(0xFFEBE6DD),
    );
  }

  Widget _buildCareerAndDocsSegment(
    BuildContext context,
    JobState state,
    bool isDark,
    Color cardBg,
    Color cardBorder,
    Color txtPri,
    Color txtSec,
  ) {
    final recentJobs = state.jobs.take(3).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          'RINGKASAN PROFESIONAL',
          trailing: GestureDetector(
            onTap: _showEditAboutDialog,
            child: const Text(
              'Ubah',
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w800,
                color: Color(0xFF5C44E4),
              ),
            ),
          ),
        ),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(AppTheme.radiusCard),
            border: Border.all(
              color: cardBorder.withValues(alpha: isDark ? 0.25 : 0.5),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.12 : 0.02),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _showEditAboutDialog,
            child: Text(
              _about.isEmpty
                  ? 'Tambahkan ringkasan singkat tentang keahlian, pengalaman, dan profil karirmu.'
                  : _about,
              style: TextStyle(
                fontSize: 13,
                height: 1.45,
                color: _about.isEmpty ? txtSec : txtPri,
                fontStyle: _about.isEmpty ? FontStyle.italic : FontStyle.normal,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        _buildSectionHeader(
          'MINAT & TARGET POSISI',
          trailing: GestureDetector(
            onTap: _showCareerInterestsSheet,
            child: const Text(
              'Atur',
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w800,
                color: Color(0xFF5C44E4),
              ),
            ),
          ),
        ),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(AppTheme.radiusCard),
            border: Border.all(
              color: cardBorder.withValues(alpha: isDark ? 0.25 : 0.5),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.12 : 0.02),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: _userInterests.isEmpty
              ? GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: _showCareerInterestsSheet,
                  child: Text(
                    'Belum memilih target posisi karir. Ketuk di sini untuk memilih peran yang kamu minati.',
                    style: TextStyle(
                      fontSize: 13,
                      color: txtSec,
                      fontStyle: FontStyle.italic,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                )
              : Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: _userInterests.map((interest) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF28253B)
                            : const Color(0xFFEEF2FF),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        interest,
                        style: const TextStyle(
                          color: Color(0xFF5C44E4),
                          fontSize: 11.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    );
                  }).toList(),
                ),
        ),
        const SizedBox(height: 16),
        _buildSectionHeader('DOKUMEN CV'),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(AppTheme.radiusCard),
            border: Border.all(
              color: cardBorder.withValues(alpha: isDark ? 0.25 : 0.5),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.12 : 0.02),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(
                    0xFF5C44E4,
                  ).withValues(alpha: isDark ? 0.22 : 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: Icon(
                    CupertinoIcons.doc_text_fill,
                    size: 20,
                    color: Color(0xFF5C44E4),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _cvPdfPath != null && _cvPdfPath!.isNotEmpty
                          ? 'Berkas CV Terpasang'
                          : 'Belum Ada CV',
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                        color: txtPri,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _cvPdfPath != null && _cvPdfPath!.isNotEmpty
                          ? 'Format PDF siap dilampirkan'
                          : 'Unggah file PDF untuk melamar',
                      style: TextStyle(fontSize: 11.5, color: txtSec),
                    ),
                  ],
                ),
              ),
              if (_cvPdfPath != null && _cvPdfPath!.isNotEmpty) ...[
                TextButton(
                  onPressed: _openCvPdf,
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                  ),
                  child: const Text(
                    'Buka',
                    style: TextStyle(
                      color: Color(0xFF5C44E4),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: _pickCvPdf,
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                  ),
                  child: Text(
                    'Ganti',
                    style: TextStyle(
                      color: txtSec,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ] else ...[
                ElevatedButton(
                  onPressed: _pickCvPdf,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF5C44E4),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Unggah',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (state.jobs.isNotEmpty) ...[
          _buildSectionHeader(
            'RIWAYAT TERKINI',
            trailing: TextButton(
              onPressed: () => Navigator.push(
                context,
                CupertinoPageRoute(
                  builder: (_) => const JobListScreen(showBackButton: true),
                ),
              ),
              style: TextButton.styleFrom(
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
              ),
              child: Text(
                'Lihat Semua (${state.jobs.length})',
                style: const TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF5C44E4),
                ),
              ),
            ),
          ),
          ...recentJobs.map((job) {
            final appliedDate = DateFormat(
              'd MMM yyyy',
              'id_ID',
            ).format(job.appliedDate);

            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(AppTheme.radiusCard),
                border: Border.all(
                  color: cardBorder.withValues(alpha: isDark ? 0.25 : 0.5),
                ),
              ),
              child: Row(
                children: [
                  Hero(
                    tag: 'company_logo_${job.id}',
                    child: CompanyLogoBadge(
                      companyName: job.companyName,
                      customImagePath: job.companyLogoPath,
                      size: 40,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          job.companyName,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: txtPri,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${job.position} / ${job.status} / $appliedDate',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w500,
                            color: txtSec,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(CupertinoIcons.chevron_right, size: 14),
                    color: txtSec,
                    onPressed: () {
                      Navigator.push(
                        context,
                        AppMotion.detailDockRoute(
                          builder: (_) => JobDetailScreen(job: job),
                        ),
                      );
                    },
                  ),
                ],
              ),
            );
          }),
        ],
      ],
    );
  }

  Widget _buildSettingsAndDataSegment(
    BuildContext context,
    JobState state,
    bool isDark,
    Color cardBg,
    Color cardBorder,
    Color txtPri,
    Color txtSec,
  ) {
    final notificationsActive = _notificationsEnabled ?? false;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Akun & Cloud
        _buildSectionHeader('AKUN & SYNC'),
        _buildSettingsCard(
          isDark: isDark,
          cardBg: cardBg,
          cardBorder: cardBorder,
          children: [
            _buildSettingTile(
              icon: CupertinoIcons.cloud_fill,
              color: const Color(0xFF0288D1),
              title: _hasCloudAccount
                  ? 'Akun Google Terhubung'
                  : 'Hubungkan Akun Google',
              subtitle: _hasCloudAccount
                  ? 'Tersambung sebagai ${_accountIdentity?.email ?? 'akun Google'} · sinkronisasi aktif'
                  : 'Pilih akun yang tersimpan di perangkat',
              onTap: _connectGoogleAccount,
              trailing: _isAccountBusy
                  ? const SizedBox.square(
                      dimension: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : null,
            ),
            if (_hasCloudAccount) ...[
              _buildSettingDivider(isDark),
              _buildSettingTile(
                icon: CupertinoIcons.cloud_upload_fill,
                color: const Color(0xFF1E8E3E),
                title: 'Backup Cloud Terenkripsi',
                subtitle: 'Simpan ZIP terenkripsi ke cloud Ngelamar',
                onTap: _uploadCloudBackup,
              ),
              _buildSettingDivider(isDark),
              _buildSettingTile(
                icon: CupertinoIcons.cloud_download_fill,
                color: const Color(0xFF5C44E4),
                title: 'Pulihkan dari Cloud',
                subtitle: 'Ambil backup terenkripsi dari cloud Ngelamar',
                onTap: _restoreCloudBackup,
              ),
            ],
            _buildSettingDivider(isDark),
            _buildSettingTile(
              icon: CupertinoIcons.star_circle_fill,
              color: const Color(0xFFF59E0B),
              title: 'Status PRO',
              subtitle: state.isProUser
                  ? 'Aktif (Akses fitur tanpa batas)'
                  : 'Buka analisis dan fitur lengkap',
              onTap: () {
                Navigator.push(
                  context,
                  CupertinoPageRoute(
                    builder: (_) => const SubscriptionScreen(),
                  ),
                );
              },
              trailing: state.isProUser
                  ? Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF3C7),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'AKTIF',
                        style: TextStyle(
                          color: Color(0xFFB45309),
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    )
                  : null,
            ),
          ],
        ),
        const SizedBox(height: 16),

        // 2. Preferensi Notifikasi & Data
        _buildSectionHeader('PREFERENSI & CADANGAN'),
        _buildSettingsCard(
          isDark: isDark,
          cardBg: cardBg,
          cardBorder: cardBorder,
          children: [
            _buildSettingTile(
              icon: state.isDarkMode
                  ? CupertinoIcons.moon_stars_fill
                  : CupertinoIcons.sun_max_fill,
              color: state.isDarkMode
                  ? const Color(0xFFA78BFA)
                  : const Color(0xFFF59E0B),
              title: 'Mode Gelap (Dark Theme)',
              subtitle: state.isDarkMode
                  ? 'Tema gelap aktif'
                  : 'Tema terang aktif',
              onTap: () => _handleThemeToggle(state),
              trailing: Switch.adaptive(
                value: state.isDarkMode,
                activeTrackColor: const Color(0xFF5C44E4),
                onChanged: (_) => _handleThemeToggle(state),
              ),
            ),
            _buildSettingDivider(isDark),
            _buildSettingTile(
              icon: notificationsActive
                  ? CupertinoIcons.bell_fill
                  : CupertinoIcons.bell_slash_fill,
              color: notificationsActive
                  ? const Color(0xFF10B981)
                  : const Color(0xFF8E8E93),
              title: 'Pengingat & Notifikasi',
              subtitle: notificationsActive
                  ? 'Aktif (Jadwal interview & tes)'
                  : 'Nonaktif • Ketuk untuk aktifkan',
              onTap: _repairNotificationPermission,
              trailing: Switch.adaptive(
                value: notificationsActive,
                activeTrackColor: const Color(0xFF5C44E4),
                onChanged: (_) => _repairNotificationPermission(),
              ),
            ),
            _buildSettingDivider(isDark),
            _buildSettingTile(
              icon: CupertinoIcons.arrow_down_doc_fill,
              color: const Color(0xFF5C44E4),
              title: 'Ekspor Data (Backup ZIP)',
              subtitle: 'Cadangkan lamaran dan dokumen',
              onTap: _exportApplicationsData,
            ),
            _buildSettingDivider(isDark),
            _buildSettingTile(
              icon: CupertinoIcons.arrow_up_doc_fill,
              color: const Color(0xFF10B981),
              title: 'Pulihkan Backup',
              subtitle: 'Impor berkas ZIP atau JSON',
              onTap: _importApplicationsData,
            ),
          ],
        ),
        const SizedBox(height: 16),

        // 3. Aplikasi & Dukungan
        _buildSectionHeader('INFORMASI & DUKUNGAN'),
        _buildSettingsCard(
          isDark: isDark,
          cardBg: cardBg,
          cardBorder: cardBorder,
          children: [
            _buildSettingTile(
              icon: CupertinoIcons.sparkles,
              color: const Color(0xFFE65100),
              title: 'Panduan Fitur Aplikasi',
              subtitle: 'Tampilkan tur interaktif fitur aplikasi',
              onTap: () async {
                await PrefsService.setAppTourSeen(false);
                await PrefsService.setTabTourSeen(4, false);
                if (context.mounted) {
                  widget.onStartAppTour?.call();
                }
              },
            ),
            _buildSettingDivider(isDark),
            _buildSettingTile(
              icon: CupertinoIcons.chat_bubble_2_fill,
              color: const Color(0xFF5C44E4),
              title: 'Kirim Masukan',
              subtitle: 'Laporkan bug atau usulkan fitur',
              onTap: _showFeedbackDialog,
            ),
            _buildSettingDivider(isDark),
            _buildSettingTile(
              icon: CupertinoIcons.lock_shield_fill,
              color: const Color(0xFF1E8E3E),
              title: 'Keamanan & Privasi',
              subtitle: 'Data terenkripsi di perangkatmu',
              onTap: _showPrivacyPolicyModal,
            ),
            _buildSettingDivider(isDark),
            _buildSettingTile(
              icon: CupertinoIcons.info_circle_fill,
              color: const Color(0xFF0288D1),
              title: 'Tentang Aplikasi & Versi',
              subtitle: 'Ngelamar v$_appVersion ($_buildNumber)',
              onTap: _showAboutAppModal,
            ),
            _buildSettingDivider(isDark),
            _buildSettingTile(
              icon: CupertinoIcons.trash,
              color: const Color(0xFFE53935),
              title: 'Bersihkan Semua Data Lamaran',
              subtitle: 'Hapus seluruh catatan dari penyimpanan',
              onTap: _clearAllData,
            ),
          ],
        ),
      ],
    );
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

  Future<void> _shareWithoutAccount() async {
    final message = _controller.text.trim();
    if (message.length < 10) {
      setState(
        () => _error = 'Tulis sedikitnya 10 karakter agar masukan jelas.',
      );
      return;
    }
    FocusScope.of(context).unfocus();
    await Share.share(
      'Masukan Ngelamar v${widget.appVersion}\n\n$message\n\n'
      'Tujuan: idkasolutions@gmail.com',
      subject: 'Masukan untuk Ngelamar',
    );
    if (mounted) Navigator.pop(context, true);
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
                  OutlinedButton.icon(
                    onPressed: _submitting ? null : _shareWithoutAccount,
                    icon: const Icon(CupertinoIcons.share),
                    label: const Text('Kirim tanpa masuk akun'),
                  ),
                  const SizedBox(height: 10),
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
