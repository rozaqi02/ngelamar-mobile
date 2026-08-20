import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../models/job_application.dart';
import '../../providers/job_provider.dart';
import '../../services/text_parser_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/apple_toast.dart';
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

  late TextEditingController _pasteController;
  late TextEditingController _companyController;
  late TextEditingController _positionController;
  late TextEditingController _minSalaryController;
  late TextEditingController _maxSalaryController;
  late TextEditingController _locationController;
  late TextEditingController _descriptionController;
  late TextEditingController _hrContactController;
  late TextEditingController _notesController;

  String _status = 'Dikirim';
  String _workType = 'WFO';
  String _jobSource = 'LinkedIn';
  DateTime _appliedDate = DateTime.now();
  DateTime? _testDate;
  DateTime? _interviewDate;
  bool _isSaving = false;

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
    'Glints',
    'JobStreet',
    'Kalibrr',
    'KitaLulus',
    'Email Direct',
    'Referensi',
    'Lainnya',
  ];

  @override
  void initState() {
    super.initState();
    final j = widget.jobToEdit;
    _pasteController = TextEditingController();
    _companyController = TextEditingController(text: j?.companyName ?? '');
    _positionController = TextEditingController(text: j?.position ?? '');

    String minSal = '';
    String maxSal = '';
    if (j?.salaryOffered != null && j!.salaryOffered!.isNotEmpty) {
      final salText = j.salaryOffered!;
      if (salText.contains('-')) {
        final parts = salText.split('-');
        minSal = parts[0].trim();
        maxSal = parts[1].trim();
      } else {
        minSal = salText.trim();
      }
    }
    _minSalaryController = TextEditingController(text: minSal);
    _maxSalaryController = TextEditingController(text: maxSal);

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
      _appliedDate = j.appliedDate;
      _testDate = j.testDate;
      _interviewDate = j.interviewDate;
    }
  }

  @override
  void dispose() {
    _pasteController.dispose();
    _companyController.dispose();
    _positionController.dispose();
    _minSalaryController.dispose();
    _maxSalaryController.dispose();
    _locationController.dispose();
    _descriptionController.dispose();
    _hrContactController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _parsePastedText() {
    final text = _pasteController.text;
    if (text.trim().isEmpty) return;

    final result = TextParserService.parseJobText(text);

    setState(() {
      _positionController.text = result.position;
      _companyController.text = result.companyName;
      _workType = result.workType;
      if (result.salary != null) {
        final sal = result.salary!;
        if (sal.contains('-')) {
          final parts = sal.split('-');
          _minSalaryController.text = parts[0].trim();
          _maxSalaryController.text = parts[1].trim();
        } else {
          _minSalaryController.text = sal;
          _maxSalaryController.clear();
        }
      }
      if (result.location != null) _locationController.text = result.location!;
      _descriptionController.text = text;
    });

    final jobs = ref.read(jobProvider).jobs;
    final isDup = jobs.any(
      (j) =>
          j.companyName.toLowerCase() == result.companyName.toLowerCase() &&
          j.position.toLowerCase() == result.position.toLowerCase(),
    );

    if (isDup) {
      AppleToast.warning(
        context,
        'Peringatan Lamaran Duplikat',
        subtitle:
            'Lamaran "${result.position}" di ${result.companyName} sudah pernah dicatat.',
      );
    } else {
      AppleToast.success(
        context,
        'Pengisian Otomatis Berhasil!',
        subtitle: '${result.position} di ${result.companyName}',
      );
    }
  }

  Future<void> _pickAndAnalyzeImage() async {
    showCupertinoModalPopup(
      context: context,
      builder: (_) => CupertinoActionSheet(
        title: const Text('Pindai Poster / Screenshot Loker'),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              _processImageSource(ImageSource.gallery);
            },
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(CupertinoIcons.photo, size: 18),
                SizedBox(width: 8),
                Text('Pilih dari Galeri Foto'),
              ],
            ),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              _processImageSource(ImageSource.camera);
            },
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(CupertinoIcons.camera, size: 18),
                SizedBox(width: 8),
                Text('Ambil Foto Kamera'),
              ],
            ),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          isDefaultAction: true,
          onPressed: () => Navigator.pop(context),
          child: const Text('Batal'),
        ),
      ),
    );
  }

  Future<void> _processImageSource(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: source,
        imageQuality: 95,
      );

      if (image == null) return;

      String extractedText = '';

      try {
        final inputImage = InputImage.fromFilePath(image.path);
        final textRecognizer =
            TextRecognizer(script: TextRecognitionScript.latin);
        final RecognizedText recognizedText =
            await textRecognizer.processImage(inputImage);
        await textRecognizer.close();

        extractedText = recognizedText.text.trim();
      } catch (ocrError) {
        debugPrint('OCR error: $ocrError');
      }

      if (extractedText.trim().isEmpty) {
        if (!mounted) return;
        AppleToast.warning(
          context,
          'Teks Tidak Terbaca',
          subtitle: 'Tidak dapat mendeteksi teks tulisan dari gambar loker.',
        );
        return;
      }

      _pasteController.text = extractedText;
      _parsePastedText();

      if (!mounted) return;
      AppleToast.success(
        context,
        'Gambar Berhasil Dipindai!',
        subtitle: 'Data loker telah diisikan otomatis ke formulir.',
      );
    } catch (e) {
      if (!mounted) return;
      AppleToast.warning(
        context,
        'Gagal Membaca Gambar',
        subtitle: 'Periksa izin akses galeri/kamera Anda.',
      );
    }
  }

  Future<void> _saveJob() async {
    if (_isSaving || !_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    final isEdit = widget.jobToEdit != null;
    final id = isEdit
        ? widget.jobToEdit!.id
        : DateTime.now().microsecondsSinceEpoch.toString();

    String? finalSalary;
    final minVal = _minSalaryController.text.trim();
    final maxVal = _maxSalaryController.text.trim();
    if (minVal.isNotEmpty && maxVal.isNotEmpty) {
      finalSalary = '$minVal - $maxVal';
    } else if (minVal.isNotEmpty) {
      finalSalary = minVal;
    } else if (maxVal.isNotEmpty) {
      finalSalary = maxVal;
    }

    final newJob = JobApplication(
      id: id,
      companyName: _companyController.text.trim(),
      position: _positionController.text.trim(),
      status: _status,
      appliedDate: _appliedDate,
      salaryOffered: finalSalary,
      workType: _workType,
      location: _locationController.text.trim().isEmpty
          ? null
          : _locationController.text.trim(),
      jobSource: _jobSource,
      jobDescription: _descriptionController.text.trim(),
      hrContact: _hrContactController.text.trim().isEmpty
          ? null
          : _hrContactController.text.trim(),
      testDate: _testDate,
      interviewDate: _interviewDate,
      notes: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
      isFavorite: widget.jobToEdit?.isFavorite ?? false,
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
    final isDark = AppTheme.isDark(context);
    final cardBg = isDark ? const Color(0xFF1E1E22) : Colors.white;
    final txtPri = AppTheme.getTextPrimary(context);

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Modal Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  isEdit ? 'Edit Lamaran' : 'Tambah Lowongan',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: txtPri,
                    letterSpacing: -0.5,
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.06),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(CupertinoIcons.xmark, size: 16),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Smart OCR & Paste Card
            if (!isEdit) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.cardYellow.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(AppTheme.radiusCard),
                  border: Border.all(color: AppTheme.cardYellow),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(CupertinoIcons.sparkles, color: Color(0xFFB8860B), size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Isi Otomatis dari Teks / Foto Loker',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _pasteController,
                      maxLines: 3,
                      style: const TextStyle(fontSize: 13),
                      decoration: const InputDecoration(
                        hintText: 'Tempel teks iklan loker di sini...',
                        fillColor: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _parsePastedText,
                            icon: const Icon(CupertinoIcons.wand_stars, size: 16),
                            label: const Text('Isi Teks', style: TextStyle(fontSize: 13)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF19191B),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _pickAndAnalyzeImage,
                            icon: const Icon(CupertinoIcons.camera, size: 16),
                            label: const Text('Pindai Foto', style: TextStyle(fontSize: 13)),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              side: const BorderSide(color: Color(0xFF19191B), width: 1.5),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Main Form Fields Container
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(AppTheme.radiusCard),
                border: Border.all(color: const Color(0xFFE6E3D8)),
              ),
              child: Column(
                children: [
                  TextFormField(
                    controller: _positionController,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      labelText: 'Posisi Lowongan *',
                      hintText: 'Contoh: Software Development Engineer',
                      prefixIcon: Icon(CupertinoIcons.briefcase, size: 18),
                    ),
                    validator: (val) => val == null || val.trim().isEmpty ? 'Posisi wajib diisi' : null,
                  ),
                  const SizedBox(height: 14),

                  TextFormField(
                    controller: _companyController,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      labelText: 'Nama Perusahaan *',
                      hintText: 'Contoh: Amazon, Google, Uber',
                      prefixIcon: Icon(CupertinoIcons.building_2_fill, size: 18),
                    ),
                    validator: (val) => val == null || val.trim().isEmpty ? 'Nama Perusahaan wajib diisi' : null,
                  ),
                  const SizedBox(height: 14),

                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _status,
                          decoration: const InputDecoration(
                            labelText: 'Status Lamaran',
                            prefixIcon: Icon(CupertinoIcons.flag, size: 18),
                          ),
                          items: _statusOptions
                              .map((s) => DropdownMenuItem(value: s, child: Text(s, style: const TextStyle(fontSize: 13))))
                              .toList(),
                          onChanged: (val) => setState(() => _status = val!),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _workType,
                          decoration: const InputDecoration(
                            labelText: 'Tipe Kerja',
                            prefixIcon: Icon(CupertinoIcons.desktopcomputer, size: 18),
                          ),
                          items: _workTypeOptions
                              .map((w) => DropdownMenuItem(value: w, child: Text(w, style: const TextStyle(fontSize: 13))))
                              .toList(),
                          onChanged: (val) => setState(() => _workType = val!),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _minSalaryController,
                          decoration: const InputDecoration(
                            labelText: 'Gaji Min',
                            hintText: 'Rp 8.000.000',
                            prefixIcon: Icon(CupertinoIcons.money_dollar, size: 18),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextFormField(
                          controller: _maxSalaryController,
                          decoration: const InputDecoration(
                            labelText: 'Gaji Max',
                            hintText: 'Rp 12.000.000',
                            prefixIcon: Icon(CupertinoIcons.money_dollar_circle, size: 18),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _locationController,
                          textCapitalization: TextCapitalization.words,
                          decoration: const InputDecoration(
                            labelText: 'Lokasi / Kota',
                            hintText: 'Jakarta, California',
                            prefixIcon: Icon(CupertinoIcons.location, size: 18),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _jobSource,
                          decoration: const InputDecoration(
                            labelText: 'Sumber Loker',
                            prefixIcon: Icon(CupertinoIcons.link, size: 18),
                          ),
                          items: _sourceOptions
                              .map((src) => DropdownMenuItem(value: src, child: Text(src, style: const TextStyle(fontSize: 13))))
                              .toList(),
                          onChanged: (val) => setState(() => _jobSource = val!),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  TextFormField(
                    controller: _hrContactController,
                    decoration: const InputDecoration(
                      labelText: 'Kontak HR (WA / Email)',
                      hintText: '+628123456789 atau hr@company.com',
                      prefixIcon: Icon(CupertinoIcons.phone, size: 18),
                    ),
                  ),
                  const SizedBox(height: 14),

                  TextFormField(
                    controller: _descriptionController,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      labelText: 'Deskripsi & Persyaratan Loker',
                      hintText: 'Tulis kualifikasi, tugas utama, atau persyaratan...',
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Submit Button
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _saveJob,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF19191B),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                ),
                child: _isSaving
                    ? const CupertinoActivityIndicator(color: Colors.white)
                    : Text(
                        isEdit ? 'Simpan Perubahan' : 'Tambah Lamaran',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
