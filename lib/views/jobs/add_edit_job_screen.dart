import 'dart:async';
import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import '../../models/job_application.dart';
import '../../providers/job_provider.dart';
import '../../services/notification_service.dart';
import '../../services/salary_evaluator_service.dart';
import '../../services/text_parser_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_dialog.dart';
import '../../widgets/apple_animations.dart';
import '../../widgets/apple_toast.dart';
import '../../widgets/delight_celebration.dart';
import '../../widgets/rupiah_input_formatter.dart';

/// Screen: Tambah & Edit Catatan Lamaran Kerja.
/// Didesain 100% presisi mengikuti referensi visual mockup:
/// - Latar belakang dominan Warm Vibrant Yellow (seperti kartu Amazon)
/// - Top Bar: Tombol bundar putih (Back), Logo Perusahaan bundar di tengah, Tombol Bookmark/Impor di kanan
/// - Nama Perusahaan besar tebal di tengah
/// - Pill Container Posisi/Role (Software Development Engineer style)
/// - Teks lokasi dengan ikon pin
/// - Tiga pill informasi: gaji, tipe kerja, dan status
/// - Section Card Putih melengkung tumpul (28px) dengan floating pill header "Kualifikasi & Detail Seleksi"
/// - Tombol Aksi Utama Pil Hitam Solid di bagian bawah: "Catat Lamaran Ini" / "Simpan Perubahan"
class AddEditJobScreen extends ConsumerStatefulWidget {
  final JobApplication? jobToEdit;
  final bool autoFocusPaste;
  final bool startQuickMode;

  const AddEditJobScreen({
    super.key,
    this.jobToEdit,
    this.autoFocusPaste = false,
    this.startQuickMode = false,
  });

  @override
  ConsumerState<AddEditJobScreen> createState() => _AddEditJobScreenState();
}

class _AddEditJobScreenState extends ConsumerState<AddEditJobScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _linkOrTextController;
  late TextEditingController _companyController;
  late TextEditingController _positionController;
  late TextEditingController _salaryController;
  late TextEditingController _locationController;
  late TextEditingController _descriptionController;
  late TextEditingController _hrContactController;
  late TextEditingController _notesController;

  String _status = 'Dikirim';
  String _workType = 'WFO';
  String _jobSource = 'LinkedIn';
  String _sourcePlatform = 'Manual';
  String? _jobUrl;
  String? _screenshotPath;
  String? _companyLogoPath;
  final Set<String> _draftAttachmentPaths = <String>{};
  DateTime _appliedDate = DateTime.now();
  DateTime? _interviewDate;
  bool _isSaving = false;
  bool _isExtracting = false;
  bool _showSmartImport = false;
  bool _quickMode = false;

  final List<String> _statusOptions = [
    'Dikirim',
    'Tes / Psikotes',
    'Interview HR',
    'Interview User',
    'Offering',
    'Diterima',
    'Ditolak',
  ];

  final List<String> _workTypeOptions = ['WFO', 'WFH', 'Hybrid'];
  final List<String> _sourceOptions = [
    'LinkedIn',
    'JobStreet',
    'Indeed',
    'Glints',
    'Kalibrr',
    'KitaLulus',
    'Website Karir',
    'Email Direct',
    'Referensi',
    'Lainnya',
  ];

  @override
  void initState() {
    super.initState();
    final j = widget.jobToEdit;
    _quickMode = widget.startQuickMode && j == null;
    _linkOrTextController = TextEditingController();
    _companyController = TextEditingController(text: j?.companyName ?? '');
    _positionController = TextEditingController(text: j?.position ?? '');
    _salaryController = TextEditingController(text: j?.salaryOffered ?? '');
    _locationController = TextEditingController(text: j?.location ?? '');
    _descriptionController = TextEditingController(
      text: j?.jobDescription ?? '',
    );
    _hrContactController = TextEditingController(text: j?.hrContact ?? '');
    _notesController = TextEditingController(text: j?.notes ?? '');

    if (j != null) {
      _status = j.status == 'HR Screening' ? 'Interview HR' : j.status;
      _workType = j.workType;
      _jobSource = j.jobSource ?? 'LinkedIn';
      _sourcePlatform = j.sourcePlatform;
      _jobUrl = j.jobUrl;
      _screenshotPath = j.screenshotPath;
      _companyLogoPath = j.companyLogoPath;
      _appliedDate = j.appliedDate;
      _interviewDate = j.interviewDate ?? j.testDate;
    }
  }

  @override
  void dispose() {
    for (final path in _draftAttachmentPaths) {
      unawaited(_deleteDraftAttachment(path));
    }
    _linkOrTextController.dispose();
    _companyController.dispose();
    _positionController.dispose();
    _salaryController.dispose();
    _locationController.dispose();
    _descriptionController.dispose();
    _hrContactController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _deleteDraftAttachment(String path) async {
    try {
      final file = File(path);
      if (await file.exists()) await file.delete();
    } catch (_) {
      // Draft cleanup must never block navigation away from this form.
    }
  }

  void _replaceDraftAttachment({
    required bool isCompanyLogo,
    required String path,
  }) {
    final previousPath = isCompanyLogo ? _companyLogoPath : _screenshotPath;
    if (previousPath != null && _draftAttachmentPaths.remove(previousPath)) {
      unawaited(_deleteDraftAttachment(previousPath));
    }
    _draftAttachmentPaths.add(path);
    setState(() {
      if (isCompanyLogo) {
        _companyLogoPath = path;
      } else {
        _screenshotPath = path;
      }
    });
  }

  /// Tempel dari Clipboard & Ekstrak otomatis
  void _pasteFromClipboard() async {
    HapticFeedback.selectionClick();
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data?.text != null && data!.text!.trim().isNotEmpty) {
      _linkOrTextController.text = data.text!.trim();
      _extractFromLinkOrText();
    } else {
      if (mounted) {
        AppleToast.info(
          context,
          'Clipboard kosong. Salin link/teks lowongan terlebih dahulu.',
        );
      }
    }
  }

  /// Ekstraksi otomatis dari Link URL atau Teks Iklan
  void _extractFromLinkOrText() async {
    final text = _linkOrTextController.text.trim();
    if (text.isEmpty) {
      AppleToast.warning(
        context,
        'Masukkan link atau teks lowongan terlebih dahulu.',
      );
      return;
    }

    HapticFeedback.mediumImpact();
    setState(() => _isExtracting = true);

    try {
      final result = await TextParserService.extractFromUrlOrText(text);
      if (!mounted) return;

      final extractedFields = <String>[
        if (result.companyName.isNotEmpty) 'perusahaan',
        if (result.position.isNotEmpty) 'posisi',
        if (result.location?.isNotEmpty == true) 'lokasi',
        if (result.salary?.isNotEmpty == true) 'gaji',
        if (result.rawDescription.isNotEmpty) 'deskripsi',
      ];
      if (extractedFields.isEmpty) {
        AppleToast.warning(
          context,
          'Belum ada informasi lowongan yang dapat dikenali.',
          subtitle: 'Coba tempel teks lowongan yang lebih lengkap.',
        );
        return;
      }

      setState(() {
        if (result.companyName.isNotEmpty) {
          _companyController.text = result.companyName;
        }
        if (result.position.isNotEmpty) {
          _positionController.text = result.position;
        }
        if (result.salary != null) {
          _salaryController.text = result.salary!;
        }
        if (result.location != null) {
          _locationController.text = result.location!;
        }
        if (result.rawDescription.isNotEmpty) {
          _descriptionController.text = result.rawDescription;
        }
        if (result.hrContact != null) {
          _hrContactController.text = result.hrContact!;
        }
        if (result.jobUrl != null) {
          _jobUrl = result.jobUrl;
        }
        _workType = result.workType;
        _sourcePlatform = result.sourcePlatform;
        if (result.sourcePlatform != 'Manual' &&
            _sourceOptions.contains(result.sourcePlatform)) {
          _jobSource = result.sourcePlatform;
        }
      });

      AppleToast.success(
        context,
        '${extractedFields.length} bagian berhasil ditemukan',
        subtitle: extractedFields.join(', '),
      );
      if (result.companyName.isNotEmpty && result.position.isNotEmpty) {
        setState(() => _showSmartImport = false);
        DelightCelebration.show(
          context,
          message: 'Detail utama lowongan sudah terisi!',
          accent: const Color(0xFF5C44E4),
          icon: Icons.auto_fix_high_rounded,
          preset: DelightPreset.smartImport,
        );
      }
    } catch (e) {
      if (mounted) {
        AppleToast.warning(context, 'Gagal mengekstrak link secara otomatis.');
      }
    } finally {
      if (mounted) setState(() => _isExtracting = false);
    }
  }

  /// Unggah Logo / Foto Perusahaan
  void _pickCompanyLogo() {
    HapticFeedback.selectionClick();
    final isDark = AppTheme.isDark(context);
    final sheetBg = isDark ? const Color(0xFF1E1E24) : Colors.white;
    final txtPri = isDark ? Colors.white : const Color(0xFF121214);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
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
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Foto / Logo Perusahaan',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: txtPri,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Pilih foto logo atau perusahaan yang Anda lamar:',
              style: TextStyle(
                fontSize: 13,
                color: isDark ? const Color(0xFFA0A0A8) : Colors.grey,
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(
                Icons.photo_library_rounded,
                color: Color(0xFF5C44E4),
              ),
              title: Text(
                'Pilih dari Galeri Foto',
                style: TextStyle(fontWeight: FontWeight.bold, color: txtPri),
              ),
              onTap: () {
                Navigator.pop(ctx);
                _processCompanyLogoPick(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.camera_alt_rounded,
                color: Color(0xFF5C44E4),
              ),
              title: Text(
                'Ambil dari Kamera',
                style: TextStyle(fontWeight: FontWeight.bold, color: txtPri),
              ),
              onTap: () {
                Navigator.pop(ctx);
                _processCompanyLogoPick(ImageSource.camera);
              },
            ),
            if (_companyLogoPath != null)
              ListTile(
                leading: const Icon(
                  Icons.delete_outline_rounded,
                  color: Color(0xFFE53935),
                ),
                title: const Text(
                  'Hapus Foto Kustom',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFE53935),
                  ),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  setState(() => _companyLogoPath = null);
                  AppleToast.info(context, 'Foto logo perusahaan dihapus');
                },
              ),
          ],
        ),
      ),
    );
  }

  void _processCompanyLogoPick(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: source,
        maxWidth: 600,
        maxHeight: 600,
        imageQuality: 85,
      );
      if (image != null && mounted) {
        final appDocDir = await getApplicationDocumentsDirectory();
        final logosDir = Directory('${appDocDir.path}/logos');
        if (!await logosDir.exists()) {
          await logosDir.create(recursive: true);
        }
        final fileName = 'logo_${DateTime.now().millisecondsSinceEpoch}.png';
        final savedImage = await File(
          image.path,
        ).copy('${logosDir.path}/$fileName');
        _replaceDraftAttachment(isCompanyLogo: true, path: savedImage.path);
        if (mounted) {
          AppleToast.success(context, 'Foto perusahaan berhasil dipilih!');
        }
      }
    } catch (_) {
      if (mounted) AppleToast.warning(context, 'Gagal memilih gambar.');
    }
  }

  /// Lampirkan Screenshot Foto / Gambar Loker
  void _pickScreenshot() {
    HapticFeedback.selectionClick();
    final isDark = AppTheme.isDark(context);
    final sheetBg = isDark ? const Color(0xFF1E1E24) : Colors.white;
    final txtPri = isDark ? Colors.white : const Color(0xFF121214);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
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
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Lampirkan Bukti / Screenshot Loker',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: txtPri,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Simpan foto poster atau bukti lowongan kerja ini:',
              style: TextStyle(
                fontSize: 13,
                color: isDark ? const Color(0xFFA0A0A8) : Colors.grey,
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(
                Icons.photo_library_rounded,
                color: Color(0xFF5C44E4),
              ),
              title: Text(
                'Pilih dari Galeri Foto',
                style: TextStyle(fontWeight: FontWeight.bold, color: txtPri),
              ),
              onTap: () {
                Navigator.pop(ctx);
                _processImagePick(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.camera_alt_rounded,
                color: Color(0xFF5C44E4),
              ),
              title: Text(
                'Ambil dari Kamera',
                style: TextStyle(fontWeight: FontWeight.bold, color: txtPri),
              ),
              onTap: () {
                Navigator.pop(ctx);
                _processImagePick(ImageSource.camera);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _processImagePick(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: source,
        maxWidth: 1200,
        maxHeight: 1600,
        imageQuality: 85,
      );
      if (image != null && mounted) {
        final appDocDir = await getApplicationDocumentsDirectory();
        final screenshotsDir = Directory('${appDocDir.path}/screenshots');
        if (!await screenshotsDir.exists()) {
          await screenshotsDir.create(recursive: true);
        }
        final fileName =
            'screenshot_${DateTime.now().millisecondsSinceEpoch}.png';
        final savedImage = await File(
          image.path,
        ).copy('${screenshotsDir.path}/$fileName');
        _replaceDraftAttachment(isCompanyLogo: false, path: savedImage.path);
        if (mounted) {
          AppleToast.success(context, 'Screenshot loker berhasil dilampirkan!');
        }
      }
    } catch (_) {
      if (mounted) AppleToast.warning(context, 'Gagal memilih gambar.');
    }
  }

  /// Pilih tanggal lamaran tanpa membuat pengingat seleksi.
  Future<void> _pickAppliedDate() async {
    HapticFeedback.selectionClick();
    final isDark = AppTheme.isDark(context);

    final picked = await showDatePicker(
      context: context,
      initialDate: _appliedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: isDark
                ? const ColorScheme.dark(
                    primary: Color(0xFF5C44E4),
                    onPrimary: Colors.white,
                    surface: Color(0xFF1E1E24),
                    onSurface: Colors.white,
                  )
                : const ColorScheme.light(
                    primary: Color(0xFF19191B),
                    onPrimary: Colors.white,
                    surface: Colors.white,
                    onSurface: Color(0xFF121214),
                  ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() => _appliedDate = picked);
    }
  }

  /// Jadwal seleksi harus berisi tanggal dan jam agar alarm tidak jatuh pukul 00.00.
  Future<void> _pickSelectionSchedule() async {
    HapticFeedback.selectionClick();
    final isDark = AppTheme.isDark(context);
    final initial =
        _interviewDate ?? DateTime.now().add(const Duration(days: 3));
    final date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: isDark
                ? const ColorScheme.dark(
                    primary: Color(0xFF5C44E4),
                    onPrimary: Colors.white,
                    surface: Color(0xFF1E1E24),
                    onSurface: Colors.white,
                  )
                : const ColorScheme.light(
                    primary: Color(0xFF19191B),
                    onPrimary: Colors.white,
                    surface: Colors.white,
                    onSurface: Color(0xFF121214),
                  ),
          ),
          child: child!,
        );
      },
    );
    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
      helpText: 'Pilih jam seleksi',
    );
    if (time == null || !mounted) return;

    setState(() {
      _interviewDate = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }

  bool get _hasSelectionStatus =>
      _status == 'Tes / Psikotes' || _status.startsWith('Interview');

  void _releaseDraftAttachmentsAfterSave() {
    _draftAttachmentPaths.remove(_screenshotPath);
    _draftAttachmentPaths.remove(_companyLogoPath);
  }

  String _formatSelectionSchedule(DateTime schedule) {
    return DateFormat('dd MMM yyyy, HH:mm', 'id_ID').format(schedule);
  }

  Widget _buildModeChoice({
    required String label,
    required IconData icon,
    required bool selected,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return FluidBounceButton(
      onTap: onTap,
      scaleFactor: 0.97,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected
              ? (isDark ? const Color(0xFF5C44E4) : const Color(0xFF19191B))
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 16,
              color: selected
                  ? Colors.white
                  : (isDark
                        ? const Color(0xFFA0A0A8)
                        : const Color(0xFF555558)),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w800,
                color: selected
                    ? Colors.white
                    : (isDark
                          ? const Color(0xFFA0A0A8)
                          : const Color(0xFF555558)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickModeCard({
    required bool isDark,
    required Color cardBg,
    required Color cardBorder,
    required Color txtPri,
    required Color txtSec,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.08),
            blurRadius: 16,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.bolt_rounded,
                color: Color(0xFFF59E0B),
                size: 20,
              ),
              const SizedBox(width: 7),
              Text(
                'Catat Cepat',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  color: txtPri,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Simpan tiga informasi penting dulu. Detail lain bisa dilengkapi nanti.',
            style: TextStyle(fontSize: 11.5, color: txtSec, height: 1.35),
          ),
          const SizedBox(height: 16),
          Text(
            'Nama Perusahaan *',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: txtSec,
            ),
          ),
          const SizedBox(height: 6),
          TextFormField(
            controller: _companyController,
            maxLength: 80,
            textCapitalization: TextCapitalization.words,
            onChanged: (_) => setState(() {}),
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: txtPri,
            ),
            decoration: _buildInputDeco(
              hint: 'Contoh: PT Bank Central Asia Tbk',
              icon: Icons.business_rounded,
              isDark: isDark,
            ),
            validator: (v) => v == null || v.trim().isEmpty
                ? 'Nama Perusahaan wajib diisi'
                : null,
          ),
          const SizedBox(height: 12),
          Text(
            'Posisi / Pekerjaan *',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: txtSec,
            ),
          ),
          const SizedBox(height: 6),
          TextFormField(
            controller: _positionController,
            maxLength: 100,
            textCapitalization: TextCapitalization.words,
            onChanged: (_) => setState(() {}),
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: txtPri,
            ),
            decoration: _buildInputDeco(
              hint: 'Contoh: Software Development Engineer',
              icon: Icons.badge_rounded,
              isDark: isDark,
            ),
            validator: (v) => v == null || v.trim().isEmpty
                ? 'Posisi lowongan wajib diisi'
                : null,
          ),
          const SizedBox(height: 12),
          Text(
            'Tanggal Melamar *',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: txtSec,
            ),
          ),
          const SizedBox(height: 6),
          FluidBounceButton(
            onTap: _pickAppliedDate,
            hapticEnabled: false,
            scaleFactor: 0.985,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF282830)
                    : const Color(0xFFF9F7F2),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark
                      ? const Color(0xFF383842)
                      : const Color(0xFFE5E0D5),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.event_available_rounded,
                    size: 18,
                    color: Color(0xFF5C44E4),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    DateFormat('dd MMM yyyy', 'id_ID').format(_appliedDate),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      color: txtPri,
                    ),
                  ),
                  const Spacer(),
                  Icon(Icons.edit_calendar_outlined, size: 17, color: txtSec),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String? _duplicateJobMessage(Object error) {
    if (error is DuplicateJobException) {
      return '${error.existingJob.position} di ${error.existingJob.companyName} sudah tercatat.';
    }
    return null;
  }

  bool _hasUnsavedChanges() {
    if (widget.jobToEdit != null) {
      final j = widget.jobToEdit!;
      return _companyController.text != j.companyName ||
          _positionController.text != j.position ||
          _salaryController.text != (j.salaryOffered ?? '') ||
          _locationController.text != (j.location ?? '') ||
          _descriptionController.text != j.jobDescription ||
          _hrContactController.text != (j.hrContact ?? '') ||
          _notesController.text != (j.notes ?? '') ||
          _status != j.status ||
          _workType != j.workType ||
          _jobSource != (j.jobSource ?? 'LinkedIn') ||
          _sourcePlatform != j.sourcePlatform ||
          _jobUrl != j.jobUrl ||
          !_isSameCalendarDate(_appliedDate, j.appliedDate) ||
          _interviewDate != (j.interviewDate ?? j.testDate) ||
          _screenshotPath != j.screenshotPath ||
          _companyLogoPath != j.companyLogoPath;
    }
    return _companyController.text.isNotEmpty ||
        _positionController.text.isNotEmpty ||
        _salaryController.text.isNotEmpty ||
        _locationController.text.isNotEmpty ||
        _descriptionController.text.isNotEmpty ||
        _hrContactController.text.isNotEmpty ||
        _notesController.text.isNotEmpty ||
        _status != 'Dikirim' ||
        _workType != 'WFO' ||
        _jobSource != 'LinkedIn' ||
        _jobUrl != null ||
        _interviewDate != null ||
        _screenshotPath != null ||
        _companyLogoPath != null;
  }

  bool _isSameCalendarDate(DateTime first, DateTime second) =>
      first.year == second.year &&
      first.month == second.month &&
      first.day == second.day;

  Future<bool> _confirmDiscard() async {
    if (!_hasUnsavedChanges()) return true;
    HapticFeedback.warningNotification();
    final discard = await AppDialog.show<bool>(
      context: context,
      title: 'Buang Perubahan?',
      content:
          'Informasi yang sudah Anda ketik belum tersimpan. Yakin ingin menutup form ini?',
      primaryLabel: 'Buang',
      isDestructive: true,
      secondaryLabel: 'Lanjut Mengisi',
      icon: Icons.delete_sweep_rounded,
      iconColor: const Color(0xFFE53935),
    );
    return discard ?? false;
  }

  void _deleteCurrentJob() async {
    HapticFeedback.heavyImpact();
    final confirm = await AppDialog.show<bool>(
      context: context,
      title: 'Hapus Lamaran Ini?',
      content:
          'Lamaran di ${widget.jobToEdit!.companyName} (${widget.jobToEdit!.position}) akan dihapus permanen.',
      primaryLabel: 'Hapus',
      isDestructive: true,
      secondaryLabel: 'Batal',
      icon: Icons.delete_outline_rounded,
      iconColor: const Color(0xFFE53935),
    );

    if (confirm == true && mounted) {
      await ref.read(jobProvider.notifier).deleteJob(widget.jobToEdit!.id);
      if (mounted) {
        Navigator.pop(context); // Close add/edit sheet
        Navigator.pop(context); // Close detail screen if opened from there
        AppleToast.success(context, 'Lamaran berhasil dihapus.');
      }
    }
  }

  Future<void> _saveJob() async {
    if (_isSaving || !_formKey.currentState!.validate()) return;
    if (_hasSelectionStatus &&
        _interviewDate != null &&
        _interviewDate!.isBefore(
          DateTime(_appliedDate.year, _appliedDate.month, _appliedDate.day),
        )) {
      AppleToast.warning(
        context,
        'Tanggal wawancara tidak boleh sebelum tanggal melamar.',
      );
      return;
    }

    setState(() => _isSaving = true);

    final isEdit = widget.jobToEdit != null;
    final id = isEdit
        ? widget.jobToEdit!.id
        : 'job_${DateTime.now().millisecondsSinceEpoch}';

    final salaryText = _salaryController.text.trim();
    final salaryRange = SalaryEvaluatorService.parseSalaryRange(salaryText);

    final selectionSchedule = _hasSelectionStatus ? _interviewDate : null;
    final isSampleData = widget.jobToEdit?.isSampleData ?? false;
    final newJob = JobApplication(
      id: id,
      companyName: _companyController.text.trim(),
      position: _positionController.text.trim(),
      status: isSampleData ? (widget.jobToEdit?.status ?? _status) : _status,
      appliedDate: _appliedDate,
      salaryOffered: salaryText.isEmpty ? null : salaryText,
      minSalary: salaryRange.min > 0 ? salaryRange.min.toInt() : null,
      maxSalary: salaryRange.max > 0 ? salaryRange.max.toInt() : null,
      workType: _workType,
      location: _locationController.text.trim().isEmpty
          ? null
          : _locationController.text.trim(),
      jobSource: _jobSource,
      sourcePlatform: _sourcePlatform,
      jobUrl: _jobUrl,
      jobDescription: _descriptionController.text.trim(),
      hrContact: _hrContactController.text.trim().isEmpty
          ? null
          : _hrContactController.text.trim(),
      interviewDate: _status.startsWith('Interview') ? selectionSchedule : null,
      testDate: _status == 'Tes / Psikotes' ? selectionSchedule : null,
      notes: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
      isFavorite: widget.jobToEdit?.isFavorite ?? false,
      screenshotPath: _screenshotPath,
      companyLogoPath: _companyLogoPath,
      isSampleData: isSampleData,
    );

    try {
      if (isEdit) {
        await ref.read(jobProvider.notifier).updateJob(newJob);
      } else {
        await ref.read(jobProvider.notifier).addJob(newJob);
      }

      _releaseDraftAttachmentsAfterSave();
      if (newJob.interviewDate != null && _hasSelectionStatus && mounted) {
        NotificationService.promptPermissionIfNeeded(context).catchError((
          Object error,
        ) {
          debugPrint('Permintaan izin notifikasi gagal: $error');
          return false;
        });
      }

      if (!mounted) return;
      Navigator.pop(context, newJob);
    } catch (error) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      final duplicateMessage = _duplicateJobMessage(error);
      if (duplicateMessage != null) {
        AppleToast.warning(context, duplicateMessage);
      } else {
        AppleToast.error(context, 'Lamaran gagal disimpan.');
      }
    }
  }

  void _showWorkTypePicker() {
    HapticFeedback.selectionClick();
    final isDark = AppTheme.isDark(context);
    final sheetBg = isDark ? const Color(0xFF1E1E24) : Colors.white;
    final txtPri = isDark ? Colors.white : const Color(0xFF121214);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
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
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Pilih Tipe Kerja',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: txtPri,
              ),
            ),
            const SizedBox(height: 14),
            ..._workTypeOptions.map((type) {
              final isSel = _workType == type;
              return ListTile(
                leading: Icon(
                  type == 'WFH'
                      ? Icons.home_work_rounded
                      : (type == 'Hybrid'
                            ? Icons.sync_alt_rounded
                            : Icons.apartment_rounded),
                  color: isSel ? const Color(0xFFF8BA38) : txtPri,
                ),
                title: Text(
                  type,
                  style: TextStyle(
                    fontWeight: isSel ? FontWeight.w900 : FontWeight.w600,
                    color: txtPri,
                  ),
                ),
                trailing: isSel
                    ? Icon(
                        Icons.check_circle_rounded,
                        color: isDark
                            ? const Color(0xFF5C44E4)
                            : const Color(0xFF19191B),
                      )
                    : null,
                onTap: () {
                  setState(() => _workType = type);
                  Navigator.pop(ctx);
                },
              );
            }),
          ],
        ),
      ),
    );
  }

  void _showStatusPicker() {
    HapticFeedback.selectionClick();
    if (widget.jobToEdit?.isSampleData ?? false) {
      AppleToast.info(context, 'Status dikunci karena ini data contoh.');
      return;
    }
    final isDark = AppTheme.isDark(context);
    final sheetBg = isDark ? const Color(0xFF1E1E24) : Colors.white;
    final txtPri = isDark ? Colors.white : const Color(0xFF121214);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
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
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Pilih Tahapan Status Lamaran',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: txtPri,
              ),
            ),
            const SizedBox(height: 14),
            ..._statusOptions.map((st) {
              final isSel = _status == st;
              final color = AppTheme.getStatusColor(st);
              return ListTile(
                leading: Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
                title: Text(
                  st,
                  style: TextStyle(
                    fontWeight: isSel ? FontWeight.w900 : FontWeight.w600,
                    color: txtPri,
                  ),
                ),
                trailing: isSel
                    ? Icon(
                        Icons.check_circle_rounded,
                        color: isDark
                            ? const Color(0xFF5C44E4)
                            : const Color(0xFF19191B),
                      )
                    : null,
                onTap: () {
                  setState(() {
                    _status = st;
                    if (!_hasSelectionStatus) _interviewDate = null;
                  });
                  Navigator.pop(ctx);
                },
              );
            }),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.jobToEdit != null;
    final isDark = AppTheme.isDark(context);
    final bottomInset = MediaQuery.of(context).padding.bottom;
    final canvasBg = isDark ? const Color(0xFF141418) : const Color(0xFFF6F1E8);
    final pillCream = isDark
        ? const Color(0xFF26262E)
        : const Color(0xFFFDE7A8);
    final cardBg = isDark ? const Color(0xFF1E1E24) : Colors.white;
    final cardBorder = isDark
        ? const Color(0xFF33333C)
        : const Color(0xFFE5E0D5);
    final txtPri = isDark ? Colors.white : const Color(0xFF121214);
    final txtSec = isDark ? const Color(0xFFA0A0A8) : const Color(0xFF555558);
    final circleBtnBg = isDark ? const Color(0xFF24242C) : Colors.white;
    final circleBtnBorder = isDark
        ? const Color(0xFF383842)
        : const Color(0xFFE5E0D5);

    final displayCompany = _companyController.text.trim().isNotEmpty
        ? _companyController.text.trim()
        : 'Nama Perusahaan';
    final displayPosition = _positionController.text.trim().isNotEmpty
        ? _positionController.text.trim()
        : 'Posisi Pekerjaan';
    final displayLocation = _locationController.text.trim().isNotEmpty
        ? _locationController.text.trim()
        : 'Lokasi Perusahaan';
    final displaySalary = _salaryController.text.trim().isNotEmpty
        ? _salaryController.text.trim()
        : 'Gaji Negosiasi';

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final discard = await _confirmDiscard();
        if (discard && context.mounted) {
          Navigator.pop(context);
        }
      },
      child: Scaffold(
        backgroundColor: canvasBg,
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: EdgeInsets.fromLTRB(20, 10, 20, 28 + bottomInset),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // ── 1. TOP HEADER BAR: CIRCULAR BACK + LOGO IN CENTER + BOOKMARK/IMPORT ──
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // Left Circular Back Button (<)
                            FluidBounceButton(
                              onTap: () async {
                                final discard = await _confirmDiscard();
                                if (discard && context.mounted) {
                                  Navigator.pop(context);
                                }
                              },
                              semanticLabel: 'Kembali',
                              child: Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: circleBtnBg,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: circleBtnBorder),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(
                                        alpha: isDark ? 0.2 : 0.08,
                                      ),
                                      blurRadius: 10,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: Center(
                                  child: Icon(
                                    CupertinoIcons.chevron_back,
                                    color: txtPri,
                                    size: 22,
                                  ),
                                ),
                              ),
                            ),

                            // Center Circular Logo Container
                            FluidBounceButton(
                              onTap: _pickCompanyLogo,
                              semanticLabel: 'Pilih logo perusahaan',
                              hapticEnabled: false,
                              scaleFactor: 0.96,
                              child: Stack(
                                children: [
                                  Container(
                                    width: 64,
                                    height: 64,
                                    decoration: BoxDecoration(
                                      color: circleBtnBg,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: circleBtnBorder,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(
                                            alpha: isDark ? 0.25 : 0.12,
                                          ),
                                          blurRadius: 12,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: ClipOval(
                                      child:
                                          _companyLogoPath != null &&
                                              File(
                                                _companyLogoPath!,
                                              ).existsSync()
                                          ? Image.file(
                                              File(_companyLogoPath!),
                                              width: 64,
                                              height: 64,
                                              fit: BoxFit.cover,
                                              cacheWidth:
                                                  (64 *
                                                          MediaQuery.of(
                                                            context,
                                                          ).devicePixelRatio)
                                                      .round(),
                                              cacheHeight:
                                                  (64 *
                                                          MediaQuery.of(
                                                            context,
                                                          ).devicePixelRatio)
                                                      .round(),
                                            )
                                          : Center(
                                              child: Text(
                                                displayCompany.isNotEmpty
                                                    ? displayCompany[0]
                                                          .toUpperCase()
                                                    : 'N',
                                                style: TextStyle(
                                                  fontSize: 28,
                                                  fontWeight: FontWeight.w900,
                                                  color: txtPri,
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
                                        color: isDark
                                            ? const Color(0xFF5C44E4)
                                            : const Color(0xFF19191B),
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

                            // Right Action: Smart Auto-Fill Toggle
                            FluidBounceButton(
                              onTap: () {
                                HapticFeedback.selectionClick();
                                if (_showSmartImport) {
                                  FocusScope.of(context).unfocus();
                                }
                                setState(
                                  () => _showSmartImport = !_showSmartImport,
                                );
                              },
                              semanticLabel: _showSmartImport
                                  ? 'Tutup impor lowongan'
                                  : 'Buka impor lowongan',
                              hapticEnabled: false,
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 220),
                                curve: Curves.easeOutCubic,
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: _showSmartImport
                                      ? (isDark
                                            ? const Color(0xFF5C44E4)
                                            : const Color(0xFF19191B))
                                      : circleBtnBg,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: circleBtnBorder),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(
                                        alpha: isDark ? 0.2 : 0.08,
                                      ),
                                      blurRadius: 10,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: Center(
                                  child: AnimatedSwitcher(
                                    duration: const Duration(milliseconds: 180),
                                    transitionBuilder: (child, animation) =>
                                        ScaleTransition(
                                          scale: animation,
                                          child: RotationTransition(
                                            turns: Tween<double>(
                                              begin: 0.85,
                                              end: 1,
                                            ).animate(animation),
                                            child: child,
                                          ),
                                        ),
                                    child: Icon(
                                      _showSmartImport
                                          ? Icons.close_rounded
                                          : Icons.link_rounded,
                                      key: ValueKey(_showSmartImport),
                                      color: _showSmartImport
                                          ? Colors.white
                                          : txtPri,
                                      size: 20,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        // ── 2. SMART AUTO-FILL ACCORDION ──
                        TweenAnimationBuilder<double>(
                          tween: Tween<double>(end: _showSmartImport ? 1 : 0),
                          duration: const Duration(milliseconds: 360),
                          curve: Curves.easeInOutCubic,
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            margin: const EdgeInsets.only(bottom: 16),
                            decoration: BoxDecoration(
                              color: cardBg,
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(color: cardBorder),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(
                                    alpha: isDark ? 0.25 : 0.08,
                                  ),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Row(
                                      children: [
                                        Icon(
                                          Icons.auto_awesome_rounded,
                                          color: Color(0xFF5C44E4),
                                          size: 18,
                                        ),
                                        SizedBox(width: 6),
                                        Text(
                                          'Impor Lowongan',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w900,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ],
                                    ),
                                    FluidBounceButton(
                                      onTap: _pasteFromClipboard,
                                      semanticLabel: 'Tempel dari clipboard',
                                      hapticEnabled: false,
                                      scaleFactor: 0.9,
                                      child: Container(
                                        width: 48,
                                        height: 48,
                                        decoration: BoxDecoration(
                                          color: isDark
                                              ? const Color(0xFF5C44E4)
                                              : const Color(0xFF19191B),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Tooltip(
                                          message: 'Tempel dari clipboard',
                                          child: Icon(
                                            Icons.content_paste_rounded,
                                            color: Colors.white,
                                            size: 17,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                TextField(
                                  controller: _linkOrTextController,
                                  minLines: 3,
                                  maxLines: 6,
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    color: txtPri,
                                  ),
                                  decoration: InputDecoration(
                                    hintText:
                                        'Tempel tautan portal atau teks lowongan...',
                                    hintStyle: TextStyle(
                                      fontSize: 12.5,
                                      color: isDark
                                          ? const Color(0xFF8E8E93)
                                          : Colors.grey.shade400,
                                    ),
                                    fillColor: isDark
                                        ? const Color(0xFF282830)
                                        : const Color(0xFFF9F7F2),
                                    filled: true,
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 10,
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(14),
                                      borderSide: BorderSide(
                                        color: isDark
                                            ? const Color(0xFF383842)
                                            : Colors.grey.shade300,
                                      ),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(14),
                                      borderSide: BorderSide(
                                        color: isDark
                                            ? const Color(0xFF383842)
                                            : Colors.grey.shade300,
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(14),
                                      borderSide: BorderSide(
                                        color: isDark
                                            ? const Color(0xFF5C44E4)
                                            : const Color(0xFF19191B),
                                        width: 1.6,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Tautan portal yang didukung akan dibaca untuk mengisi formulir secara otomatis.',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: isDark
                                        ? const Color(0xFFA0A0A8)
                                        : const Color(0xFF6B6B70),
                                    height: 1.35,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                FluidBounceButton(
                                  onTap: _isExtracting
                                      ? null
                                      : _extractFromLinkOrText,
                                  hapticEnabled: false,
                                  scaleFactor: 0.98,
                                  semanticLabel: 'Isi form dari lowongan',
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 180),
                                    width: double.infinity,
                                    height: 44,
                                    decoration: BoxDecoration(
                                      color: _isExtracting
                                          ? const Color(0xFF8E82DF)
                                          : const Color(0xFF5C44E4),
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    child: Center(
                                      child: AnimatedSwitcher(
                                        duration: const Duration(
                                          milliseconds: 180,
                                        ),
                                        child: _isExtracting
                                            ? const CupertinoActivityIndicator(
                                                key: ValueKey('loading'),
                                                color: Colors.white,
                                              )
                                            : const Row(
                                                key: ValueKey('ready'),
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(
                                                    Icons.auto_fix_high_rounded,
                                                    color: Colors.white,
                                                    size: 17,
                                                  ),
                                                  SizedBox(width: 8),
                                                  Text(
                                                    'Ekstrak dan Isi Otomatis',
                                                    style: TextStyle(
                                                      color: Colors.white,
                                                      fontWeight:
                                                          FontWeight.w800,
                                                      fontSize: 13,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          builder: (context, reveal, child) => IgnorePointer(
                            ignoring: !_showSmartImport,
                            child: ClipRect(
                              child: Align(
                                alignment: Alignment.topCenter,
                                heightFactor: reveal,
                                child: Opacity(opacity: reveal, child: child),
                              ),
                            ),
                          ),
                        ),

                        if (!isEdit) ...[
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? const Color(0xFF24242C)
                                  : Colors.white.withValues(alpha: 0.72),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: circleBtnBorder),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: _buildModeChoice(
                                    label: 'Catat Cepat',
                                    icon: Icons.bolt_rounded,
                                    selected: _quickMode,
                                    isDark: isDark,
                                    onTap: () =>
                                        setState(() => _quickMode = true),
                                  ),
                                ),
                                Expanded(
                                  child: _buildModeChoice(
                                    label: 'Detail Lengkap',
                                    icon: Icons.tune_rounded,
                                    selected: !_quickMode,
                                    isDark: isDark,
                                    onTap: () =>
                                        setState(() => _quickMode = false),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],

                        // ── 3. COMPANY NAME (LARGE BOLD EDITORIAL TYPOGRAPHY - PERSIS MOCKUP) ──
                        Text(
                          displayCompany,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 27,
                            fontWeight: FontWeight.w900,
                            color: txtPri,
                            letterSpacing: -0.6,
                          ),
                        ),

                        const SizedBox(height: 8),

                        // ── 4. POSITION PILL BADGE CONTAINER (PERSIS MOCKUP) ──
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 9,
                          ),
                          decoration: BoxDecoration(
                            color: pillCream,
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(color: cardBorder),
                          ),
                          child: Text(
                            displayPosition,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w800,
                              color: txtPri,
                              letterSpacing: -0.2,
                            ),
                          ),
                        ),

                        const SizedBox(height: 8),

                        // ── 5. LOCATION WITH PIN ──
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.location_on_outlined,
                              size: 15,
                              color: txtPri,
                            ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                displayLocation,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w700,
                                  color: txtPri,
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 18),

                        // ── 6. THREE HORIZONTAL INFO PILLS (GAJI, WORK TYPE, STATUS) - PERSIS MOCKUP ──
                        if (!_quickMode)
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            physics: const BouncingScrollPhysics(),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                // Pill 1: White Pill with Black Circle Coin (Gaji)
                                Container(
                                  padding: const EdgeInsets.fromLTRB(
                                    6,
                                    6,
                                    16,
                                    6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: circleBtnBg,
                                    borderRadius: BorderRadius.circular(28),
                                    border: Border.all(color: circleBtnBorder),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(
                                          alpha: isDark ? 0.2 : 0.05,
                                        ),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        width: 32,
                                        height: 32,
                                        decoration: BoxDecoration(
                                          color: isDark
                                              ? const Color(0xFF5C44E4)
                                              : const Color(0xFF1C1C1E),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Center(
                                          child: Text(
                                            'Rp',
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w900,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        displaySalary,
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w900,
                                          color: txtPri,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                const SizedBox(width: 8),

                                // Pill 2: Cream Pill with Clock Icon (Tipe Kerja)
                                FluidBounceButton(
                                  onTap: _showWorkTypePicker,
                                  hapticEnabled: false,
                                  scaleFactor: 0.96,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 10,
                                    ),
                                    decoration: BoxDecoration(
                                      color: pillCream,
                                      borderRadius: BorderRadius.circular(28),
                                      border: Border.all(color: cardBorder),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.access_time_rounded,
                                          size: 16,
                                          color: txtPri,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          _workType,
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w900,
                                            color: txtPri,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),

                                const SizedBox(width: 8),

                                // Pill 3: Cream Pill with Briefcase Icon (Tahapan Status)
                                FluidBounceButton(
                                  onTap: _showStatusPicker,
                                  hapticEnabled: false,
                                  scaleFactor: 0.96,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 10,
                                    ),
                                    decoration: BoxDecoration(
                                      color: pillCream,
                                      borderRadius: BorderRadius.circular(28),
                                      border: Border.all(color: cardBorder),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.business_center_outlined,
                                          size: 16,
                                          color: txtPri,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          _status,
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w900,
                                            color: txtPri,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                        if (!_quickMode) const SizedBox(height: 20),

                        if (_quickMode)
                          _buildQuickModeCard(
                            isDark: isDark,
                            cardBg: cardBg,
                            cardBorder: cardBorder,
                            txtPri: txtPri,
                            txtSec: txtSec,
                          ),

                        // ── 7. STACKED BENTO CARD CONTAINER (MINIMUM QUALIFICATION & DETAIL FORM) ──
                        if (!_quickMode)
                          Stack(
                            clipBehavior: Clip.none,
                            alignment: Alignment.topCenter,
                            children: [
                              // Big Card Container
                              Container(
                                width: double.infinity,
                                margin: const EdgeInsets.only(top: 14),
                                padding: const EdgeInsets.fromLTRB(
                                  20,
                                  28,
                                  20,
                                  22,
                                ),
                                decoration: BoxDecoration(
                                  color: cardBg,
                                  borderRadius: BorderRadius.circular(32),
                                  border: Border.all(color: cardBorder),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(
                                        alpha: isDark ? 0.25 : 0.08,
                                      ),
                                      blurRadius: 18,
                                      offset: const Offset(0, 6),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Form Input: Nama Perusahaan
                                    Text(
                                      'Nama Perusahaan *',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w800,
                                        color: txtSec,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    TextFormField(
                                      controller: _companyController,
                                      maxLength: 80,
                                      textCapitalization:
                                          TextCapitalization.words,
                                      onChanged: (_) => setState(() {}),
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: txtPri,
                                      ),
                                      decoration: _buildInputDeco(
                                        hint:
                                            'Contoh: PT Bank Central Asia Tbk',
                                        icon: Icons.business_rounded,
                                        isDark: isDark,
                                      ),
                                      validator: (v) =>
                                          v == null || v.trim().isEmpty
                                          ? 'Nama Perusahaan wajib diisi'
                                          : null,
                                    ),

                                    const SizedBox(height: 14),

                                    // Form Input: Posisi Lowongan
                                    Text(
                                      'Posisi / Pekerjaan *',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w800,
                                        color: txtSec,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    TextFormField(
                                      controller: _positionController,
                                      maxLength: 100,
                                      textCapitalization:
                                          TextCapitalization.words,
                                      onChanged: (_) => setState(() {}),
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: txtPri,
                                      ),
                                      decoration: _buildInputDeco(
                                        hint:
                                            'Contoh: Software Development Engineer',
                                        icon: Icons.badge_rounded,
                                        isDark: isDark,
                                      ),
                                      validator: (v) =>
                                          v == null || v.trim().isEmpty
                                          ? 'Posisi lowongan wajib diisi'
                                          : null,
                                    ),

                                    const SizedBox(height: 14),

                                    // Form Input: Gaji Penawaran
                                    Text(
                                      'Gaji Penawaran (Bulan)',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w800,
                                        color: txtSec,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    TextFormField(
                                      controller: _salaryController,
                                      maxLength: 50,
                                      keyboardType: TextInputType.number,
                                      inputFormatters: [RupiahInputFormatter()],
                                      onChanged: (_) => setState(() {}),
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: txtPri,
                                      ),
                                      decoration: _buildInputDeco(
                                        hint: 'Contoh: Rp 15.000.000',
                                        icon: Icons.monetization_on_outlined,
                                        isDark: isDark,
                                      ),
                                    ),

                                    const SizedBox(height: 14),

                                    // Form Input: Lokasi Perusahaan
                                    Text(
                                      'Lokasi / Kota Penempatan',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w800,
                                        color: txtSec,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    TextFormField(
                                      controller: _locationController,
                                      maxLength: 80,
                                      textCapitalization:
                                          TextCapitalization.words,
                                      onChanged: (_) => setState(() {}),
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: txtPri,
                                      ),
                                      decoration: _buildInputDeco(
                                        hint:
                                            'Contoh: Jakarta Selatan, DKI Jakarta',
                                        icon: Icons.location_on_outlined,
                                        isDark: isDark,
                                      ),
                                    ),

                                    const SizedBox(height: 14),

                                    // Row: Tanggal Melamar & Tanggal Interview
                                    Row(
                                      children: [
                                        // Tanggal Melamar
                                        Expanded(
                                          child: FluidBounceButton(
                                            onTap: _pickAppliedDate,
                                            hapticEnabled: false,
                                            scaleFactor: 0.98,
                                            child: Container(
                                              padding: const EdgeInsets.all(12),
                                              decoration: BoxDecoration(
                                                color: isDark
                                                    ? const Color(0xFF282830)
                                                    : const Color(0xFFF9F7F2),
                                                borderRadius:
                                                    BorderRadius.circular(16),
                                                border: Border.all(
                                                  color: isDark
                                                      ? const Color(0xFF383842)
                                                      : const Color(0xFFE5E0D5),
                                                ),
                                              ),
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Row(
                                                    children: [
                                                      const Icon(
                                                        Icons
                                                            .event_available_rounded,
                                                        size: 14,
                                                        color: Color(
                                                          0xFF5C44E4,
                                                        ),
                                                      ),
                                                      const SizedBox(width: 4),
                                                      Text(
                                                        'Tgl Melamar',
                                                        style: TextStyle(
                                                          fontSize: 11,
                                                          fontWeight:
                                                              FontWeight.w800,
                                                          color: txtSec,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    DateFormat(
                                                      'dd MMM yyyy',
                                                      'id_ID',
                                                    ).format(_appliedDate),
                                                    style: TextStyle(
                                                      fontSize: 12.5,
                                                      fontWeight:
                                                          FontWeight.w900,
                                                      color: txtPri,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                        if (_hasSelectionStatus) ...[
                                          const SizedBox(width: 10),
                                          // Jadwal Tes / Interview
                                          Expanded(
                                            child: FluidBounceButton(
                                              onTap: _pickSelectionSchedule,
                                              hapticEnabled: false,
                                              scaleFactor: 0.98,
                                              child: Container(
                                                padding: const EdgeInsets.all(
                                                  12,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: _interviewDate != null
                                                      ? (isDark
                                                            ? const Color(
                                                                0xFF132E1D,
                                                              )
                                                            : const Color(
                                                                0xFFDCFCE7,
                                                              ))
                                                      : (isDark
                                                            ? const Color(
                                                                0xFF282830,
                                                              )
                                                            : const Color(
                                                                0xFFF9F7F2,
                                                              )),
                                                  borderRadius:
                                                      BorderRadius.circular(16),
                                                  border: Border.all(
                                                    color:
                                                        _interviewDate != null
                                                        ? const Color(
                                                            0xFF22C55E,
                                                          )
                                                        : (isDark
                                                              ? const Color(
                                                                  0xFF383842,
                                                                )
                                                              : const Color(
                                                                  0xFFE5E0D5,
                                                                )),
                                                  ),
                                                ),
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Row(
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .spaceBetween,
                                                      children: [
                                                        Row(
                                                          children: [
                                                            Icon(
                                                              Icons
                                                                  .alarm_on_rounded,
                                                              size: 14,
                                                              color:
                                                                  _interviewDate !=
                                                                      null
                                                                  ? const Color(
                                                                      0xFF22C55E,
                                                                    )
                                                                  : const Color(
                                                                      0xFF5C44E4,
                                                                    ),
                                                            ),
                                                            const SizedBox(
                                                              width: 4,
                                                            ),
                                                            Text(
                                                              'Jadwal Seleksi',
                                                              style: TextStyle(
                                                                fontSize: 11,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w800,
                                                                color:
                                                                    _interviewDate !=
                                                                        null
                                                                    ? const Color(
                                                                        0xFF22C55E,
                                                                      )
                                                                    : txtSec,
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                        if (_interviewDate !=
                                                            null)
                                                          FluidBounceButton(
                                                            onTap: () => setState(
                                                              () =>
                                                                  _interviewDate =
                                                                      null,
                                                            ),
                                                            child: const Icon(
                                                              Icons
                                                                  .close_rounded,
                                                              size: 14,
                                                              color:
                                                                  Colors.grey,
                                                            ),
                                                          ),
                                                      ],
                                                    ),
                                                    const SizedBox(height: 4),
                                                    Text(
                                                      _interviewDate != null
                                                          ? _formatSelectionSchedule(
                                                              _interviewDate!,
                                                            )
                                                          : '+ Tanggal & Jam',
                                                      style: TextStyle(
                                                        fontSize: 12.5,
                                                        fontWeight:
                                                            FontWeight.w900,
                                                        color:
                                                            _interviewDate !=
                                                                null
                                                            ? const Color(
                                                                0xFF22C55E,
                                                              )
                                                            : txtSec,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),

                                    const SizedBox(height: 14),

                                    // Form Input: Kontak HR
                                    Text(
                                      'Kontak HR (WhatsApp / Email)',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w800,
                                        color: txtSec,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    TextFormField(
                                      controller: _hrContactController,
                                      maxLength: 80,
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: txtPri,
                                      ),
                                      decoration: _buildInputDeco(
                                        hint:
                                            'hr.recruitment@perusahaan.com / +628...',
                                        icon: Icons.contact_mail_outlined,
                                        isDark: isDark,
                                      ),
                                    ),

                                    const SizedBox(height: 14),

                                    // Form Input: Deskripsi / Kualifikasi
                                    Text(
                                      'Kualifikasi & Deskripsi Singkat',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w800,
                                        color: txtSec,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    TextFormField(
                                      controller: _descriptionController,
                                      maxLength: 3000,
                                      maxLines: 4,
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                        color: txtPri,
                                        height: 1.4,
                                      ),
                                      decoration: InputDecoration(
                                        hintText:
                                            '• Minimal S1 Pengalaman 2 Tahun\n• Mahir Flutter & State Management\n• Mampu berkomunikasi efektif...',
                                        hintStyle: TextStyle(
                                          fontSize: 12.5,
                                          color: isDark
                                              ? const Color(0xFF8E8E93)
                                              : Colors.grey.shade400,
                                          height: 1.4,
                                        ),
                                        filled: true,
                                        fillColor: isDark
                                            ? const Color(0xFF282830)
                                            : const Color(0xFFF9F7F2),
                                        counterText: '',
                                        contentPadding: const EdgeInsets.all(
                                          14,
                                        ),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                          borderSide: BorderSide(
                                            color: isDark
                                                ? const Color(0xFF383842)
                                                : const Color(0xFFE5E0D5),
                                          ),
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                          borderSide: BorderSide(
                                            color: isDark
                                                ? const Color(0xFF383842)
                                                : const Color(0xFFE5E0D5),
                                          ),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                          borderSide: BorderSide(
                                            color: isDark
                                                ? const Color(0xFF5C44E4)
                                                : const Color(0xFF19191B),
                                            width: 1.8,
                                          ),
                                        ),
                                      ),
                                    ),

                                    const SizedBox(height: 16),

                                    // Screenshot Preview & Picker
                                    if (_screenshotPath != null &&
                                        _screenshotPath!.isNotEmpty) ...[
                                      Stack(
                                        children: [
                                          Container(
                                            height: 150,
                                            width: double.infinity,
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(18),
                                              image: DecorationImage(
                                                image: ResizeImage(
                                                  FileImage(
                                                    File(_screenshotPath!),
                                                  ),
                                                  width: 1080,
                                                ),
                                                fit: BoxFit.cover,
                                              ),
                                            ),
                                          ),
                                          Positioned(
                                            top: 8,
                                            right: 8,
                                            child: FluidBounceButton(
                                              onTap: () => setState(
                                                () => _screenshotPath = null,
                                              ),
                                              child: Container(
                                                padding: const EdgeInsets.all(
                                                  6,
                                                ),
                                                decoration: const BoxDecoration(
                                                  color: Colors.black87,
                                                  shape: BoxShape.circle,
                                                ),
                                                child: const Icon(
                                                  Icons.delete_outline_rounded,
                                                  color: Colors.white,
                                                  size: 18,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 10),
                                    ],

                                    SizedBox(
                                      width: double.infinity,
                                      height: 46,
                                      child: OutlinedButton.icon(
                                        onPressed: _pickScreenshot,
                                        icon: const Icon(
                                          Icons.add_photo_alternate_rounded,
                                          size: 18,
                                        ),
                                        label: Text(
                                          _screenshotPath != null
                                              ? 'Ganti Foto Screenshot'
                                              : 'Lampirkan Screenshot Poster Loker',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w800,
                                            fontSize: 12.5,
                                          ),
                                        ),
                                        style: OutlinedButton.styleFrom(
                                          side: BorderSide(
                                            color: isDark
                                                ? const Color(0xFF383842)
                                                : const Color(0xFFDCD8CE),
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              16,
                                            ),
                                          ),
                                          foregroundColor: txtPri,
                                          backgroundColor: isDark
                                              ? const Color(0xFF282830)
                                              : const Color(0xFFF9F7F2),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // Floating Header Pill (Minimum Qualification style)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: pillCream,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: isDark
                                        ? const Color(0xFF5C44E4)
                                        : const Color(0xFFF8BA38),
                                    width: 1.5,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(
                                        alpha: isDark ? 0.2 : 0.06,
                                      ),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Text(
                                  'Formulir Detail Lamaran',
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w900,
                                    color: txtPri,
                                    letterSpacing: -0.2,
                                  ),
                                ),
                              ),
                            ],
                          ),

                        // Tombol Hapus jika mode Edit
                        if (isEdit) ...[
                          const SizedBox(height: 10),
                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: OutlinedButton.icon(
                              onPressed: _deleteCurrentJob,
                              icon: const Icon(
                                Icons.delete_forever_rounded,
                                color: Color(0xFFE53935),
                                size: 18,
                              ),
                              label: const Text(
                                'Hapus Lamaran Ini',
                                style: TextStyle(
                                  color: Color(0xFFE53935),
                                  fontWeight: FontWeight.w900,
                                  fontSize: 13,
                                ),
                              ),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(
                                  color: Color(0xFFE53935),
                                  width: 1.4,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(24),
                                ),
                                backgroundColor: isDark
                                    ? const Color(0xFF1E1E24)
                                    : Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        bottomNavigationBar: SafeArea(
          top: false,
          child: Container(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 12),
            decoration: BoxDecoration(
              color: canvasBg,
              border: Border(
                top: BorderSide(
                  color: isDark
                      ? const Color(0xFF303038)
                      : const Color(0xFFE7E0D4),
                ),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.20 : 0.06),
                  blurRadius: 16,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _saveJob,
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDark
                      ? const Color(0xFF5C44E4)
                      : const Color(0xFF19191B),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                  ),
                ),
                child: _isSaving
                    ? const CupertinoActivityIndicator(color: Colors.white)
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Flexible(
                            child: Text(
                              _quickMode
                                  ? 'Catat Lamaran Cepat'
                                  : isEdit
                                  ? 'Simpan Perubahan Lamaran'
                                  : 'Catat Lamaran Sekarang',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.2,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Icon(
                            Icons.arrow_forward_rounded,
                            color: Colors.white,
                            size: 18,
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _buildInputDeco({
    required String hint,
    required IconData icon,
    bool isDark = false,
  }) {
    final inputBg = isDark ? const Color(0xFF282830) : const Color(0xFFF9F7F2);
    final inputBorder = isDark
        ? const Color(0xFF383842)
        : const Color(0xFFE5E0D5);
    final iconColor = isDark ? Colors.white70 : const Color(0xFF121214);
    final hintColor = isDark ? const Color(0xFF8E8E93) : Colors.grey.shade400;

    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(
        fontSize: 12.5,
        color: hintColor,
        fontWeight: FontWeight.w500,
      ),
      prefixIcon: Icon(icon, size: 18, color: iconColor),
      filled: true,
      fillColor: inputBg,
      counterText: '',
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: inputBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: inputBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(
          color: isDark ? const Color(0xFF5C44E4) : const Color(0xFF19191B),
          width: 1.8,
        ),
      ),
    );
  }
}
