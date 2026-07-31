import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../models/job_application.dart';
import '../../providers/job_provider.dart';
import '../../services/text_parser_service.dart';
import '../../theme/app_theme.dart';

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
  DateTime? _interviewDate;

  final List<String> _statusOptions = [
    'Dikirim',
    'HR Screening',
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
    'Lainnya'
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
    _descriptionController =
        TextEditingController(text: j?.jobDescription ?? '');
    _hrContactController = TextEditingController(text: j?.hrContact ?? '');
    _notesController = TextEditingController(text: j?.notes ?? '');

    if (j != null) {
      _status = j.status;
      _workType = j.workType;
      _jobSource = j.jobSource ?? 'LinkedIn';
      _appliedDate = j.appliedDate;
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
    final rawText = _pasteController.text;
    if (rawText.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Silakan paste teks iklan loker dulu!')),
      );
      return;
    }

    final result = TextParserService.parseJobText(rawText);
    setState(() {
      _companyController.text = result.companyName;
      _positionController.text = result.position;
      _workType = result.workType;
      if (result.salary != null) _salaryController.text = result.salary!;
      if (result.location != null) _locationController.text = result.location!;
      _descriptionController.text = rawText;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppTheme.systemGreen,
        content: Text(
            '⚡ Auto-Fill berhasil! Terdeteksi: ${result.position} di ${result.companyName}'),
      ),
    );
  }

  void _saveJob() {
    if (!_formKey.currentState!.validate()) return;

    final isEdit = widget.jobToEdit != null;
    final id = isEdit
        ? widget.jobToEdit!.id
        : DateTime.now().millisecondsSinceEpoch.toString();

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
      interviewDate: _interviewDate,
      notes: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
      isFavorite: widget.jobToEdit?.isFavorite ?? false,
    );

    if (isEdit) {
      ref.read(jobProvider.notifier).updateJob(newJob);
    } else {
      ref.read(jobProvider.notifier).addJob(newJob);
    }

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.jobToEdit != null;
    final surfSec = AppTheme.getSurfaceSecondary(context);
    final bdr = AppTheme.getBorder(context);
    final txtPri = AppTheme.getTextPrimary(context);
    final txtSec = AppTheme.getTextSecondary(context);
    final surf = AppTheme.getSurface(context);

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
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  isEdit ? 'Edit Lamaran' : 'Tambah Lamaran Baru',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: txtPri,
                  ),
                ),
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
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppTheme.systemGreen.withValues(alpha: 0.35),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(CupertinoIcons.bolt_fill,
                            color: AppTheme.systemGreen, size: 20),
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
                      style: TextStyle(
                        color: txtSec,
                        fontSize: 12,
                      ),
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
                      height: 44,
                      child: ElevatedButton.icon(
                        onPressed: _parsePastedText,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.systemGreen,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        icon: const Icon(CupertinoIcons.wand_stars,
                            color: Colors.white, size: 18),
                        label: const Text('Parse & Isi Otomatis',
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(CupertinoIcons.info_circle_fill,
                            size: 13, color: AppTheme.getTextTertiary(context)),
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
            Text('Informasi Utama',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 17,
                    color: txtPri,
                    letterSpacing: -0.3)),
            const SizedBox(height: 10),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: surfSec,
                borderRadius: BorderRadius.circular(20),
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
                      prefixIcon:
                          Icon(CupertinoIcons.building_2_fill, size: 18),
                    ),
                    validator: (val) => val == null || val.trim().isEmpty
                        ? 'Nama Perusahaan wajib diisi'
                        : null,
                  ),
                  const SizedBox(height: 14),

                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: _status,
                          dropdownColor: surf,
                          style: TextStyle(color: txtPri),
                          decoration: const InputDecoration(
                            labelText: 'Status Lamaran',
                            prefixIcon: Icon(CupertinoIcons.flag, size: 18),
                          ),
                          items: _statusOptions
                              .map((s) => DropdownMenuItem(
                                    value: s,
                                    child: Text(s,
                                        style: TextStyle(
                                            fontSize: 13, color: txtPri)),
                                  ))
                              .toList(),
                          onChanged: (val) {
                            if (val != null) setState(() => _status = val);
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: _workType,
                          dropdownColor: surf,
                          style: TextStyle(color: txtPri),
                          decoration: const InputDecoration(
                            labelText: 'Tipe Kerja',
                            prefixIcon:
                                Icon(CupertinoIcons.desktopcomputer, size: 18),
                          ),
                          items: _workTypeOptions
                              .map((w) => DropdownMenuItem(
                                    value: w,
                                    child: Text(w,
                                        style: TextStyle(
                                            fontSize: 13, color: txtPri)),
                                  ))
                              .toList(),
                          onChanged: (val) {
                            if (val != null) setState(() => _workType = val);
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _salaryController,
                          style: TextStyle(color: txtPri),
                          decoration: const InputDecoration(
                            labelText: 'Ekspektasi/Gaji',
                            hintText: 'Contoh: Rp 6.000.000',
                            prefixIcon:
                                Icon(CupertinoIcons.money_dollar, size: 18),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
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
                    ],
                  ),
                  const SizedBox(height: 14),

                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: _jobSource,
                          dropdownColor: surf,
                          style: TextStyle(color: txtPri),
                          decoration: const InputDecoration(
                            labelText: 'Sumber Loker',
                            prefixIcon: Icon(CupertinoIcons.link, size: 18),
                          ),
                          items: _sourceOptions
                              .map((s) => DropdownMenuItem(
                                    value: s,
                                    child: Text(s,
                                        style: TextStyle(
                                            fontSize: 13, color: txtPri)),
                                  ))
                              .toList(),
                          onChanged: (val) {
                            if (val != null) setState(() => _jobSource = val);
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: InkWell(
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: _appliedDate,
                              firstDate: DateTime(2020),
                              lastDate: DateTime(2030),
                            );
                            if (picked != null) {
                              setState(() => _appliedDate = picked);
                            }
                          },
                          child: InputDecorator(
                            decoration: const InputDecoration(
                              labelText: 'Tanggal Melamar',
                              prefixIcon:
                                  Icon(CupertinoIcons.calendar, size: 18),
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
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Grouped Contact Card
            Text('Kontak HR & Jadwal',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 17,
                    color: txtPri,
                    letterSpacing: -0.3)),
            const SizedBox(height: 10),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: surfSec,
                borderRadius: BorderRadius.circular(20),
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

                  InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _interviewDate ?? DateTime.now(),
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2030),
                      );
                      if (picked != null) {
                        setState(() => _interviewDate = picked);
                      }
                    },
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: 'Jadwal Interview (Opsional)',
                        prefixIcon: const Icon(CupertinoIcons.time, size: 18),
                        suffixIcon: _interviewDate != null
                            ? IconButton(
                                icon: const Icon(CupertinoIcons.xmark_circle,
                                    size: 18),
                                onPressed: () {
                                  setState(() => _interviewDate = null);
                                },
                              )
                            : null,
                      ),
                      child: Text(
                        _interviewDate != null
                            ? DateFormat('dd MMMM yyyy')
                                .format(_interviewDate!)
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
            Text('Deskripsi & Catatan',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 17,
                    color: txtPri,
                    letterSpacing: -0.3)),
            const SizedBox(height: 10),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: surfSec,
                borderRadius: BorderRadius.circular(20),
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
              height: 50,
              child: ElevatedButton(
                onPressed: _saveJob,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.systemBlue,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(
                  isEdit ? 'Simpan Perubahan' : 'Tambah ke Ngelamar',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
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
}
