import 'dart:async';
import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import '../../models/job_application.dart';
import '../../providers/job_provider.dart';
import '../../services/notification_service.dart';
import '../../services/salary_evaluator_service.dart';
import '../../services/spreadsheet_import_service.dart';
import '../../services/text_parser_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_dialog.dart';
import '../../widgets/app_motion.dart';
import '../../widgets/apple_animations.dart';
import '../../widgets/apple_toast.dart';
import '../../widgets/company_logo_badge.dart';
import '../../widgets/delight_celebration.dart';
import '../../widgets/rupiah_input_formatter.dart';
import '../../widgets/app_layout_metrics.dart';
import 'job_detail_screen.dart';

/// Screen: Tambah & Edit Catatan Lamaran Kerja.
/// Catat Cepat: satu kartu. Detail Lengkap: tiga grup (siapa, syarat, catatan).
class AddEditJobScreen extends ConsumerStatefulWidget {
  final JobApplication? jobToEdit;
  final bool autoFocusPaste;
  final bool startQuickMode;
  final String actionHeroTag;
  final String? initialSharedText;

  const AddEditJobScreen({
    super.key,
    this.jobToEdit,
    this.autoFocusPaste = false,
    this.startQuickMode = false,
    this.actionHeroTag = 'main_nav_action_button',
    this.initialSharedText,
  });

  @override
  ConsumerState<AddEditJobScreen> createState() => _AddEditJobScreenState();
}

class _AddEditJobScreenState extends ConsumerState<AddEditJobScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _linkOrTextController;
  late TextEditingController _companyController;
  late TextEditingController _positionController;
  late TextEditingController _urlController;
  late TextEditingController _salaryController;
  late TextEditingController _locationController;
  late TextEditingController _descriptionController;
  late TextEditingController _hrContactController;
  late TextEditingController _notesController;
  late TextEditingController _nextActionNoteController;
  late TextEditingController _labelsController;

  String _status = 'Dikirim';
  String _workType = 'Belum ditentukan';
  String _jobSource = 'LinkedIn';
  String _sourcePlatform = 'Manual';
  String _priority = 'Normal';
  String _nextActionType = 'Tindak lanjut';
  String? _jobUrl;
  String? _screenshotPath;
  String? _companyLogoPath;
  String? _pdfCvPath;
  final Set<String> _draftAttachmentPaths = <String>{};
  DateTime _appliedDate = DateTime.now();
  DateTime? _interviewDate;
  DateTime? _nextActionAt;
  bool _isSaving = false;
  bool _isSaveComplete = false;
  bool _isExtracting = false;
  bool _showSmartImport = false;
  bool _quickMode = false;
  bool _notesExpanded = false;

  final List<String> _statusOptions = [
    'Tersimpan',
    'Draft',
    'Dikirim',
    'Tes / Psikotes',
    'Interview HR',
    'Interview User',
    'Offering',
    'Diterima',
    'Ditolak',
    'Dibatalkan',
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
    _linkOrTextController = TextEditingController(
      text: widget.initialSharedText?.trim() ?? '',
    );
    _companyController = TextEditingController(text: j?.companyName ?? '');
    _positionController = TextEditingController(text: j?.position ?? '');
    _urlController = TextEditingController(text: j?.jobUrl ?? '');
    _salaryController = TextEditingController(text: j?.salaryOffered ?? '');
    _locationController = TextEditingController(text: j?.location ?? '');
    _descriptionController = TextEditingController(
      text: j?.jobDescription ?? '',
    );
    _hrContactController = TextEditingController(text: j?.hrContact ?? '');
    _notesController = TextEditingController(text: j?.notes ?? '');
    _nextActionNoteController = TextEditingController(
      text: j?.nextActionNote ?? '',
    );
    _labelsController = TextEditingController(text: j?.labels.join(', ') ?? '');

    if (j == null) {
      _status = 'Tersimpan';
      // Catat cepat tidak menanyakan mode kerja; selalu belum ditentukan.
      _workType = 'Belum ditentukan';
    } else {
      _status = j.status == 'HR Screening' ? 'Interview HR' : j.status;
      _workType = j.workType;
      _jobSource = j.jobSource ?? 'LinkedIn';
      _sourcePlatform = j.sourcePlatform;
      _jobUrl = j.jobUrl;
      _screenshotPath = j.screenshotPath;
      _companyLogoPath = j.companyLogoPath;
      _pdfCvPath = j.pdfCvPath;
      _appliedDate = j.appliedDate;
      _interviewDate = j.interviewDate ?? j.testDate;
      _priority = j.priority;
      _nextActionType = j.nextActionType ?? 'Tindak lanjut';
      _nextActionAt = j.nextActionAt;
      _notesExpanded =
          j.jobDescription.trim().isNotEmpty ||
          (j.hrContact?.trim().isNotEmpty ?? false) ||
          (j.notes?.trim().isNotEmpty ?? false) ||
          (j.screenshotPath?.isNotEmpty ?? false) ||
          (j.pdfCvPath?.isNotEmpty ?? false) ||
          (j.nextActionNote?.trim().isNotEmpty ?? false);
    }
    if (j == null && widget.initialSharedText?.trim().isNotEmpty == true) {
      _showSmartImport = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _extractFromLinkOrText();
      });
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
    _urlController.dispose();
    _salaryController.dispose();
    _locationController.dispose();
    _descriptionController.dispose();
    _hrContactController.dispose();
    _notesController.dispose();
    _nextActionNoteController.dispose();
    _labelsController.dispose();
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

  Future<void> _importSpreadsheet() async {
    HapticFeedback.selectionClick();
    try {
      final picked = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['xlsx', 'xls', 'csv'],
        withData: true,
      );
      if (picked == null || picked.files.isEmpty) return;
      final file = picked.files.single;
      final bytes =
          file.bytes ??
          (file.path == null ? null : await File(file.path!).readAsBytes());
      if (bytes == null) {
        throw const SpreadsheetImportException('Berkas tidak dapat dibaca.');
      }
      final parsed = SpreadsheetImportService.parse(
        bytes: Uint8List.fromList(bytes),
        fileName: file.name,
      );
      if (!mounted) return;
      if (parsed.jobs.isEmpty) {
        AppleToast.warning(
          context,
          'Tidak ada baris lamaran yang bisa diimpor.',
          subtitle: parsed.warnings.isEmpty
              ? 'Pastikan kolom Perusahaan dan Posisi terisi.'
              : parsed.warnings.first,
        );
        return;
      }
      if (parsed.jobs.length == 1) {
        final job = parsed.jobs.first;
        setState(() {
          _companyController.text = job.companyName;
          _positionController.text = job.position;
          if (job.location != null) _locationController.text = job.location!;
          if (job.salaryOffered != null) {
            _salaryController.text = job.salaryOffered!;
          }
          if (job.jobUrl != null) _urlController.text = job.jobUrl!;
          if (job.hrContact != null) _hrContactController.text = job.hrContact!;
          if (job.jobDescription.isNotEmpty) {
            _descriptionController.text = job.jobDescription;
          }
          if (job.notes != null) _notesController.text = job.notes!;
          _status = job.status;
          if (!_quickMode) _workType = job.workType;
          _jobSource = job.jobSource ?? _jobSource;
          _sourcePlatform = 'Excel';
          _showSmartImport = false;
        });
        AppleToast.success(context, '1 lamaran dari Excel diisi ke formulir.');
        return;
      }

      final confirmed = await _showSpreadsheetPreview(parsed);
      if (confirmed != true || !mounted) return;
      final result = await ref
          .read(jobProvider.notifier)
          .importJobs(parsed.jobs);
      if (!mounted) return;
      AppleToast.success(
        context,
        '${result.importedCount} lamaran masuk dari Excel${result.skippedCount > 0 ? ', ${result.skippedCount} duplikat dilewati' : ''}.',
      );
      Navigator.pop(context);
    } on SpreadsheetImportException catch (error) {
      if (mounted) AppleToast.warning(context, error.message);
    } catch (_) {
      if (mounted) {
        AppleToast.warning(context, 'Berkas Excel belum dapat dibaca.');
      }
    }
  }

  Future<bool?> _showSpreadsheetPreview(SpreadsheetImportResult parsed) {
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
            Text(
              'Impor ${parsed.jobs.length} lamaran',
              style: TextStyle(
                fontSize: 16.5,
                fontWeight: FontWeight.w900,
                color: txtPri,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              parsed.skippedInvalid + parsed.skippedEmpty > 0
                  ? '${parsed.skippedInvalid + parsed.skippedEmpty} baris dilewati. Duplikat akan diabaikan saat menyimpan.'
                  : 'Duplikat perusahaan + posisi akan dilewati.',
              style: TextStyle(fontSize: 12.5, color: txtSec, height: 1.4),
            ),
            const SizedBox(height: 14),
            ...parsed.jobs
                .take(3)
                .map(
                  (job) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      '${job.companyName} • ${job.position}',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: txtPri,
                      ),
                    ),
                  ),
                ),
            if (parsed.jobs.length > 3)
              Text(
                '+${parsed.jobs.length - 3} lamaran lainnya',
                style: TextStyle(fontSize: 12, color: txtSec),
              ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: const Text('Batal'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF5C44E4),
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Impor ke Tracker'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
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
        if (result.hasUsableCompany) 'perusahaan',
        if (result.hasUsablePosition) 'posisi',
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

      final confirmed = await _showExtractionPreviewModal(context, result);
      if (confirmed != true || !mounted) return;

      setState(() {
        if (result.hasUsableCompany) {
          _companyController.text = result.companyName;
        }
        if (result.hasUsablePosition) {
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
        if (result.jobUrl != null && result.jobUrl!.isNotEmpty) {
          _jobUrl = result.jobUrl;
          _urlController.text = result.jobUrl!;
        } else if (text.startsWith('http://') || text.startsWith('https://')) {
          _urlController.text = text;
        }
        if (result.workType.isNotEmpty && !_quickMode) {
          _workType = result.workType;
        }
        _sourcePlatform = result.sourcePlatform;
        if (result.sourcePlatform != 'Manual' &&
            _sourceOptions.contains(result.sourcePlatform)) {
          _jobSource = result.sourcePlatform;
        }
        if (widget.jobToEdit == null) {
          _status = 'Tersimpan';
        }
      });

      AppleToast.success(
        context,
        '${extractedFields.length} bagian berhasil ditemukan',
        subtitle: extractedFields.join(', '),
      );
      if (result.hasUsableCompany && result.hasUsablePosition) {
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

  Future<bool?> _showExtractionPreviewModal(
    BuildContext context,
    ParsedJobData result,
  ) {
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
                    color: const Color(0xFF5C44E4).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.auto_fix_high_rounded,
                    color: Color(0xFF5C44E4),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Pratinjau Ekstraksi Pintar',
                        style: TextStyle(
                          fontSize: 16.5,
                          fontWeight: FontWeight.w900,
                          color: txtPri,
                        ),
                      ),
                      Text(
                        'Periksa informasi yang berhasil dideteksi',
                        style: TextStyle(fontSize: 12, color: txtSec),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildPreviewRow(
              'Posisi',
              result.hasUsablePosition ? result.position : '-',
              txtPri,
              txtSec,
            ),
            _buildPreviewRow(
              'Perusahaan',
              result.hasUsableCompany ? result.companyName : '-',
              txtPri,
              txtSec,
            ),
            _buildPreviewRow(
              'Gaji',
              result.salary ?? 'Belum dicantumkan',
              txtPri,
              txtSec,
            ),
            _buildPreviewRow('Mode Kerja', result.workType, txtPri, txtSec),
            if (result.location != null && result.location!.isNotEmpty)
              _buildPreviewRow('Lokasi', result.location!, txtPri, txtSec),
            if (result.hrContact != null && result.hrContact!.isNotEmpty)
              _buildPreviewRow('Kontak HR', result.hrContact!, txtPri, txtSec),
            if (result.hasUsableCompany && result.hasUsablePosition)
              Builder(
                builder: (_) {
                  final duplicate = ref
                      .read(jobProvider.notifier)
                      .findDuplicate(
                        companyName: result.companyName,
                        position: result.position,
                      );
                  if (duplicate == null) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Text(
                      'Lamaran ${duplicate.position} di ${duplicate.companyName} sudah ada di tracker.',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFFC2410C),
                        height: 1.35,
                      ),
                    ),
                  );
                },
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
                      backgroundColor: const Color(0xFF5C44E4),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Gunakan Data Ini',
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

  Widget _buildPreviewRow(
    String label,
    String value,
    Color txtPri,
    Color txtSec,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: txtSec,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: txtPri,
              ),
            ),
          ),
        ],
      ),
    );
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

  /// Lampirkan Dokumen PDF CV yang Dikirimkan
  Future<void> _pickPdfCv() async {
    HapticFeedback.selectionClick();
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );
      if (result != null && result.files.single.path != null) {
        final src = File(result.files.single.path!);
        final appDocDir = await getApplicationDocumentsDirectory();
        final cvDir = Directory('${appDocDir.path}/cv_docs');
        if (!await cvDir.exists()) {
          await cvDir.create(recursive: true);
        }
        final fileName = 'cv_${DateTime.now().millisecondsSinceEpoch}.pdf';
        final savedFile = await src.copy('${cvDir.path}/$fileName');
        final previousPath = _pdfCvPath;
        if (previousPath != null &&
            _draftAttachmentPaths.remove(previousPath)) {
          final previousFile = File(previousPath);
          if (await previousFile.exists()) await previousFile.delete();
        }
        _draftAttachmentPaths.add(savedFile.path);
        setState(() {
          _pdfCvPath = savedFile.path;
        });
        if (mounted) {
          AppleToast.success(context, 'Dokumen PDF CV berhasil dilampirkan!');
        }
      }
    } catch (e) {
      if (mounted) AppleToast.warning(context, 'Gagal memilih dokumen PDF: $e');
    }
  }

  /// Pilih tanggal lamaran tanpa membuat pengingat seleksi.
  Future<void> _pickAppliedDate() async {
    HapticFeedback.selectionClick();
    final isDark = AppTheme.isDark(context);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day, 23, 59, 59);
    final initial = _appliedDate.isAfter(today) ? now : _appliedDate;

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: today,
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

  Future<void> _pickNextActionSchedule() async {
    HapticFeedback.selectionClick();
    final initial =
        _nextActionAt ?? DateTime.now().add(const Duration(days: 3));
    final date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
      helpText: 'Pilih waktu tindakan berikutnya',
    );
    if (time == null || !mounted) return;
    setState(() {
      _nextActionAt = DateTime(
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
    _draftAttachmentPaths.remove(_pdfCvPath);
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

  Widget _buildFormCard({
    required bool isDark,
    required Color cardBg,
    required Color cardBorder,
    required Widget child,
    EdgeInsetsGeometry padding = const EdgeInsets.fromLTRB(18, 18, 18, 16),
  }) {
    return Container(
      width: double.infinity,
      padding: padding,
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
      child: child,
    );
  }

  Widget _buildSectionEyebrow(String label, Color color) {
    return Text(
      label,
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w900,
        letterSpacing: 0.7,
        color: color,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    required bool isDark,
    required Color txtPri,
    int maxLength = 80,
    int maxLines = 1,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    TextCapitalization textCapitalization = TextCapitalization.none,
    String? Function(String?)? validator,
    Widget? suffixIcon,
  }) {
    return TextFormField(
      controller: controller,
      maxLength: maxLength,
      maxLines: maxLines,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      textCapitalization: textCapitalization,
      onChanged: (_) => setState(() {}),
      style: TextStyle(
        fontSize: maxLines > 1 ? 13 : 14,
        fontWeight: maxLines > 1 ? FontWeight.w500 : FontWeight.w700,
        color: txtPri,
        height: maxLines > 1 ? 1.4 : null,
      ),
      decoration: _buildInputDeco(
        hint: hint,
        icon: icon,
        isDark: isDark,
        suffixIcon: suffixIcon,
        maxLength: maxLength,
        currentLength: controller.text.length,
      ),
      validator: validator,
    );
  }

  Future<void> _pasteUrl() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data?.text != null && data!.text!.trim().isNotEmpty) {
      setState(() => _urlController.text = data.text!.trim());
    }
  }

  Widget _buildDatePill({
    required bool isDark,
    required Color txtPri,
    required Color txtSec,
  }) {
    return FluidBounceButton(
      onTap: _pickAppliedDate,
      hapticEnabled: false,
      scaleFactor: 0.96,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF282830) : const Color(0xFFF9F7F2),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: isDark ? const Color(0xFF383842) : const Color(0xFFE5E0D5),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.event_available_rounded,
              size: 16,
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
            const SizedBox(width: 4),
            Icon(Icons.expand_more_rounded, size: 16, color: txtSec),
          ],
        ),
      ),
    );
  }

  Widget _buildLogoPicker({
    required bool isDark,
    required Color circleBtnBg,
    required Color circleBtnBorder,
    required String companyName,
  }) {
    return FluidBounceButton(
      onTap: _pickCompanyLogo,
      semanticLabel: 'Pilih logo perusahaan',
      hapticEnabled: false,
      scaleFactor: 0.96,
      child: Stack(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: circleBtnBg,
              shape: BoxShape.circle,
              border: Border.all(color: circleBtnBorder),
            ),
            child: CompanyLogoBadge(
              companyName: companyName.isNotEmpty ? companyName : 'N',
              customImagePath: _companyLogoPath,
              size: 56,
              backgroundColor: isDark
                  ? const Color(0xFF282830)
                  : const Color(0xFFF0EDE6),
            ),
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF5C44E4)
                    : const Color(0xFF19191B),
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
    );
  }

  Widget _buildTermsChip({
    required String eyebrow,
    required String value,
    required Color color,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: FluidBounceButton(
        onTap: onTap,
        hapticEnabled: false,
        scaleFactor: 0.96,
        child: Container(
          padding: const EdgeInsets.fromLTRB(12, 12, 10, 12),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 18, color: const Color(0xFF121214)),
              const SizedBox(height: 10),
              Text(
                eyebrow,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.2,
                  color: const Color(0xFF121214).withValues(alpha: 0.62),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF121214),
                  height: 1.15,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSalarySheet() {
    HapticFeedback.selectionClick();
    final isDark = AppTheme.isDark(context);
    final txtPri = isDark ? Colors.white : const Color(0xFF121214);
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: Container(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E1E24) : Colors.white,
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
                  'Gaji penawaran',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: txtPri,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Boleh dikosongkan kalau belum ada angka.',
                  style: TextStyle(
                    fontSize: 12.5,
                    color: isDark
                        ? const Color(0xFFA0A0A8)
                        : const Color(0xFF707074),
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _salaryController,
                  autofocus: true,
                  keyboardType: TextInputType.number,
                  inputFormatters: [RupiahInputFormatter()],
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: txtPri,
                  ),
                  decoration: _buildInputDeco(
                    hint: 'Contoh: Rp 15.000.000',
                    icon: Icons.payments_rounded,
                    isDark: isDark,
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      setState(() {});
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isDark
                          ? const Color(0xFF5C44E4)
                          : const Color(0xFF19191B),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                    child: const Text(
                      'Simpan gaji',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFormHeadline({
    required bool isEdit,
    required Color txtPri,
    required Color txtSec,
  }) {
    final company = _companyController.text.trim();
    final position = _positionController.text.trim();
    final String title;
    final String subtitle;
    if (_quickMode && !isEdit) {
      title = 'CATAT\nCEPAT';
      subtitle = 'Tulis perusahaan dan posisi. Sisanya bisa dilengkapi nanti.';
    } else if (company.isNotEmpty) {
      title = company;
      subtitle = position.isNotEmpty
          ? position
          : 'Lengkapi syarat kerja dan catatan yang kamu punya.';
    } else {
      title = 'DETAIL\nLAMARAN';
      subtitle = 'Isi siapa, syarat kerja, dan catatan yang kamu punya.';
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.w900,
            color: txtPri,
            letterSpacing: -1.15,
            height: 0.99,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          subtitle,
          style: TextStyle(fontSize: 13, height: 1.35, color: txtSec),
        ),
      ],
    );
  }

  Widget _buildQuickModeCard({
    required bool isDark,
    required Color cardBg,
    required Color cardBorder,
    required Color txtPri,
    required Color txtSec,
  }) {
    return _buildFormCard(
      isDark: isDark,
      cardBg: cardBg,
      cardBorder: cardBorder,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildFieldLabel(
            'Perusahaan',
            isRequired: true,
            isDark: isDark,
            textColor: txtSec,
          ),
          const SizedBox(height: 6),
          _buildTextField(
            controller: _companyController,
            hint: 'Contoh: PT Bank Central Asia Tbk',
            icon: Icons.business_rounded,
            isDark: isDark,
            txtPri: txtPri,
            maxLength: 80,
            textCapitalization: TextCapitalization.words,
            validator: (v) => v == null || v.trim().isEmpty
                ? 'Nama Perusahaan wajib diisi'
                : null,
          ),
          const SizedBox(height: 12),
          _buildFieldLabel(
            'Posisi',
            isRequired: true,
            isDark: isDark,
            textColor: txtSec,
          ),
          const SizedBox(height: 6),
          _buildTextField(
            controller: _positionController,
            hint: 'Contoh: Software Development Engineer',
            icon: Icons.badge_rounded,
            isDark: isDark,
            txtPri: txtPri,
            maxLength: 100,
            textCapitalization: TextCapitalization.words,
            validator: (v) => v == null || v.trim().isEmpty
                ? 'Posisi lowongan wajib diisi'
                : null,
          ),
          const SizedBox(height: 12),
          _buildFieldLabel(
            'Tautan lowongan',
            isRequired: false,
            isDark: isDark,
            textColor: txtSec,
          ),
          const SizedBox(height: 6),
          _buildTextField(
            controller: _urlController,
            hint: 'https://linkedin.com/jobs/...',
            icon: Icons.link_rounded,
            isDark: isDark,
            txtPri: txtPri,
            maxLength: 500,
            keyboardType: TextInputType.url,
            suffixIcon: IconButton(
              icon: const Icon(Icons.paste_rounded, size: 18),
              tooltip: 'Tempel URL',
              onPressed: _pasteUrl,
            ),
          ),
          const SizedBox(height: 14),
          _buildFieldLabel(
            'Tanggal',
            isRequired: true,
            isDark: isDark,
            textColor: txtSec,
          ),
          const SizedBox(height: 8),
          _buildDatePill(isDark: isDark, txtPri: txtPri, txtSec: txtSec),
        ],
      ),
    );
  }

  Widget _buildDetailForm({
    required bool isDark,
    required Color cardBg,
    required Color cardBorder,
    required Color txtPri,
    required Color txtSec,
    required Color circleBtnBg,
    required Color circleBtnBorder,
  }) {
    final company = _companyController.text.trim();
    final salary = _salaryController.text.trim();
    final workLabel = (_workType.isEmpty || _workType == 'Belum ditentukan')
        ? 'Pilih'
        : _workType;
    return Column(
      children: [
        _buildFormCard(
          isDark: isDark,
          cardBg: cardBg,
          cardBorder: cardBorder,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionEyebrow('SIAPA & DI MANA', txtSec),
              const SizedBox(height: 14),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildLogoPicker(
                    isDark: isDark,
                    circleBtnBg: circleBtnBg,
                    circleBtnBorder: circleBtnBorder,
                    companyName: company,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildFieldLabel(
                          'Perusahaan',
                          isRequired: true,
                          isDark: isDark,
                          textColor: txtSec,
                        ),
                        const SizedBox(height: 6),
                        _buildTextField(
                          controller: _companyController,
                          hint: 'Nama perusahaan',
                          icon: Icons.business_rounded,
                          isDark: isDark,
                          txtPri: txtPri,
                          maxLength: 80,
                          textCapitalization: TextCapitalization.words,
                          validator: (v) => v == null || v.trim().isEmpty
                              ? 'Nama Perusahaan wajib diisi'
                              : null,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildFieldLabel(
                'Posisi',
                isRequired: true,
                isDark: isDark,
                textColor: txtSec,
              ),
              const SizedBox(height: 6),
              _buildTextField(
                controller: _positionController,
                hint: 'Contoh: Software Development Engineer',
                icon: Icons.badge_rounded,
                isDark: isDark,
                txtPri: txtPri,
                maxLength: 100,
                textCapitalization: TextCapitalization.words,
                validator: (v) => v == null || v.trim().isEmpty
                    ? 'Posisi lowongan wajib diisi'
                    : null,
              ),
              const SizedBox(height: 12),
              _buildFieldLabel(
                'Lokasi',
                isRequired: false,
                isDark: isDark,
                textColor: txtSec,
              ),
              const SizedBox(height: 6),
              _buildTextField(
                controller: _locationController,
                hint: 'Jakarta Selatan, DKI Jakarta',
                icon: Icons.location_on_outlined,
                isDark: isDark,
                txtPri: txtPri,
                maxLength: 80,
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 12),
              _buildFieldLabel(
                'Tautan lowongan',
                isRequired: false,
                isDark: isDark,
                textColor: txtSec,
              ),
              const SizedBox(height: 6),
              _buildTextField(
                controller: _urlController,
                hint: 'https://linkedin.com/jobs/...',
                icon: Icons.link_rounded,
                isDark: isDark,
                txtPri: txtPri,
                maxLength: 500,
                keyboardType: TextInputType.url,
                suffixIcon: IconButton(
                  icon: const Icon(Icons.paste_rounded, size: 18),
                  tooltip: 'Tempel URL',
                  onPressed: _pasteUrl,
                ),
              ),
              const SizedBox(height: 14),
              _buildDatePill(isDark: isDark, txtPri: txtPri, txtSec: txtSec),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _buildFormCard(
          isDark: isDark,
          cardBg: cardBg,
          cardBorder: cardBorder,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionEyebrow('SYARAT KERJA', txtSec),
              const SizedBox(height: 14),
              Row(
                children: [
                  _buildTermsChip(
                    eyebrow: 'Gaji',
                    value: salary.isEmpty ? 'Isi' : salary,
                    color: AppTheme.cardYellow,
                    icon: Icons.payments_rounded,
                    onTap: _showSalarySheet,
                  ),
                  const SizedBox(width: 8),
                  _buildTermsChip(
                    eyebrow: 'Mode',
                    value: workLabel,
                    color: AppTheme.cardGreen,
                    icon: Icons.apartment_rounded,
                    onTap: _showWorkTypePicker,
                  ),
                  const SizedBox(width: 8),
                  _buildTermsChip(
                    eyebrow: 'Status',
                    value: _status,
                    color: AppTheme.cardPurple,
                    icon: Icons.flag_rounded,
                    onTap: _showStatusPicker,
                  ),
                ],
              ),
              if (_hasSelectionStatus) ...[
                const SizedBox(height: 12),
                FluidBounceButton(
                  onTap: _pickSelectionSchedule,
                  hapticEnabled: false,
                  scaleFactor: 0.98,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: _interviewDate != null
                          ? (isDark
                                ? const Color(0xFF132E1D)
                                : const Color(0xFFDCFCE7))
                          : (isDark
                                ? const Color(0xFF282830)
                                : const Color(0xFFF9F7F2)),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: _interviewDate != null
                            ? const Color(0xFF22C55E)
                            : (isDark
                                  ? const Color(0xFF383842)
                                  : const Color(0xFFE5E0D5)),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.alarm_on_rounded,
                          size: 16,
                          color: _interviewDate != null
                              ? const Color(0xFF22C55E)
                              : const Color(0xFF5C44E4),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _interviewDate != null
                                ? _formatSelectionSchedule(_interviewDate!)
                                : 'Jadwal tes / interview',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: _interviewDate != null
                                  ? const Color(0xFF22C55E)
                                  : txtSec,
                            ),
                          ),
                        ),
                        if (_interviewDate != null)
                          GestureDetector(
                            onTap: () => setState(() => _interviewDate = null),
                            child: const Icon(
                              Icons.close_rounded,
                              size: 16,
                              color: Colors.grey,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 12),
        _buildNotesCard(
          isDark: isDark,
          cardBg: cardBg,
          cardBorder: cardBorder,
          txtPri: txtPri,
          txtSec: txtSec,
        ),
      ],
    );
  }

  Widget _buildNotesCard({
    required bool isDark,
    required Color cardBg,
    required Color cardBorder,
    required Color txtPri,
    required Color txtSec,
  }) {
    return _buildFormCard(
      isDark: isDark,
      cardBg: cardBg,
      cardBorder: cardBorder,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FluidBounceButton(
            onTap: () => setState(() => _notesExpanded = !_notesExpanded),
            hapticEnabled: false,
            scaleFactor: 0.99,
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionEyebrow('CATATAN & LAMPIRAN', txtSec),
                      if (!_notesExpanded) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Deskripsi, HR, tindakan, foto, dan CV',
                          style: TextStyle(fontSize: 12, color: txtSec),
                        ),
                      ],
                    ],
                  ),
                ),
                Icon(
                  _notesExpanded
                      ? Icons.expand_less_rounded
                      : Icons.expand_more_rounded,
                  color: txtSec,
                ),
              ],
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeInOutCubic,
            alignment: Alignment.topCenter,
            child: _notesExpanded
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 14),
                      _buildFieldLabel(
                        'Kualifikasi & deskripsi',
                        isRequired: false,
                        isDark: isDark,
                        textColor: txtSec,
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _descriptionController,
                        maxLength: 3000,
                        maxLines: 4,
                        onChanged: (_) => setState(() {}),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: txtPri,
                          height: 1.4,
                        ),
                        decoration: _buildInputDeco(
                          hint:
                              '• Minimal S1, pengalaman 2 tahun\n• Mahir Flutter',
                          icon: Icons.notes_rounded,
                          isDark: isDark,
                          maxLength: 3000,
                          currentLength: _descriptionController.text.length,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildFieldLabel(
                        'Catatan pribadi',
                        isRequired: false,
                        isDark: isDark,
                        textColor: txtSec,
                      ),
                      const SizedBox(height: 6),
                      _buildTextField(
                        controller: _notesController,
                        hint: 'Yang perlu kamu ingat soal lamaran ini',
                        icon: Icons.sticky_note_2_outlined,
                        isDark: isDark,
                        txtPri: txtPri,
                        maxLength: 500,
                      ),
                      const SizedBox(height: 12),
                      _buildFieldLabel(
                        'Kontak HR',
                        isRequired: false,
                        isDark: isDark,
                        textColor: txtSec,
                      ),
                      const SizedBox(height: 6),
                      _buildTextField(
                        controller: _hrContactController,
                        hint: 'email atau WhatsApp',
                        icon: Icons.contact_mail_outlined,
                        isDark: isDark,
                        txtPri: txtPri,
                        maxLength: 80,
                      ),
                      const SizedBox(height: 12),
                      _buildFieldLabel(
                        'Tindakan berikutnya',
                        isRequired: false,
                        isDark: isDark,
                        textColor: txtSec,
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              initialValue: _nextActionType,
                              isExpanded: true,
                              decoration: _buildInputDeco(
                                hint: 'Jenis tindakan',
                                icon: Icons.task_alt_rounded,
                                isDark: isDark,
                              ),
                              items:
                                  const [
                                        'Tindak lanjut',
                                        'Kirim dokumen',
                                        'Siapkan tes',
                                        'Jadwal interview',
                                        'Ambil keputusan',
                                      ]
                                      .map(
                                        (item) => DropdownMenuItem(
                                          value: item,
                                          child: Text(item),
                                        ),
                                      )
                                      .toList(),
                              onChanged: (value) => setState(
                                () =>
                                    _nextActionType = value ?? 'Tindak lanjut',
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: FluidBounceButton(
                              onTap: _pickNextActionSchedule,
                              hapticEnabled: false,
                              scaleFactor: 0.98,
                              child: Container(
                                height: 56,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? const Color(0xFF282830)
                                      : const Color(0xFFF9F7F2),
                                  borderRadius: BorderRadius.circular(18),
                                  border: Border.all(
                                    color: isDark
                                        ? const Color(0xFF383842)
                                        : const Color(0xFFE5E0D5),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.alarm_rounded,
                                      color: Color(0xFF5C44E4),
                                      size: 17,
                                    ),
                                    const SizedBox(width: 7),
                                    Expanded(
                                      child: Text(
                                        _nextActionAt == null
                                            ? 'Pilih waktu'
                                            : _formatSelectionSchedule(
                                                _nextActionAt!,
                                              ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.w800,
                                          color: _nextActionAt == null
                                              ? txtSec
                                              : txtPri,
                                        ),
                                      ),
                                    ),
                                    if (_nextActionAt != null)
                                      GestureDetector(
                                        onTap: () => setState(
                                          () => _nextActionAt = null,
                                        ),
                                        child: const Icon(
                                          Icons.close_rounded,
                                          size: 15,
                                          color: Colors.grey,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      _buildTextField(
                        controller: _nextActionNoteController,
                        hint: 'Contoh: Kirim portofolio versi terbaru',
                        icon: Icons.edit_note_rounded,
                        isDark: isDark,
                        txtPri: txtPri,
                        maxLength: 240,
                      ),
                      const SizedBox(height: 12),
                      _buildFieldLabel(
                        'Prioritas & label',
                        isRequired: false,
                        isDark: isDark,
                        textColor: txtSec,
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              initialValue: _priority,
                              decoration: _buildInputDeco(
                                hint: 'Prioritas',
                                icon: Icons.flag_outlined,
                                isDark: isDark,
                              ),
                              items: const ['Rendah', 'Normal', 'Tinggi']
                                  .map(
                                    (item) => DropdownMenuItem(
                                      value: item,
                                      child: Text(item),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (value) =>
                                  setState(() => _priority = value ?? 'Normal'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _buildTextField(
                              controller: _labelsController,
                              hint: 'Label, pisahkan koma',
                              icon: Icons.sell_outlined,
                              isDark: isDark,
                              txtPri: txtPri,
                              maxLength: 120,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      _buildAttachmentBlock(
                        isDark: isDark,
                        txtPri: txtPri,
                        txtSec: txtSec,
                      ),
                    ],
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _buildAttachmentBlock({
    required bool isDark,
    required Color txtPri,
    required Color txtSec,
  }) {
    return Column(
      children: [
        if (_screenshotPath != null && _screenshotPath!.isNotEmpty) ...[
          Stack(
            children: [
              Container(
                height: 150,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  image: DecorationImage(
                    image: ResizeImage(
                      FileImage(File(_screenshotPath!)),
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
                  onTap: () => setState(() => _screenshotPath = null),
                  child: Container(
                    padding: const EdgeInsets.all(6),
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
            icon: const Icon(Icons.add_photo_alternate_rounded, size: 18),
            label: Text(
              _screenshotPath != null
                  ? 'Ganti foto screenshot'
                  : 'Lampirkan screenshot loker',
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
                borderRadius: BorderRadius.circular(16),
              ),
              foregroundColor: txtPri,
              backgroundColor: isDark
                  ? const Color(0xFF282830)
                  : const Color(0xFFF9F7F2),
            ),
          ),
        ),
        const SizedBox(height: 12),
        if (_pdfCvPath != null && _pdfCvPath!.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF282830) : const Color(0xFFF9F7F2),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark
                    ? const Color(0xFF383842)
                    : const Color(0xFFE5E0D5),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE53935).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.picture_as_pdf_rounded,
                    color: Color(0xFFE53935),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _pdfCvPath!.split(Platform.pathSeparator).last,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w800,
                          color: txtPri,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Dokumen PDF CV terlampir',
                        style: TextStyle(fontSize: 11, color: txtSec),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => setState(() => _pdfCvPath = null),
                  icon: const Icon(
                    Icons.close_rounded,
                    size: 18,
                    color: Colors.grey,
                  ),
                  tooltip: 'Hapus CV',
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
        ],
        SizedBox(
          width: double.infinity,
          height: 46,
          child: OutlinedButton.icon(
            onPressed: _pickPdfCv,
            icon: const Icon(
              Icons.picture_as_pdf_rounded,
              size: 18,
              color: Color(0xFFE53935),
            ),
            label: Text(
              _pdfCvPath != null ? 'Ganti dokumen PDF CV' : 'Lampirkan PDF CV',
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
                borderRadius: BorderRadius.circular(16),
              ),
              foregroundColor: txtPri,
              backgroundColor: isDark
                  ? const Color(0xFF282830)
                  : const Color(0xFFF9F7F2),
            ),
          ),
        ),
      ],
    );
  }

  bool _hasUnsavedChanges() {
    if (_isSaveComplete) return false;
    if (widget.jobToEdit != null) {
      final j = widget.jobToEdit!;
      return _companyController.text.trim() != j.companyName ||
          _positionController.text.trim() != j.position ||
          _salaryController.text.trim() != (j.salaryOffered ?? '') ||
          _locationController.text.trim() != (j.location ?? '') ||
          _descriptionController.text.trim() != j.jobDescription ||
          _hrContactController.text.trim() != (j.hrContact ?? '') ||
          _notesController.text.trim() != (j.notes ?? '') ||
          _nextActionNoteController.text.trim() != (j.nextActionNote ?? '') ||
          _labelsController.text.trim() != j.labels.join(', ') ||
          _status != j.status ||
          _workType != j.workType ||
          _jobSource != (j.jobSource ?? 'LinkedIn') ||
          _sourcePlatform != j.sourcePlatform ||
          _jobUrl != j.jobUrl ||
          !_isSameCalendarDate(_appliedDate, j.appliedDate) ||
          _interviewDate != (j.interviewDate ?? j.testDate) ||
          _nextActionAt != j.nextActionAt ||
          _nextActionType != (j.nextActionType ?? 'Tindak lanjut') ||
          _priority != j.priority ||
          _screenshotPath != j.screenshotPath ||
          _companyLogoPath != j.companyLogoPath ||
          _pdfCvPath != j.pdfCvPath;
    }
    return _companyController.text.trim().isNotEmpty ||
        _positionController.text.trim().isNotEmpty ||
        _salaryController.text.trim().isNotEmpty ||
        _locationController.text.trim().isNotEmpty ||
        _descriptionController.text.trim().isNotEmpty ||
        _hrContactController.text.trim().isNotEmpty ||
        _notesController.text.trim().isNotEmpty ||
        _nextActionNoteController.text.trim().isNotEmpty ||
        _labelsController.text.trim().isNotEmpty ||
        _urlController.text.trim().isNotEmpty ||
        _status != 'Tersimpan' ||
        _workType != 'Belum ditentukan' ||
        _jobSource != 'LinkedIn' ||
        _jobUrl != null ||
        _interviewDate != null ||
        _nextActionAt != null ||
        _priority != 'Normal' ||
        _screenshotPath != null ||
        _companyLogoPath != null ||
        _pdfCvPath != null;
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

    setState(() {
      _isSaving = true;
      _isSaveComplete = false;
    });

    final isEdit = widget.jobToEdit != null;
    final id = isEdit
        ? widget.jobToEdit!.id
        : 'job_${DateTime.now().millisecondsSinceEpoch}';

    final salaryText = _salaryController.text.trim();
    final salaryRange = SalaryEvaluatorService.parseSalaryRange(salaryText);
    final hrContact = _hrContactController.text.trim();
    final existingContact = widget.jobToEdit?.hrContact?.trim() ?? '';
    final recruiterContacts = isEdit && hrContact == existingContact
        ? widget.jobToEdit!.recruiterContacts
        : (hrContact.isEmpty
              ? const <RecruiterContact>[]
              : [
                  RecruiterContact(
                    id: 'contact_${DateTime.now().microsecondsSinceEpoch}',
                    name: 'Kontak rekrutmen',
                    role: 'Recruiter',
                    channel: hrContact.contains('@') ? 'Email' : 'WhatsApp',
                    value: hrContact,
                  ),
                ]);

    final selectionSchedule = _hasSelectionStatus ? _interviewDate : null;
    final isSampleData = widget.jobToEdit?.isSampleData ?? false;
    final newJob = JobApplication(
      id: id,
      companyName: _companyController.text.trim(),
      position: _positionController.text.trim(),
      status: _status,
      appliedDate: _appliedDate,
      savedAt: _status == 'Tersimpan'
          ? (widget.jobToEdit?.savedAt ?? DateTime.now())
          : widget.jobToEdit?.savedAt,
      salaryOffered: salaryText.isEmpty ? null : salaryText,
      minSalary: salaryRange.min > 0 ? salaryRange.min.toInt() : null,
      maxSalary: salaryRange.max > 0 ? salaryRange.max.toInt() : null,
      workType: _quickMode ? 'Belum ditentukan' : _workType,
      location: _locationController.text.trim().isEmpty
          ? null
          : _locationController.text.trim(),
      jobSource: _jobSource,
      sourcePlatform: _sourcePlatform,
      jobUrl: _urlController.text.trim().isNotEmpty
          ? _urlController.text.trim()
          : null,
      jobDescription: _descriptionController.text.trim(),
      hrContact: hrContact.isEmpty ? null : hrContact,
      interviewDate: _status.startsWith('Interview') ? selectionSchedule : null,
      testDate: _status == 'Tes / Psikotes' ? selectionSchedule : null,
      notes: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
      isFavorite: widget.jobToEdit?.isFavorite ?? false,
      screenshotPath: _screenshotPath,
      companyLogoPath: _companyLogoPath,
      pdfCvPath: _pdfCvPath,
      isSampleData: isSampleData,
      createdAt: widget.jobToEdit?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
      nextActionAt: _nextActionAt,
      nextActionType: _nextActionAt == null ? null : _nextActionType,
      nextActionNote: _nextActionNoteController.text.trim().isEmpty
          ? null
          : _nextActionNoteController.text.trim(),
      priority: _priority,
      labels: _labelsController.text
          .split(',')
          .map((label) => label.trim())
          .where((label) => label.isNotEmpty)
          .toSet()
          .toList(),
      recruitmentEvents: widget.jobToEdit?.recruitmentEvents,
      recruiterContacts: recruiterContacts,
      attachments: widget.jobToEdit?.attachments,
      offerDetails: widget.jobToEdit?.offerDetails,
    );

    try {
      if (isEdit) {
        await ref.read(jobProvider.notifier).updateJob(newJob);
      } else {
        await ref.read(jobProvider.notifier).addJob(newJob);
      }

      _releaseDraftAttachmentsAfterSave();

      // Ensure notification permission is requested via OS prompt without opening Flutter bottom sheets on top of Navigator
      if ((newJob.interviewDate != null && _hasSelectionStatus) ||
          newJob.nextActionAt != null) {
        NotificationService.areNotificationsEnabled()
            .then((enabled) {
              if (!enabled) {
                NotificationService.requestPermission();
              }
            })
            .catchError((_) {});
      }

      if (!mounted) return;
      setState(() {
        _isSaving = false;
        _isSaveComplete = true;
      });
      await Future<void>.delayed(const Duration(milliseconds: 260));
      if (!mounted) return;
      Navigator.pop(context, newJob);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isSaving = false;
        _isSaveComplete = false;
      });
      if (error is DuplicateJobException) {
        await _showDuplicateResolutionDialog(error, newJob, isEdit);
      } else {
        AppleToast.error(context, 'Lamaran gagal disimpan.');
      }
    }
  }

  Future<void> _showDuplicateResolutionDialog(
    DuplicateJobException duplicateError,
    JobApplication candidate,
    bool isEdit,
  ) async {
    final existing = duplicateError.existingJob;
    final isDark = AppTheme.isDark(context);
    final txtPri = isDark ? Colors.white : const Color(0xFF121214);
    final txtSec = isDark ? Colors.white70 : const Color(0xFF6B6B70);

    final action = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E1E24) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            const Icon(Icons.info_outline_rounded, color: Color(0xFFF59E0B)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Kemungkinan Lamaran Serupa Ditemukan',
                style: TextStyle(
                  fontSize: 16.5,
                  fontWeight: FontWeight.w800,
                  color: txtPri,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          'Posisi "${existing.position}" di "${existing.companyName}" sudah pernah dicatat dengan status "${existing.status}".\n\nApa yang ingin kamu lakukan?',
          style: TextStyle(fontSize: 13.5, color: txtSec, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, 'cancel'),
            child: Text('Batal', style: TextStyle(color: txtSec)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, 'open_existing'),
            child: const Text(
              'Buka Data Lama',
              style: TextStyle(
                color: Color(0xFF5C44E4),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, 'save_anyway'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF5C44E4),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: const Text('Tetap Simpan'),
          ),
        ],
      ),
    );

    if (!mounted) return;
    if (action == 'open_existing') {
      Navigator.pop(context);
      Navigator.push(
        context,
        AppMotion.detailDockRoute(
          builder: (_) => JobDetailScreen(job: existing),
        ),
      );
    } else if (action == 'save_anyway') {
      setState(() {
        _isSaving = true;
        _isSaveComplete = false;
      });
      try {
        final uniqueJob = candidate.copyWith(
          id: isEdit
              ? candidate.id
              : 'job_${DateTime.now().millisecondsSinceEpoch}',
        );
        if (isEdit) {
          await ref
              .read(jobProvider.notifier)
              .updateJob(uniqueJob, allowDuplicate: true);
        } else {
          await ref
              .read(jobProvider.notifier)
              .addJob(uniqueJob, allowDuplicate: true);
        }
        if (!mounted) return;
        setState(() {
          _isSaving = false;
          _isSaveComplete = true;
        });
        await Future<void>.delayed(const Duration(milliseconds: 260));
        if (!mounted) return;
        Navigator.pop(context, uniqueJob);
      } catch (e) {
        if (mounted) {
          setState(() {
            _isSaving = false;
            _isSaveComplete = false;
          });
          AppleToast.error(context, 'Gagal menyimpan: $e');
        }
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
        // The CTA floats above the scrolling form instead of reserving a
        // separate footer panel below it.
        extendBody: true,
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  // Keep the final fields reachable above the floating CTA
                  // while their background continues beneath its soft veil.
                  padding: EdgeInsets.fromLTRB(
                    20,
                    AppLayoutMetrics.headerTopInsideSafeArea(
                      context,
                      extra: 10,
                    ),
                    20,
                    140 + bottomInset,
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ── 1. TOP HEADER: BACK + IMPORT ──
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
                                      : _importSpreadsheet,
                                  hapticEnabled: false,
                                  scaleFactor: 0.98,
                                  semanticLabel: 'Impor dari Excel atau CSV',
                                  child: Container(
                                    width: double.infinity,
                                    height: 44,
                                    decoration: BoxDecoration(
                                      color: isDark
                                          ? const Color(0xFF282830)
                                          : const Color(0xFFF3EFE6),
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(color: cardBorder),
                                    ),
                                    child: const Center(
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.table_view_rounded,
                                            color: Color(0xFF5C44E4),
                                            size: 17,
                                          ),
                                          SizedBox(width: 8),
                                          Text(
                                            'Impor dari Excel (.xlsx)',
                                            style: TextStyle(
                                              color: Color(0xFF5C44E4),
                                              fontWeight: FontWeight.w800,
                                              fontSize: 13,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
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

                        _buildFormHeadline(
                          isEdit: isEdit,
                          txtPri: txtPri,
                          txtSec: txtSec,
                        ),
                        const SizedBox(height: 16),
                        if (_quickMode)
                          _buildQuickModeCard(
                            isDark: isDark,
                            cardBg: cardBg,
                            cardBorder: cardBorder,
                            txtPri: txtPri,
                            txtSec: txtSec,
                          )
                        else
                          _buildDetailForm(
                            isDark: isDark,
                            cardBg: cardBg,
                            cardBorder: cardBorder,
                            txtPri: txtPri,
                            txtSec: txtSec,
                            circleBtnBg: circleBtnBg,
                            circleBtnBorder: circleBtnBorder,
                          ),

                        // Tombol Hapus jika mode Edit
                        if (isEdit) ...[
                          const SizedBox(height: 16),
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
              // A transparent veil anchors the action while letting the form
              // remain visually continuous underneath—never a solid footer.
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: isDark
                    ? [
                        const Color(0xFF141418).withValues(alpha: 0.0),
                        const Color(0xFF141418).withValues(alpha: 0.05),
                        const Color(0xFF141418).withValues(alpha: 0.24),
                      ]
                    : [
                        const Color(0xFFF6F1E8).withValues(alpha: 0.0),
                        const Color(0xFFF6F1E8).withValues(alpha: 0.04),
                        const Color(0xFFF6F1E8).withValues(alpha: 0.22),
                      ],
                stops: const [0.0, 0.52, 1.0],
              ),
            ),
            child: SizedBox(
              width: double.infinity,
              height: 56,
              child: Hero(
                tag: widget.actionHeroTag,
                createRectTween: actionButtonRectTween,
                flightShuttleBuilder: actionButtonFlightShuttle,
                placeholderBuilder: actionButtonHeroPlaceholder,
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
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 180),
                    child: _isSaving
                        ? Row(
                            key: ValueKey(_isSaveComplete),
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (_isSaveComplete)
                                const Icon(Icons.check_rounded, size: 20)
                              else
                                const SizedBox.square(
                                  dimension: 18,
                                  child: CupertinoActivityIndicator(
                                    color: Colors.white,
                                  ),
                                ),
                              const SizedBox(width: 8),
                              Text(
                                _isSaveComplete ? 'Tersimpan' : 'Menyimpan…',
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ],
                          )
                        : Row(
                            key: const ValueKey('ready'),
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
                                  style: actionButtonLabelTextStyle(),
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
        ),
      ),
    );
  }

  Widget _buildFieldLabel(
    String label, {
    required bool isRequired,
    required bool isDark,
    required Color textColor,
  }) {
    return Text.rich(
      TextSpan(
        text: label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          color: textColor,
        ),
        children: [
          if (isRequired)
            TextSpan(
              text: ' *',
              style: TextStyle(
                color: isDark
                    ? const Color(0xFFFF8A94)
                    : const Color(0xFFE53935),
                fontWeight: FontWeight.w900,
              ),
            ),
        ],
      ),
    );
  }

  InputDecoration _buildInputDeco({
    required String hint,
    required IconData icon,
    bool isDark = false,
    Widget? suffixIcon,
    int? maxLength,
    int? currentLength,
  }) {
    final inputBg = isDark ? const Color(0xFF282830) : const Color(0xFFF9F7F2);
    final inputBorder = isDark
        ? const Color(0xFF383842)
        : const Color(0xFFE5E0D5);
    final iconColor = isDark ? Colors.white70 : const Color(0xFF121214);
    final hintColor = isDark ? const Color(0xFF8E8E93) : Colors.grey.shade400;
    final showCounter =
        maxLength != null &&
        currentLength != null &&
        currentLength >= (maxLength * 0.7).round();

    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(
        fontSize: 12.5,
        color: hintColor,
        fontWeight: FontWeight.w500,
      ),
      prefixIcon: Icon(icon, size: 18, color: iconColor),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: inputBg,
      counterText: showCounter ? '$currentLength/$maxLength' : '',
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide(color: inputBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide(color: inputBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide(
          color: isDark ? const Color(0xFF5C44E4) : const Color(0xFF19191B),
          width: 1.6,
        ),
      ),
    );
  }
}
