import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/job_application.dart';
import '../../providers/job_provider.dart';
import '../../services/text_parser_service.dart';
import '../../services/salary_evaluator_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/apple_animations.dart';
import '../../widgets/apple_toast.dart';
import '../../widgets/rupiah_input_formatter.dart';
import '../../services/notification_service.dart';

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
  String _jobSource = 'Pilih Sumber / Mandiri';
  String _sourcePlatform = 'Manual';
  String? _jobUrl;
  String? _screenshotPath;
  String? _companyLogoPath;
  DateTime _appliedDate = DateTime.now();
  DateTime? _interviewDate;
  bool _isSaving = false;
  bool _isExtracting = false;

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
    'Pilih Sumber / Mandiri',
    'LinkedIn',
    'JobStreet',
    'Indeed',
    'Glints',
    'Kalibrr',
    'KitaLulus',
    'Website Karir',
    'Email Direct',
    'Referensi / Rekomendasi',
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

  /// Tempel langsung dari Clipboard & Otomatis Ekstrak
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

  /// Ekstraksi otomatis dari Link URL (LinkedIn, Glints, JobStreet, Indeed) atau Teks Iklan
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
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF121214)),
            ),
            const SizedBox(height: 6),
            const Text(
              'Pilih foto logo atau kantor perusahaan yang Anda lamar:',
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
        setState(() {
          _companyLogoPath = image.path;
        });
        AppleToast.success(context, 'Foto perusahaan berhasil dipilih!');
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
              'Lampirkan Screenshot Loker',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF121214)),
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
      final XFile? image = await picker.pickImage(source: source, imageQuality: 90);
      if (image != null && mounted) {
        setState(() {
          _screenshotPath = image.path;
        });
        AppleToast.success(context, 'Screenshot loker berhasil dilampirkan!');
      }
    } catch (_) {
      if (mounted) AppleToast.warning(context, 'Gagal memilih gambar.');
    }
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
        NotificationService.requestPermission().catchError((Object error) {
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

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.jobToEdit != null;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: EdgeInsets.fromLTRB(20, 8, 20, 40 + (MediaQuery.of(context).padding.bottom > 0 ? MediaQuery.of(context).padding.bottom : 0)),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  isEdit ? 'Edit Lamaran' : 'Tambah Lamaran Baru',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF121214),
                    letterSpacing: -0.6,
                  ),
                ),
                FluidBounceButton(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.06),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.close_rounded, size: 18, color: Color(0xFF121214)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // ── SECTION 1: SMART AUTO-FILL FROM LINK / TEXT ──
            if (!isEdit) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3EEFF),
                  borderRadius: BorderRadius.circular(AppTheme.radiusCard),
                  border: Border.all(color: const Color(0xFFD6C8F8), width: 1.2),
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
                            SizedBox(width: 8),
                            Text(
                              'Impor Cepat dari Link',
                              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5, color: Color(0xFF121214)),
                            ),
                          ],
                        ),
                        GestureDetector(
                          onTap: _pasteFromClipboard,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFF5C44E4),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.content_paste_rounded, size: 13, color: Colors.white),
                                SizedBox(width: 4),
                                Text(
                                  'Tempel',
                                  style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: Colors.white),
                                ),
                              ],
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
                        fillColor: Colors.white,
                        filled: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: Color(0xFFD6C8F8)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: Color(0xFFD6C8F8)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton.icon(
                        onPressed: _isExtracting ? null : _extractFromLinkOrText,
                        icon: _isExtracting
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Icon(Icons.auto_awesome_rounded, size: 18),
                        label: Text(
                          _isExtracting ? 'Menganalisis Link...' : 'Ekstrak & Isi Otomatis',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF5C44E4),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // ── SECTION 2: INFORMASI UTAMA PEKERJAAN ──
            _buildSectionCard(
              title: 'Informasi Pekerjaan',
              icon: Icons.work_outline_rounded,
              child: Column(
                children: [
                  // Logo / Foto Perusahaan Upload Row
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF9F7F2),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE5E0D5)),
                    ),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: _pickCompanyLogo,
                          child: Stack(
                            children: [
                              Container(
                                width: 54,
                                height: 54,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: const Color(0xFFDCD8CE), width: 1.5),
                                ),
                                child: ClipOval(
                                  child: _companyLogoPath != null && File(_companyLogoPath!).existsSync()
                                      ? Image.file(
                                          File(_companyLogoPath!),
                                          width: 54,
                                          height: 54,
                                          fit: BoxFit.cover,
                                        )
                                      : Center(
                                          child: Icon(
                                            Icons.business_rounded,
                                            size: 26,
                                            color: Colors.grey.shade600,
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
                                    color: Color(0xFF19191B),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.camera_alt_rounded,
                                    color: Colors.white,
                                    size: 10,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Foto / Logo Perusahaan',
                                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: Color(0xFF121214)),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _companyLogoPath != null
                                    ? 'Foto kustom terpasang (ketuk untuk ubah)'
                                    : 'Ketuk ikon kamera untuk unggah foto/logo',
                                style: TextStyle(fontSize: 11.5, color: Colors.grey.shade600),
                              ),
                            ],
                          ),
                        ),
                        TextButton(
                          onPressed: _pickCompanyLogo,
                          child: Text(
                            _companyLogoPath != null ? 'Ubah' : 'Unggah',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5, color: Color(0xFF5C44E4)),
                          ),
                        ),
                      ],
                    ),
                  ),

                  TextFormField(
                    controller: _companyController,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      labelText: 'Nama Perusahaan *',
                      hintText: 'Contoh: PT Bank Central Asia Tbk',
                      prefixIcon: Icon(Icons.business_rounded, size: 18),
                    ),
                    validator: (val) => val == null || val.trim().isEmpty ? 'Nama Perusahaan wajib diisi' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _positionController,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      labelText: 'Posisi / Role *',
                      hintText: 'Contoh: Mobile Application Specialist',
                      prefixIcon: Icon(Icons.badge_rounded, size: 18),
                    ),
                    validator: (val) => val == null || val.trim().isEmpty ? 'Posisi wajib diisi' : null,
                  ),
                    const SizedBox(height: 14),

                    // Segmented Selector Tipe Kerja (WFO / WFH / Hybrid)
                    Row(
                      children: [
                        const Text(
                          'Tipe Kerja:',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF121214)),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Row(
                            children: _workTypeOptions.map((type) {
                              final isSelected = _workType == type;
                              return Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 3),
                                  child: ChoiceChip(
                                    selected: isSelected,
                                    checkmarkColor: Colors.white,
                                    label: Text(type),
                                    labelStyle: TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w700,
                                      color: isSelected ? Colors.white : const Color(0xFF121214),
                                    ),
                                    selectedColor: const Color(0xFF1C1C1E),
                                    backgroundColor: const Color(0xFFF5EFE6),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      side: BorderSide(
                                        color: isSelected ? const Color(0xFF1C1C1E) : const Color(0xFFDCD8CE),
                                      ),
                                    ),
                                    onSelected: (_) => setState(() => _workType = type),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              // ── SECTION 3: GAJI & LOKASI ──
              _buildSectionCard(
                title: 'Gaji & Lokasi',
                icon: Icons.payments_outlined,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _salaryController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [RupiahInputFormatter()],
                      decoration: const InputDecoration(
                        labelText: 'Gaji Penawaran (Bulan)',
                        hintText: 'Rp 15.000.000',
                        prefixIcon: Icon(Icons.monetization_on_outlined, size: 18),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: TextFormField(
                            controller: _locationController,
                            textCapitalization: TextCapitalization.words,
                            decoration: InputDecoration(
                              labelText: 'Lokasi / Link Maps',
                              hintText: 'Kota atau link Google Maps...',
                              prefixIcon: const Icon(Icons.location_on_outlined, size: 18),
                              suffixIcon: IconButton(
                                icon: const Icon(Icons.content_paste_rounded, size: 16, color: Color(0xFF5C44E4)),
                                tooltip: 'Tempel Link Maps / Lokasi',
                                onPressed: () async {
                                  HapticFeedback.selectionClick();
                                  final data = await Clipboard.getData(Clipboard.kTextPlain);
                                  if (data?.text != null && data!.text!.trim().isNotEmpty) {
                                    _locationController.text = data.text!.trim();
                                    if (context.mounted) {
                                      AppleToast.success(context, 'Alamat / Link Maps ditempel!');
                                    }
                                  } else {
                                    if (context.mounted) {
                                      AppleToast.info(context, 'Clipboard kosong');
                                    }
                                  }
                                },
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          flex: 2,
                          child: DropdownButtonFormField<String>(
                            initialValue: _jobSource,
                            decoration: const InputDecoration(
                              labelText: 'Sumber',
                              prefixIcon: Icon(Icons.link_rounded, size: 18),
                            ),
                            items: _sourceOptions
                                .map((s) => DropdownMenuItem(value: s, child: Text(s, style: const TextStyle(fontSize: 12))))
                                .toList(),
                            onChanged: (val) => setState(() => _jobSource = val!),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              // ── SECTION 4: TAHAPAN & JADWAL ──
              _buildSectionCard(
                title: 'Status & Tahapan Seleksi',
                icon: Icons.tune_rounded,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: _statusOptions.map((st) {
                        final isSelected = _status == st;
                        final color = AppTheme.getStatusColor(st);
                        return ChoiceChip(
                          selected: isSelected,
                          label: Text(st),
                          labelStyle: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: isSelected ? Colors.white : const Color(0xFF121214),
                          ),
                          selectedColor: color,
                          backgroundColor: const Color(0xFFF5EFE6),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(color: isSelected ? color : const Color(0xFFDCD8CE)),
                          ),
                          onSelected: (_) => setState(() => _status = st),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              // ── SECTION 5: SCREENSHOT & KONTAK HR ──
              _buildSectionCard(
                title: 'Screenshot Loker & Kontak HR',
                icon: Icons.attachment_rounded,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Screenshot Picker & Preview
                    if (_screenshotPath != null && _screenshotPath!.isNotEmpty) ...[
                      Stack(
                        children: [
                          Container(
                            height: 160,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              image: DecorationImage(
                                image: FileImage(File(_screenshotPath!)),
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

                    OutlinedButton.icon(
                      onPressed: _pickScreenshot,
                      icon: const Icon(Icons.add_photo_alternate_rounded, size: 18),
                      label: Text(_screenshotPath != null ? 'Ganti Screenshot Loker' : 'Lampirkan Foto Screenshot Loker'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                        side: const BorderSide(color: Color(0xFFDCD8CE)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        foregroundColor: const Color(0xFF121214),
                      ),
                    ),

                    const SizedBox(height: 12),

                    TextFormField(
                      controller: _hrContactController,
                      decoration: const InputDecoration(
                        labelText: 'Kontak HR (WhatsApp / Email)',
                        hintText: 'hr.recruitment@perusahaan.com / +628...',
                        prefixIcon: Icon(Icons.contact_mail_outlined, size: 18),
                      ),
                    ),
                    const SizedBox(height: 12),

                    TextFormField(
                      controller: _descriptionController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Deskripsi / Kualifikasi Singkat',
                        hintText: 'Persyaratan utama lowongan...',
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // ── ACTION BUTTONS ──
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _saveJob,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1C1C1E),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                    elevation: 4,
                  ),
                  child: _isSaving
                      ? const CupertinoActivityIndicator(color: Colors.white)
                      : Text(
                          isEdit ? 'Simpan Perubahan' : 'Catat Lamaran Sekarang',
                          style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w800),
                        ),
                ),
              ),

              // Delete Button if editing
              if (isEdit) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: OutlinedButton.icon(
                    onPressed: _deleteCurrentJob,
                    icon: const Icon(Icons.delete_forever_rounded, color: Color(0xFFE53935), size: 18),
                    label: const Text(
                      'Hapus Lamaran Ini',
                      style: TextStyle(color: Color(0xFFE53935), fontWeight: FontWeight.bold),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFFE53935), width: 1.2),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      );
  }

  Widget _buildSectionCard({required String title, required IconData icon, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
        border: Border.all(color: const Color(0xFFDCD8CE), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: const Color(0xFF121214)),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF121214)),
              ),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}
