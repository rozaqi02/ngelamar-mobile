import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
  late TextEditingController _salaryController;
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
    _salaryController.dispose();
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
        _salaryController.text = result.salary!;
      }
      if (result.location != null) _locationController.text = result.location!;
      _descriptionController.text = text;
    });

    // Check duplicate
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
            'Lamaran posisi "${result.position}" di ${result.companyName} sudah pernah dicatat.',
      );
    } else {
      AppleToast.success(
        context,
        'Auto-Fill berhasil! Terdeteksi: ${result.position} di ${result.companyName}',
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

    final newJob = JobApplication(
      id: id,
      companyName: _companyController.text.trim(),
      position: _positionController.text.trim(),
      status: _status,
      appliedDate: _appliedDate,
      salaryOffered: _salaryController.text.trim().isEmpty
          ? null
          : _salaryController.text.trim(),
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
      // Simpan data ke Hive terlebih dahulu - ini operasi utama.
      if (isEdit) {
        await ref.read(jobProvider.notifier).updateJob(newJob);
      } else {
        await ref.read(jobProvider.notifier).addJob(newJob);
      }

      // Minta izin notifikasi SETELAH data berhasil disimpan.
      // Kegagalan minta izin tidak membatalkan penyimpanan data.
      if (newJob.interviewDate != null && mounted) {
        NotificationService.requestPermission().catchError((Object error) {
          debugPrint('Permintaan izin notifikasi gagal (diabaikan): $error');
          return false;
        });
      }

      if (!mounted) return;
      Navigator.pop(context, newJob);
    } catch (error, stackTrace) {
      debugPrint('Error saat menyimpan lamaran: $error\n$stackTrace');
      if (!mounted) return;
      setState(() => _isSaving = false);
      AppleToast.error(
        context,
        'Lamaran gagal disimpan',
        subtitle: 'Periksa penyimpanan perangkat lalu coba lagi.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.jobToEdit != null;
    final surfSec = AppTheme.getSurfaceSecondary(context);
    final bdr = AppTheme.getBorder(context);
    final txtPri = AppTheme.getTextPrimary(context);
    final txtSec = AppTheme.getTextSecondary(context);
    final media = MediaQuery.of(context);
    final compact = media.size.width < 390 || media.textScaler.scale(1) > 1.25;

    Widget responsivePair(Widget first, Widget second) {
      if (compact) {
        return Column(children: [first, const SizedBox(height: 14), second]);
      }
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: first),
          const SizedBox(width: 12),
          Expanded(child: second),
        ],
      );
    }

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header title row for modal window
            Row(
              children: [
                Expanded(
                  child: Text(
                    isEdit ? 'Edit Lamaran' : 'Tambah Lamaran Baru',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: txtPri,
                    ),
                    maxLines: 2,
                  ),
                ),
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: surfSec,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(CupertinoIcons.xmark, size: 16, color: txtSec),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Smart Auto-Fill Section (Apple Card Style)
            if (!isEdit) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: surfSec,
                  borderRadius: BorderRadius.circular(AppTheme.radiusCard),
                  border: Border.all(
                    color: AppTheme.systemGreen.withValues(alpha: 0.35),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(
                          CupertinoIcons.bolt_fill,
                          color: AppTheme.systemGreen,
                          size: 20,
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Smart Auto-Fill (Paste Teks Loker)',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Copas teks info loker dari LinkedIn/Glints/JobStreet di sini untuk mengisi form otomatis.',
                      style: TextStyle(color: txtSec, fontSize: 12),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _pasteController,
                      autofocus: widget.autoFocusPaste,
                      maxLines: 3,
                      style: TextStyle(color: txtPri, fontSize: 13),
                      decoration: const InputDecoration(
                        hintText: 'Paste teks lowongan kerja di sini...',
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _parsePastedText,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.systemGreen,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        icon: const Icon(
                          CupertinoIcons.wand_stars,
                          color: Colors.white,
                          size: 18,
                        ),
                        label: const Text(
                          'Parse & Isi Otomatis',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          CupertinoIcons.info_circle_fill,
                          size: 13,
                          color: AppTheme.getTextTertiary(context),
                        ),
                        const SizedBox(width: 5),
                        Expanded(
                          child: Text(
                            'Smart Auto-Fill akan mendeteksi dan mengisi otomatis text box: Posisi, Perusahaan, Tipe Kerja (WFO/WFH/Hybrid), Gaji, Lokasi, dan Deskripsi.',
                            style: TextStyle(
                              color: AppTheme.getTextTertiary(context),
                              fontSize: 11,
                              height: 1.35,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],

            // Grouped Form Card
            Text(
              'Informasi Utama',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 17,
                color: txtPri,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 10),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: surfSec,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: bdr),
              ),
              child: Column(
                children: [
                  TextFormField(
                    controller: _positionController,
                    textCapitalization: TextCapitalization.words,
                    style: TextStyle(color: txtPri),
                    decoration: const InputDecoration(
                      labelText: 'Posisi Melamar *',
                      hintText: 'Contoh: Junior Frontend Developer',
                      prefixIcon: Icon(CupertinoIcons.briefcase, size: 18),
                    ),
                    validator: (val) => val == null || val.trim().isEmpty
                        ? 'Posisi wajib diisi'
                        : null,
                  ),
                  const SizedBox(height: 14),

                  TextFormField(
                    controller: _companyController,
                    textCapitalization: TextCapitalization.words,
                    style: TextStyle(color: txtPri),
                    decoration: const InputDecoration(
                      labelText: 'Nama Perusahaan *',
                      hintText: 'Contoh: PT GoTo Indonesia',
                      prefixIcon: Icon(
                        CupertinoIcons.building_2_fill,
                        size: 18,
                      ),
                    ),
                    validator: (val) => val == null || val.trim().isEmpty
                        ? 'Nama Perusahaan wajib diisi'
                        : null,
                  ),
                  const SizedBox(height: 14),

                  responsivePair(
                    InkWell(
                      onTap: () => _showAppleOptionPicker(
                        context: context,
                        title: 'Pilih Status Lamaran',
                        options: _statusOptions,
                        currentValue: _status,
                        onSelected: (val) => setState(() => _status = val),
                      ),
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Status Lamaran',
                          prefixIcon: Icon(CupertinoIcons.flag, size: 18),
                          suffixIcon: Icon(
                            CupertinoIcons.chevron_down,
                            size: 14,
                          ),
                        ),
                        child: Text(
                          _status,
                          style: TextStyle(fontSize: 13, color: txtPri),
                        ),
                      ),
                    ),
                    InkWell(
                      onTap: () => _showAppleOptionPicker(
                        context: context,
                        title: 'Pilih Tipe Kerja',
                        options: _workTypeOptions,
                        currentValue: _workType,
                        onSelected: (val) => setState(() => _workType = val),
                      ),
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Tipe Kerja',
                          prefixIcon: Icon(
                            CupertinoIcons.desktopcomputer,
                            size: 18,
                          ),
                          suffixIcon: Icon(
                            CupertinoIcons.chevron_down,
                            size: 14,
                          ),
                        ),
                        child: Text(
                          _workType,
                          style: TextStyle(fontSize: 13, color: txtPri),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  responsivePair(
                    TextFormField(
                      controller: _salaryController,
                      style: TextStyle(color: txtPri),
                      decoration: const InputDecoration(
                        labelText: 'Estimasi Range Gaji',
                        hintText: 'Contoh: Rp 8.000.000 - Rp 12.000.000',
                        prefixIcon: Icon(CupertinoIcons.money_dollar, size: 18),
                      ),
                    ),
                    TextFormField(
                      controller: _locationController,
                      textCapitalization: TextCapitalization.words,
                      style: TextStyle(color: txtPri),
                      decoration: const InputDecoration(
                        labelText: 'Kota / Lokasi',
                        hintText: 'Contoh: Jakarta',
                        prefixIcon: Icon(CupertinoIcons.location, size: 18),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  responsivePair(
                    InkWell(
                      onTap: () => _showAppleOptionPicker(
                        context: context,
                        title: 'Pilih Sumber Loker',
                        options: _sourceOptions,
                        currentValue: _jobSource,
                        onSelected: (val) => setState(() => _jobSource = val),
                      ),
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Sumber Loker',
                          prefixIcon: Icon(CupertinoIcons.link, size: 18),
                          suffixIcon: Icon(
                            CupertinoIcons.chevron_down,
                            size: 14,
                          ),
                        ),
                        child: Text(
                          _jobSource,
                          style: TextStyle(fontSize: 13, color: txtPri),
                        ),
                      ),
                    ),
                    InkWell(
                      onTap: () => _showAppleDatePicker(
                        context: context,
                        initialDate: _appliedDate,
                        onDateSelected: (val) =>
                            setState(() => _appliedDate = val),
                      ),
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Tanggal Melamar',
                          prefixIcon: Icon(CupertinoIcons.calendar, size: 18),
                        ),
                        child: Text(
                          DateFormat('dd/MM/yyyy').format(_appliedDate),
                          style: TextStyle(fontSize: 13, color: txtPri),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Grouped Contact & Schedule Card
            Text(
              'Kontak HR & Jadwal',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 17,
                color: txtPri,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 10),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: surfSec,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: bdr),
              ),
              child: Column(
                children: [
                  TextFormField(
                    controller: _hrContactController,
                    style: TextStyle(color: txtPri),
                    decoration: const InputDecoration(
                      labelText: 'Nomor WA / Email HR (Opsional)',
                      hintText: 'Contoh: +628123456789 atau hr@company.com',
                      prefixIcon: Icon(CupertinoIcons.phone, size: 18),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Tanggal Psikotes / Tes
                  InkWell(
                    onTap: () => _showAppleDatePicker(
                      context: context,
                      initialDate: _testDate ?? DateTime.now(),
                      includeTime: true,
                      onDateSelected: (val) => setState(() => _testDate = val),
                    ),
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: 'Jadwal Psikotes / Tes (Opsional)',
                        prefixIcon: const Icon(
                          CupertinoIcons.doc_checkmark,
                          size: 18,
                        ),
                        suffixIcon: _testDate != null
                            ? IconButton(
                                icon: const Icon(
                                  CupertinoIcons.xmark_circle,
                                  size: 18,
                                ),
                                onPressed: () {
                                  setState(() => _testDate = null);
                                },
                              )
                            : null,
                      ),
                      child: Text(
                        _testDate != null
                            ? DateFormat('dd MMMM yyyy, HH:mm').format(_testDate!)
                            : 'Belum ada jadwal tes / psikotes',
                        style: TextStyle(fontSize: 13, color: txtPri),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Tanggal Wawancara / Interview
                  InkWell(
                    onTap: () => _showAppleDatePicker(
                      context: context,
                      initialDate: _interviewDate ?? DateTime.now(),
                      includeTime: true,
                      onDateSelected: (val) =>
                          setState(() => _interviewDate = val),
                    ),
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: 'Jadwal Wawancara / Interview (Opsional)',
                        prefixIcon: const Icon(CupertinoIcons.time, size: 18),
                        suffixIcon: _interviewDate != null
                            ? IconButton(
                                icon: const Icon(
                                  CupertinoIcons.xmark_circle,
                                  size: 18,
                                ),
                                onPressed: () {
                                  setState(() => _interviewDate = null);
                                },
                              )
                            : null,
                      ),
                      child: Text(
                        _interviewDate != null
                            ? DateFormat(
                                'dd MMMM yyyy, HH:mm',
                              ).format(_interviewDate!)
                            : 'Belum ada jadwal interview',
                        style: TextStyle(fontSize: 13, color: txtPri),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Grouped Notes Card
            Text(
              'Deskripsi & Catatan',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 17,
                color: txtPri,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 10),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: surfSec,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: bdr),
              ),
              child: Column(
                children: [
                  TextFormField(
                    controller: _descriptionController,
                    maxLines: 4,
                    style: TextStyle(color: txtPri),
                    decoration: const InputDecoration(
                      labelText: 'Snapshot Deskripsi / Requirement Loker',
                      hintText:
                          'Catat skill & syarat utama di sini agar tidak lupa saat diwawancarai...',
                    ),
                  ),
                  const SizedBox(height: 14),

                  TextFormField(
                    controller: _notesController,
                    maxLines: 2,
                    style: TextStyle(color: txtPri),
                    decoration: const InputDecoration(
                      labelText: 'Catatan Pribadi',
                      hintText: 'Catatan tambahan (link Zoom, dll)...',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _saveJob,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.systemBlue,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          isEdit ? 'Simpan Perubahan' : 'Tambah ke Ngelamar',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                ),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  void _showAppleOptionPicker({
    required BuildContext context,
    required String title,
    required List<String> options,
    required String currentValue,
    required ValueChanged<String> onSelected,
  }) {
    final isDark = AppTheme.isDark(context);

    showCupertinoModalPopup(
      context: context,
      builder: (_) => CupertinoActionSheet(
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        ),
        actions: options.map((opt) {
          final isSelected = opt == currentValue;
          final statusColor = AppTheme.getStatusColor(opt, isDark: isDark);

          return CupertinoActionSheetAction(
            onPressed: () {
              onSelected(opt);
              Navigator.pop(context);
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: statusColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  opt,
                  style: TextStyle(
                    color: isSelected
                        ? (isDark ? Colors.white : Colors.black)
                        : AppTheme.getTextPrimary(context),
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    fontSize: 16,
                  ),
                ),
                if (isSelected) ...[
                  const SizedBox(width: 8),
                  Icon(
                    CupertinoIcons.checkmark_alt,
                    size: 16,
                    color: isDark ? AppTheme.systemBlue : AppTheme.lSystemBlue,
                  ),
                ],
              ],
            ),
          );
        }).toList(),
        cancelButton: CupertinoActionSheetAction(
          isDefaultAction: true,
          onPressed: () => Navigator.pop(context),
          child: const Text('Batal'),
        ),
      ),
    );
  }

  void _showAppleDatePicker({
    required BuildContext context,
    required DateTime initialDate,
    required ValueChanged<DateTime> onDateSelected,
    bool includeTime = false,
  }) {
    DateTime tempDate = initialDate;
    final surf = AppTheme.getSurface(context);
    final surfSec = AppTheme.getSurfaceSecondary(context);

    showCupertinoModalPopup(
      context: context,
      builder: (_) => Container(
        height: 280,
        color: surf,
        child: Column(
          children: [
            Container(
              color: surfSec,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Text(
                      'Batal',
                      style: TextStyle(color: AppTheme.systemRed, fontSize: 16),
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      onDateSelected(tempDate);
                      Navigator.pop(context);
                    },
                    child: const Text(
                      'Selesai',
                      style: TextStyle(
                        color: AppTheme.systemBlue,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: CupertinoDatePicker(
                mode: includeTime
                    ? CupertinoDatePickerMode.dateAndTime
                    : CupertinoDatePickerMode.date,
                initialDateTime: initialDate,
                minimumYear: 2020,
                maximumYear: DateTime.now().year + 20,
                use24hFormat: true,
                onDateTimeChanged: (val) => tempDate = val,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
