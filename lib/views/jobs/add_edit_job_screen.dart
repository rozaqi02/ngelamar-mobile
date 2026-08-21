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
import '../../widgets/apple_toast.dart';
import '../../widgets/rupiah_input_formatter.dart';

/// Screen: Tambah & Edit Catatan Lamaran Kerja.
/// Didesain 100% presisi mengikuti referensi visual mockup:
/// - Latar belakang dominan Warm Vibrant Yellow (seperti kartu Amazon)
/// - Top Bar: Tombol bundar putih (Back), Logo Perusahaan bundar di tengah, Tombol Bookmark/Impor di kanan
/// - Nama Perusahaan besar tebal di tengah
/// - Pill Container Posisi/Role (Software Development Engineer style)
/// - Teks Lokasi dengan pin icon (📍 California, USA style)
/// - 3 Pill Chips horizontal: [ 🪙 Gaji ], [ ⏱️ Tipe Kerja ], [ 💼 Sumber/Status ]
/// - Section Card Putih melengkung tumpul (28px) dengan floating pill header "Kualifikasi & Detail Seleksi"
/// - Tombol Aksi Utama Pil Hitam Solid di bagian bawah: "Catat Lamaran Ini" / "Simpan Perubahan"
class AddEditJobScreen extends ConsumerStatefulWidget {
  final JobApplication? jobToEdit;
  final bool autoFocusPaste;

  const AddEditJobScreen({
    super.key,
    this.jobToEdit,
    this.autoFocusPaste = false,
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
  DateTime _appliedDate = DateTime.now();
  DateTime? _interviewDate;
  bool _isSaving = false;
  bool _isExtracting = false;
  bool _showSmartImport = false;

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
    _linkOrTextController = TextEditingController();
    _companyController = TextEditingController(text: j?.companyName ?? '');
    _positionController = TextEditingController(text: j?.position ?? '');
    _salaryController = TextEditingController(text: j?.salaryOffered ?? '');
    _locationController = TextEditingController(text: j?.location ?? '');
    _descriptionController = TextEditingController(text: j?.jobDescription ?? '');
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

  /// Tempel dari Clipboard & Ekstrak otomatis
  void _pasteFromClipboard() async {
    HapticFeedback.selectionClick();
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data?.text != null && data!.text!.trim().isNotEmpty) {
      _linkOrTextController.text = data.text!.trim();
      _extractFromLinkOrText();
    } else {
      if (mounted) {
        AppleToast.info(context, 'Clipboard kosong. Salin link/teks lowongan terlebih dahulu.');
      }
    }
  }

  /// Ekstraksi otomatis dari Link URL atau Teks Iklan
  void _extractFromLinkOrText() async {
    final text = _linkOrTextController.text.trim();
    if (text.isEmpty) {
      AppleToast.warning(context, 'Masukkan link atau teks lowongan terlebih dahulu.');
      return;
    }

    HapticFeedback.mediumImpact();
    setState(() => _isExtracting = true);

    try {
      final result = await TextParserService.extractFromUrlOrText(text);

      setState(() {
        if (result.companyName.isNotEmpty) _companyController.text = result.companyName;
        if (result.position.isNotEmpty) _positionController.text = result.position;
        if (result.salary != null) _salaryController.text = result.salary!;
        if (result.location != null) _locationController.text = result.location!;
        if (result.rawDescription.isNotEmpty) _descriptionController.text = result.rawDescription;
        if (result.hrContact != null) _hrContactController.text = result.hrContact!;
        if (result.jobUrl != null) _jobUrl = result.jobUrl;
        _workType = result.workType;
        _sourcePlatform = result.sourcePlatform;
        if (result.sourcePlatform != 'Manual' && _sourceOptions.contains(result.sourcePlatform)) {
          _jobSource = result.sourcePlatform;
        }
        _showSmartImport = false;
      });

      if (!mounted) return;
      AppleToast.success(
        context,
        'Berhasil Diekstrak!',
        subtitle: '${_positionController.text} di ${_companyController.text}',
      );
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
              'Foto / Logo Perusahaan',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF121214)),
            ),
            const SizedBox(height: 6),
            const Text(
              'Pilih foto logo atau perusahaan yang Anda lamar:',
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.photo_library_rounded, color: Color(0xFF5C44E4)),
              title: const Text('Pilih dari Galeri Foto', style: TextStyle(fontWeight: FontWeight.bold)),
              onTap: () {
                Navigator.pop(ctx);
                _processCompanyLogoPick(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt_rounded, color: Color(0xFF5C44E4)),
              title: const Text('Ambil dari Kamera', style: TextStyle(fontWeight: FontWeight.bold)),
              onTap: () {
                Navigator.pop(ctx);
                _processCompanyLogoPick(ImageSource.camera);
              },
            ),
            if (_companyLogoPath != null)
              ListTile(
                leading: const Icon(Icons.delete_outline_rounded, color: Color(0xFFE53935)),
                title: const Text('Hapus Foto Kustom', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFE53935))),
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
      final XFile? image = await picker.pickImage(source: source, maxWidth: 600, maxHeight: 600, imageQuality: 85);
      if (image != null && mounted) {
        final appDocDir = await getApplicationDocumentsDirectory();
        final logosDir = Directory('${appDocDir.path}/logos');
        if (!await logosDir.exists()) {
          await logosDir.create(recursive: true);
        }
        final fileName = 'logo_${DateTime.now().millisecondsSinceEpoch}.png';
        final savedImage = await File(image.path).copy('${logosDir.path}/$fileName');
        setState(() {
          _companyLogoPath = savedImage.path;
        });
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
              'Lampirkan Bukti / Screenshot Loker',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF121214)),
            ),
            const SizedBox(height: 6),
            const Text(
              'Simpan foto poster atau bukti lowongan kerja ini:',
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.photo_library_rounded, color: Color(0xFF5C44E4)),
              title: const Text('Pilih dari Galeri Foto', style: TextStyle(fontWeight: FontWeight.bold)),
              onTap: () {
                Navigator.pop(ctx);
                _processImagePick(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt_rounded, color: Color(0xFF5C44E4)),
              title: const Text('Ambil dari Kamera', style: TextStyle(fontWeight: FontWeight.bold)),
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
        final fileName = 'screenshot_${DateTime.now().millisecondsSinceEpoch}.png';
        final savedImage = await File(image.path).copy('${screenshotsDir.path}/$fileName');
        setState(() {
          _screenshotPath = savedImage.path;
        });
        if (mounted) {
          AppleToast.success(context, 'Screenshot loker berhasil dilampirkan!');
        }
      }
    } catch (_) {
      if (mounted) AppleToast.warning(context, 'Gagal memilih gambar.');
    }
  }

  /// Pilih Tanggal Melamar & Tanggal Jadwal Interview
  Future<void> _pickDate({required bool isInterview}) async {
    HapticFeedback.selectionClick();
    final initialDate = isInterview
        ? (_interviewDate ?? DateTime.now().add(const Duration(days: 3)))
        : _appliedDate;

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
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
      setState(() {
        if (isInterview) {
          _interviewDate = picked;
        } else {
          _appliedDate = picked;
        }
      });
    }
  }

  bool _hasUnsavedChanges() {
    if (widget.jobToEdit != null) {
      final j = widget.jobToEdit!;
      return _companyController.text != j.companyName ||
          _positionController.text != j.position ||
          _salaryController.text != (j.salaryOffered ?? '') ||
          _notesController.text != (j.notes ?? '') ||
          _status != j.status ||
          _screenshotPath != j.screenshotPath ||
          _companyLogoPath != j.companyLogoPath;
    }
    return _companyController.text.isNotEmpty ||
        _positionController.text.isNotEmpty ||
        _salaryController.text.isNotEmpty ||
        _notesController.text.isNotEmpty ||
        _screenshotPath != null ||
        _companyLogoPath != null;
  }

  Future<bool> _confirmDiscard() async {
    if (!_hasUnsavedChanges()) return true;
    HapticFeedback.warningNotification();
    final discard = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Buang Perubahan?', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('Informasi yang sudah Anda ketik belum tersimpan. Yakin ingin menutup form ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Lanjut Mengisi', style: TextStyle(color: Color(0xFF5C44E4), fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE53935),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: const Text('Buang', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
    return discard ?? false;
  }

  void _deleteCurrentJob() async {
    HapticFeedback.heavyImpact();
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Hapus Lamaran Ini?', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text(
          'Lamaran di ${widget.jobToEdit!.companyName} (${widget.jobToEdit!.position}) akan dihapus permanen.',
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
    if (_interviewDate != null && _interviewDate!.isBefore(DateTime(_appliedDate.year, _appliedDate.month, _appliedDate.day))) {
      AppleToast.warning(context, 'Tanggal wawancara tidak boleh sebelum tanggal melamar.');
      return;
    }

    setState(() => _isSaving = true);

    final isEdit = widget.jobToEdit != null;
    final id = isEdit
        ? widget.jobToEdit!.id
        : 'job_${DateTime.now().millisecondsSinceEpoch}';

    final salaryText = _salaryController.text.trim();
    final salaryRange = SalaryEvaluatorService.parseSalaryRange(salaryText);

    final newJob = JobApplication(
      id: id,
      companyName: _companyController.text.trim(),
      position: _positionController.text.trim(),
      status: _status,
      appliedDate: _appliedDate,
      salaryOffered: salaryText.isEmpty ? null : salaryText,
      minSalary: salaryRange.min > 0 ? salaryRange.min.toInt() : null,
      maxSalary: salaryRange.max > 0 ? salaryRange.max.toInt() : null,
      workType: _workType,
      location: _locationController.text.trim().isEmpty ? null : _locationController.text.trim(),
      jobSource: _jobSource,
      sourcePlatform: _sourcePlatform,
      jobUrl: _jobUrl,
      jobDescription: _descriptionController.text.trim(),
      hrContact: _hrContactController.text.trim().isEmpty ? null : _hrContactController.text.trim(),
      interviewDate: _interviewDate,
      testDate: _interviewDate,
      notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      isFavorite: widget.jobToEdit?.isFavorite ?? false,
      screenshotPath: _screenshotPath,
      companyLogoPath: _companyLogoPath,
    );

    try {
      if (isEdit) {
        await ref.read(jobProvider.notifier).updateJob(newJob);
      } else {
        await ref.read(jobProvider.notifier).addJob(newJob);
      }

      if (newJob.interviewDate != null && mounted) {
        NotificationService.promptPermissionIfNeeded(context).catchError((Object error) {
          debugPrint('Permintaan izin notifikasi gagal: $error');
          return false;
        });
      }

      if (!mounted) return;
      Navigator.pop(context, newJob);
    } catch (error) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      AppleToast.error(context, 'Lamaran gagal disimpan.');
    }
  }

  void _showWorkTypePicker() {
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
              'Pilih Tipe Kerja',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF121214)),
            ),
            const SizedBox(height: 14),
            ..._workTypeOptions.map((type) {
              final isSel = _workType == type;
              return ListTile(
                leading: Icon(
                  type == 'WFH' ? Icons.home_work_rounded : (type == 'Hybrid' ? Icons.sync_alt_rounded : Icons.apartment_rounded),
                  color: isSel ? const Color(0xFFF8BA38) : const Color(0xFF121214),
                ),
                title: Text(
                  type,
                  style: TextStyle(fontWeight: isSel ? FontWeight.w900 : FontWeight.w600),
                ),
                trailing: isSel ? const Icon(Icons.check_circle_rounded, color: Color(0xFF19191B)) : null,
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
              'Pilih Tahapan Status Lamaran',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF121214)),
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
                  style: TextStyle(fontWeight: isSel ? FontWeight.w900 : FontWeight.w600),
                ),
                trailing: isSel ? const Icon(Icons.check_circle_rounded, color: Color(0xFF19191B)) : null,
                onTap: () {
                  setState(() => _status = st);
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
    final bottomInset = MediaQuery.of(context).padding.bottom;
    const canvasYellow = Color(0xFFF8BA38); // Exact Amazon Mustard Yellow from mockup
    const pillCream = Color(0xFFFDE7A8); // Exact pill cream container from mockup

    final displayCompany = _companyController.text.trim().isNotEmpty
        ? _companyController.text.trim()
        : 'Nama Perusahaan';
    final displayPosition = _positionController.text.trim().isNotEmpty
        ? _positionController.text.trim()
        : 'Posisi / Role Pekerjaan.';
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
        backgroundColor: canvasYellow,
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: EdgeInsets.fromLTRB(20, 10, 20, 20 + bottomInset),
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
                            GestureDetector(
                              onTap: () async {
                                final discard = await _confirmDiscard();
                                if (discard && context.mounted) {
                                  Navigator.pop(context);
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
                                      color: Colors.black.withValues(alpha: 0.08),
                                      blurRadius: 10,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: const Center(
                                  child: Icon(CupertinoIcons.chevron_back, color: Color(0xFF121214), size: 22),
                                ),
                              ),
                            ),

                            // Center Circular Logo Container
                            GestureDetector(
                              onTap: _pickCompanyLogo,
                              child: Stack(
                                children: [
                                  Container(
                                    width: 64,
                                    height: 64,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(alpha: 0.12),
                                          blurRadius: 12,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: ClipOval(
                                      child: _companyLogoPath != null && File(_companyLogoPath!).existsSync()
                                          ? Image.file(
                                              File(_companyLogoPath!),
                                              width: 64,
                                              height: 64,
                                              fit: BoxFit.cover,
                                              cacheWidth: (64 * MediaQuery.of(context).devicePixelRatio).round(),
                                              cacheHeight: (64 * MediaQuery.of(context).devicePixelRatio).round(),
                                            )
                                          : Center(
                                              child: Text(
                                                displayCompany.isNotEmpty ? displayCompany[0].toUpperCase() : '🏢',
                                                style: const TextStyle(
                                                  fontSize: 28,
                                                  fontWeight: FontWeight.w900,
                                                  color: Color(0xFF121214),
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
                                      decoration: const BoxDecoration(
                                        color: Color(0xFF19191B),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 12),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Right Circular Bookmark / Smart Auto-Fill Button
                            GestureDetector(
                              onTap: () {
                                HapticFeedback.selectionClick();
                                setState(() => _showSmartImport = !_showSmartImport);
                              },
                              child: Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.08),
                                      blurRadius: 10,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: Center(
                                  child: Icon(
                                    _showSmartImport ? Icons.close_rounded : Icons.auto_awesome_rounded,
                                    color: const Color(0xFF121214),
                                    size: 20,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        // ── 2. SMART AUTO-FILL ACCORDION (JIKA DIAKTIFKAN) ──
                        if (_showSmartImport) ...[
                          Container(
                            padding: const EdgeInsets.all(16),
                            margin: const EdgeInsets.only(bottom: 16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.08),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Row(
                                      children: [
                                        Icon(Icons.auto_awesome_rounded, color: Color(0xFF5C44E4), size: 18),
                                        SizedBox(width: 6),
                                        Text(
                                          'Impor dari Link / Teks Loker',
                                          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13),
                                        ),
                                      ],
                                    ),
                                    GestureDetector(
                                      onTap: _pasteFromClipboard,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF19191B),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: const Text(
                                          'Tempel Clipboard',
                                          style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                TextField(
                                  controller: _linkOrTextController,
                                  maxLines: 2,
                                  style: const TextStyle(fontSize: 12.5),
                                  decoration: InputDecoration(
                                    hintText: 'Tempel link LinkedIn, Glints, JobStreet, atau teks loker...',
                                    fillColor: const Color(0xFFF9F7F2),
                                    filled: true,
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(14),
                                      borderSide: BorderSide(color: Colors.grey.shade300),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 10),
                                SizedBox(
                                  width: double.infinity,
                                  height: 42,
                                  child: ElevatedButton(
                                    onPressed: _isExtracting ? null : _extractFromLinkOrText,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF5C44E4),
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                    ),
                                    child: _isExtracting
                                        ? const CupertinoActivityIndicator(color: Colors.white)
                                        : const Text('Ekstrak & Isi Otomatis ✨', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],

                        // ── 3. COMPANY NAME (LARGE BOLD EDITORIAL TYPOGRAPHY - PERSIS MOCKUP) ──
                        Text(
                          displayCompany,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 27,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF121214),
                            letterSpacing: -0.6,
                          ),
                        ),

                        const SizedBox(height: 8),

                        // ── 4. POSITION PILL BADGE CONTAINER (PERSIS MOCKUP) ──
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 9),
                          decoration: BoxDecoration(
                            color: pillCream,
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: Text(
                            displayPosition,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF121214),
                              letterSpacing: -0.2,
                            ),
                          ),
                        ),

                        const SizedBox(height: 8),

                        // ── 5. LOCATION (📍 LOCATION WITH PIN - PERSIS MOCKUP) ──
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.location_on_outlined, size: 15, color: Color(0xFF121214)),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                displayLocation,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF121214),
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 18),

                        // ── 6. THREE HORIZONTAL INFO PILLS (GAJI, WORK TYPE, STATUS) - PERSIS MOCKUP ──
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // Pill 1: White Pill with Black Circle Coin (Gaji)
                              Container(
                                padding: const EdgeInsets.fromLTRB(6, 6, 16, 6),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(28),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.05),
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
                                      decoration: const BoxDecoration(
                                        color: Color(0xFF1C1C1E),
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
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w900,
                                        color: Color(0xFF121214),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(width: 8),

                              // Pill 2: Cream Pill with Clock Icon (Tipe Kerja)
                              GestureDetector(
                                onTap: _showWorkTypePicker,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: pillCream,
                                    borderRadius: BorderRadius.circular(28),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.access_time_rounded, size: 16, color: Color(0xFF121214)),
                                      const SizedBox(width: 6),
                                      Text(
                                        _workType,
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w900,
                                          color: Color(0xFF121214),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                              const SizedBox(width: 8),

                              // Pill 3: Cream Pill with Briefcase Icon (Tahapan Status)
                              GestureDetector(
                                onTap: _showStatusPicker,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: pillCream,
                                    borderRadius: BorderRadius.circular(28),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.business_center_outlined, size: 16, color: Color(0xFF121214)),
                                      const SizedBox(width: 6),
                                      Text(
                                        _status,
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w900,
                                          color: Color(0xFF121214),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 20),

                        // ── 7. STACKED BENTO CARD CONTAINER (MINIMUM QUALIFICATION & DETAIL FORM) ──
                        Stack(
                          clipBehavior: Clip.none,
                          alignment: Alignment.topCenter,
                          children: [
                            // Big White Card Container
                            Container(
                              width: double.infinity,
                              margin: const EdgeInsets.only(top: 14),
                              padding: const EdgeInsets.fromLTRB(20, 28, 20, 22),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(32),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.08),
                                    blurRadius: 18,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Form Input: Nama Perusahaan
                                  const Text(
                                    'Nama Perusahaan *',
                                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF555558)),
                                  ),
                                  const SizedBox(height: 6),
                                  TextFormField(
                                    controller: _companyController,
                                    maxLength: 80,
                                    textCapitalization: TextCapitalization.words,
                                    onChanged: (_) => setState(() {}),
                                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF121214)),
                                    decoration: _buildInputDeco(
                                      hint: 'Contoh: PT Bank Central Asia Tbk',
                                      icon: Icons.business_rounded,
                                    ),
                                    validator: (v) => v == null || v.trim().isEmpty ? 'Nama Perusahaan wajib diisi' : null,
                                  ),

                                  const SizedBox(height: 14),

                                  // Form Input: Posisi Lowongan
                                  const Text(
                                    'Posisi / Pekerjaan *',
                                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF555558)),
                                  ),
                                  const SizedBox(height: 6),
                                  TextFormField(
                                    controller: _positionController,
                                    maxLength: 100,
                                    textCapitalization: TextCapitalization.words,
                                    onChanged: (_) => setState(() {}),
                                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF121214)),
                                    decoration: _buildInputDeco(
                                      hint: 'Contoh: Software Development Engineer',
                                      icon: Icons.badge_rounded,
                                    ),
                                    validator: (v) => v == null || v.trim().isEmpty ? 'Posisi lowongan wajib diisi' : null,
                                  ),

                                  const SizedBox(height: 14),

                                  // Form Input: Gaji Penawaran
                                  const Text(
                                    'Gaji Penawaran (Bulan)',
                                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF555558)),
                                  ),
                                  const SizedBox(height: 6),
                                  TextFormField(
                                    controller: _salaryController,
                                    maxLength: 50,
                                    keyboardType: TextInputType.number,
                                    inputFormatters: [RupiahInputFormatter()],
                                    onChanged: (_) => setState(() {}),
                                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF121214)),
                                    decoration: _buildInputDeco(
                                      hint: 'Contoh: Rp 15.000.000',
                                      icon: Icons.monetization_on_outlined,
                                    ),
                                  ),

                                  const SizedBox(height: 14),

                                  // Form Input: Lokasi Perusahaan
                                  const Text(
                                    'Lokasi / Kota Penempatan',
                                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF555558)),
                                  ),
                                  const SizedBox(height: 6),
                                  TextFormField(
                                    controller: _locationController,
                                    maxLength: 80,
                                    textCapitalization: TextCapitalization.words,
                                    onChanged: (_) => setState(() {}),
                                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF121214)),
                                    decoration: _buildInputDeco(
                                      hint: 'Contoh: Jakarta Selatan, DKI Jakarta',
                                      icon: Icons.location_on_outlined,
                                    ),
                                  ),

                                  const SizedBox(height: 14),

                                  // Row: Tanggal Melamar & Tanggal Interview
                                  Row(
                                    children: [
                                      // Tanggal Melamar
                                      Expanded(
                                        child: GestureDetector(
                                          onTap: () => _pickDate(isInterview: false),
                                          child: Container(
                                            padding: const EdgeInsets.all(12),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFF9F7F2),
                                              borderRadius: BorderRadius.circular(16),
                                              border: Border.all(color: const Color(0xFFE5E0D5)),
                                            ),
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                const Row(
                                                  children: [
                                                    Icon(Icons.event_available_rounded, size: 14, color: Color(0xFF5C44E4)),
                                                    SizedBox(width: 4),
                                                    Text('Tgl Melamar', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF555558))),
                                                  ],
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  DateFormat('dd MMM yyyy', 'id_ID').format(_appliedDate),
                                                  style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w900, color: Color(0xFF121214)),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      // Tanggal Interview
                                      Expanded(
                                        child: GestureDetector(
                                          onTap: () => _pickDate(isInterview: true),
                                          child: Container(
                                            padding: const EdgeInsets.all(12),
                                            decoration: BoxDecoration(
                                              color: _interviewDate != null ? const Color(0xFFDCFCE7) : const Color(0xFFF9F7F2),
                                              borderRadius: BorderRadius.circular(16),
                                              border: Border.all(
                                                color: _interviewDate != null ? const Color(0xFF15803D) : const Color(0xFFE5E0D5),
                                              ),
                                            ),
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                  children: [
                                                    const Row(
                                                      children: [
                                                        Icon(Icons.alarm_on_rounded, size: 14, color: Color(0xFF15803D)),
                                                        SizedBox(width: 4),
                                                        Text('Jadwal Tes/HR', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF15803D))),
                                                      ],
                                                    ),
                                                    if (_interviewDate != null)
                                                      GestureDetector(
                                                        onTap: () => setState(() => _interviewDate = null),
                                                        child: const Icon(Icons.close_rounded, size: 14, color: Colors.grey),
                                                      ),
                                                  ],
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  _interviewDate != null
                                                      ? DateFormat('dd MMM yyyy', 'id_ID').format(_interviewDate!)
                                                      : '+ Pasang Alarm',
                                                  style: TextStyle(
                                                    fontSize: 12.5,
                                                    fontWeight: FontWeight.w900,
                                                    color: _interviewDate != null ? const Color(0xFF15803D) : const Color(0xFF707074),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),

                                  const SizedBox(height: 14),

                                  // Form Input: Kontak HR
                                  const Text(
                                    'Kontak HR (WhatsApp / Email)',
                                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF555558)),
                                  ),
                                  const SizedBox(height: 6),
                                  TextFormField(
                                    controller: _hrContactController,
                                    maxLength: 80,
                                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF121214)),
                                    decoration: _buildInputDeco(
                                      hint: 'hr.recruitment@perusahaan.com / +628...',
                                      icon: Icons.contact_mail_outlined,
                                    ),
                                  ),

                                  const SizedBox(height: 14),

                                  // Form Input: Deskripsi / Kualifikasi
                                  const Text(
                                    'Kualifikasi & Deskripsi Singkat',
                                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF555558)),
                                  ),
                                  const SizedBox(height: 6),
                                  TextFormField(
                                    controller: _descriptionController,
                                    maxLength: 600,
                                    maxLines: 4,
                                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF121214), height: 1.4),
                                    decoration: InputDecoration(
                                      hintText: '• Minimal S1 Pengalaman 2 Tahun\n• Mahir Flutter & State Management\n• Mampu berkomunikasi efektif...',
                                      hintStyle: TextStyle(fontSize: 12.5, color: Colors.grey.shade400, height: 1.4),
                                      filled: true,
                                      fillColor: const Color(0xFFF9F7F2),
                                      counterText: '',
                                      contentPadding: const EdgeInsets.all(14),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(16),
                                        borderSide: const BorderSide(color: Color(0xFFE5E0D5)),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(16),
                                        borderSide: const BorderSide(color: Color(0xFFE5E0D5)),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(16),
                                        borderSide: const BorderSide(color: Color(0xFF19191B), width: 1.8),
                                      ),
                                    ),
                                  ),

                                  const SizedBox(height: 16),

                                  // Screenshot Preview & Picker
                                  if (_screenshotPath != null && _screenshotPath!.isNotEmpty) ...[
                                    Stack(
                                      children: [
                                        Container(
                                          height: 150,
                                          width: double.infinity,
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(18),
                                            image: DecorationImage(
                                              image: ResizeImage(FileImage(File(_screenshotPath!)), width: 1080),
                                              fit: BoxFit.cover,
                                            ),
                                          ),
                                        ),
                                        Positioned(
                                          top: 8,
                                          right: 8,
                                          child: GestureDetector(
                                            onTap: () => setState(() => _screenshotPath = null),
                                            child: Container(
                                              padding: const EdgeInsets.all(6),
                                              decoration: const BoxDecoration(
                                                color: Colors.black87,
                                                shape: BoxShape.circle,
                                              ),
                                              child: const Icon(Icons.delete_outline_rounded, color: Colors.white, size: 18),
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
                                      icon: const Icon(Icons.add_photo_alternate_rounded, size: 18),
                                      label: Text(
                                        _screenshotPath != null ? 'Ganti Foto Screenshot' : 'Lampirkan Screenshot Poster Loker',
                                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12.5),
                                      ),
                                      style: OutlinedButton.styleFrom(
                                        side: const BorderSide(color: Color(0xFFDCD8CE)),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                        foregroundColor: const Color(0xFF121214),
                                        backgroundColor: const Color(0xFFF9F7F2),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Floating Header Pill (Minimum Qualification style)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                              decoration: BoxDecoration(
                                color: pillCream,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: canvasYellow, width: 1.5),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.06),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: const Text(
                                'Formulir Detail Lamaran',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xFF121214),
                                  letterSpacing: -0.2,
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 24),

                        // ── 8. SOLID BLACK PILL BUTTON (APPLY FOR THIS JOB STYLE - PERSIS MOCKUP) ──
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: _isSaving ? null : _saveJob,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF19191B),
                              foregroundColor: Colors.white,
                              elevation: 4,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(28),
                              ),
                            ),
                            child: _isSaving
                                ? const CupertinoActivityIndicator(color: Colors.white)
                                : Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        isEdit ? 'Simpan Perubahan Lamaran' : 'Catat Lamaran Sekarang',
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w900,
                                          letterSpacing: -0.2,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 18),
                                    ],
                                  ),
                          ),
                        ),

                        // Tombol Hapus jika mode Edit
                        if (isEdit) ...[
                          const SizedBox(height: 10),
                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: OutlinedButton.icon(
                              onPressed: _deleteCurrentJob,
                              icon: const Icon(Icons.delete_forever_rounded, color: Color(0xFFE53935), size: 18),
                              label: const Text(
                                'Hapus Lamaran Ini',
                                style: TextStyle(color: Color(0xFFE53935), fontWeight: FontWeight.w900, fontSize: 13),
                              ),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: Color(0xFFE53935), width: 1.4),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                                backgroundColor: Colors.white,
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
      ),
    );
  }

  InputDecoration _buildInputDeco({
    required String hint,
    required IconData icon,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(fontSize: 12.5, color: Colors.grey.shade400, fontWeight: FontWeight.w500),
      prefixIcon: Icon(icon, size: 18, color: const Color(0xFF121214)),
      filled: true,
      fillColor: const Color(0xFFF9F7F2),
      counterText: '',
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFFE5E0D5)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFFE5E0D5)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFF19191B), width: 1.8),
      ),
    );
  }
}
